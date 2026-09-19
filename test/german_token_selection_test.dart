import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_grammar_touch_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_round_draft.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/screens/german_training_screen.dart';

void main() {
  test('grammar touch catalog is valid and spans grades one to three', () {
    expect(GermanGrammarTouchTaskCatalog.tasks, hasLength(20));
    expect(
      GermanGrammarTouchTaskCatalog.tasks
          .map((task) => task.recommendedFromGrade)
          .toSet(),
      <GradeLevel>{GradeLevel.first, GradeLevel.second, GradeLevel.third},
    );
    for (final task in GermanGrammarTouchTaskCatalog.tasks) {
      expect(task.interaction, GermanTaskInteraction.tokenSelection);
      expect(task.isWellFormed, isTrue, reason: task.id);
    }
  });

  test('token selection requires exactly the intended marked parts', () {
    final task = GermanGrammarTouchTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g2-mark-verbs-mia',
    );

    expect(task.acceptsSelection(<String>['malt', 'singt']), isTrue);
    expect(task.acceptsSelection(<String>['singt', 'malt']), isTrue);
    expect(task.acceptsSelection(<String>['malt']), isFalse);
    expect(task.acceptsSelection(<String>['malt', 'singt', 'heute']), isFalse);
  });

  test('targeted grammar practice includes active touch marking', () {
    final round = GermanPracticePlanner.buildCompetencyRound(
      gradeLevel: GradeLevel.second,
      competencyId: GermanCompetencyId.verbRecognition,
      history: const <GermanSessionResult>[],
    );

    expect(
      round.any(
        (task) => task.interaction == GermanTaskInteraction.tokenSelection,
      ),
      isTrue,
    );
  });

  testWidgets('grammar marking can be corrected entirely by touch', (
    tester,
  ) async {
    final task = GermanGrammarTouchTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g2-mark-verbs-mia',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: GermanTrainingScreen(
          gradeLevel: GradeLevel.second,
          tasks: <GermanTask>[task],
          speak: (_) async {},
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilterChip, 'malt'));
    await tester.tap(find.widgetWithText(FilterChip, 'heute'));
    await tester.pump();
    final submit = find.byKey(const ValueKey('german-token-submit'));
    await tester.tap(submit);
    await tester.pump();

    expect(find.textContaining('Markierung zu viel'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'heute'));
    await tester.tap(find.widgetWithText(FilterChip, 'singt'));
    await tester.pump();
    await tester.tap(submit);
    await tester.pump();

    expect(find.text('Runde geschafft'), findsWidgets);
  });

  testWidgets('partial grammar marking survives a resumed round', (
    tester,
  ) async {
    final task = GermanGrammarTouchTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g2-mark-verbs-mia',
    );
    final draft = GermanRoundDraft(
      gradeLevel: GradeLevel.second,
      taskIds: <String>[task.id],
      currentIndex: 0,
      startedAt: DateTime(2026, 9, 19, 9),
      updatedAt: DateTime(2026, 9, 19, 9, 1),
      completedResults: const <GermanTaskResult>[],
      currentOrderedWords: const <String>['malt'],
    );
    GermanRoundDraft? saved;

    await tester.pumpWidget(
      MaterialApp(
        home: GermanTrainingScreen(
          gradeLevel: GradeLevel.second,
          tasks: <GermanTask>[task],
          speak: (_) async {},
          draft: draft,
          onDraftChanged: (value) => saved = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final malt = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'malt'),
    );
    expect(malt.selected, isTrue);

    await tester.tap(find.widgetWithText(FilterChip, 'singt'));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.currentOrderedWords.toSet(), <String>{'malt', 'singt'});
  });
}
