import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'signature_pad_painter.dart';

class SignatureControlsPanel extends StatefulWidget {
  final VoidCallback onAddNewSignature;
  final Function(ui.Image image) onSignatureExported;
  final VoidCallback onSignatureCleared;
  final List<List<Offset>> initialStrokes;
  final Color initialColor;
  final VoidCallback onDismiss;

  const SignatureControlsPanel({
    super.key,
    required this.onAddNewSignature,
    required this.onSignatureExported,
    required this.onSignatureCleared,
    required this.initialStrokes,
    required this.initialColor,
    required this.onDismiss,
  });

  @override
  State<SignatureControlsPanel> createState() => _SignatureControlsPanelState();
}

class _SignatureControlsPanelState extends State<SignatureControlsPanel> {
  late List<List<Offset>> _signatureStrokes;
  late Color _currentSignatureColor;

  final List<Color> _presetSignatureColors = [
    const Color(0xFF2563EB),
    const Color(0xFFEF4444),
    const Color(0xFFF59E0B),
    const Color(0xFF10B981),
    const Color(0xFF0F172A),
    const Color(0xFF8B5CF6),
    const Color(0xFFFFFFFF),
  ];

  @override
  void initState() {
    super.initState();
    _signatureStrokes = List.from(widget.initialStrokes);
    _currentSignatureColor = widget.initialColor;
  }

  Future<void> _exportSignatureDrawing() async {
    if (_signatureStrokes.isEmpty) return;

    // Use specific pad canvas aspect ratio dimensions
    const double padW = 320.0;
    const double padH = 160.0;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, padW, padH));

    // Fill transparent background
    final Paint paint = Paint()..color = Colors.transparent;
    canvas.drawRect(const Rect.fromLTWH(0, 0, padW, padH), paint);

    final Paint drawPaint = Paint()
      ..color = _currentSignatureColor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    for (final stroke in _signatureStrokes) {
      if (stroke.isEmpty) continue;
      final Path path = Path();
      path.moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, drawPaint);
    }

    final ui.Picture picture = recorder.endRecording();
    final ui.Image img = await picture.toImage(padW.toInt(), padH.toInt());

    widget.onSignatureExported(img);
  }

  Widget _buildSignatureColorDot(Color color) {
    final bool isSelected = _currentSignatureColor.value == color.value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentSignatureColor = color;
        });
        _exportSignatureDrawing();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                size: 16,
              )
            : null,
      ),
    );
  }

  Widget _buildSignatureCustomColorPickerButton() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            Color pickerColor = _currentSignatureColor;
            return AlertDialog(
              title: const Text('Pick signature color'),
              content: SingleChildScrollView(
                child: ColorPicker(
                  pickerColor: pickerColor,
                  onColorChanged: (Color color) {
                    pickerColor = color;
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    setState(() {
                      _currentSignatureColor = pickerColor;
                    });
                    _exportSignatureDrawing();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: const Icon(Icons.add, size: 16, color: Color(0xFF475569)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: (details) {
              if (details.delta.dy > 4.0) {
                widget.onDismiss();
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Signature',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: widget.onAddNewSignature,
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Import Signature'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF3E8FF),
                        foregroundColor: const Color(0xFF7C3AED),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Live Drawing Pad Box
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          onPanStart: (details) {
                            setState(() {
                              _signatureStrokes.add([details.localPosition]);
                            });
                          },
                          onPanUpdate: (details) {
                            if (_signatureStrokes.isNotEmpty) {
                              setState(() {
                                _signatureStrokes.last.add(details.localPosition);
                              });
                            }
                          },
                          onPanEnd: (details) {
                            _exportSignatureDrawing();
                          },
                          child: CustomPaint(
                            painter: SignaturePadPainter(
                              strokes: _signatureStrokes,
                              strokeColor: _currentSignatureColor,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                      // Clear Button top right
                      Positioned(
                        top: 8,
                        right: 8,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _signatureStrokes.clear();
                            });
                            widget.onSignatureCleared();
                          },
                          icon: const Icon(Icons.refresh, size: 16, color: Color(0xFF7C3AED)),
                          label: const Text(
                            'Clear',
                            style: TextStyle(
                              color: Color(0xFF7C3AED),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Color Selectors Row
                SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      Expanded(
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            ..._presetSignatureColors.map((color) => _buildSignatureColorDot(color)),
                            _buildSignatureCustomColorPickerButton(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
