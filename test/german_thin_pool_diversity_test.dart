import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_task_evidence_priority.dart';
import 'package:rechenblitz/subjects/german/german_thin_pool_expansion_task_catalog.dart';
import 'package:rechenblitz/subjects/german/screens/german_training_screen.dart';

GermanSessionResult _completedRound(GradeLevel grade, List<GermanTask> tasks) =>
    GermanSessionResult(
      gradeLevel: grade,
      startedAt: DateTime(2026, 9, 20, 11),
      finishedAt: DateTime(2026, 9, 20, 11, 5),
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
  test('thin-pool expansion adds twenty-two active evidence tasks', () {
    expect(GermanThinPoolExpansionTaskCatalog.tasks, hasLength(22));
    expect(
      GermanThinPoolExpansionTaskCatalog.tasks
          .where(
            (task) =>
                task.recommendedFromGrade == GradeLevel.second &&
                task.competencyId == GermanCompetencyId.wordFamilies,
          )
          .length,
      12,
    );
    expect(
      GermanThinPoolExpansionTaskCatalog.tasks
          .where(
            (task) =>
                task.recommendedFromGrade == GradeLevel.fourth &&
                task.competencyId == GermanCompetencyId.readingInference,
          )
          .length,
      10,
    );
    for (final task in GermanThinPoolExpansionTaskCatalog.tasks) {
      expect(
        task.interaction,
        GermanTaskInteraction.tokenSelection,
        reason: task.id,
      );
      expect(task.isWellFormed, isTrue, reason: task.id);
    }
  });

  test('grade two word families now have twelve strongest current tasks', () {
    final current = GermanTaskCatalog.forCompetency(
      GermanCompetencyId.wordFamilies,
    ).where((task) => task.recommendedFromGrade == GradeLevel.second).toList();
    final bestRank = current
        .map(GermanTaskEvidencePriority.rank)
        .reduce((a, b) => a < b ? a : b);
    final strongest = current.where(
      (task) => GermanTaskEvidencePriority.rank(task) == bestRank,
    );

    expect(strongest, hasLength(12));
    expect(
      strongest.every(
        (task) => task.interaction == GermanTaskInteraction.tokenSelection,
      ),
      isTrue,
    );
  });

  test('grade four reading inference now has twelve active evidence tasks', () {
    final current = GermanTaskCatalog.forCompetency(
      GermanCompetencyId.readingInference,
    ).where((task) => task.recommendedFromGrade == GradeLevel.fourth).toList();
    final strongest = current.where(
      (task) => task.interaction == GermanTaskInteraction.tokenSelection,
    );

    expect(strongest, hasLength(12));
  });

  test('both expanded skills rotate to a completely fresh second round', () {
    final cases = <(GradeLevel, GermanCompetencyId)>[
      (GradeLevel.second, GermanCompetencyId.wordFamilies),
      (GradeLevel.fourth, GermanCompetencyId.readingInference),
    ];

    for (final entry in cases) {
      final first = GermanPracticePlanner.buildCompetencyRound(
        gradeLevel: entry.$1,
        competencyId: entry.$2,
        history: const <GermanSessionResult>[],
      );
      expect(first, hasLength(6), reason: entry.$2.name);
      expect(
        first.every(
          (task) => task.interaction == GermanTaskInteraction.tokenSelection,
        ),
        isTrue,
        reason: entry.$2.name,
      );

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

  test('word-family evidence needs all relatives and no lookalike', () {
    final task = GermanThinPoolExpansionTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g2-family-mark-write',
    );

    expect(
      task.acceptsSelection(<String>['schreiben', 'Schreiber', 'Schreibheft']),
      isTrue,
    );
    expect(task.acceptsSelection(<String>['schreiben', 'Schreiber']), isFalse);
    expect(
      task.acceptsSelection(<String>[
        'schreiben',
        'Schreiber',
        'Schreibheft',
        'schreien',
      ]),
      isFalse,
    );
  });

  test('reading inference needs the complete evidence chain', () {
    final task = GermanThinPoolExpansionTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-inference-evidence-power-outage',
    );

    expect(
      task.acceptsSelection(<String>[
        'Die Lampe bleibt dunkel.',
        'Der Kühlschrank ist plötzlich still.',
        'Auch im Nachbarhaus leuchten keine Fenster.',
      ]),
      isTrue,
    );
    expect(
      task.acceptsSelection(<String>[
        'Die Lampe bleibt dunkel.',
        'Der Kühlschrank ist plötzlich still.',
      ]),
      isFalse,
    );
    expect(
      task.acceptsSelection(<String>[
        'Die Lampe bleibt dunkel.',
        'Der Kühlschrank ist plötzlich still.',
        'Auch im Nachbarhaus leuchten keine Fenster.',
        'Auf dem Tisch liegt ein Buch.',
      ]),
      isFalse,
    );
  });

  testWidgets('new inference evidence can be corrected entirely by touch', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final task = GermanThinPoolExpansionTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-inference-evidence-flat-tire',
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
      'Der Hinterreifen liegt fast auf der Felge.',
      'Im Mantel steckt ein kleiner Nagel.',
      'Der Helm hängt am Lenker.',
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

    final helmet = find.widgetWithText(FilterChip, 'Der Helm hängt am Lenker.');
    await tester.ensureVisible(helmet);
    await tester.tap(helmet);
    final escapingAir = find.widgetWithText(
      FilterChip,
      'Nach dem Aufpumpen entweicht die Luft sofort wieder.',
    );
    await tester.ensureVisible(escapingAir);
    await tester.tap(escapingAir);
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(completed, isNotNull);
    expect(find.text('Runde geschafft'), findsWidgets);
  });
}
