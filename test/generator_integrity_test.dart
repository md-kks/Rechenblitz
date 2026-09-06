import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/cube_net.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/german_number_words.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/widgets/geometry_relation_visual.dart';

void main() {
  test('deutsche Zahlwörter decken typische Stellenwerte bis 1 Million ab', () {
    expect(GermanNumberWords.spell(0), 'null');
    expect(GermanNumberWords.spell(1), 'eins');
    expect(GermanNumberWords.spell(21), 'einundzwanzig');
    expect(GermanNumberWords.spell(105), 'einhundertfünf');
    expect(GermanNumberWords.spell(342), 'dreihundertzweiundvierzig');
    expect(GermanNumberWords.spell(1000), 'eintausend');
    expect(GermanNumberWords.spell(1234), 'eintausendzweihundertvierunddreißig');
    expect(
      GermanNumberWords.spell(999999),
      'neunhundertneunundneunzigtausend'
      'neunhundertneunundneunzig',
    );
    expect(GermanNumberWords.spell(1000000), 'eine Million');
  });

  test('Würfelnetz-Validator erkennt gültige und ungültige Netze', () {
    const valid = [
      GridCell(1, 0),
      GridCell(0, 1),
      GridCell(1, 1),
      GridCell(2, 1),
      GridCell(3, 1),
      GridCell(1, 2),
    ];
    const invalid = [
      GridCell(0, 0),
      GridCell(1, 0),
      GridCell(2, 0),
      GridCell(0, 1),
      GridCell(1, 1),
      GridCell(2, 1),
    ];

    expect(CubeNetValidator.isFoldable(valid), isTrue);
    expect(CubeNetValidator.isFoldable(invalid), isFalse);
  });

  test('Würfelnetz-Generator klassifiziert jedes erzeugte Netz korrekt', () {
    final generator = CubeNetGenerator(random: Random(20260905));
    final seen = <String>{};

    for (var i = 0; i < 250; i++) {
      final pattern = generator.generate();
      expect(pattern.cells.toSet().length, 6);
      expect(
        CubeNetValidator.isFoldable(pattern.cells),
        pattern.foldable,
      );
      seen.add(pattern.key);
    }

    expect(seen.length, greaterThan(10));
  });

  test('neue Lehrplan-Ziele werden gezielt generiert und korrekt getaggt', () {
    final generator = CurriculumExerciseGenerator(random: Random(77));
    final cases = [
      (
        mode: TrainingMode.largeNumbers,
        id: MicroCompetencyId.largeNumberOrder,
        prefix: 'large:order:',
      ),
      (
        mode: TrainingMode.largeNumbers,
        id: MicroCompetencyId.numberWordReading,
        prefix: 'large:word:',
      ),
      (
        mode: TrainingMode.probability,
        id: MicroCompetencyId.probabilityExperiment,
        prefix: 'prob:experiment:',
      ),
      (
        mode: TrainingMode.geometryBodies,
        id: MicroCompetencyId.cubeNetFoldability,
        prefix: 'body:cube-net:fold:',
      ),
    ];

    for (final item in cases) {
      final exercise = generator.generate(
        mode: item.mode,
        gradeLevel: GradeLevel.fourth,
        maxValue: 1000000,
        targetCompetency: item.id,
      );
      final tags = MicroCompetencyCatalog.tagsForTask(
        mode: item.mode,
        taskKey: exercise.key,
      );

      expect(exercise.key, startsWith(item.prefix));
      expect(tags.map((tag) => tag.id), contains(item.id));
      expect(exercise.usesChoices, isTrue);
      expect(
        exercise.answer,
        inInclusiveRange(0, exercise.choices!.length - 1),
      );
      if (item.id == MicroCompetencyId.cubeNetFoldability) {
        expect(exercise.hasCubeNet, isTrue);
        expect(
          CubeNetValidator.isFoldable(exercise.cubeNetCells!),
          exercise.answer == 0,
        );
      }
    }
  });

  test('Geraden-Winkel-Lernziele sind gezielt generierbar und getaggt', () {
    final generator = CurriculumExerciseGenerator(random: Random(8804));
    const cases = [
      (
        id: MicroCompetencyId.lineRelations,
        prefix: 'geomrel:lines:',
      ),
      (
        id: MicroCompetencyId.rightAngle,
        prefix: 'geomrel:angle:',
      ),
      (
        id: MicroCompetencyId.figureClassification,
        prefix: 'geomrel:figure:',
      ),
      (
        id: MicroCompetencyId.circleParts,
        prefix: 'geomrel:circle:',
      ),
    ];

    for (final item in cases) {
      final exercise = generator.generate(
        mode: TrainingMode.geometryRelations,
        gradeLevel: GradeLevel.third,
        maxValue: 1000,
        targetCompetency: item.id,
      );
      final tags = MicroCompetencyCatalog.tagsForTask(
        mode: TrainingMode.geometryRelations,
        taskKey: exercise.key,
      );

      expect(exercise.key, startsWith(item.prefix));
      expect(exercise.usesChoices, isTrue);
      expect(tags.map((tag) => tag.id), contains(item.id));
      expect(
        exercise.answer,
        inInclusiveRange(0, exercise.choices!.length - 1),
      );
    }
  });

  test('Zeit- und Daten-Lernziele sind gezielt generierbar und getaggt', () {
    final generator = CurriculumExerciseGenerator(random: Random(9912));
    const cases = [
      (
        mode: TrainingMode.advancedMeasures,
        id: MicroCompetencyId.secondsConversion,
        prefix: 'time:seconds:',
      ),
      (
        mode: TrainingMode.timeDurations,
        id: MicroCompetencyId.calendarDate,
        prefix: 'calendar:',
      ),
      (
        mode: TrainingMode.dataCharts,
        id: MicroCompetencyId.tallyTableReading,
        prefix: 'data:tally:',
      ),
      (
        mode: TrainingMode.dataCharts,
        id: MicroCompetencyId.dataRepresentationChoice,
        prefix: 'data:representation:',
      ),
    ];

    for (final item in cases) {
      final exercise = generator.generate(
        mode: item.mode,
        gradeLevel: GradeLevel.third,
        maxValue: 1000,
        targetCompetency: item.id,
      );
      final tags = MicroCompetencyCatalog.tagsForTask(
        mode: item.mode,
        taskKey: exercise.key,
      );

      expect(exercise.key, startsWith(item.prefix));
      expect(tags.map((tag) => tag.id), contains(item.id));
      if (exercise.usesChoices) {
        expect(
          exercise.answer,
          inInclusiveRange(0, exercise.choices!.length - 1),
        );
        expect(exercise.choices!.toSet().length, exercise.choices!.length);
      } else {
        expect(exercise.answer, greaterThanOrEqualTo(0));
      }
    }
  });

  test('Gezielte Einheitenumrechnung bleibt von Sekunden-Aufgaben getrennt',
      () {
    final generator = CurriculumExerciseGenerator(random: Random(99118));

    for (final grade in [
      GradeLevel.second,
      GradeLevel.third,
      GradeLevel.fourth,
    ]) {
      for (var i = 0; i < 60; i++) {
        final exercise = generator.generate(
          mode: TrainingMode.advancedMeasures,
          gradeLevel: grade,
          maxValue: grade.recommendedRange.maxValue,
          targetCompetency: MicroCompetencyId.unitConversion,
        );
        final tags = MicroCompetencyCatalog.tagsForTask(
          mode: TrainingMode.advancedMeasures,
          taskKey: exercise.key,
        );

        expect(exercise.key, isNot(startsWith('time:seconds:')));
        expect(
          tags.map((tag) => tag.id),
          contains(MicroCompetencyId.unitConversion),
        );
        expect(
          tags.map((tag) => tag.id),
          isNot(contains(MicroCompetencyId.secondsConversion)),
        );

        final value = int.tryParse(exercise.key.split(':').last);
        expect(value, isNotNull, reason: exercise.key);
        expect(value!, greaterThan(1), reason: exercise.key);
      }
    }
  });

  test('Gezielte Sekundenumrechnung bleibt auf secondsConversion', () {
    final generator = CurriculumExerciseGenerator(random: Random(991181));

    for (final grade in [GradeLevel.third, GradeLevel.fourth]) {
      for (var i = 0; i < 40; i++) {
        final exercise = generator.generate(
          mode: TrainingMode.advancedMeasures,
          gradeLevel: grade,
          maxValue: grade.recommendedRange.maxValue,
          targetCompetency: MicroCompetencyId.secondsConversion,
        );
        final tags = MicroCompetencyCatalog.tagsForTask(
          mode: TrainingMode.advancedMeasures,
          taskKey: exercise.key,
        );

        expect(exercise.key, startsWith('time:seconds:'));
        expect(
          tags.map((tag) => tag.id),
          contains(MicroCompetencyId.secondsConversion),
        );
        expect(
          tags.map((tag) => tag.id),
          isNot(contains(MicroCompetencyId.unitConversion)),
        );
      }
    }
  });

  test('Gezielte Zahlenvergleiche erzwingen eine spätere Entscheidungsstelle',
      () {
    final generator = CurriculumExerciseGenerator(random: Random(99119));

    int highestPlace(int value) {
      var place = 1;
      var current = value;
      while (current >= 10) {
        place *= 10;
        current ~/= 10;
      }
      return place;
    }

    int firstDifferentPlace(int a, int b) {
      var place = highestPlace(max(a, b));
      while (place > 1 && (a ~/ place) % 10 == (b ~/ place) % 10) {
        place ~/= 10;
      }
      return place;
    }

    for (final grade in [GradeLevel.third, GradeLevel.fourth]) {
      for (var i = 0; i < 60; i++) {
        final exercise = generator.generate(
          mode: TrainingMode.largeNumbers,
          gradeLevel: grade,
          maxValue: grade == GradeLevel.third ? 1000 : 1000000,
          targetCompetency: MicroCompetencyId.largeNumberCompare,
        );
        final parts = exercise.key.split(':');

        expect(parts, hasLength(4));
        expect(parts[0], 'large');
        expect(parts[1], 'compare');
        expect(exercise.choices, ['<', '>', '=']);

        final a = int.parse(parts[2]);
        final b = int.parse(parts[3]);
        final highest = highestPlace(max(a, b));
        final deciding = firstDifferentPlace(a, b);

        expect(a, isNot(b));
        expect(deciding, lessThan(highest));
        expect(
          (a ~/ highest) % 10,
          (b ~/ highest) % 10,
          reason: exercise.key,
        );
        expect(
          exercise.answer,
          a < b ? 0 : 1,
          reason: exercise.key,
        );

        final tags = MicroCompetencyCatalog.tagsForTask(
          mode: TrainingMode.largeNumbers,
          taskKey: exercise.key,
        );
        expect(
          tags.map((tag) => tag.id),
          contains(MicroCompetencyId.largeNumberCompare),
        );
      }
    }
  });

  test('Gezielte Bruchaufgaben trennen einen Teil vom Endanteil', () {
    final generator = CurriculumExerciseGenerator(random: Random(99120));

    for (final grade in [GradeLevel.third, GradeLevel.fourth]) {
      for (var i = 0; i < 40; i++) {
        final exercise = generator.generate(
          mode: TrainingMode.fractions,
          gradeLevel: grade,
          maxValue: grade == GradeLevel.third ? 1000 : 1000000,
          targetCompetency: MicroCompetencyId.fractionEqualParts,
        );
        final parts = exercise.key.split(':');

        expect(parts, hasLength(5));
        expect(parts[0], 'fraction');
        expect(parts[1], 'parts');

        final numerator = int.parse(parts[2]);
        final denominator = int.parse(parts[3]);
        final whole = int.parse(parts[4]);
        final partSize = whole ~/ denominator;

        expect(denominator, 4);
        expect(numerator, isIn([2, 3]));
        expect(whole % denominator, 0);
        expect(exercise.answer, numerator * partSize);
        expect(exercise.answer, isNot(partSize));
        expect(exercise.hint, contains('$denominator gleich große Teile'));

        final tags = MicroCompetencyCatalog.tagsForTask(
          mode: TrainingMode.fractions,
          taskKey: exercise.key,
        );
        expect(
          tags.map((tag) => tag.id),
          contains(MicroCompetencyId.fractionEqualParts),
        );
      }
    }
  });

  test('Gezielte Zeitspannen enthalten immer einen echten Stundenübergang',
      () {
    final generator = CurriculumExerciseGenerator(random: Random(99121));

    for (final grade in [GradeLevel.third, GradeLevel.fourth]) {
      for (var i = 0; i < 40; i++) {
        final exercise = generator.generate(
          mode: TrainingMode.timeDurations,
          gradeLevel: grade,
          maxValue: grade == GradeLevel.third ? 1000 : 1000000,
          targetCompetency: MicroCompetencyId.timeDuration,
        );
        final parts = exercise.key.split(':');
        expect(parts, hasLength(3));
        expect(parts.first, 'duration');

        final start = int.parse(parts[1]);
        final duration = int.parse(parts[2]);
        final minute = start % 60;
        final minutesToNextHour = 60 - minute;

        expect(minute, isIn([15, 30, 45]));
        expect(duration, greaterThan(minutesToNextHour));
        expect(exercise.hint, contains('$minutesToNextHour Minuten'));

        final tags = MicroCompetencyCatalog.tagsForTask(
          mode: TrainingMode.timeDurations,
          taskKey: exercise.key,
        );
        expect(
          tags.map((tag) => tag.id),
          contains(MicroCompetencyId.timeDuration),
        );
      }
    }
  });

  testWidgets('Geometrie-Darstellungen rendern alle vier Aufgabentypen',
      (tester) async {
    const keys = [
      'geomrel:lines:parallel:third',
      'geomrel:lines:perpendicular:third',
      'geomrel:angle:right:paper:third',
      'geomrel:figure:2:third',
      'geomrel:circle:radius:third',
      'geomrel:circle:diameter:third',
    ];

    for (final key in keys) {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeometryRelationVisual(taskKey: key),
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: key);
      expect(find.byType(CustomPaint), findsWidgets);
    }
  });

  test('automatischer Oberstufen-Generator-Audit prüft tausende Aufgaben', () {
    final generator = CurriculumExerciseGenerator(random: Random(123456));
    var generated = 0;

    for (final grade in [GradeLevel.third, GradeLevel.fourth]) {
      final range = grade == GradeLevel.third ? 1000 : 1000000;
      for (final mode
          in TrainingMode.values.where((mode) => mode.isUpperPrimary)) {
        for (var i = 0; i < 80; i++) {
          final exercise = generator.generate(
            mode: mode,
            gradeLevel: grade,
            maxValue: range,
          );

          expect(
            exercise.key,
            isNotEmpty,
            reason: '${grade.name}/${mode.name}',
          );
          expect(exercise.prompt.trim(), isNotEmpty);
          expect(exercise.hint.trim(), isNotEmpty);

          if (exercise.usesChoices) {
            expect(exercise.choices!.length, greaterThanOrEqualTo(2));
            expect(
              exercise.answer,
              inInclusiveRange(0, exercise.choices!.length - 1),
              reason: '${grade.name}/${mode.name}/${exercise.key}',
            );
            expect(
              exercise.choices!.toSet().length,
              exercise.choices!.length,
              reason: 'Doppelte Auswahl: ${exercise.key}',
            );
          } else {
            expect(exercise.answer, greaterThanOrEqualTo(0));
            if (exercise.maxAnswerValue != null) {
              expect(
                exercise.answer,
                lessThanOrEqualTo(exercise.maxAnswerValue!),
                reason: '${grade.name}/${mode.name}/${exercise.key}',
              );
            }
          }

          if (exercise.hasCubeNet) {
            expect(exercise.cubeNetCells!.toSet().length, 6);
            expect(
              CubeNetValidator.isFoldable(exercise.cubeNetCells!),
              exercise.answer == 0,
            );
          }

          generated += 1;
        }
      }
    }

    expect(generated, greaterThan(3000));
  });
}
