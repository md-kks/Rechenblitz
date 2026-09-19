import 'package:flutter/material.dart';

import '../core/accessibility_preferences.dart';
import '../core/learning_app_shell.dart';
import '../core/learning_app_theme.dart';
import '../core/learning_subject.dart';
import '../screens/home_screen.dart';
import '../screens/learning_start_screen.dart';
import '../services/app_controller.dart';
import '../subjects/german/screens/german_home_screen.dart';
import '../theme/app_theme.dart';
import 'learning_app_edition.dart';

enum LearningBlitzBootstrapStatus { loading, ready, failed }

class LearningBlitzBootstrap extends StatefulWidget {
  const LearningBlitzBootstrap({
    super.key,
    required this.controller,
    required this.edition,
    this.loadController,
  });

  final AppController controller;
  final LearningAppEdition edition;
  final Future<void> Function()? loadController;
  @override
  State<LearningBlitzBootstrap> createState() => _LearningBlitzBootstrapState();
}

class _LearningBlitzBootstrapState extends State<LearningBlitzBootstrap> {
  LearningBlitzBootstrapStatus status = LearningBlitzBootstrapStatus.loading;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => status = LearningBlitzBootstrapStatus.loading);
    try {
      await (widget.loadController ?? widget.controller.load)();
      if (mounted) setState(() => status = LearningBlitzBootstrapStatus.ready);
    } catch (error, stackTrace) {
      debugPrint('${widget.edition.title} startup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) setState(() => status = LearningBlitzBootstrapStatus.failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (status == LearningBlitzBootstrapStatus.ready) {
      return LearningBlitzApp(
        controller: widget.controller,
        edition: widget.edition,
      );
    }

    final failed = status == LearningBlitzBootstrapStatus.failed;
    final bootstrapTheme = widget.edition.subject == LearningSubject.mathematics
        ? AppTheme.light(highContrast: false)
        : LearningAppTheme.build(
            subject: widget.edition.subject,
            accessibility: const AccessibilityPreferences(),
          );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: widget.edition.title,
      theme: bootstrapTheme,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (failed)
                    const Icon(Icons.error_outline_rounded, size: 64)
                  else
                    const CircularProgressIndicator(),
                  const SizedBox(height: 22),
                  Text(
                    failed
                        ? widget.edition.startupFailureText
                        : widget.edition.startupProgressText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (failed) ...<Widget>[
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

class LearningBlitzApp extends StatelessWidget {
  const LearningBlitzApp({
    super.key,
    required this.controller,
    required this.edition,
  });

  final AppController controller;
  final LearningAppEdition edition;

  @override
  Widget build(BuildContext context) => LearningAppShell(
    title: edition.title,
    subject: edition.subject,
    settingsListenable: controller,
    accessibilityPreferences: () => controller.accessibilityPreferences,
    themeBuilder: edition.subject == LearningSubject.mathematics
        ? (accessibility) =>
              AppTheme.light(highContrast: accessibility.highContrast)
        : null,
    home: _LearningBlitzRoot(controller: controller, edition: edition),
  );
}

class _LearningBlitzRoot extends StatelessWidget {
  const _LearningBlitzRoot({required this.controller, required this.edition});

  final AppController controller;
  final LearningAppEdition edition;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      if (controller.needsOnboarding) {
        return LearningStartScreen(
          controller: controller,
          subject: edition.subject,
          appTitle: edition.title,
        );
      }
      return switch (edition.subject) {
        LearningSubject.mathematics => HomeScreen(
          controller: controller,
          showSubjectSwitcher: false,
        ),
        LearningSubject.german => GermanHomeScreen(
          controller: controller,
          showSubjectSwitcher: false,
          appTitle: edition.title,
        ),
      };
    },
  );
}
