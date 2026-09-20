import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_word_recognition_task_catalog.dart';

int _editDistance(String a, String b) {
  final left = a.toLowerCase();
  final right = b.toLowerCase();
  final previous = List<int>.generate(right.length + 1, (index) => index);
  for (var i = 1; i <= left.length; i++) {
    var diagonal = previous[0];
    previous[0] = i;
    for (var j = 1; j <= right.length; j++) {
      final above = previous[j];
      final cost = left.codeUnitAt(i - 1) == right.codeUnitAt(j - 1) ? 0 : 1;
      previous[j] = min(
        min(previous[j] + 1, previous[j - 1] + 1),
        diagonal + cost,
      );
      diagonal = above;
    }
  }
  return previous[right.length];
}

void main() {
  test('word recognition pool grows from six to twenty-four tasks', () {
    expect(GermanWordRecognitionTaskCatalog.tasks, hasLength(18));
    expect(
      GermanTaskCatalog.forCompetency(GermanCompetencyId.wordRecognition),
      hasLength(24),
    );
  });

  test('new word recognition tasks require close visual reading', () {
    for (final task in GermanWordRecognitionTaskCatalog.tasks) {
      expect(task.recommendedFromGrade, GradeLevel.first, reason: task.id);
      expect(
        task.interaction,
        GermanTaskInteraction.singleChoice,
        reason: task.id,
      );
      expect(task.isWellFormed, isTrue, reason: task.id);
      expect(task.choices, hasLength(3), reason: task.id);
      expect(task.accessiblePrompt, isNotNull, reason: task.id);

      final answer = task.acceptedAnswers.single;
      expect(
        task.accessiblePrompt!.toLowerCase().contains(answer.toLowerCase()),
        isFalse,
        reason: '${task.id} leaks the answer through accessibility text',
      );
      final distractors = task.choices.where((choice) => choice != answer);
      expect(
        distractors.any((choice) => _editDistance(answer, choice) <= 2),
        isTrue,
        reason: '${task.id} has no orthographically close distractor',
      );
    }
  });

  test('targeted word recognition can rotate to six different words', () {
    final firstRound = GermanPracticePlanner.buildCompetencyRound(
      gradeLevel: GradeLevel.first,
      competencyId: GermanCompetencyId.wordRecognition,
      history: const <GermanSessionResult>[],
    );
    expect(firstRound, hasLength(6));
    expect(firstRound.map((task) => task.id).toSet(), hasLength(6));

    final history = <GermanSessionResult>[
      GermanSessionResult(
        gradeLevel: GradeLevel.first,
        startedAt: DateTime(2026, 9, 20, 8),
        finishedAt: DateTime(2026, 9, 20, 8, 5),
        kind: GermanSessionKind.practice,
        taskResults: <GermanTaskResult>[
          for (final task in firstRound)
            GermanTaskResult(
              taskId: task.id,
              competencyId: task.competencyId,
              correctFirstTry: true,
              incorrectAttempts: 0,
              responseMs: 1200,
            ),
        ],
      ),
    ];

    final secondRound = GermanPracticePlanner.buildCompetencyRound(
      gradeLevel: GradeLevel.first,
      competencyId: GermanCompetencyId.wordRecognition,
      history: history,
    );
    expect(secondRound, hasLength(6));
    expect(secondRound.map((task) => task.id).toSet(), hasLength(6));
    expect(
      secondRound
          .map((task) => task.id)
          .toSet()
          .intersection(firstRound.map((task) => task.id).toSet()),
      isEmpty,
    );
  });
}
