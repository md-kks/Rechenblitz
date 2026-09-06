import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/micro_competency.dart';
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





  test('Gezielte Fehlerprüfung variiert genau eine Stellenwertstelle', () {
    final generator = CurriculumExerciseGenerator(random: Random(861));
    final places = <int>{};

    for (final config in [
      (GradeLevel.third, 1000),
      (GradeLevel.fourth, 1000000),
    ]) {
      for (var i = 0; i < 160; i++) {
        final exercise = generator.generate(
          mode: TrainingMode.writtenAddSub,
          gradeLevel: config.$1,
          maxValue: config.$2,
          targetCompetency: MicroCompetencyId.errorChecking,
        );
        final parts = exercise.key.split(':');
        final placeIndex = parts.indexOf('place');
        final place = int.parse(parts[placeIndex + 1]);
        final a = int.parse(parts[parts.length - 3]);
        final b = int.parse(parts[parts.length - 2]);
        final wrong = int.parse(parts.last);
        final correct = a + b;

        places.add(place);
        expect(exercise.key, startsWith('process:error:add:'));
        expect((correct - wrong).abs(), place);
        expect(correct % place, wrong % place);
        expect(correct ~/ (place * 10), wrong ~/ (place * 10));
        expect(exercise.usesChoices, isTrue);
        expect(
          exercise.choices![exercise.answer],
          correct < wrong
              ? 'Das Ergebnis ist um $place zu groß.'
              : 'Das Ergebnis ist um $place zu klein.',
        );
      }
    }

    expect(places, containsAll({1, 10, 100}));
  });

  test('Normale Fehlerprüfungen behalten den bisherigen Task-Key', () {
    final generator = CurriculumExerciseGenerator(random: Random(862));
    var seen = 0;

    for (var i = 0; i < 400; i++) {
      final exercise = generator.generate(
        mode: TrainingMode.writtenAddSub,
        gradeLevel: GradeLevel.third,
        maxValue: 1000,
      );
      if (!exercise.key.startsWith('process:error:add:')) continue;
      seen += 1;
      expect(exercise.key.split(':'), hasLength(6));
    }

    expect(seen, greaterThan(0));
  });

  test('Gezielte Zahlwort-Aufgaben enthalten ein echtes Einer-Zehner-Ende',
      () {
    final generator = CurriculumExerciseGenerator(random: Random(841));
    final kinds = <String>{};

    for (final config in [
      (GradeLevel.third, 1000),
      (GradeLevel.fourth, 1000000),
    ]) {
      for (var i = 0; i < 120; i++) {
        final exercise = generator.generate(
          mode: TrainingMode.largeNumbers,
          gradeLevel: config.$1,
          maxValue: config.$2,
          targetCompetency: MicroCompetencyId.numberWordReading,
        );
        final parts = exercise.key.split(':');
        final number = int.parse(parts.last);
        final suffix = number % 100;
        final tens = suffix ~/ 10;
        final ones = suffix % 10;

        kinds.add(parts[2]);
        expect(exercise.key, startsWith('large:word:'));
        expect(number, greaterThanOrEqualTo(100));
        expect(number, lessThanOrEqualTo(config.$2));
        expect(tens, inInclusiveRange(2, 9));
        expect(ones, inInclusiveRange(1, 9));
        expect(tens, isNot(ones));
        expect(exercise.usesChoices, isTrue);
      }
    }

    expect(kinds, containsAll({'read', 'write'}));
  });


  test('Gezielter Überschlag bleibt im echten Estimation-Pfad', () {
    final generator = CurriculumExerciseGenerator(random: Random(841));

    for (final config in [
      (GradeLevel.third, 1000),
      (GradeLevel.fourth, 1000000),
    ]) {
      for (var i = 0; i < 100; i++) {
        final exercise = generator.generate(
          mode: TrainingMode.estimation,
          gradeLevel: config.$1,
          maxValue: config.$2,
          targetCompetency: MicroCompetencyId.estimation,
        );
        final parts = exercise.key.split(':');
        final a = int.parse(parts[1]);
        final b = int.parse(parts[2]);
        final place = int.parse(parts[3]);

        expect(exercise.key, startsWith('estimate:'));
        expect(exercise.key, isNot(startsWith('process:plausibility:')));
        expect(a % place == 0 && b % place == 0, isFalse);
        expect(exercise.choices, hasLength(4));
      }
    }
  });

  test('Gezielte Strategiewahl baut korrekt über eine glatte Zielzahl auf', () {
    final generator = CurriculumExerciseGenerator(random: Random(821));

    for (final config in [
      (GradeLevel.third, 1000),
      (GradeLevel.fourth, 1000000),
    ]) {
      for (var i = 0; i < 100; i++) {
        final exercise = generator.generate(
          mode: TrainingMode.mentalStrategies,
          gradeLevel: config.$1,
          maxValue: config.$2,
          targetCompetency: MicroCompetencyId.strategyChoice,
        );
        final parts = exercise.key.split(':');
        final a = int.parse(parts[3]);
        final b = int.parse(parts[4]);
        final anchor = int.parse(parts[5]);
        final gap = anchor - a;
        final rest = b - gap;

        expect(exercise.key, startsWith('process:strategy:'));
        expect(gap, greaterThanOrEqualTo(2));
        expect(rest, greaterThanOrEqualTo(0));
        expect(a + b, lessThanOrEqualTo(config.$2));
        expect(
          exercise.choices![exercise.answer],
          '$a + $gap + $rest',
        );
      }
    }
  });

  test('Gezielte Stellenwertzerlegung enthält einen nichttrivialen Fokusplatz',
      () {
    final generator = CurriculumExerciseGenerator(random: Random(812));

    for (final config in [
      (GradeLevel.third, 1000),
      (GradeLevel.fourth, 1000000),
    ]) {
      for (var i = 0; i < 100; i++) {
        final exercise = generator.generate(
          mode: TrainingMode.largeNumbers,
          gradeLevel: config.$1,
          maxValue: config.$2,
          targetCompetency: MicroCompetencyId.placeValueDecompose,
        );
        final parts = exercise.key.split(':');
        final number = int.parse(parts[2]);
        final place = int.parse(parts[3]);
        final digit = (number ~/ place) % 10;

        expect(exercise.key, startsWith('large:decompose:'));
        expect(place, greaterThanOrEqualTo(10));
        expect(digit, greaterThan(0));
        expect(exercise.answer, number);
        expect(exercise.maxAnswerValue, config.$2);
        expect(exercise.prompt, contains('ergeben welche Zahl?'));
      }
    }
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
