import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'storage_service.dart';

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
      },
    );

    // Load product details
    final response = await _iap.queryProductDetails({monthlyProductId});
    if (response.productDetails.isNotEmpty) {
      _monthlyProduct = response.productDetails.first;
    }

    // Restore previous purchases
    await _iap.restorePurchases();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _verifyAndDeliver(purchase);
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('Purchase error: ${purchase.error}');
      }

      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _verifyAndDeliver(PurchaseDetails purchase) async {
    if (purchase.productID == monthlyProductId) {
      _isPro = true;
      await _storage.setProUser(true);
    }
  }

  Future<bool> buyMonthly() async {
    if (_monthlyProduct == null) return false;

    final purchaseParam = PurchaseParam(productDetails: _monthlyProduct!);
    return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
  }
}
