import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../for_ads/ads/ads_variable.dart';
import '../for_ads/utils/firebase_analysis.dart';

enum _Category {
  featureRequest('Feature Request', Icons.lightbulb_outline_rounded),
  bugReport('Bug Report', Icons.bug_report_outlined),
  premiumSupport('Premium Support', Icons.workspace_premium_outlined),
  general('General', Icons.chat_bubble_outline_rounded),
  other('Other', Icons.more_horiz_rounded);

  const _Category(this.label, this.icon);
  final String label;
  final IconData icon;
}

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  _Category _selected = _Category.general;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _error;
  bool _sending = false;

  static const int _maxChars = 2000;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseAnalyticsService.logEvent(eventName: 'CONTACT_SUPPORT_SCREEN');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _controller.text.trim();
    if (message.isEmpty) {
      setState(() => _error = 'Please write your message before submitting.');
      return;
    }
    setState(() {
      _error = null;
      _sending = true;
    });

    final String email = AdsVariable.supportContactEmail;
    final isPremium = AdsVariable.isPurchase;
    final tier = isPremium ? 'Premium' : 'Free';
    final subject = 'Certificate Maker Feedback · ${_selected.label} · $tier';
    final body = message;

    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: _encodeMailtoQuery({'subject': subject, 'body': body}),
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showFallbackSnackBar(email);
      }
    } catch (_) {
      if (mounted) _showFallbackSnackBar(email);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _encodeMailtoQuery(Map<String, String> params) {
    return params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }

  void _showFallbackSnackBar(String email) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E1E1E),
        content: Text(
          'No email client found. You can reach us at: $email',
          maxLines: 2,
          style: const TextStyle(color: Colors.white),
        ),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'OK',
          textColor: const Color(0xFF6F5BFF),
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final charCount = _controller.text.length;
    final isOverLimit = charCount > _maxChars;
    const accentColor = Color(0xFF6F5BFF);
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF64748B);
    const textMuted = Color(0xFF94A3B8);
    const borderColor = Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 35.w,
              height: 35.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Color(0xFF1E293B),
                size: 18,
              ),
            ),
          ),
        ),
        title: Text(
          'Contact Support',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textPrimary,
            fontFamily: 'Inter',
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => _focusNode.unfocus(),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
          children: [
            // ── Header illustration card ──────────────────────────────────
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.headset_mic_outlined,
                      color: accentColor,
                      size: 26,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "We're Here to Help",
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          "Send feedback, report issues, or request new features.",
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12.sp,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // ── Category label ────────────────────────────────────────────
            Text(
              "WHAT'S THIS ABOUT?",
              style: TextStyle(
                color: textMuted,
                letterSpacing: 0.8,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(height: 10.h),

            // ── Category chips (horizontal scroll) ────────────────────────
            SizedBox(
              height: 40.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: _Category.values.map((cat) {
                  final isActive = cat == _selected;
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFFF1EDFF) : Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: isActive ? accentColor : borderColor,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat.icon,
                              size: 16.w,
                              color: isActive ? accentColor : textSecondary,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              cat.label,
                              style: TextStyle(
                                color: isActive ? accentColor : textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13.sp,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            SizedBox(height: 20.h),

            // ── Message label ─────────────────────────────────────────────
            Text(
              'TELL US MORE',
              style: TextStyle(
                color: textMuted,
                letterSpacing: 0.8,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(height: 10.h),

            // ── Message text field ────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: _error != null
                      ? Colors.redAccent
                      : _focusNode.hasFocus
                          ? accentColor
                          : borderColor,
                  width: _focusNode.hasFocus || _error != null ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    minLines: 5,
                    maxLines: 12,
                    maxLength: _maxChars,
                    buildCounter:
                        (
                          _, {
                          required currentLength,
                          required isFocused,
                          required maxLength,
                        }) => null,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14.sp,
                      fontFamily: 'Inter',
                    ),
                    decoration: InputDecoration(
                      hintText:
                          "Describe the feature you'd love to see, the bug you found, or anything on your mind…",
                      hintStyle: TextStyle(
                        color: textMuted,
                        fontSize: 13.sp,
                        fontFamily: 'Inter',
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16.w),
                    ),
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  // Character counter
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$charCount / $_maxChars',
                          style: TextStyle(
                            color: isOverLimit
                                ? Colors.redAccent
                                : textMuted,
                            fontSize: 11.sp,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Inline error ──────────────────────────────────────────────
            if (_error != null) ...[
              SizedBox(height: 8.h),
              Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 14,
                    color: Colors.redAccent,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12.sp,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ],

            SizedBox(height: 12.h),

            // ── Subject preview ───────────────────────────────────────────
            Builder(
              builder: (ctx) {
                final isPremium = AdsVariable.isPurchase;
                final tier = isPremium ? 'Premium' : 'Free';
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.mail_outline_rounded,
                        size: 16,
                        color: textSecondary,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Subject: Certificate Maker Feedback · ${_selected.label} · $tier',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12.sp,
                            fontFamily: 'Inter',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            SizedBox(height: 6.h),
            Text(
              'You can edit the subject and body in your email app before sending.',
              style: TextStyle(
                color: textMuted,
                fontSize: 11.sp,
                fontFamily: 'Inter',
              ),
            ),

            SizedBox(height: 28.h),

            // ── Submit button ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton.icon(
                onPressed: (_sending || isOverLimit) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: accentColor.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                icon: _sending
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _sending ? 'Opening email…' : 'Open in Email App',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}
