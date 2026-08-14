import 'dart:math';
import 'vector_geometry.dart';
import 'path_command.dart';

abstract class GeometryGenerator {
  const GeometryGenerator();

  VectorGeometry generate(double width, double height, Map<String, dynamic> params);
}

class RectangleGenerator extends GeometryGenerator {
  const RectangleGenerator();

  @override
  VectorGeometry generate(double width, double height, Map<String, dynamic> params) {
    return VectorGeometry(
      commands: [
        const MoveToCommand(0, 0),
        LineToCommand(width, 0),
        LineToCommand(width, height),
        LineToCommand(0, height),
        const CloseCommand(),
      ],
    );
  }
}

class CircleGenerator extends GeometryGenerator {
  const CircleGenerator();

  @override
  VectorGeometry generate(double width, double height, Map<String, dynamic> params) {
    final cx = width / 2;
    final cy = height / 2;
    final r = min(width, height) / 2;
    return VectorGeometry(
      commands: [
        MoveToCommand(cx + r, cy),
        ArcToCommand(r, r, 0, false, true, cx - r, cy),
        ArcToCommand(r, r, 0, false, true, cx + r, cy),
        const CloseCommand(),
      ],
    );
  }
}

class EllipseGenerator extends GeometryGenerator {
  const EllipseGenerator();

  @override
  VectorGeometry generate(double width, double height, Map<String, dynamic> params) {
    final cx = width / 2;
    final cy = height / 2;
    final rx = width / 2;
    final ry = height / 2;
    return VectorGeometry(
      commands: [
        MoveToCommand(cx + rx, cy),
        ArcToCommand(rx, ry, 0, false, true, cx - rx, cy),
        ArcToCommand(rx, ry, 0, false, true, cx + rx, cy),
        const CloseCommand(),
      ],
    );
  }
}

class PolygonGenerator extends GeometryGenerator {
  const PolygonGenerator();

  @override
  VectorGeometry generate(double width, double height, Map<String, dynamic> params) {
    if (params['points'] != null && params['points'] is List) {
      final List pts = params['points'] as List;
      final List<PathCommand> commands = [];
      for (int i = 0; i < pts.length; i++) {
        final p = pts[i] as Map;
        final px = (p['x'] as num).toDouble() * width;
        final py = (p['y'] as num).toDouble() * height;
        if (i == 0) {
          commands.add(MoveToCommand(px, py));
        } else {
          commands.add(LineToCommand(px, py));
        }
      }
      commands.add(const CloseCommand());
      return VectorGeometry(commands: commands);
    }

    final int sides = params['sides'] as int? ?? params['points'] as int? ?? 5;
    final cx = width / 2;
    final cy = height / 2;
    final r = min(width, height) / 2;
    final List<PathCommand> commands = [];
    final angleStep = 2 * pi / sides;

    for (int i = 0; i < sides; i++) {
      final angle = -pi / 2 + i * angleStep;
      final px = cx + r * cos(angle);
      final py = cy + r * sin(angle);
      if (i == 0) {
        commands.add(MoveToCommand(px, py));
      } else {
        commands.add(LineToCommand(px, py));
      }
    }
    commands.add(const CloseCommand());
    return VectorGeometry(commands: commands);
  }
}

class StarGenerator extends GeometryGenerator {
  const StarGenerator();

  @override
  VectorGeometry generate(double width, double height, Map<String, dynamic> params) {
    final int points = params['points'] as int? ?? 5;
    final double innerRatio = (params['innerRadius'] as num? ?? 0.4).toDouble();
    final cx = width / 2;
    final cy = height / 2;
    final r = min(width, height) / 2;
    final ir = r * innerRatio;

    final List<PathCommand> commands = [];
    final angleStep = pi / points;

    for (int i = 0; i < 2 * points; i++) {
      final angle = -pi / 2 + i * angleStep;
      final currR = i % 2 == 0 ? r : ir;
      final px = cx + currR * cos(angle);
      final py = cy + currR * sin(angle);
      if (i == 0) {
        commands.add(MoveToCommand(px, py));
      } else {
        commands.add(LineToCommand(px, py));
      }
    }
    commands.add(const CloseCommand());
    return VectorGeometry(commands: commands);
  }
}

