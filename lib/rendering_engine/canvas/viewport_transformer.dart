import 'dart:ui';

/// Central transformation layer handling conversions between Virtual (world) space
/// and Screen (viewport) space, incorporating optional Zoom, Pan, and DPI constraints.
class ViewportTransformer {
  final double virtualWidth;
  final double virtualHeight;
  final Size targetSize;
  final Offset panOffset;
  final double zoom;

  const ViewportTransformer({
    required this.virtualWidth,
    required this.virtualHeight,
    required this.targetSize,
    this.panOffset = Offset.zero,
    this.zoom = 1.0,
  });

  double get scaleX => (targetSize.width / virtualWidth) * zoom;
  double get scaleY => (targetSize.height / virtualHeight) * zoom;

  // ─────────────────── Virtual -> Screen ───────────────────

  double toScreenX(double virtualX) => virtualX * scaleX + panOffset.dx;
  double toScreenY(double virtualY) => virtualY * scaleY + panOffset.dy;
  double toScreenWidth(double virtualW) => virtualW * scaleX;
  double toScreenHeight(double virtualH) => virtualH * scaleY;

  Offset toScreenOffset(Offset virtualOffset) => Offset(
        toScreenX(virtualOffset.dx),
        toScreenY(virtualOffset.dy),
      );

  Size toScreenSize(Size virtualSize) => Size(
        toScreenWidth(virtualSize.width),
        toScreenHeight(virtualSize.height),
      );

  Rect toScreenRect(Rect virtualRect) => Rect.fromLTWH(
        toScreenX(virtualRect.left),
        toScreenY(virtualRect.top),
        toScreenWidth(virtualRect.width),
        toScreenHeight(virtualRect.height),
      );

  // ─────────────────── Screen -> Virtual ───────────────────

  double toVirtualX(double screenX) => (screenX - panOffset.dx) / scaleX;
  double toVirtualY(double screenY) => (screenY - panOffset.dy) / scaleY;
  double toVirtualWidth(double screenW) => screenW / scaleX;
  double toVirtualHeight(double screenH) => screenH / scaleY;

  Offset toVirtualOffset(Offset screenOffset) => Offset(
        toVirtualX(screenOffset.dx),
        toVirtualY(screenOffset.dy),
      );

  Size toVirtualSize(Size screenSize) => Size(
        toVirtualWidth(screenSize.width),
        toScreenHeight(screenSize.height),
      );

  Rect toVirtualRect(Rect screenRect) => Rect.fromLTWH(
        toVirtualX(screenRect.left),
        toVirtualY(screenRect.top),
        toVirtualWidth(screenRect.width),
        toVirtualHeight(screenRect.height),
      );
}
