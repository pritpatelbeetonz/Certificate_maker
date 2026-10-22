import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

typedef EngineAssetByteProvider = Future<Uint8List> Function(String path);

class DynamicFontManager {
  DynamicFontManager._();
  static final DynamicFontManager instance = DynamicFontManager._();

  final Set<String> _loadedFonts = {};

  Future<void> loadFont(String family, String source, {EngineAssetByteProvider? assetByteProvider}) async {
    if (_loadedFonts.contains(family)) return;
    try {
      final fontLoader = FontLoader(family);
      final String resolvedSource = (source.isNotEmpty &&
              !source.startsWith('assets/') &&
              !source.startsWith('http://') &&
              !source.startsWith('https://') &&
              source.startsWith('Final_Certificates/'))
          ? 'assets/$source'
          : source;

      if (resolvedSource.startsWith('http://') || resolvedSource.startsWith('https://')) {
        final client = HttpClient();
        final request = await client.getUrl(Uri.parse(resolvedSource));
        final response = await request.close();
        final bytes = await consolidateHttpClientResponseBytes(response);
        fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
      } else if (resolvedSource.startsWith('assets/')) {
        if (assetByteProvider != null) {
          final bytes = await assetByteProvider(resolvedSource);
          fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
        } else {
          final byteData = await rootBundle.load(resolvedSource);
          fontLoader.addFont(Future.value(byteData));
        }
      } else {
        final file = File(resolvedSource);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
        }
      }
      await fontLoader.load();
      _loadedFonts.add(family);
      debugPrint('Successfully loaded dynamic font: $family');
    } catch (e) {
      debugPrint('Failed to load dynamic font: $family from $source. Error: $e');
    }
  }
}
