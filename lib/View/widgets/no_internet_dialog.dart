import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NoInternetDialog extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const NoInternetDialog({
    super.key,
    required this.onRetry,
    required this.onCancel,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onRetry,
    required VoidCallback onCancel,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: NoInternetDialog(
          onRetry: onRetry,
          onCancel: onCancel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      backgroundColor: Colors.white,
      elevation: 8,
      insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Wi-Fi Alert Icon
            Image.asset(
              'assets/noInternet.png',
              width: 76.w,
              height: 60.h,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.wifi_off_rounded,
                  size: 56.sp,
                  color: const Color(0xFF2FA2FE),
                );
              },
            ),
            SizedBox(height: 24.h),

            // Title
            Text(
              'No Internet Connection',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                fontFamily: 'Inter',
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 10.h),

            // Subtitle
            Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF94A3B8),
                fontFamily: 'Inter',
                height: 1.35,
              ),
            ),
            SizedBox(height: 28.h),

            // Action Buttons Row: [ Cancel ] [ Try Again ]
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: SizedBox(
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: onCancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE5E7EB),
                        foregroundColor: const Color(0xFF1E293B),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 14.w),

                // Try Again Button
                Expanded(
                  child: SizedBox(
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: onRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B00B9),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        'Try Again',
                        style: TextStyle(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
