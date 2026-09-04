import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/structured_exercise.dart';
import 'package:rechenblitz/models/training.dart';
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
    expect(aided.evidenceWeight, closeTo(0.65, 0.001));
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
}
