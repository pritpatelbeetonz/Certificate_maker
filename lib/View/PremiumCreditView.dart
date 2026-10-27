import 'dart:io';
import 'package:certificate_maker/View/HomePage.dart';
import 'package:certificate_maker/for_ads/ads/app_open_ad.dart';
import 'package:certificate_maker/for_ads/ads/life_cycle.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:get/get.dart';
import '../for_ads/ads/ads_variable.dart';
import '../for_ads/utils/app_constants.dart';
import '../for_ads/utils/firebase_analysis.dart';
import 'privacy_policy_screen.dart';
import 'terms_and_condition_screen.dart';
import '../for_ads/utils/shared_prefrence_service.dart';

class PremiumCreditView extends StatefulWidget {
  final bool onboarding;
  final Function onDone;

  const PremiumCreditView({key, required this.onboarding, required this.onDone}) : super(key: key);

  @override
  State<PremiumCreditView> createState() => _PremiumCreditViewState();
}

class _PremiumCreditViewState extends State<PremiumCreditView> {
  int selectedPlan = 0; // 0 = Annual, 1 = Weekly
  Package? annualPackage;
  Package? weeklyPackage;
  bool _isLoadingPlans = true;
  bool _isPurchasing = false;

  AppOpenAdManager appOpenAdManager = AppOpenAdManager();
  late AppLifecycleReactor _appLifecycleReactor;
  bool _hasInternet = true;

  Package? get selectedPackage => selectedPlan == 0 ? annualPackage : weeklyPackage;
  bool get _hasPlans => annualPackage != null || weeklyPackage != null;

