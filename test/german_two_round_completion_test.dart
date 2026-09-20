import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_task_evidence_priority.dart';
import 'package:rechenblitz/subjects/german/german_two_round_completion_task_catalog.dart';
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
  test('two-round completion catalog adds twenty-two valid tasks', () {
    expect(GermanTwoRoundCompletionTaskCatalog.tasks, hasLength(22));
    final counts = <(GradeLevel, GermanCompetencyId), int>{};
    for (final task in GermanTwoRoundCompletionTaskCatalog.tasks) {
      expect(task.isWellFormed, isTrue, reason: task.id);
      final key = (task.recommendedFromGrade, task.competencyId);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    expect(counts[(GradeLevel.third, GermanCompetencyId.wordFamilies)], 6);
    expect(counts[(GradeLevel.fourth, GermanCompetencyId.wordFamilies)], 6);
    expect(counts[(GradeLevel.fourth, GermanCompetencyId.compoundWords)], 6);
    expect(
      counts[(GradeLevel.third, GermanCompetencyId.sentenceConstituents)],
      2,
    );
    expect(
      counts[(GradeLevel.fourth, GermanCompetencyId.sentenceConstituents)],
      2,
    );
  });

  test('every current-grade German skill now has two strong full rounds', () {
    for (final grade in GradeLevel.values) {
      for (final competency in GermanCompetencyId.values) {
        final current = GermanTaskCatalog.forCompetency(
          competency,
        ).where((task) => task.recommendedFromGrade == grade).toList();
        if (current.isEmpty) continue;
        final bestRank = current
            .map(GermanTaskEvidencePriority.rank)
            .reduce((a, b) => a < b ? a : b);
        final strongest = current.where(
          (task) => GermanTaskEvidencePriority.rank(task) == bestRank,
        );
        expect(
          strongest.length,
          greaterThanOrEqualTo(12),
          reason: '${grade.name}/${competency.name}',
        );
      }
    }
  });

  test('the five completed pools rotate to a fully fresh second round', () {
    final cases = <(GradeLevel, GermanCompetencyId)>[
      (GradeLevel.third, GermanCompetencyId.wordFamilies),
      (GradeLevel.third, GermanCompetencyId.sentenceConstituents),
      (GradeLevel.fourth, GermanCompetencyId.wordFamilies),
      (GradeLevel.fourth, GermanCompetencyId.compoundWords),
      (GradeLevel.fourth, GermanCompetencyId.sentenceConstituents),
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
        reason: '${entry.$1.name}/${entry.$2.name}',
      );
    }
  });

  test('advanced compound building requires every part in order', () {
    final task = GermanTwoRoundCompletionTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-compound-build-garden-tap',
    );
    expect(task.accepts('Schulgartenwasserhahn'), isTrue);
    expect(task.accepts('Schulgartenhahn'), isFalse);
    expect(task.accepts('Schulwassergartenhahn'), isFalse);
  });

  test('word family marking rejects lookalikes and missing relatives', () {
    final task = GermanTwoRoundCompletionTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-family-mark-speak',
    );
    expect(
      task.acceptsSelection(<String>['sprechen', 'Sprecher', 'Sprechstunde']),
      isTrue,
    );
    expect(task.acceptsSelection(<String>['sprechen', 'Sprecher']), isFalse);
    expect(
      task.acceptsSelection(<String>['sprechen', 'Sprecher', 'Specht']),
      isFalse,
    );
  });

  test(
    'sentence constituent marking requires both requested chunks exactly',
    () {
      final task = GermanTwoRoundCompletionTaskCatalog.tasks.firstWhere(
        (task) => task.id == 'g4-constituents-consideration-quiet',
      );
      expect(
        task.acceptsSelection(<String>[
          'Aus Rücksicht auf die Nachbarn',
          'leise',
        ]),
        isTrue,
      );
      expect(
        task.acceptsSelection(<String>['Aus Rücksicht auf die Nachbarn']),
        isFalse,
      );
      expect(
        task.acceptsSelection(<String>[
          'Aus Rücksicht auf die Nachbarn',
          'Tom',
          'leise',
        ]),
        isFalse,
      );
    },
  );

  testWidgets('four-part compound remains fully solvable by touch', (
    tester,
  ) async {
    final task = GermanTwoRoundCompletionTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-compound-build-garden-tap',
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

    for (final chunk in <String>['Schul', 'garten', 'wasser', 'hahn']) {
      final button = find.widgetWithText(FilledButton, chunk);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
    }
    expect(find.text('Schulgartenwasserhahn'), findsOneWidget);
    final submit = find.byKey(const ValueKey('german-word-builder-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(find.text('Runde geschafft'), findsWidgets);
  });
}
