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
      Uint8List? fontBytes;

      if (assetByteProvider != null) {
        fontBytes = await assetByteProvider(source);
      } else if (source.startsWith('http://') || source.startsWith('https://')) {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        final request = await client.getUrl(Uri.parse(source));
        final response = await request.close();
        fontBytes = await consolidateHttpClientResponseBytes(response);
      } else if (File(source).existsSync()) {
        fontBytes = await File(source).readAsBytes();
      } else {
        // Fallback or asset loader
        try {
          final String resolved = (source.isNotEmpty && !source.startsWith('assets/') && !source.startsWith('http'))
              ? 'assets/$source'
              : source;
          final byteData = await rootBundle.load(resolved);
          fontBytes = byteData.buffer.asUint8List();
        } catch (_) {
          fontBytes = null;
        }
      }

      if (fontBytes != null && fontBytes.isNotEmpty) {
        fontLoader.addFont(Future.value(ByteData.view(fontBytes.buffer)));
        await fontLoader.load();
        _loadedFonts.add(family);
        debugPrint('Successfully loaded dynamic font: $family');
      } else {
        debugPrint('Could not obtain bytes for dynamic font: $family from $source');
      }
    } catch (e) {
      debugPrint('Failed to load dynamic font: $family from $source. Error: $e');
    }
  }
}
