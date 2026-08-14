import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/background_state.dart';
import '../engine_enums.dart';

/// Reusable abstraction for rendering the canvas background.
/// Can be used to build a Widget for the UI or paint to a Canvas for export.
class BackgroundRenderer {
  final Widget Function(BuildContext context, String path)? imageBackgroundBuilder;

  BackgroundRenderer({this.imageBackgroundBuilder});

  /// Builds a Flutter Widget for real-time editor rendering.
  Widget buildWidget(BuildContext context, BackgroundState state) {
    switch (state.type) {
      case BackgroundType.color:
      case BackgroundType.transparent:
        return ColoredBox(
          color: state.color ?? Colors.transparent,
        );

      case BackgroundType.gradient:
        if (state.gradient == null) return const SizedBox.shrink();
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: state.gradient!.colors,
              stops: state.gradient!.stops,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );

      case BackgroundType.image:
        if (state.imagePath == null) return const SizedBox.shrink();
        final String path = state.imagePath!;
        Widget imageWidget;

        if (imageBackgroundBuilder != null) {
          imageWidget = imageBackgroundBuilder!(context, path);
        } else {
          imageWidget = Image.asset(
            path,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
        }

        // Apply filters if needed
        if (state.blur > 0) {
          imageWidget = ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: state.blur, sigmaY: state.blur),
            child: imageWidget,
          );
        }

        if (state.opacity < 1.0) {
          imageWidget = Opacity(
            opacity: state.opacity,
            child: imageWidget,
          );
        }

        return imageWidget;

      default:
        return const SizedBox.shrink();
    }
  }

  /// Paints the background directly onto a [ui.Canvas]. 
  void paintToCanvas(BackgroundState state, ui.Canvas canvas, Size size, {Map<String, ui.Image>? imagePool}) {
    final rect = Offset.zero & size;

    switch (state.type) {
      case BackgroundType.color:
      case BackgroundType.transparent:
        final paint = Paint()..color = state.color ?? Colors.transparent;
        canvas.drawRect(rect, paint);
        break;

      case BackgroundType.gradient:
        if (state.gradient == null) return;
        final paint = Paint()
          ..shader = ui.Gradient.linear(
            rect.topLeft,
            rect.bottomRight,
            state.gradient!.colors,
            state.gradient!.stops,
          );
        canvas.drawRect(rect, paint);
        break;

      case BackgroundType.image:
        if (state.imagePath == null) break;
        final img = imagePool?[state.imagePath!];
        if (img != null) {
          paintImage(
            canvas: canvas,
            rect: rect,
            image: img,
            fit: BoxFit.cover,
          );
        } else {
          final paint = Paint()..color = Colors.black;
          canvas.drawRect(rect, paint);
        }
        break;

      default:
        break;
    }
  }
}
