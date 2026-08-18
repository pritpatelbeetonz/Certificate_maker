import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/scene_node.dart';
import 'base_node_renderer.dart';
import '../canvas/render_context.dart';
import 'geometry_cache.dart';
import '../assets/asset_repository.dart';
import 'svg_canvas_renderer.dart';
import 'shape_canvas_renderer.dart';
import 'text_canvas_renderer.dart';
import '../geometry/geometry_factory.dart';
import '../styles/paint_factory.dart';

abstract class CanvasNodeRenderer<T extends SceneNode> {
  void render(Canvas canvas, Size size, T node, Map<String, ui.Image> imagePool);
}

class FrameCanvasRenderer extends BaseNodeRenderer<FrameNode> implements CanvasNodeRenderer<FrameNode> {
  const FrameCanvasRenderer();

  @override
  GeometryCache prepareGeometry(Size size, FrameNode node) {
    final clipPath = node.mask.buildPath(size);
    return GeometryCache.fromPath(clipPath);
  }

  @override
  void drawNodeContent(Canvas canvas, Size size, FrameNode node, RenderContext context) {
    debugPrint('Frame ID: ${node.id} | Parsed mask type: ${node.mask.runtimeType} | Renderer mask type: ${node.mask.runtimeType}');

    final double virtualWidth = node.bounds.width;
    final double scaleFactor = virtualWidth > 0 ? (size.width / virtualWidth) : 1.0;

    final stroke = node.style.border;
    final bool hasAsymmetric = stroke.left != null || stroke.top != null || stroke.right != null || stroke.bottom != null;

    Size currentSize = size;
    double leftPadding = 0.0;
    double topPadding = 0.0;

    if (hasAsymmetric) {
      // 1. Draw solid background card color
      final bgPaint = Paint()
        ..color = PaintFactory.parseHexColor(stroke.color)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Offset.zero & size, bgPaint);

      // 2. Calculate paddings in rendering coordinates
      leftPadding = (stroke.left ?? 0.0) * scaleFactor;
      topPadding = (stroke.top ?? 0.0) * scaleFactor;
      final double rightPadding = (stroke.right ?? 0.0) * scaleFactor;
      final double bottomPadding = (stroke.bottom ?? 0.0) * scaleFactor;

      currentSize = Size(
        size.width - leftPadding - rightPadding,
        size.height - topPadding - bottomPadding,
      );

      canvas.save();
      canvas.translate(leftPadding, topPadding);
    }

    if (context.isExportMode && node.placeholder.mediaType == 'video') {
      final clipPath = node.mask.buildPath(currentSize);
      final paint = Paint()..blendMode = BlendMode.clear;
      canvas.drawPath(clipPath, paint);
      if (hasAsymmetric) {
        canvas.restore();
      }
      return;
    }

    final image = context.assetRepository.getImage(node.placeholder.assetId);
    if (image == null) {
      if (hasAsymmetric) {
        canvas.restore();
      }
      return;
    }

    if (!hasAsymmetric) {
      canvas.save();
    }

    // 2. Clip content to mask boundary
    final clipPath = node.mask.buildPath(currentSize);
    canvas.clipPath(clipPath);

    // 3. Image bounds calculations
    final double imgW = image.width.toDouble();
    final double imgH = image.height.toDouble();
    
    final double rot = node.contentRotation % 360.0;
    final bool isOrthogonal = (rot == 90.0 || rot == 270.0);
    final double effectiveImgW = isOrthogonal ? imgH : imgW;
    final double effectiveImgH = isOrthogonal ? imgW : imgH;

    // BoxFit.cover dynamic base scale inside padded bounds
    final double paddedCellW = currentSize.width - (node.padding * scaleFactor) * 2;
    final double paddedCellH = currentSize.height - (node.padding * scaleFactor) * 2;
    final double baseScale = max(paddedCellW / effectiveImgW, paddedCellH / effectiveImgH);

    // 4. Translate to center + offset (scaled to current scaleFactor)
    canvas.translate(
      currentSize.width / 2 + node.contentOffsetX * scaleFactor,
      currentSize.height / 2 + node.contentOffsetY * scaleFactor,
    );

    // 5. Scale
    canvas.scale(baseScale * node.contentScale);

    // 5b. Apply horizontal flip if set
    if (node.contentFlipX) {
      canvas.scale(-1.0, 1.0);
    }

    // 6. Rotate
    canvas.rotate(node.contentRotation * pi / 180.0);

    // 7. Draw centered at origin
    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = ui.FilterQuality.high;
    canvas.drawImage(image, Offset(-imgW / 2, -imgH / 2), paint);

    canvas.restore();
  }

  // Satisfy backward-compatibility map direct calls
  @override
  void render(Canvas canvas, Size size, FrameNode node, Map<String, ui.Image> imagePool) {
    final context = RenderContext(
      canvas: canvas,
      size: size,
      assetRepository: MapAssetRepository(imagePool),
    );
    super.renderWithContext(context, node);
  }
}

class StickerCanvasRenderer extends BaseNodeRenderer<StickerNode> implements CanvasNodeRenderer<StickerNode> {
  const StickerCanvasRenderer();

