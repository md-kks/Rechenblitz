import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_grade_two_diversity_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_task_evidence_priority.dart';
import 'package:rechenblitz/subjects/german/screens/german_training_screen.dart';

GermanSessionResult _completedRound(List<GermanTask> tasks) =>
    GermanSessionResult(
      gradeLevel: GradeLevel.second,
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
  test('grade-two diversity catalog adds forty active tasks', () {
    expect(GermanGradeTwoDiversityTaskCatalog.tasks, hasLength(40));
    final counts = <GermanCompetencyId, int>{};
    for (final task in GermanGradeTwoDiversityTaskCatalog.tasks) {
      expect(task.recommendedFromGrade, GradeLevel.second, reason: task.id);
      expect(task.isWellFormed, isTrue, reason: task.id);
      counts[task.competencyId] = (counts[task.competencyId] ?? 0) + 1;
    }
    expect(counts, <GermanCompetencyId, int>{
      GermanCompetencyId.nounArticle: 8,
      GermanCompetencyId.singularPlural: 8,
      GermanCompetencyId.adjectiveRecognition: 8,
      GermanCompetencyId.verbRecognition: 8,
      GermanCompetencyId.oralRetelling: 8,
    });
  });

  test('all German task ids remain unique', () {
    final ids = GermanTaskCatalog.tasks.map((task) => task.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('five grade-two skills now have twelve strongest current tasks', () {
    for (final competency in <GermanCompetencyId>[
      GermanCompetencyId.nounArticle,
      GermanCompetencyId.singularPlural,
      GermanCompetencyId.adjectiveRecognition,
      GermanCompetencyId.verbRecognition,
      GermanCompetencyId.oralRetelling,
    ]) {
      final current = GermanTaskCatalog.forCompetency(competency)
          .where((task) => task.recommendedFromGrade == GradeLevel.second)
          .toList();
      final bestRank = current
          .map(GermanTaskEvidencePriority.rank)
          .reduce((a, b) => a < b ? a : b);
      final strongest = current.where(
        (task) => GermanTaskEvidencePriority.rank(task) == bestRank,
      );
      expect(strongest, hasLength(12), reason: competency.name);
    }
  });

  test('each expanded grade-two skill rotates to a fresh second round', () {
    for (final competency in <GermanCompetencyId>[
      GermanCompetencyId.nounArticle,
      GermanCompetencyId.singularPlural,
      GermanCompetencyId.adjectiveRecognition,
      GermanCompetencyId.verbRecognition,
      GermanCompetencyId.oralRetelling,
    ]) {
      final first = GermanPracticePlanner.buildCompetencyRound(
        gradeLevel: GradeLevel.second,
        competencyId: competency,
        history: const <GermanSessionResult>[],
      );
      expect(first, hasLength(6), reason: competency.name);
      final second = GermanPracticePlanner.buildCompetencyRound(
        gradeLevel: GradeLevel.second,
        competencyId: competency,
        history: <GermanSessionResult>[_completedRound(first)],
      );
      expect(second, hasLength(6), reason: competency.name);
      expect(
        second
            .map((task) => task.id)
            .toSet()
            .intersection(first.map((task) => task.id).toSet()),
        isEmpty,
        reason: competency.name,
      );
    }
  });

  test('plural builders require the exact plural form', () {
    final task = GermanGradeTwoDiversityTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g2-plural-apples-build',
    );
    expect(task.accepts('Äpfel'), isTrue);
    expect(task.accepts('Apfel'), isFalse);
    expect(task.accepts('ÄpfelAp'), isFalse);
  });

  test('adjective marking requires the complete exact set', () {
    final task = GermanGradeTwoDiversityTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g2-mark-adjectives-stone',
    );
    expect(task.acceptsSelection(<String>['runde', 'glatt', 'schwer']), isTrue);
    expect(task.acceptsSelection(<String>['runde', 'glatt']), isFalse);
    expect(
      task.acceptsSelection(<String>['runde', 'glatt', 'schwer', 'Stein']),
      isFalse,
    );
  });

  test('oral retelling remains audio-driven and order-sensitive', () {
    final task = GermanGradeTwoDiversityTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g2-retell-order-library',
    );
    expect(task.requiresSpeech, isTrue);
    expect(
      task.accepts(
        'Mia sucht ein Tierbuch Sie leiht das Buch aus Sie liest zu Hause darin',
      ),
      isTrue,
    );
    expect(
      task.accepts(
        'Sie leiht das Buch aus Mia sucht ein Tierbuch Sie liest zu Hause darin',
      ),
      isFalse,
    );
  });

  testWidgets('new grade-two retelling auto-plays and works by touch', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final task = GermanGradeTwoDiversityTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g2-retell-order-sandcastle',
    );
    final spoken = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: GermanTrainingScreen(
          gradeLevel: GradeLevel.second,
          tasks: <GermanTask>[task],
          speak: (_) async {},
          autoSpeak: (text) async => spoken.add(text),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(spoken, contains(task.spokenText));
    for (final value in task.choices) {
      final button = find.widgetWithText(FilledButton, value);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
    }
    final submit = find.text('Prüfen');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(find.text('Runde geschafft'), findsWidgets);
  });
}
