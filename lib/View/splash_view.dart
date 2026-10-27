import 'dart:developer';
import 'package:certificate_maker/View/HomePage.dart';
import 'package:certificate_maker/View/welcomePageView.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:lottie/lottie.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../for_ads/ads/ads_splash_utils.dart';
import '../../for_ads/ads/ads_variable.dart';
import '../../for_ads/utils/app_constants.dart';
import '../../for_ads/utils/firebase_analysis.dart';
import '../../for_ads/utils/shared_prefrence_service.dart';
import 'PremiumCreditView.dart';
import 'SurveyScreen.dart';

import 'widgets/no_internet_dialog.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    debugPrint("*****///***** adsvarible === ${AdsVariable.isPurchase}......");
    WidgetsBinding.instance.addPostFrameCallback((callback) async {
      FirebaseAnalyticsService.logEvent(eventName: 'SPLASH_SCREEN');
      _startSplashInitialization();
    });
  }

  Future<void> _startSplashInitialization() async {
    final bool isOnline = await AdsVariable.isInternetConnected();
    if (!isOnline && mounted) {
      _showNoInternetDialog();
      return;
    }
    _runSplashOnlineIds();
  }

  Future<void> _runSplashOnlineIds() async {
    await AdsSplashUtils().getOnlineIds(
      navigateScreen: () async {
        log('navigate screen');
        fetchData();
        navigatingToNextActivity();
      },
    );
  }

  void _showNoInternetDialog() {
    if (_isDialogShowing || !mounted) return;
    _isDialogShowing = true;

    NoInternetDialog.show(
      context,
      onRetry: () async {
        if (_isDialogShowing && mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          _isDialogShowing = false;
        }
        // Small delay to let dialog dismiss smoothly before re-checking
        await Future.delayed(const Duration(milliseconds: 250));
        if (mounted) {
          _startSplashInitialization();
        }
      },
      onCancel: () {
        if (_isDialogShowing && mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          _isDialogShowing = false;
        }
        // User chooses Cancel/Continue: don't get stuck, navigate to app
        fetchData();
        navigatingToNextActivity();
      },
    );
  }

  void navigatingToNextActivity() async {
    bool isFirstLaunch = SharedPrefService.getIsFirstTime();
    if (isFirstLaunch) {
      AdsVariable.showSurveyScreen ? Get.off(SurveyForm()) : Get.off(WelPageview()); //SurveyForm()
    } else {
      if (AdsVariable.isPurchase) {
        Get.offAll(() => Homepage());
      } else {
        Get.offAll(() => PremiumCreditView(onboarding: true, onDone: () {}));
      }
    }
  }

  Future<void> fetchData() async {
    print("get price");
    Offerings? offerings;
    try {
      offerings = await Purchases.getOfferings();
      if (kDebugMode) {
        print(offerings);
      }

      GlobalVariables.availablePackages = {for (var package in offerings.current?.availablePackages ?? []) package.identifier: package};
      print(GlobalVariables.availablePackages);
      void printLongString(String text) {
        final pattern = RegExp('.{1,800}'); // Splits the string every 800 characters
        pattern.allMatches(text).forEach((match) => print(match.group(0)));
      }

      // Usage
      printLongString("availablePackages ********** ${GlobalVariables.availablePackages}");

      // print(
      //     "availablePackages ********** ${GlobalVariables.availablePackages}");

      if ((GlobalVariables.availablePackages?.entries ?? []).length >= 2) {}
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("get error");

        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            children: [
              Image.asset("assets/Splash Screen/Splash Screen.png", fit: BoxFit.cover, width: double.infinity, height: double.infinity),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset("assets/Splash Screen/ic.png", width: 100.w, height: 100.w),
                    SizedBox(height: 14.h),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Certificate Maker",
                          style: TextStyle(fontSize: 30.sp, color: Colors.black, fontFamily: 'Inter', fontWeight: FontWeight.w700),
                        ),
                        // SizedBox(height: 4.h),
                        // Text(
                        //   "Where Memories Meet Design",
                        //   style: TextStyle(
                        //     color: Colors.black,
                        //     fontSize: 14.sp,
                        //     fontWeight: FontWeight.w300,
                        //     fontFamily: 'Inter',
                        //   ),
                        // ),
                        // SizedBox(height: 5.h),
                      ],
                    ),
                  ],
                ),
              ),
              // Positioned(
              //   left: 0,
              //   right: 0,
              //   bottom: 10.h,
              //   child: Center(
              //     child: Lottie.asset(
              //       "assets/Splash Screen/vtV06TU06B.json",
              //       width: 300.w, // adjust as needed
              //       height:15.h, // adjust as needed
              //       fit: BoxFit.contain,
              //       repeat: true,
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
