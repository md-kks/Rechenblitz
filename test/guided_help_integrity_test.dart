import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/guided_method.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/structured_exercise.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/adaptive_engine.dart';
import 'package:rechenblitz/services/app_controller.dart';

void _auditGuide({
  required String owner,
  required GuidedMethodGuide guide,
  required List<String> failures,
}) {
  if (guide.methodKey.trim().isEmpty) failures.add('$owner: empty methodKey');
  if (guide.methodLabel.trim().isEmpty) {
    failures.add('$owner: empty methodLabel');
  }
  if (guide.nudge.trim().isEmpty) failures.add('$owner: empty nudge');
  if (guide.steps.isEmpty) failures.add('$owner: no guided steps');
  if (guide.methodKey.startsWith('general:')) {
    failures.add('$owner: generic method ${guide.methodKey}');
  }

  for (var index = 0; index < guide.steps.length; index++) {
    final step = guide.steps[index];
    final label = '$owner/step$index';
    if (step.title.trim().isEmpty) failures.add('$label: empty title');
    if (step.instruction.trim().isEmpty) {
      failures.add('$label: empty instruction');
    }
    if (step.question != null && step.question!.trim().isEmpty) {
      failures.add('$label: blank question');
    }

    final hasQuestion = step.question != null;
    final hasChoices = step.choices.isNotEmpty;
    final hasCorrect = step.correctChoice != null;
    if (hasQuestion || hasChoices || hasCorrect) {
      if (!hasQuestion || !hasChoices || !hasCorrect) {
        failures.add(
          '$label: incomplete interaction q=$hasQuestion '
          'choices=$hasChoices correct=$hasCorrect',
        );
      } else {
        if (step.correctChoice! < 0 ||
            step.correctChoice! >= step.choices.length) {
          failures.add(
            '$label: bad correctChoice=${step.correctChoice} '
            'len=${step.choices.length}',
          );
        }
        if (step.choices.any((value) => value.trim().isEmpty)) {
          failures.add('$label: blank choice ${step.choices}');
        }
        if (step.choices.toSet().length != step.choices.length) {
          failures.add('$label: duplicate choices ${step.choices}');
        }
      }
    }

    final hasEvidenceKey = step.evidenceKey != null;
    final hasEvidenceCompetency = step.evidenceCompetency != null;
    if (hasEvidenceKey != hasEvidenceCompetency) {
      failures.add(
        '$label: partial evidence key=${step.evidenceKey} '
        'competency=${step.evidenceCompetency}',
      );
    }
    if ((hasEvidenceKey || hasEvidenceCompetency) && !step.isInteractive) {
      failures.add('$label: evidence on non-interactive step');
    }
    if (hasEvidenceKey && step.evidenceKey!.trim().isEmpty) {
      failures.add('$label: blank evidenceKey');
    }
    if (step.recordsIntermediateEvidence && step.evidenceWeight <= 0) {
      failures.add('$label: non-positive evidenceWeight');
    }
  }
}

void main() {
  test(
    'audit guided help integrity across targeted normal and transfer tasks',
    () {
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

        for (final transfer in <bool>[false, true]) {
          final mode = transfer
              ? controller.transferModeFor(definition.id)
              : definition.preferredMode;

          for (var seed = 0; seed < 64; seed++) {
            final owner =
                '${definition.id.name}/${transfer ? 'transfer' : 'normal'}/$seed';
            String taskKey;
            int expected;
            MathFact? fact;

            if (mode.isUpperPrimary) {
              final exercise =
                  CurriculumExerciseGenerator(
                    random: Random(
                      1410000 +
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
              taskKey = exercise.key;
              expected = exercise.answer;
            } else if (mode.isStructured) {
              final exercise =
                  StructuredExerciseGenerator(
                    random: Random(
                      1510000 +
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
              taskKey = exercise.key;
              expected = exercise.answer;
            } else {
              final factMax = min(maxValue, 100);
              fact =
                  AdaptiveEngine(
                    random: Random(
                      1610000 +
                          definition.id.index * 1000 +
                          seed +
                          (transfer ? 500 : 0),
                    ),
                  ).selectNext(
                    facts: AdaptiveEngine.buildFactPool(maxValue: factMax),
                    mode: mode,
                    maxValue: factMax,
                    targetCompetency: definition.id,
                  );
              taskKey = fact.key;
              expected = mode == TrainingMode.numberFriends
                  ? fact.b
                  : fact.result;
            }

            final guide = GuidedMethodFactory.forTask(
              mode: mode,
              taskKey: taskKey,
              expected: expected,
              preferences: const MethodPreferences(),
              targetCompetency: definition.id,
              fact: fact,
            );
            _auditGuide(
              owner: '$owner/$taskKey',
              guide: guide,
              failures: failures,
            );
            for (final alternative in GuidedMethodFactory.alternativesForTask(
              mode: mode,
              taskKey: taskKey,
              expected: expected,
              preferences: const MethodPreferences(),
              targetCompetency: definition.id,
              fact: fact,
            )) {
              _auditGuide(
                owner: '$owner/$taskKey/alt:${alternative.methodKey}',
                guide: alternative,
                failures: failures,
              );
            }
          }
        }
      }

      expect(failures, isEmpty, reason: failures.take(160).join('\n'));
    },
  );

  test(
    'Sachaufgaben-Hilfe zeigt bei gleichen Gruppengrößen keine doppelten Optionen',
    () {
      final guide = GuidedMethodFactory.forTask(
        mode: TrainingMode.wordProblems,
        taskKey: 'story:info:groups:4:4:7',
        expected: 0,
        preferences: const MethodPreferences(),
        targetCompetency: MicroCompetencyId.wordProblemRelevantInformation,
      );
      final step = guide.steps.firstWhere(
        (value) => value.evidenceKey == 'storyInfo',
      );
      expect(step.choices.toSet().length, step.choices.length);
      expect(step.correctChoice, 0);
    },
  );

  test('Rechnungsmodell-Hilfe bleibt bei gleichen Operanden eindeutig', () {
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.wordProblems,
      taskKey: 'story:equation:+:7:7',
      expected: 0,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.wordProblemModel,
    );
    final step = guide.steps.firstWhere(
      (value) => value.evidenceKey == 'storyEquation',
    );
    expect(step.choices.toSet().length, step.choices.length);
    expect(step.choices, hasLength(4));
    expect(step.choices[step.correctChoice!], '7 + 7');
  });

  test('Mal-Hilfe erklärt auch null Gruppen mit echtem Text', () {
    final fact = MathFact(a: 0, b: 4, operation: MathOperation.multiply);
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.multiply,
      taskKey: fact.key,
      expected: 0,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.multiplicationFacts,
      fact: fact,
    );
    expect(
      guide.steps.every((step) => step.instruction.trim().isNotEmpty),
      isTrue,
    );
    expect(
      guide.steps.any((step) => step.instruction.contains('0 Gruppen')),
      isTrue,
    );
  });
}
