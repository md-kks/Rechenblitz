import 'package:flutter/material.dart';

import 'services/app_controller.dart';
import 'screens/home_screen.dart';
import 'screens/learning_start_screen.dart';

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
    const seed = Color(0xFF6B5DD3);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final accessibility = controller.accessibilityPreferences;
        final baseScheme = ColorScheme.fromSeed(
          seedColor: seed,
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
          theme: ThemeData(
            colorScheme: scheme,
            useMaterial3: true,
            scaffoldBackgroundColor: accessibility.highContrast
                ? Colors.white
                : const Color(0xFFF8F7FC),
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
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
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
