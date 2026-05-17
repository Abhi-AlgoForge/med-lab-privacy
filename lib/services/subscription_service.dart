import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'storage_service.dart';

/// Outcome of a [SubscriptionService.buyMonthly] / restore attempt. Lets the
/// paywall react to the actual Play-Billing event instead of polling.
enum PurchaseOutcome {
  /// Purchase or restore confirmed and entitlement was granted.
  success,

  /// User dismissed the Play / App Store sheet.
  cancelled,

  /// Billing reported an error (network, Play Services missing, etc).
  error,

  /// No product was loaded yet — cannot launch the purchase flow.
  unavailable,

  /// User already owns the subscription (Play returns this on duplicate buy).
  alreadyOwned,

  /// We never received a response from the store within the timeout.
  timeout,
}

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._();
  factory SubscriptionService() => _instance;
  SubscriptionService._();

  // Replace with your actual product ID from Google Play Console
  static const String monthlyProductId = 'med_lab_pro_monthly';

  final InAppPurchase _iap = InAppPurchase.instance;
  final StorageService _storage = StorageService();

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? _monthlyProduct;
  bool _isAvailable = false;
  bool _isPro = false;

  /// Completer for the in-flight purchase / restore. The Play Billing stream
  /// resolves it on the next event so the paywall can react to the actual
  /// outcome instead of waiting a fixed amount of time.
  Completer<PurchaseOutcome>? _pendingOutcome;

  bool get isPro => _isPro;
  bool get isAvailable => _isAvailable;
  ProductDetails? get monthlyProduct => _monthlyProduct;

  String get priceString => _monthlyProduct?.price ?? '\$5.99';

  Future<void> initialize() async {
    _isPro = await _storage.isProUser();

    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) return;

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (error) {
        debugPrint('Purchase stream error: $error');
        _completeOutcome(PurchaseOutcome.error);
      },
    );

    // Load product details
    final response = await _iap.queryProductDetails({monthlyProductId});
    if (response.productDetails.isNotEmpty) {
      _monthlyProduct = response.productDetails.first;
    }

    // Restore previous purchases. Don't tie this to _pendingOutcome — the
    // app may have been launched cold and there's no UI waiting on it.
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('Initial restorePurchases failed: $e');
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _verifyAndDeliver(purchase).then((_) {
            _completeOutcome(PurchaseOutcome.success);
          });
          break;
        case PurchaseStatus.error:
          debugPrint('Purchase error: ${purchase.error}');
          final code = purchase.error?.code ?? '';
          if (code.contains('itemAlreadyOwned') ||
              code == '7' /* BillingResponseCode.ITEM_ALREADY_OWNED */) {
            _completeOutcome(PurchaseOutcome.alreadyOwned);
          } else {
            _completeOutcome(PurchaseOutcome.error);
          }
          break;
        case PurchaseStatus.canceled:
          _completeOutcome(PurchaseOutcome.cancelled);
          break;
        case PurchaseStatus.pending:
          // Keep waiting — Play will fire again with the final state.
          break;
      }

      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  void _completeOutcome(PurchaseOutcome outcome) {
    final pending = _pendingOutcome;
    if (pending != null && !pending.isCompleted) {
      pending.complete(outcome);
    }
    _pendingOutcome = null;
  }

  Future<void> _verifyAndDeliver(PurchaseDetails purchase) async {
    // ⚠️  CLIENT-SIDE ONLY VERIFICATION  ⚠️
    //
    // The checks below are best-effort guards against the common cases
    // (wrong product, empty receipt) — they do NOT prevent receipt
    // tampering on rooted devices or Lucky-Patcher-style attacks. For
    // production-grade subscription security, verify
    // `purchase.verificationData.serverVerificationData` against the
    // Play Developer API (`purchases.subscriptions.get`) from a backend
    // and only grant Pro on a verified response.
    //
    // Tracked as a follow-up — see project audit "IAP hardening".

    if (purchase.productID != monthlyProductId) {
      debugPrint(
          'Ignoring purchase for unexpected productID: ${purchase.productID}');
      return;
    }

    final receipt = purchase.verificationData.localVerificationData;
    if (receipt.isEmpty) {
      debugPrint('Ignoring purchase with empty verification data');
      return;
    }

    _isPro = true;
    await _storage.setProUser(true);
  }

  /// Launches the monthly subscription purchase flow and resolves with the
  /// actual outcome reported by Play Billing.
  Future<PurchaseOutcome> buyMonthly() async {
    if (_monthlyProduct == null) return PurchaseOutcome.unavailable;

    // Fail any prior wait that never resolved.
    _completeOutcome(PurchaseOutcome.timeout);
    final completer = Completer<PurchaseOutcome>();
    _pendingOutcome = completer;

    final purchaseParam = PurchaseParam(productDetails: _monthlyProduct!);
    try {
      final launched =
          await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      if (!launched) {
        _completeOutcome(PurchaseOutcome.error);
      }
    } catch (e) {
      debugPrint('buyNonConsumable threw: $e');
      final msg = e.toString().toLowerCase();
      if (msg.contains('already owned') || msg.contains('itemalreadyowned')) {
        _completeOutcome(PurchaseOutcome.alreadyOwned);
      } else {
        _completeOutcome(PurchaseOutcome.error);
      }
    }

    // Safety net — if Play never reports back, don't hang the paywall forever.
    return completer.future.timeout(
      const Duration(seconds: 90),
      onTimeout: () => PurchaseOutcome.timeout,
    );
  }

  /// Restores prior purchases. Resolves on the next billing event or after
  /// a short window if the store has nothing to report.
  Future<PurchaseOutcome> restorePurchases() async {
    _completeOutcome(PurchaseOutcome.timeout);
    final completer = Completer<PurchaseOutcome>();
    _pendingOutcome = completer;

    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('restorePurchases threw: $e');
      _completeOutcome(PurchaseOutcome.error);
    }

    // Restore is silent when the user owns nothing. Resolve to "cancelled"
    // (treated as "no active subscription") after 4s.
    return completer.future.timeout(
      const Duration(seconds: 4),
      onTimeout: () => PurchaseOutcome.cancelled,
    );
  }

  void dispose() {
    _subscription?.cancel();
  }
}