  @override
  void initState() {
    if (widget.onboarding) {
      FirebaseAnalyticsService.logEvent(eventName: 'PREMIUM_SCREEN_FROM_INTRO_SCREEN');
    } else {
      FirebaseAnalyticsService.logEvent(eventName: 'PREMIUM_SCREEN_FROM_OTHER_PAGES');
    }

    // Show the packages cached at splash right away, then refresh from the store.
    final cached = GlobalVariables.availablePackages?.values.toList() ?? [];
    if (cached.isNotEmpty) {
      _applyPackages(cached);
      _isLoadingPlans = false;
    }

    isInternetConnected();
    PackageData();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      _appLifecycleReactor = AppLifecycleReactor(appOpenAdManager: appOpenAdManager);
      _appLifecycleReactor.listenToAppStateChanges(shouldShow: false);
    });

    super.initState();
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
              // 1. Collage background at top half
              Positioned.fill(child: Image.asset("assets/Premium/bg.png", fit: BoxFit.cover)),

              // 2. Scrollable Body Contents
              Positioned.fill(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top + 280.h),
                      // Title
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Text(
                          'Create Without Limits',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 26.sp, color: Colors.black, fontWeight: FontWeight.w600, fontFamily: 'Inter', letterSpacing: -0.5),
                        ),
                      ),
                      SizedBox(height: 8.h),

                      // Subtitle
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Text(
                          "Unlock premium editing and templates.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w400, color: Colors.black.withValues(alpha: 0.7), fontFamily: 'Inter'),
                        ),
                      ),
                      SizedBox(height: 28.h),

                      // 3. Features Card (rounded with thin border)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10.w),
                                    width: 40.w,
                                    height: 40.w,
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(9999.r), color: Color(0xFF4200AD).withValues(alpha: 0.1)),
                                    child: Image.asset("assets/Premium/2.png"),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    "Custom\nBranding",
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.sp),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10.w),
                                    width: 40.w,
                                    height: 40.w,
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(9999.r), color: Color(0xFF4200AD).withValues(alpha: 0.1)),
                                    child: Image.asset("assets/Premium/3.png"),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    "Premium\nTemplates",
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.sp),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10.w),
                                    width: 40.w,
                                    height: 40.w,
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(9999.r), color: Color(0xFF4200AD).withValues(alpha: 0.1)),
                                    child: Image.asset("assets/Premium/4.png"),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    "Ad-Free\nExperience",
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.sp),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      if (_hasInternet && (_isLoadingPlans || _hasPlans)) ...[
                        // 4. Subscription Plan Cards Row
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Row(
                            children: [
                              if (_isLoadingPlans && !_hasPlans) ...[
                                Expanded(child: _planCardShimmer()),
                                SizedBox(width: 12.w),
                                Expanded(child: _planCardShimmer()),
                              ] else ...[
                                if (annualPackage != null)
                                  Expanded(
                                    child: _planCard(
                                      index: 0,
                                      title: "Annual Plan",
                                      price: annualPackage!.storeProduct.priceString,
                                      period: '/year',
                                      subtitle: _annualPerWeekPrice() != null ? "${_annualPerWeekPrice()} / week" : "Best Value",
                                      ribbonText: _savePercent() > 0 ? "SAVE ${_savePercent()}%" : null,
                                    ),
                                  ),
                                if (annualPackage != null && weeklyPackage != null) SizedBox(width: 12.w),
                                if (weeklyPackage != null)
                                  Expanded(
                                    child: _planCard(
                                      index: 1,
                                      title: "Weekly Plan",
                                      price: weeklyPackage!.storeProduct.priceString,
                                      period: '/week',
                                      subtitle: "Cancel Anytime",
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: 30.h),

                        // 5. Upgrade Button
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: GestureDetector(
                            onTap: _getPremiumVersion,
                            child: Container(
                              height: 56.h,
                              width: double.infinity,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16.r),
                                color: const Color(0xFF4200AD),
                                boxShadow: [BoxShadow(color: const Color(0xFF6F5BFF).withOpacity(0.6), blurRadius: 24, spreadRadius: 2)],
                              ),
                              child: Text(
                                _hasFreeTrial(selectedPackage) ? "Start Free Trial" : "Upgrade to Premium",
                                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Inter'),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Premium Offline Card
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Container(
                            padding: EdgeInsets.all(24.r),
                            decoration: BoxDecoration(
                              color: const Color(0xFF101012),
                              borderRadius: BorderRadius.circular(24.r),
                              border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.0),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.wifi_off_rounded, color: Colors.white54, size: 40),
                                SizedBox(height: 12.h),
                                Text(
                                  _hasInternet ? "Plans are unavailable right now" : "Plans are unavailable offline",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  _hasInternet
                                      ? "We couldn't load the subscription plans. Please try again."
                                      : "Please connect to the internet to purchase premium subscriptions.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white54, fontSize: 13.sp, fontFamily: 'Inter'),
                                ),
                                SizedBox(height: 20.h),
                                GestureDetector(
                                  onTap: () {
                                    isInternetConnected();
                                    PackageData();
                                  },
                                  child: Container(
                                    height: 40.h,
                                    width: 120.w,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(color: const Color(0xFF4200AD), borderRadius: BorderRadius.circular(20.r)),
                                    child: Text(
                                      "Try Again",
                                      style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 5.h),

                      // 6. Terms & Privacy policy footer
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(fontSize: 12.sp, color: Colors.black, height: 1.5, fontFamily: 'Inter'),
                            children: [
                              const TextSpan(text: 'by continue, you accept our '),
                              TextSpan(
                                text: 'terms of use',
                                style: const TextStyle(color: Colors.black, decoration: TextDecoration.underline, fontWeight: FontWeight.w600),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Get.to(() => const TermsAndConditionView());
                                  },
                              ),
                              const TextSpan(text: ' & '),
                              TextSpan(
                                text: 'privacy policy',
                                style: const TextStyle(color: Colors.black, decoration: TextDecoration.underline, fontWeight: FontWeight.w600),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // Open privacy policy view
                                    Get.to(() => const PrivacyPolicyView());
                                  },
                              ),
                              TextSpan(text: '\n${_renewalTerms()}'),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 30.h),
                    ],
                  ),
                ),
              ),

              // 7. Top Navigation Bar (Back and Restore)
              Positioned(
                top: MediaQuery.of(context).padding.top + 10.h,
                left: 16.w,
                right: 16.w,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (widget.onboarding) {
                          Get.offAll(() => Homepage());
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        width: 36.w,
                        height: 36.w,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withValues(alpha: 0.4)),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    GestureDetector(
                      onTap: _restorePurchases,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(16.r)),
                        child: Text(
                          "Restore",
                          style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Keeps only the two plans sold on this screen: Annual and Weekly.
  void _applyPackages(List<Package> packages) {
    annualPackage = _firstWhereOrNull(packages, (p) => p.packageType == PackageType.annual);
    weeklyPackage = _firstWhereOrNull(packages, (p) => p.packageType == PackageType.weekly);
    if (annualPackage == null && weeklyPackage != null) {
      selectedPlan = 1;
    } else if (weeklyPackage == null) {
      selectedPlan = 0;
    }
  }

  Future<void> PackageData() async {
    if (mounted && !_hasPlans) {
      setState(() => _isLoadingPlans = true);
    }
    try {
      final offerings = await Purchases.getOfferings();
      final packages = offerings.current?.availablePackages ?? [];
      GlobalVariables.availablePackages = {for (var package in packages) package.identifier: package};

      if (mounted) {
        setState(() {
          _hasInternet = true;
          _applyPackages(packages);
        });
      }
    } on PlatformException catch (_) {
      if (mounted) {
        setState(() {
          _hasInternet = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingPlans = false);
      }
    }
  }

  void isInternetConnected() async {
    final result = await Connectivity().checkConnectivity();
    if (!mounted) return;
    if (result.contains(ConnectivityResult.none)) {
      setState(() {
        _hasInternet = false;
      });
      Fluttertoast.showToast(msg: "No Internet Connection Found", toastLength: Toast.LENGTH_LONG, backgroundColor: Colors.white, textColor: Colors.black);
    } else {
      setState(() {
        _hasInternet = true;
      });
    }
  }

  void _showLoadingDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            contentPadding: EdgeInsets.zero,
            content: Center(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 30.w),
                decoration: BoxDecoration(color: const Color(0xFF141416), borderRadius: BorderRadius.circular(16.r)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 24.w,
                      height: 24.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6F5BFF)),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Text(
                      "Loading...",
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Inter'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _hideLoadingDialog() {
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _getPremiumVersion() async {
    if (_isPurchasing) return;
    final package = selectedPackage;
    if (package == null) {
      Fluttertoast.showToast(msg: "Store is currently unavailable. Try again later.");
      return;
    }

    _isPurchasing = true;
    _showLoadingDialog();

    bool purchaseCompleted = false;
    bool entitlementActive = false;
    bool alreadyOwned = false;
    try {
      final purchaseResult = await Purchases.purchase(PurchaseParams.package(package));
      purchaseCompleted = true;
      entitlementActive = purchaseResult.customerInfo.entitlements.all[entitlementKey]?.isActive ?? false;
    } on PlatformException catch (e) {
      switch (PurchasesErrorHelper.getErrorCode(e)) {
        case PurchasesErrorCode.purchaseCancelledError:
          break;
        case PurchasesErrorCode.paymentPendingError:
          Fluttertoast.showToast(msg: "Payment is pending approval. Premium will unlock once it's approved.");
          break;
        case PurchasesErrorCode.productAlreadyPurchasedError:
          alreadyOwned = true;
          break;
        case PurchasesErrorCode.networkError:
          Fluttertoast.showToast(msg: "Check your internet connection and try again.");
          break;
        default:
          Fluttertoast.showToast(msg: "Purchase failed. Please try again.");
      }
    } finally {
      _isPurchasing = false;
      _hideLoadingDialog();
    }

    if (entitlementActive) {
      await _activatePremium(fromPurchase: true);
    } else if (alreadyOwned) {
      await _restorePurchases();
    } else if (purchaseCompleted) {
      Fluttertoast.showToast(msg: "Purchase received, but premium isn't active yet. Tap Restore to try again.");
    }
  }

  Future<void> _restorePurchases() async {
    if (_isPurchasing) return;
    _isPurchasing = true;
    _showLoadingDialog();

    bool restored = false;
    bool failed = false;
    try {
      final restoredInfo = await Purchases.restorePurchases();
      restored = restoredInfo.entitlements.all[entitlementKey]?.isActive == true;
    } catch (_) {
      failed = true;
    } finally {
      _isPurchasing = false;
      _hideLoadingDialog();
    }

    if (restored) {
      Fluttertoast.showToast(msg: "Premium restored!", backgroundColor: const Color(0xFF6F5BFF), textColor: Colors.white);
      await _activatePremium(fromPurchase: false);
    } else {
      Fluttertoast.showToast(msg: failed ? "Restore failed. Please try again." : "No active subscription found.");
    }
  }

  /// Unlocks premium and closes the screen. Revenue analytics are logged only for a
  /// new purchase, never for a restore.
  Future<void> _activatePremium({required bool fromPurchase}) async {
    AdsVariable.resetAdIds();
    AdsVariable.isPurchase = true;
    await SharedPrefService.sharedPreferences.setBool('is_premium_active', true);

    if (fromPurchase) {
      final bool isAnnual = selectedPlan == 0;
      FirebaseAnalyticsService.logEvent(eventName: isAnnual ? 'YEAR_PLAN_PURCHASE' : 'WEEK_PLAN_PURCHASE');

      // iOS-only standard GA4 purchase event with full parameters
      final package = selectedPackage;
      if (package != null) {
        FirebaseAnalyticsService.logIosPurchase(package: package, planName: isAnnual ? 'Annual' : 'Weekly');
      }

      Fluttertoast.showToast(msg: 'Successfully upgraded to Premium!', backgroundColor: const Color(0xFF6F5BFF), textColor: Colors.white);
    } else {
      FirebaseAnalyticsService.logEvent(eventName: 'PREMIUM_RESTORED');
    }

    if (!mounted) return;
    if (widget.onboarding) {
      Get.offAll(() => Homepage());
    } else {
      // The caller gets `true` back and refreshes its premium badges.
      Navigator.of(context).pop(true);
    }
  }

  Package? _firstWhereOrNull(Iterable<Package> list, bool Function(Package) test) {
    for (final element in list) {
      if (test(element)) return element;
    }
    return null;
  }

  /// Annual price divided by 52, written in the same currency format as the store price.
  String? _annualPerWeekPrice() {
    final annual = annualPackage?.storeProduct;
    if (annual == null || annual.price <= 0) return null;
    final double perWeek = annual.price / 52;
    final String amount = perWeek.toStringAsFixed(perWeek < 10 ? 2 : 0);
    final match = RegExp(r'\d[\d.,\s ]*\d|\d').firstMatch(annual.priceString);
    if (match == null) return "${annual.currencyCode} $amount";
    return annual.priceString.replaceRange(match.start, match.end, amount);
  }

  /// How much cheaper Annual is than paying Weekly for 52 weeks.
  int _savePercent() {
    final annual = annualPackage?.storeProduct.price;
    final weekly = weeklyPackage?.storeProduct.price;
    if (annual == null || weekly == null || weekly <= 0) return 0;
    return ((1 - annual / (weekly * 52)) * 100).round();
  }

  bool _hasFreeTrial(Package? package) {
    final intro = package?.storeProduct.introductoryPrice;
    return intro != null && intro.price == 0;
  }

  String _renewalTerms() {
    final String store = Platform.isIOS ? 'App Store' : 'Google Play';
    return 'Subscription auto-renews until cancelled in your $store settings.';
  }

  Widget _planCardShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE5E5E7),
      highlightColor: const Color(0xFFF5F5F7),
      child: Container(
        height: 150.h,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
      ),
    );
  }

  Widget _planCard({
    required int index,
    required String title,
    required String price,
    required String period,
    required String subtitle,
    String? ribbonText,
  }) {
    final bool selected = selectedPlan == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlan = index;
        });
      },
      child: Container(
        height: 150.h,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: selected ? const Color(0xFF4200AD) : Color(0xFFE5E5E7), width: 2.w),
          boxShadow: selected ? [BoxShadow(color: const Color(0xFF2265FB).withOpacity(0.6), blurRadius: 15, spreadRadius: 1)] : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14.r),
          child: Stack(
            children: [
              // Main content
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 40.h, 16.w, 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: Colors.black, fontFamily: 'Inter'),
                    ),
                    Spacer(),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: price,
                              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700, color: Colors.black, fontFamily: 'Inter'),
                            ),
                            TextSpan(
                              text: period,
                              style: TextStyle(color: Colors.black45, fontSize: 13.sp, fontWeight: FontWeight.w400, fontFamily: 'Inter'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Spacer(),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: selected ? const Color(0xFF4200AD) : Colors.black38,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // SAVE X% ribbon (top left)
              if (ribbonText != null)
                Positioned(
                  top: 10.h,
                  left: 10.w,
                  child: Container(
                    width: 72.w,
                    height: 23.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.r),
                      gradient: LinearGradient(colors: [Color(0xFF2265FB), Color(0xFF8E86BE)]),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      ribbonText,
                      style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Inter'),
                    ),
                  ),
                ),
              Positioned(
                right: 10.w,
                top: 10.h,
                child: selected ? Image.asset("assets/Premium/check mark.png", width: 23.w, height: 23.w) : SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
