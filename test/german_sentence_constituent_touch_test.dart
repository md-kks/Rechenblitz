import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_round_draft.dart';
import 'package:rechenblitz/subjects/german/german_sentence_constituent_touch_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_support_catalog.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/screens/german_training_screen.dart';

void main() {
  test(
    'sentence constituent touch catalog is valid for grades three and four',
    () {
      expect(GermanSentenceConstituentTouchTaskCatalog.tasks, hasLength(20));
      expect(
        GermanSentenceConstituentTouchTaskCatalog.tasks
            .map((task) => task.recommendedFromGrade)
            .toSet(),
        <GradeLevel>{GradeLevel.third, GradeLevel.fourth},
      );
      for (final task in GermanSentenceConstituentTouchTaskCatalog.tasks) {
        expect(task.competencyId, GermanCompetencyId.sentenceConstituents);
        expect(task.interaction, GermanTaskInteraction.tokenSelection);
        expect(task.acceptedAnswers, hasLength(2), reason: task.id);
        expect(task.isWellFormed, isTrue, reason: task.id);
      }
    },
  );

  test('constituent marking requires both exact sentence parts', () {
    final task = GermanSentenceConstituentTouchTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-constituents-why-how-snow',
    );

    expect(
      task.acceptsSelection(<String>[
        'Wegen starken Schnees',
        'besonders langsam',
      ]),
      isTrue,
    );
    expect(task.acceptsSelection(<String>['Wegen starken Schnees']), isFalse);
    expect(
      task.acceptsSelection(<String>['Wegen starken Schnees', 'heute']),
      isFalse,
    );
  });

  test('targeted sentence constituent practice prefers active marking', () {
    for (final grade in <GradeLevel>[GradeLevel.third, GradeLevel.fourth]) {
      final round = GermanPracticePlanner.buildCompetencyRound(
        gradeLevel: grade,
        competencyId: GermanCompetencyId.sentenceConstituents,
        history: const <GermanSessionResult>[],
      );
      expect(
        round.any(
          (task) => task.interaction == GermanTaskInteraction.tokenSelection,
        ),
        isTrue,
        reason: grade.name,
      );
    }
  });

  test('constituent hints teach question and movement tests', () {
    final task = GermanSentenceConstituentTouchTaskCatalog.tasks.first;
    expect(GermanSupportCatalog.firstHintForTask(task), contains('Frageprobe'));
    expect(
      GermanSupportCatalog.secondHintForTask(task),
      contains('Verschiebeprobe'),
    );
  });

  testWidgets('sentence constituent task can be corrected entirely by touch', (
    tester,
  ) async {
    final task = GermanSentenceConstituentTouchTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g3-constituents-when-means-school',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: GermanTrainingScreen(
          gradeLevel: GradeLevel.third,
          tasks: <GermanTask>[task],
          speak: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'Am Morgen'));
    await tester.tap(find.widgetWithText(FilterChip, 'Lea'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('german-token-submit')));
    await tester.pump();
    expect(find.textContaining('Frageprobe'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Lea'));
    await tester.tap(find.widgetWithText(FilterChip, 'mit dem Bus'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('german-token-submit')));
    await tester.pump();
    expect(find.text('Runde geschafft'), findsWidgets);
  });

  testWidgets('partial sentence constituent marking survives resume', (
    tester,
  ) async {
    final task = GermanSentenceConstituentTouchTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-constituents-why-how-snow',
    );
    final draft = GermanRoundDraft(
      gradeLevel: GradeLevel.fourth,
      taskIds: <String>[task.id],
      currentIndex: 0,
      startedAt: DateTime(2026, 9, 19, 20),
      updatedAt: DateTime(2026, 9, 19, 20, 1),
      completedResults: const <GermanTaskResult>[],
      currentOrderedWords: const <String>['Wegen starken Schnees'],
    );
    GermanRoundDraft? saved;

    await tester.pumpWidget(
      MaterialApp(
        home: GermanTrainingScreen(
          gradeLevel: GradeLevel.fourth,
          tasks: <GermanTask>[task],
          speak: (_) async {},
          draft: draft,
          onDraftChanged: (value) => saved = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final reason = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Wegen starken Schnees'),
    );
    expect(reason.selected, isTrue);
    await tester.tap(find.widgetWithText(FilterChip, 'besonders langsam'));
    await tester.pump();
    expect(saved, isNotNull);
    expect(saved!.currentOrderedWords.toSet(), <String>{
      'Wegen starken Schnees',
      'besonders langsam',
    });
  });
}
