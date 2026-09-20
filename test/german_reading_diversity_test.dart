import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_reading_diversity_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_task_evidence_priority.dart';
import 'package:rechenblitz/subjects/german/screens/german_training_screen.dart';

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
            responseMs: 1400,
          ),
      ],
    );

void main() {
  test('reading diversity catalog adds eighteen active evidence tasks', () {
    expect(GermanReadingDiversityTaskCatalog.tasks, hasLength(18));
    final counts = <(GradeLevel, GermanCompetencyId), int>{};
    for (final task in GermanReadingDiversityTaskCatalog.tasks) {
      expect(
        task.interaction,
        GermanTaskInteraction.tokenSelection,
        reason: task.id,
      );
      expect(task.isWellFormed, isTrue, reason: task.id);
      final key = (task.recommendedFromGrade, task.competencyId);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    expect(counts, <(GradeLevel, GermanCompetencyId), int>{
      (GradeLevel.first, GermanCompetencyId.sentenceComprehension): 6,
      (GradeLevel.second, GermanCompetencyId.textInformation): 6,
      (GradeLevel.fourth, GermanCompetencyId.textMainIdea): 6,
    });
  });

  test('three reading skills now have twelve strongest current tasks', () {
    final cases = <(GradeLevel, GermanCompetencyId)>[
      (GradeLevel.first, GermanCompetencyId.sentenceComprehension),
      (GradeLevel.second, GermanCompetencyId.textInformation),
      (GradeLevel.fourth, GermanCompetencyId.textMainIdea),
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
      expect(strongest, hasLength(12), reason: entry.$2.name);
    }
  });

  test('reading skills rotate to a completely fresh second round', () {
    final cases = <(GradeLevel, GermanCompetencyId)>[
      (GradeLevel.first, GermanCompetencyId.sentenceComprehension),
      (GradeLevel.second, GermanCompetencyId.textInformation),
      (GradeLevel.fourth, GermanCompetencyId.textMainIdea),
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

  test('sentence comprehension requires both requested sentence parts', () {
    final task = GermanReadingDiversityTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g1-read-evidence-lina-dog',
    );
    expect(task.acceptsSelection(<String>['Lina', 'den Hund']), isTrue);
    expect(task.acceptsSelection(<String>['Lina']), isFalse);
    expect(
      task.acceptsSelection(<String>['Lina', 'den Hund', 'im Garten']),
      isFalse,
    );
  });

  test('text information rejects a nearby but unasked detail', () {
    final task = GermanReadingDiversityTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g2-read-info-trip-meeting',
    );
    expect(
      task.acceptsSelection(<String>['um halb acht', 'vor der Schule']),
      isTrue,
    );
    expect(
      task.acceptsSelection(<String>['um halb acht', 'um acht Uhr']),
      isFalse,
    );
  });

  test('main idea excludes decorative details', () {
    final task = GermanReadingDiversityTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-read-main-repair',
    );
    expect(
      task.acceptsSelection(<String>[
        'Kaputte Dinge müssen nicht sofort weggeworfen werden.',
        'Eine Reparatur spart oft Rohstoffe und Geld.',
      ]),
      isTrue,
    );
    expect(
      task.acceptsSelection(<String>[
        'Eine Reparatur spart oft Rohstoffe und Geld.',
        'Werkzeugkästen können viele Fächer haben.',
      ]),
      isFalse,
    );
  });

  testWidgets('new main-idea evidence can be corrected entirely by touch', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final task = GermanReadingDiversityTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-read-main-breakfast',
    );
    GermanSessionResult? completed;

    await tester.pumpWidget(
      MaterialApp(
        home: GermanTrainingScreen(
          gradeLevel: GradeLevel.fourth,
          tasks: <GermanTask>[task],
          speak: (_) async {},
          onComplete: (result) => completed = result,
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final value in <String>[
      'Ein ausgewogenes Frühstück liefert dem Körper Energie.',
      'Manche Müslischalen sind blau.',
    ]) {
      final chip = find.widgetWithText(FilterChip, value);
      await tester.ensureVisible(chip);
      await tester.tap(chip);
    }
    final submit = find.byKey(const ValueKey('german-token-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(completed, isNull);

    final decorative = find.widgetWithText(
      FilterChip,
      'Manche Müslischalen sind blau.',
    );
    await tester.ensureVisible(decorative);
    await tester.tap(decorative);
    final concentration = find.widgetWithText(
      FilterChip,
      'Wer morgens etwas isst, kann sich in der Schule oft besser konzentrieren.',
    );
    await tester.ensureVisible(concentration);
    await tester.tap(concentration);
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(completed, isNotNull);
    expect(find.text('Runde geschafft'), findsWidgets);
  });
}
