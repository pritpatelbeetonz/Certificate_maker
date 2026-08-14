import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/scene_node.dart';
import '../canvas/graphics_engine.dart';
import '../canvas/render_context.dart';
import '../assets/asset_repository.dart';
import '../canvas/viewport_transformer.dart';
import '../models/background_state.dart';
import '../renderers/background_renderer.dart';
import '../engine_enums.dart';

class SceneExportService {
  Future<String> renderSceneToFile({
    required SceneDocument doc,
    required Future<ui.Image> Function(String src) assetImageLoader,
    required Future<ui.Image> Function(String path) fileImageLoader,
    required double aspectDouble,
    List<String>? imagePaths,
    List<SceneNode>? nodes,
    double? workspaceCanvasWidth,
    BackgroundState? backgroundState,
    Map<String, ui.Image>? editorImagePool,
    double quality = 1.0,
    bool watermarkEnabled = true,
    double exportTargetWidth = 1920.0,
    double? outerSpacing,
    double? innerSpacing,
    Uint8List? watermarkBytes,
  }) async {
    final double targetWidth = exportTargetWidth;
    final double targetHeight = targetWidth / aspectDouble;

    debugPrint(
      '📤 [EXPORT START] Base Rendering Resolution: ${targetWidth.toInt()}x${targetHeight.toInt()} (Aspect: ${aspectDouble.toStringAsFixed(2)})',
    );

    final virtualCanvas = doc.canvas;

    // Use current editor nodes directly (including all user additions) if available
    final List<SceneNode> resolvedNodes = nodes ?? doc.layers;

    // 1. Pre-fill imagePool using editor's high-quality/loaded/cropped images
    final Map<String, ui.Image> imagePool = {};
    if (editorImagePool != null) {
      imagePool.addAll(editorImagePool);
      // Remove any user photos so they are decoded fresh at export-level resolution
      for (final node in resolvedNodes) {
        if (node is FrameNode) {
          final index = getImageIndex(node);
          if (index != null) {
            imagePool.remove(node.placeholder.assetId);
          }
        }
      }
    }

    final List<ui.Image> locallyLoadedImages = [];

    try {
      for (final entry in doc.assets.entries) {
        final asset = entry.value;
        if (asset.type != 'image' || imagePool.containsKey(entry.key)) {
          continue;
        }

        try {
          final image = await assetImageLoader(asset.src);
          imagePool[entry.key] = image;
          locallyLoadedImages.add(image);
        } catch (_) {
          final fallbackSrc = asset.fallbackSrc;
          if (fallbackSrc != null && fallbackSrc.isNotEmpty) {
            final image = await assetImageLoader(fallbackSrc);
            imagePool[entry.key] = image;
            locallyLoadedImages.add(image);
          }
        }
      }

      // Preload background image if type is image
      if (backgroundState != null &&
          backgroundState.type == BackgroundType.image &&
          backgroundState.imagePath != null) {
        final bgPath = backgroundState.imagePath!;
        if (!imagePool.containsKey(bgPath)) {
          try {
            final image = await assetImageLoader(bgPath);
            imagePool[bgPath] = image;
            locallyLoadedImages.add(image);
          } catch (_) {
            if (File(bgPath).existsSync()) {
              final image = await fileImageLoader(bgPath);
              imagePool[bgPath] = image;
              locallyLoadedImages.add(image);
            }
          }
        }
      }

      // Load any missing images from paths list
      if (imagePaths != null) {
        for (final node in resolvedNodes) {
          final String? assetId = node is FrameNode
              ? node.placeholder.assetId
              : (node is StickerNode ? node.assetId : null);

          if (assetId != null && !imagePool.containsKey(assetId)) {
            final index = getImageIndex(node);
            if (index != null && index < imagePaths.length) {
              final path = imagePaths[index];
              if (path.isNotEmpty && File(path).existsSync()) {
                final ext = path.split('.').last.toLowerCase();
                final isVideo = [
                  'mp4',
                  'mov',
                  'avi',
                  'mkv',
                  '3gp',
                  'flv',
                  'webm',
                  'qt',
                ].contains(ext);
                final isVideoNode =
                    node is FrameNode && node.placeholder.mediaType == 'video';
                if (isVideo || isVideoNode) {
                  continue;
                }
                final image = await fileImageLoader(path);
                imagePool[assetId] = image;
                locallyLoadedImages.add(image);
              }
            }
          }
        }
      }

      // 1b. Load all SVG vector pictures asynchronously
      final Map<String, ui.Picture> picturePool = {};
      try {
        for (final node in resolvedNodes) {
          if (node is SvgNode) {
            try {
              final PictureInfo pictureInfo = await vg.loadPicture(
                SvgStringLoader(node.pathData),
                null,
              );
              picturePool[node.id] = pictureInfo.picture;
            } catch (e) {
              debugPrint('Error preloading SVG for export: $e');
            }
          }
        }

        // Check if there are image frames (non-video) that should have loaded
        final hasImageFrames = resolvedNodes.any((n) {
          if (n is FrameNode) {
            final index = getImageIndex(n);
            if (imagePaths != null && index != null && index < imagePaths.length) {
              final path = imagePaths[index];
              final ext = path.split('.').last.toLowerCase();
              final isVideo = [
                'mp4',
                'mov',
                'avi',
                'mkv',
                '3gp',
                'flv',
                'webm',
                'qt',
              ].contains(ext);
              return !isVideo && n.placeholder.mediaType != 'video';
            }
          }
          return false;
        });

        if (imagePool.isEmpty && hasImageFrames) {
          throw Exception(
            'No valid images could be loaded for scene rendering.',
          );
        }

        // 2. Setup Canvas
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        // Draw background (using BackgroundRenderer)
        BackgroundRenderer().paintToCanvas(
          backgroundState ?? const BackgroundState(color: Colors.white),
          canvas,
          Size(targetWidth, targetHeight),
          imagePool: imagePool,
        );

        final transformer = ViewportTransformer(
          virtualWidth: virtualCanvas.virtualWidth,
          virtualHeight: virtualCanvas.virtualHeight,
          targetSize: Size(targetWidth, targetHeight),
        );

        final graphicsEngine = GraphicsEngine();
        final context = RenderContext(
          canvas: canvas,
          size: Size(targetWidth, targetHeight),
          assetRepository: MapAssetRepository(imagePool),
          isExportMode: true,
          viewportTransformer: transformer,
          picturePool: picturePool,
          outerSpacing: outerSpacing ?? virtualCanvas.outerSpacing,
          innerSpacing: innerSpacing ?? virtualCanvas.innerSpacing,
        );

        graphicsEngine.renderScene(context: context, layers: resolvedNodes);

        // Draw watermark if enabled
        if (watermarkEnabled) {
          try {
            if (watermarkBytes == null) {
              throw Exception('Watermark bytes not provided');
            }
            final codec = await ui.instantiateImageCodec(watermarkBytes);
            final frameInfo = await codec.getNextFrame();
            final watermarkImage = frameInfo.image;

            final double scale =
                (workspaceCanvasWidth != null && workspaceCanvasWidth > 0)
                ? (targetWidth / workspaceCanvasWidth)
                : (targetWidth / 360.0);

            final double wmHeight = 35.0 * scale;
            final double wmWidth =
                wmHeight * (watermarkImage.width / watermarkImage.height);

            final double wmX = targetWidth - wmWidth - (14.0 * scale);
            final double wmY = targetHeight - wmHeight - (6.0 * scale);

            paintImage(
              canvas: canvas,
              rect: Rect.fromLTWH(wmX, wmY, wmWidth, wmHeight),
              image: watermarkImage,
              fit: BoxFit.contain,
            );
            watermarkImage.dispose();
          } catch (e) {
            debugPrint('Error loading watermark asset: $e');

            final double scale =
                (workspaceCanvasWidth != null && workspaceCanvasWidth > 0)
                ? (targetWidth / workspaceCanvasWidth)
                : (targetWidth / 360.0);

            // Fallback: draw watermark text
            final textPainter = TextPainter(
              text: const TextSpan(
                text: 'CollageKit',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              textDirection: TextDirection.ltr,
            );
            textPainter.layout();
            final double wmX = targetWidth - textPainter.width - (14.0 * scale);
            final double wmY =
                targetHeight - textPainter.height - (6.0 * scale);

            final bgRect = Rect.fromLTWH(
              wmX - (6.0 * scale),
              wmY - (4.0 * scale),
              textPainter.width + (12.0 * scale),
              textPainter.height + (8.0 * scale),
            );
            final bgPaint = Paint()
              ..color = Colors.black.withValues(alpha: 0.5)
              ..style = PaintingStyle.fill;
            final rrect = RRect.fromRectAndRadius(
              bgRect,
              Radius.circular(4.0 * scale),
            );
            canvas.drawRRect(rrect, bgPaint);

            textPainter.paint(canvas, Offset(wmX, wmY));
          }
        }

        // 4. Export to file
        final picture = recorder.endRecording();
        final img = await picture.toImage(
          targetWidth.toInt(),
          targetHeight.toInt(),
        );
        picture.dispose();

        try {
          final double scaleFactor = 0.3 + (0.7 * quality);
          final int exportWidth = (targetWidth * scaleFactor).toInt();
          final int exportHeight = (targetHeight * scaleFactor).toInt();

          debugPrint(
            '📦 [EXPORT COMPRESS] Quality: ${(quality * 100).toInt()}% | Output Resolution: ${exportWidth}x$exportHeight',
          );

          final compressedImg = scaleFactor == 1.0
              ? img
              : await _resizeImage(img, exportWidth, exportHeight);

          try {
            final byteData = await compressedImg.toByteData(
              format: ui.ImageByteFormat.png,
            );

            if (byteData == null) {
              throw Exception('Failed to encode scene image to bytes.');
            }

            final pngBytes = byteData.buffer.asUint8List();

            final tempDir = await getTemporaryDirectory();
            final filePath =
                '${tempDir.path}/scene_${DateTime.now().millisecondsSinceEpoch}.png';
            final file = File(filePath);
            await file.writeAsBytes(pngBytes);

            debugPrint(
              '✅ [EXPORT FINISHED] File Size: ${(pngBytes.length / 1024).toStringAsFixed(1)} KB | Path: $filePath',
            );

            return filePath;
          } finally {
            if (compressedImg != img) {
              compressedImg.dispose();
            }
          }
        } finally {
          img.dispose();
        }
      } finally {
        for (final pic in picturePool.values) {
          pic.dispose();
        }
      }
    } finally {
      for (final img in locallyLoadedImages) {
        img.dispose();
      }
    }
  }

  Future<ui.Image> _resizeImage(ui.Image image, int width, int height) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      image: image,
      fit: BoxFit.fill,
    );
    final picture = recorder.endRecording();
    final resizedImg = await picture.toImage(width, height);
    picture.dispose();
    return resizedImg;
  }
}
