import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

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
    final directory = await getApplicationSupportDirectory();
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
    final changed = await Future.wait([
      _downloadAndCacheJson("$remoteBase/index.json", 'index.json'),
      _downloadAndCacheJson("$remoteBase/banner_certificates.json", 'banner_certificates.json'),
      _downloadAndCacheJson("$remoteBase/fonts.json", 'fonts.json'),
      _downloadAndCacheJson("$remoteBase/stickers.json", 'stickers.json'),
      _downloadAndCacheJson("$remoteBase/backgrounds.json", 'backgrounds.json'),
    ]);

    // Cache banner + first category thumbnails in the background (splash doesn't wait;
    // first-time users are still in onboarding while this runs).
    _precacheInitialThumbnailsInBackground(catalogChanged: changed[0] || changed[1]);

    debugPrint("[FetchData] ✨ Remote data sync finished.");
    debugPrint("========================================================");
  }

  /// Thumbnail URLs of every banner in banner_certificates.json.
  static Future<List<String>> _bannerThumbnailUrls() async {
    final List<String> urls = [];
    try {
      final data = json.decode(await loadBannerCertificatesJson());
      // The file is {"banner_certificates": [...]}; also accept a bare list.
      final List banners = data is Map ? (data['banner_certificates'] as List? ?? []) : (data is List ? data : []);
      for (final b in banners) {
        final String thumb = b['thumbnail'] ?? '';
        if (thumb.isNotEmpty) {
          urls.add(resolveThumbnailUrl(thumb));
        }
      }
    } catch (e) {
      debugPrint("[FetchData] ⚠ Could not read banner thumbnails: $e");
    }
    return urls;
  }

  /// Downloads remote images into the shared disk cache used by CachedNetworkImage.
  /// Images already on disk are skipped, even if their cache entry has expired.
  /// Returns true when every image is now cached.
  static Future<bool> _downloadToDiskCache(List<String> urls) async {
    final remoteUrls = urls.where((url) => url.startsWith('http')).toSet();
    if (remoteUrls.isEmpty) return true;
    final cacheManager = DefaultCacheManager();
    int downloaded = 0;
    final results = await Future.wait(remoteUrls.map((url) async {
      try {
        if (await cacheManager.getFileFromCache(url) != null) return true;
        await cacheManager.downloadFile(url);
        downloaded++;
        return true;
      } catch (e) {
        debugPrint("[FetchData] ⚠ Pre-cache error for $url: $e");
        return false;
      }
    }));
    debugPrint("[FetchData] 🚀 Thumbnails: ${remoteUrls.length} needed, $downloaded downloaded, rest already cached.");
    return results.every((ok) => ok);
  }

  /// Caches banner thumbnails, then the first 3 thumbnails of each category, in the
  /// background. Skipped entirely when the catalog JSON hasn't changed since the last
  /// run that cached everything (tracked by a marker file).
  void _precacheInitialThumbnailsInBackground({required bool catalogChanged}) {
    Future.microtask(() async {
      try {
        final marker = await _getLocalFile('thumbnails_precached.flag');
        if (catalogChanged) {
          if (await marker.exists()) await marker.delete();
        } else if (await marker.exists()) {
          debugPrint("[FetchData] ✅ Catalog unchanged and thumbnails already cached. Skipping.");
          return;
        }

        final List<String> urlsToPrecache = [...await _bannerThumbnailUrls()];
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
        // Banners come first in the list, so they start downloading first.
        if (await _downloadToDiskCache(urlsToPrecache)) {
          await marker.writeAsString(DateTime.now().toIso8601String());
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

  /// Returns true only when the server's JSON differs from the copy already on disk.
  Future<bool> _downloadAndCacheJson(String url, String localFileName) async {
    try {
      debugPrint("[FetchData] ⬇ Fetching remote JSON from: $url");
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final file = await _getLocalFile(localFileName);
        if (await file.exists() && await file.readAsString() == response.body) {
          debugPrint("[FetchData] ✅ '$localFileName' unchanged since last sync");
          return false;
        }
        await file.writeAsString(response.body);
        debugPrint("[FetchData] ✅ Successfully downloaded and cached '$localFileName' (${response.body.length} bytes) to ${file.path}");
        return true;
      } else {
        debugPrint("[FetchData] ⚠ Server returned HTTP ${response.statusCode} for '$localFileName' (body length: ${response.body.length}). Will use bundled asset fallback.");
      }
    } catch (e, stack) {
      debugPrint("[FetchData] ❌ Error downloading '$localFileName' from $url: $e");
      debugPrint("[FetchData] Stack: $stack");
    }
    return false;
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

  /// 7. Load raw image bytes from server, cache on disk, or fallback to bundled asset
  static Future<Uint8List> loadAssetBytes(String source) async {
    if (source.isEmpty) {
      throw Exception('Empty source path');
    }

    // 1. If it's already a local file path that exists on disk
    if (File(source).existsSync()) {
      return await File(source).readAsBytes();
    }

    // 2. Derive a deterministic local cache filename for this resource
    final String cleanPath = source.replaceFirst('assets/', '');
    final String sanitizedFileName = cleanPath.replaceAll('/', '_').replaceAll('\\', '_');
    final file = await _getLocalFile(sanitizedFileName);

    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      if (bytes.isNotEmpty) {
        return bytes;
      }
    }

    // 3. Resolve remote URL on server
    final String remoteUrl = resolveThumbnailUrl(source);
    if (remoteUrl.startsWith('http://') || remoteUrl.startsWith('https://')) {
      try {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        final request = await client.getUrl(Uri.parse(remoteUrl)).timeout(const Duration(seconds: 15));
        final response = await request.close();
        if (response.statusCode == 200) {
          final bytes = await consolidateHttpClientResponseBytes(response);
          if (bytes.isNotEmpty) {
            await file.writeAsBytes(bytes);
            debugPrint("[FetchData] ✅ Downloaded and cached image asset '$sanitizedFileName' (${bytes.length} bytes)");
            return bytes;
          }
        } else {
          debugPrint("[FetchData] ⚠ Server returned HTTP ${response.statusCode} for '$remoteUrl'");
        }
      } catch (e) {
        debugPrint("[FetchData] ❌ Error downloading asset from '$remoteUrl': $e");
      }
    }

    // 4. Fallback to bundled asset if still present in APK
    final String assetFallback = (source.isNotEmpty && !source.startsWith('assets/') && !source.startsWith('http'))
        ? 'assets/$source'
        : source;
    final byteData = await rootBundle.load(assetFallback);
    return byteData.buffer.asUint8List();
  }

  /// 8. Decode a ui.Image from server, disk cache, or local bundle
  static Future<ui.Image> loadUiImage(String source) async {
    final Uint8List bytes = await loadAssetBytes(source);
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
