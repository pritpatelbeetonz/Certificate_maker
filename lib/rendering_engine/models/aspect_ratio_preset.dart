class AspectRatioPreset {
  final String id;
  final String label;
  final bool isDefault;

  const AspectRatioPreset({
    required this.id,
    required this.label,
    this.isDefault = false,
  });

  factory AspectRatioPreset.fromJson(Map<String, dynamic> json) {
    return AspectRatioPreset(
      id: json['id'] as String? ?? '1:1',
      label: json['label'] as String? ?? 'Square',
      isDefault: json['default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        if (isDefault) 'default': true,
      };
}
