import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../rendering_engine/models/scene_node.dart';
import '../../rendering_engine/canvas/graphics_engine.dart';
import '../../rendering_engine/canvas/render_context.dart';
import '../../rendering_engine/canvas/viewport_transformer.dart';
import '../../rendering_engine/assets/asset_repository.dart';
import '../../rendering_engine/renderers/background_renderer.dart';
import '../../rendering_engine/models/background_state.dart';

class RealtimeCertificatePainter extends CustomPainter {
  final SceneDocument document;
  final Map<String, ui.Image> loadedImages;
  final String? selectedNodeId;
  final String? editingNodeId;

  RealtimeCertificatePainter({
    required this.document,
    required this.loadedImages,
    required this.selectedNodeId,
    this.editingNodeId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgState = document.theme['background'] is BackgroundState
        ? document.theme['background'] as BackgroundState
        : document.theme['background'] is Map<String, dynamic>
            ? BackgroundState.fromJson(Map<String, dynamic>.from(document.theme['background']))
            : const BackgroundState(color: Colors.white);

    BackgroundRenderer().paintToCanvas(
      bgState,
      canvas,
      size,
      imagePool: loadedImages,
    );

    final transformer = ViewportTransformer(
      virtualWidth: document.canvas.virtualWidth,
      virtualHeight: document.canvas.virtualHeight,
      targetSize: size,
    );

    final context = RenderContext(
      canvas: canvas,
      size: size,
      assetRepository: MapAssetRepository(loadedImages),
      viewportTransformer: transformer,
      picturePool: const {},
      outerSpacing: document.canvas.outerSpacing,
      innerSpacing: document.canvas.innerSpacing,
      isEditorMode: true,
    );

    final graphicsEngine = GraphicsEngine();
    graphicsEngine.renderScene(
      context: context,
      layers: document.layers,
      selectedNodeId: selectedNodeId,
      editingNodeId: editingNodeId,
    );
  }

  @override
  bool shouldRepaint(covariant RealtimeCertificatePainter oldDelegate) => true;
}
