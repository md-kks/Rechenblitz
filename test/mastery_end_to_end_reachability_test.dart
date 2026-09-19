import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/structured_exercise.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/adaptive_engine.dart';
import 'package:rechenblitz/services/app_controller.dart';

class _GeneratedTask {
  const _GeneratedTask(this.key, this.mode, [this.fact]);
  final String key;
  final TrainingMode mode;
  final MathFact? fact;
}

List<_GeneratedTask> _generateTasks({
  required MicroCompetencyDefinition definition,
  required TrainingMode mode,
  required GradeLevel grade,
  required int maxValue,
  required int count,
  required int seed,
  bool transferEmphasis = false,
  Iterable<String> initialRecent = const <String>[],
}) {
  final tasks = <_GeneratedTask>[];
  final recent = List<String>.from(initialRecent);

  if (mode.isUpperPrimary) {
    final generator = CurriculumExerciseGenerator(random: Random(seed));
    for (var i = 0; i < 160 && tasks.length < count; i++) {
      final exercise = generator.generate(
        mode: mode,
        gradeLevel: grade,
        maxValue: maxValue,
        recentKeys: recent,
        targetCompetency: definition.id,
      );
      recent.insert(0, exercise.key);
      if (tasks.any((task) => task.key == exercise.key)) continue;
      final tags = MicroCompetencyCatalog.tagsForTask(
        mode: mode,
        taskKey: exercise.key,
      );
      if (tags.any((tag) => tag.id == definition.id)) {
        tasks.add(_GeneratedTask(exercise.key, mode));
      }
    }
    return tasks;
  }

  if (mode.isStructured) {
    final generator = StructuredExerciseGenerator(random: Random(seed));
    for (var i = 0; i < 160 && tasks.length < count; i++) {
      final exercise = generator.generate(
        mode: mode,
        gradeLevel: grade,
        maxValue: maxValue,
        recentKeys: recent,
        targetCompetency: definition.id,
        transferEmphasis: transferEmphasis,
      );
      recent.insert(0, exercise.key);
      if (tasks.any((task) => task.key == exercise.key)) continue;
      final tags = MicroCompetencyCatalog.tagsForTask(
        mode: mode,
        taskKey: exercise.key,
      );
      if (tags.any((tag) => tag.id == definition.id)) {
        tasks.add(_GeneratedTask(exercise.key, mode));
      }
    }
    return tasks;
  }

  final engine = AdaptiveEngine(random: Random(seed));
  final facts = AdaptiveEngine.buildFactPool(maxValue: maxValue);
  for (var i = 0; i < 240 && tasks.length < count; i++) {
    final fact = engine.selectNext(
      facts: facts,
      mode: mode,
      maxValue: maxValue,
      recentKeys: recent,
      targetCompetency: definition.id,
    );
    recent.insert(0, fact.key);
    if (tasks.any((task) => task.key == fact.key)) continue;
    final tags = MicroCompetencyCatalog.tagsForTask(
      mode: mode,
      taskKey: fact.key,
      fact: fact,
    );
    if (tags.any((tag) => tag.id == definition.id)) {
      tasks.add(_GeneratedTask(fact.key, mode, fact));
    }
  }
  return tasks;
}

