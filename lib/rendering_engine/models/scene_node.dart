import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/material.dart' show Matrix4;
import '../geometry/vector_geometry.dart';
import '../geometry/svg_path_parser.dart';
import 'virtual_canvas.dart';

abstract class CellMask {
  Path buildPath(Size size);
  Map<String, dynamic> toJson();

  static CellMask fromJson(Map<String, dynamic> json) {
    debugPrint('CellMask.fromJson -> Parsed JSON: $json');
    final type = json['type'] as String? ?? 'rect';
    switch (type) {
      case 'rounded_rect':
        return RoundedRectMask(
          cornerRadius: (json['cornerRadius'] as num? ?? 0.0).toDouble(),
        );
      case 'circle':
        return CircleMask();
      case 'polygon':
        final ptsList = json['points'] as List? ?? [];
        final pts = ptsList
            .map(
              (p) => Offset(
                (p['x'] as num? ?? 0.0).toDouble(),
                (p['y'] as num? ?? 0.0).toDouble(),
              ),
            )
            .toList();
        return PolygonMask(points: pts);
      case 'svg':
        return SvgMask(
          svgPathData: json['svgPathData'] as String? ?? '',
          assetPath: json['assetPath'] as String?,
        );
      case 'boolean':
        final childList = json['children'] as List? ?? [];
        final children = childList
            .map((c) => CellMask.fromJson(Map<String, dynamic>.from(c as Map)))
            .toList();
        return BooleanMask(
          operation: json['operation'] as String? ?? 'intersect',
          children: children,
        );
      case 'rect':
      default:
        return RectMask();
    }
  }
}

class RectMask implements CellMask {
  @override
  Path buildPath(Size size) {
    return Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  @override
  Map<String, dynamic> toJson() => {'type': 'rect'};
}

class RoundedRectMask implements CellMask {
  final double cornerRadius;

  RoundedRectMask({required this.cornerRadius});

  @override
  Path buildPath(Size size) {
    return Path()..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(cornerRadius),
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'rounded_rect',
    'cornerRadius': cornerRadius,
  };
}

class CircleMask implements CellMask {
  @override
  Path buildPath(Size size) {
    return Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  @override
  Map<String, dynamic> toJson() => {'type': 'circle'};
}

class PolygonMask implements CellMask {
  final List<Offset>
  points; // Normalized inside [0.0 - 1.0] relative coordinates

  PolygonMask({required this.points});

  @override
  Path buildPath(Size size) {
    debugPrint(
      'PolygonMask.buildPath -> Incoming size: $size | Points: $points',
    );
    final path = Path();
    if (points.isEmpty) return path;

    path.moveTo(points[0].dx * size.width, points[0].dy * size.height);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx * size.width, points[i].dy * size.height);
    }
    path.close();
    debugPrint(
      'PolygonMask.buildPath -> Generated path bounds: ${path.getBounds()}',
    );
    return path;
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'polygon',
    'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
  };
}

class SvgMask implements CellMask {
  final String svgPathData;
  final String? assetPath;

  SvgMask({required this.svgPathData, this.assetPath});

  @override
  Path buildPath(Size size) {
    if (svgPathData.isEmpty) {
      return Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }
    final commands = SvgPathParser.parse(svgPathData);
    final rawGeometry = VectorGeometry(commands: commands);
    final rawPath = rawGeometry.toPath();
    final bounds = rawPath.getBounds();

    if (bounds.width > 0 && bounds.height > 0) {
      final matrix = Matrix4.identity()
        ..scale(size.width / bounds.width, size.height / bounds.height)
        ..translate(-bounds.left, -bounds.top);
      return rawPath.transform(matrix.storage);
    }
    return rawPath;
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'svg',
    'svgPathData': svgPathData,
    if (assetPath != null) 'assetPath': assetPath,
  };
}

class BooleanMask implements CellMask {
  final String operation; // 'union', 'intersect', 'subtract'
  final List<CellMask> children;

  BooleanMask({required this.operation, required this.children});

  @override
  Path buildPath(Size size) {
    if (children.isEmpty) {
      return Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    Path result = children[0].buildPath(size);

    for (int i = 1; i < children.length; i++) {
      final childPath = children[i].buildPath(size);
      switch (operation) {
        case 'union':
          result = Path.combine(PathOperation.union, result, childPath);
          break;
        case 'subtract':
          result = Path.combine(PathOperation.difference, result, childPath);
          break;
        case 'intersect':
        default:
          result = Path.combine(PathOperation.intersect, result, childPath);
          break;
      }
    }
    return result;
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'boolean',
    'operation': operation,
    'children': children.map((c) => c.toJson()).toList(),
  };
}

class NodeBounds {
  final double x;
  final double y;
  final double width;
  final double height;

