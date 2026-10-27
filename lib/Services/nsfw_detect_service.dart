import 'dart:convert';
import 'dart:io';
import 'package:certificate_maker/for_ads/ads/ads_variable.dart';
import 'package:certificate_maker/for_ads/utils/app_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:nsfw_detector_flutter/nsfw_detector_flutter.dart';
import 'package:path_provider/path_provider.dart';


class NsfwDetectService {
  static int nsfwBorderPercentage = 40;
  static bool _localDetectorInitialized = false;

  /// Optional: call in main()
  static Future<void> init() async {
    await _ensureLocalDetectorInitialized();
  }

  static Future<void> _ensureLocalDetectorInitialized() async {
    if (_localDetectorInitialized) return;
    await NsfwDetector.initialize();
    _localDetectorInitialized = true;
  }

  /// Returns:
  /// true  -> NSFW image
  /// false -> Safe image
  static Future<bool> checkIsNSFWImage({
    required String imagePathOrUrl,
    bool showDialog = true,
  }) async {
    String? tempFilePath;
    try {
      final context = Get.context;
      if (showDialog && context != null) {
        showLoadingDialog(context);
      }
      String imagePath = imagePathOrUrl;

      /// Download URL image locally if needed
      if (imagePathOrUrl.startsWith("http")) {
        final dir = await getApplicationCacheDirectory();
        final microSeconds = DateTime.now().microsecondsSinceEpoch;
        imagePath =
            "${dir.path}/temp_$microSeconds.${imagePathOrUrl.split(".").last}";
        tempFilePath = imagePath;
        final downloaded = await downloadFileToAppDirectory(
          fileUrl: imagePathOrUrl,
          filePathToSave: imagePath,
        );
        if (!downloaded) {
          showLog("Failed to download image.");
          if (showDialog) {
            hideLoadingDialog();
          }
          return false;
        }
      }
      bool? a1Result;
      bool isNsfw = false;

      /// ==========================================================
      /// A1 ART CHECK
      /// ==========================================================
      if (AdsVariable.isUseA1ArtForNsfwCheck) {
        try {
          a1Result = await A1ArtNsfwService.isNsfw(File(imagePath));
          showLog("A1 ART RESULT => $a1Result");
        } catch (e) {
          showLog("A1 ART ERROR => $e");
          a1Result = null;
        }
      }

      if (a1Result != null) {
        isNsfw = a1Result;
        showLog("USING A1 ART RESULT AS FINAL VERDICT => $isNsfw");
      } else {
        /// ==========================================================
        /// LOCAL PACKAGE CHECK
        /// ==========================================================
        /// ==========================================================
        /// LOCAL PACKAGE CHECK (runs on main isolate — model asset
        /// loading requires rootBundle, which isn't available inside
        /// compute()/background isolates)
        /// ==========================================================
        showLog("API RESULT IS NULL, RUNNING LOCAL DETECTOR ON MAIN THREAD");
        try {
          await _ensureLocalDetectorInitialized();
          final imageBytes = await File(imagePath).readAsBytes();
          final result = await NsfwDetector.instance.detectNSFWFromBytes(
            imageBytes,
          );
          final bool packageResult =
              result != null && (result.score * 100) > nsfwBorderPercentage;
          showLog("PACKAGE RESULT => ${result?.score} => $packageResult");
          isNsfw = packageResult;
        } catch (e) {
          showLog("PACKAGE NSFW ERROR => $e");
          isNsfw = false;
        }
      }

      /// ==========================================================
      /// FINAL DECISION
      /// ==========================================================
      showLog("FINAL NSFW RESULT => A1:$a1Result | FINAL:$isNsfw");
      if (showDialog) {
        hideLoadingDialog();
      }
      return await _handleResult(isNsfw);
    } catch (e) {
      showLog("ERROR IN checkIsNSFWImage => $e");
      return false;
    } finally {
      /// Delete temporary downloaded file
      if (tempFilePath != null) {
        try {
          final file = File(tempFilePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          showLog("ERROR DELETING TEMP FILE => $e");
        }
      }
    }
  }

  // static Future<bool> checkIsNSFWImage({
  //   required String imagePathOrUrl,
  // })
  // async {
  //   String? tempFilePath;
  //
  //   try {
  //     if (InstallReferrerService.isAdInstall) {
  //       return false;
  //     }
  //
  //     String imagePath = imagePathOrUrl;
  //
  //     /// Download URL image locally if needed
  //     if (imagePathOrUrl.startsWith("http")) {
  //       final dir = await getApplicationCacheDirectory();
  //       final microSeconds = DateTime.now().microsecondsSinceEpoch;
  //
  //       imagePath = "${dir.path}/temp_$microSeconds.${imagePathOrUrl.split(".").last}";
  //
  //       tempFilePath = imagePath;
  //
  //       final downloaded = await downloadFileToAppDirectory(
  //         fileUrl: imagePathOrUrl,
  //         filePathToSave: imagePath,
  //       );
  //
  //       if (!downloaded) {
  //         showLog("Failed to download image.");
  //         return false;
  //       }
  //     }
  //
  //     /// ==========================================================
  //     /// STEP 1 : TRY A1 ART
  //     /// ==========================================================
  //     if (AdsVariable.isUseA1ArtForNsfwCheck) {
  //       final a1Result = await A1ArtNsfwService.isNsfw(
  //         File(imagePath),
  //       );
  //
  //       if (a1Result != null) {
  //         showLog("NSFW RESULT FROM A1 ART => $a1Result");
  //         return await _handleResult(a1Result);
  //       }
  //
  //       showLog(
  //         "A1 ART CHECK FAILED. FALLING BACK TO PACKAGE.",
  //       );
  //     }
  //
  //     /// ==========================================================
  //     /// STEP 2 : TRY RAPID API
  //     /// ==========================================================
  //     final apiResult = await RapidApiNsfwService.isNsfw(
  //       File(imagePath),
  //     );
  //
  //     if (apiResult != null) {
  //       showLog("NSFW RESULT FROM API => $apiResult");
  //       return await _handleResult(apiResult);
  //     }
  //
  //
  //
  //     /// ==========================================================
  //     /// STEP 3 : FALLBACK TO LOCAL PACKAGE
  //     /// ==========================================================
  //     showLog(
  //       "NSFW API/A1 ART failed. Falling back to local detector.",
  //     );
  //
  //     await _ensureLocalDetectorInitialized();
  //
  //     final imageBytes = await File(imagePath).readAsBytes();
  //
  //     final result = await NsfwDetector.instance.detectNSFWFromBytes(
  //       imageBytes,
  //     );
  //
  //     showLog("PACKAGE RESULT => ${result?.toJson()}");
  //
  //     return await _handleResult(
  //       ((result?.score ?? 0) * 100) > nsfwBorderPercentage,
  //     );
  //   } catch (e) {
  //     showLog("ERROR IN checkIsNSFWImage => $e");
  //     return false;
  //   } finally {
  //     /// Delete temporary downloaded file
  //     if (tempFilePath != null) {
  //       try {
  //         final file = File(tempFilePath);
  //
  //         if (await file.exists()) {
  //           await file.delete();
  //         }
  //       } catch (e) {
  //         showLog("ERROR DELETING TEMP FILE => $e");
  //       }
  //     }
  //   }
  // }
  static Future<bool> _handleResult(bool isNsfw) async {
    if (!isNsfw) {
      return false;
    }
    final context = Get.context;
    if (context != null) {
      await NsfwDialog.show(context);
    }
    return true;
  }

  static Future<bool> downloadFileToAppDirectory({
    required String fileUrl,
    required String filePathToSave,
  }) async {
    try {
      showLog("URL TO DOWNLOAD => $fileUrl");
      final dio = Dio();
      await dio.download(fileUrl, filePathToSave);
      showLog("FILE DOWNLOADED TO => $filePathToSave");
      return true;
    } catch (e) {
      showLog("ERROR IN downloadFileToAppDirectory => $e");
      return false;
    }
  }
}

/// A1 ART
class A1ArtNsfwService {
  static const String _url = "https://a1.art/api/common/v1/upload/images";
  static const String _appId = "1775082379769741314";

