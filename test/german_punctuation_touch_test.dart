import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_punctuation_touch_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_support_catalog.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/screens/german_training_screen.dart';

void main() {
  test('punctuation touch catalog is valid across grades two and four', () {
    expect(GermanPunctuationTouchTaskCatalog.tasks, hasLength(25));
    expect(
      GermanPunctuationTouchTaskCatalog.tasks
          .map((task) => task.recommendedFromGrade)
          .toSet(),
      <GradeLevel>{GradeLevel.second, GradeLevel.fourth},
    );
    expect(
      GermanPunctuationTouchTaskCatalog.tasks
          .where(
            (task) => task.interaction == GermanTaskInteraction.tokenSelection,
          )
          .length,
      13,
    );
    expect(
      GermanPunctuationTouchTaskCatalog.tasks
          .where(
            (task) => task.interaction == GermanTaskInteraction.wordBuilder,
          )
          .length,
      12,
    );
    for (final task in GermanPunctuationTouchTaskCatalog.tasks) {
      expect(task.isWellFormed, isTrue, reason: task.id);
    }
  });

  test('sentence type pairing requires type and punctuation together', () {
    final task = GermanPunctuationTouchTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g2-punctuation-pair-heft',
    );

    expect(task.acceptsSelection(<String>['Fragesatz', '?']), isTrue);
    expect(task.acceptsSelection(<String>['Fragesatz']), isFalse);
    expect(task.acceptsSelection(<String>['Fragesatz', '.']), isFalse);
  });

  test('direct speech builders enforce German punctuation placement', () {
    final question = GermanPunctuationTouchTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-direct-build-mia-after-question',
    );
    final call = GermanPunctuationTouchTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-direct-build-tom-after-call',
    );

    expect(question.accepts('„Kommst du morgen?“, fragt Mia.'), isTrue);
    expect(question.accepts('„Kommst du morgen?“ fragt Mia.'), isFalse);
    expect(call.accepts('„Halt sofort an!“, ruft Tom.'), isTrue);
    expect(call.accepts('„Halt sofort an!“ ruft Tom.'), isFalse);
  });

  test('targeted punctuation practice surfaces active touch tasks', () {
    final cases = <(GradeLevel, GermanCompetencyId)>[
      (GradeLevel.second, GermanCompetencyId.sentencePunctuation),
      (GradeLevel.second, GermanCompetencyId.sentenceTypes),
      (GradeLevel.fourth, GermanCompetencyId.directSpeechPunctuation),
    ];

    for (final entry in cases) {
      final round = GermanPracticePlanner.buildCompetencyRound(
        gradeLevel: entry.$1,
        competencyId: entry.$2,
        history: const <GermanSessionResult>[],
      );
      expect(
        round.any(
          (task) =>
              task.interaction == GermanTaskInteraction.tokenSelection ||
              task.interaction == GermanTaskInteraction.wordBuilder,
        ),
        isTrue,
        reason: '${entry.$1.name}/${entry.$2.name}',
      );
    }
  });

  test('punctuation hints match the active interaction', () {
    final pair = GermanPunctuationTouchTaskCatalog.tasks.first;
    final speech = GermanPunctuationTouchTaskCatalog.tasks.firstWhere(
      (task) => task.competencyId == GermanCompetencyId.directSpeechPunctuation,
    );

    expect(GermanSupportCatalog.firstHintForTask(pair), contains('Satzart'));
    expect(
      GermanSupportCatalog.firstHintForTask(speech),
      contains('Begleitsatz'),
    );
    expect(
      GermanSupportCatalog.secondHintForTask(speech),
      contains('Anführungszeichen'),
    );
  });

  testWidgets('direct speech builder uses sentence-specific touch wording', (
    tester,
  ) async {
    final task = GermanPunctuationTouchTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-direct-build-mia-statement',
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

    expect(find.text('Baue hier den richtig gesetzten Satz.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Mia sagt: „'));
    await tester.tap(find.widgetWithText(FilledButton, 'Ich komme gleich'));
    await tester.tap(find.widgetWithText(FilledButton, '.“'));
    await tester.pump();

    expect(find.text('Mia sagt: „Ich komme gleich.“'), findsOneWidget);
    expect(find.textContaining('Satz- und Zeichenbausteine:'), findsOneWidget);
  });
}
