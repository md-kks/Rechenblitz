import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/structured_exercise.dart';
import 'package:rechenblitz/models/training.dart';

void main() {
  test('strukturierte Zweitklassen-Aufgaben bleiben im gewählten Zahlenraum', () {
    final generator = StructuredExerciseGenerator(random: Random(9));
    const modes = [
      TrainingMode.numberWall,
      TrainingMode.missingNumber,
      TrainingMode.neighbors,
      TrainingMode.placeValue,
      TrainingMode.doublesHalves,
      TrainingMode.sequences,
      TrainingMode.factFamilies,
      TrainingMode.wordProblems,
      TrainingMode.money,
      TrainingMode.clock,
      TrainingMode.measures,
      TrainingMode.geometry,
    ];

    for (final maxValue in [10, 20, 100]) {
      for (final mode in modes) {
        for (var i = 0; i < 100; i++) {
          final exercise =
              generator.generate(mode: mode, maxValue: maxValue);
          final effectiveMax = exercise.maxAnswerValue ?? maxValue;
          expect(exercise.answer, inInclusiveRange(0, effectiveMax),
              reason: '$mode im Zahlenraum $maxValue');
        }
      }
    }
  });

  test('Zahlenmauer folgt der Summenregel', () {
    final generator = StructuredExerciseGenerator(random: Random(4));
    for (var i = 0; i < 100; i++) {
      final exercise = generator.generate(
        mode: TrainingMode.numberWall,
        maxValue: 100,
      );
      final values = exercise.wallValues!;
      expect(values[3], values[0] + values[1]);
      expect(values[4], values[1] + values[2]);
      expect(values[5], values[3] + values[4]);
      expect(exercise.answer, values[exercise.hiddenWallIndex!]);
    }
  });

  test('Zahlenfolgen bleiben vollständig im Zahlenraum', () {
    final generator = StructuredExerciseGenerator(random: Random(11));
    for (final maxValue in [10, 20, 100]) {
      for (var i = 0; i < 100; i++) {
        final exercise = generator.generate(
          mode: TrainingMode.sequences,
          maxValue: maxValue,
        );
        expect(exercise.answer, inInclusiveRange(0, maxValue));
      }
    }
  });

  test('Uhrzeit-Aufgaben besitzen vier eindeutige Antwortoptionen', () {
    final generator = StructuredExerciseGenerator(random: Random(17));
    for (var i = 0; i < 50; i++) {
      final exercise = generator.generate(
        mode: TrainingMode.clock,
        maxValue: 100,
      );
      expect(exercise.hasClock, isTrue);
      expect(exercise.choices, hasLength(4));
      expect(exercise.choices!.toSet(), hasLength(4));
      expect(exercise.answer, inInclusiveRange(0, 3));
      expect(exercise.clockMinute, isIn([0, 15, 30, 45]));
    }
  });

  test('Geometrie verwendet Grundformen und gültige Antworten', () {
    final generator = StructuredExerciseGenerator(random: Random(23));
    for (var i = 0; i < 80; i++) {
      final exercise = generator.generate(
        mode: TrainingMode.geometry,
        maxValue: 20,
      );
      expect(exercise.shape, isNotNull);
      if (exercise.usesChoices) {
        expect(exercise.answer, inInclusiveRange(0, exercise.choices!.length - 1));
      } else {
        expect(exercise.answer, inInclusiveRange(0, 4));
      }
    }
  });

  test('Sachaufgaben liefern Ergebnisse innerhalb des Zahlenraums', () {
    final generator = StructuredExerciseGenerator(random: Random(31));
    for (final maxValue in [10, 20, 100]) {
      for (var i = 0; i < 100; i++) {
        final exercise = generator.generate(
          mode: TrainingMode.wordProblems,
          maxValue: maxValue,
        );
        expect(exercise.answer, inInclusiveRange(0, maxValue));
        expect(exercise.prompt, isNotEmpty);
        expect(exercise.hint, isNotEmpty);
      }
    }
  });
}
