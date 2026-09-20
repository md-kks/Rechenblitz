import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_answer_feedback.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_competency_catalog.dart';
import 'package:rechenblitz/subjects/german/german_learning_domain.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_support_catalog.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/german_vocabulary_touch_task_catalog.dart';
import 'package:rechenblitz/subjects/german/screens/german_training_screen.dart';

void main() {
  test('upper-primary vocabulary touch catalog is valid', () {
    expect(GermanVocabularyTouchTaskCatalog.tasks, hasLength(18));
    expect(
      GermanVocabularyTouchTaskCatalog.tasks
          .map((task) => task.recommendedFromGrade)
          .toSet(),
      <GradeLevel>{GradeLevel.third, GradeLevel.fourth},
    );
    expect(
      GermanVocabularyTouchTaskCatalog.tasks
          .where(
            (task) => task.interaction == GermanTaskInteraction.tokenSelection,
          )
          .length,
      12,
    );
    expect(
      GermanVocabularyTouchTaskCatalog.tasks
          .where(
            (task) => task.interaction == GermanTaskInteraction.wordBuilder,
          )
          .length,
      6,
    );
    for (final task in GermanVocabularyTouchTaskCatalog.tasks) {
      expect(task.isWellFormed, isTrue, reason: task.id);
    }
  });

  test('word-family marking requires the exact related words', () {
    final task = GermanVocabularyTouchTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g3-family-mark-write',
    );
    expect(
      task.acceptsSelection(<String>['schreiben', 'Schreiber', 'Schreibheft']),
      isTrue,
    );
    expect(
      task.acceptsSelection(<String>['schreiben', 'Schreiber', 'schreien']),
      isFalse,
    );
  });

  test('multi-part compounds must be assembled exactly', () {
    final task = GermanVocabularyTouchTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-compound-build-rain-tank',
    );
    expect(task.accepts('Regenwasserbehälter'), isTrue);
    expect(task.accepts('Regenregelwasserbehälter'), isFalse);
    expect(task.accepts('Wasserregenbehälter'), isFalse);
  });

  test('targeted upper-primary vocabulary prefers active tasks', () {
    final cases = <(GradeLevel, GermanCompetencyId)>[
      (GradeLevel.third, GermanCompetencyId.wordFamilies),
      (GradeLevel.fourth, GermanCompetencyId.wordFamilies),
      (GradeLevel.fourth, GermanCompetencyId.compoundWords),
    ];
    for (final entry in cases) {
      final round = GermanPracticePlanner.buildCompetencyRound(
        gradeLevel: entry.$1,
        competencyId: entry.$2,
        history: const <GermanSessionResult>[],
      );
      expect(
        round.first.interaction == GermanTaskInteraction.tokenSelection ||
            round.first.interaction == GermanTaskInteraction.wordBuilder,
        isTrue,
        reason: '${entry.$1.name}/${entry.$2.name}',
      );
    }
  });

  test('third and fourth grade daily vocabulary slots are active', () {
    for (final grade in <GradeLevel>[GradeLevel.third, GradeLevel.fourth]) {
      final round = GermanPracticePlanner.buildDailyRound(
        gradeLevel: grade,
        history: const <GermanSessionResult>[],
      );
      final vocabulary = round.where(
        (task) =>
            GermanCompetencyCatalog.definition(task.competencyId).domain ==
            GermanLearningDomain.vocabulary,
      );
      expect(vocabulary, hasLength(2), reason: grade.name);
      expect(
        vocabulary.every(
          (task) => task.interaction != GermanTaskInteraction.singleChoice,
        ),
        isTrue,
        reason: grade.name,
      );
    }
  });

  test('vocabulary hints distinguish family and compound strategies', () {
    final family = GermanVocabularyTouchTaskCatalog.tasks.first;
    final compound = GermanVocabularyTouchTaskCatalog.tasks.firstWhere(
      (task) => task.competencyId == GermanCompetencyId.compoundWords,
    );
    expect(
      GermanSupportCatalog.firstHintForTask(family),
      contains('Wortstamm'),
    );
    expect(
      GermanSupportCatalog.secondHintForTask(family),
      contains('Grundbedeutung'),
    );
    expect(
      GermanSupportCatalog.firstHintForTask(compound),
      contains('Grundwort'),
    );
    expect(
      GermanSupportCatalog.secondHintForTask(compound),
      contains('zuletzt'),
    );
    expect(
      GermanAnswerFeedback.forIncorrect(family, 'schreien'),
      contains('ähnlich'),
    );
  });

  testWidgets('word-family task can be corrected entirely by touch', (
    tester,
  ) async {
    final task = GermanVocabularyTouchTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g3-family-mark-play',
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

    for (final value in <String>['spielen', 'Spieler', 'Spiegel']) {
      await tester.tap(find.widgetWithText(FilterChip, value));
    }
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('german-token-submit')));
    await tester.pump();
    expect(find.textContaining('Wortstamm'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Spiegel'));
    await tester.tap(find.widgetWithText(FilterChip, 'Spielplatz'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('german-token-submit')));
    await tester.pump();
    expect(find.text('Runde geschafft'), findsWidgets);
  });
}
