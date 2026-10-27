import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class FirebaseAnalyticsService {


  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: _analytics);


  static Future<void> logEvent({
    required String eventName,
    Map<String, Object>? parameters, // Change dynamic to Object
  }) async {
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );
    } catch (e) {
      print("Error logging event: $e");
    }
  }


  /// Sets a user property
  static Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _analytics.setUserProperty(
        name: name,
        value: value,
      );
    } catch (e) {
      print("Error setting user property: $e");
    }
  }

  /// Sets the current screen for analytics
  static Future<void> setCurrentScreen({
    required String screenName,
    String screenClassOverride='',
  }) async {
    try {
      await _analytics.setCurrentScreen(
        screenName: screenName,
        screenClassOverride: screenClassOverride,
      );
    } catch (e) {
      print("Error setting current screen: $e");
    }
  }

  /// Logs an app open event
  static Future<void> logAppOpen() async {
    try {
      await _analytics.logAppOpen();
    } catch (e) {
      print("Error logging app open: $e");
    }
  }

  /// Logs a user sign-in event
  static Future<void> logSignIn({
    required String method,
  }) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      print("Error logging sign-in: $e");
    }
  }

  /// Logs a user sign-out event
  static Future<void> logSignOut() async {
    try {
      await logEvent(eventName: 'user_sign_out');
    } catch (e) {
      print("Error logging sign-out: $e");
    }
  }

  /// Logs standard GA4 purchase event on iOS only for verified StoreKit 2 purchases
  /// matching all parameters provided by the automatic in_app_purchase event.
  static Future<void> logIosPurchase({
    required Package package,
    required String planName,
  }) async {
    if (!Platform.isIOS) return;

    try {
      final double price = package.storeProduct.price;
      final String currency = package.storeProduct.currencyCode;
      final String productId = package.storeProduct.identifier;

      await _analytics.logPurchase(
        currency: currency,
        value: price,
        items: [
          AnalyticsEventItem(
            itemId: productId,
            itemName: planName,
            itemCategory: 'Subscription',
            price: price,
            quantity: 1,
          ),
        ],
      );
      print("Logged iOS purchase event successfully: $planName ($productId) -> $currency $price");
    } catch (e) {
      print("Error logging iOS purchase event: $e");
    }
  }
}
