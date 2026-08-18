import 'dart:math' show cos, sin, max;
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import '../models/sticker_model.dart';

const double kEdgeHandleLength = 24.0;
const double kEdgeHandleThickness = 09.0;
const double kHandleInset = 16.0;
const double kHandleCornerRadius = 3.0;

class InteractiveOverlay extends StatefulWidget {
  final Widget child;
  final StickerModel model;
  final double boundWidth;
  final double boundHeight;
  final double width;
  final double height;
  final bool isEditingImage;
  final bool isEditingText;
  final bool showTopBottomHandles;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onCancel;
  final VoidCallback? onUpdate;
  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionEnd;
  final VoidCallback? onEdit;
  final Function(double left, double top, double width, double height)? onResize;
  final bool viewOnly;

  const InteractiveOverlay({
    super.key,
    required this.child,
    required this.model,
    required this.boundWidth,
    required this.boundHeight,
    required this.width,
    required this.height,
    this.isEditingImage = false,
    this.isEditingText = false,
    this.showTopBottomHandles = true,
    this.onTap,
    this.onDoubleTap,
    this.onCancel,
    this.onUpdate,
    this.onInteractionStart,
    this.onInteractionEnd,
    this.onEdit,
    this.onResize,
    this.viewOnly = false,
  });

  @override
  State<InteractiveOverlay> createState() => _InteractiveOverlayState();
}

class _InteractiveOverlayState extends State<InteractiveOverlay> {
  Offset _initialFocalPoint = Offset.zero;
  double _initialLeft = 0.0;
  double _initialTop = 0.0;
  double _initialWidth = 0.0;
  double _initialHeight = 0.0;

  bool _isResizing = false;
  Offset _initialTouchPosition = Offset.zero;
  Offset _stickerCenter = Offset.zero;
  double _initialResizeDistance = 1.0;
  double _lastResizeDistance = 1.0;

  Offset _rotateStickerCenter = Offset.zero;

  double _lastScale = 1.0;
  double _lastRotation = 0.0;
  bool _isScaling = false;
  bool _wasScaling = false;

  double _initialImageScale = 1.0;
  double _initialImageOffsetX = 0.0;
  double _initialImageOffsetY = 0.0;
  static const double kSelectionPadding = 12.0;
  static const double kOverlayMargin = 28.0;

