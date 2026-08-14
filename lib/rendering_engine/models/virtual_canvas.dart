import 'aspect_ratio_preset.dart';

class VirtualCanvas {
  final double virtualWidth;
  final double virtualHeight;
  final String defaultAspectRatio;
  final List<AspectRatioPreset> supportedAspectRatios;
  final double outerSpacing;
  final double innerSpacing;

  const VirtualCanvas({
    this.virtualWidth = 1000.0,
    this.virtualHeight = 1000.0,
    this.defaultAspectRatio = '1:1',
    this.supportedAspectRatios = const [],
    this.outerSpacing = 0.0,
    this.innerSpacing = 0.0,
  });

  factory VirtualCanvas.fromJson(Map<String, dynamic> json) {
    final virtualSize = json['virtualSize'] as Map?;
    final double width = (virtualSize?['width'] as num? ?? json['width'] as num? ?? 1000.0).toDouble();
    final double height = (virtualSize?['height'] as num? ?? json['height'] as num? ?? 1000.0).toDouble();
    
    final legacyRatioMap = json['aspectRatio'] as Map?;
    final String legacyRatio = legacyRatioMap?['ratio'] as String? ?? '1:1';
    final String defaultRatio = json['defaultAspectRatio'] as String? ?? legacyRatio;
    
    final List supportedList = json['supportedAspectRatios'] as List? ?? [];
    List<AspectRatioPreset> supported = supportedList
        .map((item) => AspectRatioPreset.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();

    if (supported.isEmpty) {
      supported = [
        AspectRatioPreset(id: defaultRatio, label: defaultRatio, isDefault: true)
      ];
    }

    final spacingMap = json['layoutSpacing'] as Map?;
    final double outer = (spacingMap?['outer'] as num? ?? 0.0).toDouble();
    final double inner = (spacingMap?['inner'] as num? ?? 0.0).toDouble();

    return VirtualCanvas(
      virtualWidth: width,
      virtualHeight: height,
      defaultAspectRatio: defaultRatio,
      supportedAspectRatios: supported,
      outerSpacing: outer,
      innerSpacing: inner,
    );
  }

  Map<String, dynamic> toJson() => {
        'virtualSize': {
          'width': virtualWidth,
          'height': virtualHeight,
        },
        'defaultAspectRatio': defaultAspectRatio,
        'supportedAspectRatios': supportedAspectRatios.map((r) => r.toJson()).toList(),
        'layoutSpacing': {
          'outer': outerSpacing,
          'inner': innerSpacing,
        },
      };
}
