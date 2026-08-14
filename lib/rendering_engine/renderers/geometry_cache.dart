import 'dart:ui';

/// Caches the path and geometric bounds of a node to avoid redundant path creation and bounds computation.
class GeometryCache {
  final Path path;
  final Rect bounds;

  const GeometryCache({
    required this.path,
    required this.bounds,
  });

  factory GeometryCache.fromPath(Path path) {
    return GeometryCache(
      path: path,
      bounds: path.getBounds(),
    );
  }
}
