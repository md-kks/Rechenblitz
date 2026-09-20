import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_answer_feedback.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_sentence_structure_expansion_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_support_catalog.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';
import 'package:rechenblitz/subjects/german/screens/german_training_screen.dart';

GermanSessionResult _completedRound(GradeLevel grade, List<GermanTask> tasks) =>
    GermanSessionResult(
      gradeLevel: grade,
      startedAt: DateTime(2026, 9, 20, 10),
      finishedAt: DateTime(2026, 9, 20, 10, 5),
      kind: GermanSessionKind.practice,
      taskResults: <GermanTaskResult>[
        for (final task in tasks)
          GermanTaskResult(
            taskId: task.id,
            competencyId: task.competencyId,
            correctFirstTry: true,
            incorrectAttempts: 0,
            responseMs: 1500,
          ),
      ],
    );

void main() {
  test('sentence structure expansion adds thirty productive tasks', () {
    expect(GermanSentenceStructureExpansionTaskCatalog.tasks, hasLength(30));
    expect(
      GermanSentenceStructureExpansionTaskCatalog.tasks
          .where(
            (task) => task.competencyId == GermanCompetencyId.sentenceWordOrder,
          )
          .length,
      10,
    );
    expect(
      GermanSentenceStructureExpansionTaskCatalog.tasks
          .where(
            (task) => task.competencyId == GermanCompetencyId.sentenceWriting,
          )
          .length,
      8,
    );
    expect(
      GermanSentenceStructureExpansionTaskCatalog.tasks
          .where(
            (task) => task.competencyId == GermanCompetencyId.subjectPredicate,
          )
          .length,
      12,
    );
    for (final task in GermanSentenceStructureExpansionTaskCatalog.tasks) {
      expect(task.isWellFormed, isTrue, reason: task.id);
    }
  });

  test(
    'grade three now has twelve current sentence-order and writing tasks',
    () {
      final order = GermanTaskCatalog.forCompetency(
        GermanCompetencyId.sentenceWordOrder,
      ).where((task) => task.recommendedFromGrade == GradeLevel.third);
      final writing = GermanTaskCatalog.forCompetency(
        GermanCompetencyId.sentenceWriting,
      ).where((task) => task.recommendedFromGrade == GradeLevel.third);

      expect(order, hasLength(12));
      expect(writing, hasLength(12));
      expect(
        order.every(
          (task) => task.interaction == GermanTaskInteraction.wordOrder,
        ),
        isTrue,
      );
      expect(
        writing.every(
          (task) => task.interaction == GermanTaskInteraction.typedText,
        ),
        isTrue,
      );
    },
  );

  test('grade four subject-predicate practice prefers twelve active tasks', () {
    final current = GermanTaskCatalog.forCompetency(
      GermanCompetencyId.subjectPredicate,
    ).where((task) => task.recommendedFromGrade == GradeLevel.fourth);
    final active = current.where(
      (task) => task.interaction == GermanTaskInteraction.tokenSelection,
    );

    expect(active, hasLength(12));
    expect(
      GermanPracticePlanner.buildCompetencyRound(
        gradeLevel: GradeLevel.fourth,
        competencyId: GermanCompetencyId.subjectPredicate,
        history: const <GermanSessionResult>[],
      ).every(
        (task) => task.interaction == GermanTaskInteraction.tokenSelection,
      ),
      isTrue,
    );
  });

  test(
    'all three sentence-structure skills rotate to a second fresh round',
    () {
      final cases = <(GradeLevel, GermanCompetencyId)>[
        (GradeLevel.third, GermanCompetencyId.sentenceWordOrder),
        (GradeLevel.third, GermanCompetencyId.sentenceWriting),
        (GradeLevel.fourth, GermanCompetencyId.subjectPredicate),
      ];

      for (final entry in cases) {
        final first = GermanPracticePlanner.buildCompetencyRound(
          gradeLevel: entry.$1,
          competencyId: entry.$2,
          history: const <GermanSessionResult>[],
        );
        expect(first, hasLength(6), reason: entry.$2.name);
        final second = GermanPracticePlanner.buildCompetencyRound(
          gradeLevel: entry.$1,
          competencyId: entry.$2,
          history: <GermanSessionResult>[_completedRound(entry.$1, first)],
        );
        expect(second, hasLength(6), reason: entry.$2.name);
        expect(
          second
              .map((task) => task.id)
              .toSet()
              .intersection(first.map((task) => task.id).toSet()),
          isEmpty,
          reason: entry.$2.name,
        );
      }
    },
  );

  test('multi-part predicate requires every verb part and the subject', () {
    final task = GermanSentenceStructureExpansionTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-subpred-letter-perfect',
    );

    expect(
      task.acceptsSelection(<String>['Mia', 'hat', 'geschrieben']),
      isTrue,
    );
    expect(task.acceptsSelection(<String>['Mia', 'geschrieben']), isFalse);
    expect(
      task.acceptsSelection(<String>[
        'Mia',
        'hat',
        'einen langen Brief',
        'geschrieben',
      ]),
      isFalse,
    );
  });

  test(
    'subject-predicate support teaches subject question and verb bracket',
    () {
      final task = GermanSentenceStructureExpansionTaskCatalog.tasks.firstWhere(
        (task) => task.id == 'g4-subpred-bike-modal',
      );
      expect(
        GermanSupportCatalog.firstHintForTask(task),
        contains('Wer oder was'),
      );
      expect(
        GermanSupportCatalog.secondHintForTask(task),
        contains('Verbklammer'),
      );
      expect(
        GermanAnswerFeedback.forIncorrect(task, 'Ben · reparieren'),
        contains('Verbteile'),
      );
    },
  );

  testWidgets('split predicate can be corrected entirely by touch', (
    tester,
  ) async {
    final task = GermanSentenceStructureExpansionTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-subpred-letter-perfect',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GermanTrainingScreen(
          gradeLevel: GradeLevel.fourth,
          tasks: <GermanTask>[task],
          speak: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final value in <String>['Mia', 'hat', 'einen langen Brief']) {
      await tester.tap(find.widgetWithText(FilterChip, value));
    }
    await tester.pump();
    final submit = find.byKey(const ValueKey('german-token-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(find.textContaining('Verbteile'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'einen langen Brief'));
    await tester.tap(find.widgetWithText(FilterChip, 'geschrieben'));
    await tester.pump();
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(find.text('Runde geschafft'), findsWidgets);
  });
}
