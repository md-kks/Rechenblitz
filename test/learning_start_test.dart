import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/main.dart';
import 'package:rechenblitz/models/assessment.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/learning_path.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Lerncheck erzeugt pro Klassenstufe 12 gültige Aufgaben', () {
    for (final grade in GradeLevel.values) {
      final generator = AssessmentGenerator(random: Random(2026 + grade.index));
      final tasks = generator.generate(
        grade: grade,
        range: grade.recommendedRange,
      );

      expect(tasks, hasLength(12), reason: grade.label);
      final counts = <TrainingMode, int>{};
      for (final task in tasks) {
        counts[task.mode] = (counts[task.mode] ?? 0) + 1;
        expect(task.prompt, isNotEmpty);
        if (task.usesChoices) {
          expect(
            task.answer,
            inInclusiveRange(0, task.choices!.length - 1),
            reason: '${grade.label} · ${task.mode}',
          );
        } else {
          expect(task.answer, greaterThanOrEqualTo(0));
          expect(task.answer, lessThanOrEqualTo(task.maxAnswerValue));
        }
      }
      expect(counts, hasLength(6));
      expect(counts.values.every((value) => value == 2), isTrue);
    }
  });

  test('frische Installation startet im Lernstart', () async {
    final controller = AppController();
    await controller.load();

    expect(controller.needsOnboarding, isTrue);
    expect(controller.activeProfile.onboardingComplete, isFalse);
    expect(controller.history, isEmpty);
  });

  test('Einstufung beeinflusst Lernkarte aber nicht Sterne oder Abzeichen',
      () async {
    final controller = AppController();
    await controller.load();

    await controller.saveLearningStartSetup(
      name: 'Testkind',
      grade: GradeLevel.second,
      state: controller.activeProfile.state,
      methods: const MethodPreferences(),
    );

    await controller.completeAssessment(const [
      AssessmentModeResult(
        mode: TrainingMode.practice,
        correct: 2,
        total: 2,
      ),
      AssessmentModeResult(
        mode: TrainingMode.minus,
        correct: 0,
        total: 2,
      ),
      AssessmentModeResult(
        mode: TrainingMode.multiply,
        correct: 2,
        total: 2,
      ),
      AssessmentModeResult(
        mode: TrainingMode.divide,
        correct: 2,
        total: 2,
      ),
      AssessmentModeResult(
        mode: TrainingMode.placeValue,
        correct: 2,
        total: 2,
      ),
      AssessmentModeResult(
        mode: TrainingMode.wordProblems,
        correct: 2,
        total: 2,
      ),
    ]);

    expect(controller.needsOnboarding, isFalse);
    expect(controller.history.where((entry) => entry.isAssessment), hasLength(6));
    expect(controller.stars, 0);
    expect(controller.badges, isEmpty);
    expect(controller.todayTasks, 0);

    expect(
      controller.competencyProgress(TrainingMode.practice).state,
      CompetencyState.secure,
    );
    expect(
      controller.competencyProgress(TrainingMode.minus).state,
      CompetencyState.learning,
    );
    expect(controller.recommendedMode(), TrainingMode.minus);
  });

  test('Lerncheck kann ohne Verlust später wiederholt werden', () async {
    final controller = AppController();
    await controller.load();

    await controller.completeAssessment(const [
      AssessmentModeResult(
        mode: TrainingMode.practice,
        correct: 0,
        total: 2,
      ),
    ]);
    expect(
      controller.history.where((entry) => entry.isAssessment),
      hasLength(1),
    );

    await controller.completeAssessment(const [
      AssessmentModeResult(
        mode: TrainingMode.practice,
        correct: 2,
        total: 2,
      ),
    ]);

    final assessment =
        controller.history.where((entry) => entry.isAssessment).toList();
    expect(assessment, hasLength(1));
    expect(assessment.single.correctFirstTry, 2);
    expect(controller.stars, 0);
  });

  testWidgets('Lernstart kann ohne Einstufung später fortgesetzt werden',
      (tester) async {
    final controller = AppController();
    await controller.load();
    await tester.pumpWidget(RechenblitzApp(controller: controller));

    expect(find.text('Rechenblitz Lernstart'), findsOneWidget);
    expect(find.text('Für wen ist Rechenblitz?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('learning-start-next')));
    await tester.pumpAndSettle();
    expect(find.text('So rechnen wir in der Schule'), findsOneWidget);

    await tester.tap(find.text('Weiter').last);
    await tester.pumpAndSettle();
    expect(find.text('Wo stehst du gerade?'), findsOneWidget);
    expect(
      find.text(
        '12 kurze Aufgaben aus verschiedenen Bereichen helfen Rechenblitz, die erste Lernlandkarte sinnvoll zu starten.',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('learning-start-assessment-later')),
    );
    await tester.pumpAndSettle();

    expect(controller.needsOnboarding, isFalse);
    expect(find.text('Rechenblitz'), findsWidgets);
    expect(find.text('Klassenstufe'), findsOneWidget);
  });

  test('Klassenwechsel verwirft nur die alte Einstufungs-Baseline', () async {
    final controller = AppController();
    await controller.load();

    await controller.completeAssessment(const [
      AssessmentModeResult(
        mode: TrainingMode.practice,
        correct: 2,
        total: 2,
      ),
    ]);
    await controller.addSession(
      TrainingSessionResult(
        mode: TrainingMode.money,
        startedAt: DateTime(2026, 9, 4, 12),
        finishedAt: DateTime(2026, 9, 4, 12, 5),
        total: 10,
        correctFirstTry: 9,
        incorrectAttempts: 1,
        plusCorrect: 0,
        plusTotal: 0,
        minusCorrect: 0,
        minusTotal: 0,
        averageResponseMs: 2500,
        numberRange: NumberRangeLevel.hundred,
        gradeLevel: GradeLevel.second,
        starsEarned: 2,
      ),
    );

    await controller.setGradeLevel(GradeLevel.third);

    expect(
      controller.history.where((entry) => entry.isAssessment),
      isEmpty,
    );
    expect(
      controller.history.where((entry) => !entry.isAssessment),
      hasLength(1),
    );
    expect(controller.activeProfile.assessmentCompletedAt, isNull);
  });

}
