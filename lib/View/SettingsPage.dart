import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../for_ads/ads/ads_variable.dart';
import 'PremiumCreditView.dart';
import 'privacy_policy_screen.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _shareApp(BuildContext context) {
    Clipboard.setData(const ClipboardData(
        text: 'Check out this awesome Certificate Maker App! https://apps.apple.com/app/id64748B'));
    Fluttertoast.showToast(msg: "App sharing link copied to clipboard!");
  }

  void _rateUs() async {
    final InAppReview inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      inAppReview.requestReview();
    } else {
      Fluttertoast.showToast(msg: "Rating is not available right now.");
    }
  }

  void _contactUs() async {
    final email = AdsVariable.supportContactEmail;
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Certificate Maker Support Request',
      },
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      Fluttertoast.showToast(msg: "Could not launch email app. Support: $email");
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, top: 16.h, bottom: 8.h),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF94A3B8),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildNewSettingsItem({
    required String iconPath,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
      leading: Image.asset(
        iconPath,
        width: 24.w,
        height: 24.w,
        fit: BoxFit.contain,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF0F172A),
          fontFamily: 'Inter',
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFFCBD5E1),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Get.back(),
        ),
        titleSpacing: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            color: const Color(0xFF0F172A),
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Premium Banner
            Container(
              height: 140.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                image: const DecorationImage(
                  image: AssetImage('assets/Settings/banner.png'),
                  fit: BoxFit.cover,
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Unlock Premium',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                      fontFamily: 'Inter',
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Enjoy unlimited access and premium tools.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF64748B),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Get.to(() => PremiumCreditView(onboarding: false, onDone: () {}));
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4200AD),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Go Premium',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 14.w,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            _buildSectionHeader('General'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildNewSettingsItem(
                    iconPath: 'assets/Settings/rate.png',
                    title: 'Rate App',
                    onTap: _rateUs,
                  ),
                  _buildNewSettingsItem(
                    iconPath: 'assets/Settings/share_app.png',
                    title: 'Share App',
                    onTap: () => _shareApp(context),
                  ),
                  _buildNewSettingsItem(
                    iconPath: 'assets/Settings/moreApps.png',
                    title: 'More Apps',
                    onTap: () {
                      Fluttertoast.showToast(msg: "Discover more apps coming soon!");
                    },
                  ),
                  _buildNewSettingsItem(
                    iconPath: 'assets/Settings/requestfeature.png',
                    title: 'Request a Feature',
                    onTap: () {
                      Fluttertoast.showToast(msg: "Feature request support is coming soon!");
                    },
                  ),
                ],
              ),
            ),

            _buildSectionHeader('Legal'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildNewSettingsItem(
                    iconPath: 'assets/Settings/privacyPolicy.png',
                    title: 'Privacy Policy',
                    onTap: () {
                      Get.to(() => const PrivacyPolicyView());
                    },
                  ),
                  _buildNewSettingsItem(
                    iconPath: 'assets/Settings/contanct_support.png',
                    title: 'Contact Support',
                    onTap: _contactUs,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