  /// Returns:
  /// true  -> NSFW
  /// false -> Safe
  /// null  -> API failure
  static Future<bool?> isNsfw(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_url));
      request.fields.addAll({'appId': _appId, 'type': '101'});
      request.files.add(
        await http.MultipartFile.fromPath('files', imageFile.path),
      );
      final response = await request.send().timeout(
        const Duration(seconds: 15),
      );
      final responseBody = await response.stream.bytesToString();
      showLog("A1 ART NSFW RESPONSE => $responseBody");
      if (response.statusCode != 200) {
        showLog("A1 ART HTTP ERROR => ${response.statusCode}");
        return null;
      }
      final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;
      final int code = (jsonResponse['code'] as num?)?.toInt() ?? -1;

      /// Safe image
      if (code == 0) {
        return false;
      }

      /// NSFW image
      if (code == 700106 || jsonResponse['key'] == 'IMAGE_NOT_ALLOW') {
        return true;
      }
      showLog("A1 ART UNKNOWN RESPONSE => $jsonResponse");
      return null;
    } catch (e) {
      showLog("A1 ART NSFW EXCEPTION => $e");
      return null;
    }
  }
}

class NsfwDialog {
  static Future<void> show(BuildContext context) {
    const gradientColors = [Color(0xFF6F5BFF), Color(0xFF8A7DFF)];

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: gradientColors,
                stops: [0.0, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4779F4).withValues(alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: const Color(0xFF171717),
                borderRadius: BorderRadius.circular(27),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gradient Icon Container
                  Container(
                    height: 84,
                    width: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradientColors,
                        stops: [0.0, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF4779F4,
                          ).withValues(alpha: 0.35),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF1F1F1F),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        size: 42,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    "Image Not Allowed",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "This image cannot be used because our app does not allow NSFW content.\nPlease choose a different image.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Gradient Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: gradientColors,
                          stops: [0.0, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF4779F4,
                            ).withValues(alpha: 0.35),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.pop(context),
                          child: const Center(
                            child: Text(
                              "Choose Another Image",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

BuildContext? _nsfwLoadingContext;

void showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      _nsfwLoadingContext = ctx;
      return PopScope(
        canPop: false,
        child: Center(
          child: Container(
            width: 220,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0052D4)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Analyzing Image',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 15,
                    decoration: TextDecoration.none,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Verifying content safety...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    decoration: TextDecoration.none,
                    fontWeight: FontWeight.normal,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void hideLoadingDialog() {
  if (_nsfwLoadingContext != null) {
    try {
      Navigator.of(_nsfwLoadingContext!).pop();
    } catch (e) {
      debugPrint("Error closing loading dialog: $e");
    }
    _nsfwLoadingContext = null;
  }
}
