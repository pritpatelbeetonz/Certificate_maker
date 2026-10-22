import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../for_ads/ads/ads_variable.dart';

class FetchDataFromServerServices {
  static const String _defaultServerUrl = "https://phpstack-1550637-6001716.cloudwaysapps.com";
  static const String _defaultBaseFolder = "Sn_Ro_Pri_Certificate_Maker";

  static const String _indexAssetPath = 'assets/Final_Certificates/index.json';
  static const String _bannerAssetPath = 'assets/Final_Certificates/banner_certificates.json';
  static const String _fontsAssetPath = 'assets/Final_Certificates/fonts.json';
  static const String _stickersAssetPath = 'assets/Final_Certificates/stickers.json';
  static const String _backgroundsAssetPath = 'assets/Final_Certificates/backgrounds.json';

  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> _getLocalFile(String fileName) async {
    final path = await _localPath;
    return File('$path/$fileName');
  }

  /// Downloads all catalog JSON files from server (Firebase Remote Config / fallback)
  /// and saves them into the app's local document directory.
  Future<void> initCall() async {
    String serverUrl = AdsVariable.serverUrl.trim();
    if (serverUrl.isEmpty) {
      serverUrl = _defaultServerUrl;
    }

    String baseFolder = AdsVariable.serverBaseFolderName.trim();
    if (baseFolder.isEmpty) {
      baseFolder = _defaultBaseFolder;
    }

    final String cleanServerUrl = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;
    final String cleanBaseFolder = baseFolder.startsWith('/')
        ? baseFolder.substring(1)
        : baseFolder;

    // Full remote root: https://domain.com/Sn_Ro_Pri_Certificate_Maker/Final_Certificates
    final String remoteBase = "$cleanServerUrl/$cleanBaseFolder/Final_Certificates";

    debugPrint("========================================================");
    debugPrint("[FetchData] 🌐 Initializing remote data sync...");
    debugPrint("[FetchData] 📍 AdsVariable.serverUrl: '${AdsVariable.serverUrl}'");
    debugPrint("[FetchData] 📍 AdsVariable.serverBaseFolderName: '${AdsVariable.serverBaseFolderName}'");
    debugPrint("[FetchData] 🔗 Resolved Remote Base: $remoteBase");
    debugPrint("========================================================");

    await _downloadAndCacheJson("$remoteBase/index.json", 'index.json');
    await _downloadAndCacheJson("$remoteBase/banner_certificates.json", 'banner_certificates.json');
    await _downloadAndCacheJson("$remoteBase/fonts.json", 'fonts.json');
    await _downloadAndCacheJson("$remoteBase/stickers.json", 'stickers.json');
    await _downloadAndCacheJson("$remoteBase/backgrounds.json", 'backgrounds.json');

    debugPrint("[FetchData] ✨ Remote data sync finished.");
    debugPrint("========================================================");
  }

