import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_answer_feedback.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_writing_revision_expansion_task_catalog.dart';

GermanSessionResult _completedRound(List<GermanTask> tasks) =>
    GermanSessionResult(
      gradeLevel: GradeLevel.fourth,
      startedAt: DateTime(2026, 9, 20, 9),
      finishedAt: DateTime(2026, 9, 20, 9, 5),
      kind: GermanSessionKind.practice,
      taskResults: <GermanTaskResult>[
        for (final task in tasks)
          GermanTaskResult(
            taskId: task.id,
            competencyId: task.competencyId,
            correctFirstTry: true,
            incorrectAttempts: 0,
            responseMs: 1800,
          ),
      ],
    );

void main() {
  test('writing revision expansion adds eighteen productive tasks', () {
    expect(GermanWritingRevisionExpansionTaskCatalog.tasks, hasLength(18));
    expect(
      GermanWritingRevisionExpansionTaskCatalog.tasks
          .where(
            (task) =>
                task.competencyId == GermanCompetencyId.sentenceConnections,
          )
          .length,
      9,
    );
    expect(
      GermanWritingRevisionExpansionTaskCatalog.tasks
          .where((task) => task.competencyId == GermanCompetencyId.textRevision)
          .length,
      9,
    );
    for (final task in GermanWritingRevisionExpansionTaskCatalog.tasks) {
      expect(task.recommendedFromGrade, GradeLevel.fourth, reason: task.id);
      expect(
        task.interaction,
        GermanTaskInteraction.typedText,
        reason: task.id,
      );
      expect(task.isWellFormed, isTrue, reason: task.id);
    }
  });

  test(
    'each upper-primary writing competency now has twelve productive tasks',
    () {
      for (final competency in <GermanCompetencyId>[
        GermanCompetencyId.sentenceConnections,
        GermanCompetencyId.textRevision,
      ]) {
        final productive = GermanTaskCatalog.forCompetency(
          competency,
        ).where((task) => task.interaction == GermanTaskInteraction.typedText);
        expect(productive, hasLength(12), reason: competency.name);
      }
    },
  );

  test('targeted writing can rotate to six completely different tasks', () {
    for (final competency in <GermanCompetencyId>[
      GermanCompetencyId.sentenceConnections,
      GermanCompetencyId.textRevision,
    ]) {
      final firstRound = GermanPracticePlanner.buildCompetencyRound(
        gradeLevel: GradeLevel.fourth,
        competencyId: competency,
        history: const <GermanSessionResult>[],
      );
      expect(firstRound, hasLength(6), reason: competency.name);
      expect(
        firstRound.every(
          (task) => task.interaction == GermanTaskInteraction.typedText,
        ),
        isTrue,
        reason: competency.name,
      );

      final secondRound = GermanPracticePlanner.buildCompetencyRound(
        gradeLevel: GradeLevel.fourth,
        competencyId: competency,
        history: <GermanSessionResult>[_completedRound(firstRound)],
      );
      expect(secondRound, hasLength(6), reason: competency.name);
      expect(
        secondRound
            .map((task) => task.id)
            .toSet()
            .intersection(firstRound.map((task) => task.id).toSet()),
        isEmpty,
        reason: competency.name,
      );
    }
  });

  test(
    'connection tasks accept valid clause order and reject wrong relation',
    () {
      final task = GermanWritingRevisionExpansionTaskCatalog.tasks.firstWhere(
        (task) => task.id == 'g4-connect-frost-write',
      );
      expect(
        task.accepts('Die Wege sind glatt, weil es nachts gefroren hat.'),
        isTrue,
      );
      expect(
        task.accepts('Weil es nachts gefroren hat, sind die Wege glatt.'),
        isTrue,
      );
      expect(
        task.accepts('Die Wege sind glatt, obwohl es nachts gefroren hat.'),
        isFalse,
      );
    },
  );

  test('revision tasks accept the requested improvement only', () {
    final task = GermanWritingRevisionExpansionTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-revision-jacket-pronouns',
    );
    expect(task.accepts('Mia nimmt ihre Jacke. Sie zieht sie an.'), isTrue);
    expect(
      task.accepts('Mia nimmt Mias Jacke. Mia zieht Mias Jacke an.'),
      isFalse,
    );
  });

  test('typed writing feedback is competency-specific', () {
    final connection = GermanWritingRevisionExpansionTaskCatalog.tasks.first;
    final revision = GermanWritingRevisionExpansionTaskCatalog.tasks.firstWhere(
      (task) => task.competencyId == GermanCompetencyId.textRevision,
    );

    expect(
      GermanAnswerFeedback.forIncorrect(connection, 'Die Wege sind glatt.'),
      contains('Verbindungswort'),
    );
    expect(
      GermanAnswerFeedback.forIncorrect(revision, revision.prompt),
      contains('verlangte Überarbeitung'),
    );
  });
}
