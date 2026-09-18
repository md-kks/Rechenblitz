import 'package:flutter/material.dart';

import 'core/learning_app_shell.dart';
import 'core/learning_subject.dart';
import 'services/app_controller.dart';
import 'screens/home_screen.dart';
import 'screens/learning_start_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(RechenblitzBootstrap(controller: AppController()));
}

enum _BootstrapStatus { loading, ready, failed }

class RechenblitzBootstrap extends StatefulWidget {
  const RechenblitzBootstrap({
    super.key,
    required this.controller,
    this.loadController,
  });

  final AppController controller;
  final Future<void> Function()? loadController;

  @override
  State<RechenblitzBootstrap> createState() => _RechenblitzBootstrapState();
}

class _RechenblitzBootstrapState extends State<RechenblitzBootstrap> {
  _BootstrapStatus status = _BootstrapStatus.loading;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => status = _BootstrapStatus.loading);
    try {
      await (widget.loadController ?? widget.controller.load)();
      if (mounted) setState(() => status = _BootstrapStatus.ready);
    } catch (error, stackTrace) {
      debugPrint('Rechenblitz startup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) setState(() => status = _BootstrapStatus.failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (status == _BootstrapStatus.ready) {
      return RechenblitzApp(controller: widget.controller);
    }

    final failed = status == _BootstrapStatus.failed;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rechenblitz',
      theme: AppTheme.light(highContrast: false),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (failed)
                    const Icon(Icons.error_outline_rounded, size: 64)
                  else
                    const CircularProgressIndicator(),
                  const SizedBox(height: 22),
                  Text(
                    failed
                        ? 'Rechenblitz konnte nicht starten.'
                        : 'Rechenblitz startet …',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (failed) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Bitte versuche es noch einmal. Bleibt das Problem bestehen, aktualisiere die App.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Erneut versuchen'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
