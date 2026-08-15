import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/scene_node.dart';
import '../renderers/canvas_renderer_registry.dart';
import 'render_context.dart';
import '../assets/asset_repository.dart';
import '../renderers/base_node_renderer.dart';

/// Single entry point coordinating all rendering stages, scene traversal, and style subsystems.
class GraphicsEngine {
  final CanvasRendererRegistry registry;

  GraphicsEngine({CanvasRendererRegistry? registry})
      : registry = registry ?? CanvasRendererRegistry();

  /// Calculates the visual bounds of a FrameNode by applying outer/inner layout spacing
  Rect getFrameInsetBounds({
    required Rect bounds,
    required double virtualWidth,
    required double virtualHeight,
    required double outerSpacing,
    required double innerSpacing,
  }) {
    double leftInset = (bounds.left.abs() < 0.1) ? outerSpacing : (innerSpacing / 2);
    double rightInset = ((bounds.right - virtualWidth).abs() < 0.1) ? outerSpacing : (innerSpacing / 2);
    double topInset = (bounds.top.abs() < 0.1) ? outerSpacing : (innerSpacing / 2);
    double bottomInset = ((bounds.bottom - virtualHeight).abs() < 0.1) ? outerSpacing : (innerSpacing / 2);

    return Rect.fromLTRB(
      bounds.left + leftInset,
      bounds.top + topInset,
      bounds.right - rightInset,
      bounds.bottom - bottomInset,
    );
  }

  void renderScene({
    required RenderContext context,
    required List<SceneNode> layers,
    String? selectedNodeId,
    String? editingNodeId,
  }) {
    // Traverse scene, filter visible layers, and sort by z-index
    final List<SceneNode> sortedLayers = layers.where((l) => l.state.visible).toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    final transformer = context.viewportTransformer;
    final double virtualWidth = transformer.virtualWidth;
    final double virtualHeight = transformer.virtualHeight;
    final double outer = context.outerSpacing;
    final double inner = context.innerSpacing;

    for (final node in sortedLayers) {
      if (editingNodeId != null && node.id == editingNodeId) {
        continue;
      }
      double x = node.bounds.x;
      double y = node.bounds.y;
      double w = node.bounds.width;
      double h = node.bounds.height;

      // Apply layout spacing insets visually for frame cells
      if (node is FrameNode && (outer > 0 || inner > 0)) {
        final inset = getFrameInsetBounds(
          bounds: Rect.fromLTWH(x, y, w, h),
          virtualWidth: virtualWidth,
          virtualHeight: virtualHeight,
          outerSpacing: outer,
          innerSpacing: inner,
        );
        x = inset.left;
        y = inset.top;
        w = inset.width;
        h = inset.height;
      }

      final double cellX = transformer.toScreenX(x);
      final double cellY = transformer.toScreenY(y);
      final double cellW = transformer.toScreenWidth(w);
      final double cellH = transformer.toScreenHeight(h);

      context.canvas.save();
      context.canvas.translate(cellX, cellY);

      if (node.transform.rotation != 0.0) {
        context.canvas.translate(cellW / 2, cellH / 2);
        context.canvas.rotate(node.transform.rotation * 3.141592653589793 / 180.0);
        context.canvas.translate(-cellW / 2, -cellH / 2);
      }

      final renderer = registry.getRendererForNode(node);
      if (renderer != null) {
        final nodeSize = Size(cellW, cellH);
        final nodeContext = RenderContext(
          canvas: context.canvas,
          size: nodeSize,
          assetRepository: context.assetRepository,
          devicePixelRatio: context.devicePixelRatio,
          isExportMode: context.isExportMode,
          isEditorMode: context.isEditorMode,
          isSelected: context.isSelected && (selectedNodeId != null && node.id == selectedNodeId),
          isEditing: editingNodeId != null && node.id == editingNodeId,
          picturePool: context.picturePool,
          viewportTransformer: context.viewportTransformer,
        );

        if (renderer is BaseNodeRenderer) {
          (renderer as BaseNodeRenderer).renderWithContext(nodeContext, node);
        } else {
          // Fallback call for any non-BaseNodeRenderer registry delegates
          // using the MapAssetRepository adapter if needed.
          if (context.assetRepository is MapAssetRepository) {
            final pool = (context.assetRepository as MapAssetRepository).getImagePoolMap();
            renderer.render(context.canvas, nodeSize, node, pool);
          }
        }
      }

      context.canvas.restore();
    }
  }
}

extension on MapAssetRepository {
  Map<String, ui.Image> getImagePoolMap() {
    // Expose inner map for fallback renderer compatibility
    return imagePool;
  }
}
