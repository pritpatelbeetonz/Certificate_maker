import 'dart:ui';
import 'vector_geometry.dart';

/// Represents a boolean geometry combination (Union, Intersect, Difference, XOR) of two vector geometries.
class BooleanGeometry extends VectorGeometry {
  final VectorGeometry geometryA;
  final VectorGeometry geometryB;
  final PathOperation operation;

  BooleanGeometry({
    required this.geometryA,
    required this.geometryB,
    required this.operation,
  }) : super(commands: []);

  @override
  Path toPath() {
    return Path.combine(operation, geometryA.toPath(), geometryB.toPath());
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'boolean',
        'operation': operation.name,
        'geometryA': geometryA.toJson(),
        'geometryB': geometryB.toJson(),
      };
}
