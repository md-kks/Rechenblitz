import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/main.dart';
import 'package:rechenblitz/models/assessment.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/learning_path.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/assessment_screen.dart';
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

  test('Lerncheck streut Aufgaben gezielt über Mikro-Kompetenzen', () {
    for (final grade in GradeLevel.values) {
      final range = grade.recommendedRange;
      final tasks = AssessmentGenerator(random: Random(9100 + grade.index)).generate(
        grade: grade,
        range: range,
      );

      for (final task in tasks) {
        expect(task.taskKey, isNotEmpty, reason: '${grade.label} · ${task.mode.name}');
        final target = task.targetCompetency;
        if (target == null) continue;
        final tags = MicroCompetencyCatalog.tagsForTask(
          mode: task.mode,
          taskKey: task.taskKey,
          fact: task.fact,
        );
        expect(
          tags.any((tag) => tag.id == target),
          isTrue,
          reason: '${grade.label} · ${task.mode.name} · ${task.taskKey}',
        );
      }

      for (final mode in tasks.map((task) => task.mode).toSet()) {
        if (mode == TrainingMode.multiply || mode == TrainingMode.divide) continue;
        final available = MicroCompetencyCatalog.forContext(grade, range)
            .where((definition) => definition.preferredMode == mode)
            .map((definition) => definition.id)
            .toSet();
        if (available.length < 2) continue;
        final sampled = tasks
            .where((task) => task.mode == mode)
            .map((task) => task.targetCompetency)
            .whereType<MicroCompetencyId>()
            .toSet();
        expect(sampled, hasLength(2), reason: '${grade.label} · ${mode.name}');
      }
    }
  });

  test('Lerncheck schreibt gewichtete Mikro-Evidenz statt nur Bereichswerte', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;

    final weakFact = MathFact(a: 7, b: 5, operation: MathOperation.plus);
    final stableFact = MathFact(a: 3, b: 4, operation: MathOperation.plus);
    await controller.completeAssessment(
      const [
        AssessmentModeResult(mode: TrainingMode.practice, correct: 1, total: 2),
      ],
      taskResults: [
        AssessmentTaskResult(
          mode: TrainingMode.practice,
          taskKey: 'plus:7:5',
          correct: false,
          fact: weakFact,
          targetCompetency: MicroCompetencyId.additionTenBridge,
        ),
        AssessmentTaskResult(
          mode: TrainingMode.practice,
          taskKey: 'plus:3:4',
          correct: true,
          fact: stableFact,
          targetCompetency: MicroCompetencyId.additionNoBridge,
        ),
      ],
    );

    final assessment = controller.microObservations
        .where((entry) => entry.source == MicroEvidenceSource.assessment)
        .toList();
    expect(assessment, isNotEmpty);
    expect(
      assessment.any(
        (entry) =>
            entry.id == MicroCompetencyId.additionTenBridge && !entry.correct,
      ),
      isTrue,
    );
    expect(
      assessment.any(
        (entry) =>
            entry.id == MicroCompetencyId.additionNoBridge && entry.correct,
      ),
      isTrue,
    );
    expect(
      controller.microCompetencyProgress(MicroCompetencyId.additionTenBridge)
          .basisNeedsReconfirmation,
      isTrue,
    );
  });

  test('wiederholter Lerncheck ersetzt Assessment-Evidenz statt sie aufzublähen', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    final fact = MathFact(a: 3, b: 4, operation: MathOperation.plus);
    final taskResults = [
      AssessmentTaskResult(
        mode: TrainingMode.practice,
        taskKey: 'plus:3:4',
        correct: true,
        fact: fact,
        targetCompetency: MicroCompetencyId.additionNoBridge,
      ),
    ];
    const modeResults = [
      AssessmentModeResult(mode: TrainingMode.practice, correct: 1, total: 1),
    ];

    await controller.completeAssessment(modeResults, taskResults: taskResults);
    final firstCount = controller.microObservations
        .where((entry) => entry.source == MicroEvidenceSource.assessment)
        .length;
    await controller.completeAssessment(modeResults, taskResults: taskResults);
    final secondCount = controller.microObservations
        .where((entry) => entry.source == MicroEvidenceSource.assessment)
        .length;

    expect(firstCount, greaterThan(0));
    expect(secondCount, firstCount);
  });

  test('zwei richtige Lerncheck-Aufgaben machen eine Kompetenz noch nicht sicher', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    final first = MathFact(a: 3, b: 4, operation: MathOperation.plus);
    final second = MathFact(a: 4, b: 3, operation: MathOperation.plus);

    await controller.completeAssessment(
      const [
        AssessmentModeResult(mode: TrainingMode.practice, correct: 2, total: 2),
      ],
      taskResults: [
        AssessmentTaskResult(
          mode: TrainingMode.practice,
          taskKey: 'plus:3:4',
          correct: true,
          fact: first,
          targetCompetency: MicroCompetencyId.additionNoBridge,
        ),
        AssessmentTaskResult(
          mode: TrainingMode.practice,
          taskKey: 'plus:4:3',
          correct: true,
          fact: second,
          targetCompetency: MicroCompetencyId.additionNoBridge,
        ),
      ],
    );

    final progress =
        controller.microCompetencyProgress(MicroCompetencyId.additionNoBridge);
    expect(progress.independentEvidence, closeTo(1.5, 0.001));
    expect(progress.state, MicroCompetencyState.practicing);
    expect(progress.fluencyState, MicroFluencyState.notMeasured);
  });

  test('Assessment-Mikroevidenz bleibt nach Neustart erhalten', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    final fact = MathFact(a: 3, b: 4, operation: MathOperation.plus);
    await controller.completeAssessment(
      const [
        AssessmentModeResult(mode: TrainingMode.practice, correct: 1, total: 1),
      ],
      taskResults: [
        AssessmentTaskResult(
          mode: TrainingMode.practice,
          taskKey: 'plus:3:4',
          correct: true,
          fact: fact,
          targetCompetency: MicroCompetencyId.additionNoBridge,
        ),
      ],
    );

    final reloaded = AppController();
    await reloaded.load();
    expect(
      reloaded.microObservations.any(
        (entry) => entry.source == MicroEvidenceSource.assessment,
      ),
      isTrue,
    );
  });

  test('wiederholte Lernchecks streuen breite Bereiche über weitere Mikro-Ziele', () {
    for (final grade in GradeLevel.values) {
      final range = grade.recommendedRange;
      final sampledByMode = <TrainingMode, Set<MicroCompetencyId>>{};
      Set<TrainingMode>? assessedModes;
      for (var seed = 0; seed < 40; seed++) {
        final tasks = AssessmentGenerator(random: Random(15000 + seed + grade.index * 100)).generate(
          grade: grade,
          range: range,
        );
        assessedModes ??= tasks.map((task) => task.mode).toSet();
        for (final task in tasks) {
          final target = task.targetCompetency;
          if (target != null) {
            sampledByMode.putIfAbsent(task.mode, () => <MicroCompetencyId>{}).add(target);
          }
        }
      }

      for (final mode in assessedModes ?? const <TrainingMode>{}) {
        if (mode == TrainingMode.practice ||
            mode == TrainingMode.minus ||
            mode == TrainingMode.multiply ||
            mode == TrainingMode.divide) {
          continue;
        }
        final available = MicroCompetencyCatalog.forContext(grade, range)
            .where((definition) => definition.preferredMode == mode)
            .map((definition) => definition.id)
            .toSet();
        if (available.length <= 2) continue;
        expect(
          sampledByMode[mode]!.length,
          greaterThanOrEqualTo(3),
          reason: '${grade.label} · ${mode.name}',
        );
      }
    }
  });

  test('Lerncheck vermeidet doppelte Aufgaben innerhalb einer Runde', () {
    for (final grade in GradeLevel.values) {
      for (var seed = 0; seed < 24; seed++) {
        final tasks = AssessmentGenerator(random: Random(12000 + seed + grade.index * 100)).generate(
          grade: grade,
          range: grade.recommendedRange,
        );
        expect(
          tasks.map((task) => task.taskKey).toSet(),
          hasLength(tasks.length),
          reason: '${grade.label} · seed $seed',
        );
      }
    }
  });

  test('Lerncheck schreibt nur Evidenz für die gezielt geprüfte Mikro-Kompetenz', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    final bridge = MathFact(a: 7, b: 5, operation: MathOperation.plus);
    final multiply = MathFact(a: 6, b: 7, operation: MathOperation.multiply);

    await controller.completeAssessment(
      const [
        AssessmentModeResult(mode: TrainingMode.practice, correct: 1, total: 1),
        AssessmentModeResult(mode: TrainingMode.multiply, correct: 1, total: 1),
      ],
      taskResults: [
        AssessmentTaskResult(
          mode: TrainingMode.practice,
          taskKey: bridge.key,
          correct: true,
          fact: bridge,
          targetCompetency: MicroCompetencyId.additionTenBridge,
        ),
        AssessmentTaskResult(
          mode: TrainingMode.multiply,
          taskKey: multiply.key,
          correct: true,
          fact: multiply,
          targetCompetency: MicroCompetencyId.multiplicationFacts,
        ),
      ],
    );

    final assessmentIds = controller.microObservations
        .where((entry) => entry.source == MicroEvidenceSource.assessment)
        .map((entry) => entry.id)
        .toSet();
    expect(
      assessmentIds,
      equals({
        MicroCompetencyId.additionTenBridge,
        MicroCompetencyId.multiplicationFacts,
      }),
    );
    expect(assessmentIds, isNot(contains(MicroCompetencyId.numberDecomposition)));
    expect(assessmentIds, isNot(contains(MicroCompetencyId.multiplicationGroups)));
  });

  test('wiederholte Lernchecks ersetzen nur Evidenz im aktuellen Zahlenraum', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    final fact = MathFact(a: 3, b: 4, operation: MathOperation.plus);
    final task = AssessmentTaskResult(
      mode: TrainingMode.practice,
      taskKey: fact.key,
      correct: true,
      fact: fact,
      targetCompetency: MicroCompetencyId.additionNoBridge,
    );
    const result = [
      AssessmentModeResult(mode: TrainingMode.practice, correct: 1, total: 1),
    ];

    controller.numberRange = NumberRangeLevel.hundred;
    await controller.completeAssessment(result, taskResults: [task]);
    controller.numberRange = NumberRangeLevel.twenty;
    await controller.completeAssessment(result, taskResults: [task]);

    int countFor(NumberRangeLevel range) => controller.microObservations
        .where(
          (entry) =>
              entry.source == MicroEvidenceSource.assessment &&
              entry.gradeLevel == GradeLevel.second &&
              entry.numberRange == range,
        )
        .length;

    expect(countFor(NumberRangeLevel.hundred), 1);
    expect(countFor(NumberRangeLevel.twenty), 1);

    controller.numberRange = NumberRangeLevel.hundred;
    await controller.completeAssessment(result, taskResults: [task]);
    expect(countFor(NumberRangeLevel.hundred), 1);
    expect(countFor(NumberRangeLevel.twenty), 1);
  });

  test('Startempfehlung bleibt kindlich kurz', () async {
    final controller = AppController();
    await controller.load();

    expect(
      controller.childRecommendationText(),
      'Starte mit einer kurzen Übungsrunde.',
    );

    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;
    final upperPrimaryText = controller.childRecommendationText();
    expect(upperPrimaryText, startsWith('Als Nächstes passt „'));
    expect(upperPrimaryText, isNot(contains('Lehrplan')));
    expect(upperPrimaryText, isNot(contains('Übungspotenzial')));
    expect(controller.recommendationText(), contains('Lehrplanbereich'));
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

    expect(find.text('Rechenblitz'), findsOneWidget);
    expect(find.text('Start 1 von 2'), findsOneWidget);
    expect(find.text('Kurz einrichten'), findsOneWidget);
    expect(find.text('Name oder Spitzname (optional)'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('learning-start-grade-third')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('learning-start-next')));
    await tester.pumpAndSettle();
    expect(find.text('So rechnen wir in der Schule'), findsNothing);
    expect(find.text('Start 2 von 2'), findsOneWidget);
    expect(find.text('Ein kurzer Lerncheck'), findsOneWidget);
    expect(
      find.text(
        '12 Aufgaben ohne Zeitdruck. So findet Rechenblitz einen guten Startpunkt.',
      ),
      findsOneWidget,
    );
    expect(find.text('Kein Zeitdruck'), findsOneWidget);
    expect(find.text('Keine Note'), findsOneWidget);
    expect(find.text('Ohne Lerncheck starten'), findsOneWidget);

    final later =
        find.byKey(const ValueKey('learning-start-assessment-later'));
    await tester.scrollUntilVisible(
      later,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(later);
    await tester.pumpAndSettle();

    expect(controller.needsOnboarding, isFalse);
    expect(controller.gradeLevel, GradeLevel.third);
    expect(
      controller.methodPreferences.selectionPreference,
      MethodSelectionPreference.automatic,
    );
    expect(find.text('Rechenblitz'), findsWidgets);
    expect(find.text('Deine Runde'), findsOneWidget);
  });

  testWidgets('Lerncheck hält Aufgaben und Ergebnis kindlich knapp', (tester) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;

    await tester.pumpWidget(
      MaterialApp(home: AssessmentScreen(controller: controller)),
    );

    expect(find.text('Lerncheck'), findsOneWidget);
    expect(find.text('Aufgabe 1 von 12'), findsOneWidget);
    expect(find.text('Ohne Zeitdruck · ohne Note'), findsOneWidget);

    for (var task = 0; task < 12; task += 1) {
      final dontKnow = find.byKey(const ValueKey('assessment-dont-know'));
      await tester.scrollUntilVisible(
        dontKnow,
        180,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pump();
      await tester.tap(dontKnow);
      await tester.pumpAndSettle();
    }

    expect(find.text('Lerncheck geschafft!'), findsOneWidget);
    expect(find.text('Als Nächstes'), findsOneWidget);
    expect(
      find.text('Damit starten wir in deiner ersten Runde.'),
      findsOneWidget,
    );
    expect(find.textContaining('% im Lerncheck'), findsNothing);
    expect(
      find.byKey(const ValueKey('assessment-start-my-round')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('assessment-next-focus')), findsOneWidget);
    expect(controller.currentMicroFocus(), isNotNull);
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
