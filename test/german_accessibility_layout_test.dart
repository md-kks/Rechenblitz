import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/subjects/german/german_assessment.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_storage_service.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';
import 'package:rechenblitz/subjects/german/screens/german_assessment_result_screen.dart';
import 'package:rechenblitz/subjects/german/screens/german_competency_map_screen.dart';
import 'package:rechenblitz/subjects/german/screens/german_curriculum_audit_screen.dart';
import 'package:rechenblitz/subjects/german/screens/german_home_screen.dart';
import 'package:rechenblitz/subjects/german/screens/german_parent_overview_screen.dart';
import 'package:rechenblitz/subjects/german/screens/german_teacher_mode_screen.dart';
import 'package:rechenblitz/subjects/german/screens/german_training_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void _compactLargeText(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<AppController> _controller() async {
  final controller = AppController();
  await controller.load();
  return controller;
}

GermanSessionResult _assessmentSession(List<GermanTask> tasks) {
  final finishedAt = DateTime(2026, 9, 18, 10, 5);
  return GermanSessionResult(
    gradeLevel: GradeLevel.second,
    startedAt: DateTime(2026, 9, 18, 10),
    finishedAt: finishedAt,
    kind: GermanSessionKind.assessment,
    taskResults: tasks
        .map(
          (task) => GermanTaskResult(
            taskId: task.id,
            competencyId: task.competencyId,
            correctFirstTry: true,
            incorrectAttempts: 0,
            responseMs: 1200,
          ),
        )
        .toList(growable: false),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('Deutsch-Start bleibt bei 320px und 200 Prozent stabil', (
    tester,
  ) async {
    _compactLargeText(tester);
    final controller = await _controller();
    await GermanStorageService(
      profileId: controller.activeProfileId,
    ).setIntroComplete(true);

    await tester.pumpWidget(
      MaterialApp(home: GermanHomeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Meine Deutsch-Runde'), findsOneWidget);
  });

  testWidgets('alle Deutsch-Aufgabentypen bleiben kompakt zugänglich', (
    tester,
  ) async {
    _compactLargeText(tester);
    for (final interaction in GermanTaskInteraction.values) {
      final task = GermanTaskCatalog.tasks.firstWhere(
        (candidate) => candidate.interaction == interaction,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: GermanTrainingScreen(
            gradeLevel: task.recommendedFromGrade,
            tasks: <GermanTask>[task],
            speak: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: interaction.name);
    }
  });

  testWidgets('Deutsch-Rundenabschluss ist bei großer Schrift scrollbar', (
    tester,
  ) async {
    _compactLargeText(tester);
    final task = GermanTaskCatalog.tasks.firstWhere(
      (candidate) =>
          candidate.interaction == GermanTaskInteraction.singleChoice,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: GermanTrainingScreen(
          gradeLevel: task.recommendedFromGrade,
          tasks: <GermanTask>[task],
          speak: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final answer = find.text(task.acceptedAnswers.first);
    await tester.scrollUntilVisible(
      answer,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(answer);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final done = find.byKey(const ValueKey('german-round-done'));
    expect(done, findsOneWidget);
    await tester.ensureVisible(done);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Deutsch-Lernlandkarte zeigt Grundlagen ohne Layoutfehler', (
    tester,
  ) async {
    _compactLargeText(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: GermanCompetencyMapScreen(
          gradeLevel: GradeLevel.second,
          history: <GermanSessionResult>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final button = find.byKey(
      const ValueKey('german-competency-practice-sentenceComprehension'),
    );
    await tester.scrollUntilVisible(
      button,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
    expect(
      find.descendant(of: button, matching: find.text('Grundlage üben')),
      findsOneWidget,
    );
  });

  testWidgets('Deutsch-Elternbereich bleibt bei großer Schrift stabil', (
    tester,
  ) async {
    _compactLargeText(tester);
    final controller = await _controller();
    await tester.pumpWidget(
      MaterialApp(home: GermanParentOverviewScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Deutsch-Lernstand'), findsOneWidget);
  });

  testWidgets('Deutsch-Lehrerauftrag bleibt auf schmalem Handy stabil', (
    tester,
  ) async {
    _compactLargeText(tester);
    final controller = await _controller();
    await tester.pumpWidget(
      MaterialApp(home: GermanTeacherModeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final qr = find.byKey(const ValueKey('german-teacher-qr'));
    await tester.scrollUntilVisible(
      qr,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(qr, findsOneWidget);
    final rect = tester.getRect(qr);
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(320));
  });

  testWidgets('Deutsch-Lerncheck-Ergebnis bleibt bei großer Schrift stabil', (
    tester,
  ) async {
    _compactLargeText(tester);
    final tasks = GermanAssessmentPlanner.buildRound(GradeLevel.second);
    final summary = GermanAssessmentSummary.fromSession(
      _assessmentSession(tasks),
    );

    await tester.pumpWidget(
      MaterialApp(home: GermanAssessmentResultScreen(summary: summary)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Lerncheck ausgewertet'), findsOneWidget);
  });

  testWidgets('Deutsch-Lehrplan-Audit bleibt bei großer Schrift stabil', (
    tester,
  ) async {
    _compactLargeText(tester);
    final controller = await _controller();
    await tester.pumpWidget(
      MaterialApp(home: GermanCurriculumAuditScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Deutsch-Lehrplan-Audit'), findsOneWidget);
  });
}
