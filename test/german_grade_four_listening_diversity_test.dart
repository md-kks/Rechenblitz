import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_assessment.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_competency_catalog.dart';
import 'package:rechenblitz/subjects/german/german_grade_four_listening_diversity_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_learning_domain.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_task_evidence_priority.dart';

GermanSessionResult _completedRound(List<GermanTask> tasks) =>
    GermanSessionResult(
      gradeLevel: GradeLevel.fourth,
      startedAt: DateTime(2026, 9, 20, 13),
      finishedAt: DateTime(2026, 9, 20, 13, 5),
      kind: GermanSessionKind.practice,
      taskResults: <GermanTaskResult>[
        for (final task in tasks)
          GermanTaskResult(
            taskId: task.id,
            competencyId: task.competencyId,
            correctFirstTry: true,
            incorrectAttempts: 0,
            responseMs: 1600,
          ),
      ],
    );

void main() {
  test('grade-four listening diversity adds sixteen audio touch tasks', () {
    expect(GermanGradeFourListeningDiversityTaskCatalog.tasks, hasLength(16));
    final counts = <GermanCompetencyId, int>{};
    for (final task in GermanGradeFourListeningDiversityTaskCatalog.tasks) {
      expect(task.recommendedFromGrade, GradeLevel.fourth, reason: task.id);
      expect(
        task.interaction,
        GermanTaskInteraction.tokenSelection,
        reason: task.id,
      );
      expect(task.requiresSpeech, isTrue, reason: task.id);
      expect(task.isWellFormed, isTrue, reason: task.id);
      counts[task.competencyId] = (counts[task.competencyId] ?? 0) + 1;
    }
    expect(counts, <GermanCompetencyId, int>{
      GermanCompetencyId.listeningMainIdeas: 8,
      GermanCompetencyId.discussionReasoning: 8,
    });
  });

  test('both grade-four listening skills now have twelve strongest tasks', () {
    for (final competency in <GermanCompetencyId>[
      GermanCompetencyId.listeningMainIdeas,
      GermanCompetencyId.discussionReasoning,
    ]) {
      final current = GermanTaskCatalog.forCompetency(competency)
          .where((task) => task.recommendedFromGrade == GradeLevel.fourth)
          .toList();
      final bestRank = current
          .map(GermanTaskEvidencePriority.rank)
          .reduce((a, b) => a < b ? a : b);
      final strongest = current.where(
        (task) => GermanTaskEvidencePriority.rank(task) == bestRank,
      );
      expect(strongest, hasLength(12), reason: competency.name);
      expect(
        strongest.every(
          (task) =>
              task.interaction == GermanTaskInteraction.tokenSelection &&
              task.requiresSpeech,
        ),
        isTrue,
        reason: competency.name,
      );
    }
  });

  test('both grade-four listening skills rotate to a fresh second round', () {
    for (final competency in <GermanCompetencyId>[
      GermanCompetencyId.listeningMainIdeas,
      GermanCompetencyId.discussionReasoning,
    ]) {
      final first = GermanPracticePlanner.buildCompetencyRound(
        gradeLevel: GradeLevel.fourth,
        competencyId: competency,
        history: const <GermanSessionResult>[],
      );
      expect(first, hasLength(6), reason: competency.name);
      final second = GermanPracticePlanner.buildCompetencyRound(
        gradeLevel: GradeLevel.fourth,
        competencyId: competency,
        history: <GermanSessionResult>[_completedRound(first)],
      );
      expect(second, hasLength(6), reason: competency.name);
      expect(
        second
            .map((task) => task.id)
            .toSet()
            .intersection(first.map((task) => task.id).toSet()),
        isEmpty,
        reason: competency.name,
      );
    }
  });

  test('main-idea task requires both central statements only', () {
    final task = GermanGradeFourListeningDiversityTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-listen-main-mark-plastic',
    );
    expect(
      task.acceptsSelection(<String>[
        'Mehrwegflaschen können Abfall vermeiden.',
        'Wiederholtes Benutzen spart neue Verpackungen.',
      ]),
      isTrue,
    );
    expect(
      task.acceptsSelection(<String>[
        'Mehrwegflaschen können Abfall vermeiden.',
      ]),
      isFalse,
    );
    expect(
      task.acceptsSelection(<String>[
        'Mehrwegflaschen können Abfall vermeiden.',
        'Wiederholtes Benutzen spart neue Verpackungen.',
        'Flaschen können durchsichtig sein.',
      ]),
      isFalse,
    );
  });

  test('discussion task requires the actually spoken arguments', () {
    final task = GermanGradeFourListeningDiversityTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-discuss-mark-water',
    );
    expect(
      task.acceptsSelection(<String>[
        'Kinder können ihre Flaschen in der Schule auffüllen.',
        'Weniger Einwegflaschen können nötig sein.',
      ]),
      isTrue,
    );
    expect(
      task.acceptsSelection(<String>[
        'Kinder können ihre Flaschen in der Schule auffüllen.',
        'Der Flur hat weiße Wände.',
      ]),
      isFalse,
    );
  });

  test('daily round and Lerncheck keep rich audio evidence in grade four', () {
    for (final round in <List<GermanTask>>[
      GermanPracticePlanner.buildDailyRound(
        gradeLevel: GradeLevel.fourth,
        history: const <GermanSessionResult>[],
      ),
      GermanAssessmentPlanner.buildRound(GradeLevel.fourth),
    ]) {
      final listening = round.where(
        (task) =>
            GermanCompetencyCatalog.definition(task.competencyId).domain ==
            GermanLearningDomain.listening,
      );
      expect(listening, hasLength(2));
      expect(
        listening.every(
          (task) =>
              task.interaction == GermanTaskInteraction.tokenSelection &&
              task.requiresSpeech,
        ),
        isTrue,
      );
    }
  });
}
