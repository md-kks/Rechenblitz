import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/theme/app_theme.dart';

void main() {
  test('Standardtheme bleibt ruhig und zentral definiert', () {
    final theme = AppTheme.light(highContrast: false);

    expect(theme.colorScheme.primary, AppTheme.primary);
    expect(theme.scaffoldBackgroundColor, AppTheme.canvas);
    expect(theme.cardTheme.elevation, 0);
    expect(theme.cardTheme.surfaceTintColor, Colors.transparent);
    expect(
      (theme.cardTheme.shape as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(AppTheme.cardRadius),
    );
    expect(theme.textTheme.bodyLarge?.fontSize, 17);
    expect(
      WidgetStateProperty.resolveAs<Color?>(
        theme.chipTheme.labelStyle?.color,
        const <WidgetState>{},
      ),
      AppTheme.text,
    );
    expect(
      WidgetStateProperty.resolveAs<Color?>(
        theme.chipTheme.labelStyle?.color,
        const <WidgetState>{WidgetState.selected},
      ),
      Colors.white,
    );
    expect(
      theme.chipTheme.color?.resolve(const <WidgetState>{WidgetState.selected}),
      AppTheme.primary,
    );
    expect(theme.chipTheme.checkmarkColor, Colors.white);
  });

  test('Hoher Kontrast bleibt trotz neuer Farbwelt deutlich', () {
    final theme = AppTheme.light(highContrast: true);

    expect(theme.scaffoldBackgroundColor, Colors.white);
    expect(theme.colorScheme.onSurface, Colors.black);
    expect(theme.colorScheme.outline, Colors.black87);
    expect(
      (theme.cardTheme.shape as RoundedRectangleBorder).side.color,
      Colors.black54,
    );
    expect(
      WidgetStateProperty.resolveAs<Color?>(
        theme.chipTheme.labelStyle?.color,
        const <WidgetState>{},
      ),
      Colors.black,
    );
    expect(
      WidgetStateProperty.resolveAs<Color?>(
        theme.chipTheme.labelStyle?.color,
        const <WidgetState>{WidgetState.selected},
      ),
      Colors.white,
    );
    expect(
      theme.chipTheme.color?.resolve(const <WidgetState>{WidgetState.selected}),
      Colors.black,
    );
  });
}
