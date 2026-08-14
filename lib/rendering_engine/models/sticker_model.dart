class StickerModel {
  double top;
  double left;
  double scale;
  double scaleX;
  double scaleY;
  double cropLeft;
  double cropTop;
  double cropRight;
  double cropBottom;
  double angle; // in radians
  bool isSelected;
  double imageScale;
  double imageOffsetX;
  double imageOffsetY;

  StickerModel({
    this.top = 0,
    this.left = 0,
    this.scale = 1.0,
    this.scaleX = 1.0,
    this.scaleY = 1.0,
    this.cropLeft = 0.0,
    this.cropTop = 0.0,
    this.cropRight = 0.0,
    this.cropBottom = 0.0,
    this.angle = 0.0,
    this.isSelected = false,
    this.imageScale = 1.0,
    this.imageOffsetX = 0.0,
    this.imageOffsetY = 0.0,
  });
}
