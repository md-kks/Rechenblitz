import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_grade_four_diversity_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_task_evidence_priority.dart';

GermanSessionResult _completedRound(List<GermanTask> tasks) =>
    GermanSessionResult(
      gradeLevel: GradeLevel.fourth,
      startedAt: DateTime(2026, 9, 20, 12),
      finishedAt: DateTime(2026, 9, 20, 12, 5),
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
  test('grade-four diversity catalog adds thirty-two active tasks', () {
    expect(GermanGradeFourDiversityTaskCatalog.tasks, hasLength(32));
    final counts = <GermanCompetencyId, int>{};
    for (final task in GermanGradeFourDiversityTaskCatalog.tasks) {
      expect(task.recommendedFromGrade, GradeLevel.fourth, reason: task.id);
      expect(task.isWellFormed, isTrue, reason: task.id);
      counts[task.competencyId] = (counts[task.competencyId] ?? 0) + 1;
    }
    expect(counts, <GermanCompetencyId, int>{
      GermanCompetencyId.spellingStrategies: 8,
      GermanCompetencyId.dictionarySkills: 8,
      GermanCompetencyId.verbTenses: 8,
      GermanCompetencyId.textSequence: 8,
    });
  });

  test('all German task ids remain unique', () {
    final ids = GermanTaskCatalog.tasks.map((task) => task.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('four grade-four skills now have twelve strongest current tasks', () {
    for (final competency in <GermanCompetencyId>[
      GermanCompetencyId.spellingStrategies,
      GermanCompetencyId.dictionarySkills,
      GermanCompetencyId.verbTenses,
      GermanCompetencyId.textSequence,
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
    }
  });

  test('each expanded grade-four skill rotates to a fresh second round', () {
    for (final competency in <GermanCompetencyId>[
      GermanCompetencyId.spellingStrategies,
      GermanCompetencyId.dictionarySkills,
      GermanCompetencyId.verbTenses,
      GermanCompetencyId.textSequence,
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

  test('irregular perfect forms must be built completely', () {
    final gone = GermanGradeFourDiversityTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-tense-go-perfect-build',
    );
    final written = GermanGradeFourDiversityTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-tense-write-perfect-build',
    );

    expect(gone.accepts('gegangen'), isTrue);
    expect(gone.accepts('gegangt'), isFalse);
    expect(written.accepts('geschrieben'), isTrue);
    expect(written.accepts('geschreibt'), isFalse);
  });

  test('dictionary ordering checks close prefixes exactly', () {
    final task = GermanGradeFourDiversityTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-dictionary-order-schale',
    );
    expect(task.accepts('Schale Schalter Schanze Schaufel'), isTrue);
    expect(task.accepts('Schalter Schale Schanze Schaufel'), isFalse);
  });

  test('spelling strategy builder distinguishes final consonants', () {
    final task = GermanGradeFourDiversityTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-spell-korb-build',
    );
    expect(task.accepts('Korb'), isTrue);
    expect(task.accepts('Korp'), isFalse);
  });

  test('complex process order requires the complete sequence', () {
    final task = GermanGradeFourDiversityTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-sequence-protocol-order',
    );
    expect(
      task.accepts(
        'Fragestellung notieren. Material aufschreiben. Durchführung beschreiben. Ergebnis festhalten.',
      ),
      isTrue,
    );
    expect(
      task.accepts(
        'Material aufschreiben. Fragestellung notieren. Durchführung beschreiben. Ergebnis festhalten.',
      ),
      isFalse,
    );
  });
}
