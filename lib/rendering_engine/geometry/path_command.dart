import 'dart:ui';

/// Base class for all vector path commands.
abstract class PathCommand {
  const PathCommand();

  /// Applies the command to a Flutter Path, updating the pen state.
  void applyTo(Path path, PathPenState state);

  Map<String, dynamic> toJson();

  static PathCommand fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'moveTo':
        return MoveToCommand(
          (json['x'] as num).toDouble(),
          (json['y'] as num).toDouble(),
        );
      case 'lineTo':
        return LineToCommand(
          (json['x'] as num).toDouble(),
          (json['y'] as num).toDouble(),
        );
      case 'horizontalTo':
        return HorizontalToCommand((json['x'] as num).toDouble());
      case 'verticalTo':
        return VerticalToCommand((json['y'] as num).toDouble());
      case 'cubicTo':
        return CubicToCommand(
          (json['x1'] as num).toDouble(),
          (json['y1'] as num).toDouble(),
          (json['x2'] as num).toDouble(),
          (json['y2'] as num).toDouble(),
          (json['x'] as num).toDouble(),
          (json['y'] as num).toDouble(),
        );
      case 'quadTo':
        return QuadToCommand(
          (json['x1'] as num).toDouble(),
          (json['y1'] as num).toDouble(),
          (json['x'] as num).toDouble(),
          (json['y'] as num).toDouble(),
        );
      case 'arcTo':
        return ArcToCommand(
          (json['rx'] as num).toDouble(),
          (json['ry'] as num).toDouble(),
          (json['rotation'] as num).toDouble(),
          json['largeArc'] as bool? ?? false,
          json['sweep'] as bool? ?? false,
          (json['x'] as num).toDouble(),
          (json['y'] as num).toDouble(),
        );
      case 'close':
      default:
        return const CloseCommand();
    }
  }
}

class PathPenState {
  Offset current = Offset.zero;
  Offset lastControl = Offset.zero;
}

class MoveToCommand extends PathCommand {
  final double x;
  final double y;

  const MoveToCommand(this.x, this.y);

  @override
  void applyTo(Path path, PathPenState state) {
    path.moveTo(x, y);
    state.current = Offset(x, y);
    state.lastControl = Offset(x, y);
  }

  @override
  Map<String, dynamic> toJson() => {'type': 'moveTo', 'x': x, 'y': y};
}

class LineToCommand extends PathCommand {
  final double x;
  final double y;

  const LineToCommand(this.x, this.y);

  @override
  void applyTo(Path path, PathPenState state) {
    path.lineTo(x, y);
    state.current = Offset(x, y);
    state.lastControl = Offset(x, y);
  }

  @override
  Map<String, dynamic> toJson() => {'type': 'lineTo', 'x': x, 'y': y};
}

class HorizontalToCommand extends PathCommand {
  final double x;

  const HorizontalToCommand(this.x);

  @override
  void applyTo(Path path, PathPenState state) {
    final y = state.current.dy;
    path.lineTo(x, y);
    state.current = Offset(x, y);
    state.lastControl = Offset(x, y);
  }

  @override
  Map<String, dynamic> toJson() => {'type': 'horizontalTo', 'x': x};
}

class VerticalToCommand extends PathCommand {
  final double y;

  const VerticalToCommand(this.y);

  @override
  void applyTo(Path path, PathPenState state) {
    final x = state.current.dx;
    path.lineTo(x, y);
    state.current = Offset(x, y);
    state.lastControl = Offset(x, y);
  }

  @override
  Map<String, dynamic> toJson() => {'type': 'verticalTo', 'y': y};
}

class CubicToCommand extends PathCommand {
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double x;
  final double y;

  const CubicToCommand(this.x1, this.y1, this.x2, this.y2, this.x, this.y);

  @override
  void applyTo(Path path, PathPenState state) {
    path.cubicTo(x1, y1, x2, y2, x, y);
    state.current = Offset(x, y);
    state.lastControl = Offset(x2, y2);
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'cubicTo',
        'x1': x1,
        'y1': y1,
        'x2': x2,
        'y2': y2,
        'x': x,
        'y': y,
      };
}

class QuadToCommand extends PathCommand {
  final double x1;
  final double y1;
  final double x;
  final double y;

  const QuadToCommand(this.x1, this.y1, this.x, this.y);

  @override
  void applyTo(Path path, PathPenState state) {
    path.quadraticBezierTo(x1, y1, x, y);
    state.current = Offset(x, y);
    state.lastControl = Offset(x1, y1);
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'quadTo',
        'x1': x1,
        'y1': y1,
        'x': x,
        'y': y,
      };
}

class ArcToCommand extends PathCommand {
  final double rx;
  final double ry;
  final double rotation;
  final bool largeArc;
  final bool sweep;
  final double x;
  final double y;

  const ArcToCommand(this.rx, this.ry, this.rotation, this.largeArc, this.sweep, this.x, this.y);

  @override
  void applyTo(Path path, PathPenState state) {
    // Svg arc to bezier approximation or native ArcToPoint call
    path.arcToPoint(
      Offset(x, y),
      radius: Radius.elliptical(rx, ry),
      rotation: rotation,
      largeArc: largeArc,
      clockwise: sweep,
    );
    state.current = Offset(x, y);
    state.lastControl = Offset(x, y);
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'arcTo',
        'rx': rx,
        'ry': ry,
        'rotation': rotation,
        'largeArc': largeArc,
        'sweep': sweep,
        'x': x,
        'y': y,
      };
}

class CloseCommand extends PathCommand {
  const CloseCommand();

  @override
  void applyTo(Path path, PathPenState state) {
    path.close();
  }

  @override
  Map<String, dynamic> toJson() => {'type': 'close'};
}
