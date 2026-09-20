import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/assessment.dart';
import 'package:rechenblitz/models/learner_profile.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

AssessmentProgress _progress({
  required AssessmentTask first,
  required AssessmentTaskResult result,
}) {
  final now = DateTime(2026, 9, 20, 16);
  return AssessmentProgress(
    gradeLevel: GradeLevel.second,
    numberRange: NumberRangeLevel.hundred,
    tasks: [
      first,
      const AssessmentTask(
        mode: TrainingMode.minus,
        taskKey: 'minus:12:5',
        prompt: '12 - 5 = ?',
        answer: 7,
        maxAnswerValue: 20,
      ),
    ],
    taskResults: [result],
    nextIndex: 1,
    startedAt: now.subtract(const Duration(minutes: 2)),
    updatedAt: now,
    state: GermanState.thuringia,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('Choice-Aufgaben brauchen gültigen eindeutigen Antwortindex', () {
    final invalidIndex = _progress(
      first: const AssessmentTask(
        mode: TrainingMode.dataCharts,
        taskKey: 'choice:bad-index',
        prompt: 'Welche Antwort passt?',
        answer: 3,
        maxAnswerValue: 10,
        choices: ['A', 'B'],
      ),
      result: const AssessmentTaskResult(
        mode: TrainingMode.dataCharts,
        taskKey: 'choice:bad-index',
        correct: false,
      ),
    );
    final duplicate = _progress(
      first: const AssessmentTask(
        mode: TrainingMode.dataCharts,
        taskKey: 'choice:duplicate',
        prompt: 'Welche Antwort passt?',
        answer: 0,
        maxAnswerValue: 10,
        choices: ['A', 'A'],
      ),
      result: const AssessmentTaskResult(
        mode: TrainingMode.dataCharts,
        taskKey: 'choice:duplicate',
        correct: true,
      ),
    );

    expect(invalidIndex.hasSaneState(now: invalidIndex.updatedAt), isFalse);
    expect(duplicate.hasSaneState(now: duplicate.updatedAt), isFalse);
  });

  test('gespeichertes Resultat muss Target und Fact des Tasks behalten', () {
    final fact = MathFact(a: 7, b: 5, operation: MathOperation.plus);
    final wrongTarget = _progress(
      first: AssessmentTask(
        mode: TrainingMode.practice,
        taskKey: fact.key,
        prompt: '7 + 5 = ?',
        answer: 12,
        maxAnswerValue: 20,
        fact: fact,
        targetCompetency: MicroCompetencyId.additionTenBridge,
      ),
      result: AssessmentTaskResult(
        mode: TrainingMode.practice,
        taskKey: fact.key,
        correct: true,
        fact: fact,
        targetCompetency: MicroCompetencyId.subtractionTenBridge,
      ),
    );
    final wrongFact = _progress(
      first: AssessmentTask(
        mode: TrainingMode.practice,
        taskKey: fact.key,
        prompt: '7 + 5 = ?',
        answer: 12,
        maxAnswerValue: 20,
        fact: fact,
        targetCompetency: MicroCompetencyId.additionTenBridge,
      ),
      result: AssessmentTaskResult(
        mode: TrainingMode.practice,
        taskKey: fact.key,
        correct: true,
        fact: MathFact(a: 6, b: 6, operation: MathOperation.plus),
        targetCompetency: MicroCompetencyId.additionTenBridge,
      ),
    );

    expect(wrongTarget.hasSaneState(now: wrongTarget.updatedAt), isFalse);
    expect(wrongFact.hasSaneState(now: wrongFact.updatedAt), isFalse);
  });

  test('Touch-Metadaten müssen als vollständige Paare gespeichert sein', () {
    final wall = _progress(
      first: const AssessmentTask(
        mode: TrainingMode.numberWall,
        taskKey: 'wall:broken',
        prompt: 'Welche Zahl fehlt?',
        answer: 5,
        maxAnswerValue: 20,
        wallValues: [2, 3, 5],
      ),
      result: const AssessmentTaskResult(
        mode: TrainingMode.numberWall,
        taskKey: 'wall:broken',
        correct: true,
      ),
    );
    final clock = _progress(
      first: const AssessmentTask(
        mode: TrainingMode.clock,
        taskKey: 'clock:broken',
        prompt: 'Wie spät ist es?',
        answer: 8,
        maxAnswerValue: 24,
        clockHour: 8,
      ),
      result: const AssessmentTaskResult(
        mode: TrainingMode.clock,
        taskKey: 'clock:broken',
        correct: true,
      ),
    );

    expect(wall.hasSaneState(now: wall.updatedAt), isFalse);
    expect(clock.hasSaneState(now: clock.updatedAt), isFalse);
  });

  test(
    'beschädigter Lerncheck wird beim App-Start aus dem Speicher geheilt',
    () async {
      final storage = StorageService();
      await storage.initializeProfiles();
      final bad = _progress(
        first: const AssessmentTask(
          mode: TrainingMode.practice,
          taskKey: 'plus:7:5',
          prompt: '7 + 5 = ?',
          answer: 12,
          maxAnswerValue: 20,
          targetCompetency: MicroCompetencyId.additionTenBridge,
        ),
        result: const AssessmentTaskResult(
          mode: TrainingMode.practice,
          taskKey: 'plus:7:5',
          correct: true,
          targetCompetency: MicroCompetencyId.subtractionTenBridge,
        ),
      );
      await storage.saveAssessmentProgress(bad);

      final controller = AppController(storage: storage);
      await controller.load();

      expect(controller.assessmentProgress, isNull);
      expect(await storage.loadAssessmentProgress(), isNull);
    },
  );

  test('regulär erzeugte Lernchecks bleiben in allen Ländern fortsetzbar', () {
    final now = DateTime(2026, 9, 20, 16);
    final failures = <String>[];

    for (final state in GermanState.values) {
      for (final grade in GradeLevel.values) {
        final range = grade.recommendedRange;
        for (var seed = 0; seed < 16; seed++) {
          final tasks = AssessmentGenerator(
            random: Random(
              1400000 + state.index * 10000 + grade.index * 100 + seed,
            ),
          ).generate(grade: grade, range: range, state: state);
          if (tasks.length < 2) {
            failures.add('${state.name}/${grade.name}/$seed: too few tasks');
            continue;
          }

          final first = tasks.first;
          final progress = AssessmentProgress(
            gradeLevel: grade,
            numberRange: range,
            tasks: tasks,
            taskResults: <AssessmentTaskResult>[
              AssessmentTaskResult(
                mode: first.mode,
                taskKey: first.taskKey,
                correct: true,
                fact: first.fact,
                targetCompetency: first.targetCompetency,
              ),
            ],
            nextIndex: 1,
            startedAt: now.subtract(const Duration(minutes: 2)),
            updatedAt: now,
            state: state,
          );
          if (!progress.hasSaneState(now: now)) {
            failures.add(
              '${state.name}/${grade.name}/$seed: invalid generated progress',
            );
          }
        }
      }
    }

    expect(failures, isEmpty, reason: failures.take(80).join('\n'));
  });
}
