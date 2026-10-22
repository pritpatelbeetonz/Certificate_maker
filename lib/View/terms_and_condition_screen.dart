import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../for_ads/utils/firebase_analysis.dart';

class TermsAndConditionView extends StatefulWidget {
  final String? url;
  const TermsAndConditionView({super.key, this.url});

  @override
  State<TermsAndConditionView> createState() => _TermsAndConditionViewState();
}

class _TermsAndConditionViewState extends State<TermsAndConditionView> {
  late WebViewController controller;
  RxBool isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    FirebaseAnalyticsService.logEvent(eventName: 'TERMS_AND_CONDITION_SCREEN');
    try {
      final String targetUrl = widget.url ??
          (Platform.isAndroid
              ? 'https://nidhirola.blogspot.com/2025/01/privacy-policy.html'
              : 'https://nidhirola.blogspot.com/2025/01/privacy-policy.html');

      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..enableZoom(true)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              setState(() {
                isLoading.value = true;
              });
            },
            onPageFinished: (url) {
              setState(() {
                isLoading.value = false;
              });
              injectDarkCss();
            },
          ),
        )
        ..loadRequest(Uri.parse(targetUrl));
      controller.setBackgroundColor(Colors.white);
    } catch (e) {
      log("Webview Error :- $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: SafeArea(
        top: false,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 35.w,
                  height: 35.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
            title: Text(
              'Terms & Conditions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
            ),
            centerTitle: true,
          ),
          body: Obx(
            () => isLoading.value
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF7C4DFF)),
                  )
                : WebViewWidget(controller: controller),
          ),
        ),
      ),
    );
  }

  void injectDarkCss() {
    controller.runJavaScript("""
    (function() {
      var style = document.createElement('style');
      style.type = 'text/css';
      style.innerHTML = `
        html, body {
          background-color: #14151A !important;
          color: #ffffff !important;
        }
        * {
          color: #ffffff !important;
          background-color: transparent !important;
        }
        a { color: #4da6ff !important; }
      `;
      document.head.appendChild(style);
    })();
  """);
  }
}
