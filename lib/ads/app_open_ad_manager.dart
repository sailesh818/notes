import 'package:google_mobile_ads/google_mobile_ads.dart';

class AppOpenAdManager {
  static AppOpenAd? _appOpenAd;
  static bool _isShowingAd = false;
  static bool _isLoadingAd = false;

  /// Preload App Open Ad
  static Future<void> loadAd() async {
    if (_isLoadingAd || _appOpenAd != null) return;

    _isLoadingAd = true;

    await AppOpenAd.load(
      // Test App Open Ad unit ID
      //adUnitId: "ca-app-pub-3940256099942544/3419835294",
      //real adUnitId here
      adUnitId: "ca-app-pub-6704136477020125/3623085232",
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isLoadingAd = false;
          print("AppOpenAd loaded successfully.");
        },
        onAdFailedToLoad: (error) {
          print("AppOpenAd failed to load: $error");
          _appOpenAd = null;
          _isLoadingAd = false;
        },
      ),
      //orientation: AppOpenAd.orientationPortrait,
    );
  }

  /// Show the ad if available, otherwise load a new one
  static void showAdIfAvailable() {
    if (_isShowingAd) return;

    if (_appOpenAd == null) {
      print("No AppOpenAd available, loading now...");
      loadAd(); // preload if not available
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        print("AppOpenAd dismissed.");
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd(); // preload next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print("AppOpenAd failed to show: $error");
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd(); // preload next ad
      },
      onAdShowedFullScreenContent: (ad) {
        print("AppOpenAd is showing.");
      },
    );

    _isShowingAd = true;
    _appOpenAd!.show();
  }

  /// Optional: check if ad is ready
  static bool get isAdAvailable => _appOpenAd != null;
}
