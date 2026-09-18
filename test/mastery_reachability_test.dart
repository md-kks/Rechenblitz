import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/structured_exercise.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/adaptive_engine.dart';

void main() {
  test('jede Mikro-Kompetenz kann vier verschiedene Zielaufgaben liefern', () {
    const requiredTaskVariety = 4;
    final failures = <String>[];

    for (final definition in MicroCompetencyCatalog.definitions) {
      final mode = definition.preferredMode;
      final grade = definition.minGrade;
      final maxValue = max(
        grade.recommendedRange.maxValue,
        definition.minNumberRange.maxValue,
      );
      final keys = <String>{};
      var targetMismatch = false;

      if (mode.isUpperPrimary) {
        final generator = CurriculumExerciseGenerator(
          random: Random(9185000 + definition.id.index),
        );
        for (var i = 0; i < 80; i++) {
          final exercise = generator.generate(
            mode: mode,
            gradeLevel: grade,
            maxValue: maxValue,
            targetCompetency: definition.id,
          );
          keys.add(exercise.key);
          final tags = MicroCompetencyCatalog.tagsForTask(
            mode: mode,
            taskKey: exercise.key,
          );
          targetMismatch =
              targetMismatch || !tags.any((tag) => tag.id == definition.id);
        }
      } else if (mode.isStructured) {
        final generator = StructuredExerciseGenerator(
          random: Random(9186000 + definition.id.index),
        );
        for (var i = 0; i < 80; i++) {
          final exercise = generator.generate(
            mode: mode,
            gradeLevel: grade,
            maxValue: maxValue,
            targetCompetency: definition.id,
          );
          keys.add(exercise.key);
          final tags = MicroCompetencyCatalog.tagsForTask(
            mode: mode,
            taskKey: exercise.key,
          );
          targetMismatch =
              targetMismatch || !tags.any((tag) => tag.id == definition.id);
        }
      } else {
        final engine = AdaptiveEngine(
          random: Random(9187000 + definition.id.index),
        );
        final facts = AdaptiveEngine.buildFactPool(maxValue: maxValue);
        for (var i = 0; i < 80; i++) {
          final fact = engine.selectNext(
            facts: facts,
            mode: mode,
            maxValue: maxValue,
            targetCompetency: definition.id,
          );
          keys.add(fact.key);
          final tags = MicroCompetencyCatalog.tagsForTask(
            mode: mode,
            taskKey: fact.key,
            fact: fact,
          );
          targetMismatch =
              targetMismatch || !tags.any((tag) => tag.id == definition.id);
        }
      }

      if (targetMismatch || keys.length < requiredTaskVariety) {
        failures.add(
          '${definition.id.name}/${mode.name}: '
          '${keys.length} verschiedene Aufgaben'
          '${targetMismatch ? ' · falsches Target-Tag' : ''}',
        );
      }
    }

    expect(
      failures,
      isEmpty,
      reason:
          '„Gemeistert“ braucht vier unterschiedliche selbstständige Aufgaben. '
          'Diese Lernziele wären nicht zuverlässig erreichbar:\n'
          '${failures.join('\n')}',
    );
  });
}
