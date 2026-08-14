import 'geometry_generator.dart';
import 'vector_geometry.dart';

/// Registry and orchestrator for all geometry generators.
class GeometryFactory {
  static final Map<String, GeometryGenerator> _generators = {
    'rect': const RectangleGenerator(),
    'rectangle': const RectangleGenerator(),
    'circle': const CircleGenerator(),
    'ellipse': const EllipseGenerator(),
    'polygon': const PolygonGenerator(),
    'star': const StarGenerator(),
    'heart': const HeartGenerator(),
    'arrow': const ArrowGenerator(),
    'cloud': const CloudGenerator(),
    'blob': const BlobGenerator(),
  };

  static void register(String id, GeometryGenerator generator) {
    _generators[id.toLowerCase()] = generator;
  }

  static VectorGeometry generate(String generatorId, double width, double height, Map<String, dynamic> params) {
    final generator = _generators[generatorId.toLowerCase()];
    if (generator != null) {
      return generator.generate(width, height, params);
    }
    return const RectangleGenerator().generate(width, height, params);
  }
}
