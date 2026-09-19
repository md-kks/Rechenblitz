import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/guided_method.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/touch_interaction.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/curriculum_training_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

CurriculumExercise _transferTask(MicroCompetencyId id, {int seed = 99100}) {
  final definition = MicroCompetencyCatalog.definition(id);
  final grade = definition.minGrade;
  final maxValue = max(
    grade.recommendedRange.maxValue,
    definition.minNumberRange.maxValue,
  );
  return CurriculumExerciseGenerator(random: Random(seed + id.index)).generate(
    mode: definition.preferredMode,
    gradeLevel: grade,
    maxValue: maxValue,
    targetCompetency: id,
    transferEmphasis: true,
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'Transfer nutzt in zentralen Klasse-3/4-Domänen eigene Aufgabenformen',
    () {
      final tasks = <MicroCompetencyId, CurriculumExercise>{
        for (final id in <MicroCompetencyId>[
          MicroCompetencyId.roundingPlace,
          MicroCompetencyId.romanNumeral,
          MicroCompetencyId.unitConversion,
          MicroCompetencyId.secondsConversion,
          MicroCompetencyId.timeDuration,
          MicroCompetencyId.calendarDate,
          MicroCompetencyId.dataReading,
          MicroCompetencyId.tallyTableReading,
          MicroCompetencyId.probabilityReasoning,
          MicroCompetencyId.probabilityExperiment,
          MicroCompetencyId.combinatoricsSystematic,
          MicroCompetencyId.proportionalUnit,
          MicroCompetencyId.perimeter,
          MicroCompetencyId.area,
          MicroCompetencyId.scale,
          MicroCompetencyId.volumeCubes,
        ])
          id: _transferTask(id),
      };

      expect(
        tasks[MicroCompetencyId.roundingPlace]!.key,
        contains(':transfer:'),
      );
      expect(
        tasks[MicroCompetencyId.romanNumeral]!.key,
        startsWith('roman:write:'),
      );
      expect(tasks[MicroCompetencyId.romanNumeral]!.key, contains(':transfer'));
      expect(
        tasks[MicroCompetencyId.unitConversion]!.key,
        contains(':transfer:'),
      );
      expect(
        tasks[MicroCompetencyId.secondsConversion]!.key,
        contains(':transfer:'),
      );
      expect(
        tasks[MicroCompetencyId.timeDuration]!.key,
        contains(':transfer:'),
      );
      expect(tasks[MicroCompetencyId.calendarDate]!.key, endsWith(':transfer'));
      expect(tasks[MicroCompetencyId.dataReading]!.key, contains(':transfer:'));
      expect(
        tasks[MicroCompetencyId.tallyTableReading]!.key,
        contains(':transfer:'),
      );
      expect(
        tasks[MicroCompetencyId.probabilityReasoning]!.key,
        startsWith('prob:bag:spinner:'),
      );
      expect(
        tasks[MicroCompetencyId.probabilityExperiment]!.key,
        startsWith('prob:experiment:relative:'),
      );
      expect(
        tasks[MicroCompetencyId.probabilityExperiment]!.key,
        endsWith(':transfer'),
      );
      for (final id in <MicroCompetencyId>[
        MicroCompetencyId.combinatoricsSystematic,
        MicroCompetencyId.proportionalUnit,
        MicroCompetencyId.perimeter,
        MicroCompetencyId.area,
        MicroCompetencyId.scale,
        MicroCompetencyId.volumeCubes,
      ]) {
        expect(tasks[id]!.key, contains(':transfer'));
      }
    },
  );

  test(
    'Alle Einheiten- und Sekundenvarianten bleiben echte Transferaufgaben',
    () {
      for (final id in <MicroCompetencyId>[
        MicroCompetencyId.unitConversion,
        MicroCompetencyId.secondsConversion,
      ]) {
        final definition = MicroCompetencyCatalog.definition(id);
        for (var seed = 0; seed < 96; seed++) {
          final task = CurriculumExerciseGenerator(random: Random(99500 + seed))
              .generate(
                mode: definition.preferredMode,
                gradeLevel: GradeLevel.fourth,
                maxValue: NumberRangeLevel.million.maxValue,
                targetCompetency: id,
                transferEmphasis: true,
              );
          expect(
            task.key,
            contains(':transfer:'),
            reason: '${id.name} · seed $seed · ${task.key}',
          );
        }
      }
    },
  );

  test('Transfervarianten bleiben korrekt getaggt, geführt und interaktiv', () {
    final failures = <String>[];
    for (final id in <MicroCompetencyId>[
      MicroCompetencyId.roundingPlace,
      MicroCompetencyId.romanNumeral,
      MicroCompetencyId.unitConversion,
      MicroCompetencyId.secondsConversion,
      MicroCompetencyId.timeDuration,
      MicroCompetencyId.calendarDate,
      MicroCompetencyId.dataReading,
      MicroCompetencyId.tallyTableReading,
      MicroCompetencyId.probabilityReasoning,
      MicroCompetencyId.probabilityExperiment,
      MicroCompetencyId.combinatoricsSystematic,
      MicroCompetencyId.proportionalUnit,
      MicroCompetencyId.perimeter,
      MicroCompetencyId.area,
      MicroCompetencyId.scale,
      MicroCompetencyId.volumeCubes,
    ]) {
      final definition = MicroCompetencyCatalog.definition(id);
      final task = _transferTask(id, seed: 99200);
      final tags = MicroCompetencyCatalog.tagsForTask(
        mode: definition.preferredMode,
        taskKey: task.key,
      );
      if (!tags.any((tag) => tag.id == id)) {
        failures.add('TAG ${id.name}: ${task.key}');
      }
      final guide = GuidedMethodFactory.forTask(
        mode: definition.preferredMode,
        taskKey: task.key,
        expected: task.answer,
        targetCompetency: id,
        preferences: const MethodPreferences(),
      );
      if (guide.methodKey.startsWith('general:')) {
        failures.add('GUIDE ${id.name}: ${task.key}');
      }
      final plan = TouchInteractionPlan.forTask(
        mode: definition.preferredMode,
        taskKey: task.key,
        answer: task.answer,
        maxValue:
            task.maxAnswerValue ??
            max(
              definition.minGrade.recommendedRange.maxValue,
              definition.minNumberRange.maxValue,
            ),
        choices: task.choices,
        answerSuffix: task.answerSuffix,
        chartLabels: task.bars?.map((bar) => bar.label).toList(growable: false),
        targetCompetency: id,
      );
      if (plan == null) {
        failures.add('TOUCH ${id.name}: ${task.key}');
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));

    final dataTask = _transferTask(MicroCompetencyId.dataReading, seed: 99400);
    final dataPlan = TouchInteractionPlan.forTask(
      mode: TrainingMode.dataCharts,
      taskKey: dataTask.key,
      answer: dataTask.answer,
      maxValue: dataTask.maxAnswerValue ?? 100,
      chartLabels: dataTask.bars
          ?.map((bar) => bar.label)
          .toList(growable: false),
      targetCompetency: MicroCompetencyId.dataReading,
    );
    expect(dataPlan, isNotNull);
    expect(
      dataPlan!.dataLabels,
      dataTask.bars!.map((bar) => bar.label).toList(),
    );
  });

  testWidgets('Curriculum-Screen reicht Transfer bis zum Generator durch', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;
    final generator = _TransferProbeGenerator();

    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.rounding,
          targetTasks: 1,
          targetCompetency: MicroCompetencyId.roundingPlace,
          transferEmphasis: true,
          exerciseGenerator: generator,
        ),
      ),
    );
    await tester.pump();

    expect(generator.transferRequested, isTrue);
  });

  test('Normales Zieltraining bleibt von Transferformen getrennt', () {
    final generator = CurriculumExerciseGenerator(random: Random(99300));
    final roman = generator.generate(
      mode: TrainingMode.romanNumerals,
      gradeLevel: GradeLevel.third,
      maxValue: 1000,
      targetCompetency: MicroCompetencyId.romanNumeral,
    );
    final probability = generator.generate(
      mode: TrainingMode.probability,
      gradeLevel: GradeLevel.third,
      maxValue: 1000,
      targetCompetency: MicroCompetencyId.probabilityReasoning,
    );
    expect(roman.key, startsWith('roman:read:'));
    expect(roman.key, isNot(contains(':transfer')));
    expect(probability.key, startsWith('prob:bag:'));
    expect(probability.key, isNot(contains(':spinner:')));
    expect(probability.key, isNot(contains(':transfer')));
  });
}

class _TransferProbeGenerator extends CurriculumExerciseGenerator {
  bool transferRequested = false;

  @override
  CurriculumExercise generate({
    required TrainingMode mode,
    required GradeLevel gradeLevel,
    required int maxValue,
    Iterable<String> recentKeys = const <String>[],
    MicroCompetencyId? targetCompetency,
    bool transferEmphasis = false,
  }) {
    transferRequested = transferRequested || transferEmphasis;
    return const CurriculumExercise(
      mode: TrainingMode.rounding,
      prompt: 'Runde 153 auf Zehner.',
      answer: 150,
      hint: 'Schau auf die Einerstelle.',
      key: 'round:153:10:transfer:context',
      maxAnswerValue: 200,
      method: 'Runden in einer Sachsituation',
    );
  }
}
