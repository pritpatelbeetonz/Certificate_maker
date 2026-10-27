import 'dart:async';
import 'package:certificate_maker/View/HomePage.dart';
import 'package:certificate_maker/for_ads/ads/ads_splash_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../for_ads/ads/ads_load_util.dart';
import '../../for_ads/ads/ads_variable.dart';
import '../../for_ads/utils/app_constants.dart';
import '../../for_ads/utils/firebase_analysis.dart';
import '../../for_ads/utils/ad_revenue_analytics_service.dart';
import '../../for_ads/widgets/loading_screen.dart';
import 'PremiumCreditView.dart';
import 'RatingScreen.dart';
import 'welcome1.dart';
import 'welcome2.dart';
import 'welcome3.dart';

class WelPageview extends StatefulWidget {
  const WelPageview({super.key});

  State<WelPageview> createState() => WelPageviewState();
}

class WelPageviewState extends State<WelPageview> {
  final PageController pageController = PageController(initialPage: 0);
  int currentIndex = 0;
  bool isInterNetConnected = false;
  bool _hasRequestedReview = false;

  // Intro AppOpen Ad state
  AppOpenAd? _introAppOpenAd;
  bool _isIntroAdLoading = false;
  bool _isShowingIntroAd = false;

  @override
  void initState() {
    super.initState();
    checkInterNetConnectivity();
    _preloadIntroAppOpenAd();
  }

  @override
  void dispose() {
    _introAppOpenAd?.dispose();
    pageController.dispose();
    super.dispose();
  }

