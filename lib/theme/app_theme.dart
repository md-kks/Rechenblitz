import 'package:flutter/material.dart';

/// Zentrale Gestaltung für eine ruhige, kindgerechte Oberfläche.
///
/// Farben, Radien und Abstände sollen nicht pro Screen neu erfunden werden.
/// So bleibt Rechenblitz auch dann übersichtlich, wenn weitere Lernbereiche
/// hinzukommen.
abstract final class AppTheme {
  static const Color primary = Color(0xFF3D73D9);
  static const Color secondary = Color(0xFFE9A62D);
  static const Color tertiary = Color(0xFF4E9B83);
  static const Color canvas = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF263142);
  static const Color subtleText = Color(0xFF5D6878);
  static const Color softBorder = Color(0xFFDDE3EC);

  static const double cardRadius = 22;
  static const double controlRadius = 16;
  static const double pagePadding = 18;

  static ThemeData light({required bool highContrast}) {
    final generated = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    );
    final scheme = highContrast
        ? generated.copyWith(
            primary: const Color(0xFF174EA6),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
            outline: Colors.black87,
            outlineVariant: Colors.black54,
          )
        : generated.copyWith(
            primary: primary,
            secondary: secondary,
            tertiary: tertiary,
            surface: surface,
            onSurface: text,
            outline: softBorder,
            outlineVariant: softBorder,
          );

    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final textTheme = base.textTheme.apply(
      bodyColor: highContrast ? Colors.black : text,
      displayColor: highContrast ? Colors.black : text,
    );

    return base.copyWith(
      scaffoldBackgroundColor: highContrast ? Colors.white : canvas,
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          height: 1.12,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          height: 1.15,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          height: 1.18,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: 17, height: 1.4),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          fontSize: 15.5,
          height: 1.4,
          color: highContrast ? Colors.black : subtleText,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: highContrast ? Colors.white : canvas,
        foregroundColor: highContrast ? Colors.black : text,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: highContrast ? Colors.black : text,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: highContrast ? Colors.black54 : softBorder),
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          side: BorderSide(color: highContrast ? Colors.black87 : softBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: highContrast ? Colors.white : const Color(0xFFFBFCFE),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(
            color: highContrast ? Colors.black87 : softBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(
            color: highContrast ? Colors.black87 : softBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: highContrast ? Colors.white : const Color(0xFFF0F3F8),
        side: BorderSide(color: highContrast ? Colors.black87 : softBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      ),
      dividerTheme: DividerThemeData(
        color: highContrast ? Colors.black54 : softBorder,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minVerticalPadding: 10,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: highContrast
            ? Colors.black12
            : const Color(0xFFE5EAF2),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
