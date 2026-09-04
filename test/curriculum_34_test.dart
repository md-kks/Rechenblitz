import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/training.dart';

void main() {
  const upperModes = [
    TrainingMode.largeNumbers,
    TrainingMode.rounding,
    TrainingMode.mentalStrategies,
    TrainingMode.writtenAddSub,
    TrainingMode.writtenMultiply,
    TrainingMode.writtenDivide,
    TrainingMode.estimation,
    TrainingMode.arithmeticLaws,
    TrainingMode.romanNumerals,
    TrainingMode.fractions,
    TrainingMode.advancedMeasures,
    TrainingMode.timeDurations,
    TrainingMode.dataCharts,
    TrainingMode.probability,
    TrainingMode.combinatorics,
    TrainingMode.proportionality,
    TrainingMode.perimeterArea,
    TrainingMode.geometryBodies,
    TrainingMode.symmetry,
    TrainingMode.plansAndOrientation,
    TrainingMode.volumeCubes,
  ];

  test('Klassenstufen haben passende Standard-Zahlenräume', () {
    expect(GradeLevel.first.recommendedRange, NumberRangeLevel.twenty);
    expect(GradeLevel.second.recommendedRange, NumberRangeLevel.hundred);
    expect(GradeLevel.third.recommendedRange, NumberRangeLevel.thousand);
    expect(GradeLevel.fourth.recommendedRange, NumberRangeLevel.million);
  });

  test('alle Lernbereiche Klasse 3/4 erzeugen gültige Aufgaben', () {
    final generator = CurriculumExerciseGenerator(random: Random(2026));

    for (final config in [
      (GradeLevel.third, 1000),
      (GradeLevel.fourth, 1000000),
    ]) {
      for (final mode in upperModes) {
        for (var i = 0; i < 40; i++) {
          final exercise = generator.generate(
            mode: mode,
            gradeLevel: config.$1,
            maxValue: config.$2,
          );

          expect(exercise.prompt, isNotEmpty, reason: '$mode prompt');
          expect(exercise.hint, isNotEmpty, reason: '$mode hint');
          expect(exercise.key, isNotEmpty, reason: '$mode key');

          if (exercise.usesChoices) {
            expect(
              exercise.answer,
              inInclusiveRange(0, exercise.choices!.length - 1),
              reason: '$mode Auswahlindex',
            );
          } else {
            expect(exercise.answer, greaterThanOrEqualTo(0), reason: '$mode');
            if (exercise.maxAnswerValue != null) {
              expect(
                exercise.answer,
                lessThanOrEqualTo(exercise.maxAnswerValue!),
                reason: '$mode Antwortbereich',
              );
            }
          }

          if (exercise.hasBars) {
            expect(exercise.bars!.every((bar) => bar.value >= 0), isTrue);
          }
        }
      }
    }
  });

  test('Förder-Zahlenraum 100 bleibt bei Rechenaufgaben begrenzt', () {
    final generator = CurriculumExerciseGenerator(random: Random(77));
    const modes = [
      TrainingMode.largeNumbers,
      TrainingMode.rounding,
      TrainingMode.mentalStrategies,
      TrainingMode.writtenAddSub,
      TrainingMode.writtenMultiply,
      TrainingMode.writtenDivide,
    ];

    for (final mode in modes) {
      for (var i = 0; i < 100; i++) {
        final exercise = generator.generate(
          mode: mode,
          gradeLevel: GradeLevel.third,
          maxValue: 100,
        );
        if (!exercise.usesChoices) {
          expect(exercise.answer, lessThanOrEqualTo(100), reason: '$mode');
        }
      }
    }
  });

  test('alte Sitzungen ohne Klassenstufe bleiben lesbar', () {
    final oldJson = <String, dynamic>{
      'mode': 'practice',
      'startedAt': '2026-09-01T12:00:00.000',
      'finishedAt': '2026-09-01T12:05:00.000',
      'total': 10,
      'correctFirstTry': 8,
      'incorrectAttempts': 2,
      'plusCorrect': 4,
      'plusTotal': 5,
      'minusCorrect': 4,
      'minusTotal': 5,
      'averageResponseMs': 3200,
      'numberRange': 'twenty',
      'starsEarned': 2,
    };

    final restored = TrainingSessionResult.fromJson(oldJson);
    expect(restored.gradeLevel, GradeLevel.second);
    expect(restored.numberRange, NumberRangeLevel.twenty);
  });

  test('Millionen-Zahlenraum enthält eine echte Millionenstelle', () {
    final generator = CurriculumExerciseGenerator(random: Random(123));
    var sawLargePlace = false;
    for (var i = 0; i < 2000; i++) {
      final exercise = generator.generate(
        mode: TrainingMode.largeNumbers,
        gradeLevel: GradeLevel.fourth,
        maxValue: 1000000,
      );
      if (exercise.prompt.contains('Millionenstelle') ||
          exercise.prompt.contains('1 M')) {
        sawLargePlace = true;
        break;
      }
    }
    expect(sawLargePlace, isTrue);
  });
}
