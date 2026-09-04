import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/structured_exercise.dart';
import 'package:rechenblitz/models/task_diversity.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/adaptive_engine.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/widgets/learning_visual_aid.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Sachaufgaben vermeiden exakte und sprachliche Kurzzeit-Wiederholungen',
      () {
    final generator = StructuredExerciseGenerator(random: Random(4201));
    final recent = <String>[];
    final keys = <String>[];

    for (var i = 0; i < 80; i++) {
      final exercise = generator.generate(
        mode: TrainingMode.wordProblems,
        maxValue: 100,
        recentKeys: recent,
      );
      expect(
        recent.take(8),
        isNot(contains(exercise.key)),
        reason: 'Aufgabe wurde zu früh wiederholt: ${exercise.key}',
      );
      keys.add(exercise.key);
      recent.insert(0, exercise.key);
      if (recent.length > 40) recent.removeLast();
    }

    final audit = TaskDiversityAudit.analyze(keys);
    expect(audit.immediateRepeats, 0);
    expect(audit.repeatWithinFiveShare, lessThan(0.03));
    expect(audit.uniqueKeyShare, greaterThan(0.75));
    expect(audit.uniqueFamilies, greaterThanOrEqualTo(10));
  });

  test('Geld und Größen rotieren über mehrere Aufgabenfamilien', () {
    for (final mode in [TrainingMode.money, TrainingMode.measures]) {
      final generator =
          StructuredExerciseGenerator(random: Random(8000 + mode.index));
      final recent = <String>[];
      final families = <String>{};

      for (var i = 0; i < 50; i++) {
        final exercise = generator.generate(
          mode: mode,
          maxValue: 100,
          recentKeys: recent,
        );
        families.add(TaskDiversity.familyForKey(exercise.key));
        recent.insert(0, exercise.key);
        if (recent.length > 40) recent.removeLast();
      }

      expect(families.length, greaterThanOrEqualTo(4), reason: mode.name);
    }
  });

  test('Klasse-3/4-Generator vermeidet kurze Wiederholungsschleifen', () {
    for (final mode in [
      TrainingMode.probability,
      TrainingMode.combinatorics,
      TrainingMode.proportionality,
      TrainingMode.perimeterArea,
      TrainingMode.largeNumbers,
      TrainingMode.rounding,
    ]) {
      final generator =
          CurriculumExerciseGenerator(random: Random(9000 + mode.index));
      final recent = <String>[];
      final keys = <String>[];

      for (var i = 0; i < 60; i++) {
        final exercise = generator.generate(
          mode: mode,
          gradeLevel: GradeLevel.fourth,
          maxValue: 1000000,
          recentKeys: recent,
        );
        keys.add(exercise.key);
        recent.insert(0, exercise.key);
        if (recent.length > 40) recent.removeLast();
      }

      final audit = TaskDiversityAudit.analyze(keys);
      expect(audit.immediateRepeats, 0, reason: mode.name);
      expect(
        audit.repeatWithinFiveShare,
        lessThan(0.08),
        reason: mode.name,
      );
    }
  });

  test('adaptive Grundrechenarten halten Mindestabstand zwischen Fakten', () {
    final engine = AdaptiveEngine(random: Random(2026));
    final facts = AdaptiveEngine.buildFactPool(maxValue: 100);
    final recent = <String>[];
    final keys = <String>[];

    for (var i = 0; i < 80; i++) {
      final fact = engine.selectNext(
        facts: facts,
        mode: TrainingMode.practice,
        maxValue: 20,
        recentKeys: recent,
      );
      expect(
        recent.take(5),
        isNot(contains(fact.key)),
        reason: 'Grundaufgabe zu früh wiederholt: ${fact.key}',
      );
      keys.add(fact.key);
      recent.insert(0, fact.key);
      if (recent.length > 40) recent.removeLast();
    }

    final audit = TaskDiversityAudit.analyze(keys);
    expect(audit.immediateRepeats, 0);
    expect(audit.repeatWithinFive, 0);
  });

  test('Aufgaben-Gedächtnis bleibt lokal über Neustart erhalten', () async {
    final controller = AppController();
    await controller.load();

    await controller.rememberPresentedTask(
      TrainingMode.wordProblems,
      'story:+:books:12:7',
    );
    await controller.rememberPresentedTask(
      TrainingMode.wordProblems,
      'story:-:cards:18:6',
    );

    final reloaded = AppController();
    await reloaded.load();

    expect(
      reloaded.recentTaskKeys(TrainingMode.wordProblems),
      [
        'story:-:cards:18:6',
        'story:+:books:12:7',
      ],
    );
  });

  test('Reset löscht auch das Aufgaben-Gedächtnis', () async {
    final controller = AppController();
    await controller.load();
    await controller.rememberPresentedTask(
      TrainingMode.money,
      'money:add:school:8:4',
    );

    await controller.resetProgress();

    expect(controller.recentTaskKeys(TrainingMode.money), isEmpty);

    final reloaded = AppController();
    await reloaded.load();
    expect(reloaded.recentTaskKeys(TrainingMode.money), isEmpty);
  });

  testWidgets('visuelle Hilfen rendern zentrale Rechenmuster', (tester) async {
    for (final pattern in [
      ErrorPattern.tenBridge,
      ErrorPattern.multiplicationFact,
      ErrorPattern.placeValue,
      ErrorPattern.unitConversion,
      ErrorPattern.fractionPart,
      ErrorPattern.timeDuration,
      ErrorPattern.perimeterArea,
      ErrorPattern.wordProblem,
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LearningVisualAid(
                pattern: pattern,
                taskKey: switch (pattern) {
                  ErrorPattern.tenBridge => 'minus:13:5',
                  ErrorPattern.multiplicationFact => 'multiply:4:6',
                  ErrorPattern.placeValue => 'large:place:438:100',
                  ErrorPattern.fractionPart => 'fraction:quarter:20',
                  _ => 'visual:test:12:4',
                },
                expected: 8,
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: pattern.name);
    }
  });
}
