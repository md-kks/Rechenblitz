import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_grade_one_diversity_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_task_evidence_priority.dart';
import 'package:rechenblitz/subjects/german/screens/german_training_screen.dart';

GermanSessionResult _completedRound(List<GermanTask> tasks) =>
    GermanSessionResult(
      gradeLevel: GradeLevel.first,
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
            responseMs: 1200,
          ),
      ],
    );

void main() {
  test('grade-one diversity catalog adds thirty-two strong tasks', () {
    expect(GermanGradeOneDiversityTaskCatalog.tasks, hasLength(32));
    final counts = <GermanCompetencyId, int>{};
    for (final task in GermanGradeOneDiversityTaskCatalog.tasks) {
      expect(task.recommendedFromGrade, GradeLevel.first, reason: task.id);
      expect(task.isWellFormed, isTrue, reason: task.id);
      counts[task.competencyId] = (counts[task.competencyId] ?? 0) + 1;
    }
    expect(counts, <GermanCompetencyId, int>{
      GermanCompetencyId.vowelConsonantRecognition: 8,
      GermanCompetencyId.wordBuilding: 8,
      GermanCompetencyId.listeningComprehension: 8,
      GermanCompetencyId.conversationRules: 8,
    });
  });

  test('all German task ids remain unique', () {
    final ids = GermanTaskCatalog.tasks.map((task) => task.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('all four grade-one skills now have twelve strongest current tasks', () {
    for (final competency in <GermanCompetencyId>[
      GermanCompetencyId.vowelConsonantRecognition,
      GermanCompetencyId.wordBuilding,
      GermanCompetencyId.listeningComprehension,
      GermanCompetencyId.conversationRules,
    ]) {
      final current = GermanTaskCatalog.forCompetency(
        competency,
      ).where((task) => task.recommendedFromGrade == GradeLevel.first).toList();
      final bestRank = current
          .map(GermanTaskEvidencePriority.rank)
          .reduce((a, b) => a < b ? a : b);
      final strongest = current.where(
        (task) => GermanTaskEvidencePriority.rank(task) == bestRank,
      );
      expect(strongest, hasLength(12), reason: competency.name);
    }
  });

  test('each expanded grade-one skill rotates to a fresh second round', () {
    for (final competency in <GermanCompetencyId>[
      GermanCompetencyId.vowelConsonantRecognition,
      GermanCompetencyId.wordBuilding,
      GermanCompetencyId.listeningComprehension,
      GermanCompetencyId.conversationRules,
    ]) {
      final first = GermanPracticePlanner.buildCompetencyRound(
        gradeLevel: GradeLevel.first,
        competencyId: competency,
        history: const <GermanSessionResult>[],
      );
      expect(first, hasLength(6), reason: competency.name);
      final second = GermanPracticePlanner.buildCompetencyRound(
        gradeLevel: GradeLevel.first,
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

  test('grade-one listening evidence always has spoken content', () {
    for (final task in GermanGradeOneDiversityTaskCatalog.tasks.where(
      (task) =>
          task.competencyId == GermanCompetencyId.listeningComprehension ||
          task.competencyId == GermanCompetencyId.conversationRules,
    )) {
      expect(task.requiresSpeech, isTrue, reason: task.id);
      expect(task.spokenText, isNotNull, reason: task.id);
    }
  });

  test('new grade-one answer models require exact evidence', () {
    final vowels = GermanGradeOneDiversityTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g1-mark-vowels-maus',
    );
    final builder = GermanGradeOneDiversityTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g1-build-touch-haus',
    );
    final listening = GermanGradeOneDiversityTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g1-listen-mark-trip-bag',
    );

    expect(vowels.acceptsSelection(<String>['a', 'u']), isTrue);
    expect(vowels.acceptsSelection(<String>['a']), isFalse);
    expect(builder.accepts('Haus'), isTrue);
    expect(builder.accepts('Hausx'), isFalse);
    expect(
      listening.acceptsSelection(<String>['Trinkflasche', 'Regenjacke']),
      isTrue,
    );
    expect(
      listening.acceptsSelection(<String>['Trinkflasche', 'Buch']),
      isFalse,
    );
  });

  testWidgets('new grade-one word building works entirely by touch', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final task = GermanGradeOneDiversityTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g1-build-touch-haus',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: GermanTrainingScreen(
          gradeLevel: GradeLevel.first,
          tasks: <GermanTask>[task],
          speak: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Hau'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 's'));
    await tester.pump();
    expect(find.text('Haus'), findsOneWidget);
    final submit = find.byKey(const ValueKey('german-word-builder-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(find.text('Runde geschafft'), findsWidgets);
  });
  testWidgets('new grade-one listening auto-plays and accepts touch evidence', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final task = GermanGradeOneDiversityTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g1-listen-mark-trip-bag',
    );
    final spoken = <String>[];
    GermanSessionResult? completed;
    await tester.pumpWidget(
      MaterialApp(
        home: GermanTrainingScreen(
          gradeLevel: GradeLevel.first,
          tasks: <GermanTask>[task],
          speak: (_) async {},
          autoSpeak: (text) async => spoken.add(text),
          onComplete: (result) => completed = result,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(spoken, contains(task.spokenText));
    for (final value in <String>['Trinkflasche', 'Regenjacke']) {
      final chip = find.widgetWithText(FilterChip, value);
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pump();
    }
    final submit = find.byKey(const ValueKey('german-token-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(completed, isNotNull);
    expect(find.text('Runde geschafft'), findsWidgets);
  });
}
