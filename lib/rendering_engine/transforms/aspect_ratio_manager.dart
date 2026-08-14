import 'dart:ui';

class AspectRatioManager {
  static final Map<String, double> _presetRatios = {
    '1:1': 1.0,
    '4:5': 0.8,
    '3:4': 0.75,
    '2:3': 2.0 / 3.0,
    '9:16': 9.0 / 16.0,
    '16:9': 16.0 / 9.0,
  };

  static double parseRatio(String ratioId) {
    if (_presetRatios.containsKey(ratioId)) {
      return _presetRatios[ratioId]!;
    }
    final parts = ratioId.split(':');
    if (parts.length == 2) {
      final w = double.tryParse(parts[0]);
      final h = double.tryParse(parts[1]);
      if (w != null && h != null && h > 0) {
        return w / h;
      }
    }
    return 1.0;
  }

  static Size resolveCanvasSize(String ratioId, {double targetWidth = 1080.0}) {
    final double ratio = parseRatio(ratioId);
    return Size(targetWidth, targetWidth / ratio);
  }
}
