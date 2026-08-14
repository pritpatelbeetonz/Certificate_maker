import 'package:flutter/material.dart';
import '../engine_enums.dart';
import 'gradient_model.dart';

/// Represents the visual state of the canvas background.
class BackgroundState {
  final BackgroundType type;
  final Color? color;
  final GradientModel? gradient;
  final String? imagePath;
  final double opacity;
  final double blur;
  final double brightness;
  final double saturation;
  final double contrast;

  const BackgroundState({
    this.type = BackgroundType.color,
    this.color = Colors.white,
    this.gradient,
    this.imagePath,
    this.opacity = 1.0,
    this.blur = 0.0,
    this.brightness = 1.0,
    this.saturation = 1.0,
    this.contrast = 1.0,
  });

  /// Factory for a solid color background
  factory BackgroundState.color(Color color) {
    return BackgroundState(
      type: BackgroundType.color,
      color: color,
    );
  }

  /// Factory for a gradient background
  factory BackgroundState.gradient(GradientModel gradient) {
    return BackgroundState(
      type: BackgroundType.gradient,
      gradient: gradient,
      color: null,
    );
  }

  /// Factory for an image background
  factory BackgroundState.image(String imagePath) {
    return BackgroundState(
      type: BackgroundType.image,
      imagePath: imagePath,
      color: null,
    );
  }

  BackgroundState copyWith({
    BackgroundType? type,
    Color? color,
    GradientModel? gradient,
    String? imagePath,
    double? opacity,
    double? blur,
    double? brightness,
    double? saturation,
    double? contrast,
  }) {
    return BackgroundState(
      type: type ?? this.type,
      color: color ?? this.color,
      gradient: gradient ?? this.gradient,
      imagePath: imagePath ?? this.imagePath,
      opacity: opacity ?? this.opacity,
      blur: blur ?? this.blur,
      brightness: brightness ?? this.brightness,
      saturation: saturation ?? this.saturation,
      contrast: contrast ?? this.contrast,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'color': color?.toARGB32(),
      'gradient': gradient?.toJson(),
      'imagePath': imagePath,
      'opacity': opacity,
      'blur': blur,
      'brightness': brightness,
      'saturation': saturation,
      'contrast': contrast,
    };
  }

  factory BackgroundState.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    final type = BackgroundType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => BackgroundType.color,
    );

    return BackgroundState(
      type: type,
      color: json['color'] != null ? Color(json['color'] as int) : null,
      gradient: json['gradient'] != null ? GradientModel.fromJson(json['gradient'] as Map<String, dynamic>) : null,
      imagePath: json['imagePath'] as String?,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      blur: (json['blur'] as num?)?.toDouble() ?? 0.0,
      brightness: (json['brightness'] as num?)?.toDouble() ?? 1.0,
      saturation: (json['saturation'] as num?)?.toDouble() ?? 1.0,
      contrast: (json['contrast'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
