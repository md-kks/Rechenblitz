class AccessibilityPreferences {
  const AccessibilityPreferences({
    this.largeText = false,
    this.highContrast = false,
    this.reducedMotion = false,
    this.readAloud = false,
    this.speechRate = 0.45,
  });

  final bool largeText;
  final bool highContrast;
  final bool reducedMotion;
  final bool readAloud;
  final double speechRate;

  AccessibilityPreferences copyWith({
    bool? largeText,
    bool? highContrast,
    bool? reducedMotion,
    bool? readAloud,
    double? speechRate,
  }) =>
      AccessibilityPreferences(
        largeText: largeText ?? this.largeText,
        highContrast: highContrast ?? this.highContrast,
        reducedMotion: reducedMotion ?? this.reducedMotion,
        readAloud: readAloud ?? this.readAloud,
        speechRate: speechRate ?? this.speechRate,
      );

  Map<String, dynamic> toJson() => {
        'largeText': largeText,
        'highContrast': highContrast,
        'reducedMotion': reducedMotion,
        'readAloud': readAloud,
        'speechRate': speechRate,
      };

  factory AccessibilityPreferences.fromJson(Map<String, dynamic> json) =>
      AccessibilityPreferences(
        largeText: json['largeText'] as bool? ?? false,
        highContrast: json['highContrast'] as bool? ?? false,
        reducedMotion: json['reducedMotion'] as bool? ?? false,
        readAloud: json['readAloud'] as bool? ?? false,
        speechRate: (json['speechRate'] as num?)?.toDouble() ?? 0.45,
      );
}
