import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/structured_exercise.dart';
import 'package:rechenblitz/models/touch_interaction.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/app_controller.dart';

void _checkCommon({
  required String owner,
  required String prompt,
  required String hint,
  required String key,
  required int answer,
  required int maxValue,
  required List<String>? choices,
  required List<String> failures,
}) {
  if (prompt.trim().isEmpty) failures.add('$owner: empty prompt');
  if (hint.trim().isEmpty) failures.add('$owner: empty hint');
  if (key.trim().isEmpty) failures.add('$owner: empty key');
  if (choices != null && choices.isNotEmpty) {
    if (answer < 0 || answer >= choices.length) {
      failures.add(
        '$owner: choice answer=$answer len=${choices.length} key=$key',
      );
    }
    if (choices.any((c) => c.trim().isEmpty)) {
      failures.add('$owner: empty choice key=$key choices=$choices');
    }
    if (choices.toSet().length != choices.length) {
      failures.add('$owner: duplicate choices key=$key choices=$choices');
    }
  } else if (answer < 0 || answer > maxValue) {
    failures.add('$owner: answer=$answer max=$maxValue key=$key');
  }
}

void main() {
  test('audit all targeted generated task contracts', () {
    final controller = AppController();
    final failures = <String>[];

    for (final definition in MicroCompetencyCatalog.definitions) {
      final grade = definition.minGrade;
      final range = NumberRangeLevel.values.firstWhere(
        (value) =>
            value.index >= grade.recommendedRange.index &&
            value.index >= definition.minNumberRange.index,
      );
      final maxValue = range.maxValue;
      final transferMode = controller.transferModeFor(definition.id);

      for (final transfer in <bool>[false, true]) {
        final mode = transfer ? transferMode : definition.preferredMode;
        for (var seed = 0; seed < 96; seed++) {
          final owner = '${definition.id.name}/${transfer ? "T" : "N"}/$seed';
          if (mode.isUpperPrimary) {
            final task =
                CurriculumExerciseGenerator(
                  random: Random(
                    710000 +
                        definition.id.index * 1000 +
                        seed +
                        (transfer ? 500 : 0),
                  ),
                ).generate(
                  mode: mode,
                  gradeLevel: grade,
                  maxValue: maxValue,
                  targetCompetency: definition.id,
                  transferEmphasis: transfer,
                );
            _checkCommon(
              owner: owner,
              prompt: task.prompt,
              hint: task.hint,
              key: task.key,
              answer: task.answer,
              maxValue: task.maxAnswerValue ?? maxValue,
              choices: task.choices,
              failures: failures,
            );
            final bars = task.bars;
            if (bars != null) {
              if (bars.isEmpty) failures.add('$owner: empty bars ${task.key}');
              if (bars.map((b) => b.label).toSet().length != bars.length) {
                failures.add('$owner: duplicate bar labels ${task.key}');
              }
              if (bars.any((b) => b.value < 0)) {
                failures.add('$owner: negative bar value ${task.key}');
              }
            }
            final cells = task.cubeNetCells;
            if (cells != null && cells.toSet().length != cells.length) {
              failures.add('$owner: duplicate cube cells ${task.key}');
            }
            final labels = task.cubeNetLabels;
            if (labels != null &&
                cells != null &&
                !labels.keys.every(cells.contains)) {
              failures.add('$owner: cube label outside cells ${task.key}');
            }
            final plan = TouchInteractionPlan.forTask(
              mode: mode,
              taskKey: task.key,
              answer: task.answer,
              maxValue: task.maxAnswerValue ?? maxValue,
              choices: task.choices,
              answerSuffix: task.answerSuffix,
              chartLabels: task.bars?.map((b) => b.label).toList(),
              targetCompetency: definition.id,
            );
            if (plan?.expectedAnswer != null &&
                plan!.expectedAnswer != task.answer) {
              failures.add(
                '$owner: touch expected=${plan.expectedAnswer} task=${task.answer} ${task.key}',
              );
            }
          } else if (mode.isStructured) {
            final task =
                StructuredExerciseGenerator(
                  random: Random(
                    810000 +
                        definition.id.index * 1000 +
                        seed +
                        (transfer ? 500 : 0),
                  ),
                ).generate(
                  mode: mode,
                  gradeLevel: grade,
                  maxValue: maxValue,
                  targetCompetency: definition.id,
                  transferEmphasis: transfer,
                );
            _checkCommon(
              owner: owner,
              prompt: task.prompt,
              hint: task.hint,
              key: task.key,
              answer: task.answer,
              maxValue: task.maxAnswerValue ?? maxValue,
              choices: task.choices,
              failures: failures,
            );
            if (task.wallValues != null || task.hiddenWallIndex != null) {
              final wall = task.wallValues;
              final hidden = task.hiddenWallIndex;
              if (wall == null ||
                  hidden == null ||
                  hidden < 0 ||
                  hidden >= wall.length) {
                failures.add('$owner: invalid wall metadata ${task.key}');
              }
            }
            if (task.clockHour != null || task.clockMinute != null) {
              final h = task.clockHour;
              final m = task.clockMinute;
              if (h == null ||
                  m == null ||
                  h < 0 ||
                  h > 23 ||
                  m < 0 ||
                  m > 59) {
                failures.add('$owner: invalid clock $h:$m ${task.key}');
              }
            }
            if (task.moneyPartsCents != null &&
                task.moneyPartsCents!.any((v) => v <= 0)) {
              failures.add('$owner: invalid money pieces ${task.key}');
            }
            for (final checkpoint in task.checkpoints) {
              if (checkpoint.question.trim().isEmpty ||
                  checkpoint.key.trim().isEmpty) {
                failures.add('$owner: empty checkpoint text ${task.key}');
              }
              if (checkpoint.correctChoice < 0 ||
                  checkpoint.correctChoice >= checkpoint.choices.length) {
                failures.add(
                  '$owner: bad checkpoint index ${task.key}:${checkpoint.key}',
                );
              }
              if (checkpoint.choices.toSet().length !=
                  checkpoint.choices.length) {
                failures.add(
                  '$owner: duplicate checkpoint choices ${task.key}:${checkpoint.key}',
                );
              }
            }
            final plan = TouchInteractionPlan.forTask(
              mode: mode,
              taskKey: task.key,
              answer: task.answer,
              maxValue: task.maxAnswerValue ?? maxValue,
              wallValues: task.wallValues,
              hiddenWallIndex: task.hiddenWallIndex,
              choices: task.choices,
              clockHour: task.clockHour,
              clockMinute: task.clockMinute,
              answerSuffix: task.answerSuffix,
              targetCompetency: definition.id,
            );
            if (plan?.expectedAnswer != null &&
                plan!.expectedAnswer != task.answer) {
              failures.add(
                '$owner: touch expected=${plan.expectedAnswer} task=${task.answer} ${task.key}',
              );
            }
          }
        }
      }
    }

    expect(failures, isEmpty, reason: failures.take(160).join('\n'));
  });

  test('audit untargeted generators across grades and modes', () {
    final failures = <String>[];
    for (final grade in GradeLevel.values) {
      final maxValue = grade.recommendedRange.maxValue;
      for (final mode in TrainingMode.values) {
        if (!mode.isStructured && !mode.isUpperPrimary) continue;
        if (mode.isUpperPrimary && grade.index < GradeLevel.third.index) {
          continue;
        }
        for (var seed = 0; seed < 48; seed++) {
          final owner = '${grade.name}/${mode.name}/$seed';
          if (mode.isUpperPrimary) {
            final task = CurriculumExerciseGenerator(
              random: Random(
                910000 + grade.index * 10000 + mode.index * 100 + seed,
              ),
            ).generate(mode: mode, gradeLevel: grade, maxValue: maxValue);
            _checkCommon(
              owner: owner,
              prompt: task.prompt,
              hint: task.hint,
              key: task.key,
              answer: task.answer,
              maxValue: task.maxAnswerValue ?? maxValue,
              choices: task.choices,
              failures: failures,
            );
          } else {
            final task =
                StructuredExerciseGenerator(
                  random: Random(
                    1010000 + grade.index * 10000 + mode.index * 100 + seed,
                  ),
                ).generate(
                  mode: mode,
                  gradeLevel: grade,
                  maxValue: maxValue,
                  transferEmphasis:
                      mode == TrainingMode.wordProblems && seed.isOdd,
                );
            _checkCommon(
              owner: owner,
              prompt: task.prompt,
              hint: task.hint,
              key: task.key,
              answer: task.answer,
              maxValue: task.maxAnswerValue ?? maxValue,
              choices: task.choices,
              failures: failures,
            );
            for (final checkpoint in task.checkpoints) {
              if (checkpoint.correctChoice < 0 ||
                  checkpoint.correctChoice >= checkpoint.choices.length) {
                failures.add(
                  '$owner: bad checkpoint index ${task.key}:${checkpoint.key}',
                );
              }
              if (checkpoint.choices.toSet().length !=
                  checkpoint.choices.length) {
                failures.add(
                  '$owner: duplicate checkpoint choices ${task.key}:${checkpoint.key}',
                );
              }
            }
          }
        }
      }
    }
    expect(failures, isEmpty, reason: failures.take(160).join('\n'));
  });
}
