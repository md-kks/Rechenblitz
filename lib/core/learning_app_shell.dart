import 'package:flutter/material.dart';

import 'accessibility_preferences.dart';
import 'learning_app_theme.dart';
import 'learning_subject.dart';

class LearningAppShell extends StatelessWidget {
  const LearningAppShell({
    super.key,
    required this.title,
    required this.subject,
    required this.settingsListenable,
    required this.accessibilityPreferences,
    required this.home,
    this.themeBuilder,
  });

  final String title;
  final LearningSubject subject;
  final Listenable settingsListenable;
  final AccessibilityPreferences Function() accessibilityPreferences;
  final Widget home;
  final ThemeData Function(AccessibilityPreferences preferences)? themeBuilder;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: settingsListenable,
    builder: (context, _) {
      final accessibility = accessibilityPreferences();
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: title,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(
                accessibility.largeText ? 1.25 : 1.0,
              ),
              disableAnimations: accessibility.reducedMotion,
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        theme:
            themeBuilder?.call(accessibility) ??
            LearningAppTheme.build(
              subject: subject,
              accessibility: accessibility,
            ),
        home: home,
      );
    },
  );
}
