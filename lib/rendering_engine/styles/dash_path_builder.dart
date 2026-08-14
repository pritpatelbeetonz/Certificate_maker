import 'dart:ui';

/// Generates dashed or dotted paths from a source path using path metrics.
class DashPathBuilder {
  static Path build(Path source, List<double> dashArray) {
    if (dashArray.isEmpty) return source;

    final Path dest = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      int index = 0;
      while (distance < metric.length) {
        final double len = dashArray[index];
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, (distance + len).clamp(0.0, metric.length)),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
        index = (index + 1) % dashArray.length;
      }
    }
    return dest;
  }

  static Path buildDashed(Path source, double strokeWidth) {
    final dash = strokeWidth * 3.0;
    final gap = strokeWidth * 2.0;
    return build(source, [dash > 0 ? dash : 6.0, gap > 0 ? gap : 4.0]);
  }

  static Path buildDotted(Path source, double strokeWidth) {
    final dot = strokeWidth > 0 ? strokeWidth : 2.0;
    final gap = strokeWidth > 0 ? strokeWidth * 2.0 : 4.0;
    return build(source, [dot, gap]);
  }
}
