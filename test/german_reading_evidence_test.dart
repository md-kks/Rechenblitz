import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_reading_evidence_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_support_catalog.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/screens/german_training_screen.dart';

void main() {
  test('reading evidence catalog is valid across grades one to four', () {
    expect(GermanReadingEvidenceTaskCatalog.tasks, hasLength(24));
    expect(
      GermanReadingEvidenceTaskCatalog.tasks
          .map((task) => task.recommendedFromGrade)
          .toSet(),
      <GradeLevel>{
        GradeLevel.first,
        GradeLevel.second,
        GradeLevel.third,
        GradeLevel.fourth,
      },
    );
    expect(
      GermanReadingEvidenceTaskCatalog.tasks
          .map((task) => task.competencyId)
          .toSet(),
      <GermanCompetencyId>{
        GermanCompetencyId.sentenceComprehension,
        GermanCompetencyId.textInformation,
        GermanCompetencyId.readingInference,
        GermanCompetencyId.textMainIdea,
      },
    );
    for (final task in GermanReadingEvidenceTaskCatalog.tasks) {
      expect(task.interaction, GermanTaskInteraction.tokenSelection);
      expect(task.isWellFormed, isTrue, reason: task.id);
    }
  });

  test('reading evidence requires the exact supporting set', () {
    final task = GermanReadingEvidenceTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g3-evidence-inference-cold',
    );

    expect(
      task.acceptsSelection(<String>[
        'Lea zieht Mütze und Schal an.',
        'Sie nimmt dicke Handschuhe mit.',
      ]),
      isTrue,
    );
    expect(
      task.acceptsSelection(<String>['Lea zieht Mütze und Schal an.']),
      isFalse,
    );
    expect(
      task.acceptsSelection(<String>[
        'Lea zieht Mütze und Schal an.',
        'Sie nimmt dicke Handschuhe mit.',
        'Ihr Rucksack ist blau.',
      ]),
      isFalse,
    );
  });

  test('targeted reading practice surfaces evidence marking', () {
    final cases = <(GradeLevel, GermanCompetencyId)>[
      (GradeLevel.first, GermanCompetencyId.sentenceComprehension),
      (GradeLevel.second, GermanCompetencyId.textInformation),
      (GradeLevel.third, GermanCompetencyId.readingInference),
      (GradeLevel.fourth, GermanCompetencyId.textMainIdea),
    ];

    for (final entry in cases) {
      final round = GermanPracticePlanner.buildCompetencyRound(
        gradeLevel: entry.$1,
        competencyId: entry.$2,
        history: const <GermanSessionResult>[],
      );
      expect(
        round.any(
          (task) => task.interaction == GermanTaskInteraction.tokenSelection,
        ),
        isTrue,
        reason: '${entry.$1.name}/${entry.$2.name}',
      );
    }
  });

  test('reading evidence hints focus on proof instead of guessing', () {
    final task = GermanReadingEvidenceTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-evidence-inference-wet-dog',
    );

    expect(
      GermanSupportCatalog.firstHintForTask(task),
      contains('wirklich belegen'),
    );
    expect(GermanSupportCatalog.secondHintForTask(task), contains('begründen'));
  });

  testWidgets('read-aloud evidence marking stays assisted reading', (
    tester,
  ) async {
    final task = GermanReadingEvidenceTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g1-evidence-dog-basket',
    );
    GermanSessionResult? completed;

    await tester.pumpWidget(
      MaterialApp(
        home: GermanTrainingScreen(
          gradeLevel: GradeLevel.first,
          tasks: <GermanTask>[task],
          speak: (_) async {},
          autoSpeak: (_) async {},
          readAloudEnabled: true,
          onComplete: (result) => completed = result,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(FilterChip, 'Der Hund'));
    await tester.tap(find.widgetWithText(FilterChip, 'im Korb'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('german-token-submit')));
    await tester.pump();

    final result = completed!.taskResults.single;
    expect(result.correctFirstTry, isTrue);
    expect(result.usedReadAloud, isTrue);
    expect(result.independentCorrectFirstTry, isFalse);
  });

  testWidgets('evidence marking without read-aloud is independent reading', (
    tester,
  ) async {
    final task = GermanReadingEvidenceTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g1-evidence-lina-park',
    );
    GermanSessionResult? completed;

    await tester.pumpWidget(
      MaterialApp(
        home: GermanTrainingScreen(
          gradeLevel: GradeLevel.first,
          tasks: <GermanTask>[task],
          speak: (_) async {},
          readAloudEnabled: false,
          onComplete: (result) => completed = result,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(FilterChip, 'Lina'));
    await tester.tap(find.widgetWithText(FilterChip, 'zum Park'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('german-token-submit')));
    await tester.pump();

    final result = completed!.taskResults.single;
    expect(result.correctFirstTry, isTrue);
    expect(result.usedReadAloud, isFalse);
    expect(result.independentCorrectFirstTry, isTrue);
  });
}
