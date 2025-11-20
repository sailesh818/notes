import 'package:google_mobile_ads/google_mobile_ads.dart';

class AppOpenAdManager {
  static AppOpenAd? _appOpenAd;
  static bool _isShowingAd = false;

  static Future<void> loadAd() async {
    await AppOpenAd.load(
      adUnitId: "ca-app-pub-6704136477020125/3623085232",
      //adUnitId: "ca-app-pub-3940256099942544/3419835294",  //testAppOpenAdUnitId
      // your App Open Ad ID // 
      //const String testAppOpenAdUnitId = 'ca-app-pub-3940256099942544/3419835294'; 
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (error) {
          _appOpenAd = null;
        },
      ),
      
    );
  }

  static void showAdIfAvailable() {
    if (_isShowingAd) return;
    if (_appOpenAd == null) {
      loadAd();
      return;
    }

    _appOpenAd!.fullScreenContentCallback =
        FullScreenContentCallback(onAdDismissedFullScreenContent: (ad) {
      _isShowingAd = false;
      ad.dispose();
      loadAd(); // load again
    }, onAdFailedToShowFullScreenContent: (ad, error) {
      _isShowingAd = false;
      ad.dispose();
      loadAd();
    });

    _isShowingAd = true;
    _appOpenAd!.show();
  }
}
