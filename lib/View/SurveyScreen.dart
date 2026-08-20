import 'package:certificate_maker/View/welcomePageView.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../for_ads/ads/ads_load_util.dart';
import '../../for_ads/ads/ads_splash_utils.dart';
import '../../for_ads/ads/ads_variable.dart';
import '../../for_ads/utils/firebase_analysis.dart';

enum UsageLocation { home, office, onTheGo, publicSpaces }

class SurveyForm extends StatefulWidget {

  const SurveyForm({super.key,});

  @override
  State<SurveyForm> createState() => SurveyFormState();
}

class SurveyFormState extends State<SurveyForm> {
  UsageLocation? selectedLocation = UsageLocation.home;

  @override
  void initState() {
    FirebaseAnalyticsService.logEvent(eventName: 'SURVEYSCREEN');
    super.initState();
    checkInterNetConnectivity();
  }

  bool isInterNetConnected = false;

  Future<void> checkInterNetConnectivity() async {
    if (await AdsVariable.isInternetConnected()) {
      setState(() {
        isInterNetConnected = true;
        print('=>>>> Internet Connected');
      });
      loadPreLoadIntroFullNativeAds();
    }
  }

  int selectedIndex = -1;

  //---------------------------------------------------------------main Scafold ---------------------------------------------
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Color(0xFFf8f9fa),
        bottomNavigationBar: SafeArea(
          child: (AdsVariable.isPurchase == false)
              ? isInterNetConnected
                    ? selectedIndex == -1
                        ? SurveyBigNativeAds1(
                            showNativeAd: AdsVariable.nativeBigAdSurvey1,
                            isBigNative: true,
                            isNativeAdLoaded:
                                AdsLoadUtil.isBigNativeSurveyAdLoaded1,
                            isNativeAdFailedToLoad:
                                AdsLoadUtil.isNativeAdFailedToLoadBigSurvey1,
                          )
                        : SurveyBigNativeAds2(
                            showNativeAd: AdsVariable.nativeBigAdSurvey2,
                            isBigNative: true,
                            isNativeAdLoaded:
                                AdsLoadUtil.isBigNativeSurveyAdLoaded2,
                            isNativeAdFailedToLoad:
                                AdsLoadUtil.isNativeAdFailedToLoadBigSurvey2,
                          )
                    : const SizedBox()
              : const SizedBox(),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 0.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10.h,),
                  /// Title
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      children: [
                        //SizedBox(height: 10.h,),
                        Text(
                          "How do you usually create\n certificates ?",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                            color: Colors.black,
                          ),
                        ),
                          Spacer(),
                          Visibility(
                            visible:selectedIndex != -1,
                            replacement: SizedBox(height: 36.h,),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        WelPageview(),
                                  ),
                                );
                              },
                              child: Container(
                                width: 68.w,
                                height: 36.h,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                 color: Color(0xFF4200AD),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  "Done",
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Inter',
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
  
                  SizedBox(height: 10.h),
  
                  Column(
                    children: [
                      /// OPTIONS
                      SurveyOption(
                        title: "Use a Template",
                        index: 0,
                        selectedIndex: selectedIndex,
                        onTap: () {
                          setState(() {
                            selectedIndex = 0;
                          });
                        },
                        image: "assets/Survay/Frame 1.png",
                        subtitle: "Start with a ready-made design",
                      ),
                     SizedBox(height: 10.h),
                      SurveyOption(
                        title: "Edit Manually",
                        index: 1,
                        selectedIndex: selectedIndex,
                        onTap: () {
                          setState(() {
                            selectedIndex = 1;
                          });
                        },
                        image: "assets/Survay/Frame 2.png",
                        subtitle: "Customize every detail yourself",
                      ),
                      SizedBox(height: 10.h),
                      SurveyOption(
                        title: "Personalize the Design",
                        index: 2,
                        selectedIndex: selectedIndex,
                        onTap: () {
                          setState(() {
                            selectedIndex = 2;
                          });
                        },
                        image: "assets/Survay/Frame 3.png",
                        subtitle: "Add logos, signatures and stickers",
                      ),
                      SizedBox(height: 10.h),
                      SurveyOption(
                        title: "Mix & Match",
                        index: 3,
                        selectedIndex: selectedIndex,
                        onTap: () {
                          setState(() {
                            selectedIndex = 3;
                          });
                        },
                        image: "assets/Survay/Frame 4.png",
                        subtitle: "Combine templates with your ideas",
                      ),
                    ],
                  )
  
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SurveyOption extends StatelessWidget {
  final String title;
  final int index;
  final int selectedIndex;
  final VoidCallback onTap;
  final String image;
  final String subtitle;

  const SurveyOption({
    super.key,
    required this.title,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
    required this.image,
    required this.subtitle
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        //height: 85.h,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white:Colors.white,
         // border: isSelected ? Border.all(color: Color(0xFFffc31f)):Border.all(color: Colors.transparent),
          borderRadius: BorderRadius.circular(20.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),

        child: Row(
          children: [
            ///image
            Container(
              padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9999.r),
                  color: Color(0xFFEFF6FF),
                ),
                child: Image.asset(image,width: 24.w,height: 24.w,)),

            SizedBox(width: 14.w),
            /// TEXT
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                      color: isSelected ? Colors.black : Colors.black,
                    ),
                  ),
                  SizedBox(height: 4.h,),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
                      color: isSelected ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3),
                    ),
                  )
                ],
              ),
            ),
            /// RADIO
            Padding(
              padding: EdgeInsetsGeometry.only(right: 10.w),
              child: Image.asset(
                isSelected
                    ? "assets/Survay/Frame 5.png"
                    : "assets/Survay/Border.png",
                height: 24.w,
                width: 24.w,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
