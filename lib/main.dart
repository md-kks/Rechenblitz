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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rechenblitz',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F7FC),
        cardTheme: const CardThemeData(
          margin: EdgeInsets.zero,
          elevation: 0,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ),
      home: _AppRoot(controller: controller),
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