  @override
  Widget build(BuildContext context) {
    debugPrint("Custom InteractiveOverlay is building");
    final double handlePos = kOverlayMargin - kSelectionPadding - 15.0; // 1.0 (positive hit-test bounds)

    ///scaling
    return Positioned(
      top: widget.model.top - kOverlayMargin,
      left: widget.model.left - kOverlayMargin,
      child: Transform.scale(
        scaleX: widget.model.scale * widget.model.scaleX,
        scaleY: widget.model.scale * widget.model.scaleY,
        child: Transform.rotate(
          angle: widget.model.angle,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: (details) {
              if (widget.viewOnly) return;
              widget.onInteractionStart?.call();
              if (!widget.model.isSelected && !widget.isEditingImage) return;

              _isScaling = true;
              _wasScaling = true;

              _initialFocalPoint = details.focalPoint;
              _initialLeft = widget.model.left;
              _initialTop = widget.model.top;
              _lastScale = 1.0;
              _lastRotation = 0.0;

              _initialImageScale = widget.model.imageScale;
              _initialImageOffsetX = widget.model.imageOffsetX;
              _initialImageOffsetY = widget.model.imageOffsetY;
            },
            onScaleUpdate: (details) {
              if (widget.viewOnly) return;
              if (!widget.model.isSelected && !widget.isEditingImage) return;

              if (widget.isEditingImage) {
                setState(() {
                  final Offset translationDelta = details.focalPoint - _initialFocalPoint;
                  final double angle = widget.model.angle;
                  final double dxLocal = translationDelta.dx * cos(-angle) - translationDelta.dy * sin(-angle);
                  final double dyLocal = translationDelta.dx * sin(-angle) + translationDelta.dy * cos(-angle);

                  widget.model.imageOffsetX = _initialImageOffsetX + dxLocal;
                  widget.model.imageOffsetY = _initialImageOffsetY + dyLocal;

                  widget.model.imageScale = (_initialImageScale * details.scale).clamp(1.0, 8.0);
                });
                widget.onUpdate?.call();
                return;
              }

              setState(() {
                if (details.pointerCount > 1) {
                  double scaleMultiplier = _lastScale == 0.0 ? 1.0 : (details.scale / _lastScale);
                  double rotationDelta = details.rotation - _lastRotation;

                  // Apply direct damping / sensitivity to two-finger scaling and rotation
                  const double twoFingerScaleSensitivity = 0.3;
                  const double twoFingerRotationSensitivity = 0.4;

                  scaleMultiplier = 1.0 + (scaleMultiplier - 1.0) * twoFingerScaleSensitivity;
                  rotationDelta = rotationDelta * twoFingerRotationSensitivity;

                  final renderBox = context.findRenderObject() as RenderBox?;
                  double minScale = 0.1;
                  double currentCroppedW = 100.0;
                  double currentCroppedH = 100.0;
                  if (renderBox != null) {
                    final double croppedW = renderBox.size.width;
                    final double croppedH = renderBox.size.height;
                    final double uncroppedW = croppedW / (1.0 - widget.model.cropLeft - widget.model.cropRight).clamp(0.1, 1.0);
                    final double uncroppedH = croppedH / (1.0 - widget.model.cropTop - widget.model.cropBottom).clamp(0.1, 1.0);

                    currentCroppedW = uncroppedW * (1.0 - widget.model.cropLeft - widget.model.cropRight);
                    currentCroppedH = uncroppedH * (1.0 - widget.model.cropTop - widget.model.cropBottom);

                    const double minSize = 10.0;
                    final double minScaleW = minSize / currentCroppedW.clamp(1.0, double.infinity);
                    final double minScaleH = minSize / currentCroppedH.clamp(1.0, double.infinity);
                    minScale = max(minScaleW, minScaleH).clamp(0.1, 8.0);
                  }

                  final double nextScale = (widget.model.scale * scaleMultiplier).clamp(minScale, 8.0);

                  widget.model.scale = nextScale;
                  widget.model.angle += rotationDelta;

                  _lastScale = details.scale;
                  _lastRotation = details.rotation;

                  // Update focal point anchors to current position so lifting a finger transitioning back to drag does not jump
                  _initialFocalPoint = details.focalPoint;
                  _initialLeft = widget.model.left;
                  _initialTop = widget.model.top;
                } else {
                  // Single finger translation drag only
                  final Offset translationDelta = details.focalPoint - _initialFocalPoint;
                  widget.model.left = _initialLeft + translationDelta.dx;
                  widget.model.top = _initialTop + translationDelta.dy;
                }
              });

              widget.onUpdate?.call();
            },
            onScaleEnd: (details) {
              _isScaling = false;
              Future.delayed(const Duration(milliseconds: 200), () {
                if (mounted) {
                  _wasScaling = false;
                }
              });
              widget.onInteractionEnd?.call();
            },
            onTap: () {
              if (widget.viewOnly) return;
              if (_isScaling || _wasScaling) return;
              widget.onTap?.call();
            },
            onDoubleTap: () {
              if (widget.viewOnly) return;
              widget.onDoubleTap?.call();
            },
            child: SizedBox(
              width: widget.width + (kOverlayMargin * 2),
              height: widget.height + (kOverlayMargin * 2),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: kOverlayMargin,
                    left: kOverlayMargin,
                    width: widget.width,
                    height: widget.height,
                    child: widget.child,
                  ),
                  if (widget.model.isSelected && !widget.viewOnly && !widget.isEditingImage) ...[
                    Positioned(
                      top: kOverlayMargin - kSelectionPadding,
                      left: kOverlayMargin - kSelectionPadding,
                      width: widget.width + (kSelectionPadding * 2),
                      height: widget.height + (kSelectionPadding * 2),
                      child: IgnorePointer(
                        child: DottedBorder(
                          options: RectDottedBorderOptions(
                            padding: EdgeInsets.zero,
                            color: widget.isEditingText ? Colors.blueAccent : const Color(0xFF4200AD),
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                    // 1. TOP Handle (Horizontal rectangular bar or fallback circular dot)
                    if (widget.showTopBottomHandles)
                      Positioned(
                        top: kOverlayMargin - kSelectionPadding - 20.0,
                        left: kOverlayMargin + widget.width / 2.0 - 24.0,
                        width: 48.0,
                        height: 40.0,
                        child: Transform.scale(
                          scale: 1.0 / widget.model.scale.clamp(0.1, 8.0),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: (details) {
                              widget.onInteractionStart?.call();
                              _initialWidth = widget.width;
                              _initialHeight = widget.height;
                              _initialLeft = widget.model.left;
                              _initialTop = widget.model.top;
                              _initialTouchPosition = details.globalPosition;
                            },
                            onPanUpdate: (details) {
                              final double angle = widget.model.angle;
                              final Offset screenDragDelta = details.globalPosition - _initialTouchPosition;
                              final double localDy = screenDragDelta.dx * sin(-angle) + screenDragDelta.dy * cos(-angle);

                              final double newHeight = (_initialHeight - localDy).clamp(20.0, double.infinity);
                              final double localOffsetY = (_initialHeight - newHeight) / 2.0;

                              final double initialCenterX = _initialLeft + _initialWidth / 2.0;
                              final double initialCenterY = _initialTop + _initialHeight / 2.0;
                              final double newCenterX = initialCenterX - localOffsetY * sin(angle);
                              final double newCenterY = initialCenterY + localOffsetY * cos(angle);

                              final double newLeft = newCenterX - _initialWidth / 2.0;
                              final double newTop = newCenterY - newHeight / 2.0;

                              widget.onResize?.call(newLeft, newTop, _initialWidth, newHeight);
                            },
                            onPanEnd: (details) => widget.onInteractionEnd?.call(),
                            onPanCancel: () => widget.onInteractionEnd?.call(),
                            child: Center(
                              child: Builder(
                                builder: (context) {
                                  final bool useBar = widget.width + kSelectionPadding * 2 >= 70.0;
                                  return Container(
                                    width: useBar ? 24.0 : 6.0,
                                    height: 6.0,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: useBar ? BoxShape.rectangle : BoxShape.circle,
                                      borderRadius: useBar ? BorderRadius.circular(2.5) : null,
                                      border: Border.all(color: const Color(0xFF4200AD), width: 1.5),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 2,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              ),
                            ),
                          ),
                        ),
                      ),
                    // 2. BOTTOM Handle (Horizontal rectangular bar or fallback circular dot)
                    if (widget.showTopBottomHandles)
                      Positioned(
                        top: kOverlayMargin + widget.height + kSelectionPadding - 20.0,
                        left: kOverlayMargin + widget.width / 2.0 - 24.0,
                        width: 48.0,
                        height: 40.0,
                        child: Transform.scale(
                          scale: 1.0 / widget.model.scale.clamp(0.1, 8.0),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: (details) {
                              widget.onInteractionStart?.call();
                              _initialWidth = widget.width;
                              _initialHeight = widget.height;
                              _initialLeft = widget.model.left;
                              _initialTop = widget.model.top;
                              _initialTouchPosition = details.globalPosition;
                            },
                            onPanUpdate: (details) {
                              final double angle = widget.model.angle;
                              final Offset screenDragDelta = details.globalPosition - _initialTouchPosition;
                              final double localDy = screenDragDelta.dx * sin(-angle) + screenDragDelta.dy * cos(-angle);

                              final double newHeight = (_initialHeight + localDy).clamp(20.0, double.infinity);
                              final double localOffsetY = (newHeight - _initialHeight) / 2.0;

                              final double initialCenterX = _initialLeft + _initialWidth / 2.0;
                              final double initialCenterY = _initialTop + _initialHeight / 2.0;
                              final double newCenterX = initialCenterX - localOffsetY * sin(angle);
                              final double newCenterY = initialCenterY + localOffsetY * cos(angle);

                              final double newLeft = newCenterX - _initialWidth / 2.0;
                              final double newTop = newCenterY - newHeight / 2.0;

                              widget.onResize?.call(newLeft, newTop, _initialWidth, newHeight);
                            },
                            onPanEnd: (details) => widget.onInteractionEnd?.call(),
                            onPanCancel: () => widget.onInteractionEnd?.call(),
                            child: Center(
                              child: Builder(
                                builder: (context) {
                                  final bool useBar = widget.width + kSelectionPadding * 2 >= 70.0;
                                  return Container(
                                    width: useBar ? 24.0 : 6.0,
                                    height: 6.0,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: useBar ? BoxShape.rectangle : BoxShape.circle,
                                      borderRadius: useBar ? BorderRadius.circular(2.5) : null,
                                      border: Border.all(color: const Color(0xFF4200AD), width: 1.5),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 2,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              ),
                            ),
                          ),
                        ),
                      ),
                    // 3. LEFT Handle (Vertical rectangular bar or fallback circular dot)
                    Positioned(
                      top: kOverlayMargin + widget.height / 2.0 - 24.0,
                      left: kOverlayMargin - kSelectionPadding - 20.0,
                      width: 40.0,
                      height: 48.0,
                      child: Transform.scale(
                        scale: 1.0 / widget.model.scale.clamp(0.1, 8.0),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanStart: (details) {
                            widget.onInteractionStart?.call();
                            _initialWidth = widget.width;
                            _initialHeight = widget.height;
                            _initialLeft = widget.model.left;
                            _initialTop = widget.model.top;
                            _initialTouchPosition = details.globalPosition;
                          },
                          onPanUpdate: (details) {
                            final double angle = widget.model.angle;
                            final Offset screenDragDelta = details.globalPosition - _initialTouchPosition;
                            final double localDx = screenDragDelta.dx * cos(-angle) - screenDragDelta.dy * sin(-angle);

                            final double newWidth = (_initialWidth - localDx).clamp(20.0, double.infinity);
                            final double localOffsetX = (_initialWidth - newWidth) / 2.0;

                            final double initialCenterX = _initialLeft + _initialWidth / 2.0;
                            final double initialCenterY = _initialTop + _initialHeight / 2.0;
                            final double newCenterX = initialCenterX + localOffsetX * cos(angle);
                            final double newCenterY = initialCenterY + localOffsetX * sin(angle);

                            final double newLeft = newCenterX - newWidth / 2.0;
                            final double newTop = newCenterY - _initialHeight / 2.0;

                            widget.onResize?.call(newLeft, newTop, newWidth, _initialHeight);
                          },
                          onPanEnd: (details) => widget.onInteractionEnd?.call(),
                          onPanCancel: () => widget.onInteractionEnd?.call(),
                          child: Center(
                            child: Builder(
                              builder: (context) {
                                final bool useBar = widget.height + kSelectionPadding * 2 >= 70.0;
                                return Container(
                                  width: 6.0,
                                  height: useBar ? 24.0 : 6.0,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: useBar ? BoxShape.rectangle : BoxShape.circle,
                                    borderRadius: useBar ? BorderRadius.circular(2.5) : null,
                                    border: Border.all(color: const Color(0xFF4200AD), width: 1.5),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 4. RIGHT Handle (Vertical rectangular bar or fallback circular dot)
                    Positioned(
                      top: kOverlayMargin + widget.height / 2.0 - 24.0,
                      left: kOverlayMargin + widget.width + kSelectionPadding - 20.0,
                      width: 40.0,
                      height: 48.0,
                      child: Transform.scale(
                        scale: 1.0 / widget.model.scale.clamp(0.1, 8.0),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanStart: (details) {
                            widget.onInteractionStart?.call();
                            _initialWidth = widget.width;
                            _initialHeight = widget.height;
                            _initialLeft = widget.model.left;
                            _initialTop = widget.model.top;
                            _initialTouchPosition = details.globalPosition;
                          },
                          onPanUpdate: (details) {
                            final double angle = widget.model.angle;
                            final Offset screenDragDelta = details.globalPosition - _initialTouchPosition;
                            final double localDx = screenDragDelta.dx * cos(-angle) - screenDragDelta.dy * sin(-angle);

                            final double newWidth = (_initialWidth + localDx).clamp(20.0, double.infinity);
                            final double localOffsetX = (newWidth - _initialWidth) / 2.0;

                            final double initialCenterX = _initialLeft + _initialWidth / 2.0;
                            final double initialCenterY = _initialTop + _initialHeight / 2.0;
                            final double newCenterX = initialCenterX + localOffsetX * cos(angle);
                            final double newCenterY = initialCenterY + localOffsetX * sin(angle);

                            final double newLeft = newCenterX - newWidth / 2.0;
                            final double newTop = newCenterY - _initialHeight / 2.0;

                            widget.onResize?.call(newLeft, newTop, newWidth, _initialHeight);
                          },
                          onPanEnd: (details) => widget.onInteractionEnd?.call(),
                          onPanCancel: () => widget.onInteractionEnd?.call(),
                          child: Center(
                            child: Builder(
                              builder: (context) {
                                final bool useBar = widget.height + kSelectionPadding * 2 >= 70.0;
                                return Container(
                                  width: 6.0,
                                  height: useBar ? 24.0 : 6.0,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: useBar ? BoxShape.rectangle : BoxShape.circle,
                                    borderRadius: useBar ? BorderRadius.circular(2.5) : null,
                                    border: Border.all(color: const Color(0xFF4200AD), width: 1.5),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (widget.isEditingImage && !widget.viewOnly) ...[
                    Positioned(
                      top: kOverlayMargin - kSelectionPadding,
                      left: kOverlayMargin - kSelectionPadding,
                      width: widget.width + (kSelectionPadding * 2),
                      height: widget.height + (kSelectionPadding * 2),
                      child: IgnorePointer(
                        child: DottedBorder(
                          options: const RectDottedBorderOptions(
                            padding: EdgeInsets.zero,
                            color: Colors.blueAccent,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                            child: const Text(
                              'Pan / Scale Image',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  ///delete
                  if (widget.model.isSelected && !widget.viewOnly && !widget.isEditingImage)
                    Positioned(
                      top: handlePos,
                      left: handlePos,
                      child: Transform.scale(
                        scale: 1.0 / widget.model.scale.clamp(0.1, 8.0),
                        child: InkWell(
                          onTap: () {
                            widget.onCancel?.call();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xFF4200AD), width: 2),
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Color(0xFF4200AD),
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ///scalling
                  if (widget.model.isSelected && !widget.viewOnly && !widget.isEditingImage)
                    Positioned(
                      top: handlePos,
                      right: handlePos,
                      child: Transform.scale(
                        scale: 1.0 / widget.model.scale.clamp(0.1, 8.0),
                        child: GestureDetector(
                          onPanStart: (details) {
                            final renderBox = context.findRenderObject() as RenderBox?;
                            if (renderBox != null) {
                              widget.onInteractionStart?.call();
                              final centerLocal = Offset(renderBox.size.width / 2, renderBox.size.height / 2);
                              _stickerCenter = renderBox.localToGlobal(centerLocal);
                              _initialTouchPosition = details.globalPosition;
                              _initialResizeDistance = (_initialTouchPosition - _stickerCenter).distance;
                              _lastResizeDistance = _initialResizeDistance;
                              _isResizing = false;
                            }
                          },
                          onPanUpdate: (details) {
                            final double dragDelta = (details.globalPosition - _initialTouchPosition).distance;
                            if (!_isResizing && dragDelta > 2.5) {
                              _isResizing = true;
                              _initialResizeDistance = (details.globalPosition - _stickerCenter).distance;
                              if (_initialResizeDistance == 0) _initialResizeDistance = 1.0;
                              _lastResizeDistance = _initialResizeDistance;
                            }

                            if (_isResizing) {
                              final double currentDistance = (details.globalPosition - _stickerCenter).distance;
                              if (currentDistance == 0 || _lastResizeDistance == 0) return;

                              double distanceMultiplier = currentDistance / _lastResizeDistance;

                              if (_initialResizeDistance < 80.0) {
                                final double dampingFactor = (_initialResizeDistance / 80.0).clamp(0.5, 1.0);
                                distanceMultiplier = 1.0 + (distanceMultiplier - 1.0) * dampingFactor;
                              }

                              const double globalSensitivity = 0.4;
                              distanceMultiplier = 1.0 + (distanceMultiplier - 1.0) * globalSensitivity;

                              final renderBox = context.findRenderObject() as RenderBox?;
                              double minScale = 0.1;
                              if (renderBox != null) {
                                final double croppedW = renderBox.size.width;
                                final double croppedH = renderBox.size.height;
                                final double uncroppedW = croppedW / (1.0 - widget.model.cropLeft - widget.model.cropRight).clamp(0.1, 1.0);
                                final double uncroppedH = croppedH / (1.0 - widget.model.cropTop - widget.model.cropBottom).clamp(0.1, 1.0);

                                final double currentCroppedW = uncroppedW * (1.0 - widget.model.cropLeft - widget.model.cropRight);
                                final double currentCroppedH = uncroppedH * (1.0 - widget.model.cropTop - widget.model.cropBottom);

                                const double minSize = 10.0;
                                final double minScaleW = minSize / currentCroppedW.clamp(1.0, double.infinity);
                                final double minScaleH = minSize / currentCroppedH.clamp(1.0, double.infinity);
                                minScale = max(minScaleW, minScaleH).clamp(0.1, 8.0);
                              }

                              final double targetScale = (widget.model.scale * distanceMultiplier).clamp(minScale, 8.0);

                              if ((targetScale - widget.model.scale).abs() > 0.001) {
                                setState(() {
                                  widget.model.scale = targetScale;
                                });
                                _lastResizeDistance = currentDistance;
                                widget.onUpdate?.call();
                              }
                            }
                          },
                          onPanEnd: (details) {
                            _isResizing = false;
                            widget.onInteractionEnd?.call();
                          },
                          onPanCancel: () {
                            _isResizing = false;
                            widget.onInteractionEnd?.call();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xFF4200AD), width: 2),
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.crop,
                              color: Color(0xFF4200AD),
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ///Rotation
                  if (widget.model.isSelected && !widget.viewOnly && !widget.isEditingImage)
                    Positioned(
                      bottom: handlePos,
                      right: handlePos,
                      child: Transform.scale(
                        scale: 1.0 / widget.model.scale.clamp(0.1, 8.0),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanStart: (details) {
                            final renderBox = context.findRenderObject() as RenderBox?;
                            if (renderBox != null) {
                              widget.onInteractionStart?.call();
                              final centerLocal = Offset(renderBox.size.width / 2, renderBox.size.height / 2);
                              _rotateStickerCenter = renderBox.localToGlobal(centerLocal);
                            }
                          },
                          onPanUpdate: (details) {
                            final Offset toPointer = details.globalPosition - _rotateStickerCenter;
                            final Offset startVector = details.globalPosition - details.delta - _rotateStickerCenter;

                            final double currentAngle = toPointer.direction;
                            final double startAngle = startVector.direction;
                            final double deltaAngle = currentAngle - startAngle;

                            setState(() {
                              widget.model.angle += deltaAngle;
                            });

                            widget.onUpdate?.call();
                          },
                          onPanEnd: (details) => widget.onInteractionEnd?.call(),
                          onPanCancel: () => widget.onInteractionEnd?.call(),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xFF4200AD), width: 2),
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.rotate_right,
                              color: Color(0xFF4200AD),
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
