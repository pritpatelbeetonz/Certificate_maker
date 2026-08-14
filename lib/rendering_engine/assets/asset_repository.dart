import 'dart:ui' as ui;

/// Decouples renderers from raw image resource maps, preparing the system for various asset types.
abstract class AssetRepository {
  ui.Image? getImage(String id);
  Future<ui.Image?> loadImage(String id);
}

/// An adapter wrapping a standard image pool map.
class MapAssetRepository implements AssetRepository {
  final Map<String, ui.Image> _imagePool;

  MapAssetRepository(this._imagePool);

  Map<String, ui.Image> get imagePool => _imagePool;

  @override
  ui.Image? getImage(String id) => _imagePool[id];

  @override
  Future<ui.Image?> loadImage(String id) async => _imagePool[id];
}
