import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

import '../for_ads/ads/ads_variable.dart';

class FetchDataFromServerServices {
  static const String _templetsAssetPath = 'assets/Final_Data/index_templets.json';
  static const String _layoutsAssetPath = 'assets/Final_Data/index_layouts.json';
  static const String _stickersAssetPath = 'assets/Final_Data/index_stickers.json';

  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> _getLocalFile(String fileName) async {
    final path = await _localPath;
    return File('$path/$fileName');
  }

  /// Downloads the three JSON files from the server if online, and saves them locally.
  Future<void> initCall() async {
    final String serverUrl = AdsVariable.serverUrl;
    final String baseFolder = AdsVariable.serverBaseFolderName;

    if (serverUrl.isEmpty || baseFolder.isEmpty) {
      print("[FetchData] Server URL or Base Folder is empty. Skipping remote download.");
      return;
    }

    // Ensure serverUrl doesn't end with a slash
    final String cleanServerUrl = serverUrl.endsWith('/') 
        ? serverUrl.substring(0, serverUrl.length - 1) 
        : serverUrl;

    // e.g. https://domain.com/basefolder/assets/Final_Data/index_templets.json
    final String templetsUrl = "$cleanServerUrl/$baseFolder/assets/Final_Data/index_templets.json";
    final String layoutsUrl = "$cleanServerUrl/$baseFolder/assets/Final_Data/index_layouts.json";
    final String stickersUrl = "$cleanServerUrl/$baseFolder/assets/Final_Data/index_stickers.json";

    await _downloadAndCacheJson(templetsUrl, 'index_templets.json');
    await _downloadAndCacheJson(layoutsUrl, 'index_layouts.json');
    await _downloadAndCacheJson(stickersUrl, 'index_stickers.json');
  }

  Future<void> _downloadAndCacheJson(String url, String localFileName) async {
    try {
      print("[FetchData] Fetching remote JSON from: $url");
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final file = await _getLocalFile(localFileName);
        await file.writeAsString(response.body);
        print("[FetchData] Successfully cached $localFileName locally.");
      } else {
        print("[FetchData] Failed to download $localFileName. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("[FetchData] Error downloading $localFileName: $e");
    }
  }

  /// Loader methods that check local cache first, then fall back to assets
  static Future<String> loadIndexTempletsJson() async {
    try {
      final file = await _getLocalFile('index_templets.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          print("[FetchData] Loaded index_templets.json from local cache.");
          return content;
        }
      }
    } catch (e) {
      print("[FetchData] Error reading index_templets.json cache: $e");
    }
    print("[FetchData] Falling back to bundled index_templets.json asset.");
    return await rootBundle.loadString(_templetsAssetPath);
  }

  static Future<String> loadIndexLayoutsJson() async {
    try {
      final file = await _getLocalFile('index_layouts.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          print("[FetchData] Loaded index_layouts.json from local cache.");
          return content;
        }
      }
    } catch (e) {
      print("[FetchData] Error reading index_layouts.json cache: $e");
    }
    print("[FetchData] Falling back to bundled index_layouts.json asset.");
    return await rootBundle.loadString(_layoutsAssetPath);
  }

  static Future<String> loadIndexStickersJson() async {
    try {
      final file = await _getLocalFile('index_stickers.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          print("[FetchData] Loaded index_stickers.json from local cache.");
          return content;
        }
      }
    } catch (e) {
      print("[FetchData] Error reading index_stickers.json cache: $e");
    }
    print("[FetchData] Falling back to bundled index_stickers.json asset.");
    return await rootBundle.loadString(_stickersAssetPath);
  }
}
