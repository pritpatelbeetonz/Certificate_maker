import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../ads/ads_variable.dart';
import 'firebase_analysis.dart';

class AdRevenueAnalyticsService {
  /// Master switch check, then the ad unit must be in Remote Config's adImpressionEventAllowed list
  static bool shouldTrackRevenue(String adUnitId) {
    if (!AdsVariable.sendRevenueToAnalytics) {
      debugPrint('[AdRevenueAnalytics] 🚫 Master switch (sendRevenueToAnalytics) is OFF. Skipping ad_impression.');
      return false;
    }
    if (!AdsVariable.adImpressionEventAllowed.contains(adUnitId.trim())) {
      debugPrint('[AdRevenueAnalytics] 🚫 Ad unit $adUnitId is not in adImpressionEventAllowed. Skipping ad_impression.');
      return false;
    }
    return true;
  }

  /// Track official Firebase ad_impression with revenue metrics (only for allowed ad unit IDs)
  static void trackAdImpression({
    required Ad ad,
    required double valueMicros,
    required PrecisionType precision,
    required String currencyCode,
    required String placement,
  }) {
    if (!shouldTrackRevenue(ad.adUnitId)) {
      return;
    }

    try {
      final double revenueValue = valueMicros / 1000000.0;
      final String adUnitId = ad.adUnitId;

      String adFormat = 'unknown';
      if (ad is AppOpenAd) {
        adFormat = 'app_open';
      } else if (ad is InterstitialAd) {
        adFormat = 'interstitial';
      } else if (ad is NativeAd) {
        adFormat = 'native';
      } else if (ad is BannerAd) {
        adFormat = 'banner';
      }

      final Map<String, Object> params = {
        'ad_platform': 'admob',
        'ad_source': 'admob',
        'ad_unit_name': adUnitId,
        'ad_format': adFormat,
        'value': revenueValue,
        'currency': currencyCode.isEmpty ? 'USD' : currencyCode,
        'precision': precision.name,
        'placement': placement,
      };

      debugPrint('[AdRevenueAnalytics] 💰 Logging ad_impression: placement=$placement, value=$revenueValue $currencyCode, format=$adFormat');
      FirebaseAnalyticsService.logEvent(
        eventName: 'ad_impression',
        parameters: params,
      );
    } catch (e) {
      debugPrint('[AdRevenueAnalytics] ❌ Error tracking ad_impression: $e');
    }
  }
}