class HeartGenerator extends GeometryGenerator {
  const HeartGenerator();

  @override
  VectorGeometry generate(double width, double height, Map<String, dynamic> params) {
    return VectorGeometry(
      commands: [
        MoveToCommand(width * 0.5, height * 0.25),
        CubicToCommand(width * 0.5, height * 0.05, width * 0.15, height * 0.05, width * 0.15, height * 0.4),
        CubicToCommand(width * 0.15, height * 0.65, width * 0.5, height * 0.9, width * 0.5, height * 0.9),
        CubicToCommand(width * 0.5, height * 0.9, width * 0.85, height * 0.65, width * 0.85, height * 0.4),
        CubicToCommand(width * 0.85, height * 0.05, width * 0.5, height * 0.05, width * 0.5, height * 0.25),
        const CloseCommand(),
      ],
    );
  }
}

class ArrowGenerator extends GeometryGenerator {
  const ArrowGenerator();

  @override
  VectorGeometry generate(double width, double height, Map<String, dynamic> params) {
    final shaft = (params['shaftThickness'] as num? ?? 0.4).toDouble();
    final head = (params['headLength'] as num? ?? 0.4).toDouble();
    return VectorGeometry(
      commands: [
        MoveToCommand(0, height * (0.5 - shaft / 2)),
        LineToCommand(width - width * head, height * (0.5 - shaft / 2)),
        LineToCommand(width - width * head, 0),
        LineToCommand(width, height * 0.5),
        LineToCommand(width - width * head, height),
        LineToCommand(width - width * head, height * (0.5 + shaft / 2)),
        LineToCommand(0, height * (0.5 + shaft / 2)),
        const CloseCommand(),
      ],
    );
  }
}

class CloudGenerator extends GeometryGenerator {
  const CloudGenerator();

  @override
  VectorGeometry generate(double width, double height, Map<String, dynamic> params) {
    return VectorGeometry(
      commands: [
        MoveToCommand(width * 0.25, height * 0.75),
        ArcToCommand(width * 0.15, height * 0.15, 0, false, true, width * 0.35, height * 0.5),
        ArcToCommand(width * 0.2, height * 0.2, 0, false, true, width * 0.7, height * 0.55),
        ArcToCommand(width * 0.15, height * 0.15, 0, false, true, width * 0.85, height * 0.75),
        ArcToCommand(width * 0.12, height * 0.12, 0, false, true, width * 0.65, height * 0.88),
        ArcToCommand(width * 0.2, height * 0.12, 0, false, true, width * 0.25, height * 0.75),
        const CloseCommand(),
      ],
    );
  }
}

class BlobGenerator extends GeometryGenerator {
  const BlobGenerator();

  @override
  VectorGeometry generate(double width, double height, Map<String, dynamic> params) {
    final cx = width / 2;
    final cy = height / 2;
    final r = min(width, height) / 2;
    return VectorGeometry(
      commands: [
        MoveToCommand(cx + r * 0.9, cy + r * 0.1),
        CubicToCommand(cx + r * 0.9, cy - r * 0.5, cx + r * 0.4, cy - r * 0.9, cx, cy - r * 0.9),
        CubicToCommand(cx - r * 0.5, cy - r * 0.9, cx - r * 0.9, cy - r * 0.5, cx - r * 0.9, cy),
        CubicToCommand(cx - r * 0.9, cy + r * 0.6, cx - r * 0.4, cy + r * 0.9, cx, cy + r * 0.9),
        CubicToCommand(cx + r * 0.5, cy + r * 0.9, cx + r * 0.9, cy + r * 0.5, cx + r * 0.9, cy + r * 0.1),
        const CloseCommand(),
      ],
    );
  }
}
