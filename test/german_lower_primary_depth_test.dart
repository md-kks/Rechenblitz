import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_lower_primary_depth_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_task_evidence_priority.dart';

GermanSessionResult _completedRound(GradeLevel grade, List<GermanTask> tasks) =>
    GermanSessionResult(
      gradeLevel: grade,
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
            responseMs: 1300,
          ),
      ],
    );

void main() {
  test('lower-primary depth catalog adds thirty-five active tasks', () {
    expect(GermanLowerPrimaryDepthTaskCatalog.tasks, hasLength(35));
    final counts = <GermanCompetencyId, int>{};
    for (final task in GermanLowerPrimaryDepthTaskCatalog.tasks) {
      expect(task.isWellFormed, isTrue, reason: task.id);
      counts[task.competencyId] = (counts[task.competencyId] ?? 0) + 1;
    }
    expect(counts, <GermanCompetencyId, int>{
      GermanCompetencyId.alphabeticalOrder: 4,
      GermanCompetencyId.syllableSegmentation: 4,
      GermanCompetencyId.sentenceWordOrder: 6,
      GermanCompetencyId.verbInflection: 4,
      GermanCompetencyId.sentencePunctuation: 6,
      GermanCompetencyId.sentenceTypes: 5,
      GermanCompetencyId.sentenceWriting: 6,
    });
  });

  test('all German task ids remain unique', () {
    final ids = GermanTaskCatalog.tasks.map((task) => task.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('all seven lower-primary skills now have twelve strongest tasks', () {
    final cases = <(GradeLevel, GermanCompetencyId)>[
      (GradeLevel.first, GermanCompetencyId.alphabeticalOrder),
      (GradeLevel.first, GermanCompetencyId.syllableSegmentation),
      (GradeLevel.first, GermanCompetencyId.sentenceWordOrder),
      (GradeLevel.second, GermanCompetencyId.verbInflection),
      (GradeLevel.second, GermanCompetencyId.sentencePunctuation),
      (GradeLevel.second, GermanCompetencyId.sentenceTypes),
      (GradeLevel.second, GermanCompetencyId.sentenceWriting),
    ];

    for (final entry in cases) {
      final current = GermanTaskCatalog.forCompetency(
        entry.$2,
      ).where((task) => task.recommendedFromGrade == entry.$1).toList();
      final bestRank = current
          .map(GermanTaskEvidencePriority.rank)
          .reduce((a, b) => a < b ? a : b);
      final strongest = current.where(
        (task) => GermanTaskEvidencePriority.rank(task) == bestRank,
      );
      expect(strongest, hasLength(12), reason: '${entry.$1}/${entry.$2}');
    }
  });

  test('each expanded lower-primary skill rotates to a fresh second round', () {
    final cases = <(GradeLevel, GermanCompetencyId)>[
      (GradeLevel.first, GermanCompetencyId.alphabeticalOrder),
      (GradeLevel.first, GermanCompetencyId.syllableSegmentation),
      (GradeLevel.first, GermanCompetencyId.sentenceWordOrder),
      (GradeLevel.second, GermanCompetencyId.verbInflection),
      (GradeLevel.second, GermanCompetencyId.sentencePunctuation),
      (GradeLevel.second, GermanCompetencyId.sentenceTypes),
      (GradeLevel.second, GermanCompetencyId.sentenceWriting),
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
  });

  test('new lower-primary tasks enforce their productive evidence', () {
    final alpha = GermanLowerPrimaryDepthTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g1-alpha-order-transport-depth',
    );
    final syllables = GermanLowerPrimaryDepthTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g1-syllable-build-ananas-depth',
    );
    final punctuation = GermanLowerPrimaryDepthTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g2-punctuation-film-depth',
    );
    final writing = GermanLowerPrimaryDepthTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g2-write-morning-school-depth',
    );

    expect(alpha.accepts('Auto Bus Fahrrad Zug'), isTrue);
    expect(alpha.accepts('Bus Auto Fahrrad Zug'), isFalse);
    expect(syllables.accepts('Ananas'), isTrue);
    expect(syllables.accepts('Ananis'), isFalse);
    expect(punctuation.acceptsSelection(<String>['Fragesatz', '?']), isTrue);
    expect(punctuation.acceptsSelection(<String>['Fragesatz', '.']), isFalse);
    expect(writing.accepts('Am Morgen fährt Lea zur Schule.'), isTrue);
    expect(writing.accepts('Lea fährt am Morgen zur Schule.'), isTrue);
    expect(writing.accepts('Am Morgen Lea fährt zur Schule.'), isFalse);
  });
}
