import 'dart:typed_data';
import 'dart:ui';
import 'path_command.dart';

/// Immutable model of vector geometries containing commands, fill rules, and transforms.
class VectorGeometry {
  final List<PathCommand> commands;
  final PathFillType fillRule;
  final Float64List? transform;

  const VectorGeometry({
    required this.commands,
    this.fillRule = PathFillType.nonZero,
    this.transform,
  });

  /// Generates the Flutter Path from the command list lazily.
  Path toPath() {
    final path = Path()..fillType = fillRule;
    final state = PathPenState();
    for (final cmd in commands) {
      cmd.applyTo(path, state);
    }
    if (transform != null) {
      return path.transform(transform!);
    }
    return path;
  }

  factory VectorGeometry.fromJson(Map<String, dynamic> json) {
    final commandsList = json['commands'] as List? ?? [];
    final commands = commandsList
        .map((c) => PathCommand.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList();

    final fillRuleStr = json['fillRule'] as String? ?? 'nonZero';
    final fillRule = fillRuleStr == 'evenOdd' ? PathFillType.evenOdd : PathFillType.nonZero;

    final transformList = json['transform'] as List?;
    final transform = transformList != null
        ? Float64List.fromList(transformList.map((t) => (t as num).toDouble()).toList())
        : null;

    return VectorGeometry(
      commands: commands,
      fillRule: fillRule,
      transform: transform,
    );
  }

  Map<String, dynamic> toJson() => {
        'commands': commands.map((c) => c.toJson()).toList(),
        'fillRule': fillRule == PathFillType.evenOdd ? 'evenOdd' : 'nonZero',
        if (transform != null) 'transform': transform!.toList(),
      };
}
