import 'package:flutter/cupertino.dart';

import '../models/scene_node.dart';
import '../canvas/render_context.dart';
import 'geometry_cache.dart';
import '../styles/style_renderer.dart';

/// Abstract base class for all node renderers that orchestrates style rendering passes.
abstract class BaseNodeRenderer<T extends SceneNode> {
  const BaseNodeRenderer();

  /// Prepares the geometry cache for the node.
  GeometryCache prepareGeometry(Size size, T node) {
    final Path path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    return GeometryCache.fromPath(path);
  }

  /// Subclasses implement this to draw their specific content.
  void drawNodeContent(Canvas canvas, Size size, T node, RenderContext context);

  /// Executes the rendering pipeline in deterministic pass order.
  void renderWithContext(RenderContext context, T node) {
      final canvas = context.canvas;
      final size = context.size;
      debugPrint(
        'Renderer: ${node.id}, '
            'size=$size, '
            'editor=${context.isEditorMode}, '
            'export=${context.isExportMode}',
      );
      final bool hasFlip = node.transform.flipX || node.transform.flipY;
      if (hasFlip) {
        canvas.save();
        canvas.translate(size.width / 2, size.height / 2);
        canvas.scale(
          node.transform.flipX ? -1.0 : 1.0,
          node.transform.flipY ? -1.0 : 1.0,
        );
        canvas.translate(-size.width / 2, -size.height / 2);
      }

      // Resolve node style dynamically to preserve node hierarchy
      NodeStyle? style;
      if (node is FrameNode) {
        style = node.style;
      } else if (node is ShapeNode) {
        style = node.style;
      } else if (node is SvgNode) {
        style = node.style;
      } else if (node is StickerNode) {
        style = node.style;
      }

      final geometry = prepareGeometry(size, node);
      final effects = style?.effects ??
          (node is TextNode ? EffectsStyle(opacity: (node as TextNode).opacity) : const EffectsStyle());

      StyleRenderer.applyEffects(context, effects, () {
        // 1. Background Fill
        if (style?.fill != null) {
          StyleRenderer.drawFill(context, geometry, style?.fill, 1.0);
        }

        // 2. Outer Shadow
        StyleRenderer.drawShadow(context, geometry, style?.shadow ?? const ShadowStyle(), 1.0);

        // 3. Content Rendering (Subclass drawing)
        if (node is StickerNode && context.isEditing) {
          canvas.saveLayer(null, Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.3));
          drawNodeContent(canvas, size, node, context);
          canvas.restore();
        }

        canvas.save();
        if (node is StickerNode) {
          canvas.clipPath(geometry.path);
        }
        drawNodeContent(canvas, size, node, context);
        canvas.restore();

        // 4. Border / Stroke
        StyleRenderer.drawStroke(context, geometry, style?.border ?? const StrokeStyle(), 1.0);

        // 5. Inner Shadow
        StyleRenderer.drawInnerShadow(context, geometry, style?.innerShadow ?? const InnerShadowStyle(), 1.0);

        // 6. Glow
        StyleRenderer.drawGlow(context, geometry, style?.glow ?? const GlowStyle(), 1.0);

        // 7. Selection Overlay (Editor Only)
        if (context.isEditorMode && context.isSelected) {
          final selectionPaint = Paint()
            ..style = PaintingStyle.stroke
            ..color = const Color(0xFF2196F3)
            ..strokeWidth = 2.0;
          canvas.drawPath(geometry.path, selectionPaint);
        }
      });

      if (hasFlip) {
        canvas.restore();
      }
  }
}
