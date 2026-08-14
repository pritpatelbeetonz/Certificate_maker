import 'package:flutter/painting.dart';

class GradientModel {
  final List<Color> colors;
  final List<double>? stops;

  const GradientModel({
    required this.colors,
    this.stops,
  });

  Map<String, dynamic> toJson() {
    return {
      'colors': colors.map((c) => c.toARGB32()).toList(),
      'stops': stops,
    };
  }

  factory GradientModel.fromJson(Map<String, dynamic> json) {
    final colorsList = (json['colors'] as List<dynamic>?)
            ?.map((c) => Color(c as int))
            .toList() ??
        [];
    final stopsList = (json['stops'] as List<dynamic>?)
            ?.map((s) => (s as num).toDouble())
            .toList();
    return GradientModel(
      colors: colorsList,
      stops: stopsList,
    );
  }
}
