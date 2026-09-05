import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/cube_net.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/german_number_words.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/training.dart';

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
