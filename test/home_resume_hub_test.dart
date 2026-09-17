import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/main.dart';
import 'package:rechenblitz/models/accessibility_preferences.dart';
import 'package:rechenblitz/models/assessment.dart';
import 'package:rechenblitz/models/learning_path.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/models/training_session_progress.dart';
import 'package:rechenblitz/screens/assessment_screen.dart';
import 'package:rechenblitz/screens/training_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  AppController baseController() {
    final controller = AppController();
    controller.loaded = true;
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    return controller;
  }

  testWidgets('Startseite setzt eine unterbrochene Einzelübung direkt fort', (
    tester,
  ) async {
    final controller = baseController();
    final fact = MathFact(a: 8, b: 7, operation: MathOperation.plus);
    controller.facts = [fact];
    final now = DateTime.now();
    controller.coreTrainingSessionProgress = CoreTrainingSessionProgress(
      kind: CoreTrainingKind.fact,
      mode: TrainingMode.practice,
      targetTasks: 10,
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      startedAt: now.subtract(const Duration(minutes: 3)),
      updatedAt: now,
      currentTask: {'key': fact.key},
      completed: 3,
    );

    await tester.pumpWidget(RechenblitzApp(controller: controller));
    await tester.pump();

    expect(find.byKey(const ValueKey('home-resume-card')), findsOneWidget);
    expect(find.text('Plus & Minus fortsetzen'), findsOneWidget);
    expect(find.text('Aufgabe 4 von 10'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-resume-core')));
    await tester.pumpAndSettle();

    expect(find.byType(TrainingScreen), findsOneWidget);
    expect(find.text('Aufgabe 4 von 10 · fortgesetzt'), findsOneWidget);
    expect(find.text('8 + 7 = ?'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Startseite setzt einen begonnenen Lerncheck direkt fort', (
    tester,
  ) async {
    final controller = baseController();
    final now = DateTime.now();
    const tasks = <AssessmentTask>[
      AssessmentTask(
        mode: TrainingMode.practice,
        taskKey: 'assessment:first',
        prompt: '2 + 3 = ?',
        answer: 5,
        maxAnswerValue: 20,
      ),
      AssessmentTask(
        mode: TrainingMode.practice,
        taskKey: 'assessment:second',
        prompt: '4 + 4 = ?',
        answer: 8,
        maxAnswerValue: 20,
      ),
    ];
    controller.assessmentProgress = AssessmentProgress(
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      tasks: tasks,
      taskResults: const [
        AssessmentTaskResult(
          mode: TrainingMode.practice,
          taskKey: 'assessment:first',
          correct: true,
        ),
      ],
      nextIndex: 1,
      startedAt: now.subtract(const Duration(minutes: 4)),
      updatedAt: now,
    );

    await tester.pumpWidget(RechenblitzApp(controller: controller));
    await tester.pump();

    expect(find.text('Lerncheck fortsetzen'), findsOneWidget);
    expect(find.text('1 von 2 Aufgaben beantwortet'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-resume-assessment')));
    await tester.pumpAndSettle();

    expect(find.byType(AssessmentScreen), findsOneWidget);
    expect(find.text('4 + 4 = ?'), findsOneWidget);
  });

  testWidgets('Eine laufende Meine Runde bleibt der führende Wiedereinstieg', (
    tester,
  ) async {
    final controller = baseController();
    final fact = MathFact(a: 3, b: 4, operation: MathOperation.plus);
    controller.facts = [fact];
    final now = DateTime.now();
    controller.guidedRoundProgress = GuidedRoundProgress(
      plan: const [
        GuidedRoundSegment(
          role: GuidedRoundRole.warmUp,
          mode: TrainingMode.blitz,
          tasks: 2,
          reason: 'Kurz ankommen',
        ),
      ],
      completedRoles: const <GuidedRoundRole>{},
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      startedAt: now.subtract(const Duration(minutes: 5)),
      updatedAt: now,
      recoveryRequired: false,
    );
    controller.coreTrainingSessionProgress = CoreTrainingSessionProgress(
      kind: CoreTrainingKind.fact,
      mode: TrainingMode.blitz,
      targetTasks: 2,
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      startedAt: now.subtract(const Duration(minutes: 2)),
      updatedAt: now,
      currentTask: {'key': fact.key},
      completed: 1,
    );

    await tester.pumpWidget(RechenblitzApp(controller: controller));
    await tester.pump();

    expect(find.text('Runde fortsetzen'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-resume-card')), findsNothing);
  });

  testWidgets(
    'Eine fertige Tagesrunde wird nicht als neu starten beschriftet',
    (tester) async {
      final controller = baseController();
      final now = DateTime.now();
      controller.guidedRoundProgress = GuidedRoundProgress(
        plan: const [
          GuidedRoundSegment(
            role: GuidedRoundRole.warmUp,
            mode: TrainingMode.blitz,
            tasks: 2,
            reason: 'Kurz ankommen',
          ),
        ],
        completedRoles: const {GuidedRoundRole.warmUp},
        completedTaskCounts: const {GuidedRoundRole.warmUp: 2},
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        startedAt: now.subtract(const Duration(minutes: 8)),
        updatedAt: now,
        recoveryRequired: false,
      );

      await tester.pumpWidget(RechenblitzApp(controller: controller));
      await tester.pump();

      expect(find.text('Heutige Runde ansehen'), findsOneWidget);
      expect(find.text('Runde starten'), findsNothing);
    },
  );

  testWidgets('Fortsetzen-Karte bleibt auf schmalem Display gut bedienbar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = baseController();
    controller.accessibilityPreferences = const AccessibilityPreferences(
      largeText: true,
    );
    final fact = MathFact(a: 9, b: 6, operation: MathOperation.plus);
    controller.facts = [fact];
    final now = DateTime.now();
    controller.coreTrainingSessionProgress = CoreTrainingSessionProgress(
      kind: CoreTrainingKind.fact,
      mode: TrainingMode.practice,
      targetTasks: 10,
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      startedAt: now,
      updatedAt: now,
      currentTask: {'key': fact.key},
      completed: 4,
    );

    await tester.pumpWidget(RechenblitzApp(controller: controller));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('home-resume-core')), findsOneWidget);
  });
}
