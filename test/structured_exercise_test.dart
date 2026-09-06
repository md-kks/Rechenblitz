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


  test('Gezielte Zahlenmauern prüfen zuerst Plus nach oben oder Minus rückwärts',
      () {
    final generator = StructuredExerciseGenerator(random: Random(721));
    final directions = <String>{};

    for (final maxValue in [10, 20, 100]) {
      for (var i = 0; i < 100; i++) {
        final exercise = generator.generate(
          mode: TrainingMode.numberWall,
          maxValue: maxValue,
          gradeLevel: GradeLevel.first,
          targetCompetency: MicroCompetencyId.numberRelations,
        );

        final values = exercise.wallValues!;
        final hidden = exercise.hiddenWallIndex!;
        final checkpoint = exercise.checkpoints.single;
        final addition = hidden >= 3;
        directions.add(addition ? 'up' : 'down');

        expect(values, hasLength(6));
        expect(values.take(3).every((value) => value > 0), isTrue);
        expect(values[3], values[0] + values[1]);
        expect(values[4], values[1] + values[2]);
        expect(values[5], values[3] + values[4]);
        expect(values[5], lessThanOrEqualTo(maxValue));
        expect(exercise.answer, values[hidden]);
        expect(checkpoint.key, 'wallOperationChoice');
        expect(
          checkpoint.competencyId,
          MicroCompetencyId.numberRelations,
        );
        expect(checkpoint.evidenceWeight, 0.40);
        expect(checkpoint.choices.toSet(), {'Plus (+)', 'Minus (−)'});
        expect(
          checkpoint.choices[checkpoint.correctChoice],
          addition ? 'Plus (+)' : 'Minus (−)',
        );
      }
    }

    expect(directions, {'up', 'down'});
  });

  test('Normales Zahlenmauer-Training bleibt ohne Pflicht-Checkpoint', () {
    final generator = StructuredExerciseGenerator(random: Random(722));

    for (var i = 0; i < 80; i++) {
      final exercise = generator.generate(
        mode: TrainingMode.numberWall,
        maxValue: 20,
        gradeLevel: GradeLevel.first,
      );
      expect(exercise.checkpoints, isEmpty, reason: exercise.key);
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

  test('Gezielte Zahlenfolgen prüfen Richtung und Schrittweite getrennt', () {
    final generator = StructuredExerciseGenerator(random: Random(174));

    for (final maxValue in [10, 20, 100]) {
      for (var i = 0; i < 80; i++) {
        final exercise = generator.generate(
          mode: TrainingMode.sequences,
          maxValue: maxValue,
          gradeLevel: GradeLevel.first,
          targetCompetency: MicroCompetencyId.numberPatterns,
        );
        final parts = exercise.key.split(':');
        final direction = parts[1];
        final start = int.parse(parts[2]);
        final step = int.parse(parts[3]);
        final checkpoint = exercise.checkpoints.single;
        final correctRule = direction == '-'
            ? 'immer −$step'
            : 'immer +$step';

        expect(exercise.key, startsWith('sequence:'));
        expect(exercise.checkpoints, hasLength(1));
        expect(checkpoint.key, 'sequenceStepSize');
        expect(checkpoint.competencyId, MicroCompetencyId.numberPatterns);
        expect(checkpoint.evidenceWeight, 0.40);
        expect(checkpoint.choices, hasLength(4));
        expect(checkpoint.choices.toSet(), hasLength(4));
        expect(
          checkpoint.choices[checkpoint.correctChoice],
          correctRule,
          reason: exercise.key,
        );

        if (direction == '-') {
          expect(exercise.answer, start - step * 3);
        } else {
          expect(direction, '+');
          expect(exercise.answer, start + step * 3);
        }
      }
    }
  });

  test('Normales Folgentraining bleibt ohne Pflicht-Checkpoint', () {
    final generator = StructuredExerciseGenerator(random: Random(175));

    for (var i = 0; i < 40; i++) {
      final exercise = generator.generate(
        mode: TrainingMode.sequences,
        maxValue: 20,
        gradeLevel: GradeLevel.first,
      );
      expect(exercise.checkpoints, isEmpty);
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

  test('Gezieltes Uhrlesen prüft zuerst den langen Minutenzeiger', () {
    final gradeOne = StructuredExerciseGenerator(random: Random(171));
    for (var i = 0; i < 40; i++) {
      final exercise = gradeOne.generate(
        mode: TrainingMode.clock,
        maxValue: 20,
        gradeLevel: GradeLevel.first,
        targetCompetency: MicroCompetencyId.clockReading,
      );

      expect(exercise.key, startsWith('clock:'));
      expect(exercise.clockMinute, 30);
      expect(exercise.checkpoints, hasLength(1));
      final checkpoint = exercise.checkpoints.single;
      expect(checkpoint.key, 'minuteHandMinutes');
      expect(checkpoint.competencyId, MicroCompetencyId.clockReading);
      expect(checkpoint.evidenceWeight, 0.40);
      expect(checkpoint.choices, ['0 Minuten', '30 Minuten']);
      expect(checkpoint.choices[checkpoint.correctChoice], '30 Minuten');
    }

    final upper = StructuredExerciseGenerator(random: Random(172));
    for (var i = 0; i < 80; i++) {
      final exercise = upper.generate(
        mode: TrainingMode.clock,
        maxValue: 100,
        gradeLevel: GradeLevel.second,
        targetCompetency: MicroCompetencyId.clockReading,
      );
      final checkpoint = exercise.checkpoints.single;

      expect(exercise.clockMinute, isIn([15, 30, 45]));
      expect(exercise.clockMinute, isNot(0));
      expect(
        checkpoint.choices[checkpoint.correctChoice],
        '${exercise.clockMinute} Minuten',
      );
      expect(
        checkpoint.choices,
        exercise.clockMinute == 30
            ? ['0 Minuten', '30 Minuten']
            : ['0 Minuten', '15 Minuten', '30 Minuten', '45 Minuten'],
      );
    }
  });

  test('Normales Uhrtraining bleibt ohne zusätzlichen Pflicht-Checkpoint', () {
    final generator = StructuredExerciseGenerator(random: Random(173));

    for (var i = 0; i < 30; i++) {
      final exercise = generator.generate(
        mode: TrainingMode.clock,
        maxValue: 20,
        gradeLevel: GradeLevel.first,
      );
      expect(exercise.checkpoints, isEmpty);
    }
  });


  test('Gezielte Längenaufgaben prüfen zuerst die passende Rechenart', () {
    final generator = StructuredExerciseGenerator(random: Random(731));
    final families = <String>{};

    for (final maxValue in [10, 20, 100]) {
      for (var i = 0; i < 100; i++) {
        final exercise = generator.generate(
          mode: TrainingMode.measures,
          maxValue: maxValue,
          gradeLevel: GradeLevel.first,
          targetCompetency: MicroCompetencyId.measurementCalculation,
        );
        final parts = exercise.key.split(':');
        final family = parts[1];
        final first = int.parse(parts[parts.length - 2]);
        final second = int.parse(parts.last);
        final checkpoint = exercise.checkpoints.single;

        families.add(family);
        expect(family, isIn(['add', 'subtract']));
        expect(first, greaterThan(0));
        expect(second, greaterThan(0));
        expect(exercise.prompt, isNot(contains(' + ')));
        expect(exercise.prompt, isNot(contains(' − ')));
        expect(exercise.answerSuffix, 'cm');
        expect(checkpoint.key, 'measureOperationChoice');
        expect(
          checkpoint.competencyId,
          MicroCompetencyId.measurementCalculation,
        );
        expect(checkpoint.evidenceWeight, 0.40);
        expect(checkpoint.choices.toSet(), {'Plus (+)', 'Minus (−)'});

        if (family == 'add') {
          expect(first + second, lessThanOrEqualTo(maxValue));
          expect(exercise.answer, first + second);
          expect(
            checkpoint.choices[checkpoint.correctChoice],
            'Plus (+)',
          );
        } else {
          expect(first, greaterThan(second));
          expect(exercise.answer, first - second);
          expect(
            checkpoint.choices[checkpoint.correctChoice],
            'Minus (−)',
          );
        }
      }
    }

    expect(families, {'add', 'subtract'});
  });

  test('Normales Maßtraining bleibt ohne Pflicht-Checkpoint', () {
    final generator = StructuredExerciseGenerator(random: Random(732));

    for (var i = 0; i < 120; i++) {
      final exercise = generator.generate(
        mode: TrainingMode.measures,
        maxValue: 100,
        gradeLevel: GradeLevel.second,
      );
      expect(exercise.checkpoints, isEmpty, reason: exercise.key);
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

  test('Grundrechenarten wechseln im Transfer in Sachkontexte', () {
    final generator = StructuredExerciseGenerator(random: Random(501));
    const targets = [
      MicroCompetencyId.additionNoBridge,
      MicroCompetencyId.additionTenBridge,
      MicroCompetencyId.subtractionNoBridge,
      MicroCompetencyId.subtractionTenBridge,
      MicroCompetencyId.multiplicationGroups,
      MicroCompetencyId.multiplicationFacts,
      MicroCompetencyId.divisionSharing,
      MicroCompetencyId.divisionFacts,
    ];

    for (final maxValue in [10, 20, 100]) {
      for (final target in targets) {
        for (var i = 0; i < 25; i++) {
          final exercise = generator.generate(
            mode: TrainingMode.wordProblems,
            maxValue: maxValue,
            gradeLevel: GradeLevel.second,
            targetCompetency: target,
            transferEmphasis: true,
          );
          final tags = MicroCompetencyCatalog.tagsForTask(
            mode: TrainingMode.wordProblems,
            taskKey: exercise.key,
          );

          expect(
            exercise.key,
            startsWith('story:transfer:skill:${target.name}:'),
          );
          expect(tags.first.id, target);
          expect(exercise.answer, inInclusiveRange(0, maxValue));

          final parts = exercise.key.split(':');
          final operation = parts[4];
          final a = int.parse(parts[6]);
          final b = int.parse(parts[7]);
          if (target == MicroCompetencyId.additionTenBridge) {
            expect((a % 10) + (b % 10), greaterThanOrEqualTo(10));
          }
          if (target == MicroCompetencyId.additionNoBridge) {
            expect((a % 10) + (b % 10), lessThan(10));
          }
          if (target == MicroCompetencyId.subtractionTenBridge) {
            expect(a % 10, lessThan(b % 10));
          }
          if (target == MicroCompetencyId.subtractionNoBridge) {
            expect(a % 10, greaterThanOrEqualTo(b % 10));
          }
          if (operation == 'x') {
            expect(a * b, exercise.answer);
          }
          if (operation == 'divide') {
            expect(a % b, 0);
            expect(a ~/ b, exercise.answer);
          }
        }
      }
    }
  });


  test('Darstellungswechsel erzeugt eigenständige Repräsentationsschritte', () {
    final generator = StructuredExerciseGenerator(random: Random(404));
    final families = <String>{};

    for (var i = 0; i < 160; i++) {
      final exercise = generator.generate(
        mode: TrainingMode.wordProblems,
        maxValue: 100,
        gradeLevel: GradeLevel.second,
        targetCompetency: MicroCompetencyId.representationTranslation,
      );
      final family = exercise.key.split(':')[2];
      families.add(family);

      expect(exercise.hasCheckpoints, isTrue, reason: exercise.key);
      for (final checkpoint in exercise.checkpoints) {
        expect(checkpoint.choices, hasLength(4));
        expect(checkpoint.choices.toSet(), hasLength(4));
        expect(
          checkpoint.correctChoice,
          inInclusiveRange(0, checkpoint.choices.length - 1),
        );
        expect(checkpoint.evidenceWeight, inInclusiveRange(0.25, 0.50));
      }

      if (family == 'place' || family == 'decompose') {
        expect(exercise.checkpoints, hasLength(1));
        expect(
          exercise.checkpoints.single.competencyId,
          MicroCompetencyId.placeValueDigits,
        );
        expect(
          exercise.checkpoints.single.key == 'onesDigit' ||
              exercise.checkpoints.single.key.startsWith('placeDigit_'),
          isTrue,
        );
      } else {
        expect(exercise.checkpoints, hasLength(2));
        expect(
          exercise.checkpoints.every(
            (checkpoint) =>
                checkpoint.competencyId ==
                MicroCompetencyId.multiplicationGroups,
          ),
          isTrue,
        );
        expect(
          exercise.checkpoints.map((checkpoint) => checkpoint.key).toSet(),
          {'groupCount', 'itemsPerGroup'},
        );
      }
    }

    expect(families, containsAll(['place', 'decompose', 'groups', 'equation']));
  });

  test('Klasse 1 bekommt nur Stellenwert-Teilfragen', () {
    final generator = StructuredExerciseGenerator(random: Random(405));

    for (var i = 0; i < 80; i++) {
      final exercise = generator.generate(
        mode: TrainingMode.wordProblems,
        maxValue: 20,
        gradeLevel: GradeLevel.first,
        targetCompetency: MicroCompetencyId.representationTranslation,
      );

      expect(exercise.checkpoints, hasLength(1));
      expect(
        exercise.checkpoints.single.competencyId,
        MicroCompetencyId.placeValueDigits,
      );
      expect(
        exercise.checkpoints.single.question,
        contains('Welche Ziffer'),
      );
    }
  });



  test('Teilen trainiert Verteilen und Gruppieren mit eigenem Verständnis',
      () {
    final generator = StructuredExerciseGenerator(random: Random(319));
    final meanings = <String>{};

    for (final maxValue in [20, 100]) {
      for (var i = 0; i < 80; i++) {
        final exercise = generator.generate(
          mode: TrainingMode.wordProblems,
          maxValue: maxValue,
          gradeLevel: GradeLevel.second,
          targetCompetency: MicroCompetencyId.divisionSharing,
        );
        final tags = MicroCompetencyCatalog.tagsForTask(
          mode: TrainingMode.wordProblems,
          taskKey: exercise.key,
        );
        final parts = exercise.key.split(':');
        final meaning = parts[1];
        meanings.add(meaning);
        final total = int.parse(parts[3]);
        final divisor = int.parse(parts[4]);

        expect(
          meaning == 'sharing' || meaning == 'grouping',
          isTrue,
          reason: exercise.key,
        );
        expect(tags.first.id, MicroCompetencyId.divisionSharing);
        expect(
          tags.map((tag) => tag.id),
          contains(MicroCompetencyId.divisionFacts),
        );
        expect(exercise.answer, total ~/ divisor);
        expect(exercise.answer, inInclusiveRange(0, maxValue));
        expect(exercise.checkpoints, hasLength(1));
        final checkpoint = exercise.checkpoints.single;
        expect(checkpoint.key, 'divisionTargetQuantity');
        expect(
          checkpoint.competencyId,
          MicroCompetencyId.divisionSharing,
        );
        expect(checkpoint.choices, hasLength(3));
        expect(
          checkpoint.correctChoice,
          meaning == 'sharing' ? 1 : 0,
          reason: exercise.key,
        );
      }
    }

    expect(meanings, {'sharing', 'grouping'});
  });


  test('fokussierte Sachaufgaben deklarieren genau ihren Modellierungsschritt',
      () {
    final generator = StructuredExerciseGenerator(random: Random(620));
    const cases = [
      (
        competency: MicroCompetencyId.wordProblemRelevantInformation,
        key: 'storyInfo',
      ),
      (
        competency: MicroCompetencyId.wordProblemOperation,
        key: 'storyOperation',
      ),
      (
        competency: MicroCompetencyId.wordProblemModel,
        key: 'storyEquation',
      ),
      (
        competency: MicroCompetencyId.wordProblemCalculation,
        key: 'storyCalculation',
      ),
      (
        competency: MicroCompetencyId.wordProblemInterpretation,
        key: 'storyInterpretation',
      ),
    ];

    for (final item in cases) {
      for (var i = 0; i < 20; i++) {
        final exercise = generator.generate(
          mode: TrainingMode.wordProblems,
          maxValue: 20,
          gradeLevel: GradeLevel.first,
          targetCompetency: item.competency,
        );

        expect(exercise.hasDirectIndependentStep, isTrue,
            reason: item.competency.name);
        expect(exercise.directIndependentStepKey, item.key,
            reason: exercise.key);
        expect(exercise.directIndependentStepCompetency, item.competency,
            reason: exercise.key);
      }
    }
  });

  test('normale und Transfer-Sachaufgaben erzeugen keine direkte Step-Evidenz',
      () {
    final generator = StructuredExerciseGenerator(random: Random(621));

    for (var i = 0; i < 40; i++) {
      final normal = generator.generate(
        mode: TrainingMode.wordProblems,
        maxValue: 100,
        gradeLevel: GradeLevel.second,
      );
      expect(normal.hasDirectIndependentStep, isFalse, reason: normal.key);

      final transfer = generator.generate(
        mode: TrainingMode.wordProblems,
        maxValue: 100,
        gradeLevel: GradeLevel.second,
        targetCompetency: MicroCompetencyId.additionTenBridge,
        transferEmphasis: true,
      );
      expect(
        transfer.hasDirectIndependentStep,
        isFalse,
        reason: transfer.key,
      );
    }
  });

  test('Gezielte Umkehraufgaben Klasse 1 verraten Minus nicht vor dem Step',
      () {
    final generator = StructuredExerciseGenerator(random: Random(701));

    for (var i = 0; i < 80; i++) {
      final exercise = generator.generate(
        mode: TrainingMode.factFamilies,
        maxValue: 20,
        gradeLevel: GradeLevel.first,
        targetCompetency: MicroCompetencyId.inverseRelationship,
      );
      final parts = exercise.key.split(':');
      final a = int.parse(parts[2]);
      final b = int.parse(parts[3]);

      expect(exercise.key, startsWith('family:+:'));
      expect(a, greaterThanOrEqualTo(1));
      expect(b, greaterThanOrEqualTo(1));
      expect(a + b, lessThanOrEqualTo(20));
      expect(exercise.answer, a);
      expect(exercise.prompt, isNot(contains('−')));
      expect(exercise.prompt, isNot(contains('÷')));
      expect(exercise.checkpoints, hasLength(1));

      final checkpoint = exercise.checkpoints.single;
      expect(checkpoint.key, 'inverseOperationChoice');
      expect(
        checkpoint.competencyId,
        MicroCompetencyId.inverseRelationship,
      );
      expect(checkpoint.evidenceWeight, 0.40);
      expect(checkpoint.choices.toSet(), {'+$b', '−$b'});
      expect(
        checkpoint.choices[checkpoint.correctChoice],
        '−$b',
      );
    }
  });

  test('Gezielte Umkehraufgaben Klasse 2 trennen Plus-Minus und Mal-Teilen',
      () {
    final generator = StructuredExerciseGenerator(random: Random(702));
    final families = <String>{};

    for (var i = 0; i < 160; i++) {
      final exercise = generator.generate(
        mode: TrainingMode.factFamilies,
        maxValue: 100,
        gradeLevel: GradeLevel.second,
        targetCompetency: MicroCompetencyId.inverseRelationship,
      );
      final parts = exercise.key.split(':');
      final family = parts[1];
      final a = int.parse(parts[2]);
      final b = int.parse(parts[3]);
      families.add(family);

      expect(exercise.checkpoints, hasLength(1));
      final checkpoint = exercise.checkpoints.single;
      expect(checkpoint.key, 'inverseOperationChoice');
      expect(checkpoint.choices, hasLength(4));
      expect(checkpoint.choices.toSet(), hasLength(4));
      expect(exercise.answer, a);

      if (family == 'x') {
        expect(a, greaterThanOrEqualTo(2));
        expect(b, greaterThanOrEqualTo(2));
        expect(a * b, lessThanOrEqualTo(100));
        expect(exercise.prompt, isNot(contains('÷')));
        expect(
          checkpoint.choices[checkpoint.correctChoice],
          '÷$b',
        );
      } else {
        expect(family, '+');
        expect(a + b, lessThanOrEqualTo(100));
        expect(exercise.prompt, isNot(contains('−')));
        expect(
          checkpoint.choices[checkpoint.correctChoice],
          '−$b',
        );
      }
    }

    expect(families, containsAll(['+', 'x']));
  });

  test('Normales Umkehraufgaben-Training bleibt ohne Pflicht-Checkpoint', () {
    final generator = StructuredExerciseGenerator(random: Random(703));

    for (var i = 0; i < 50; i++) {
      final exercise = generator.generate(
        mode: TrainingMode.factFamilies,
        maxValue: 100,
        gradeLevel: GradeLevel.second,
      );
      expect(exercise.checkpoints, isEmpty, reason: exercise.key);
    }
  });


  test('Gezielte Geldaufgaben prüfen zuerst den Rechenplan', () {
    final generator = StructuredExerciseGenerator(random: Random(711));
    final families = <String>{};

    for (var i = 0; i < 140; i++) {
      final exercise = generator.generate(
        mode: TrainingMode.money,
        maxValue: 20,
        gradeLevel: GradeLevel.first,
        targetCompetency: MicroCompetencyId.moneyCalculation,
      );
      final parts = exercise.key.split(':');
      final family = parts[1];
      final first = int.parse(parts[parts.length - 2]);
      final second = int.parse(parts.last);
      families.add(family);

      expect(
        family == 'add' || family == 'change' || family == 'missing',
        isTrue,
        reason: exercise.key,
      );
      expect(first, greaterThanOrEqualTo(1));
      expect(second, greaterThanOrEqualTo(1));
      expect(exercise.prompt, isNot(contains(' + ')));
      expect(exercise.prompt, isNot(contains(' − ')));
      expect(exercise.checkpoints, hasLength(1));

      final checkpoint = exercise.checkpoints.single;
      expect(checkpoint.key, 'moneyOperationChoice');
      expect(
        checkpoint.competencyId,
        MicroCompetencyId.moneyCalculation,
      );
      expect(checkpoint.evidenceWeight, 0.40);
      expect(checkpoint.choices.toSet(), {'Plus (+)', 'Minus (−)'});

      if (family == 'add') {
        expect(first + second, lessThanOrEqualTo(20));
        expect(exercise.answer, first + second);
        expect(
          checkpoint.choices[checkpoint.correctChoice],
          'Plus (+)',
        );
      } else {
        expect(first, greaterThan(second));
        expect(exercise.answer, first - second);
        expect(
          checkpoint.choices[checkpoint.correctChoice],
          'Minus (−)',
        );
      }
    }

    expect(families, containsAll(['add', 'change', 'missing']));
  });

  test('Normales Geldtraining bleibt ohne Pflicht-Checkpoint', () {
    final generator = StructuredExerciseGenerator(random: Random(712));

    for (var i = 0; i < 100; i++) {
      final exercise = generator.generate(
        mode: TrainingMode.money,
        maxValue: 100,
        gradeLevel: GradeLevel.second,
      );
      expect(exercise.checkpoints, isEmpty, reason: exercise.key);
    }
  });


}
