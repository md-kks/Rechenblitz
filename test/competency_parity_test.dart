import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/guided_method.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/structured_exercise.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/models/touch_interaction.dart';
import 'package:rechenblitz/services/adaptive_engine.dart';
import 'package:rechenblitz/widgets/learning_visual_aid.dart';

void main() {
  test('jede Mikro-Kompetenz hat spezifische und visuelle Zielhilfe', () {
    final failures = <String>[];
    final structured = StructuredExerciseGenerator(random: Random(26091511));
    final curriculum = CurriculumExerciseGenerator(random: Random(26091512));
    final adaptive = AdaptiveEngine(random: Random(26091513));

    for (final definition in MicroCompetencyCatalog.definitions) {
      final mode = definition.preferredMode;
      final grade = definition.minGrade;
      final maxValue = grade.recommendedRange.maxValue;
      String taskKey;
      int expected;
      List<String>? choices;
      MathFact? fact;

      if (mode.isUpperPrimary) {
        final exercise = curriculum.generate(
          mode: mode,
          gradeLevel: grade,
          maxValue: maxValue,
          targetCompetency: definition.id,
        );
        taskKey = exercise.key;
        expected = exercise.answer;
        choices = exercise.choices;
      } else if (mode.isStructured) {
        final exercise = structured.generate(
          mode: mode,
          gradeLevel: grade,
          maxValue: maxValue,
          targetCompetency: definition.id,
        );
        taskKey = exercise.key;
        expected = exercise.answer;
        choices = exercise.choices;
      } else {
        final factMax = min(maxValue, 100);
        fact = adaptive.selectNext(
          facts: AdaptiveEngine.buildFactPool(maxValue: factMax),
          mode: mode,
          maxValue: factMax,
          targetCompetency: definition.id,
        );
        taskKey = fact.key;
        expected = fact.result;
      }

      final guide = GuidedMethodFactory.forTask(
        mode: mode,
        taskKey: taskKey,
        expected: expected,
        preferences: const MethodPreferences(),
        targetCompetency: definition.id,
        fact: fact,
      );
      if (guide.methodKey.startsWith('general:')) {
        failures.add('METHOD ${definition.id.name}: $taskKey / ${guide.methodKey}');
      }

      final wrong = choices != null && choices.length > 1
          ? (expected + 1) % choices.length
          : expected == 0
              ? 1
              : expected - 1;
      final pattern = ErrorClassifier.classify(
            mode: mode,
            taskKey: taskKey,
            expected: expected,
            actual: wrong,
            fact: fact,
          ) ??
          ErrorPattern.unknown;
      if (!LearningVisualAid.canRender(
        pattern: pattern,
        taskKey: taskKey,
        methodKey: guide.methodKey,
      )) {
        failures.add('VISUAL ${definition.id.name}: $taskKey / ${guide.methodKey} / ${pattern.name}');
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('viele Varianten jeder Mikro-Kompetenz bleiben hilfe-paritätisch', () {
    final structured = StructuredExerciseGenerator(random: Random(26091521));
    final curriculum = CurriculumExerciseGenerator(random: Random(26091522));
    final adaptive = AdaptiveEngine(random: Random(26091523));
    final failures = <String>[];

    for (final definition in MicroCompetencyCatalog.definitions) {
      final mode = definition.preferredMode;
      final grade = definition.minGrade;
      final maxValue = grade.recommendedRange.maxValue;
      final recent = <String>[];
      for (var sample = 0; sample < 12; sample++) {
        String taskKey;
        int expected;
        List<String>? choices;
        MathFact? fact;
        if (mode.isUpperPrimary) {
          final exercise = curriculum.generate(
            mode: mode,
            gradeLevel: grade,
            maxValue: maxValue,
            targetCompetency: definition.id,
            recentKeys: recent,
          );
          taskKey = exercise.key;
          expected = exercise.answer;
          choices = exercise.choices;
        } else if (mode.isStructured) {
          final exercise = structured.generate(
            mode: mode,
            gradeLevel: grade,
            maxValue: maxValue,
            targetCompetency: definition.id,
            recentKeys: recent,
          );
          taskKey = exercise.key;
          expected = exercise.answer;
          choices = exercise.choices;
        } else {
          final factMax = min(maxValue, 100);
          fact = adaptive.selectNext(
            facts: AdaptiveEngine.buildFactPool(maxValue: factMax),
            mode: mode,
            maxValue: factMax,
            targetCompetency: definition.id,
          );
          taskKey = fact.key;
          expected = fact.result;
        }
        recent.add(taskKey);
        if (recent.length > 8) recent.removeAt(0);

        final guide = GuidedMethodFactory.forTask(
          mode: mode,
          taskKey: taskKey,
          expected: expected,
          preferences: const MethodPreferences(),
          targetCompetency: definition.id,
          fact: fact,
        );
        if (guide.methodKey.startsWith('general:')) {
          failures.add('METHOD ${definition.id.name}: $taskKey / ${guide.methodKey}');
          continue;
        }
        final wrong = choices != null && choices.length > 1
            ? (expected + 1) % choices.length
            : expected == 0
                ? 1
                : expected - 1;
        final pattern = ErrorClassifier.classify(
              mode: mode,
              taskKey: taskKey,
              expected: expected,
              actual: wrong,
              fact: fact,
            ) ??
            ErrorPattern.unknown;
        if (!LearningVisualAid.canRender(
          pattern: pattern,
          taskKey: taskKey,
          methodKey: guide.methodKey,
        )) {
          failures.add(
            'VISUAL ${definition.id.name}: $taskKey / ${guide.methodKey} / ${pattern.name}',
          );
        }
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });


  test('normale Generatorvarianten behalten spezifische visuelle Hilfe', () {
    final structured = StructuredExerciseGenerator(random: Random(26091531));
    final curriculum = CurriculumExerciseGenerator(random: Random(26091532));
    final failures = <String>[];

    for (final mode in TrainingMode.values.where((mode) => mode.isStructured)) {
      final recent = <String>[];
      for (var sample = 0; sample < 32; sample++) {
        final exercise = structured.generate(
          mode: mode,
          gradeLevel: GradeLevel.second,
          maxValue: 100,
          recentKeys: recent,
        );
        recent.add(exercise.key);
        if (recent.length > 12) recent.removeAt(0);
        final guide = GuidedMethodFactory.forTask(
          mode: mode,
          taskKey: exercise.key,
          expected: exercise.answer,
          preferences: const MethodPreferences(),
        );
        if (guide.methodKey.startsWith('general:')) {
          failures.add('METHOD ${mode.name}: ${exercise.key} / ${guide.methodKey}');
          continue;
        }
        final choices = exercise.choices;
        final wrong = choices != null && choices.length > 1
            ? (exercise.answer + 1) % choices.length
            : exercise.answer == 0
                ? 1
                : exercise.answer - 1;
        final pattern = ErrorClassifier.classify(
              mode: mode,
              taskKey: exercise.key,
              expected: exercise.answer,
              actual: wrong,
            ) ??
            ErrorPattern.unknown;
        if (!LearningVisualAid.canRender(
          pattern: pattern,
          taskKey: exercise.key,
          methodKey: guide.methodKey,
        )) {
          failures.add('VISUAL ${mode.name}: ${exercise.key} / ${guide.methodKey} / ${pattern.name}');
        }
      }
    }

    for (final mode in TrainingMode.values.where((mode) => mode.isUpperPrimary)) {
      final recent = <String>[];
      for (var sample = 0; sample < 32; sample++) {
        final exercise = curriculum.generate(
          mode: mode,
          gradeLevel: GradeLevel.fourth,
          maxValue: 1000000,
          recentKeys: recent,
        );
        recent.add(exercise.key);
        if (recent.length > 12) recent.removeAt(0);
        final guide = GuidedMethodFactory.forTask(
          mode: mode,
          taskKey: exercise.key,
          expected: exercise.answer,
          preferences: const MethodPreferences(),
        );
        if (guide.methodKey.startsWith('general:')) {
          failures.add('METHOD ${mode.name}: ${exercise.key} / ${guide.methodKey}');
          continue;
        }
        final choices = exercise.choices;
        final wrong = choices != null && choices.length > 1
            ? (exercise.answer + 1) % choices.length
            : exercise.answer == 0
                ? 1
                : exercise.answer - 1;
        final pattern = ErrorClassifier.classify(
              mode: mode,
              taskKey: exercise.key,
              expected: exercise.answer,
              actual: wrong,
            ) ??
            ErrorPattern.unknown;
        if (!LearningVisualAid.canRender(
          pattern: pattern,
          taskKey: exercise.key,
          methodKey: guide.methodKey,
        )) {
          failures.add('VISUAL ${mode.name}: ${exercise.key} / ${guide.methodKey} / ${pattern.name}');
        }
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });


  test('nur bewusst klassische Kompetenzen dürfen ohne Touch bleiben', () {
    final structured = StructuredExerciseGenerator(random: Random(26091541));
    final curriculum = CurriculumExerciseGenerator(random: Random(26091542));
    final adaptive = AdaptiveEngine(random: Random(26091543));
    final unexpectedMissing = <String>{};
    const intentionallyClassic = <MicroCompetencyId>{
      MicroCompetencyId.additionNoBridge,
      MicroCompetencyId.additionTenBridge,
      MicroCompetencyId.subtractionNoBridge,
      MicroCompetencyId.subtractionTenBridge,
      MicroCompetencyId.multiplicationFacts,
      MicroCompetencyId.divisionFacts,
      MicroCompetencyId.numberWordReading,
      MicroCompetencyId.wordProblemCalculation,
    };

    for (final definition in MicroCompetencyCatalog.definitions) {
      final mode = definition.preferredMode;
      final grade = definition.minGrade;
      final maxValue = grade.recommendedRange.maxValue;
      for (var sample = 0; sample < 6; sample++) {
        TouchInteractionPlan? plan;
        String key;
        if (mode.isUpperPrimary) {
          final exercise = curriculum.generate(
            mode: mode,
            gradeLevel: grade,
            maxValue: maxValue,
            targetCompetency: definition.id,
          );
          key = exercise.key;
          plan = TouchInteractionPlan.forTask(
            mode: mode,
            taskKey: exercise.key,
            answer: exercise.answer,
            maxValue: exercise.maxAnswerValue ?? maxValue,
            choices: exercise.choices,
            answerSuffix: exercise.answerSuffix,
            targetCompetency: definition.id,
          );
        } else if (mode.isStructured) {
          final exercise = structured.generate(
            mode: mode,
            gradeLevel: grade,
            maxValue: maxValue,
            targetCompetency: definition.id,
          );
          key = exercise.key;
          plan = TouchInteractionPlan.forTask(
            mode: mode,
            taskKey: exercise.key,
            answer: exercise.answer,
            maxValue: exercise.maxAnswerValue ?? maxValue,
            wallValues: exercise.wallValues,
            hiddenWallIndex: exercise.hiddenWallIndex,
            choices: exercise.choices,
            clockHour: exercise.clockHour,
            clockMinute: exercise.clockMinute,
            answerSuffix: exercise.answerSuffix,
            targetCompetency: definition.id,
          );
        } else {
          final factMax = min(maxValue, 100);
          final fact = adaptive.selectNext(
            facts: AdaptiveEngine.buildFactPool(maxValue: factMax),
            mode: mode,
            maxValue: factMax,
            targetCompetency: definition.id,
          );
          key = fact.key;
          plan = TouchInteractionPlan.forTask(
            mode: mode,
            taskKey: fact.key,
            answer: mode == TrainingMode.numberFriends ? fact.b : fact.result,
            maxValue: factMax,
            targetCompetency: definition.id,
          );
        }
        if (plan == null && !intentionallyClassic.contains(definition.id)) {
          unexpectedMissing.add('${definition.id.name}: ${mode.name}: $key');
        }
      }
    }
    final sorted = unexpectedMissing.toList()..sort();
    expect(sorted, isEmpty, reason: sorted.join('\n'));
  });

}
