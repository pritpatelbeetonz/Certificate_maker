import 'dart:ui';
import 'dart:ui' as ui;
import '../models/scene_node.dart';
import 'base_node_renderer.dart';
import 'geometry_cache.dart';
import '../canvas/render_context.dart';
import '../geometry/vector_geometry.dart';
import '../geometry/svg_path_parser.dart';
import '../styles/paint_factory.dart';
import 'package:flutter/material.dart' show Matrix4, Colors;

import 'canvas_renderer_registry.dart';
import '../assets/asset_repository.dart';

class SvgCanvasRenderer extends BaseNodeRenderer<SvgNode> implements CanvasNodeRenderer<SvgNode> {
  const SvgCanvasRenderer();

  @override
  GeometryCache prepareGeometry(Size size, SvgNode node) {
    final Path combinedPath = Path();

    // 1. Extract all SVG <path d="..." /> tags and parse them
    final pathRegex = RegExp(r'\bd="([^"]+)"');
    final pathMatches = pathRegex.allMatches(node.pathData);
    for (final match in pathMatches) {
      final pathStr = match.group(1);
      if (pathStr != null && pathStr.isNotEmpty) {
        final commands = SvgPathParser.parse(pathStr);
        final geometry = VectorGeometry(commands: commands);
        combinedPath.addPath(geometry.toPath(), Offset.zero);
      }
    }

    // 2. Extract and parse all <circle cx="..." cy="..." r="..." /> tags
    final circleRegex = RegExp(r'<circle\s+[^>]*cx="([^"]+)"\s+[^>]*cy="([^"]+)"\s+[^>]*r="([^"]+)"');
    final circleMatches = circleRegex.allMatches(node.pathData);
    for (final match in circleMatches) {
      final cx = double.tryParse(match.group(1) ?? '') ?? 0.0;
      final cy = double.tryParse(match.group(2) ?? '') ?? 0.0;
      final r = double.tryParse(match.group(3) ?? '') ?? 0.0;
      if (r > 0) {
        combinedPath.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      }
    }

    final bounds = combinedPath.getBounds();
    if (bounds.width > 0 && bounds.height > 0) {
      // Scale and translate path to fit the destination size bounds
      final matrix = Matrix4.identity()
        ..scale(size.width / bounds.width, size.height / bounds.height)
        ..translate(-bounds.left, -bounds.top);
      final scaledPath = combinedPath.transform(matrix.storage);
      return GeometryCache.fromPath(scaledPath);
    }
    return GeometryCache.fromPath(combinedPath);
  }

  @override
  void drawNodeContent(Canvas canvas, Size size, SvgNode node, RenderContext context) {
    if (context.picturePool != null && context.picturePool!.containsKey(node.id)) {
      final picture = context.picturePool![node.id]!;
      
      // Parse viewBox width and height to scale picture to fit destination size
      final viewBoxRegex = RegExp(r'viewBox="([^"]+)"');
      final match = viewBoxRegex.firstMatch(node.pathData);
      double vbW = 72.0;
      double vbH = 72.0;
      if (match != null) {
        final parts = match.group(1)!.trim().split(RegExp(r'\s+'));
        if (parts.length == 4) {
          vbW = double.tryParse(parts[2]) ?? 72.0;
          vbH = double.tryParse(parts[3]) ?? 72.0;
        }
      }
      
      final double scaleX = size.width / vbW;
      final double scaleY = size.height / vbH;
      final double scale = scaleX < scaleY ? scaleX : scaleY;
      
      final double dx = (size.width - vbW * scale) / 2;
      final double dy = (size.height - vbH * scale) / 2;
      
      canvas.save();
      canvas.translate(dx, dy);
      canvas.scale(scale, scale);
      
      // If a custom (non-default) fill style is present, colorize the vector graphic
      if (node.style.fill != null && node.style.fill!.color != '#FFFFD700') {
        final color = PaintFactory.parseHexColor(node.style.fill!.color ?? '#000000');
        final paint = Paint()
          ..colorFilter = ColorFilter.mode(color, BlendMode.srcIn);
        canvas.saveLayer(null, paint);
        canvas.drawPicture(picture);
        canvas.restore();
      } else {
        canvas.drawPicture(picture);
      }
      canvas.restore();
    } else {
      // Fallback: draw parsed path using amber if style fill is null
      if (node.style.fill == null) {
        final geometry = prepareGeometry(size, node);
        final paint = Paint()
          ..color = Colors.amber
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;
        canvas.drawPath(geometry.path, paint);
      }
    }
  }

  @override
  void render(Canvas canvas, Size size, SvgNode node, Map<String, ui.Image> imagePool) {
    final context = RenderContext(
      canvas: canvas,
      size: size,
      assetRepository: MapAssetRepository(imagePool),
    );
    super.renderWithContext(context, node);
  }
}
