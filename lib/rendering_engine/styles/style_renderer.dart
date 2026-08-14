import 'dart:ui';
import 'package:flutter/material.dart' show Colors, debugPrint;
import '../models/scene_node.dart';
import '../renderers/geometry_cache.dart';
import 'dash_path_builder.dart';
import 'paint_factory.dart';
import '../canvas/render_context.dart';

/// Centralized class to render background fills, borders, shadows, glows, and effects.
class StyleRenderer {
  static void drawFill(RenderContext context, GeometryCache geometry, FillStyle? fill, double nodeOpacity) {
    if (fill == null) return;
    final paint = PaintFactory.createFillPaint(fill, geometry.bounds, nodeOpacity);
    context.canvas.drawPath(geometry.path, paint);
  }

  static void drawStroke(RenderContext context, GeometryCache geometry, StrokeStyle stroke, double nodeOpacity) {
    if (stroke.width <= 0) return;
    
    final scaleFactor = context.viewportTransformer.scaleX;
    
    debugPrint(
      'Stroke: width=${stroke.width}, alignment=${stroke.alignment}',
    );
    final paint = PaintFactory.createStrokePaint(stroke, geometry.bounds, nodeOpacity, scaleFactor: scaleFactor);
    debugPrint(
      'Stroke scale: '
          'width=${stroke.width}, '
          'scaleX=$scaleFactor',
    );
    Path strokePath = geometry.path;
    if (stroke.style == StrokeStyleType.dashed) {
      strokePath = DashPathBuilder.buildDashed(geometry.path, stroke.width * scaleFactor);
    } else if (stroke.style == StrokeStyleType.dotted) {
      strokePath = DashPathBuilder.buildDotted(geometry.path, stroke.width * scaleFactor);
    }

    final canvas = context.canvas;

    if (stroke.alignment == 'inside') {
      canvas.save();
      canvas.clipPath(geometry.path);
      paint.strokeWidth = stroke.width * scaleFactor * 2.0;
      canvas.drawPath(strokePath, paint);
      canvas.restore();
    } else if (stroke.alignment == 'outside') {
      canvas.save();
      final outsideClip = Path.combine(
        PathOperation.difference,
        Path()..addRect(geometry.bounds.inflate(stroke.width * scaleFactor * 2.0)),
        geometry.path,
      );
      canvas.clipPath(outsideClip);
      paint.strokeWidth = stroke.width * scaleFactor * 2.0;
      canvas.drawPath(strokePath, paint);
      canvas.restore();
    } else {
      // center
      canvas.drawPath(strokePath, paint);
    }
  }

  static void drawShadow(RenderContext context, GeometryCache geometry, ShadowStyle shadow, double nodeOpacity) {
    if (!shadow.enabled) return;
    if (shadow.blurRadius <= 0 && shadow.offset == Offset.zero) return;

    final scaleFactor = context.viewportTransformer.scaleX;
    final canvas = context.canvas;
    canvas.save();

    final Color shadowColor = PaintFactory.parseHexColor(shadow.color)
        .withOpacity((shadow.opacity * nodeOpacity).clamp(0.0, 1.0));

    final shadowPaint = Paint()
      ..color = shadowColor
      ..isAntiAlias = true
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius * scaleFactor);

    final shiftedPath = geometry.path.shift(shadow.offset * scaleFactor);

    if (shadow.spreadRadius > 0) {
      final spreadPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = shadow.spreadRadius * scaleFactor * 2.0
        ..color = shadowColor
        ..maskFilter = shadowPaint.maskFilter
        ..isAntiAlias = true;
      canvas.drawPath(shiftedPath, spreadPaint);
    }

    canvas.drawPath(shiftedPath, shadowPaint);
    canvas.restore();
  }

  static void drawInnerShadow(RenderContext context, GeometryCache geometry, InnerShadowStyle innerShadow, double nodeOpacity) {
    if (!innerShadow.enabled) return;

    final scaleFactor = context.viewportTransformer.scaleX;
    final canvas = context.canvas;
    canvas.save();
    canvas.clipPath(geometry.path);

    final Color shadowColor = PaintFactory.parseHexColor(innerShadow.color)
        .withOpacity((innerShadow.opacity * nodeOpacity).clamp(0.0, 1.0));

    final shadowPaint = Paint()
      ..color = shadowColor
      ..isAntiAlias = true
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, innerShadow.blurRadius * scaleFactor);

    // Inflated rect outside the bounds to clip the difference
    final double margin = (innerShadow.blurRadius + innerShadow.spreadRadius + 100.0) * scaleFactor;
    final inversePath = Path.combine(
      PathOperation.difference,
      Path()..addRect(geometry.bounds.inflate(margin)),
      geometry.path,
    );

    final shiftedInverse = inversePath.shift(innerShadow.offset * scaleFactor);

    if (innerShadow.spreadRadius > 0) {
      final spreadPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = innerShadow.spreadRadius * scaleFactor * 2.0
        ..color = shadowColor
        ..maskFilter = shadowPaint.maskFilter
        ..isAntiAlias = true;
      canvas.drawPath(shiftedInverse, spreadPaint);
    }

    canvas.drawPath(shiftedInverse, shadowPaint);
    canvas.restore();
  }

  static void drawGlow(RenderContext context, GeometryCache geometry, GlowStyle glow, double nodeOpacity) {
    if (!glow.enabled) return;
    drawShadow(
      context,
      geometry,
      ShadowStyle(
        enabled: glow.enabled,
        color: glow.color,
        opacity: glow.opacity,
        blurRadius: glow.radius,
        offset: Offset.zero,
      ),
      nodeOpacity,
    );
  }

  static void applyEffects(RenderContext context, EffectsStyle effects, void Function() drawContent) {
    final canvas = context.canvas;
    
    BlendMode blendMode = BlendMode.srcOver;
    switch (effects.blendMode) {
      case BlendModeType.multiply:
        blendMode = BlendMode.multiply;
        break;
      case BlendModeType.screen:
        blendMode = BlendMode.screen;
        break;
      case BlendModeType.overlay:
        blendMode = BlendMode.overlay;
        break;
      case BlendModeType.darken:
        blendMode = BlendMode.darken;
        break;
      case BlendModeType.lighten:
        blendMode = BlendMode.lighten;
        break;
      case BlendModeType.softLight:
        blendMode = BlendMode.softLight;
        break;
      case BlendModeType.hardLight:
        blendMode = BlendMode.hardLight;
        break;
      case BlendModeType.normal:
      default:
        blendMode = BlendMode.srcOver;
    }

    final layerPaint = Paint()
      ..color = Colors.white.withOpacity(effects.opacity.clamp(0.0, 1.0))
      ..blendMode = blendMode;

    canvas.saveLayer(null, layerPaint);
    drawContent();
    canvas.restore();
  }
}
