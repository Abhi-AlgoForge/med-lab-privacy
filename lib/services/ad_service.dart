import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'storage_service.dart';

class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  final StorageService _storage = StorageService();

  // Test ad unit IDs — replace with real ones from AdMob console for production
  static const String _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    await _loadInterstitialAd();
  }

  Future<void> _loadInterstitialAd() async {
    await InterstitialAd.load(
      adUnitId: _testInterstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isAdLoaded = false;
              _loadInterstitialAd(); // Preload next ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isAdLoaded = false;
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
          _isAdLoaded = false;
          // Retry after delay
          Future.delayed(const Duration(seconds: 30), _loadInterstitialAd);
        },
      ),
    );
  }

  /// Show interstitial ad if user is free tier. Returns true if ad was shown.
  Future<bool> showInterstitialIfFree() async {
    final isPro = await _storage.isProUser();
    if (isPro) return false;

    if (_isAdLoaded && _interstitialAd != null) {
      await _interstitialAd!.show();
      return true;
    }
    return false;
  }

  void dispose() {
    _interstitialAd?.dispose();
  }
}
