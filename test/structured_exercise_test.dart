import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/micro_competency.dart';
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

  test('Modellierungsschritte sind gezielt generierbar und getrennt getaggt', () {
    final generator = StructuredExerciseGenerator(random: Random(311));
    const cases = [
      (
        id: MicroCompetencyId.wordProblemRelevantInformation,
        prefix: 'story:info:',
        choices: true,
      ),
      (
        id: MicroCompetencyId.wordProblemOperation,
        prefix: 'story:operation:',
        choices: true,
      ),
      (
        id: MicroCompetencyId.wordProblemModel,
        prefix: 'story:equation:',
        choices: true,
      ),
      (
        id: MicroCompetencyId.wordProblemCalculation,
        prefix: 'story:calc:',
        choices: false,
      ),
      (
        id: MicroCompetencyId.wordProblemInterpretation,
        prefix: 'story:interpret:',
        choices: true,
      ),
    ];

    for (final item in cases) {
      final exercise = generator.generate(
        mode: TrainingMode.wordProblems,
        maxValue: 100,
        gradeLevel: GradeLevel.second,
        targetCompetency: item.id,
      );
      final tags = MicroCompetencyCatalog.tagsForTask(
        mode: TrainingMode.wordProblems,
        taskKey: exercise.key,
      );

      expect(exercise.key, startsWith(item.prefix));
      expect(tags.first.id, item.id);
      expect(exercise.usesChoices, item.choices);
      if (exercise.usesChoices) {
        expect(exercise.choices, hasLength(4));
        expect(exercise.choices!.toSet(), hasLength(4));
        expect(
          exercise.answer,
          inInclusiveRange(0, exercise.choices!.length - 1),
        );
      } else {
        expect(exercise.answer, inInclusiveRange(0, 100));
      }
    }
  });

  test('Klasse 1 sieht in Modellierungsaufgaben nur bekannte Rechenarten', () {
    final generator = StructuredExerciseGenerator(random: Random(313));

    for (var i = 0; i < 30; i++) {
      final operation = generator.generate(
        mode: TrainingMode.wordProblems,
        maxValue: 20,
        gradeLevel: GradeLevel.first,
        targetCompetency: MicroCompetencyId.wordProblemOperation,
      );
      expect(operation.choices, hasLength(2));
      expect(operation.choices!.toSet(), {'Plus (+)', 'Minus (−)'});

      final equation = generator.generate(
        mode: TrainingMode.wordProblems,
        maxValue: 20,
        gradeLevel: GradeLevel.first,
        targetCompetency: MicroCompetencyId.wordProblemModel,
      );
      expect(
        equation.choices!.every(
          (choice) => !choice.contains('×') && !choice.contains('÷'),
        ),
        isTrue,
      );
    }
  });

  test('gezielte Modellierungsaufgaben respektieren kleine Zahlenräume', () {
    final generator = StructuredExerciseGenerator(random: Random(312));
    const targets = [
      MicroCompetencyId.wordProblemRelevantInformation,
      MicroCompetencyId.wordProblemOperation,
      MicroCompetencyId.wordProblemModel,
      MicroCompetencyId.wordProblemCalculation,
      MicroCompetencyId.wordProblemInterpretation,
    ];

    for (final maxValue in [10, 20, 100]) {
      for (final target in targets) {
        for (var i = 0; i < 30; i++) {
          final exercise = generator.generate(
            mode: TrainingMode.wordProblems,
            maxValue: maxValue,
            gradeLevel: GradeLevel.second,
            targetCompetency: target,
          );
          final numbers = RegExp(r'\d+')
              .allMatches(exercise.key)
              .map((match) => int.parse(match.group(0)!));

          expect(
            numbers.every((value) => value <= maxValue),
            isTrue,
            reason: '${target.name} / ${exercise.key} / $maxValue',
          );
          if (exercise.usesChoices) {
            expect(
              exercise.answer,
              inInclusiveRange(0, exercise.choices!.length - 1),
            );
          } else {
            expect(exercise.answer, inInclusiveRange(0, maxValue));
          }
        }
      }
    }
  });
  test('Darstellungswechsel ist gezielt generierbar und getrennt getaggt', () {
    final generator = StructuredExerciseGenerator(random: Random(401));
    final families = <String>{};

    for (var i = 0; i < 120; i++) {
      final exercise = generator.generate(
        mode: TrainingMode.wordProblems,
        maxValue: 100,
        gradeLevel: GradeLevel.second,
        targetCompetency: MicroCompetencyId.representationTranslation,
      );
      final tags = MicroCompetencyCatalog.tagsForTask(
        mode: TrainingMode.wordProblems,
        taskKey: exercise.key,
      );

      expect(exercise.key, startsWith('process:representation:'));
      expect(tags.first.id, MicroCompetencyId.representationTranslation);
      expect(exercise.choices, hasLength(4));
      expect(exercise.choices!.toSet(), hasLength(4));
      expect(exercise.answer, inInclusiveRange(0, 3));

      final parts = exercise.key.split(':');
      families.add(parts[2]);
      if (parts[2] == 'place' || parts[2] == 'decompose') {
        expect(exercise.representation, ExerciseRepresentation.placeValue);
        expect(exercise.representationA, isNotNull);
      } else if (parts[2] == 'groups') {
        expect(exercise.representation, ExerciseRepresentation.equalGroups);
        expect(exercise.representationA, isNotNull);
        expect(exercise.representationB, isNotNull);
      }
    }

    expect(families, containsAll(['place', 'decompose', 'groups', 'equation']));
  });

  test('Klasse 1 nutzt beim Darstellungswechsel nur Zahl und Stellenwert', () {
    final generator = StructuredExerciseGenerator(random: Random(402));

    for (var i = 0; i < 80; i++) {
      final exercise = generator.generate(
        mode: TrainingMode.wordProblems,
        maxValue: 20,
        gradeLevel: GradeLevel.first,
        targetCompetency: MicroCompetencyId.representationTranslation,
      );

      expect(
        exercise.key.startsWith('process:representation:place:') ||
            exercise.key.startsWith('process:representation:decompose:'),
        isTrue,
      );
      expect(exercise.representation, ExerciseRepresentation.placeValue);
      expect(
        exercise.choices!.every((choice) => !choice.contains('×')),
        isTrue,
      );
    }
  });

  test('Darstellungswechsel skaliert bis zum Millionenraum', () {
    final generator = StructuredExerciseGenerator(random: Random(403));

    for (final maxValue in [10, 20, 100, 1000, 1000000]) {
      for (var i = 0; i < 40; i++) {
        final exercise = generator.generate(
          mode: TrainingMode.wordProblems,
          maxValue: maxValue,
          gradeLevel: GradeLevel.fourth,
          targetCompetency: MicroCompetencyId.representationTranslation,
        );
        final numbers = RegExp(r'\d+')
            .allMatches(exercise.key)
            .map((match) => int.parse(match.group(0)!))
            .toList();

        expect(
          numbers.every((value) => value <= maxValue),
          isTrue,
          reason: '${exercise.key} / $maxValue',
        );
        expect(exercise.answer, inInclusiveRange(0, 3));
      }
    }
  });

}