  Future<void> _downloadAndCacheJson(String url, String localFileName) async {
    try {
      debugPrint("[FetchData] ⬇ Fetching remote JSON from: $url");
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final file = await _getLocalFile(localFileName);
        await file.writeAsString(response.body);
        debugPrint("[FetchData] ✅ Successfully downloaded and cached '$localFileName' (${response.body.length} bytes) to ${file.path}");
      } else {
        debugPrint("[FetchData] ⚠ Server returned HTTP ${response.statusCode} for '$localFileName' (body length: ${response.body.length}). Will use bundled asset fallback.");
      }
    } catch (e, stack) {
      debugPrint("[FetchData] ❌ Error downloading '$localFileName' from $url: $e");
      debugPrint("[FetchData] Stack: $stack");
    }
  }

  /// 1. Load index.json (Categories & Templates Catalog)
  static Future<String> loadIndexJson() async {
    try {
      final file = await _getLocalFile('index.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          debugPrint("[FetchData] 📦 Loaded index.json from local disk cache (${content.length} chars) at: ${file.path}");
          return content;
        }
      }
    } catch (e) {
      debugPrint("[FetchData] ⚠ Error reading index.json cache: $e");
    }
    debugPrint("[FetchData] 📁 Falling back to bundled asset: $_indexAssetPath");
    final assetContent = await rootBundle.loadString(_indexAssetPath);
    debugPrint("[FetchData] 📦 Loaded index.json from asset (${assetContent.length} chars)");
    return assetContent;
  }

  /// 2. Load banner_certificates.json
  static Future<String> loadBannerCertificatesJson() async {
    try {
      final file = await _getLocalFile('banner_certificates.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          debugPrint("[FetchData] 📦 Loaded banner_certificates.json from local disk cache (${content.length} chars) at: ${file.path}");
          return content;
        }
      }
    } catch (e) {
      debugPrint("[FetchData] ⚠ Error reading banner_certificates.json cache: $e");
    }
    debugPrint("[FetchData] 📁 Falling back to bundled asset: $_bannerAssetPath");
    final assetContent = await rootBundle.loadString(_bannerAssetPath);
    debugPrint("[FetchData] 📦 Loaded banner_certificates.json from asset (${assetContent.length} chars)");
    return assetContent;
  }

  /// 3. Load fonts.json
  static Future<String> loadFontsJson() async {
    try {
      final file = await _getLocalFile('fonts.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          debugPrint("[FetchData] 📦 Loaded fonts.json from local disk cache (${content.length} chars) at: ${file.path}");
          return content;
        }
      }
    } catch (e) {
      debugPrint("[FetchData] ⚠ Error reading fonts.json cache: $e");
    }
    debugPrint("[FetchData] 📁 Falling back to bundled asset: $_fontsAssetPath");
    final assetContent = await rootBundle.loadString(_fontsAssetPath);
    debugPrint("[FetchData] 📦 Loaded fonts.json from asset (${assetContent.length} chars)");
    return assetContent;
  }

  /// 4. Load stickers.json
  static Future<String> loadStickersJson() async {
    try {
      final file = await _getLocalFile('stickers.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          debugPrint("[FetchData] 📦 Loaded stickers.json from local disk cache (${content.length} chars) at: ${file.path}");
          return content;
        }
      }
    } catch (e) {
      debugPrint("[FetchData] ⚠ Error reading stickers.json cache: $e");
    }
    debugPrint("[FetchData] 📁 Falling back to bundled asset: $_stickersAssetPath");
    final assetContent = await rootBundle.loadString(_stickersAssetPath);
    debugPrint("[FetchData] 📦 Loaded stickers.json from asset (${assetContent.length} chars)");
    return assetContent;
  }

  /// 5. Load backgrounds.json
  static Future<String> loadBackgroundsJson() async {
    try {
      final file = await _getLocalFile('backgrounds.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          debugPrint("[FetchData] 📦 Loaded backgrounds.json from local disk cache (${content.length} chars) at: ${file.path}");
          return content;
        }
      }
    } catch (e) {
      debugPrint("[FetchData] ⚠ Error reading backgrounds.json cache: $e");
    }
    debugPrint("[FetchData] 📁 Falling back to bundled asset: $_backgroundsAssetPath");
    final assetContent = await rootBundle.loadString(_backgroundsAssetPath);
    debugPrint("[FetchData] 📦 Loaded backgrounds.json from asset (${assetContent.length} chars)");
    return assetContent;
  }

  /// 6. Load a specific template layout JSON (checks local disk cache first, else rootBundle)
  static Future<String> loadLayoutJson(String layoutPath) async {
    try {
      final String fileName = layoutPath.split('/').last;
      final file = await _getLocalFile(fileName);
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          debugPrint("[FetchData] 📦 Loaded layout '$fileName' from local disk cache (${content.length} chars) at: ${file.path}");
          return content;
        }
      }
    } catch (e) {
      debugPrint("[FetchData] ⚠ Error reading layout cache for '$layoutPath': $e");
    }

    final String resolvedPath = (layoutPath.isNotEmpty &&
            !layoutPath.startsWith('assets/') &&
            !layoutPath.startsWith('http'))
        ? 'assets/$layoutPath'
        : layoutPath;

    debugPrint("[FetchData] 📁 Loading layout from asset: $resolvedPath");
    final assetContent = await rootBundle.loadString(resolvedPath);
    debugPrint("[FetchData] 📦 Loaded layout asset '$resolvedPath' (${assetContent.length} chars)");
    return assetContent;
  }
}
