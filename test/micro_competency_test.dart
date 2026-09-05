import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/structured_exercise.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/structured_training_screen.dart';
import 'package:rechenblitz/services/adaptive_engine.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Minus über den Zehner trägt Haupt- und Unterstützungsziel', () {
    final fact = MathFact(
      a: 13,
      b: 5,
      operation: MathOperation.minus,
    );

    final tags = MicroCompetencyCatalog.tagsForTask(
      mode: TrainingMode.minus,
      taskKey: fact.key,
      fact: fact,
    );

    expect(tags.first.id, MicroCompetencyId.subtractionTenBridge);
    expect(
      tags.any((tag) => tag.id == MicroCompetencyId.numberDecomposition),
      isTrue,
    );
  });

  test('schriftliches Verfahren trennt Entbündeln von reiner Ausrichtung', () {
    final withBorrow = MicroCompetencyCatalog.tagsForTask(
      mode: TrainingMode.writtenAddSub,
      taskKey: 'written:-:402:187',
    );
    final withoutBorrow = MicroCompetencyCatalog.tagsForTask(
      mode: TrainingMode.writtenAddSub,
      taskKey: 'written:-:432:111',
    );

    expect(
      withBorrow.first.id,
      MicroCompetencyId.writtenRegrouping,
    );
    expect(
      withoutBorrow.map((tag) => tag.id),
      [MicroCompetencyId.writtenAlignment],
    );
  });

  test('erfolgreiche Hilfsantwort zählt weniger Evidenz als freie Antwort',
      () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;

    final fact = MathFact(
      a: 13,
      b: 5,
      operation: MathOperation.minus,
    );

    await controller.recordDiagnosticAttempt(
      mode: TrainingMode.minus,
      taskKey: fact.key,
      expected: 8,
      actual: 8,
      fact: fact,
      usedHelp: true,
    );

    final aided = controller.microObservations.firstWhere(
      (entry) => entry.id == MicroCompetencyId.subtractionTenBridge,
    );
    expect(aided.evidenceWeight, closeTo(0.80, 0.001));
  });

  test('unsichere Voraussetzung wird vor höherem Teilschritt fokussiert', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = [
      MicroCompetencyObservation(
        id: MicroCompetencyId.subtractionTenBridge,
        occurredAt: DateTime(2026, 9, 5, 10),
        correct: false,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        mode: TrainingMode.minus,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'minus:13:5',
      ),
      MicroCompetencyObservation(
        id: MicroCompetencyId.numberDecomposition,
        occurredAt: DateTime(2026, 9, 5, 10),
        correct: false,
        evidenceWeight: 0.45,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        mode: TrainingMode.minus,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'minus:13:5',
      ),
    ];

    expect(
      controller.currentMicroFocus()!.definition.id,
      MicroCompetencyId.numberDecomposition,
    );
  });

  test('Meine Runde übernimmt den erkannten Mikro-Fokus', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = List.generate(
      3,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.subtractionTenBridge,
        occurredAt: DateTime(2026, 9, 5, 10, index),
        correct: false,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        mode: TrainingMode.minus,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'minus:${13 + index}:5',
      ),
    );

    final plan = controller.buildMyRound();

    expect(plan, hasLength(4));
    expect(plan.fold<int>(0, (sum, segment) => sum + segment.tasks), 12);
    expect(
      plan.any(
        (segment) =>
            segment.targetCompetency ==
            MicroCompetencyId.subtractionTenBridge,
      ),
      isTrue,
    );
  });

  test('adaptive Grundaufgaben können gezielt Zehnerübergang erzeugen', () {
    final engine = AdaptiveEngine(random: Random(44));
    final facts = AdaptiveEngine.buildFactPool(maxValue: 100);

    for (var i = 0; i < 20; i++) {
      final fact = engine.selectNext(
        facts: facts,
        mode: TrainingMode.practice,
        maxValue: 100,
        targetCompetency: MicroCompetencyId.additionTenBridge,
      );
      final tags = MicroCompetencyCatalog.tagsForTask(
        mode: TrainingMode.practice,
        taskKey: fact.key,
        fact: fact,
      );
      expect(
        tags.any(
          (tag) => tag.id == MicroCompetencyId.additionTenBridge,
        ),
        isTrue,
      );
    }
  });

  test('strukturierte und Klasse-3/4-Generatoren treffen Mikro-Ziel', () {
    final structured = StructuredExerciseGenerator(random: Random(11));
    final story = structured.generate(
      mode: TrainingMode.wordProblems,
      maxValue: 100,
      targetCompetency: MicroCompetencyId.wordProblemOperation,
    );
    expect(story.key, startsWith('story:'));

    final curriculum = CurriculumExerciseGenerator(random: Random(12));
    final area = curriculum.generate(
      mode: TrainingMode.perimeterArea,
      gradeLevel: GradeLevel.fourth,
      maxValue: 1000000,
      targetCompetency: MicroCompetencyId.area,
    );
    expect(area.key, contains(':area:'));
  });

  test('Mikro-Beobachtungen bleiben nach Neustart lokal erhalten', () async {
    final controller = AppController();
    await controller.load();

    await controller.recordDiagnosticAttempt(
      mode: TrainingMode.minus,
      taskKey: 'minus:13:5',
      expected: 8,
      actual: 9,
      fact: MathFact(
        a: 13,
        b: 5,
        operation: MathOperation.minus,
      ),
    );

    final reloaded = AppController();
    await reloaded.load();

    expect(reloaded.microObservations, isNotEmpty);
    expect(
      reloaded.microObservations.first.id,
      MicroCompetencyId.subtractionTenBridge,
    );
  });
  test('Gemeistert verlangt selbstständig, Abstand und Transfer', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = List.generate(
      6,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.additionTenBridge,
        occurredAt: DateTime(2026, 9, 1, 12, index),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        mode: TrainingMode.practice,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'plus:47:${3 + index}',
      ),
    );

    final base =
        controller.microCompetencyProgress(MicroCompetencyId.additionTenBridge);
    expect(base.state, MicroCompetencyState.secure);
    expect(base.independentEvidence, closeTo(6, 0.001));
    expect(base.independentAccuracy, closeTo(1, 0.001));
    expect(base.reviewEvidence, 0);
    expect(base.transferEvidence, 0);

    controller.microObservations.insertAll(
      0,
      List.generate(
        2,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.additionTenBridge,
          occurredAt: DateTime(2026, 9, 2, 13, index),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.transfer,
          usedHelp: false,
          mode: TrainingMode.wordProblems,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey:
              'story:transfer:skill:additionTenBridge:+:books:47:${3 + index}',
        ),
      ),
    );

    final withoutReview =
        controller.microCompetencyProgress(MicroCompetencyId.additionTenBridge);
    expect(withoutReview.state, MicroCompetencyState.secure);
    expect(withoutReview.transferIndependentEvidence, closeTo(2, 0.001));

    controller.microObservations.insertAll(
      0,
      List.generate(
        2,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.additionTenBridge,
          occurredAt: DateTime(2026, 9, 4, 13, index),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.review,
          usedHelp: false,
          mode: TrainingMode.practice,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'review:plus:47:${3 + index}',
        ),
      ),
    );

    final mastered =
        controller.microCompetencyProgress(MicroCompetencyId.additionTenBridge);
    expect(mastered.state, MicroCompetencyState.mastered);
    expect(mastered.reviewIndependentEvidence, closeTo(2, 0.001));
    expect(mastered.reviewIndependentAccuracy, closeTo(1, 0.001));
    expect(mastered.transferIndependentEvidence, closeTo(2, 0.001));
    expect(mastered.transferIndependentAccuracy, closeTo(1, 0.001));
  });

  test('Hilfe zählt sichtbar, erzeugt aber keine selbstständige Sicherheit', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = List.generate(
      8,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.subtractionTenBridge,
        occurredAt: DateTime(2026, 9, 1, 12, index),
        correct: true,
        evidenceWeight: 0.8,
        source: MicroEvidenceSource.practice,
        usedHelp: true,
        helpLevel: 1,
        mode: TrainingMode.minus,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'minus:43:18:$index',
      ),
    );

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.subtractionTenBridge,
    );

    expect(progress.aidedObservations, 8);
    expect(progress.aidedEvidence, greaterThan(0));
    expect(progress.independentEvidence, 0);
    expect(progress.state, MicroCompetencyState.practicing);
  });

  test('Abstandskontrolle wird erst nach zwei Tagen fällig', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = List.generate(
      6,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.subtractionTenBridge,
        occurredAt: DateTime(2026, 9, 1, 10, index),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        mode: TrainingMode.minus,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'minus:${30 + index}:8',
      ),
    );

    expect(
      controller.dueReviewMicroCompetency(
        now: DateTime(2026, 9, 2, 10),
      ),
      isNull,
    );
    final due = controller.dueReviewMicroCompetency(
      now: DateTime(2026, 9, 3, 10),
    );
    expect(due, isNotNull);
    expect(due!.definition.id, MicroCompetencyId.subtractionTenBridge);

    final plan = controller.buildMyRound(
      now: DateTime(2026, 9, 3, 10),
    );
    expect(plan[2].reviewEmphasis, isTrue);
    expect(
      plan[2].targetCompetency,
      MicroCompetencyId.subtractionTenBridge,
    );
    expect(plan[2].reason, contains('zeitlichem Abstand'));
    expect(
      plan.where((segment) => segment.transferEmphasis).every(
            (segment) =>
                segment.targetCompetency !=
                MicroCompetencyId.subtractionTenBridge,
          ),
      isTrue,
    );
  });

  test('nach erster Abstandskontrolle gilt ein Sieben-Tage-Abstand', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = [
      MicroCompetencyObservation(
        id: MicroCompetencyId.additionNoBridge,
        occurredAt: DateTime(2026, 9, 4, 10),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.review,
        usedHelp: false,
        mode: TrainingMode.practice,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'review:plus:12:7',
      ),
      ...List.generate(
        6,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.additionNoBridge,
          occurredAt: DateTime(2026, 9, 1, 10, index),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.practice,
          usedHelp: false,
          mode: TrainingMode.practice,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'plus:12:${2 + index}',
        ),
      ),
    ];

    expect(
      controller.dueReviewMicroCompetency(
        now: DateTime(2026, 9, 10, 10),
      ),
      isNull,
    );
    expect(
      controller.dueReviewMicroCompetency(
        now: DateTime(2026, 9, 11, 10),
      ),
      isNotNull,
    );
  });

  test('Hilfe im Transfer reicht nicht für Gemeistert', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = [
      ...List.generate(
        2,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.additionTenBridge,
          occurredAt: DateTime(2026, 9, 4, 13, index),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.review,
          usedHelp: false,
          mode: TrainingMode.practice,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'review:plus:47:${3 + index}',
        ),
      ),
      ...List.generate(
        2,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.additionTenBridge,
          occurredAt: DateTime(2026, 9, 3, 13, index),
          correct: true,
          evidenceWeight: 0.8,
          source: MicroEvidenceSource.transfer,
          usedHelp: true,
          helpLevel: 1,
          mode: TrainingMode.wordProblems,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey:
              'story:transfer:skill:additionTenBridge:+:books:47:${3 + index}',
        ),
      ),
      ...List.generate(
        6,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.additionTenBridge,
          occurredAt: DateTime(2026, 9, 1, 12, index),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.practice,
          usedHelp: false,
          mode: TrainingMode.practice,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'plus:47:${3 + index}',
        ),
      ),
    ];

    final progress =
        controller.microCompetencyProgress(MicroCompetencyId.additionTenBridge);

    expect(progress.transferEvidence, greaterThan(0));
    expect(progress.transferIndependentEvidence, 0);
    expect(progress.state, MicroCompetencyState.secure);
  });

  test('unsichere Abstandskontrolle bleibt nach zwei Tagen erneut fällig', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = [
      MicroCompetencyObservation(
        id: MicroCompetencyId.additionNoBridge,
        occurredAt: DateTime(2026, 9, 4, 10),
        correct: false,
        evidenceWeight: 1,
        source: MicroEvidenceSource.review,
        usedHelp: false,
        mode: TrainingMode.practice,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'review:plus:12:7',
      ),
      ...List.generate(
        6,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.additionNoBridge,
          occurredAt: DateTime(2026, 9, 1, 10, index),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.practice,
          usedHelp: false,
          mode: TrainingMode.practice,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'plus:12:${2 + index}',
        ),
      ),
    ];

    expect(
      controller.dueReviewMicroCompetency(
        now: DateTime(2026, 9, 5, 10),
      ),
      isNull,
    );
    expect(
      controller.dueReviewMicroCompetency(
        now: DateTime(2026, 9, 6, 10),
      ),
      isNotNull,
    );
  });

  test('Meine Runde transferiert zuerst eine sichere Kompetenz', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = List.generate(
      6,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.subtractionTenBridge,
        occurredAt: DateTime(2026, 9, 5, 12, index),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        mode: TrainingMode.minus,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'minus:${20 + index}:7',
      ),
    );

    final candidate = controller.transferCandidateMicroCompetency();
    expect(candidate, isNotNull);
    expect(candidate!.definition.id, MicroCompetencyId.subtractionTenBridge);

    final plan = controller.buildMyRound();
    final transfer = plan.last;
    expect(transfer.transferEmphasis, isTrue);
    expect(
      transfer.targetCompetency,
      MicroCompetencyId.subtractionTenBridge,
    );
    expect(transfer.mode, TrainingMode.wordProblems);
    expect(transfer.reason, contains('veränderten Aufgabe'));
    expect(
      plan.take(3).every(
            (segment) =>
                segment.targetCompetency !=
                MicroCompetencyId.subtractionTenBridge,
          ),
      isTrue,
      reason: 'Das Transferziel soll in derselben Runde nicht vorgeübt werden.',
    );
  });

  test('ohne sichere Kompetenz bleibt der Abschluss Entdeckung statt Transfer',
      () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;

    final plan = controller.buildMyRound();

    expect(plan.last.transferEmphasis, isFalse);
  });

  test('Transfer-Evidenz bleibt lokal über Neustart erhalten', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;

    await controller.recordDiagnosticAttempt(
      mode: TrainingMode.wordProblems,
      taskKey:
          'story:transfer:skill:additionTenBridge:+:books:47:38',
      expected: 85,
      actual: 85,
      source: MicroEvidenceSource.transfer,
    );

    final reloaded = AppController();
    await reloaded.load();
    final observation = reloaded.microObservations.firstWhere(
      (entry) => entry.id == MicroCompetencyId.additionTenBridge,
    );
    expect(observation.source, MicroEvidenceSource.transfer);
  });


  test('Abstandsevidenz bleibt lokal über Neustart erhalten', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;

    await controller.recordDiagnosticAttempt(
      mode: TrainingMode.practice,
      taskKey: 'plus:12:7',
      expected: 19,
      actual: 19,
      source: MicroEvidenceSource.review,
    );

    final reloaded = AppController();
    await reloaded.load();
    expect(reloaded.microObservations.first.source, MicroEvidenceSource.review);
  });

  test('alte Mikro-Daten ohne Evidenzquelle bleiben normale Übung', () {
    final observation = MicroCompetencyObservation.fromJson({
      'id': MicroCompetencyId.additionNoBridge.name,
      'occurredAt': '2026-09-05T12:00:00.000',
      'correct': true,
      'evidenceWeight': 1.0,
      'usedHelp': false,
      'mode': TrainingMode.practice.name,
      'gradeLevel': GradeLevel.second.name,
      'numberRange': NumberRangeLevel.hundred.name,
      'taskKey': 'plus:12:7',
    });

    expect(observation.source, MicroEvidenceSource.practice);
  });

  testWidgets('Transfer-Runde speichert aus der Oberfläche Transfer-Evidenz',
      (tester) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.ten;

    await tester.pumpWidget(
      MaterialApp(
        home: StructuredTrainingScreen(
          controller: controller,
          mode: TrainingMode.wordProblems,
          targetTasks: 2,
          targetCompetency: MicroCompetencyId.additionTenBridge,
          transferEmphasis: true,
        ),
      ),
    );
    await tester.pump();

    final answerButton = find.widgetWithText(FilledButton, '10');
    expect(answerButton, findsOneWidget);
    await tester.ensureVisible(answerButton);
    await tester.pump();
    await tester.tap(answerButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final observation = controller.microObservations.firstWhere(
      (entry) => entry.id == MicroCompetencyId.additionTenBridge,
    );
    expect(observation.source, MicroEvidenceSource.transfer);
    expect(
      observation.taskKey,
      startsWith('story:transfer:skill:additionTenBridge:'),
    );
  });

}
