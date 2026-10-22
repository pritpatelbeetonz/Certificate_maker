import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

    // Download in parallel for fast network sync on slow connections
    await Future.wait([
      _downloadAndCacheJson("$remoteBase/index.json", 'index.json'),
      _downloadAndCacheJson("$remoteBase/banner_certificates.json", 'banner_certificates.json'),
      _downloadAndCacheJson("$remoteBase/fonts.json", 'fonts.json'),
      _downloadAndCacheJson("$remoteBase/stickers.json", 'stickers.json'),
      _downloadAndCacheJson("$remoteBase/backgrounds.json", 'backgrounds.json'),
    ]);

    // Pre-cache initial visible thumbnails in background so HomePage shows them instantly
    _precacheInitialThumbnailsInBackground();

    debugPrint("[FetchData] ✨ Remote data sync finished.");
    debugPrint("========================================================");
  }

  /// Extracts initial visible thumbnails (banners + first 3 of each category)
  /// and downloads them into DefaultCacheManager in the background
  void _precacheInitialThumbnailsInBackground() {
    Future.microtask(() async {
      try {
        final List<String> urlsToPrecache = [];

        // 1. Banner thumbnails
        final bannerFile = await _getLocalFile('banner_certificates.json');
        if (await bannerFile.exists()) {
          final String raw = await bannerFile.readAsString();
          if (raw.isNotEmpty) {
            final bannerList = json.decode(raw);
            if (bannerList is List) {
              for (final b in bannerList) {
                final String thumb = b['thumbnail'] ?? '';
                if (thumb.isNotEmpty) {
                  urlsToPrecache.add(resolveThumbnailUrl(thumb));
                }
              }
            }
          }
        }

        // 2. Index catalog thumbnails (first 3 of each category)
        final indexFile = await _getLocalFile('index.json');
        if (await indexFile.exists()) {
          final String raw = await indexFile.readAsString();
          if (raw.isNotEmpty) {
            final data = json.decode(raw);
            final layouts = data['layouts'] as List? ?? [];
            final Map<String, int> categoryCount = {};
            for (final item in layouts) {
              final String cat = item['category'] ?? '';
              final int count = categoryCount[cat] ?? 0;
              if (count < 3) {
                categoryCount[cat] = count + 1;
                final String thumb = item['thumbnail'] ?? '';
                if (thumb.isNotEmpty) {
                  urlsToPrecache.add(resolveThumbnailUrl(thumb));
                }
              }
            }
          }
        }

        if (urlsToPrecache.isNotEmpty) {
          debugPrint("[FetchData] 🚀 Pre-caching ${urlsToPrecache.length} initial thumbnails in background...");
          for (final url in urlsToPrecache) {
            if (url.startsWith('http')) {
              try {
                final provider = CachedNetworkImageProvider(url);
                provider.resolve(const ImageConfiguration());
              } catch (e) {
                debugPrint("[FetchData] ⚠ Pre-cache error for $url: $e");
              }
            }
          }
        }
      } catch (e) {
        debugPrint("[FetchData] ⚠ Background thumbnail pre-caching failed: $e");
      }
    });
  }

  /// Resolves any thumbnail string into either:
  /// - A remote HTTP/HTTPS URL
  /// - Or a clean asset path
  static String resolveThumbnailUrl(String rawPath) {
    if (rawPath.isEmpty) return '';
    if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
      return rawPath;
    }

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

    String cleanPath = rawPath.startsWith('/') ? rawPath.substring(1) : rawPath;
    if (cleanPath.startsWith('assets/')) {
      cleanPath = cleanPath.substring(7);
    }

    return "$cleanServerUrl/$cleanBaseFolder/$cleanPath";
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

    final String fileName = layoutPath.split('/').last;

    // If not in cache and layoutPath is a server relative path, fetch it on-demand from server
    if (layoutPath.isNotEmpty && !layoutPath.startsWith('http://') && !layoutPath.startsWith('https://')) {
      final String remoteUrl = FetchDataFromServerServices.resolveThumbnailUrl(layoutPath);
      debugPrint("[FetchData] 🌐 Layout '$fileName' not in cache. Fetching from server: $remoteUrl");
      try {
        final response = await http.get(Uri.parse(remoteUrl)).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200 && response.body.isNotEmpty) {
          final file = await _getLocalFile(fileName);
          await file.writeAsString(response.body);
          debugPrint("[FetchData] ✅ Cached on-demand layout '$fileName' (${response.body.length} bytes)");
          return response.body;
        }
      } catch (e) {
        debugPrint("[FetchData] ❌ Error fetching remote layout: $e");
      }
    }

    try {
      final String resolvedPath = (layoutPath.isNotEmpty &&
              !layoutPath.startsWith('assets/') &&
              !layoutPath.startsWith('http'))
          ? 'assets/$layoutPath'
          : layoutPath;

      debugPrint("[FetchData] 📁 Attempting layout load from asset: $resolvedPath");
      return await rootBundle.loadString(resolvedPath);
    } catch (e) {
      debugPrint("[FetchData] ⚠ Asset fallback not available for '$layoutPath': $e");
      return '{}';
    }
  }
}
