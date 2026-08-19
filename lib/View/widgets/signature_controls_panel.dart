import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    final Canvas canvas = Canvas(
      recorder,
      const Rect.fromLTWH(0, 0, padW, padH),
    );

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
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(2.5),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: color == Colors.white
                  ? const Color(0xFFCBD5E1)
                  : Colors.transparent,
              width: 1,
            ),
          ),
        ),
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
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.add, size: 18, color: Color(0xFF475569)),
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
                    Text(
                      'Edit Signature',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF191C1D),
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onAddNewSignature,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFFece5f7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              "assets/Text edit/import.png",
                              width: 16.w,
                              height: 16.h,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Import Signature',
                              style: TextStyle(
                                color: Color(0xFF6B21A8),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Live Drawing Pad Box
                Container(
                  height: 140.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                                _signatureStrokes.last.add(
                                  details.localPosition,
                                );
                              });
                            }
                          },
                          onPanEnd: (details) {
                            _exportSignatureDrawing();
                          },
                          child: ClipRect(
                            child: CustomPaint(
                              painter: SignaturePadPainter(
                                strokes: _signatureStrokes,
                                strokeColor: _currentSignatureColor,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                      ),
                      // Controls top right
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _signatureStrokes.clear();
                                });
                                widget.onSignatureCleared();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.refresh,
                                      size: 16,
                                      color: Color(0xFF6B21A8),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Clear',
                                      style: TextStyle(
                                        color: Color(0xFF6B21A8),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _showFullscreenSignatureDialog,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEBE8F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.crop_free_rounded,
                                  size: 16,
                                  color: Color(0xFF6B21A8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Color Selectors Row
                SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      Expanded(
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            ..._presetSignatureColors.map(
                              (color) => _buildSignatureColorDot(color),
                            ),
                            _buildSignatureCustomColorPickerButton(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<ui.Image?> _exportStrokesToImage(
    List<List<Offset>> strokes,
    Color color,
  ) async {
    if (strokes.isEmpty) return null;

    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;

    for (final stroke in strokes) {
      for (final pt in stroke) {
        if (pt.dx < minX) minX = pt.dx;
        if (pt.dx > maxX) maxX = pt.dx;
        if (pt.dy < minY) minY = pt.dy;
        if (pt.dy > maxY) maxY = pt.dy;
      }
    }

    const double padding = 15.0;
    minX = (minX - padding).clamp(0.0, double.infinity);
    minY = (minY - padding).clamp(0.0, double.infinity);

    double drawWidth = (maxX - minX) + padding * 2;
    double drawHeight = (maxY - minY) + padding * 2;

    if (drawWidth <= 0) drawWidth = 320.0;
    if (drawHeight <= 0) drawHeight = 160.0;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, drawWidth, drawHeight),
    );

    final Paint drawPaint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      final Path path = Path();
      path.moveTo(stroke.first.dx - minX, stroke.first.dy - minY);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx - minX, stroke[i].dy - minY);
      }
      canvas.drawPath(path, drawPaint);
    }

    final ui.Picture picture = recorder.endRecording();
    return await picture.toImage(drawWidth.toInt(), drawHeight.toInt());
  }

  void _showFullscreenSignatureDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      pageBuilder: (context, anim1, anim2) {
        List<List<Offset>> tempStrokes = [];
        Color tempColor = _currentSignatureColor;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF0F172A)),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(
                  'Draw Signature',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: tempStrokes.isEmpty
                        ? null
                        : () async {
                            final img = await _exportStrokesToImage(
                              tempStrokes,
                              tempColor,
                            );
                            if (img != null) {
                              widget.onSignatureExported(img);
                            }
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                    child: Text(
                      'Done',
                      style: TextStyle(
                        color: tempStrokes.isEmpty
                            ? Colors.grey
                            : const Color(0xFF7C3AED),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              body: Column(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: GestureDetector(
                              onPanStart: (details) {
                                setDialogState(() {
                                  tempStrokes.add([details.localPosition]);
                                });
                              },
                              onPanUpdate: (details) {
                                if (tempStrokes.isNotEmpty) {
                                  setDialogState(() {
                                    tempStrokes.last.add(details.localPosition);
                                  });
                                }
                              },
                              child: ClipRect(
                                child: CustomPaint(
                                  painter: SignaturePadPainter(
                                    strokes: tempStrokes,
                                    strokeColor: tempColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 16,
                            right: 16,
                            child: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  tempStrokes.clear();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 24.0,
                      left: 16,
                      right: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ..._presetSignatureColors.map((color) {
                          final bool isSelected =
                              tempColor.value == color.value;
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                tempColor = color;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF7C3AED)
                                      : const Color(0xFFCBD5E1),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      color: color.computeLuminance() > 0.5
                                          ? Colors.black
                                          : Colors.white,
                                      size: 16,
                                    )
                                  : null,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
