import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../ads/ads_variable.dart';
import 'firebase_analysis.dart';

class AdRevenueAnalyticsService {
  /// Master check and sub-switch validator
  static bool shouldTrackRevenue(bool subSwitchEnabled) {
    if (!AdsVariable.sendRevenueToAnalytics) {
      debugPrint('[AdRevenueAnalytics] 🚫 Master switch (sendRevenueToAnalytics) is OFF. Skipping ad_impression.');
      return false;
    }
    if (!subSwitchEnabled) {
      debugPrint('[AdRevenueAnalytics] 🚫 Specific sub-switch is OFF. Skipping ad_impression.');
      return false;
    }
    return true;
  }

  /// Track official Firebase ad_impression with revenue metrics (Controlled by switches)
  static void trackAdImpression({
    required Ad ad,
    required double valueMicros,
    required PrecisionType precision,
    required String currencyCode,
    required String placement,
    required bool isSubSwitchEnabled,
  }) {
    if (!shouldTrackRevenue(isSubSwitchEnabled)) {
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

  /// COMPULSARY: Always fires `Show_<Placement>` count event when an ad is displayed
  static void trackCompulsoryShow({
    required String eventName,
    required String adUnitId,
  }) {
    try {
      debugPrint('[AdAnalytics] 👁️ Compulsory Show Event: $eventName (adUnit: $adUnitId)');
      FirebaseAnalyticsService.logEvent(
        eventName: eventName,
        parameters: {
          'ad_unit_id': adUnitId,
        },
      );
    } catch (e) {
      debugPrint('[AdAnalytics] ❌ Error logging $eventName: $e');
    }
  }

  /// COMPULSARY: Always fires `Rev_<Placement>` with value & currency when an ad earns revenue
  static void trackCompulsoryRevenue({
    required String eventName,
    required Ad ad,
    required double valueMicros,
    required PrecisionType precision,
    required String currencyCode,
  }) {
    try {
      final double revenueValue = valueMicros / 1000000.0;
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
        'value': revenueValue,
        'currency': currencyCode.isEmpty ? 'USD' : currencyCode,
        'ad_unit_id': ad.adUnitId,
        'ad_format': adFormat,
        'precision': precision.name,
      };

      debugPrint('[AdAnalytics] 💵 Compulsory Revenue Event: $eventName, value=$revenueValue $currencyCode');
      FirebaseAnalyticsService.logEvent(
        eventName: eventName,
        parameters: params,
      );
    } catch (e) {
      debugPrint('[AdAnalytics] ❌ Error logging $eventName: $e');
    }
  }
}
