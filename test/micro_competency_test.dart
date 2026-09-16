import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/accessibility_preferences.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/guided_method.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/structured_exercise.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/structured_training_screen.dart';
import 'package:rechenblitz/services/adaptive_engine.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void _secureMicro(
  AppController controller,
  MicroCompetencyId id, {
  GradeLevel grade = GradeLevel.second,
  NumberRangeLevel range = NumberRangeLevel.hundred,
  DateTime? start,
  bool withTransferEvidence = false,
}) {
  final definition = MicroCompetencyCatalog.definition(id);
  final base = start ?? DateTime(2026, 9, 1, 8);
  controller.microObservations.addAll(
    List.generate(
      6,
      (index) => MicroCompetencyObservation(
        id: id,
        occurredAt: base.add(Duration(minutes: index)),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        mode: definition.preferredMode,
        gradeLevel: grade,
        numberRange: range,
        taskKey: 'secure-${id.name}:$index',
      ),
    ),
  );
  if (withTransferEvidence) {
    controller.microObservations.add(
      MicroCompetencyObservation(
        id: id,
        occurredAt: base.add(const Duration(hours: 1)),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.transfer,
        usedHelp: false,
        mode: definition.preferredMode,
        gradeLevel: grade,
        numberRange: range,
        taskKey: 'secure-transfer-${id.name}',
      ),
    );
  }
}

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

  test('voller Zehner ist kein künstlicher Minus-Zehnerübergang', () {
    final fact = MathFact(
      a: 10,
      b: 6,
      operation: MathOperation.minus,
    );

    final tags = MicroCompetencyCatalog.tagsForTask(
      mode: TrainingMode.minus,
      taskKey: fact.key,
      fact: fact,
    );

    expect(needsSubtractionTenBridge(10, 6), isFalse);
    expect(tags.first.id, MicroCompetencyId.subtractionNoBridge);
    expect(
      tags.any((tag) => tag.id == MicroCompetencyId.numberDecomposition),
      isFalse,
    );
  });

  test('Minus-Zehnerübergang ist im Zahlenraum bis 10 kein Lernziel', () {
    final ids = MicroCompetencyCatalog.forContext(
      GradeLevel.first,
      NumberRangeLevel.ten,
    ).map((definition) => definition.id);

    expect(ids, isNot(contains(MicroCompetencyId.subtractionTenBridge)));
    expect(ids, contains(MicroCompetencyId.subtractionNoBridge));
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
    _secureMicro(controller, MicroCompetencyId.numberDecomposition);
    _secureMicro(controller, MicroCompetencyId.subtractionNoBridge);

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

  test('exakte Zehnerergänzung ist kein Plus über den Zehner', () {
    final fact = MathFact(a: 17, b: 3, operation: MathOperation.plus);
    final tags = MicroCompetencyCatalog.tagsForTask(
      mode: TrainingMode.practice,
      taskKey: fact.key,
      fact: fact,
    );

    expect(needsAdditionTenBridge(17, 3), isFalse);
    expect(tags.first.id, MicroCompetencyId.additionNoBridge);
    expect(
      tags.any((tag) => tag.id == MicroCompetencyId.additionTenBridge),
      isFalse,
    );
    expect(needsAdditionTenBridge(17, 4), isTrue);
    expect(needsAdditionTenBridge(47, 13), isTrue);
  });

  test('Plus-Zehnerübergang ist im Zahlenraum bis 10 kein Lernziel', () {
    final ten = MicroCompetencyCatalog.forContext(
      GradeLevel.first,
      NumberRangeLevel.ten,
    );
    final twenty = MicroCompetencyCatalog.forContext(
      GradeLevel.first,
      NumberRangeLevel.twenty,
    );

    expect(
      ten.any((item) => item.id == MicroCompetencyId.additionTenBridge),
      isFalse,
    );
    expect(
      twenty.any((item) => item.id == MicroCompetencyId.additionTenBridge),
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
      expect(needsAdditionTenBridge(fact.a, fact.b), isTrue);
      final nextTen = ((fact.a ~/ 10) + 1) * 10;
      expect(fact.result, isNot(nextTen));
    }
  });

  test('gezieltes Minus über den Zehner wählt keinen vollen Startzehner', () {
    final engine = AdaptiveEngine(random: Random(45));
    final facts = AdaptiveEngine.buildFactPool(maxValue: 100);

    for (var i = 0; i < 40; i++) {
      final fact = engine.selectNext(
        facts: facts,
        mode: TrainingMode.minus,
        maxValue: 100,
        targetCompetency: MicroCompetencyId.subtractionTenBridge,
      );
      expect(needsSubtractionTenBridge(fact.a, fact.b), isTrue);
      expect(fact.a % 10, isNot(0));
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
    _secureMicro(
      controller,
      MicroCompetencyId.numberDecomposition,
      start: DateTime(2026, 9, 2, 11),
    );
    _secureMicro(
      controller,
      MicroCompetencyId.subtractionNoBridge,
      start: DateTime(2026, 9, 2, 12),
    );

    expect(
      controller.dueReviewMicroCompetency(
        now: DateTime(2026, 9, 2, 10),
      ),
      isNull,
    );
    final due = controller.dueReviewMicroCompetency(
      now: DateTime(2026, 9, 3, 10, 5),
    );
    expect(due, isNotNull);
    expect(due!.definition.id, MicroCompetencyId.subtractionTenBridge);

    final plan = controller.buildMyRound(
      now: DateTime(2026, 9, 3, 10, 5),
    );
    expect(plan[2].reviewEmphasis, isTrue);
    expect(
      plan[2].targetCompetency,
      MicroCompetencyId.subtractionTenBridge,
    );
    expect(plan[2].reason, contains('zeitlichem Abstand'));
    expect(
      [
        plan[0],
        plan[1],
        plan[3],
      ].every(
        (segment) =>
            segment.targetCompetency !=
            MicroCompetencyId.subtractionTenBridge,
      ),
      isTrue,
      reason:
          'Das Abstandsziel darf in derselben Runde nicht vorgeübt werden.',
    );
  });

  test('nach erster Abstandskontrolle gilt ein Sieben-Tage-Abstand', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = [
      ...List.generate(
        2,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.additionNoBridge,
          occurredAt: DateTime(2026, 9, 4, 10, index),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.review,
          usedHelp: false,
          mode: TrainingMode.practice,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'review:plus:12:${7 + index}',
        ),
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
        now: DateTime(2026, 9, 11, 10, 1),
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

  test('unsichere Abstandskontrolle wird nach einem Tag erneut fällig', () {
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
        now: DateTime(2026, 9, 5, 9, 59),
      ),
      isNull,
    );
    expect(
      controller.dueReviewMicroCompetency(
        now: DateTime(2026, 9, 5, 10),
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
    _secureMicro(
      controller,
      MicroCompetencyId.numberDecomposition,
      start: DateTime(2026, 9, 5, 10),
      withTransferEvidence: true,
    );
    _secureMicro(
      controller,
      MicroCompetencyId.subtractionNoBridge,
      start: DateTime(2026, 9, 5, 11),
      withTransferEvidence: true,
    );

    final candidate = controller.transferCandidateMicroCompetency();
    expect(candidate, isNotNull);
    expect(candidate!.definition.id, MicroCompetencyId.subtractionTenBridge);

    final plan = controller.buildMyRound(
      now: DateTime(2026, 9, 6, 12),
    );
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

    final fact = MathFact(
      a: 12,
      b: 7,
      operation: MathOperation.plus,
    );
    await controller.recordDiagnosticAttempt(
      mode: TrainingMode.practice,
      taskKey: fact.key,
      expected: 19,
      actual: 19,
      fact: fact,
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
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.twenty;

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

    final zeroButton = find.widgetWithText(FilledButton, '0');
    expect(zeroButton, findsOneWidget);
    await tester.ensureVisible(zeroButton);
    await tester.tap(zeroButton);
    await tester.pump();
    final okButton = find.widgetWithText(FilledButton, 'OK');
    expect(okButton, findsOneWidget);
    await tester.ensureVisible(okButton);
    await tester.tap(okButton);
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

  test('Geführte Zwischenschritte erzeugen keine selbstständige Mastery', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;

    for (var i = 0; i < 8; i++) {
      await controller.recordGuidedStepAttempt(
        mode: TrainingMode.minus,
        taskKey: 'minus:13:5',
        methodKey: 'subtraction:bridgeToTen',
        stepKey: 'bridgeAmount',
        competencyId: MicroCompetencyId.subtractionTenBridge,
        correct: true,
      );
    }

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.subtractionTenBridge,
    );

    expect(progress.observations, 8);
    expect(progress.aidedObservations, 8);
    expect(progress.aidedEvidence, greaterThan(0));
    expect(progress.independentEvidence, 0);
    expect(progress.reviewIndependentEvidence, 0);
    expect(progress.transferIndependentEvidence, 0);
    expect(progress.state, MicroCompetencyState.practicing);
  });

  test('Geführte Zwischritt-Evidenz bleibt lokal und eindeutig markiert',
      () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;

    await controller.recordGuidedStepAttempt(
      mode: TrainingMode.minus,
      taskKey: 'minus:13:5',
      methodKey: 'subtraction:bridgeToTen',
      stepKey: 'remainingSubtrahend',
      competencyId: MicroCompetencyId.numberDecomposition,
      correct: false,
      evidenceWeight: 0.35,
    );

    final reloaded = AppController();
    await reloaded.load();
    final observation = reloaded.microObservations.firstWhere(
      (entry) => entry.source == MicroEvidenceSource.guidedStep,
    );

    expect(observation.id, MicroCompetencyId.numberDecomposition);
    expect(observation.correct, isFalse);
    expect(observation.usedHelp, isTrue);
    expect(observation.helpLevel, HelpLevel.guided.value);
    expect(observation.evidenceWeight, closeTo(0.35, 0.001));
    expect(
      observation.taskKey,
      contains('guided:subtraction:bridgeToTen:remainingSubtrahend'),
    );
  });

  test('Viele geführte Schritte verdrängen selbstständige Mastery-Evidenz nicht',
      () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = [
      ...List.generate(
        30,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.subtractionTenBridge,
          occurredAt: DateTime(2026, 9, 5, 12, index),
          correct: index.isEven,
          evidenceWeight: 0.35,
          source: MicroEvidenceSource.guidedStep,
          usedHelp: true,
          helpLevel: HelpLevel.guided.value,
          methodKey: 'subtraction:bridgeToTen',
          mode: TrainingMode.minus,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'guided:subtraction:bridgeToTen:bridgeAmount:$index',
        ),
      ),
      ...List.generate(
        6,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.subtractionTenBridge,
          occurredAt: DateTime(2026, 9, 4, 12, index),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.practice,
          usedHelp: false,
          mode: TrainingMode.minus,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'minus:${20 + index}:7',
        ),
      ),
    ];

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.subtractionTenBridge,
    );

    expect(progress.independentEvidence, closeTo(6, 0.001));
    expect(progress.independentAccuracy, closeTo(1, 0.001));
    expect(progress.aidedObservations, 12);
    expect(progress.state, MicroCompetencyState.secure);
  });


  test('korrekte geführte Schritte erzeugen keinen falschen Mikro-Fokus', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = List.generate(
      6,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.numberDecomposition,
        occurredAt: DateTime(2026, 9, 5, 12, index),
        correct: true,
        evidenceWeight: 0.35,
        source: MicroEvidenceSource.guidedStep,
        usedHelp: true,
        helpLevel: HelpLevel.guided.value,
        methodKey: 'subtraction:bridgeToTen',
        mode: TrainingMode.minus,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey:
            'guided:subtraction:bridgeToTen:remainingSubtrahend:minus:13:5:$index',
      ),
    );

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.numberDecomposition,
    );

    expect(progress.guidedStepObservations, 6);
    expect(progress.guidedStepAccuracy, closeTo(1, 0.001));
    expect(progress.independentEvidence, 0);
    expect(controller.guidedStepFocus(), isNull);
    expect(controller.currentMicroFocus(), isNull);
    expect(controller.strongestMicroCompetency(), isNull);
  });

  test('wiederholt falscher geführter Zwischenschritt steuert auf Voraussetzung',
      () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = [
      ...List.generate(
        3,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.subtractionTenBridge,
          occurredAt: DateTime(2026, 9, 5, 12, 10 + index),
          correct: false,
          evidenceWeight: 1,
          source: MicroEvidenceSource.practice,
          usedHelp: false,
          mode: TrainingMode.minus,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'minus:13:5:$index',
        ),
      ),
      ...List.generate(
        3,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.numberDecomposition,
          occurredAt: DateTime(2026, 9, 5, 12, index),
          correct: index == 2,
          evidenceWeight: 0.35,
          source: MicroEvidenceSource.guidedStep,
          usedHelp: true,
          helpLevel: HelpLevel.guided.value,
          methodKey: 'subtraction:bridgeToTen',
          mode: TrainingMode.minus,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey:
              'guided:subtraction:bridgeToTen:remainingSubtrahend:minus:13:5:$index',
        ),
      ),
    ];

    final guided = controller.guidedStepFocus();
    expect(guided, isNotNull);
    expect(guided!.competencyId, MicroCompetencyId.numberDecomposition);
    expect(guided.stepKey, 'remainingSubtrahend');
    expect(guided.label, contains('Subtrahenden'));
    expect(guided.incorrectFirstAttempts, 2);
    expect(guided.accuracy, closeTo(1 / 3, 0.001));

    final focus = controller.currentMicroFocus();
    expect(focus, isNotNull);
    expect(focus!.definition.id, MicroCompetencyId.numberDecomposition);

    final plan = controller.buildMyRound();
    expect(plan[1].targetCompetency, MicroCompetencyId.numberDecomposition);
    expect(plan[1].reason, contains('verbleibenden Teil des Subtrahenden'));
  });

  test('erholte geführte Teilfrage löst keinen guidedStep-Fokus mehr aus', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    final outcomes = [true, true, true, false, false];
    controller.microObservations = List.generate(
      outcomes.length,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.numberDecomposition,
        occurredAt: DateTime(2026, 9, 5, 12, index),
        correct: outcomes[index],
        evidenceWeight: 0.35,
        source: MicroEvidenceSource.guidedStep,
        usedHelp: true,
        helpLevel: HelpLevel.guided.value,
        methodKey: 'subtraction:bridgeToTen',
        mode: TrainingMode.minus,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey:
            'guided:subtraction:bridgeToTen:remainingSubtrahend:minus:13:5:$index',
      ),
    );

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.numberDecomposition,
    );
    expect(progress.guidedStepAccuracy, closeTo(0.60, 0.001));
    expect(controller.guidedStepFocus(), isNull);
    expect(controller.currentMicroFocus(), isNull);
  });

  test('reguläre Aufgaben mit Hilfe bleiben als Mikro-Fokus relevant', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = List.generate(
      4,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.additionNoBridge,
        occurredAt: DateTime(2026, 9, 5, 12, index),
        correct: true,
        evidenceWeight: 0.8,
        source: MicroEvidenceSource.practice,
        usedHelp: true,
        helpLevel: 1,
        mode: TrainingMode.practice,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'plus:12:7:$index',
      ),
    );

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.additionNoBridge,
    );
    expect(progress.baseEvidence, greaterThan(0));
    expect(progress.independentEvidence, 0);
    expect(controller.guidedStepFocus(), isNull);
    expect(
      controller.currentMicroFocus()!.definition.id,
      MicroCompetencyId.additionNoBridge,
    );
  });


  test('guidedStep stuft sichere Kompetenz nicht zurück', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = [
      ...List.generate(
        3,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.numberDecomposition,
          occurredAt: DateTime(2026, 9, 5, 13, index),
          correct: false,
          evidenceWeight: 0.35,
          source: MicroEvidenceSource.guidedStep,
          usedHelp: true,
          helpLevel: HelpLevel.guided.value,
          methodKey: 'subtraction:bridgeToTen',
          mode: TrainingMode.minus,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey:
              'guided:subtraction:bridgeToTen:remainingSubtrahend:minus:13:5:$index',
        ),
      ),
      ...List.generate(
        6,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.numberDecomposition,
          occurredAt: DateTime(2026, 9, 4, 12, index),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.practice,
          usedHelp: false,
          mode: TrainingMode.numberFriends,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'friends:10:$index',
        ),
      ),
    ];

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.numberDecomposition,
    );

    expect(progress.state, MicroCompetencyState.secure);
    expect(progress.guidedStepAccuracy, 0);
    expect(controller.guidedStepFocus(), isNull);
    expect(controller.currentMicroFocus(), isNull);
  });


  test('zwei selbstständige Bestätigungen lösen altes guidedStep-Signal ab',
      () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = [
      MicroCompetencyObservation(
        id: MicroCompetencyId.numberDecomposition,
        occurredAt: DateTime(2026, 9, 5, 11, 1),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        mode: TrainingMode.numberFriends,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'friends:10:6',
      ),
      MicroCompetencyObservation(
        id: MicroCompetencyId.numberDecomposition,
        occurredAt: DateTime(2026, 9, 5, 11),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        mode: TrainingMode.numberFriends,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'friends:10:4',
      ),
      ...List.generate(
        3,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.numberDecomposition,
          occurredAt: DateTime(2026, 9, 5, 10, index),
          correct: index == 2,
          evidenceWeight: 0.35,
          source: MicroEvidenceSource.guidedStep,
          usedHelp: true,
          helpLevel: HelpLevel.guided.value,
          methodKey: 'subtraction:bridgeToTen',
          mode: TrainingMode.minus,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey:
              'guided:subtraction:bridgeToTen:remainingSubtrahend:minus:13:5:$index',
        ),
      ),
    ];

    expect(controller.guidedStepFocus(), isNull);
    final plan = controller.buildMyRound();
    expect(plan[1].targetCompetency, MicroCompetencyId.numberDecomposition);
    expect(plan[1].scaffoldFading, isFalse);
  });

  test('aktueller selbstständiger Fehler hält guidedStep-Fading aktiv', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = [
      MicroCompetencyObservation(
        id: MicroCompetencyId.numberDecomposition,
        occurredAt: DateTime(2026, 9, 5, 11, 2),
        correct: false,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        mode: TrainingMode.numberFriends,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'friends:10:7',
      ),
      MicroCompetencyObservation(
        id: MicroCompetencyId.numberDecomposition,
        occurredAt: DateTime(2026, 9, 5, 11, 1),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        mode: TrainingMode.numberFriends,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'friends:10:6',
      ),
      MicroCompetencyObservation(
        id: MicroCompetencyId.numberDecomposition,
        occurredAt: DateTime(2026, 9, 5, 11),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        mode: TrainingMode.numberFriends,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'friends:10:4',
      ),
      ...List.generate(
        3,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.numberDecomposition,
          occurredAt: DateTime(2026, 9, 5, 10, index),
          correct: index == 2,
          evidenceWeight: 0.35,
          source: MicroEvidenceSource.guidedStep,
          usedHelp: true,
          helpLevel: HelpLevel.guided.value,
          methodKey: 'subtraction:bridgeToTen',
          mode: TrainingMode.minus,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey:
              'guided:subtraction:bridgeToTen:remainingSubtrahend:minus:13:5:$index',
        ),
      ),
    ];

    final guided = controller.guidedStepFocus();
    expect(guided, isNotNull);
    expect(guided!.stepKey, 'remainingSubtrahend');

    final plan = controller.buildMyRound();
    expect(plan[1].targetCompetency, MicroCompetencyId.numberDecomposition);
    expect(plan[1].scaffoldFading, isTrue);
    expect(plan[1].reason, contains('schrittweise zurück'));
  });


  test('Eigenständige Teilfragen zählen geringer, aber selbstständig', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;

    for (var i = 0; i < 10; i++) {
      await controller.recordIndependentStepAttempt(
        mode: TrainingMode.wordProblems,
        taskKey: 'process:representation:groups:3:4:$i',
        stepKey: 'groupCount',
        competencyId: MicroCompetencyId.multiplicationGroups,
        correct: true,
        usedHelp: false,
        helpLevel: 0,
        evidenceWeight: 0.40,
      );
    }

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.multiplicationGroups,
    );

    expect(progress.independentStepObservations, 10);
    expect(progress.independentStepAccuracy, closeTo(1, 0.001));
    expect(progress.independentStepEvidence, closeTo(4, 0.001));
    expect(progress.independentEvidence, closeTo(4, 0.001));
    expect(progress.aidedObservations, 0);
    expect(progress.state, MicroCompetencyState.secure);
  });

  test('Teilfrage nach geöffneter Hilfe ist keine selbstständige Evidenz',
      () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;

    for (var i = 0; i < 6; i++) {
      await controller.recordIndependentStepAttempt(
        mode: TrainingMode.wordProblems,
        taskKey: 'process:representation:place:47:$i',
        stepKey: 'placeDigit:tens',
        competencyId: MicroCompetencyId.placeValueDigits,
        correct: true,
        usedHelp: true,
        helpLevel: HelpLevel.visual.value,
        methodKey: 'representation:placeValue',
        evidenceWeight: 0.40,
      );
    }

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.placeValueDigits,
    );

    expect(progress.independentStepObservations, 6);
    expect(progress.independentStepEvidence, greaterThan(0));
    expect(progress.independentEvidence, 0);
    expect(progress.aidedObservations, 6);
    expect(progress.state, isNot(MicroCompetencyState.secure));
  });

  test('Eigenständige Teilfragen bleiben lokal eindeutig markiert', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;

    await controller.recordIndependentStepAttempt(
      mode: TrainingMode.wordProblems,
      taskKey: 'process:representation:groups:3:4',
      stepKey: 'itemsPerGroup',
      competencyId: MicroCompetencyId.multiplicationGroups,
      correct: false,
      usedHelp: false,
      helpLevel: 0,
      evidenceWeight: 0.30,
    );

    final reloaded = AppController();
    await reloaded.load();
    final observation = reloaded.microObservations.firstWhere(
      (entry) => entry.source == MicroEvidenceSource.independentStep,
    );

    expect(observation.id, MicroCompetencyId.multiplicationGroups);
    expect(observation.correct, isFalse);
    expect(observation.usedHelp, isFalse);
    expect(observation.evidenceWeight, closeTo(0.30, 0.001));
    expect(
      observation.taskKey,
      startsWith('independent:itemsPerGroup:process:representation:'),
    );
  });

  test('Zwei eigenständige Teilfragen können altes guidedStep-Signal ablösen',
      () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = [
      MicroCompetencyObservation(
        id: MicroCompetencyId.multiplicationGroups,
        occurredAt: DateTime(2026, 9, 5, 11, 1),
        correct: true,
        evidenceWeight: 0.30,
        source: MicroEvidenceSource.independentStep,
        usedHelp: false,
        mode: TrainingMode.wordProblems,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey:
            'independent:groupCount:process:representation:groups:4:3',
      ),
      MicroCompetencyObservation(
        id: MicroCompetencyId.multiplicationGroups,
        occurredAt: DateTime(2026, 9, 5, 11),
        correct: true,
        evidenceWeight: 0.30,
        source: MicroEvidenceSource.independentStep,
        usedHelp: false,
        mode: TrainingMode.wordProblems,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey:
            'independent:groupCount:process:representation:groups:3:4',
      ),
      ...List.generate(
        3,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.multiplicationGroups,
          occurredAt: DateTime(2026, 9, 5, 10, index),
          correct: index == 2,
          evidenceWeight: 0.35,
          source: MicroEvidenceSource.guidedStep,
          usedHelp: true,
          helpLevel: HelpLevel.guided.value,
          methodKey: 'representation:equalGroups',
          mode: TrainingMode.wordProblems,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey:
              'guided:representation:equalGroups:groupCount:process:representation:groups:3:4:$index',
        ),
      ),
    ];

    expect(controller.guidedStepFocus(), isNull);
  });

  test('Anderer eigenständiger Teilsschritt löscht guidedStep-Signal nicht',
      () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = [
      ...List.generate(
        2,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.multiplicationGroups,
          occurredAt: DateTime(2026, 9, 5, 11, index),
          correct: true,
          evidenceWeight: 0.30,
          source: MicroEvidenceSource.independentStep,
          usedHelp: false,
          mode: TrainingMode.wordProblems,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey:
              'independent:itemsPerGroup:process:representation:groups:${3 + index}:4',
        ),
      ),
      ...List.generate(
        3,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.multiplicationGroups,
          occurredAt: DateTime(2026, 9, 5, 10, index),
          correct: index == 2,
          evidenceWeight: 0.35,
          source: MicroEvidenceSource.guidedStep,
          usedHelp: true,
          helpLevel: HelpLevel.guided.value,
          methodKey: 'representation:equalGroups',
          mode: TrainingMode.wordProblems,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey:
              'guided:representation:equalGroups:groupCount:process:representation:groups:3:4:$index',
        ),
      ),
    ];

    final guided = controller.guidedStepFocus();
    expect(guided, isNotNull);
    expect(guided!.stepKey, 'groupCount');
  });

  testWidgets('Repräsentationsaufgabe speichert ersten Teilversuch außerhalb Hilfe',
      (tester) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;

    await tester.pumpWidget(
      MaterialApp(
        home: StructuredTrainingScreen(
          controller: controller,
          mode: TrainingMode.wordProblems,
          targetTasks: 2,
          targetCompetency: MicroCompetencyId.representationTranslation,
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Schritt 1 von'), findsOneWidget);
    final buttons = find.byType(FilledButton);
    expect(buttons, findsWidgets);

    await tester.tap(buttons.first);
    await tester.pump(const Duration(milliseconds: 420));

    final observation = controller.microObservations.firstWhere(
      (entry) => entry.source == MicroEvidenceSource.independentStep,
    );
    expect(observation.usedHelp, isFalse);
    expect(
      observation.id == MicroCompetencyId.placeValueDigits ||
          observation.id == MicroCompetencyId.multiplicationGroups,
      isTrue,
    );
  });

  test('Viele Teilfragen verdrängen vollständige Aufgaben nicht aus Mastery-Fenster',
      () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = [
      ...List.generate(
        30,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.multiplicationGroups,
          occurredAt: DateTime(2026, 9, 5, 12, index),
          correct: true,
          evidenceWeight: 0.25,
          source: MicroEvidenceSource.independentStep,
          usedHelp: false,
          mode: TrainingMode.wordProblems,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey:
              'independent:groupCount:process:representation:groups:${3 + index % 3}:4:$index',
        ),
      ),
      ...List.generate(
        6,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.multiplicationGroups,
          occurredAt: DateTime(2026, 9, 4, 12, index),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.practice,
          usedHelp: false,
          mode: TrainingMode.multiply,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'multiply:${3 + index}:4',
        ),
      ),
    ];

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.multiplicationGroups,
    );

    expect(progress.independentStepObservations, 12);
    expect(progress.independentStepEvidence, closeTo(3, 0.001));
    expect(progress.independentEvidence, closeTo(9, 0.001));
    expect(progress.observations, 18);
  });


  test('identische Aufgaben koennen Sicherheit nicht kuenstlich aufblasen', () {
    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.hundred;
    controller.microObservations = List.generate(
      8,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.additionTenBridge,
        occurredAt: DateTime(2026, 9, 16, 10, index),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        mode: TrainingMode.practice,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'plus:47:8',
      ),
    );

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.additionTenBridge,
    );

    expect(progress.independentEvidence, closeTo(8, 0.001));
    expect(progress.independentAccuracy, closeTo(1, 0.001));
    expect(progress.independentTaskVariety, 1);
    expect(progress.state, MicroCompetencyState.practicing);
    expect(
      controller.microEvidenceConfidence(MicroCompetencyId.additionTenBridge).detail,
      contains('1 unterschiedliche Aufgaben'),
    );
  });

  test('drei unterschiedliche selbststaendige Aufgaben ermoeglichen Sicher', () {
    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.hundred;
    controller.microObservations = <MicroCompetencyObservation>[
      for (var index = 0; index < 4; index++)
        MicroCompetencyObservation(
          id: MicroCompetencyId.additionTenBridge,
          occurredAt: DateTime(2026, 9, 16, 11, index),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.practice,
          usedHelp: false,
          mode: TrainingMode.practice,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: index == 3 ? 'plus:47:8' : 'plus:4${index + 4}:${8 - index}',
        ),
    ];

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.additionTenBridge,
    );

    expect(progress.independentTaskVariety, 4);
    expect(progress.state, MicroCompetencyState.secure);
  });

  test('Gemeistert verlangt Vielfalt auch in Review und Transfer', () {
    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.hundred;
    final base = DateTime(2026, 9, 1, 9);
    controller.microObservations = <MicroCompetencyObservation>[
      for (var index = 0; index < 6; index++)
        MicroCompetencyObservation(
          id: MicroCompetencyId.additionTenBridge,
          occurredAt: base.add(Duration(minutes: index)),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.practice,
          usedHelp: false,
          mode: TrainingMode.practice,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'plus:${41 + index}:${9 - index}',
        ),
      for (var index = 0; index < 2; index++)
        MicroCompetencyObservation(
          id: MicroCompetencyId.additionTenBridge,
          occurredAt: base.add(Duration(days: 3, minutes: index)),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.review,
          usedHelp: false,
          mode: TrainingMode.practice,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'review:plus:47:8',
        ),
      for (var index = 0; index < 2; index++)
        MicroCompetencyObservation(
          id: MicroCompetencyId.additionTenBridge,
          occurredAt: base.add(Duration(days: 4, minutes: index)),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.transfer,
          usedHelp: false,
          mode: TrainingMode.wordProblems,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'story:transfer:skill:additionTenBridge:+:books:47:8',
        ),
    ];

    var progress = controller.microCompetencyProgress(
      MicroCompetencyId.additionTenBridge,
    );
    expect(progress.reviewIndependentTaskVariety, 1);
    expect(progress.transferIndependentTaskVariety, 1);
    expect(progress.state, MicroCompetencyState.secure);

    controller.microObservations.insertAll(0, <MicroCompetencyObservation>[
      MicroCompetencyObservation(
        id: MicroCompetencyId.additionTenBridge,
        occurredAt: base.add(const Duration(days: 3, hours: 1)),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.review,
        usedHelp: false,
        mode: TrainingMode.practice,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'review:plus:46:9',
      ),
      MicroCompetencyObservation(
        id: MicroCompetencyId.additionTenBridge,
        occurredAt: base.add(const Duration(days: 4, hours: 1)),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.transfer,
        usedHelp: false,
        mode: TrainingMode.wordProblems,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'story:transfer:skill:additionTenBridge:+:stickers:46:9',
      ),
    ]);

    progress = controller.microCompetencyProgress(
      MicroCompetencyId.additionTenBridge,
    );
    expect(progress.reviewIndependentTaskVariety, 2);
    expect(progress.transferIndependentTaskVariety, 2);
    expect(progress.state, MicroCompetencyState.mastered);
  });

  test('Teilfragen derselben Aufgabe zaehlen fuer Vielfalt nur einmal', () {
    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.hundred;
    controller.microObservations = <MicroCompetencyObservation>[
      for (final step in <String>['groupCount', 'groupSize', 'groupCount'])
        MicroCompetencyObservation(
          id: MicroCompetencyId.multiplicationGroups,
          occurredAt: DateTime(2026, 9, 16, 12).add(
            Duration(minutes: step == 'groupSize' ? 1 : 0),
          ),
          correct: true,
          evidenceWeight: 0.5,
          source: MicroEvidenceSource.independentStep,
          usedHelp: false,
          mode: TrainingMode.multiply,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'independent:$step:process:representation:groups:3:4',
        ),
    ];

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.multiplicationGroups,
    );
    expect(progress.independentTaskVariety, 1);
  });

  test('Mikro-Fokus bevorzugt bei gleicher Quote die geringere Aufgabenvielfalt', () {
    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.hundred;

    MicroCompetencyObservation observation(
      MicroCompetencyId id,
      String key,
      int minute,
    ) => MicroCompetencyObservation(
      id: id,
      occurredAt: DateTime(2026, 9, 16, 13, minute),
      correct: true,
      evidenceWeight: 1,
      source: MicroEvidenceSource.practice,
      usedHelp: false,
      mode: id == MicroCompetencyId.additionNoBridge
          ? TrainingMode.practice
          : TrainingMode.minus,
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      taskKey: key,
    );

    controller.microObservations = <MicroCompetencyObservation>[
      observation(MicroCompetencyId.additionNoBridge, 'plus:14:3', 0),
      observation(MicroCompetencyId.additionNoBridge, 'plus:14:3', 1),
      observation(MicroCompetencyId.additionNoBridge, 'plus:15:2', 2),
      observation(MicroCompetencyId.additionNoBridge, 'plus:15:2', 3),
      observation(MicroCompetencyId.subtractionNoBridge, 'minus:17:3', 4),
      observation(MicroCompetencyId.subtractionNoBridge, 'minus:17:3', 5),
      observation(MicroCompetencyId.subtractionNoBridge, 'minus:17:3', 6),
      observation(MicroCompetencyId.subtractionNoBridge, 'minus:17:3', 7),
    ];

    final addition = controller.microCompetencyProgress(
      MicroCompetencyId.additionNoBridge,
    );
    final subtraction = controller.microCompetencyProgress(
      MicroCompetencyId.subtractionNoBridge,
    );
    expect(addition.independentTaskVariety, 2);
    expect(subtraction.independentTaskVariety, 1);
    expect(addition.independentAccuracy, subtraction.independentAccuracy);
    expect(
      controller.currentMicroFocus()?.definition.id,
      MicroCompetencyId.subtractionNoBridge,
    );
  });

  test('Mikro-Beobachtung speichert Antwortzeit rueckwaertskompatibel', () {
    final observation = MicroCompetencyObservation(
      id: MicroCompetencyId.additionNoBridge,
      occurredAt: DateTime(2026, 9, 16, 14),
      correct: true,
      evidenceWeight: 1,
      source: MicroEvidenceSource.practice,
      usedHelp: false,
      mode: TrainingMode.practice,
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      taskKey: 'plus:14:3',
      responseMs: 3200,
    );

    final restored = MicroCompetencyObservation.fromJson(observation.toJson());
    expect(restored.responseMs, 3200);

    final legacy = Map<String, dynamic>.from(observation.toJson())
      ..remove('responseMs');
    expect(MicroCompetencyObservation.fromJson(legacy).responseMs, isNull);
  });

  test('langsame richtige Antworten bleiben fachlich Sicher', () {
    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.hundred;
    controller.microObservations = List.generate(
      4,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.additionNoBridge,
        occurredAt: DateTime(2026, 9, 16, 15, index),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        mode: TrainingMode.practice,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'plus:${12 + index}:3',
        responseMs: 9000,
      ),
    );

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.additionNoBridge,
    );
    expect(progress.state, MicroCompetencyState.secure);
    expect(progress.fluencySamples, 4);
    expect(progress.fluencyState, MicroFluencyState.building);
    expect(progress.averageFluencyResponseMs, closeTo(9000, 0.001));
  });

  test('schnelle selbststaendige Grundaufgaben belegen fluessigen Abruf', () {
    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.hundred;
    controller.microObservations = List.generate(
      4,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.subtractionNoBridge,
        occurredAt: DateTime(2026, 9, 16, 16, index),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        mode: TrainingMode.minus,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'minus:${18 + index}:3',
        responseMs: 3000 + index * 100,
      ),
    );

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.subtractionNoBridge,
    );
    expect(progress.state, MicroCompetencyState.secure);
    expect(progress.fluencyState, MicroFluencyState.fluent);
    expect(progress.fluencySamples, 4);
  });

  test('Hilfe und falsche Antworten zaehlen nicht als Automatisierung', () {
    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.hundred;
    controller.microObservations = <MicroCompetencyObservation>[
      for (var index = 0; index < 2; index++)
        MicroCompetencyObservation(
          id: MicroCompetencyId.multiplicationFacts,
          occurredAt: DateTime(2026, 9, 16, 17, index),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.practice,
          usedHelp: false,
          mode: TrainingMode.multiply,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'multiply:${3 + index}:4',
          responseMs: 2800,
        ),
      MicroCompetencyObservation(
        id: MicroCompetencyId.multiplicationFacts,
        occurredAt: DateTime(2026, 9, 16, 17, 2),
        correct: true,
        evidenceWeight: 0.8,
        source: MicroEvidenceSource.practice,
        usedHelp: true,
        helpLevel: 1,
        mode: TrainingMode.multiply,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'multiply:5:4',
        responseMs: 1000,
      ),
      MicroCompetencyObservation(
        id: MicroCompetencyId.multiplicationFacts,
        occurredAt: DateTime(2026, 9, 16, 17, 3),
        correct: false,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        mode: TrainingMode.multiply,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'multiply:6:4',
        responseMs: 1000,
      ),
    ];

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.multiplicationFacts,
    );
    expect(progress.fluencySamples, 2);
    expect(progress.fluencyState, MicroFluencyState.notMeasured);
  });

  test('komplexe Kompetenzen bekommen keine pauschale Tempowertung', () {
    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.hundred;
    controller.microObservations = List.generate(
      4,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.wordProblemModel,
        occurredAt: DateTime(2026, 9, 16, 18, index),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        mode: TrainingMode.wordProblems,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'story:model:+:books:${20 + index}:5',
        responseMs: 12000,
      ),
    );

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.wordProblemModel,
    );
    expect(progress.fluencyState, MicroFluencyState.notApplicable);
    expect(progress.fluencySamples, 0);
  });

  test('recordDiagnosticAttempt uebernimmt die erste Antwortzeit', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    await controller.recordDiagnosticAttempt(
      mode: TrainingMode.practice,
      taskKey: 'plus:14:3',
      expected: 17,
      actual: 17,
      fact: MathFact(a: 14, b: 3, operation: MathOperation.plus),
      responseTime: const Duration(milliseconds: 3456),
    );

    expect(controller.microObservations, isNotEmpty);
    expect(controller.microObservations.first.responseMs, 3456);
  });


  test('Automatisierung bewertet nur das aktuelle Zeitfenster', () {
    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.hundred;
    controller.microObservations = List<MicroCompetencyObservation>.generate(
      12,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.additionNoBridge,
        occurredAt: DateTime(2026, 9, 16, 8).add(Duration(minutes: index)),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        mode: TrainingMode.practice,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'plus:${10 + index}:2',
        responseMs: index < 4 ? 9000 : 3000,
      ),
    );

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.additionNoBridge,
    );
    expect(progress.fluencySamples, 8);
    expect(progress.averageFluencyResponseMs, closeTo(3000, 0.001));
    expect(progress.fluencyState, MicroFluencyState.fluent);
  });

  test('Sachaufgabenzeit wird nicht als Kopfrechen-Automatisierung gewertet', () {
    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.hundred;
    controller.microObservations = List<MicroCompetencyObservation>.generate(
      4,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.additionNoBridge,
        occurredAt: DateTime(2026, 9, 16, 20, index),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.transfer,
        usedHelp: false,
        mode: TrainingMode.wordProblems,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'story:+:books:${14 + index}:3',
        responseMs: 12000,
      ),
    );

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.additionNoBridge,
    );
    expect(progress.fluencySamples, 0);
    expect(progress.fluencyState, MicroFluencyState.notMeasured);
  });

  test('Meine Runde nutzt Automatisierung erst nach fachlicher Sicherheit', () {
    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.hundred;
    controller.microObservations = <MicroCompetencyObservation>[
      for (var index = 0; index < 4; index++)
        MicroCompetencyObservation(
          id: MicroCompetencyId.additionNoBridge,
          occurredAt: DateTime(2026, 9, 16, 21, index),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.practice,
          usedHelp: false,
          mode: TrainingMode.practice,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'plus:${20 + index}:3',
          responseMs: 8000,
        ),
      MicroCompetencyObservation(
        id: MicroCompetencyId.additionNoBridge,
        occurredAt: DateTime(2026, 9, 16, 21, 4),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.review,
        usedHelp: false,
        mode: TrainingMode.practice,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'plus:31:4:review',
      ),
      MicroCompetencyObservation(
        id: MicroCompetencyId.additionNoBridge,
        occurredAt: DateTime(2026, 9, 16, 21, 5),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.transfer,
        usedHelp: false,
        mode: TrainingMode.wordProblems,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'story:+:books:24:3:transfer',
      ),
    ];

    final fluency = controller.fluencyFocusMicroCompetency();
    expect(fluency?.definition.id, MicroCompetencyId.additionNoBridge);
    expect(fluency?.fluencyState, MicroFluencyState.building);

    final plan = controller.buildMyRound(now: DateTime(2026, 9, 16, 21, 10));
    final focus = plan[1];
    expect(focus.targetCompetency, MicroCompetencyId.additionNoBridge);
    expect(focus.fluencyEmphasis, isTrue);
    expect(focus.reason, contains('Automatisierung'));
    expect(plan.fold<int>(0, (sum, segment) => sum + segment.tasks), 12);

    final trace = controller.guidedRoundDecisionTrace(
      now: DateTime(2026, 9, 16, 21, 10),
    );
    expect(trace.primary?.kind.name, 'fluency');
    expect(trace.primary?.competencyId, MicroCompetencyId.additionNoBridge);

    final insight = controller.parentInsight(
      now: DateTime(2026, 9, 16, 21, 10),
    );
    expect(insight.focus, contains('fachlich sicher'));
    expect(insight.action, contains('ohne Countdown'));
    expect(insight.notYet, contains('Automatisierung wird davon getrennt'));
  });

  test('fachliche Unsicherheit verdraengt einen moeglichen Fluency-Fokus', () {
    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.hundred;
    controller.microObservations = <MicroCompetencyObservation>[
      for (var index = 0; index < 4; index++)
        MicroCompetencyObservation(
          id: MicroCompetencyId.additionNoBridge,
          occurredAt: DateTime(2026, 9, 16, 21, index),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.practice,
          usedHelp: false,
          mode: TrainingMode.practice,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'plus:${20 + index}:3',
          responseMs: 8000,
        ),
      for (var index = 0; index < 3; index++)
        MicroCompetencyObservation(
          id: MicroCompetencyId.subtractionNoBridge,
          occurredAt: DateTime(2026, 9, 16, 22, index),
          correct: false,
          evidenceWeight: 1,
          source: MicroEvidenceSource.practice,
          usedHelp: false,
          mode: TrainingMode.minus,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'minus:${18 + index}:3',
          responseMs: 2500,
        ),
    ];

    expect(
      controller.currentMicroFocus()?.definition.id,
      MicroCompetencyId.subtractionNoBridge,
    );
    final plan = controller.buildMyRound(now: DateTime(2026, 9, 16, 22, 10));
    expect(plan[1].targetCompetency, MicroCompetencyId.subtractionNoBridge);
    expect(plan[1].fluencyEmphasis, isFalse);
  });


  test('wiederholte identische Aufgabe reicht nicht fuer Fluency', () {
    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.hundred;
    controller.microObservations = List.generate(
      4,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.additionNoBridge,
        occurredAt: DateTime(2026, 9, 16, 23, index),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        mode: TrainingMode.practice,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'plus:14:3',
        responseMs: 2400,
      ),
    );

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.additionNoBridge,
    );
    expect(progress.fluencyAttempts, 4);
    expect(progress.fluencySamples, 4);
    expect(progress.fluencyTaskVariety, 1);
    expect(progress.fluencyState, MicroFluencyState.notMeasured);
  });

  test('schnelle Treffer reichen bei zu vielen Fehlern nicht fuer Fluency', () {
    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.hundred;
    controller.microObservations = List.generate(
      8,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.subtractionNoBridge,
        occurredAt: DateTime(2026, 9, 17, 8, index),
        correct: index >= 2,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        mode: TrainingMode.minus,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'minus:${30 + index}:4',
        responseMs: 2300 + index * 50,
      ),
    );

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.subtractionNoBridge,
    );
    expect(progress.fluencyAttempts, 8);
    expect(progress.fluencyCorrectAttempts, 6);
    expect(progress.fluencyAccuracy, closeTo(0.75, 0.001));
    expect(progress.fluencyTaskVariety, 6);
    expect(progress.fluencyState, MicroFluencyState.building);
  });

  test('ein einzelner langsamer Ausreisser verzerrt typische Fluency nicht', () {
    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.hundred;
    const times = <int>[2500, 2600, 2700, 15000];
    controller.microObservations = List.generate(
      times.length,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.multiplicationFacts,
        occurredAt: DateTime(2026, 9, 17, 9, index),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        mode: TrainingMode.multiply,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'multiply:${3 + index}:4',
        responseMs: times[index],
      ),
    );

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.multiplicationFacts,
    );
    expect(progress.averageFluencyResponseMs, greaterThan(5000));
    expect(progress.typicalFluencyResponseMs, closeTo(2650, 0.001));
    expect(progress.fluencyAccuracy, 1);
    expect(progress.fluencyState, MicroFluencyState.fluent);
  });

  test('neue Fehler koennen zuvor fluessigen Abruf wieder herabstufen', () {
    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.hundred;
    controller.microObservations = <MicroCompetencyObservation>[
      for (var index = 0; index < 8; index++)
        MicroCompetencyObservation(
          id: MicroCompetencyId.divisionFacts,
          occurredAt: DateTime(2026, 9, 17, 10, index),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.practice,
          usedHelp: false,
          mode: TrainingMode.divide,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'divide:${24 + index * 4}:4',
          responseMs: 2800,
        ),
      for (var index = 0; index < 2; index++)
        MicroCompetencyObservation(
          id: MicroCompetencyId.divisionFacts,
          occurredAt: DateTime(2026, 9, 17, 11, index),
          correct: false,
          evidenceWeight: 1,
          source: MicroEvidenceSource.practice,
          usedHelp: false,
          mode: TrainingMode.divide,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'divide:${64 + index * 4}:4',
          responseMs: 2500,
        ),
    ];

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.divisionFacts,
    );
    expect(progress.fluencyAttempts, 8);
    expect(progress.fluencyCorrectAttempts, 6);
    expect(progress.fluencyAccuracy, closeTo(0.75, 0.001));
    expect(progress.typicalFluencyResponseMs, closeTo(2800, 0.001));
    expect(progress.fluencyState, MicroFluencyState.building);
  });


  test('Vorlesen pausiert nur die Fluency-Zeitmessung', () async {
    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.hundred
      ..accessibilityPreferences = const AccessibilityPreferences(readAloud: true);
    await controller.recordDiagnosticAttempt(
      mode: TrainingMode.practice,
      taskKey: 'plus:14:3',
      expected: 17,
      actual: 17,
      fact: MathFact(a: 14, b: 3, operation: MathOperation.plus),
      responseTime: const Duration(milliseconds: 2100),
    );

    final observation = controller.microObservations.firstWhere(
      (entry) => entry.id == MicroCompetencyId.additionNoBridge,
    );
    expect(observation.correct, isTrue);
    expect(observation.responseMs, isNull);
    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.additionNoBridge,
    );
    expect(progress.independentEvidence, greaterThan(0));
    expect(progress.fluencyAttempts, 0);
  });

  test('lange Unterbrechung wird nicht als langsame Fluency gewertet', () async {
    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.hundred;
    await controller.recordDiagnosticAttempt(
      mode: TrainingMode.minus,
      taskKey: 'minus:18:3',
      expected: 15,
      actual: 15,
      fact: MathFact(a: 18, b: 3, operation: MathOperation.minus),
      responseTime: const Duration(seconds: 31),
    );

    final observation = controller.microObservations.firstWhere(
      (entry) => entry.id == MicroCompetencyId.subtractionNoBridge,
    );
    expect(observation.correct, isTrue);
    expect(observation.responseMs, isNull);
    expect(
      controller.microCompetencyProgress(MicroCompetencyId.subtractionNoBridge)
          .independentEvidence,
      greaterThan(0),
    );
  });

  test('Remediation-Zeiten sind kein Fluency-Nachweis', () {
    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.hundred;
    controller.microObservations = List.generate(
      5,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.multiplicationFacts,
        occurredAt: DateTime(2026, 9, 17, 12, index),
        correct: true,
        evidenceWeight: 0.65,
        source: MicroEvidenceSource.remediation,
        usedHelp: false,
        mode: TrainingMode.multiply,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'multiply:${3 + index}:4:remediation',
        responseMs: 1800,
      ),
    );

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.multiplicationFacts,
    );
    expect(progress.independentEvidence, greaterThan(0));
    expect(progress.fluencyAttempts, 0);
    expect(progress.fluencySamples, 0);
    expect(progress.fluencyState, MicroFluencyState.notMeasured);
  });

  test('Vorlesen unterdrueckt Fluency-Fokus ohne Lernfortschritt zu loeschen', () {
    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.hundred;
    controller.microObservations = List.generate(
      5,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.additionNoBridge,
        occurredAt: DateTime(2026, 9, 17, 13, index),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        mode: TrainingMode.practice,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'plus:${20 + index}:3',
        responseMs: 8200,
      ),
    );
    expect(
      controller.microCompetencyProgress(MicroCompetencyId.additionNoBridge)
          .fluencyState,
      MicroFluencyState.building,
    );
    expect(controller.fluencyFocusMicroCompetency(), isNotNull);

    controller.accessibilityPreferences =
        const AccessibilityPreferences(readAloud: true);
    expect(controller.fluencyFocusMicroCompetency(), isNull);
    final plan = controller.buildMyRound(now: DateTime(2026, 9, 17, 14));
    expect(plan.any((segment) => segment.fluencyEmphasis), isFalse);
    expect(
      controller.microCompetencyProgress(MicroCompetencyId.additionNoBridge)
          .state,
      MicroCompetencyState.secure,
    );
  });

}
