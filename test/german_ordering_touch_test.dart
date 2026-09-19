import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_ordering_touch_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_support_catalog.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/screens/german_training_screen.dart';

void main() {
  test('ordering touch catalog is valid across grades one to four', () {
    expect(GermanOrderingTouchTaskCatalog.tasks, hasLength(24));
    expect(
      GermanOrderingTouchTaskCatalog.tasks
          .map((task) => task.recommendedFromGrade)
          .toSet(),
      <GradeLevel>{GradeLevel.first, GradeLevel.third, GradeLevel.fourth},
    );
    for (final task in GermanOrderingTouchTaskCatalog.tasks) {
      expect(task.interaction, GermanTaskInteraction.wordOrder);
      expect(task.isWellFormed, isTrue, reason: task.id);
    }
  });

  test('ordering tasks require the complete correct sequence', () {
    final dictionary = GermanOrderingTouchTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g3-dictionary-order-band',
    );
    final sequence = GermanOrderingTouchTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-sequence-library-order',
    );

    expect(dictionary.accepts('Band Bank Bart'), isTrue);
    expect(dictionary.accepts('Bank Band Bart'), isFalse);
    expect(
      sequence.accepts(
        'Im Katalog suchen. Regalnummer notieren. Buch im Regal finden. Mit dem Ausweis ausleihen.',
      ),
      isTrue,
    );
  });

  test('targeted practice surfaces active ordering tasks', () {
    final cases = <(GradeLevel, GermanCompetencyId)>[
      (GradeLevel.first, GermanCompetencyId.alphabeticalOrder),
      (GradeLevel.third, GermanCompetencyId.dictionarySkills),
      (GradeLevel.third, GermanCompetencyId.textSequence),
      (GradeLevel.fourth, GermanCompetencyId.dictionarySkills),
      (GradeLevel.fourth, GermanCompetencyId.textSequence),
    ];

    for (final entry in cases) {
      final round = GermanPracticePlanner.buildCompetencyRound(
        gradeLevel: entry.$1,
        competencyId: entry.$2,
        history: const <GermanSessionResult>[],
      );
      expect(
        round.any(
          (task) => task.interaction == GermanTaskInteraction.wordOrder,
        ),
        isTrue,
        reason: '${entry.$1.name}/${entry.$2.name}',
      );
    }
  });

  test('ordering hints match alphabet and text sequence goals', () {
    final alphabet = GermanOrderingTouchTaskCatalog.tasks.first;
    final sequence = GermanOrderingTouchTaskCatalog.tasks.firstWhere(
      (task) => task.competencyId == GermanCompetencyId.textSequence,
    );

    expect(
      GermanSupportCatalog.firstHintForTask(alphabet),
      contains('zweiten'),
    );
    expect(
      GermanSupportCatalog.secondHintForTask(sequence),
      contains('Übergang'),
    );
  });

  testWidgets('text sequence uses step-specific touch wording', (tester) async {
    final task = GermanOrderingTouchTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g3-sequence-cocoa-order',
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

    expect(
      find.text('Tippe die Schritte in der richtigen Reihenfolge an.'),
      findsOneWidget,
    );
    final firstChoice = find.widgetWithText(FilledButton, 'Milch erwärmen.');
    await tester.tap(firstChoice);
    await tester.pump();
    expect(find.text('Letzten Schritt zurück'), findsOneWidget);
  });
}