  NodeBounds({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory NodeBounds.fromJson(Map<String, dynamic> json) {
    return NodeBounds(
      x: (json['x'] as num? ?? 0.0).toDouble(),
      y: (json['y'] as num? ?? 0.0).toDouble(),
      width: (json['width'] as num? ?? 0.0).toDouble(),
      height: (json['height'] as num? ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'width': width,
    'height': height,
  };

  NodeBounds copyWith({double? x, double? y, double? width, double? height}) {
    return NodeBounds(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}

class NodeTransform {
  final double rotation;
  final Offset pivot;
  final Offset skew;
  final bool flipX;
  final bool flipY;

  NodeTransform({
    this.rotation = 0.0,
    this.pivot = const Offset(0.5, 0.5),
    this.skew = Offset.zero,
    this.flipX = false,
    this.flipY = false,
  });

  factory NodeTransform.fromJson(Map<String, dynamic> json) {
    final pivotJson = json['pivot'] as Map? ?? {};
    final skewJson = json['skew'] as Map? ?? {};
    return NodeTransform(
      rotation: (json['rotation'] as num? ?? 0.0).toDouble(),
      pivot: Offset(
        (pivotJson['x'] as num? ?? 0.5).toDouble(),
        (pivotJson['y'] as num? ?? 0.5).toDouble(),
      ),
      skew: Offset(
        (skewJson['x'] as num? ?? 0.0).toDouble(),
        (skewJson['y'] as num? ?? 0.0).toDouble(),
      ),
      flipX: json['flipX'] as bool? ?? false,
      flipY: json['flipY'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'rotation': rotation,
    'pivot': {'x': pivot.dx, 'y': pivot.dy},
    'skew': {'x': skew.dx, 'y': skew.dy},
    'flipX': flipX,
    'flipY': flipY,
  };

  NodeTransform copyWith({
    double? rotation,
    Offset? pivot,
    Offset? skew,
    bool? flipX,
    bool? flipY,
  }) {
    return NodeTransform(
      rotation: rotation ?? this.rotation,
      pivot: pivot ?? this.pivot,
      skew: skew ?? this.skew,
      flipX: flipX ?? this.flipX,
      flipY: flipY ?? this.flipY,
    );
  }
}

class NodeState {
  final bool visible;
  final bool locked;

  NodeState({this.visible = true, this.locked = false});

  factory NodeState.fromJson(Map<String, dynamic> json) {
    return NodeState(
      visible: json['visible'] as bool? ?? true,
      locked: json['locked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {'visible': visible, 'locked': locked};
}

class NodeInteraction {
  final bool selectable;
  final bool movable;
  final bool editable;
  final double hitPadding;

  NodeInteraction({
    this.selectable = true,
    this.movable = true,
    this.editable = true,
    this.hitPadding = 0.0,
  });

  factory NodeInteraction.fromJson(Map<String, dynamic> json) {
    return NodeInteraction(
      selectable: json['selectable'] as bool? ?? true,
      movable: json['movable'] as bool? ?? true,
      editable: json['editable'] as bool? ?? true,
      hitPadding: (json['hitPadding'] as num? ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'selectable': selectable,
    'movable': movable,
    'editable': editable,
    'hitPadding': hitPadding,
  };
}

class NodePlaceholder {
  final String assetId;
  final String mediaType;
  final double? maxDuration;

  NodePlaceholder({
    required this.assetId,
    this.mediaType = 'image',
    this.maxDuration,
  });

  factory NodePlaceholder.fromJson(Map<String, dynamic> json) {
    return NodePlaceholder(
      assetId: json['assetId'] as String? ?? '',
      mediaType: json['mediaType'] as String? ?? 'image',
      maxDuration: (json['maxDuration'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'assetId': assetId,
    'mediaType': mediaType,
    if (maxDuration != null) 'maxDuration': maxDuration,
  };

  NodePlaceholder copyWith({
    String? assetId,
    String? mediaType,
    double? maxDuration,
  }) {
    return NodePlaceholder(
      assetId: assetId ?? this.assetId,
      mediaType: mediaType ?? this.mediaType,
      maxDuration: maxDuration ?? this.maxDuration,
    );
  }
}

enum StrokeStyleType { solid, dashed, dotted }

enum GradientType { solid, linear, radial, sweep }

enum BlendModeType {
  normal,
  multiply,
  screen,
  overlay,
  darken,
  lighten,
  softLight,
  hardLight,
}

enum ShadowType { outer, inner, glow }

enum RenderPass {
  background,
  fill,
  shadow,
  content,
  stroke,
  innerShadow,
  glow,
  overlay,
  selection,
}

class FillStyle {
  final GradientType type;
  final String? color;
  final double opacity;
  final List<String>? colors;
  final List<double>? stops;
  final Offset? begin;
  final Offset? end;
  final Offset? center;
  final double? radius;

  const FillStyle({
    this.type = GradientType.solid,
    this.color,
    this.opacity = 1.0,
    this.colors,
    this.stops,
    this.begin,
    this.end,
    this.center,
    this.radius,
  });

  factory FillStyle.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'solid';
    final GradientType gType;
    switch (typeStr) {
      case 'linear':
      case 'linearGradient':
        gType = GradientType.linear;
        break;
      case 'radial':
      case 'radialGradient':
        gType = GradientType.radial;
        break;
      case 'sweep':
      case 'sweepGradient':
        gType = GradientType.sweep;
        break;
      case 'solid':
      default:
        gType = GradientType.solid;
        break;
    }

    final colorsList = json['colors'] as List?;
    final colors = colorsList?.map((c) => c as String).toList();
    final stopsList = json['stops'] as List?;
    final stops = stopsList?.map((s) => (s as num).toDouble()).toList();

    Offset? beginOffset;
    if (json['begin'] != null) {
      final b = json['begin'] as Map;
      beginOffset = Offset(
        (b['x'] as num? ?? 0.0).toDouble(),
        (b['y'] as num? ?? 0.0).toDouble(),
      );
    }

    Offset? endOffset;
    if (json['end'] != null) {
      final e = json['end'] as Map;
      endOffset = Offset(
        (e['x'] as num? ?? 0.0).toDouble(),
        (e['y'] as num? ?? 0.0).toDouble(),
      );
    }

    Offset? centerOffset;
    if (json['center'] != null) {
      final c = json['center'] as Map;
      centerOffset = Offset(
        (c['x'] as num? ?? 0.0).toDouble(),
        (c['y'] as num? ?? 0.0).toDouble(),
      );
    }

    return FillStyle(
      type: gType,
      color: json['color'] as String?,
      opacity: (json['opacity'] as num? ?? 1.0).toDouble(),
      colors: colors,
      stops: stops,
      begin: beginOffset,
      end: endOffset,
      center: centerOffset,
      radius: (json['radius'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    if (color != null) 'color': color,
    'opacity': opacity,
    if (colors != null) 'colors': colors,
    if (stops != null) 'stops': stops,
    if (begin != null) 'begin': {'x': begin!.dx, 'y': begin!.dy},
    if (end != null) 'end': {'x': end!.dx, 'y': end!.dy},
    if (center != null) 'center': {'x': center!.dx, 'y': center!.dy},
    if (radius != null) 'radius': radius,
  };
}

class StrokeStyle {
  final double width;
  final String alignment; // 'inside', 'center', 'outside'
  final StrokeStyleType style;
  final String color;
  final FillStyle? fill; // Gradient stroke
  final double opacity;
  final String strokeJoin; // 'miter', 'round', 'bevel'
  final String strokeCap; // 'butt', 'round', 'square'

  // Asymmetric border width values
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;

  const StrokeStyle({
    this.width = 0.0,
    this.alignment = 'inside',
    this.style = StrokeStyleType.solid,
    this.color = '#00000000',
    this.fill,
    this.opacity = 1.0,
    this.strokeJoin = 'round',
    this.strokeCap = 'round',
    this.left,
    this.top,
    this.right,
    this.bottom,
  });

  factory StrokeStyle.fromJson(Map<String, dynamic> json) {
    final styleStr = json['style'] as String? ?? 'solid';
    final StrokeStyleType sType;
    switch (styleStr) {
      case 'dashed':
        sType = StrokeStyleType.dashed;
        break;
      case 'dotted':
        sType = StrokeStyleType.dotted;
        break;
      case 'solid':
      default:
        sType = StrokeStyleType.solid;
        break;
    }

    return StrokeStyle(
      width: (json['width'] as num? ?? 0.0).toDouble(),
      alignment: json['alignment'] as String? ?? 'inside',
      style: sType,
      color: json['color'] as String? ?? '#00000000',
      fill: json['fill'] != null
          ? FillStyle.fromJson(Map<String, dynamic>.from(json['fill'] as Map))
          : null,
      opacity: (json['opacity'] as num? ?? 1.0).toDouble(),
      strokeJoin: json['strokeJoin'] as String? ?? 'round',
      strokeCap: json['strokeCap'] as String? ?? 'round',
      left: json['left'] != null ? (json['left'] as num).toDouble() : null,
      top: json['top'] != null ? (json['top'] as num).toDouble() : null,
      right: json['right'] != null ? (json['right'] as num).toDouble() : null,
      bottom: json['bottom'] != null ? (json['bottom'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'width': width,
    'alignment': alignment,
    'style': style.name,
    'color': color,
    if (fill != null) 'fill': fill!.toJson(),
    'opacity': opacity,
    'strokeJoin': strokeJoin,
    'strokeCap': strokeCap,
    if (left != null) 'left': left,
    if (top != null) 'top': top,
    if (right != null) 'right': right,
    if (bottom != null) 'bottom': bottom,
  };
}

class ShadowStyle {
  final bool enabled;
  final String color;
  final double opacity;
  final Offset offset;
  final double blurRadius;
  final double spreadRadius;

  const ShadowStyle({
    this.enabled = false,
    this.color = '#FF000000',
    this.opacity = 0.30,
    this.offset = const Offset(6.0, 6.0),
    this.blurRadius = 8.0,
    this.spreadRadius = 0.0,
  });

  factory ShadowStyle.fromJson(Map<String, dynamic> json) {
    final offsetJson = json['offset'] as Map? ?? {};
    final bool isEnabled =
        json['enabled'] as bool? ?? json['visible'] as bool? ?? false;
    return ShadowStyle(
      enabled: isEnabled,
      color: json['color'] as String? ?? '#00000000',
      opacity: (json['opacity'] as num? ?? 1.0).toDouble(),
      offset: Offset(
        (offsetJson['x'] as num? ?? 0.0).toDouble(),
        (offsetJson['y'] as num? ?? 0.0).toDouble(),
      ),
      blurRadius: (json['blurRadius'] as num? ?? 0.0).toDouble(),
      spreadRadius: (json['spreadRadius'] as num? ?? 0.0).toDouble(),
    );
  }

  ShadowStyle copyWith({
    bool? enabled,
    String? color,
    double? opacity,
    Offset? offset,
    double? blurRadius,
    double? spreadRadius,
  }) {
    return ShadowStyle(
      enabled: enabled ?? this.enabled,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      offset: offset ?? this.offset,
      blurRadius: blurRadius ?? this.blurRadius,
      spreadRadius: spreadRadius ?? this.spreadRadius,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'color': color,
    'opacity': opacity,
    'offset': {'x': offset.dx, 'y': offset.dy},
    'blurRadius': blurRadius,
    'spreadRadius': spreadRadius,
  };
}

class InnerShadowStyle {
  final bool enabled;
  final String color;
  final double opacity;
  final Offset offset;
  final double blurRadius;
  final double spreadRadius;

  const InnerShadowStyle({
    this.enabled = false,
    this.color = '#00000000',
    this.opacity = 1.0,
    this.offset = Offset.zero,
    this.blurRadius = 0.0,
    this.spreadRadius = 0.0,
  });

  factory InnerShadowStyle.fromJson(Map<String, dynamic> json) {
    final offsetJson = json['offset'] as Map? ?? {};
    return InnerShadowStyle(
      enabled: json['enabled'] as bool? ?? false,
      color: json['color'] as String? ?? '#00000000',
      opacity: (json['opacity'] as num? ?? 1.0).toDouble(),
      offset: Offset(
        (offsetJson['x'] as num? ?? 0.0).toDouble(),
        (offsetJson['y'] as num? ?? 0.0).toDouble(),
      ),
      blurRadius: (json['blurRadius'] as num? ?? 0.0).toDouble(),
      spreadRadius: (json['spreadRadius'] as num? ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'color': color,
    'opacity': opacity,
    'offset': {'x': offset.dx, 'y': offset.dy},
    'blurRadius': blurRadius,
    'spreadRadius': spreadRadius,
  };
}

class GlowStyle {
  final bool enabled;
  final String color;
  final double radius;
  final double opacity;

  const GlowStyle({
    this.enabled = false,
    this.color = '#00000000',
    this.radius = 0.0,
    this.opacity = 1.0,
  });

  factory GlowStyle.fromJson(Map<String, dynamic> json) {
    return GlowStyle(
      enabled: json['enabled'] as bool? ?? false,
      color: json['color'] as String? ?? '#00000000',
      radius: (json['radius'] as num? ?? 0.0).toDouble(),
      opacity: (json['opacity'] as num? ?? 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'color': color,
    'radius': radius,
    'opacity': opacity,
  };
}

class EffectsStyle {
  final double opacity;
  final BlendModeType blendMode;
  final Map<String, dynamic>? filters; // Delayed: structure & json support only

  const EffectsStyle({
    this.opacity = 1.0,
    this.blendMode = BlendModeType.normal,
    this.filters,
  });

  factory EffectsStyle.fromJson(Map<String, dynamic> json) {
    final modeStr = json['blendMode'] as String? ?? 'normal';
    final BlendModeType bMode;
    switch (modeStr) {
      case 'multiply':
        bMode = BlendModeType.multiply;
        break;
      case 'screen':
        bMode = BlendModeType.screen;
        break;
      case 'overlay':
        bMode = BlendModeType.overlay;
        break;
      case 'darken':
        bMode = BlendModeType.darken;
        break;
      case 'lighten':
        bMode = BlendModeType.lighten;
        break;
      case 'softLight':
      case 'soft_light':
        bMode = BlendModeType.softLight;
        break;
      case 'hardLight':
      case 'hard_light':
        bMode = BlendModeType.hardLight;
        break;
      case 'normal':
      default:
        bMode = BlendModeType.normal;
        break;
    }

    return EffectsStyle(
      opacity: (json['opacity'] as num? ?? 1.0).toDouble(),
      blendMode: bMode,
      filters: json['filters'] != null
          ? Map<String, dynamic>.from(json['filters'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'opacity': opacity,
    'blendMode': blendMode.name,
    if (filters != null) 'filters': filters,
  };

  EffectsStyle copyWith({
    double? opacity,
    BlendModeType? blendMode,
    Map<String, dynamic>? filters,
  }) {
    return EffectsStyle(
      opacity: opacity ?? this.opacity,
      blendMode: blendMode ?? this.blendMode,
      filters: filters ?? this.filters,
    );
  }
}

// CornerStyle, PatternStyle, TextureStyle placeholders
class CornerStyle {
  const CornerStyle();
  factory CornerStyle.fromJson(Map<String, dynamic> json) =>
      const CornerStyle();
  Map<String, dynamic> toJson() => {};
}

class PatternStyle {
  const PatternStyle();
  factory PatternStyle.fromJson(Map<String, dynamic> json) =>
      const PatternStyle();
  Map<String, dynamic> toJson() => {};
}

class TextureStyle {
  const TextureStyle();
  factory TextureStyle.fromJson(Map<String, dynamic> json) =>
      const TextureStyle();
  Map<String, dynamic> toJson() => {};
}

class NodeStyle {
  final FillStyle? fill;
  final StrokeStyle border;
  final ShadowStyle shadow;
  final InnerShadowStyle innerShadow;
  final GlowStyle glow;
  final EffectsStyle effects;
  final CornerStyle corner;
  final PatternStyle pattern;
  final TextureStyle texture;

  const NodeStyle({
    this.fill,
    this.border = const StrokeStyle(),
    this.shadow = const ShadowStyle(),
    this.innerShadow = const InnerShadowStyle(),
    this.glow = const GlowStyle(),
    this.effects = const EffectsStyle(),
    this.corner = const CornerStyle(),
    this.pattern = const PatternStyle(),
    this.texture = const TextureStyle(),
  });

  factory NodeStyle.fromJson(Map<String, dynamic> json) {
    FillStyle? fillStyle;
    if (json['fill'] != null) {
      if (json['fill'] is String) {
        fillStyle = FillStyle(color: json['fill'] as String);
      } else {
        fillStyle = FillStyle.fromJson(
          Map<String, dynamic>.from(json['fill'] as Map),
        );
      }
    }

    return NodeStyle(
      fill: fillStyle,
      border: json['border'] != null
          ? StrokeStyle.fromJson(
              Map<String, dynamic>.from(json['border'] as Map),
            )
          : const StrokeStyle(),
      shadow: json['shadow'] != null
          ? ShadowStyle.fromJson(
              Map<String, dynamic>.from(json['shadow'] as Map),
            )
          : const ShadowStyle(),
      innerShadow: json['innerShadow'] != null
          ? InnerShadowStyle.fromJson(
              Map<String, dynamic>.from(json['innerShadow'] as Map),
            )
          : const InnerShadowStyle(),
      glow: json['glow'] != null
          ? GlowStyle.fromJson(Map<String, dynamic>.from(json['glow'] as Map))
          : const GlowStyle(),
      effects: json['effects'] != null
          ? EffectsStyle.fromJson(
              Map<String, dynamic>.from(json['effects'] as Map),
            )
          : const EffectsStyle(),
      corner: json['corner'] != null
          ? CornerStyle.fromJson(
              Map<String, dynamic>.from(json['corner'] as Map),
            )
          : const CornerStyle(),
      pattern: json['pattern'] != null
          ? PatternStyle.fromJson(
              Map<String, dynamic>.from(json['pattern'] as Map),
            )
          : const PatternStyle(),
      texture: json['texture'] != null
          ? TextureStyle.fromJson(
              Map<String, dynamic>.from(json['texture'] as Map),
            )
          : const TextureStyle(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (fill != null) 'fill': fill!.toJson(),
    'border': border.toJson(),
    'shadow': shadow.toJson(),
    'innerShadow': innerShadow.toJson(),
    'glow': glow.toJson(),
    'effects': effects.toJson(),
    'corner': corner.toJson(),
    'pattern': pattern.toJson(),
    'texture': texture.toJson(),
  };

  NodeStyle copyWith({
    FillStyle? fill,
    StrokeStyle? border,
    ShadowStyle? shadow,
    InnerShadowStyle? innerShadow,
    GlowStyle? glow,
    EffectsStyle? effects,
    CornerStyle? corner,
    PatternStyle? pattern,
    TextureStyle? texture,
    bool clearFill = false,
  }) {
    return NodeStyle(
      fill: clearFill ? null : (fill ?? this.fill),
      border: border ?? this.border,
      shadow: shadow ?? this.shadow,
      innerShadow: innerShadow ?? this.innerShadow,
      glow: glow ?? this.glow,
      effects: effects ?? this.effects,
      corner: corner ?? this.corner,
      pattern: pattern ?? this.pattern,
      texture: texture ?? this.texture,
    );
  }
}

abstract class SceneNode {
  String get id;
  String get displayName;
  String get type;
  String get renderPass;
  int get zIndex;
  NodeState get state;
  NodeInteraction get interaction;
  NodeBounds get bounds;
  NodeTransform get transform;

  Map<String, dynamic> toJson();

  SceneNode clone() => SceneNode.fromJson(toJson());

  static SceneNode fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'frame';
    switch (type) {
      case 'group':
        return GroupNode.fromJson(json);
      case 'text':
        return TextNode.fromJson(json);
      case 'sticker':
        return StickerNode.fromJson(json);
      case 'svg':
        return SvgNode.fromJson(json);
      case 'shape':
        return ShapeNode.fromJson(json);
      case 'frame':
      default:
        return FrameNode.fromJson(json);
    }
  }
}

class FrameContent {
  final int slot;
  FrameContent({required this.slot});
}

int? getImageIndex(SceneNode node) {
  if (node is FrameNode) {
    return node.content?.slot;
  } else if (node is StickerNode) {
    final assetId = node.assetId;
    if (assetId.startsWith('placeholder_image_')) {
      final suffix = assetId.substring('placeholder_image_'.length);
      return int.tryParse(suffix);
    }
  }
  return null;
}

class FrameNode implements SceneNode {
  @override
  final String id;
  @override
  final String displayName;
  @override
  final String type = 'frame';
  @override
  final String renderPass;
  @override
  final int zIndex;
  @override
  final NodeState state;
  @override
  final NodeInteraction interaction;
  @override
  final NodeBounds bounds;
  @override
  final NodeTransform transform;

  final NodePlaceholder placeholder;
  final CellMask mask;
  final NodeStyle style;
  final FrameContent? content;

  // Runtime attributes mapping to active loaded assets / transforms
  // Crucial: These properties represent the interactive editor content edits
  final double contentOffsetX;
  final double contentOffsetY;
  final double contentScale;
  final double contentRotation;
  final bool contentFlipX;
  final double padding; // virtual units padding override

  FrameNode({
    required this.id,
    required this.displayName,
    this.renderPass = 'content',
    this.zIndex = 0,
    required this.state,
    required this.interaction,
    required this.bounds,
    required this.transform,
    required this.placeholder,
    required this.mask,
    required this.style,
    this.content,
    this.contentOffsetX = 0.0,
    this.contentOffsetY = 0.0,
    this.contentScale = 1.0,
    this.contentRotation = 0.0,
    this.contentFlipX = false,
    this.padding = 0.0,
  });

  factory FrameNode.fromJson(Map<String, dynamic> json) {
    debugPrint(
      'FrameNode.fromJson -> Frame ID: ${json['id']} | bounds: ${json['bounds']} | mask: ${json['mask']}',
    );
    NodePlaceholder placeholder;
    FrameContent? content;

    if (json['content'] != null) {
      final contentMap = Map<String, dynamic>.from(json['content'] as Map);
      final slot = contentMap['slot'] as int? ?? 0;
      content = FrameContent(slot: slot);
    }

    if (json['placeholder'] != null) {
      placeholder = NodePlaceholder.fromJson(
        Map<String, dynamic>.from(json['placeholder'] as Map),
      );
    } else if (json['content'] != null) {
      final contentMap = Map<String, dynamic>.from(json['content'] as Map);
      final slot = contentMap['slot'] as int? ?? 0;
      placeholder = NodePlaceholder(
        assetId: 'placeholder_image_$slot',
        mediaType: contentMap['mediaType'] as String? ?? 'image',
      );
    } else {
      placeholder = NodePlaceholder(assetId: '');
    }

    return FrameNode(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Frame Layer',
      renderPass: json['renderPass'] as String? ?? 'content',
      zIndex: json['zIndex'] as int? ?? 0,
      state: NodeState.fromJson(
        Map<String, dynamic>.from(json['state'] as Map? ?? {}),
      ),
      interaction: NodeInteraction.fromJson(
        Map<String, dynamic>.from(json['interaction'] as Map? ?? {}),
      ),
      bounds: NodeBounds.fromJson(
        Map<String, dynamic>.from(json['bounds'] as Map? ?? {}),
      ),
      transform: NodeTransform.fromJson(
        Map<String, dynamic>.from(json['transform'] as Map? ?? {}),
      ),
      placeholder: placeholder,
      mask: CellMask.fromJson(
        Map<String, dynamic>.from(json['mask'] as Map? ?? {}),
      ),
      style: NodeStyle.fromJson(
        Map<String, dynamic>.from(json['style'] as Map? ?? {}),
      ),
      content: content,
      contentOffsetX: (json['contentOffsetX'] as num? ?? 0.0).toDouble(),
      contentOffsetY: (json['contentOffsetY'] as num? ?? 0.0).toDouble(),
      contentScale: (json['contentScale'] as num? ?? 1.0).toDouble(),
      contentRotation: (json['contentRotation'] as num? ?? 0.0).toDouble(),
      contentFlipX: json['contentFlipX'] as bool? ?? false,
      padding: (json['padding'] as num? ?? 0.0).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'type': type,
    'renderPass': renderPass,
    'zIndex': zIndex,
    'state': state.toJson(),
    'interaction': interaction.toJson(),
    'bounds': bounds.toJson(),
    'transform': transform.toJson(),
    'placeholder': placeholder.toJson(),
    'mask': mask.toJson(),
    'style': style.toJson(),
    if (content != null) 'content': {'slot': content!.slot},
    'contentOffsetX': contentOffsetX,
    'contentOffsetY': contentOffsetY,
    'contentScale': contentScale,
    'contentRotation': contentRotation,
    'contentFlipX': contentFlipX,
    'padding': padding,
  };

  @override
  SceneNode clone() => SceneNode.fromJson(toJson());

  FrameNode copyWith({
    String? id,
    String? displayName,
    String? renderPass,
    int? zIndex,
    NodeState? state,
    NodeInteraction? interaction,
    NodeBounds? bounds,
    NodeTransform? transform,
    NodePlaceholder? placeholder,
    CellMask? mask,
    NodeStyle? style,
    FrameContent? content,
    double? contentOffsetX,
    double? contentOffsetY,
    double? contentScale,
    double? contentRotation,
    bool? contentFlipX,
    double? padding,
  }) {
    return FrameNode(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      renderPass: renderPass ?? this.renderPass,
      zIndex: zIndex ?? this.zIndex,
      state: state ?? this.state,
      interaction: interaction ?? this.interaction,
      bounds: bounds ?? this.bounds,
      transform: transform ?? this.transform,
      placeholder: placeholder ?? this.placeholder,
      mask: mask ?? this.mask,
      style: style ?? this.style,
      content: content ?? this.content,
      contentOffsetX: contentOffsetX ?? this.contentOffsetX,
      contentOffsetY: contentOffsetY ?? this.contentOffsetY,
      contentScale: contentScale ?? this.contentScale,
      contentRotation: contentRotation ?? this.contentRotation,
      contentFlipX: contentFlipX ?? this.contentFlipX,
      padding: padding ?? this.padding,
    );
  }
}

class GroupNode implements SceneNode {
  @override
  final String id;
  @override
  final String displayName;
  @override
  final String type = 'group';
  @override
  final String renderPass;
  @override
  final int zIndex;
  @override
  final NodeState state;
  @override
  final NodeInteraction interaction;
  @override
  final NodeBounds bounds;
  @override
  final NodeTransform transform;

  final List<SceneNode> children;

  GroupNode({
    required this.id,
    required this.displayName,
    this.renderPass = 'content',
    this.zIndex = 0,
    required this.state,
    required this.interaction,
    required this.bounds,
    required this.transform,
    required this.children,
  });

  factory GroupNode.fromJson(Map<String, dynamic> json) {
    final childrenList = json['children'] as List? ?? [];
    final childNodes = childrenList
        .map((c) => SceneNode.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList();
    return GroupNode(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Group',
      renderPass: json['renderPass'] as String? ?? 'content',
      zIndex: json['zIndex'] as int? ?? 0,
      state: NodeState.fromJson(
        Map<String, dynamic>.from(json['state'] as Map? ?? {}),
      ),
      interaction: NodeInteraction.fromJson(
        Map<String, dynamic>.from(json['interaction'] as Map? ?? {}),
      ),
      bounds: NodeBounds.fromJson(
        Map<String, dynamic>.from(json['bounds'] as Map? ?? {}),
      ),
      transform: NodeTransform.fromJson(
        Map<String, dynamic>.from(json['transform'] as Map? ?? {}),
      ),
      children: childNodes,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'type': type,
    'renderPass': renderPass,
    'zIndex': zIndex,
    'state': state.toJson(),
    'interaction': interaction.toJson(),
    'bounds': bounds.toJson(),
    'transform': transform.toJson(),
    'children': children.map((c) => c.toJson()).toList(),
  };

  @override
  SceneNode clone() => SceneNode.fromJson(toJson());
}

class TextNode implements SceneNode {
  @override
  final String id;
  @override
  final String displayName;
  @override
  final String type = 'text';
  @override
  final String renderPass;
  @override
  final int zIndex;
  @override
  final NodeState state;
  @override
  final NodeInteraction interaction;
  @override
  final NodeBounds bounds;
  @override
  final NodeTransform transform;

  final String text;
  final String fontFamily;
  final double fontSize;
  final String color;
  final String align;
  final String fontWeight;
  final String fontStyle;
  final String decoration;
  final double opacity;
  final double letterSpacing;
  final double wordSpacing;
  final double? lineHeight;
  final ShadowStyle shadow;

  TextNode({
    required this.id,
    required this.displayName,
    this.renderPass = 'text',
    this.zIndex = 0,
    required this.state,
    required this.interaction,
    required this.bounds,
    required this.transform,
    required this.text,
    this.fontFamily = 'System',
    this.fontSize = 14.0,
    this.color = '#FFFFFFFF',
    this.align = 'left',
    this.fontWeight = 'normal',
    this.fontStyle = 'normal',
    this.decoration = 'none',
    this.opacity = 1.0,
    this.letterSpacing = 0.0,
    this.wordSpacing = 0.0,
    this.lineHeight,
    this.shadow = const ShadowStyle(),
  });

  factory TextNode.fromJson(Map<String, dynamic> json) {
    final content = Map<String, dynamic>.from(json['content'] as Map? ?? json);
    return TextNode(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Text Layer',
      renderPass: json['renderPass'] as String? ?? 'text',
      zIndex: json['zIndex'] as int? ?? 0,
      state: NodeState.fromJson(
        Map<String, dynamic>.from(json['state'] as Map? ?? {}),
      ),
      interaction: NodeInteraction.fromJson(
        Map<String, dynamic>.from(json['interaction'] as Map? ?? {}),
      ),
      bounds: NodeBounds.fromJson(
        Map<String, dynamic>.from(json['bounds'] as Map? ?? {}),
      ),
      transform: NodeTransform.fromJson(
        Map<String, dynamic>.from(json['transform'] as Map? ?? {}),
      ),
      text: content['text'] as String? ?? '',
      fontFamily: content['fontFamily'] as String? ?? 'System',
      fontSize: (content['fontSize'] as num? ?? 14.0).toDouble(),
      color: content['color'] as String? ?? '#FFFFFFFF',
      align:
          (content['textAlign'] as String? ??
          content['align'] as String? ??
          'left'),
      fontWeight: content['fontWeight'] as String? ?? 'normal',
      fontStyle: content['fontStyle'] as String? ?? 'normal',
      decoration: content['decoration'] as String? ?? 'none',
      opacity: (content['opacity'] as num? ?? 1.0).toDouble(),
      letterSpacing: (content['letterSpacing'] as num? ?? 0.0).toDouble(),
      wordSpacing: (content['wordSpacing'] as num? ?? 0.0).toDouble(),
      lineHeight: content['lineHeight'] != null ? (content['lineHeight'] as num).toDouble() : null,
      shadow: content['shadow'] != null
          ? ShadowStyle.fromJson(Map<String, dynamic>.from(content['shadow'] as Map))
          : const ShadowStyle(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'type': type,
    'renderPass': renderPass,
    'zIndex': zIndex,
    'state': state.toJson(),
    'interaction': interaction.toJson(),
    'bounds': bounds.toJson(),
    'transform': transform.toJson(),
    'text': text,
    'fontFamily': fontFamily,
    'fontSize': fontSize,
    'color': color,
    'align': align,
    'fontWeight': fontWeight,
    'fontStyle': fontStyle,
    'decoration': decoration,
    'opacity': opacity,
    'letterSpacing': letterSpacing,
    'wordSpacing': wordSpacing,
    if (lineHeight != null) 'lineHeight': lineHeight,
    'shadow': shadow.toJson(),
  };

  @override
  SceneNode clone() => SceneNode.fromJson(toJson());

  TextNode copyWith({
    String? id,
    String? displayName,
    String? renderPass,
    int? zIndex,
    NodeState? state,
    NodeInteraction? interaction,
    NodeBounds? bounds,
    NodeTransform? transform,
    String? text,
    String? fontFamily,
    double? fontSize,
    String? color,
    String? align,
    String? fontWeight,
    String? fontStyle,
    String? decoration,
    double? opacity,
    double? letterSpacing,
    double? wordSpacing,
    double? lineHeight,
    ShadowStyle? shadow,
    bool clearLineHeight = false,
  }) {
    return TextNode(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      renderPass: renderPass ?? this.renderPass,
      zIndex: zIndex ?? this.zIndex,
      state: state ?? this.state,
      interaction: interaction ?? this.interaction,
      bounds: bounds ?? this.bounds,
      transform: transform ?? this.transform,
      text: text ?? this.text,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      align: align ?? this.align,
      fontWeight: fontWeight ?? this.fontWeight,
      fontStyle: fontStyle ?? this.fontStyle,
      decoration: decoration ?? this.decoration,
      opacity: opacity ?? this.opacity,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      wordSpacing: wordSpacing ?? this.wordSpacing,
      lineHeight: clearLineHeight ? null : (lineHeight ?? this.lineHeight),
      shadow: shadow ?? this.shadow,
    );
  }
}

class StickerNode implements SceneNode {
  @override
  final String id;
  @override
  final String displayName;
  @override
  final String type = 'sticker';
  @override
  final String renderPass;
  @override
  final int zIndex;
  @override
  final NodeState state;
  @override
  final NodeInteraction interaction;
  @override
  final NodeBounds bounds;
  @override
  final NodeTransform transform;

  final String assetId;
  final String mediaType;
  final NodeStyle? style;

  final double cropLeft;
  final double cropTop;
  final double cropRight;
  final double cropBottom;
  final String? shape;
  final double cornerRadius;
  final double imageScale;
  final double imageOffsetX;
  final double imageOffsetY;

  StickerNode({
    required this.id,
    required this.displayName,
    this.renderPass = 'sticker',
    this.zIndex = 0,
    required this.state,
    required this.interaction,
    required this.bounds,
    required this.transform,
    required this.assetId,
    this.mediaType = 'image',
    this.style,
    this.cropLeft = 0.0,
    this.cropTop = 0.0,
    this.cropRight = 0.0,
    this.cropBottom = 0.0,
    this.shape,
    this.cornerRadius = 0.0,
    this.imageScale = 1.0,
    this.imageOffsetX = 0.0,
    this.imageOffsetY = 0.0,
  });

  factory StickerNode.fromJson(Map<String, dynamic> json) {
    return StickerNode(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Sticker Layer',
      renderPass: json['renderPass'] as String? ?? 'sticker',
      zIndex: json['zIndex'] as int? ?? 0,
      state: NodeState.fromJson(
        Map<String, dynamic>.from(json['state'] as Map? ?? {}),
      ),
      interaction: NodeInteraction.fromJson(
        Map<String, dynamic>.from(json['interaction'] as Map? ?? {}),
      ),
      bounds: NodeBounds.fromJson(
        Map<String, dynamic>.from(json['bounds'] as Map? ?? {}),
      ),
      transform: NodeTransform.fromJson(
        Map<String, dynamic>.from(json['transform'] as Map? ?? {}),
      ),
      assetId: json['assetId'] as String? ?? '',
      mediaType: json['mediaType'] as String? ?? 'image',
      style: json['style'] != null
          ? NodeStyle.fromJson(Map<String, dynamic>.from(json['style'] as Map))
          : null,
      cropLeft: (json['cropLeft'] as num? ?? 0.0).toDouble(),
      cropTop: (json['cropTop'] as num? ?? 0.0).toDouble(),
      cropRight: (json['cropRight'] as num? ?? 0.0).toDouble(),
      cropBottom: (json['cropBottom'] as num? ?? 0.0).toDouble(),
      shape: json['shape'] as String?,
      cornerRadius: (json['cornerRadius'] as num? ?? 0.0).toDouble(),
      imageScale: (json['imageScale'] as num? ?? 1.0).toDouble(),
      imageOffsetX: (json['imageOffsetX'] as num? ?? 0.0).toDouble(),
      imageOffsetY: (json['imageOffsetY'] as num? ?? 0.0).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'type': type,
    'renderPass': renderPass,
    'zIndex': zIndex,
    'state': state.toJson(),
    'interaction': interaction.toJson(),
    'bounds': bounds.toJson(),
    'transform': transform.toJson(),
    'assetId': assetId,
    'mediaType': mediaType,
    if (style != null) 'style': style!.toJson(),
    'cropLeft': cropLeft,
    'cropTop': cropTop,
    'cropRight': cropRight,
    'cropBottom': cropBottom,
    if (shape != null) 'shape': shape,
    'cornerRadius': cornerRadius,
    'imageScale': imageScale,
    'imageOffsetX': imageOffsetX,
    'imageOffsetY': imageOffsetY,
  };

  @override
  SceneNode clone() => SceneNode.fromJson(toJson());

  StickerNode copyWith({
    String? id,
    String? displayName,
    String? renderPass,
    int? zIndex,
    NodeState? state,
    NodeInteraction? interaction,
    NodeBounds? bounds,
    NodeTransform? transform,
    String? assetId,
    String? mediaType,
    NodeStyle? style,
    double? cropLeft,
    double? cropTop,
    double? cropRight,
    double? cropBottom,
    String? shape,
    bool clearShape = false,
    double? cornerRadius,
    double? imageScale,
    double? imageOffsetX,
    double? imageOffsetY,
  }) {
    return StickerNode(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      renderPass: renderPass ?? this.renderPass,
      zIndex: zIndex ?? this.zIndex,
      state: state ?? this.state,
      interaction: interaction ?? this.interaction,
      bounds: bounds ?? this.bounds,
      transform: transform ?? this.transform,
      assetId: assetId ?? this.assetId,
      mediaType: mediaType ?? this.mediaType,
      style: style ?? this.style,
      cropLeft: cropLeft ?? this.cropLeft,
      cropTop: cropTop ?? this.cropTop,
      cropRight: cropRight ?? this.cropRight,
      cropBottom: cropBottom ?? this.cropBottom,
      shape: clearShape ? null : (shape ?? this.shape),
      cornerRadius: cornerRadius ?? this.cornerRadius,
      imageScale: imageScale ?? this.imageScale,
      imageOffsetX: imageOffsetX ?? this.imageOffsetX,
      imageOffsetY: imageOffsetY ?? this.imageOffsetY,
    );
  }
}

class SceneAsset {
  final String type;
  final String src;
  final String? fallbackSrc;

  SceneAsset({required this.type, required this.src, this.fallbackSrc});

  factory SceneAsset.fromJson(Map<String, dynamic> json) {
    return SceneAsset(
      type: json['type'] as String? ?? 'image',
      src: json['src'] as String? ?? '',
      fallbackSrc: json['fallbackSrc'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'src': src,
    if (fallbackSrc != null) 'fallbackSrc': fallbackSrc,
  };
}

class CollageDivider {
  final String id;
  final String orientation;
  final double coordinate;
  final double startSpan;
  final double endSpan;
  final double minCoordinate;
  final double maxCoordinate;
  final List<String> affectedLeftOrTopLayers;
  final List<String> affectedRightOrBottomLayers;

  CollageDivider({
    required this.id,
    required this.orientation,
    required this.coordinate,
    required this.startSpan,
    required this.endSpan,
    this.minCoordinate = 0.0,
    this.maxCoordinate = 1000.0,
    required this.affectedLeftOrTopLayers,
    required this.affectedRightOrBottomLayers,
  });

  factory CollageDivider.fromJson(Map<String, dynamic> json) {
    return CollageDivider(
      id: json['id'] as String? ?? '',
      orientation: json['orientation'] as String? ?? 'vertical',
      coordinate: (json['coordinate'] as num? ?? 0.0).toDouble(),
      startSpan: (json['startSpan'] as num? ?? 0.0).toDouble(),
      endSpan: (json['endSpan'] as num? ?? 1000.0).toDouble(),
      minCoordinate: (json['minCoordinate'] as num? ?? 0.0).toDouble(),
      maxCoordinate: (json['maxCoordinate'] as num? ?? 1000.0).toDouble(),
      affectedLeftOrTopLayers: List<String>.from(
        json['affectedLeftOrTopLayers'] as List? ?? [],
      ),
      affectedRightOrBottomLayers: List<String>.from(
        json['affectedRightOrBottomLayers'] as List? ?? [],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'orientation': orientation,
    'coordinate': coordinate,
    'startSpan': startSpan,
    'endSpan': endSpan,
    'minCoordinate': minCoordinate,
    'maxCoordinate': maxCoordinate,
    'affectedLeftOrTopLayers': affectedLeftOrTopLayers,
    'affectedRightOrBottomLayers': affectedRightOrBottomLayers,
  };

  CollageDivider copyWith({
    String? id,
    String? orientation,
    double? coordinate,
    double? startSpan,
    double? endSpan,
    double? minCoordinate,
    double? maxCoordinate,
    List<String>? affectedLeftOrTopLayers,
    List<String>? affectedRightOrBottomLayers,
  }) {
    return CollageDivider(
      id: id ?? this.id,
      orientation: orientation ?? this.orientation,
      coordinate: coordinate ?? this.coordinate,
      startSpan: startSpan ?? this.startSpan,
      endSpan: endSpan ?? this.endSpan,
      minCoordinate: minCoordinate ?? this.minCoordinate,
      maxCoordinate: maxCoordinate ?? this.maxCoordinate,
      affectedLeftOrTopLayers:
          affectedLeftOrTopLayers ?? this.affectedLeftOrTopLayers,
      affectedRightOrBottomLayers:
          affectedRightOrBottomLayers ?? this.affectedRightOrBottomLayers,
    );
  }
}

class SceneDocument {
  final String schemaVersion;
  final String minEngineVersion;
  final String compatibilityMode;
  final Map<String, dynamic> metadata;
  final Map<String, dynamic> validation;
  final VirtualCanvas canvas;
  final Map<String, SceneAsset> assets;
  final Map<String, dynamic> theme;
  final List<CollageDivider> dividers;
  final List<SceneNode> layers;

  SceneDocument({
    required this.schemaVersion,
    required this.minEngineVersion,
    required this.compatibilityMode,
    required this.metadata,
    required this.validation,
    required this.canvas,
    required this.assets,
    required this.theme,
    required this.dividers,
    required this.layers,
  });

  factory SceneDocument.fromJson(Map<String, dynamic> json) {
    debugPrint(
      'SceneDocument.fromJson -> JSON loaded with metadata: ${json['metadata']}',
    );
    final assetsMap = json['assets'] as Map? ?? {};
    final assets = assetsMap.map(
      (k, v) => MapEntry(
        k as String,
        SceneAsset.fromJson(Map<String, dynamic>.from(v as Map)),
      ),
    );

    List dividersList = [];
    if (json['dividers'] != null) {
      if (json['dividers'] is Map) {
        dividersList = json['dividers']['handles'] as List? ?? [];
      } else if (json['dividers'] is List) {
        dividersList = json['dividers'] as List;
      }
    }
    final dividers = dividersList
        .map(
          (d) => CollageDivider.fromJson(Map<String, dynamic>.from(d as Map)),
        )
        .toList();

    final layersList = json['scene']?['layers'] as List? ?? [];
    final layers = layersList
        .map((l) => SceneNode.fromJson(Map<String, dynamic>.from(l as Map)))
        .toList();

    return SceneDocument(
      schemaVersion: json['schemaVersion'] as String? ?? '2.1.0',
      minEngineVersion: json['minEngineVersion'] as String? ?? '3.5.0',
      compatibilityMode:
          json['compatibilityMode'] as String? ?? 'graceful_degrade',
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      validation: Map<String, dynamic>.from(json['validation'] as Map? ?? {}),
      canvas: VirtualCanvas.fromJson(
        Map<String, dynamic>.from(json['canvas'] as Map? ?? {}),
      ),
      assets: assets,
      theme: Map<String, dynamic>.from(json['theme'] as Map? ?? {}),
      dividers: dividers,
      layers: layers,
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'minEngineVersion': minEngineVersion,
    'compatibilityMode': compatibilityMode,
    'metadata': metadata,
    'validation': validation,
    'canvas': canvas.toJson(),
    'assets': assets.map((k, v) => MapEntry(k, v.toJson())),
    'theme': theme,
    'dividers': dividers.map((d) => d.toJson()).toList(),
    'scene': {'layers': layers.map((l) => l.toJson()).toList()},
  };

  SceneDocument copyWith({
    String? schemaVersion,
    String? minEngineVersion,
    String? compatibilityMode,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? validation,
    VirtualCanvas? canvas,
    Map<String, SceneAsset>? assets,
    Map<String, dynamic>? theme,
    List<CollageDivider>? dividers,
    List<SceneNode>? layers,
  }) {
    return SceneDocument(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      minEngineVersion: minEngineVersion ?? this.minEngineVersion,
      compatibilityMode: compatibilityMode ?? this.compatibilityMode,
      metadata: metadata ?? this.metadata,
      validation: validation ?? this.validation,
      canvas: canvas ?? this.canvas,
      assets: assets ?? this.assets,
      theme: theme ?? this.theme,
      dividers: dividers ?? this.dividers,
      layers: layers ?? this.layers,
    );
  }
}

class ShapeDefinition {
  final String generatorId;
  final Map<String, dynamic> parameters;

  const ShapeDefinition({
    required this.generatorId,
    this.parameters = const {},
  });

  factory ShapeDefinition.fromJson(Map<String, dynamic> json) {
    return ShapeDefinition(
      generatorId:
          json['generatorId'] as String? ?? json['shape'] as String? ?? 'rect',
      parameters: Map<String, dynamic>.from(
        json['parameters'] as Map? ??
            json['params'] as Map? ??
            (json['points'] is List ? {'points': json['points']} : {}),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'generatorId': generatorId,
    'parameters': parameters,
  };
}

class SvgNode implements SceneNode {
  @override
  final String id;
  @override
  final String displayName;
  @override
  final String type = 'svg';
  @override
  final String renderPass;
  @override
  final int zIndex;
  @override
  final NodeState state;
  @override
  final NodeInteraction interaction;
  @override
  final NodeBounds bounds;
  @override
  final NodeTransform transform;

  final String pathData;
  final NodeStyle style;

  SvgNode({
    required this.id,
    required this.displayName,
    this.renderPass = 'content',
    this.zIndex = 0,
    required this.state,
    required this.interaction,
    required this.bounds,
    required this.transform,
    required this.pathData,
    required this.style,
  });

  factory SvgNode.fromJson(Map<String, dynamic> json) {
    return SvgNode(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'SVG Layer',
      renderPass: json['renderPass'] as String? ?? 'content',
      zIndex: json['zIndex'] as int? ?? 0,
      state: NodeState.fromJson(
        Map<String, dynamic>.from(json['state'] as Map? ?? {}),
      ),
      interaction: NodeInteraction.fromJson(
        Map<String, dynamic>.from(json['interaction'] as Map? ?? {}),
      ),
      bounds: NodeBounds.fromJson(
        Map<String, dynamic>.from(json['bounds'] as Map? ?? {}),
      ),
      transform: NodeTransform.fromJson(
        Map<String, dynamic>.from(json['transform'] as Map? ?? {}),
      ),
      pathData:
          json['geometry']?['pathData'] as String? ??
          json['pathData'] as String? ??
          '',
      style: NodeStyle.fromJson(
        Map<String, dynamic>.from(json['style'] as Map? ?? {}),
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'type': type,
    'renderPass': renderPass,
    'zIndex': zIndex,
    'state': state.toJson(),
    'interaction': interaction.toJson(),
    'bounds': bounds.toJson(),
    'transform': transform.toJson(),
    'geometry': {'pathData': pathData},
    'style': style.toJson(),
  };

  @override
  SceneNode clone() => SceneNode.fromJson(toJson());

  SvgNode copyWith({
    String? id,
    String? displayName,
    String? renderPass,
    int? zIndex,
    NodeState? state,
    NodeInteraction? interaction,
    NodeBounds? bounds,
    NodeTransform? transform,
    String? pathData,
    NodeStyle? style,
  }) {
    return SvgNode(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      renderPass: renderPass ?? this.renderPass,
      zIndex: zIndex ?? this.zIndex,
      state: state ?? this.state,
      interaction: interaction ?? this.interaction,
      bounds: bounds ?? this.bounds,
      transform: transform ?? this.transform,
      pathData: pathData ?? this.pathData,
      style: style ?? this.style,
    );
  }
}

class ShapeNode implements SceneNode {
  @override
  final String id;
  @override
  final String displayName;
  @override
  final String type = 'shape';
  @override
  final String renderPass;
  @override
  final int zIndex;
  @override
  final NodeState state;
  @override
  final NodeInteraction interaction;
  @override
  final NodeBounds bounds;
  @override
  final NodeTransform transform;

  final ShapeDefinition shape;
  final NodeStyle style;

  ShapeNode({
    required this.id,
    required this.displayName,
    this.renderPass = 'content',
    this.zIndex = 0,
    required this.state,
    required this.interaction,
    required this.bounds,
    required this.transform,
    required this.shape,
    required this.style,
  });

  factory ShapeNode.fromJson(Map<String, dynamic> json) {
    return ShapeNode(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Shape Layer',
      renderPass: json['renderPass'] as String? ?? 'content',
      zIndex: json['zIndex'] as int? ?? 0,
      state: NodeState.fromJson(
        Map<String, dynamic>.from(json['state'] as Map? ?? {}),
      ),
      interaction: NodeInteraction.fromJson(
        Map<String, dynamic>.from(json['interaction'] as Map? ?? {}),
      ),
      bounds: NodeBounds.fromJson(
        Map<String, dynamic>.from(json['bounds'] as Map? ?? {}),
      ),
      transform: NodeTransform.fromJson(
        Map<String, dynamic>.from(json['transform'] as Map? ?? {}),
      ),
      shape: ShapeDefinition.fromJson(Map<String, dynamic>.from(json as Map)),
      style: NodeStyle.fromJson(
        Map<String, dynamic>.from(json['style'] as Map? ?? {}),
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'type': type,
    'renderPass': renderPass,
    'zIndex': zIndex,
    'state': state.toJson(),
    'interaction': interaction.toJson(),
    'bounds': bounds.toJson(),
    'transform': transform.toJson(),
    'generatorId': shape.generatorId,
    'parameters': shape.parameters,
    'style': style.toJson(),
  };

  @override
  SceneNode clone() => SceneNode.fromJson(toJson());

  ShapeNode copyWith({
    String? id,
    String? displayName,
    String? renderPass,
    int? zIndex,
    NodeState? state,
    NodeInteraction? interaction,
    NodeBounds? bounds,
    NodeTransform? transform,
    ShapeDefinition? shape,
    NodeStyle? style,
  }) {
    return ShapeNode(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      renderPass: renderPass ?? this.renderPass,
      zIndex: zIndex ?? this.zIndex,
      state: state ?? this.state,
      interaction: interaction ?? this.interaction,
      bounds: bounds ?? this.bounds,
      transform: transform ?? this.transform,
      shape: shape ?? this.shape,
      style: style ?? this.style,
    );
  }
}
