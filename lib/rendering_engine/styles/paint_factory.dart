import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/scene_node.dart';

/// Centralizes paint generation and gradient shader configuration.
class PaintFactory {
  static Color parseHexColor(String hex) {
    var cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 6) {
      cleaned = 'FF$cleaned';
    }
    if (cleaned.length == 8) {
      final val = int.tryParse(cleaned, radix: 16);
      if (val != null) return Color(val);
    }
    return const Color(0x00000000);
  }

  static Paint createFillPaint(FillStyle? fill, Rect bounds, double nodeOpacity) {
    final paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    if (fill == null) {
      paint.color = const Color(0x00000000);
      return paint;
    }

    final double finalOpacity = (fill.opacity * nodeOpacity).clamp(0.0, 1.0);

    if (fill.type == GradientType.solid || fill.colors == null || fill.colors!.isEmpty) {
      paint.color = parseHexColor(fill.color ?? '#000000').withOpacity(finalOpacity);
      return paint;
    }

    final colors = fill.colors!.map((c) => parseHexColor(c).withOpacity(finalOpacity)).toList();
    final stops = fill.stops;

    switch (fill.type) {
      case GradientType.linear:
        final beginNorm = fill.begin ?? const Offset(0.0, 0.0);
        final endNorm = fill.end ?? const Offset(1.0, 0.0);
        final begin = Offset(bounds.left + beginNorm.dx * bounds.width, bounds.top + beginNorm.dy * bounds.height);
        final end = Offset(bounds.left + endNorm.dx * bounds.width, bounds.top + endNorm.dy * bounds.height);
        paint.shader = ui.Gradient.linear(begin, end, colors, stops);
        break;
      case GradientType.radial:
        final centerNorm = fill.center ?? const Offset(0.5, 0.5);
        final center = Offset(bounds.left + centerNorm.dx * bounds.width, bounds.top + centerNorm.dy * bounds.height);
        final radius = (fill.radius ?? 0.5) * bounds.width;
        paint.shader = ui.Gradient.radial(center, radius, colors, stops);
        break;
      case GradientType.sweep:
        final centerNorm = fill.center ?? const Offset(0.5, 0.5);
        final center = Offset(bounds.left + centerNorm.dx * bounds.width, bounds.top + centerNorm.dy * bounds.height);
        paint.shader = ui.Gradient.sweep(center, colors, stops);
        break;
      default:
        paint.color = parseHexColor(fill.color ?? '#000000').withOpacity(finalOpacity);
    }

    return paint;
  }

  static Paint createStrokePaint(StrokeStyle stroke, Rect bounds, double nodeOpacity, {double scaleFactor = 1.0}) {
    final paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke.width * scaleFactor;

    switch (stroke.strokeJoin) {
      case 'miter':
        paint.strokeJoin = StrokeJoin.miter;
        break;
      case 'bevel':
        paint.strokeJoin = StrokeJoin.bevel;
        break;
      case 'round':
      default:
        paint.strokeJoin = StrokeJoin.round;
        break;
    }

    switch (stroke.strokeCap) {
      case 'butt':
        paint.strokeCap = StrokeCap.butt;
        break;
      case 'square':
        paint.strokeCap = StrokeCap.square;
        break;
      case 'round':
      default:
        paint.strokeCap = StrokeCap.round;
        break;
    }

    final double finalOpacity = (stroke.opacity * nodeOpacity).clamp(0.0, 1.0);

    if (stroke.fill != null) {
      final fillPaint = createFillPaint(stroke.fill, bounds, finalOpacity);
      paint.color = fillPaint.color;
      paint.shader = fillPaint.shader;
    } else {
      paint.color = parseHexColor(stroke.color).withOpacity(finalOpacity);
    }

    return paint;
  }
}