  @override
  GeometryCache prepareGeometry(Size size, StickerNode node) {
    if (node.cornerRadius > 0 && (node.shape == null || node.shape!.isEmpty || node.shape == 'rect')) {
      final double side = node.shape == 'rect' ? min(size.width, size.height) : 0;
      final Path path;
      if (node.shape == 'rect') {
        final double left = (size.width - side) / 2;
        final double top = (size.height - side) / 2;
        path = Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(left, top, side, side),
            Radius.circular(node.cornerRadius),
          ));
      } else {
        path = Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, size.height),
            Radius.circular(node.cornerRadius),
          ));
      }
      return GeometryCache.fromPath(path);
    }

    if (node.shape != null && node.shape!.isNotEmpty) {
      if (node.shape == 'rect') {
        final double side = min(size.width, size.height);
        final double left = (size.width - side) / 2;
        final double top = (size.height - side) / 2;
        final path = Path()..addRect(Rect.fromLTWH(left, top, side, side));
        return GeometryCache.fromPath(path);
      }

      final String generatorId;
      final Map<String, dynamic> params;
      if (node.shape == 'triangle') {
        generatorId = 'polygon';
        params = {'sides': 3};
      } else {
        generatorId = node.shape!;
        params = {};
      }
      final geometry = GeometryFactory.generate(
        generatorId,
        size.width,
        size.height,
        params,
      );
      return GeometryCache.fromPath(geometry.toPath());
    }
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    return GeometryCache.fromPath(path);
  }

  @override
  void drawNodeContent(Canvas canvas, Size size, StickerNode node, RenderContext context) {
    final picture = context.picturePool != null ? context.picturePool![node.assetId] : null;
    if (picture != null) {
      canvas.save();
      final double virtualWidth = node.bounds.width;
      final double scaleFactor = virtualWidth > 0 ? (size.width / virtualWidth) : 1.0;
      canvas.scale(scaleFactor);
      canvas.drawPicture(picture);
      canvas.restore();
      return;
    }

    final image = context.assetRepository.getImage(node.assetId);
    if (image == null) return;

    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = ui.FilterQuality.high;

    if (node.style?.fill != null && node.style!.fill!.color != null) {
      final color = PaintFactory.parseHexColor(node.style!.fill!.color!);
      paint.colorFilter = ColorFilter.mode(color, BlendMode.srcATop);
    }

    // 1. Calculate scale factor from virtual coordinate system to actual rendering canvas size
    final double virtualWidth = node.bounds.width;
    final double scaleFactor = virtualWidth > 0 ? (size.width / virtualWidth) : 1.0;

    final stroke = node.style?.border;
    final bool hasAsymmetric = stroke != null &&
        (stroke.left != null || stroke.top != null || stroke.right != null || stroke.bottom != null);

    Size currentSize = size;
    double leftPadding = 0.0;
    double topPadding = 0.0;

    if (hasAsymmetric) {
      // Draw solid background card color
      final bgPaint = Paint()
        ..color = PaintFactory.parseHexColor(stroke.color)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Offset.zero & size, bgPaint);

      // Calculate paddings in rendering coordinates
      leftPadding = (stroke.left ?? 0.0) * scaleFactor;
      topPadding = (stroke.top ?? 0.0) * scaleFactor;
      final double rightPadding = (stroke.right ?? 0.0) * scaleFactor;
      final double bottomPadding = (stroke.bottom ?? 0.0) * scaleFactor;

      currentSize = Size(
        size.width - leftPadding - rightPadding,
        size.height - topPadding - bottomPadding,
      );

      canvas.save();
      canvas.translate(leftPadding, topPadding);
      canvas.clipRect(Offset.zero & currentSize);
    }

    canvas.save();

    // 2. Image bounds calculations
    final double imgW = image.width.toDouble();
    final double imgH = image.height.toDouble();

    // BoxFit.cover base scale
    final double baseScale = max(currentSize.width / imgW, currentSize.height / imgH);

    // 3. Translate to center + offset (scaled by scaleFactor)
    canvas.translate(
      currentSize.width / 2 + node.imageOffsetX * scaleFactor,
      currentSize.height / 2 + node.imageOffsetY * scaleFactor,
    );

    // 4. Scale by baseScale * imageScale
    canvas.scale(baseScale * node.imageScale);

    // 5. Draw centered at origin
    canvas.drawImage(image, Offset(-imgW / 2, -imgH / 2), paint);

    canvas.restore();

    if (hasAsymmetric) {
      canvas.restore();
    }
  }

  @override
  void render(Canvas canvas, Size size, StickerNode node, Map<String, ui.Image> imagePool) {
    final context = RenderContext(
      canvas: canvas,
      size: size,
      assetRepository: MapAssetRepository(imagePool),
    );
    super.renderWithContext(context, node);
  }
}

class CanvasRendererRegistry {
  final Map<Type, CanvasNodeRenderer> _renderers = {};

  CanvasRendererRegistry() {
    register<FrameNode>(const FrameCanvasRenderer());
    register<SvgNode>(const SvgCanvasRenderer());
    register<ShapeNode>(const ShapeCanvasRenderer());
    register<TextNode>(const TextCanvasRenderer());
    register<StickerNode>(const StickerCanvasRenderer());
  }

  void register<T extends SceneNode>(CanvasNodeRenderer<T> renderer) {
    _renderers[T] = renderer;
  }

  CanvasNodeRenderer? getRendererForNode(SceneNode node) {
    return _renderers[node.runtimeType];
  }

  void renderNode(Canvas canvas, Size size, SceneNode node, Map<String, ui.Image> imagePool) {
    final renderer = _renderers[node.runtimeType];
    if (renderer != null) {
      renderer.render(canvas, size, node, imagePool);
    }
  }
}
