import 'dart:ui';
import '../assets/asset_repository.dart';
import 'viewport_transformer.dart';

/// Holds context parameters required for engine rendering passes.
class RenderContext {
  final Canvas canvas;
  final Size size;
  final AssetRepository assetRepository;
  final double devicePixelRatio;
  final bool isExportMode;
  final bool isEditorMode;
  final bool isSelected;
  final bool isEditing;
  final ViewportTransformer viewportTransformer;
  final Map<String, Picture>? picturePool;
  final double outerSpacing;
  final double innerSpacing;

  RenderContext({
    required this.canvas,
    required this.size,
    required this.assetRepository,
    this.devicePixelRatio = 1.0,
    this.isExportMode = false,
    this.isEditorMode = false,
    this.isSelected = false,
    this.isEditing = false,
    ViewportTransformer? viewportTransformer,
    this.picturePool,
    this.outerSpacing = 0.0,
    this.innerSpacing = 0.0,
  }) : viewportTransformer = viewportTransformer ?? ViewportTransformer(
          virtualWidth: 1000.0,
          virtualHeight: 1000.0,
          targetSize: size,
        );
}
