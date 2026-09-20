import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/structured_exercise.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/adaptive_engine.dart';
import 'package:rechenblitz/services/app_controller.dart';

class _View {
  const _View(this.key, this.visible);
  final String key;
  final String visible;
}

String _norm(String value) =>
    value.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();

_View _structuredView(StructuredExercise task) => _View(
  task.key,
  jsonEncode({
    'prompt': _norm(task.prompt),
    'choices': task.choices,
    'wall': task.wallValues,
    'hidden': task.hiddenWallIndex,
    'clockH': task.clockHour,
    'clockM': task.clockMinute,
    'shape': task.shape?.name,
    'money': task.moneyPartsCents,
    'suffix': task.answerSuffix,
    'representation': task.representation?.name,
    'a': task.representationA,
    'b': task.representationB,
  }),
);

_View _curriculumView(CurriculumExercise task) => _View(
  task.key,
  jsonEncode({
    'prompt': _norm(task.prompt),
    'choices': task.choices,
    'suffix': task.answerSuffix,
    'bars': task.bars
        ?.map((bar) => <Object>[bar.label, bar.value])
        .toList(growable: false),
    'cells': task.cubeNetCells?.map((cell) => [cell.x, cell.y]).toList(),
    'labels': task.cubeNetLabels?.entries
        .map((entry) => '${entry.key.x},${entry.key.y}=${entry.value}')
        .toList(),
  }),
);

void main() {
  test('every five-task focus block is visibly diverse across seed series', () {
    final failures = <String>[];

    for (final definition in MicroCompetencyCatalog.definitions) {
      final mode = definition.preferredMode;
      final range = NumberRangeLevel.values.firstWhere(
        (value) =>
            value.index >= definition.minGrade.recommendedRange.index &&
            value.index >= definition.minNumberRange.index,
      );
      final maxValue = range.maxValue;

      for (var series = 0; series < 24; series++) {
        final recent = <String>[];
        final visible = <String>[];

        if (mode.isUpperPrimary) {
          final generator = CurriculumExerciseGenerator(
            random: Random(730000 + definition.id.index * 100 + series),
          );
          for (var i = 0; i < 5; i++) {
            final task = generator.generate(
              mode: mode,
              gradeLevel: definition.minGrade,
              maxValue: maxValue,
              recentKeys: recent,
              targetCompetency: definition.id,
            );
            final view = _curriculumView(task);
            recent.insert(0, view.key);
            visible.add(view.visible);
          }
        } else if (mode.isStructured) {
          final generator = StructuredExerciseGenerator(
            random: Random(830000 + definition.id.index * 100 + series),
          );
          for (var i = 0; i < 5; i++) {
            final task = generator.generate(
              mode: mode,
              gradeLevel: definition.minGrade,
              maxValue: maxValue,
              recentKeys: recent,
              targetCompetency: definition.id,
            );
            final view = _structuredView(task);
            recent.insert(0, view.key);
            visible.add(view.visible);
          }
        } else {
          final engine = AdaptiveEngine(
            random: Random(930000 + definition.id.index * 100 + series),
          );
          final facts = AdaptiveEngine.buildFactPool(maxValue: maxValue);
          for (var i = 0; i < 5; i++) {
            final fact = engine.selectNext(
              facts: facts,
              mode: mode,
              maxValue: maxValue,
              recentKeys: recent,
              targetCompetency: definition.id,
            );
            recent.insert(0, fact.key);
            visible.add(fact.key);
          }
        }

        if (visible.toSet().length < 5) {
          failures.add(
            '${definition.id.name}/series=$series => '
            '${visible.toSet().length}/5 visible unique',
          );
          break;
        }
      }
    }

    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test(
    'every two-task transfer block is visibly diverse across seed series',
    () {
      final controller = AppController();
      final failures = <String>[];

      for (final definition in MicroCompetencyCatalog.definitions) {
        final mode = controller.transferModeFor(definition.id);
        final range = NumberRangeLevel.values.firstWhere(
          (value) =>
              value.index >= definition.minGrade.recommendedRange.index &&
              value.index >= definition.minNumberRange.index,
        );
        final maxValue = range.maxValue;

        for (var series = 0; series < 24; series++) {
          final recent = <String>[];
          final visible = <String>[];

          if (mode.isUpperPrimary) {
            final generator = CurriculumExerciseGenerator(
              random: Random(1030000 + definition.id.index * 100 + series),
            );
            for (var i = 0; i < 2; i++) {
              final task = generator.generate(
                mode: mode,
                gradeLevel: definition.minGrade,
                maxValue: maxValue,
                recentKeys: recent,
                targetCompetency: definition.id,
                transferEmphasis: true,
              );
              final view = _curriculumView(task);
              recent.insert(0, view.key);
              visible.add(view.visible);
            }
          } else if (mode.isStructured) {
            final generator = StructuredExerciseGenerator(
              random: Random(1130000 + definition.id.index * 100 + series),
            );
            for (var i = 0; i < 2; i++) {
              final task = generator.generate(
                mode: mode,
                gradeLevel: definition.minGrade,
                maxValue: maxValue,
                recentKeys: recent,
                targetCompetency: definition.id,
                transferEmphasis: true,
              );
              final view = _structuredView(task);
              recent.insert(0, view.key);
              visible.add(view.visible);
            }
          } else {
            final engine = AdaptiveEngine(
              random: Random(1230000 + definition.id.index * 100 + series),
            );
            final facts = AdaptiveEngine.buildFactPool(maxValue: maxValue);
            for (var i = 0; i < 2; i++) {
              final fact = engine.selectNext(
                facts: facts,
                mode: mode,
                maxValue: maxValue,
                recentKeys: recent,
                targetCompetency: definition.id,
              );
              recent.insert(0, fact.key);
              visible.add(fact.key);
            }
          }

          if (visible.toSet().length < 2) {
            failures.add(
              '${definition.id.name}/series=$series => '
              '${visible.toSet().length}/2 transfer views unique',
            );
            break;
          }
        }
      }

      expect(failures, isEmpty, reason: failures.join('\n'));
    },
  );
}
