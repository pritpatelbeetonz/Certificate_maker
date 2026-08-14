# Custom Rendering Engine Module

This folder contains the complete, decoupled custom rendering engine. You can drop this module into any Flutter project and start rendering complex scenes, frames, stickers, SVGs, texts, shapes, and borders.

---

## 1. Installation Requirements

To use this module in another Flutter project:
1. Copy the `rendering_engine/` folder into your new project's `lib/` directory.
2. Add the following dependencies to your project's `pubspec.yaml`:
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     flutter_svg: ^2.0.0      # Required for SVG picture loading
     path_provider: ^2.0.0    # Required by the export service to resolve temp paths
   ```

---

## 2. Basic Usage Guide

Here is a step-by-step example of how to load a scene, render it to the screen in real-time, and export it.

### Step 2.1: Loading a Scene
Parse the SceneDocument from JSON (typically retrieved from a database, file, or network):
```dart
import 'package:your_project/rendering_engine/models/scene_node.dart';

final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
final SceneDocument document = SceneDocument.fromJson(jsonMap);
```

### Step 2.2: Real-time Canvas Painting (UI)
Create a `CustomPainter` to draw the scene on the screen using the `GraphicsEngine`.

```dart
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:your_project/rendering_engine/canvas/graphics_engine.dart';
import 'package:your_project/rendering_engine/canvas/render_context.dart';
import 'package:your_project/rendering_engine/canvas/viewport_transformer.dart';
import 'package:your_project/rendering_engine/assets/asset_repository.dart';

class RealtimeScenePainter extends CustomPainter {
  final SceneDocument document;
  final Map<String, ui.Image> loadedImages; // Preloaded images pool
  final Map<String, ui.Picture> loadedPictures; // Preloaded SVG picture pool

  RealtimeScenePainter({
    required this.document,
    required this.loadedImages,
    required this.loadedPictures,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Background
    BackgroundRenderer().paintToCanvas(
      document.theme['background'] ?? const BackgroundState(color: Colors.white),
      canvas,
      size,
      imagePool: loadedImages,
    );

    // 2. Setup Coordinate Mappings (e.g. mapping virtual 1000x1000 to screen size)
    final transformer = ViewportTransformer(
      virtualWidth: document.canvas.virtualWidth,
      virtualHeight: document.canvas.virtualHeight,
      targetSize: size,
    );

    // 3. Create Render Context
    final context = RenderContext(
      canvas: canvas,
      size: size,
      assetRepository: MapAssetRepository(loadedImages),
      viewportTransformer: transformer,
      picturePool: loadedPictures,
      outerSpacing: document.canvas.outerSpacing,
      innerSpacing: document.canvas.innerSpacing,
      isEditorMode: true, // Highlights selected layer boundaries if selected
    );

    // 4. Render Scene Layers
    final graphicsEngine = GraphicsEngine();
    graphicsEngine.renderScene(
      context: context,
      layers: document.layers,
    );
  }

  @override
  bool shouldRepaint(covariant RealtimeScenePainter oldDelegate) => true;
}
```

### Step 2.3: Rendering the Painter in a Widget
Wrap your `CustomPainter` inside a `CustomPaint` widget:
```dart
Widget build(BuildContext context) {
  return CustomPaint(
    size: Size(300, 300), // Target viewport size
    painter: RealtimeScenePainter(
      document: myDocument,
      loadedImages: myImagePool,
      loadedPictures: myPicturePool,
    ),
  );
}
```

---

## 3. Scene Exporting

To export the scene to a high-quality PNG/image file on disk, invoke `SceneExportService`:

```dart
import 'package:your_project/rendering_engine/export/scene_export_service.dart';

final exportService = SceneExportService();

final String exportedFilePath = await exportService.renderSceneToFile(
  doc: document,
  aspectDouble: 1.0, // Output aspect ratio (width / height)
  exportTargetWidth: 1920.0, // Target render width
  quality: 0.9, // Quality factor
  watermarkEnabled: false,
  assetImageLoader: (String src) async {
    // Load local asset bundle images
    final byteData = await rootBundle.load(src);
    final codec = await ui.instantiateImageCodec(byteData.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  },
  fileImageLoader: (String filePath) async {
    // Load user/camera gallery images from disk path
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  },
);

print('Scene exported successfully to: $exportedFilePath');
```
