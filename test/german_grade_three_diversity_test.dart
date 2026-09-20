import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_grade_three_diversity_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_task_evidence_priority.dart';
import 'package:rechenblitz/subjects/german/screens/german_training_screen.dart';

GermanSessionResult _completedRound(List<GermanTask> tasks) =>
    GermanSessionResult(
      gradeLevel: GradeLevel.third,
      startedAt: DateTime(2026, 9, 20, 14),
      finishedAt: DateTime(2026, 9, 20, 14, 5),
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
  test('grade-three diversity catalog adds seventy-two active tasks', () {
    expect(GermanGradeThreeDiversityTaskCatalog.tasks, hasLength(72));
    final counts = <GermanCompetencyId, int>{};
    for (final task in GermanGradeThreeDiversityTaskCatalog.tasks) {
      expect(task.recommendedFromGrade, GradeLevel.third, reason: task.id);
      expect(task.isWellFormed, isTrue, reason: task.id);
      counts[task.competencyId] = (counts[task.competencyId] ?? 0) + 1;
    }
    expect(counts, <GermanCompetencyId, int>{
      GermanCompetencyId.oralRetelling: 8,
      GermanCompetencyId.spellingStrategies: 8,
      GermanCompetencyId.dictionarySkills: 8,
      GermanCompetencyId.compoundWords: 8,
      GermanCompetencyId.subjectPredicate: 8,
      GermanCompetencyId.verbTenses: 8,
      GermanCompetencyId.readingInference: 8,
      GermanCompetencyId.textSequence: 8,
      GermanCompetencyId.presentationStructure: 8,
    });
  });

  test('all German task ids remain unique', () {
    final ids = GermanTaskCatalog.tasks.map((task) => task.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('nine grade-three skills now have twelve strongest current tasks', () {
    for (final competency in <GermanCompetencyId>[
      GermanCompetencyId.oralRetelling,
      GermanCompetencyId.spellingStrategies,
      GermanCompetencyId.dictionarySkills,
      GermanCompetencyId.compoundWords,
      GermanCompetencyId.subjectPredicate,
      GermanCompetencyId.verbTenses,
      GermanCompetencyId.readingInference,
      GermanCompetencyId.textSequence,
      GermanCompetencyId.presentationStructure,
    ]) {
      final current = GermanTaskCatalog.forCompetency(
        competency,
      ).where((task) => task.recommendedFromGrade == GradeLevel.third).toList();
      final bestRank = current
          .map(GermanTaskEvidencePriority.rank)
          .reduce((a, b) => a < b ? a : b);
      final strongest = current.where(
        (task) => GermanTaskEvidencePriority.rank(task) == bestRank,
      );
      expect(strongest, hasLength(12), reason: competency.name);
    }
  });

  test('each expanded grade-three skill rotates to a fresh second round', () {
    for (final competency in <GermanCompetencyId>[
      GermanCompetencyId.oralRetelling,
      GermanCompetencyId.spellingStrategies,
      GermanCompetencyId.dictionarySkills,
      GermanCompetencyId.compoundWords,
      GermanCompetencyId.subjectPredicate,
      GermanCompetencyId.verbTenses,
      GermanCompetencyId.readingInference,
      GermanCompetencyId.textSequence,
      GermanCompetencyId.presentationStructure,
    ]) {
      final first = GermanPracticePlanner.buildCompetencyRound(
        gradeLevel: GradeLevel.third,
        competencyId: competency,
        history: const <GermanSessionResult>[],
      );
      expect(first, hasLength(6), reason: competency.name);
      final second = GermanPracticePlanner.buildCompetencyRound(
        gradeLevel: GradeLevel.third,
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

  test('all new listening tasks stay audio-driven', () {
    final listeningCompetencies = <GermanCompetencyId>{
      GermanCompetencyId.oralRetelling,
      GermanCompetencyId.presentationStructure,
    };
    final listening = GermanGradeThreeDiversityTaskCatalog.tasks.where(
      (task) => listeningCompetencies.contains(task.competencyId),
    );
    expect(listening, hasLength(16));
    expect(listening.every((task) => task.requiresSpeech), isTrue);
    expect(
      listening.every(
        (task) => task.interaction == GermanTaskInteraction.wordOrder,
      ),
      isTrue,
    );
  });

  test('irregular past builders require the exact form', () {
    final task = GermanGradeThreeDiversityTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g3-tense-write-past-build',
    );
    expect(task.accepts('schrieb'), isTrue);
    expect(task.accepts('schreibte'), isFalse);
    expect(task.accepts('schriep'), isFalse);
  });

  test('reading inference requires the complete evidence chain', () {
    final task = GermanGradeThreeDiversityTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g3-inference-evidence-school-start',
    );
    expect(
      task.acceptsSelection(<String>[
        'Die Kinder sitzen an ihren Plätzen.',
        'Die Hefte liegen offen.',
        'Die Lehrerin schreibt das Datum an die Tafel.',
      ]),
      isTrue,
    );
    expect(
      task.acceptsSelection(<String>[
        'Die Kinder sitzen an ihren Plätzen.',
        'Die Hefte liegen offen.',
      ]),
      isFalse,
    );
  });

  testWidgets('new grade-three retelling auto-plays and works by touch', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final task = GermanGradeThreeDiversityTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g3-retell-order-garden',
    );
    final spoken = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: GermanTrainingScreen(
          gradeLevel: GradeLevel.third,
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
