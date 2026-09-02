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
    ];

    for (final maxValue in [10, 20, 100]) {
      for (final mode in modes) {
        for (var i = 0; i < 100; i++) {
          final exercise =
              generator.generate(mode: mode, maxValue: maxValue);
          expect(exercise.answer, inInclusiveRange(0, maxValue),
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
}
