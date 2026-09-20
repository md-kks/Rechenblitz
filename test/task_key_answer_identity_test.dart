import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/structured_exercise.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/app_controller.dart';

class _Seen {
  const _Seen(this.semanticAnswer, this.mode, this.prompt);
  final String semanticAnswer;
  final TrainingMode mode;
  final String prompt;
}

String _answer(int answer, List<String>? choices, String? suffix) {
  if (choices != null && choices.isNotEmpty) {
    if (answer < 0 || answer >= choices.length) return 'INVALID:$answer';
    return 'choice:${choices[answer]}';
  }
  return 'number:$answer:${suffix ?? ''}';
}

void main() {
  test('task keys never change their semantic answer', () {
    final controller = AppController();
    final seen = <String, _Seen>{};
    final failures = <String>[];

    void record({
      required String owner,
      required TrainingMode mode,
      required String key,
      required String prompt,
      required int answer,
      required List<String>? choices,
      required String? suffix,
    }) {
      final semantic = _answer(answer, choices, suffix);
      final previous = seen[key];
      if (previous == null) {
        seen[key] = _Seen(semantic, mode, prompt);
        return;
      }
      if (previous.semanticAnswer != semantic) {
        failures.add(
          '$owner | $key | ${previous.semanticAnswer} != $semantic | '
          '${previous.mode.name} -> ${mode.name}',
        );
      }
    }

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
        for (var seed = 0; seed < 32; seed++) {
          final owner = '${definition.id.name}/${transfer ? "T" : "N"}/$seed';
          if (mode.isUpperPrimary) {
            final task =
                CurriculumExerciseGenerator(
                  random: Random(
                    1700000 +
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
            record(
              owner: owner,
              mode: mode,
              key: task.key,
              prompt: task.prompt,
              answer: task.answer,
              choices: task.choices,
              suffix: task.answerSuffix,
            );
          } else if (mode.isStructured) {
            final task =
                StructuredExerciseGenerator(
                  random: Random(
                    1800000 +
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
            record(
              owner: owner,
              mode: mode,
              key: task.key,
              prompt: task.prompt,
              answer: task.answer,
              choices: task.choices,
              suffix: task.answerSuffix,
            );
          }
        }
      }
    }

    for (final grade in GradeLevel.values) {
      final maxValue = grade.recommendedRange.maxValue;
      for (final mode in TrainingMode.values) {
        if (!mode.isStructured && !mode.isUpperPrimary) continue;
        if (mode.isUpperPrimary && grade.index < GradeLevel.third.index) {
          continue;
        }
        for (var seed = 0; seed < 64; seed++) {
          final owner = 'untargeted/${grade.name}/${mode.name}/$seed';
          if (mode.isUpperPrimary) {
            final task = CurriculumExerciseGenerator(
              random: Random(
                1900000 + grade.index * 10000 + mode.index * 100 + seed,
              ),
            ).generate(mode: mode, gradeLevel: grade, maxValue: maxValue);
            record(
              owner: owner,
              mode: mode,
              key: task.key,
              prompt: task.prompt,
              answer: task.answer,
              choices: task.choices,
              suffix: task.answerSuffix,
            );
          } else {
            final task =
                StructuredExerciseGenerator(
                  random: Random(
                    2000000 + grade.index * 10000 + mode.index * 100 + seed,
                  ),
                ).generate(
                  mode: mode,
                  gradeLevel: grade,
                  maxValue: maxValue,
                  transferEmphasis:
                      mode == TrainingMode.wordProblems && seed.isOdd,
                );
            record(
              owner: owner,
              mode: mode,
              key: task.key,
              prompt: task.prompt,
              answer: task.answer,
              choices: task.choices,
              suffix: task.answerSuffix,
            );
          }
        }
      }
    }

    expect(failures, isEmpty, reason: failures.take(120).join('\n'));
  });
}
