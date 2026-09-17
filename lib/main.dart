import 'package:flutter/material.dart';

import 'core/learning_app_shell.dart';
import 'core/learning_subject.dart';
import 'services/app_controller.dart';
import 'screens/home_screen.dart';
import 'screens/learning_start_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController();
  await controller.load();
  runApp(RechenblitzApp(controller: controller));
}

class RechenblitzApp extends StatelessWidget {
  const RechenblitzApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) => LearningAppShell(
    title: 'Rechenblitz',
    subject: LearningSubject.mathematics,
    settingsListenable: controller,
    accessibilityPreferences: () => controller.accessibilityPreferences,
    themeBuilder: (accessibility) =>
        AppTheme.light(highContrast: accessibility.highContrast),
    home: _AppRoot(controller: controller),
  );
}

class _AppRoot extends StatelessWidget {
  const _AppRoot({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => controller.needsOnboarding
        ? LearningStartScreen(controller: controller)
        : HomeScreen(controller: controller),
  );
}
