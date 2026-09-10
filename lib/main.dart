import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final accessibility = controller.accessibilityPreferences;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Rechenblitz',
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
          theme: AppTheme.light(
            highContrast: accessibility.highContrast,
          ),
          home: _AppRoot(controller: controller),
        );
      },
    );
  }
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
