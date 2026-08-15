import 'package:flutter/material.dart';

class SignaturePadPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color strokeColor;

  SignaturePadPainter({required this.strokes, required this.strokeColor});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw dotted baseline
    final Paint linePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double dashWidth = 4.0;
    const double dashSpace = 4.0;
    double startX = 16.0;
    final double y = size.height - 40.0;
    final double endX = size.width - 16.0;

    while (startX < endX) {
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), linePaint);
      startX += dashWidth + dashSpace;
    }

    // 2. Draw drawn paths
    final Paint drawPaint = Paint()
      ..color = strokeColor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    // Gaussian smoothing: averages each point with neighbours to eliminate
    // sharp corners from sparse touch events during fast drawing.
    // Applied twice for stronger effect.
    List<Offset> smoothPoints(List<Offset> pts) {
      if (pts.length < 3) return pts;
      final out = <Offset>[pts.first];
      for (int i = 1; i < pts.length - 1; i++) {
        out.add(Offset(
          (pts[i - 1].dx + pts[i].dx * 2 + pts[i + 1].dx) / 4.0,
          (pts[i - 1].dy + pts[i].dy * 2 + pts[i + 1].dy) / 4.0,
        ));
      }
      out.add(pts.last);
      return out;
    }

    for (final rawStroke in strokes) {
      if (rawStroke.isEmpty) continue;

      // Apply 2 passes of Gaussian smoothing before rendering
      final stroke = smoothPoints(smoothPoints(rawStroke));

      final Path path = Path();

      if (stroke.length == 1) {
        canvas.drawCircle(
          stroke.first,
          drawPaint.strokeWidth / 2,
          Paint()
            ..color = strokeColor
            ..style = PaintingStyle.fill,
        );
        continue;
      }

      path.moveTo(stroke.first.dx, stroke.first.dy);

      if (stroke.length == 2) {
        path.lineTo(stroke[1].dx, stroke[1].dy);
      } else if (stroke.length == 3) {
        path.quadraticBezierTo(
          stroke[1].dx, stroke[1].dy,
          stroke[2].dx, stroke[2].dy,
        );
      } else {
        // Catmull-Rom spline → cubic Bézier.
        for (int i = 0; i < stroke.length - 1; i++) {
          final p0 = i > 0 ? stroke[i - 1] : stroke[i];
          final p1 = stroke[i];
          final p2 = stroke[i + 1];
          final p3 = (i + 2 < stroke.length) ? stroke[i + 2] : stroke[i + 1];

          final cp1 = Offset(
            p1.dx + (p2.dx - p0.dx) / 6.0,
            p1.dy + (p2.dy - p0.dy) / 6.0,
          );
          final cp2 = Offset(
            p2.dx - (p3.dx - p1.dx) / 6.0,
            p2.dy - (p3.dy - p1.dy) / 6.0,
          );

          path.cubicTo(
            cp1.dx, cp1.dy,
            cp2.dx, cp2.dy,
            p2.dx, p2.dy,
          );
        }
      }

      canvas.drawPath(path, drawPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SignaturePadPainter oldDelegate) => true;
}
