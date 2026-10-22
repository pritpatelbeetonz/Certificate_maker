import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/scene_node.dart';
import 'canvas_renderer_registry.dart';
import 'base_node_renderer.dart';
import '../canvas/render_context.dart';
import '../styles/paint_factory.dart';
import '../assets/asset_repository.dart';

class TextCanvasRenderer extends BaseNodeRenderer<TextNode> implements CanvasNodeRenderer<TextNode> {
  const TextCanvasRenderer();

  @override
  void drawNodeContent(Canvas canvas, Size size, TextNode node, RenderContext context) {
    if (node.id.startsWith('logo') || node.id.startsWith('signature')) {
      final image = context.assetRepository.getImage(node.id);
      if (image != null) {
        final srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
        final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
        canvas.drawImageRect(
          image,
          srcRect,
          dstRect,
          Paint()
            ..isAntiAlias = true
            ..filterQuality = ui.FilterQuality.high,
        );
        return;
      }
    }

    canvas.save();
    debugPrint(
        "Global Scale = ${context.viewportTransformer.scaleX}"
    );
    // 1. Clip content to bounds to prevent overflow is disabled to prevent cutting off descenders/ascenders
    // canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // 2. Parse styles from string formats
    final parsedColor = PaintFactory.parseHexColor(node.color);
    final parsedFontWeight = _parseFontWeight(node.fontWeight);
    final parsedFontStyle = _parseFontStyle(node.fontStyle);
    final parsedTextAlign = _parseTextAlign(node.align);
    final parsedTextDecoration = _parseTextDecoration(node.decoration);


    // 4. Set scale to 1.0 to keep font size consistent and prevent text from stretching/shrinking when typed
    final double scale = 1.0;

    // 5. Get current screen scale factor (mapping virtual to screen space)
    final double screenScale = context.viewportTransformer.scaleX;


    if (node.textBend != 0.0) {
      debugPrint('>>> Bending Text: "${node.text}" | Bend: ${node.textBend}% | Radius: ${node.textBendRadius} | Characters: ${node.text.length} <<<');
      final List<String> characters = node.text.split('');
      if (characters.isNotEmpty) {
        final List<double> charWidths = [];
        for (final char in characters) {
          final charPainter = TextPainter(
            text: TextSpan(
              text: char,
              style: TextStyle(
                fontFamily: node.fontFamily == 'System' ? null : node.fontFamily,
                fontSize: node.fontSize * scale * screenScale,
                fontWeight: parsedFontWeight,
                fontStyle: parsedFontStyle,
                decoration: parsedTextDecoration,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          charWidths.add(charPainter.width);
        }

        final double letterSpacingVal = node.letterSpacing * scale * screenScale;
        final double wordSpacingVal = node.wordSpacing * scale * screenScale;

        double totalCharWidth = 0.0;
        for (int i = 0; i < charWidths.length; i++) {
          totalCharWidth += charWidths[i];
          if (i < charWidths.length - 1) {
            final isSpace = characters[i] == ' ';
            totalCharWidth += isSpace ? wordSpacingVal : letterSpacingVal;
          }
        }
        final double totalTextWidth = totalCharWidth;

        double alignmentOffset = 0.0;
        if (parsedTextAlign == TextAlign.center) {
          alignmentOffset = (size.width - totalTextWidth) / 2.0;
        } else if (parsedTextAlign == TextAlign.right) {
          alignmentOffset = size.width - totalTextWidth;
        }

        final double bendStrength = node.textBend.abs() / 100.0;
        final double radius = node.textBendRadius * scale * screenScale;
        final double effectiveRadius = radius / bendStrength;

        double currentX = 0.0;
        for (int i = 0; i < characters.length; i++) {
          final String char = characters[i];
          final double charW = charWidths[i];

          final double charCenterFromStart = currentX + charW / 2.0;
          final double xOffsetFromCenter = charCenterFromStart - totalTextWidth / 2.0;

          // Compute arc angle theta along the curve from center (preserving left-to-right x-progression)
          final double theta = (xOffsetFromCenter / radius) * bendStrength;

          double dx = effectiveRadius * math.sin(theta);
          // For a rainbow arch (dy > 0 as we move away from center):
          // Left side (theta < 0) points up-right (rotation < 0)
          // Right side (theta > 0) points down-right (rotation > 0)
          double rotation = (node.textBend >= 0.0) ? theta : -theta;
          double dy = (node.textBend >= 0.0)
              ? effectiveRadius * (1.0 - math.cos(theta))
              : -effectiveRadius * (1.0 - math.cos(theta));

          final double finalX = alignmentOffset + totalTextWidth / 2.0 + dx;
          final double finalY = (size.height / 2.0) + dy;

          canvas.save();
          canvas.translate(finalX, finalY);
          canvas.rotate(rotation);

          final charPainter = TextPainter(
            text: TextSpan(
              text: char,
              style: TextStyle(
                fontFamily: node.fontFamily == 'System' ? null : node.fontFamily,
                fontSize: node.fontSize * scale * screenScale,
                color: parsedColor,
                fontWeight: parsedFontWeight,
                fontStyle: parsedFontStyle,
                decoration: parsedTextDecoration,
                shadows: node.shadow.enabled
                    ? [
                        Shadow(
                          color: PaintFactory.parseHexColor(node.shadow.color)
                              .withValues(alpha: node.shadow.opacity),
                          offset: node.shadow.offset * scale * screenScale,
                          blurRadius: node.shadow.blurRadius * scale * screenScale,
                        )
                      ]
                    : null,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          charPainter.paint(canvas, Offset(-charW / 2.0, -charPainter.height / 2.0));
          canvas.restore();

          final isSpace = char == ' ';
          currentX += charW + (isSpace ? wordSpacingVal : letterSpacingVal);
        }

        canvas.restore();
        return;
      }
    }

    // 6. Paint text directly using TextPainter with the scaled font size
    final textPainter = TextPainter(
      text: TextSpan(
        text: node.text,
        style: TextStyle(
          fontFamily: node.fontFamily == 'System' ? null : node.fontFamily,
          fontSize: node.fontSize * scale * screenScale,
          color: parsedColor,
          fontWeight: parsedFontWeight,
          fontStyle: parsedFontStyle,
          decoration: parsedTextDecoration,
          letterSpacing: node.letterSpacing * scale * screenScale,
          wordSpacing: node.wordSpacing * scale * screenScale,
          height: node.lineHeight,
          shadows: node.shadow.enabled
              ? [
                  Shadow(
                    color: PaintFactory.parseHexColor(node.shadow.color)
                        .withValues(alpha: node.shadow.opacity),
                    offset: node.shadow.offset * scale * screenScale,
                    blurRadius: node.shadow.blurRadius * scale * screenScale,
                  )
                ]
              : null,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: parsedTextAlign,
    );

    // Layout with infinite width first to find the natural single-line width of the text
    textPainter.layout(maxWidth: double.infinity);
    final double naturalWidth = textPainter.width;

    // Check if the bounding box height is only tall enough for a single line
    final bool isSingleLineHeight = size.height <= (node.fontSize * scale * screenScale * 1.8);

    // Prevent wrapping if the box is single-line height, the text is short, has no spaces, or is only slightly wider than bounds
    final bool shouldPreventWrap = isSingleLineHeight ||
        node.text.length < 50 ||
        !node.text.trim().contains(' ') ||
        naturalWidth < (size.width * 1.20);

    if (shouldPreventWrap) {
      textPainter.layout(maxWidth: naturalWidth + 10);
    } else {
      textPainter.layout(maxWidth: size.width + 2);
    }
    
    // 7. Align the text horizontally based on parsedTextAlign and center vertically within the bounding box
    double xOffset = 0.0;
    if (parsedTextAlign == TextAlign.center) {
      xOffset = ((size.width - textPainter.width) / 2.0).roundToDouble();
    } else if (parsedTextAlign == TextAlign.right) {
      xOffset = (size.width - textPainter.width).roundToDouble();
    } else {
      xOffset = 0.0; // Left and justify
    }

    // Prevent ascenders/top serifs from clipping or splitting across fractional sub-pixel boundaries
    final double rawYOffset = (size.height - textPainter.height) / 2.0;
    final double yOffset = rawYOffset < 0.0
        ? 0.0
        : rawYOffset.floorToDouble() + (!context.isExportMode && screenScale < 0.8 ? 1.0 : 0.0);
    textPainter.paint(canvas, Offset(xOffset, yOffset));

    canvas.restore();
  }

  @override
  void render(Canvas canvas, Size size, TextNode node, Map<String, ui.Image> imagePool) {
    final context = RenderContext(
      canvas: canvas,
      size: size,
      assetRepository: MapAssetRepository(imagePool),
    );
    super.renderWithContext(context, node);
  }

  // Helper parsers
  FontWeight _parseFontWeight(String? weight) {
    if (weight == null) return FontWeight.normal;
    switch (weight.toLowerCase()) {
      case 'bold':
        return FontWeight.bold;
      case 'w100':
      case '100':
        return FontWeight.w100;
      case 'w200':
      case '200':
        return FontWeight.w200;
      case 'w300':
      case '300':
        return FontWeight.w300;
      case 'w400':
      case '400':
        return FontWeight.w400;
      case 'w500':
      case '500':
        return FontWeight.w500;
      case 'w600':
      case '600':
        return FontWeight.w600;
      case 'w700':
      case '700':
        return FontWeight.w700;
      case 'w800':
      case '800':
        return FontWeight.w800;
      case 'w900':
      case '900':
        return FontWeight.w900;
      case 'normal':
      default:
        return FontWeight.normal;
    }
  }

  FontStyle _parseFontStyle(String? style) {
    if (style == null) return FontStyle.normal;
    switch (style.toLowerCase()) {
      case 'italic':
        return FontStyle.italic;
      case 'normal':
      default:
        return FontStyle.normal;
    }
  }

  TextAlign _parseTextAlign(String? align) {
    if (align == null) return TextAlign.left;
    switch (align.toLowerCase()) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      case 'left':
      default:
        return TextAlign.left;
    }
  }

  TextDecoration _parseTextDecoration(String? decoration) {
    if (decoration == null) return TextDecoration.none;
    switch (decoration.toLowerCase()) {
      case 'underline':
        return TextDecoration.underline;
      case 'lineThrough':
      case 'line-through':
        return TextDecoration.lineThrough;
      case 'overline':
        return TextDecoration.overline;
      case 'none':
      default:
        return TextDecoration.none;
    }
  }
}