void main() {
  test('jede Mikrokompetenz erreicht Gemeistert mit echten Generatoraufgaben', () {
    final failures = <String>[];
    final noveltyFailures = <String>[];
    final base = DateTime(2026, 1, 1, 9);

    for (final definition in MicroCompetencyCatalog.definitions) {
      final grade = definition.minGrade;
      final range = NumberRangeLevel.values.firstWhere(
        (value) =>
            value.index >= grade.recommendedRange.index &&
            value.index >= definition.minNumberRange.index,
      );
      final maxValue = range.maxValue;
      final controller = AppController()
        ..gradeLevel = grade
        ..numberRange = range;

      final basis = _generateTasks(
        definition: definition,
        mode: definition.preferredMode,
        grade: grade,
        maxValue: maxValue,
        count: 4,
        seed: 950000 + definition.id.index,
      );
      final review = _generateTasks(
        definition: definition,
        mode: definition.preferredMode,
        grade: grade,
        maxValue: maxValue,
        count: 2,
        seed: 960000 + definition.id.index,
        initialRecent: basis.map((task) => task.key),
      );
      final transferMode = controller.transferModeFor(definition.id);
      final transfer = _generateTasks(
        definition: definition,
        mode: transferMode,
        grade: grade,
        maxValue: maxValue,
        count: 2,
        seed: 970000 + definition.id.index,
        transferEmphasis: true,
        initialRecent: transferMode == definition.preferredMode
            ? <String>[
                ...review.map((task) => task.key),
                ...basis.map((task) => task.key),
              ]
            : const <String>[],
      );

      if (basis.length < 4 || review.length < 2 || transfer.length < 2) {
        failures.add(
          '${definition.id.name}: basis=${basis.length}, review=${review.length}, transfer=${transfer.length} (${transferMode.name})',
        );
        continue;
      }

      controller.microObservations = <MicroCompetencyObservation>[
        for (var i = 0; i < 6; i++)
          MicroCompetencyObservation(
            id: definition.id,
            occurredAt: base.add(Duration(minutes: i)),
            correct: true,
            evidenceWeight: 1,
            source: MicroEvidenceSource.practice,
            usedHelp: false,
            mode: basis[i % basis.length].mode,
            gradeLevel: grade,
            numberRange: range,
            taskKey: basis[i % basis.length].key,
          ),
        for (var i = 0; i < review.length; i++)
          MicroCompetencyObservation(
            id: definition.id,
            occurredAt: base.add(Duration(days: 3, minutes: i)),
            correct: true,
            evidenceWeight: 1,
            source: MicroEvidenceSource.review,
            usedHelp: false,
            mode: review[i].mode,
            gradeLevel: grade,
            numberRange: range,
            taskKey: review[i].key,
          ),
        for (var i = 0; i < transfer.length; i++)
          MicroCompetencyObservation(
            id: definition.id,
            occurredAt: base.add(Duration(days: 4, minutes: i)),
            correct: true,
            evidenceWeight: 1,
            source: MicroEvidenceSource.transfer,
            usedHelp: false,
            mode: transfer[i].mode,
            gradeLevel: grade,
            numberRange: range,
            taskKey: transfer[i].key,
          ),
      ];

      final progress = controller.microCompetencyProgress(definition.id);
      if (progress.state != MicroCompetencyState.mastered) {
        failures.add(
          '${definition.id.name}: state=${progress.state.name}, base=${progress.independentEvidence}/${progress.independentTaskVariety}, review=${progress.reviewIndependentEvidence}/${progress.reviewIndependentTaskVariety}, transfer=${progress.transferIndependentEvidence}/${progress.transferIndependentTaskVariety}',
        );
      }

      final basisKeys = basis.map((task) => task.key).toSet();
      final reviewKeys = review.map((task) => task.key).toSet();
      final transferKeys = transfer.map((task) => task.key).toSet();
      if (basisKeys.intersection(reviewKeys).isNotEmpty) {
        noveltyFailures.add('${definition.id.name}: Review wiederholt Basis');
      }
      if (basisKeys.union(reviewKeys).intersection(transferKeys).isNotEmpty) {
        noveltyFailures.add(
          '${definition.id.name}: Transfer wiederholt Basis/Review',
        );
      }
    }

    expect(failures, isEmpty, reason: failures.join('\n'));
    expect(
      noveltyFailures,
      isEmpty,
      reason:
          'Review und Transfer sollen nach der selbstständigen Basis echte neue Aufgaben liefern:\n${noveltyFailures.join('\n')}',
    );
  });

  test('Review- und Transfer-Scheduler können jedes Lernziel auswählen', () {
    final controller = AppController()
      ..gradeLevel = GradeLevel.fourth
      ..numberRange = NumberRangeLevel.million;
    final base = DateTime(2026, 1, 1, 9);
    final definitions = MicroCompetencyCatalog.definitions;

    controller.microObservations = <MicroCompetencyObservation>[
      for (final definition in definitions)
        for (var index = 0; index < 4; index++)
          MicroCompetencyObservation(
            id: definition.id,
            occurredAt: base.add(Duration(minutes: index)),
            correct: true,
            evidenceWeight: 1,
            source: MicroEvidenceSource.practice,
            usedHelp: false,
            mode: definition.preferredMode,
            gradeLevel: GradeLevel.fourth,
            numberRange: NumberRangeLevel.million,
            taskKey: 'scheduler:${definition.id.name}:$index',
          ),
    ];

    final available = controller
        .microCompetenciesForGrade()
        .map((progress) => progress.definition.id)
        .toSet();
    expect(available, definitions.map((definition) => definition.id).toSet());

    final failures = <String>[];
    final now = base.add(const Duration(days: 3));
    for (final definition in definitions) {
      final excluding = definitions
          .where((other) => other.id != definition.id)
          .map((other) => other.id)
          .toList(growable: false);

      final review = controller.dueReviewMicroCompetency(
        now: now,
        excluding: excluding,
      );
      if (review?.definition.id != definition.id) {
        failures.add('${definition.id.name}: review');
      }

      final transfer = controller.transferCandidateMicroCompetency(
        now: now,
        respectSchedule: true,
        excludingAny: excluding,
      );
      if (transfer?.definition.id != definition.id) {
        failures.add('${definition.id.name}: transfer');
      }
    }

    expect(failures, isEmpty, reason: failures.join(', '));
  });
}
