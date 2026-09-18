import 'package:flutter/material.dart';

import 'accessibility_preferences.dart';
import 'learning_subject.dart';

class LearningSubjectVisuals {
  const LearningSubjectVisuals({
    required this.seedColor,
    required this.scaffoldBackground,
  });
  final Color seedColor;
  final Color scaffoldBackground;
}

extension LearningSubjectVisualsX on LearningSubject {
  LearningSubjectVisuals get visuals => switch (this) {
    LearningSubject.mathematics => const LearningSubjectVisuals(
      seedColor: Color(0xFF3D73D9),
      scaffoldBackground: Color(0xFFF5F7FA),
    ),
    LearningSubject.german => const LearningSubjectVisuals(
      seedColor: Color.fromARGB(255, 198, 40, 40),
      scaffoldBackground: Color.fromARGB(255, 255, 247, 247),
    ),
  };
}

class LearningAppTheme {
  const LearningAppTheme._();

  static ThemeData build({
    required LearningSubject subject,
    required AccessibilityPreferences accessibility,
  }) {
    final visuals = subject.visuals;
    final baseScheme = ColorScheme.fromSeed(
      seedColor: visuals.seedColor,
      brightness: Brightness.light,
    );
    final scheme = accessibility.highContrast
        ? baseScheme.copyWith(
            surface: Colors.white,
            onSurface: Colors.black,
            outline: Colors.black87,
            outlineVariant: Colors.black54,
          )
        : baseScheme;

    const fullWidthButtonSize = Size(48, 54);
    const touchSize = Size(48, 48);
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    );
    final primaryButtonStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(fullWidthButtonSize),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      shape: WidgetStatePropertyAll(buttonShape),
    );
    final touchButtonStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(touchSize),
      shape: WidgetStatePropertyAll(buttonShape),
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: accessibility.highContrast
          ? Colors.white
          : visuals.scaffoldBackground,
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: accessibility.highContrast ? 1 : 0,
        shape: RoundedRectangleBorder(
          side: accessibility.highContrast
              ? const BorderSide(color: Colors.black54)
              : BorderSide.none,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: primaryButtonStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: touchButtonStyle),
      textButtonTheme: TextButtonThemeData(style: touchButtonStyle),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(minimumSize: WidgetStatePropertyAll(touchSize)),
      ),
    );
  }
}