  void _preloadIntroAppOpenAd() {
    if (AdsVariable.isPurchase || AdsVariable.appOpenAdsIOS == "11") {
      debugPrint("[IntroAppOpen] 👑 Premium user or dummy ad unit -> Skipping intro app open preload");
      return;
    }
    if (_introAppOpenAd != null || _isIntroAdLoading) {
      return;
    }
    _isIntroAdLoading = true;
    debugPrint("[IntroAppOpen] ⏳ Preloading App Open Ad from Intro 1... Unit: '${AdsVariable.appOpenAdsIOS}'");
    AppOpenAd.load(
      adUnitId: AdsVariable.appOpenAdsIOS,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _isIntroAdLoading = false;
          _introAppOpenAd = ad;
          debugPrint("[IntroAppOpen] 🟢 Intro App Open Ad preloaded and ready!");
        },
        onAdFailedToLoad: (error) {
          _isIntroAdLoading = false;
          _introAppOpenAd = null;
          debugPrint("[IntroAppOpen] 🔴 Intro App Open Ad preload failed: ${error.message}");
        },
      ),
    );
  }

  void _showIntroAppOpenAndProceed() {
    // If premium, proceed immediately
    if (AdsVariable.isPurchase || AdsVariable.appOpenAdsIOS == "11") {
      _navigateToPremium();
      return;
    }

    if (_isShowingIntroAd) return;

    // Case 1: Ad is already preloaded
    if (_introAppOpenAd != null) {
      debugPrint("[IntroAppOpen] 🚀 Preloaded ad available -> Showing immediately!");
      _displayAppOpenAd(_introAppOpenAd!);
      return;
    }

    // Case 2: Ad is still loading in-flight OR failed previously -> Show loader and load on the spot
    debugPrint("[IntroAppOpen] ⏳ Ad not ready yet -> Showing loader & waiting/fetching on the spot...");
    loadingScreen.show();
    bool hasTimedOut = false;
    Timer? timeoutTimer = Timer(const Duration(seconds: 4), () {
      hasTimedOut = true;
      debugPrint("[IntroAppOpen] ⏱️ Timeout reached (4s) -> Hiding loader and proceeding");
      loadingScreen.hide();
      _navigateToPremium();
    });

    AppOpenAd.load(
      adUnitId: AdsVariable.appOpenAdsIOS,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          if (hasTimedOut) {
            ad.dispose();
            return;
          }
          timeoutTimer.cancel();
          loadingScreen.hide();
          debugPrint("[IntroAppOpen] 🟢 On-the-spot App Open Ad loaded -> Showing now!");
          _displayAppOpenAd(ad);
        },
        onAdFailedToLoad: (error) {
          if (hasTimedOut) return;
          timeoutTimer.cancel();
          loadingScreen.hide();
          debugPrint("[IntroAppOpen] ❌ On-the-spot App Open Ad failed: ${error.message} -> Proceeding to Premium");
          _navigateToPremium();
        },
      ),
    );
  }

  void _displayAppOpenAd(AppOpenAd ad) {
    _isShowingIntroAd = true;
    ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
      AdRevenueAnalyticsService.trackAdImpression(
        ad: ad,
        valueMicros: valueMicros,
        precision: precision,
        currencyCode: currencyCode,
        placement: 'intro_app_open',
      );
    };
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint("[IntroAppOpen] 📺 App Open Ad showed full screen");
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint("[IntroAppOpen] 👋 App Open Ad dismissed -> Navigating to Premium");
        _isShowingIntroAd = false;
        ad.dispose();
        _introAppOpenAd = null;
        _navigateToPremium();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint("[IntroAppOpen] ❌ App Open Ad failed to show: $error -> Navigating to Premium");
        _isShowingIntroAd = false;
        ad.dispose();
        _introAppOpenAd = null;
        _navigateToPremium();
      },
    );
    ad.show();
  }

  void _navigateToPremium() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => PremiumCreditView(
          onboarding: true,
          onDone: () {
            Get.offAll(() => Homepage());
          },
        ),
      ),
      (route) => false,
    );
  }

  Future<void> checkInterNetConnectivity() async {
    if (await AdsVariable.isInternetConnected()) {
      setState(() {
        isInterNetConnected = true;
      });
      _preloadIntroAppOpenAd();
    }
  }

  static const int dataLength = 3;

  int GetDots(int length) {
    return 3;
  }

  int getDotIndex(int index, int length) {
    return index;
  }

  Widget bottomnavigation(int dataLength, int currentIndex) {
    final List<String> titles = ["Beautiful Templates", "Sign with Ease", "Style Your Certificate"];

    final List<String> Subtitles = [
      "Start with a professionally designed certificate.",
      "Draw your signature or import an existing one.",
      "Enhance your certificate with elegant stickers. ",
    ];

    final int dotIdx = currentIndex;

    return PopScope(
      canPop: false,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            height: 170.h,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  titles[dotIdx],
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black, fontSize: 28.sp, fontFamily: 'Inter', fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 5),
                //Spacer(),

                Text(
                  Subtitles[dotIdx],
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black.withValues(alpha: 0.8), fontSize: 14.sp, fontWeight: FontWeight.w400),
                ),

                // const SizedBox(height: 15),
                Spacer(),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final bool isActive = dotIdx == index;
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      width: isActive ? 24.w : 8.w,
                      height: 8.h,
                      decoration: BoxDecoration(
                        color: isActive ? Color(0xFF4200AD) : Color(0x1010104D).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    );
                  }),
                ),

                //const SizedBox(height: 15),
                Spacer(),

                //dots
                Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: GestureDetector(
                    onTap: () {
                      if (currentIndex == dataLength - 1) {
                        _showIntroAppOpenAndProceed();
                      } else {
                        pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                      }
                    },
                    child: Container(
                      alignment: Alignment.center,
                      width: 358.w,
                      height: 48.h,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.r), color: Color(0xFF4200AD)),
                      child: Text(
                        currentIndex == dataLength - 1 ? "Get Started" : 'Next',
                        style: TextStyle(fontSize: 14.sp, color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            children: [
              PageView(
                controller: pageController,
                onPageChanged: (index) {
                  setState(() {
                    currentIndex = index;
                  });
                  // Show review only once when Welcome2 is reached.
                  if (!_hasRequestedReview && index == 1) {
                    _hasRequestedReview = true;
                    AdsVariable.showRateUsDialogInIntro ? checkAndShowInAppReview('onboarding_rate_us') : null;
                  }
                },
                children: const [Welcome1(), Welcome2(), Welcome3()],
              ),

              Align(alignment: Alignment.bottomCenter, child: bottomnavigation(dataLength, currentIndex)),
            ],
          ),
        ),
      ),
    );
  }
}
