import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google's published test ad unit — always serves a placeholder test ad, so
/// this is safe to ship until the app has its own AdMob account/units (same
/// "not a secret" reasoning as the RevenueCat key elsewhere in shared/).
/// Swap for the app's real unit ID(s) before release.
/// See https://developers.google.com/admob/flutter/test-ads.
String get sessionBannerAdUnitId {
  if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/6300978111';
  return 'ca-app-pub-3940256099942544/2934735716';
}

/// Centralized wrapper around the Google Mobile Ads SDK. All ad calls in the
/// app should go through this class rather than calling `MobileAds.*`
/// directly, so the SDK surface stays swappable/testable in one place.
class AdsService {
  static final AdsService _instance = AdsService._internal();
  factory AdsService() => _instance;
  AdsService._internal();

  bool _isInitialized = false;

  // The Mobile Ads SDK only ships native plugin code for Android and iOS —
  // on other platforms (e.g. Windows desktop, web) every call throws
  // MissingPluginException. Checked via defaultTargetPlatform/kIsWeb rather
  // than dart:io's Platform, which throws UnsupportedError on web.
  static bool get isSupported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    if (_isInitialized || !isSupported) return;
    await MobileAds.instance.initialize();
    _isInitialized = true;
  }

  /// Builds (but does not load) a banner ad. Callers must call `.load()`
  /// themselves and wait for [onLoaded] — the ad has no content, and
  /// [AdWidget] has nothing to display, until that fires. The `.load()`
  /// call's own returned Future only confirms the request was dispatched,
  /// not that a creative came back.
  BannerAd createSessionBannerAd({
    required void Function(BannerAd ad) onLoaded,
    required void Function(Ad ad) onFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: sessionBannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => onLoaded(ad as BannerAd),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onFailedToLoad(ad);
        },
      ),
    );
  }
}
