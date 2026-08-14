import 'dart:ui' as ui;
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
    canvas.save();
    debugPrint(
        "Global Scale = ${context.viewportTransformer.scaleX}"
    );
    // 1. Clip content to bounds to prevent overflow
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // 2. Parse styles from string formats
    final parsedColor = PaintFactory.parseHexColor(node.color);
    final parsedFontWeight = _parseFontWeight(node.fontWeight);
    final parsedFontStyle = _parseFontStyle(node.fontStyle);
    final parsedTextAlign = _parseTextAlign(node.align);
    final parsedTextDecoration = _parseTextDecoration(node.decoration);

    // 3. Measure the text at the base font size to find its original virtual width
    final baseTextPainter = TextPainter(
      text: TextSpan(
        text: node.text,
        style: TextStyle(
          fontFamily: node.fontFamily == 'System' ? null : node.fontFamily,
          fontSize: node.fontSize,
          fontWeight: parsedFontWeight,
          fontStyle: parsedFontStyle,
          decoration: parsedTextDecoration,
          letterSpacing: node.letterSpacing,
          height: node.lineHeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final double baseVirtualWidth = baseTextPainter.width > 0 ? baseTextPainter.width : 1.0;

    // 4. Calculate scale relative to the base virtual width
    final double scale = node.bounds.width / baseVirtualWidth;

    // 5. Get current screen scale factor (mapping virtual to screen space)
    final double screenScale = context.viewportTransformer.scaleX;


    debugPrint('================ TEXT RENDER =================');
    debugPrint('Text: ${node.text}');
    debugPrint('Font: ${node.fontFamily}');
    debugPrint('Font Size: ${node.fontSize}');
    debugPrint('Bounds Width: ${node.bounds.width}');
    debugPrint('Base Width: $baseVirtualWidth');
    debugPrint('Content Scale: $scale');
    debugPrint('Viewport Scale: $screenScale');
    debugPrint('Effective Font Size: ${node.fontSize * scale}');
    debugPrint('Rendered Font Size: ${node.fontSize * scale * screenScale}');
    debugPrint('==============================================');

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
          height: node.lineHeight,
          shadows: node.shadow.enabled
              ? [
                  Shadow(
                    color: PaintFactory.parseHexColor(node.shadow.color)
                        .withOpacity(node.shadow.opacity),
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

    textPainter.layout(maxWidth: size.width + 2); // add minor layout tolerance
    
    // 7. Center the text horizontally and vertically within the bounding box
    final double xOffset = (size.width - textPainter.width) / 2;
    final double yOffset = (size.height - textPainter.height) / 2;
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
