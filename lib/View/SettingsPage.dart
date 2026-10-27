import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../for_ads/utils/app_constants.dart';
import 'PremiumCreditView.dart';
import 'contact_support_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_and_condition_screen.dart';
import '../for_ads/ads/ads_variable.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> rateUs(BuildContext context) async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String packageName = packageInfo.packageName;
      if (Platform.isIOS) {
        final String url = 'https://apps.apple.com/app/id$iosAppId';
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch App Store.';
        }
      } else {
        final String url = 'market://details?id=$packageName';
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } else {
          final String webUrl = 'https://play.google.com/store/apps/details?id=$packageName';
          if (await canLaunchUrl(Uri.parse(webUrl))) {
            await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
          } else {
            throw 'Could not launch Play Store.';
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        Fluttertoast.showToast(msg: 'Error: $e', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
      }
    }
  }

  Future<void> shareApp(BuildContext context) async {
    try {
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      final Rect? sharePositionOrigin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;
      final packageInfo = await PackageInfo.fromPlatform();
      final packageName = packageInfo.packageName;

      if (Platform.isIOS) {
        final url = 'https://apps.apple.com/app/id$iosAppId';
        await Share.share(url, sharePositionOrigin: sharePositionOrigin);
      } else {
        final url = 'https://play.google.com/store/apps/details?id=$packageName';
        await Share.share(url, sharePositionOrigin: sharePositionOrigin);
      }
    } catch (e) {
      if (context.mounted) {
        Fluttertoast.showToast(msg: 'Error: $e', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
      }
    }
  }

  Future<void> moreAppOnTap() async {
    if (Platform.isIOS) {
      const String appStoreURL = 'https://apps.apple.com/us/developer/nidhi-rola/id1791680431';
      if (await canLaunchUrl(Uri.parse(appStoreURL))) {
        log("========== LAUNCH URL ==============");
        await launchUrl(Uri.parse(appStoreURL));
      } else {
        log("Could not launch $appStoreURL");
        throw 'Could not launch $appStoreURL';
      }
    } else {
      const String storeURL = 'https://play.google.com/store/apps/developer?id=Pahal+Tech';
      if (await canLaunchUrl(Uri.parse(storeURL))) {
        await launchUrl(Uri.parse(storeURL));
      } else {
        throw 'Could not launch $storeURL';
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, top: 16.h, bottom: 8.h),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8), letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildNewSettingsItem({required String iconPath, required String title, required VoidCallback onTap, BorderRadius? borderRadius}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        splashColor: const Color(0xFF6F5BFF).withOpacity(0.12),
        highlightColor: const Color(0xFF6F5BFF).withOpacity(0.06),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            children: [
              Image.asset(iconPath, width: 24.w, height: 24.w, fit: BoxFit.contain),
              SizedBox(width: 14.w),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF0F172A), fontFamily: 'Inter'),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
            ],
          ),
        ),
      ),
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
          style: TextStyle(color: const Color(0xFF0F172A), fontSize: 18.sp, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Premium Banner
            if (!AdsVariable.isPurchase) ...{
              Container(
                height: 140.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  image: const DecorationImage(image: AssetImage('assets/Settings/banner.png'), fit: BoxFit.cover),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Unlock Premium',
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A), fontFamily: 'Inter'),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Enjoy unlimited access and premium tools.',
                      style: TextStyle(fontSize: 12.sp, color: const Color(0xFF64748B), fontFamily: 'Inter'),
                    ),
                    const Spacer(),
                    Material(
                      color: const Color(0xFF4200AD),
                      borderRadius: BorderRadius.circular(20.r),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20.r),
                        splashColor: Colors.white.withOpacity(0.2),
                        highlightColor: Colors.white.withOpacity(0.1),
                        onTap: () {
                          Get.to(() => PremiumCreditView(onboarding: false, onDone: () {}));
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Go Premium',
                                style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                              ),
                              SizedBox(width: 6.w),
                              Icon(Icons.arrow_forward, color: Colors.white, size: 14.w),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            },

            _buildSectionHeader('General'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Column(
                  children: [
                    _buildNewSettingsItem(
                      iconPath: 'assets/Settings/rate.png',
                      title: 'Rate App',
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                      onTap: () => rateUs(context),
                    ),
                    Divider(height: 1, thickness: 1, color: const Color(0xFFF1F5F9), indent: 54.w),
                    _buildNewSettingsItem(iconPath: 'assets/Settings/share_app.png', title: 'Share App', onTap: () => shareApp(context)),
                    Divider(height: 1, thickness: 1, color: const Color(0xFFF1F5F9), indent: 54.w),
                    _buildNewSettingsItem(
                      iconPath: 'assets/Settings/moreApps.png',
                      title: 'More Apps',
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(16.r)),
                      onTap: moreAppOnTap,
                    ),
                  ],
                ),
              ),
            ),

            _buildSectionHeader('Legal'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Column(
                  children: [
                    _buildNewSettingsItem(
                      iconPath: 'assets/Settings/privacyPolicy.png',
                      title: 'Privacy Policy',
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                      onTap: () {
                        Get.to(() => const PrivacyPolicyView());
                      },
                    ),
                    Divider(height: 1, thickness: 1, color: const Color(0xFFF1F5F9), indent: 54.w),
                    _buildNewSettingsItem(
                      iconPath: 'assets/Settings/privacyPolicy.png',
                      title: 'Terms of Use',
                      onTap: () {
                        Get.to(() => const TermsAndConditionView());
                      },
                    ),
                    Divider(height: 1, thickness: 1, color: const Color(0xFFF1F5F9), indent: 54.w),
                    _buildNewSettingsItem(
                      iconPath: 'assets/Settings/contanct_support.png',
                      title: 'Contact Support',
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(16.r)),
                      onTap: () {
                        Get.to(() => const ContactSupportScreen());
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
