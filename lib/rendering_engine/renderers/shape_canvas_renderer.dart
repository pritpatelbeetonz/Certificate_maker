import 'dart:ui';
import 'dart:ui' as ui;
import '../models/scene_node.dart';
import 'base_node_renderer.dart';
import 'geometry_cache.dart';
import '../canvas/render_context.dart';
import '../geometry/geometry_factory.dart';

import 'canvas_renderer_registry.dart';
import '../assets/asset_repository.dart';

class ShapeCanvasRenderer extends BaseNodeRenderer<ShapeNode> implements CanvasNodeRenderer<ShapeNode> {
  const ShapeCanvasRenderer();

  @override
  GeometryCache prepareGeometry(Size size, ShapeNode node) {
    final geometry = GeometryFactory.generate(
      node.shape.generatorId,
      size.width,
      size.height,
      node.shape.parameters,
    );
    return GeometryCache.fromPath(geometry.toPath());
  }

  @override
  void drawNodeContent(Canvas canvas, Size size, ShapeNode node, RenderContext context) {
    // ShapeNode is a pure vector path. Background fill and strokes are handled
    // generically in the BaseNodeRenderer lifecycle, no additional content is drawn.
  }

  @override
  void render(Canvas canvas, Size size, ShapeNode node, Map<String, ui.Image> imagePool) {
    final context = RenderContext(
      canvas: canvas,
      size: size,
      assetRepository: MapAssetRepository(imagePool),
    );
    super.renderWithContext(context, node);
  }
}
