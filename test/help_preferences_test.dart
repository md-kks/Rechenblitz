import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/guided_method.dart';
import 'package:rechenblitz/models/help_preferences.dart';
import 'package:rechenblitz/models/learner_profile.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/parent_screen.dart';
import 'package:rechenblitz/screens/structured_training_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppController> _controller() async {
  final controller = AppController();
  await controller.load();
  controller.gradeLevel = GradeLevel.second;
  controller.numberRange = NumberRangeLevel.twenty;
  return controller;
}

Widget _structured(AppController controller, {bool scaffoldFading = false}) {
  return MaterialApp(
    home: StructuredTrainingScreen(
      controller: controller,
      mode: TrainingMode.wordProblems,
      targetTasks: 2,
      targetCompetency: MicroCompetencyId.wordProblemOperation,
      scaffoldFading: scaffoldFading,
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Hilfeeinstellungen haben einen kindgerechten sicheren Standard', () {
    const preferences = HelpPreferences();

    expect(preferences.access, HelpAccess.all);
    expect(preferences.presentation, HelpPresentation.progressive);
    expect(preferences.maxLevel, HelpLevel.guided);
    expect(preferences.manualStartLevel, HelpLevel.nudge);
    expect(preferences.automaticStartLevel(HelpLevel.visual), HelpLevel.visual);
  });

  test('direkte Hilfe öffnet die stärkste erlaubte Hilfestufe', () {
    const allDirect = HelpPreferences(presentation: HelpPresentation.direct);
    const visualDirect = HelpPreferences(
      access: HelpAccess.hintAndVisual,
      presentation: HelpPresentation.direct,
    );
    const hintOnly = HelpPreferences(access: HelpAccess.hintOnly);
    const disabled = HelpPreferences(access: HelpAccess.none);

    expect(allDirect.manualStartLevel, HelpLevel.guided);
    expect(allDirect.automaticStartLevel(HelpLevel.nudge), HelpLevel.guided);
    expect(visualDirect.manualStartLevel, HelpLevel.visual);
    expect(hintOnly.clamp(HelpLevel.guided), HelpLevel.nudge);
    expect(disabled.manualStartLevel, isNull);
  });

  test('Hilfeeinstellungen werden im Lernprofil gespeichert', () {
    final profile = LearnerProfile(
      id: 'help-profile',
      name: 'Kind',
      gradeLevel: GradeLevel.second,
      createdAt: DateTime(2026, 9, 12),
      helpPreferences: const HelpPreferences(
        access: HelpAccess.hintAndVisual,
        presentation: HelpPresentation.direct,
      ),
    );

    final restored = LearnerProfile.fromJson(
      jsonDecode(jsonEncode(profile.toJson())) as Map<String, dynamic>,
    );
    final legacy = LearnerProfile.fromJson({
      'id': 'legacy',
      'name': 'Alt',
      'gradeLevel': 'second',
      'createdAt': '2026-09-01T10:00:00.000',
    });

    expect(restored.helpPreferences.access, HelpAccess.hintAndVisual);
    expect(restored.helpPreferences.presentation, HelpPresentation.direct);
    expect(legacy.helpPreferences, const HelpPreferences());
  });

  test('Hilfeeinstellungen bleiben pro Kind getrennt', () async {
    final controller = await _controller();
    final firstProfileId = controller.activeProfileId;

    await controller.setHelpPreferences(
      const HelpPreferences(access: HelpAccess.none),
    );
    await controller.createProfile(
      name: 'Zweites Kind',
      grade: GradeLevel.second,
    );

    expect(controller.helpPreferences, const HelpPreferences());

    await controller.switchProfile(firstProfileId);
    expect(controller.helpPreferences.access, HelpAccess.none);

    final reloaded = AppController();
    await reloaded.load();
    expect(reloaded.activeProfileId, firstProfileId);
    expect(reloaded.helpPreferences.access, HelpAccess.none);
  });

  testWidgets('Elternbereich bietet profilbezogene Hilfesteuerung', (
    tester,
  ) async {
    final controller = await _controller();

    await tester.pumpWidget(
      MaterialApp(home: ParentScreen(controller: controller)),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('parent-help-access')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('parent-help-presentation')),
      findsOneWidget,
    );
    expect(find.text('Verfügbare Hilfen'), findsOneWidget);
    expect(find.text('Hilfe öffnen'), findsOneWidget);
  });

  testWidgets('ausgeschaltete Hilfen sind in Aufgaben nicht zugänglich', (
    tester,
  ) async {
    final controller = await _controller();
    await controller.setHelpPreferences(
      const HelpPreferences(access: HelpAccess.none),
    );

    await tester.pumpWidget(_structured(controller, scaffoldFading: true));
    await tester.pump();

    expect(find.text('Ich brauche Hilfe'), findsNothing);
    expect(find.textContaining('Hilfe ·'), findsNothing);
  });

  testWidgets('nur Denkhinweis sperrt Darstellung und geführten Rechenweg', (
    tester,
  ) async {
    final controller = await _controller();
    await controller.setHelpPreferences(
      const HelpPreferences(access: HelpAccess.hintOnly),
    );

    await tester.pumpWidget(_structured(controller));
    await tester.pump();
    final helpButton = find.text('Ich brauche Hilfe');
    expect(helpButton, findsOneWidget);
    await tester.ensureVisible(helpButton);
    await tester.tap(helpButton);
    await tester.pump();

    expect(find.textContaining('Hilfe ·'), findsOneWidget);
    expect(find.byKey(const ValueKey('help-show-visual')), findsNothing);
    expect(find.byKey(const ValueKey('help-show-guided')), findsNothing);
  });

  testWidgets('direkte volle Hilfe gilt auch für Meine-Runde-Scaffolding', (
    tester,
  ) async {
    final controller = await _controller();
    await controller.setHelpPreferences(
      const HelpPreferences(presentation: HelpPresentation.direct),
    );

    await tester.pumpWidget(_structured(controller, scaffoldFading: true));
    await tester.pump();

    expect(find.textContaining('Hilfe ·'), findsOneWidget);
    expect(find.textContaining('Schritt 1 von'), findsOneWidget);
  });

  testWidgets('Meine Runde zeigt bei Lückenaufgaben den konkreten Rechenweg', (
    tester,
  ) async {
    final controller = await _controller();
    await controller.setHelpPreferences(
      const HelpPreferences(presentation: HelpPresentation.direct),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StructuredTrainingScreen(
          controller: controller,
          mode: TrainingMode.missingNumber,
          targetTasks: 2,
          scaffoldFading: true,
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Hilfe ·'), findsOneWidget);
    expect(find.text('Lückenweg'), findsOneWidget);
    expect(find.textContaining('Schritt 1 von'), findsOneWidget);
  });
}
