import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/structured_exercise.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/app_controller.dart';

void main() {
  test('multiple-choice answers do not reveal themselves by position', () {
    final controller = AppController();
    final counts = <String, List<int>>{};

    void add(String bucket, int answer, int length) {
      if (length < 2 || answer < 0 || answer >= length) return;
      final values = counts.putIfAbsent(
        bucket,
        () => List<int>.filled(length, 0),
      );
      if (values.length != length) return;
      values[answer] += 1;
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
        for (var seed = 0; seed < 256; seed++) {
          if (mode.isUpperPrimary) {
            final task =
                CurriculumExerciseGenerator(
                  random: Random(
                    2100000 +
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
            if (task.choices != null && task.choices!.length > 1) {
              add(
                '${definition.id.name}/${transfer ? "T" : "N"}/${task.key.split(":").take(3).join(":")}',
                task.answer,
                task.choices!.length,
              );
            }
          } else if (mode.isStructured) {
            final task =
                StructuredExerciseGenerator(
                  random: Random(
                    2200000 +
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
            if (task.choices != null && task.choices!.length > 1) {
              add(
                '${definition.id.name}/${transfer ? "T" : "N"}/${task.key.split(":").take(3).join(":")}',
                task.answer,
                task.choices!.length,
              );
            }
            for (final checkpoint in task.checkpoints) {
              if (checkpoint.choices.length > 1) {
                add(
                  '${definition.id.name}/checkpoint/${checkpoint.key}',
                  checkpoint.correctChoice,
                  checkpoint.choices.length,
                );
              }
            }
          }
        }
      }
    }

    final suspicious = <String>[];
    final fixed = <String>[];
    for (final entry in counts.entries) {
      final total = entry.value.fold<int>(0, (a, b) => a + b);
      if (total < 40) continue;
      final maxCount = entry.value.reduce(max);
      final share = maxCount / total;
      if (entry.value.where((v) => v > 0).length == 1) {
        fixed.add('${entry.key} total=$total counts=${entry.value}');
      } else if (share >= 0.72) {
        suspicious.add(
          '${entry.key} total=$total counts=${entry.value} share=${share.toStringAsFixed(2)}',
        );
      }
    }
    expect(
      fixed,
      isEmpty,
      reason: 'Feste richtige Positionen:\n${fixed.take(80).join("\n")}',
    );
    expect(
      suspicious,
      isEmpty,
      reason:
          'Stark einseitige richtige Positionen:\n${suspicious.take(80).join("\n")}',
    );
  });
}
