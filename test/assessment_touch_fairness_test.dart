import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/assessment.dart';
import 'package:rechenblitz/models/learner_profile.dart';
import 'package:rechenblitz/models/touch_interaction.dart';
import 'package:rechenblitz/models/training.dart';

void main() {
  test('audit assessment touch plans for answer-revealing defaults', () {
    final suspicious = <String>[];
    var touchCount = 0;

    for (final state in GermanState.values) {
      for (final grade in GradeLevel.values) {
        final range = grade.recommendedRange;
        for (var seed = 0; seed < 80; seed++) {
          final tasks = AssessmentGenerator(
            random: Random(
              1800000 + state.index * 10000 + grade.index * 1000 + seed,
            ),
          ).generate(grade: grade, range: range, state: state);
          for (var index = 0; index < tasks.length; index++) {
            final task = tasks[index];
            final plan = TouchInteractionPlan.forTask(
              mode: task.mode,
              taskKey: task.taskKey,
              answer: task.answer,
              maxValue: task.maxAnswerValue,
              wallValues: task.wallValues,
              hiddenWallIndex: task.hiddenWallIndex,
              choices: task.choices,
              clockHour: task.clockHour,
              clockMinute: task.clockMinute,
              answerSuffix: task.answerSuffix,
              targetCompetency: null,
            );
            if (plan == null) continue;
            touchCount++;

            final revealsByDefault = switch (plan.kind) {
              TouchInteractionKind.numberLine => plan.startValue == task.answer,
              TouchInteractionKind.numberBondComposer => task.answer == 0,
              TouchInteractionKind.volumeLayerBuilder => task.answer == 1,
              _ => false,
            };
            if (revealsByDefault) {
              suspicious.add(
                '${state.name}/${grade.name}/$seed/$index '
                '${plan.kind.name} ${task.taskKey} answer=${task.answer} '
                'start=${plan.startValue}',
              );
            }
          }
        }
      }
    }

    expect(touchCount, greaterThan(10000));
    expect(suspicious, isEmpty, reason: suspicious.take(80).join('\n'));
  });
  test('Zahlenfreunde im Lerncheck sind immer echte Zerlegungen', () {
    for (final state in GermanState.values) {
      for (var seed = 0; seed < 160; seed++) {
        final tasks =
            AssessmentGenerator(
              random: Random(2200000 + state.index * 1000 + seed),
            ).generate(
              grade: GradeLevel.first,
              range: NumberRangeLevel.twenty,
              state: state,
            );
        final numberFriends = tasks.where(
          (task) => task.mode == TrainingMode.numberFriends,
        );
        for (final task in numberFriends) {
          expect(task.answer, inInclusiveRange(1, 19));
          expect(task.fact, isNotNull);
          expect(task.fact!.a, inInclusiveRange(1, 19));
          expect(task.fact!.b, inInclusiveRange(1, 19));
        }
      }
    }
  });
}
