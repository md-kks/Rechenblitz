import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_answer_feedback.dart';
import 'package:rechenblitz/subjects/german/german_assessment.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_competency_catalog.dart';
import 'package:rechenblitz/subjects/german/german_learning_domain.dart';
import 'package:rechenblitz/subjects/german/german_listening_touch_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/german_task_evidence_priority.dart';
import 'package:rechenblitz/subjects/german/screens/german_training_screen.dart';

void main() {
  test('listening touch catalog is valid and balanced across grades', () {
    expect(GermanListeningTouchTaskCatalog.tasks, hasLength(28));
    final byGrade = <GradeLevel, int>{};
    final byInteraction = <GermanTaskInteraction, int>{};
    final spoken = <String>{};
    for (final task in GermanListeningTouchTaskCatalog.tasks) {
      byGrade[task.recommendedFromGrade] =
          (byGrade[task.recommendedFromGrade] ?? 0) + 1;
      byInteraction[task.interaction] =
          (byInteraction[task.interaction] ?? 0) + 1;
      expect(task.requiresSpeech, isTrue, reason: task.id);
      expect(task.isWellFormed, isTrue, reason: task.id);
      expect(spoken.add(task.spokenText!), isTrue, reason: task.id);
    }
    expect(byGrade, <GradeLevel, int>{
      GradeLevel.first: 8,
      GradeLevel.second: 4,
      GradeLevel.third: 8,
      GradeLevel.fourth: 8,
    });
    expect(byInteraction[GermanTaskInteraction.tokenSelection], 16);
    expect(byInteraction[GermanTaskInteraction.wordOrder], 12);
  });

  test('richer listening evidence outranks classic listening choice', () {
    final token = GermanListeningTouchTaskCatalog.tasks.firstWhere(
      (task) => task.interaction == GermanTaskInteraction.tokenSelection,
    );
    final order = GermanListeningTouchTaskCatalog.tasks.firstWhere(
      (task) => task.interaction == GermanTaskInteraction.wordOrder,
    );
    final classic = const GermanTask(
      id: 'classic-listen',
      competencyId: GermanCompetencyId.listeningComprehension,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Hör zu.',
      prompt: 'Hörtext',
      interaction: GermanTaskInteraction.listeningChoice,
      acceptedAnswers: <String>['ja'],
      choices: <String>['ja', 'nein'],
      spokenText: 'Ein kurzer Hörtext.',
    );

    expect(
      GermanTaskEvidencePriority.rank(order),
      lessThan(GermanTaskEvidencePriority.rank(classic)),
    );
    expect(
      GermanTaskEvidencePriority.rank(token),
      lessThan(GermanTaskEvidencePriority.rank(classic)),
    );
  });

  test('targeted listening practice uses touch evidence in every grade', () {
    final cases = <(GradeLevel, GermanCompetencyId, GermanTaskInteraction)>[
      (
        GradeLevel.first,
        GermanCompetencyId.listeningComprehension,
        GermanTaskInteraction.tokenSelection,
      ),
      (
        GradeLevel.first,
        GermanCompetencyId.conversationRules,
        GermanTaskInteraction.tokenSelection,
      ),
      (
        GradeLevel.second,
        GermanCompetencyId.oralRetelling,
        GermanTaskInteraction.wordOrder,
      ),
      (
        GradeLevel.third,
        GermanCompetencyId.oralRetelling,
        GermanTaskInteraction.wordOrder,
      ),
      (
        GradeLevel.third,
        GermanCompetencyId.presentationStructure,
        GermanTaskInteraction.wordOrder,
      ),
      (
        GradeLevel.fourth,
        GermanCompetencyId.listeningMainIdeas,
        GermanTaskInteraction.tokenSelection,
      ),
      (
        GradeLevel.fourth,
        GermanCompetencyId.discussionReasoning,
        GermanTaskInteraction.tokenSelection,
      ),
    ];

    for (final entry in cases) {
      final round = GermanPracticePlanner.buildCompetencyRound(
        gradeLevel: entry.$1,
        competencyId: entry.$2,
        history: const <GermanSessionResult>[],
      );
      expect(
        round.first.interaction,
        entry.$3,
        reason: '${entry.$1}/${entry.$2}',
      );
      expect(round.first.requiresSpeech, isTrue);
    }
  });

  test('daily rounds and Lernchecks use richer listening interactions', () {
    for (final grade in GradeLevel.values) {
      final daily = GermanPracticePlanner.buildDailyRound(
        gradeLevel: grade,
        history: const <GermanSessionResult>[],
      );
      final assessment = GermanAssessmentPlanner.buildRound(grade);

      for (final round in <List<GermanTask>>[daily, assessment]) {
        final listening = round.where(
          (task) =>
              GermanCompetencyCatalog.definition(task.competencyId).domain ==
              GermanLearningDomain.listening,
        );
        expect(listening, hasLength(2), reason: grade.toString());
        expect(listening.every((task) => task.requiresSpeech), isTrue);
        expect(
          listening.every(
            (task) => task.interaction != GermanTaskInteraction.listeningChoice,
          ),
          isTrue,
          reason: grade.toString(),
        );
      }
    }
  });

  test('audio-driven token and order tasks validate answers normally', () {
    final token = GermanListeningTouchTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g1-listen-mark-park',
    );
    final order = GermanListeningTouchTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g2-retell-order-card',
    );

    expect(
      token.acceptsSelection(<String>['roter Ball', 'gelbe Decke']),
      isTrue,
    );
    expect(
      token.acceptsSelection(<String>['roter Ball', 'blauer Eimer']),
      isFalse,
    );
    expect(
      order.accepts(
        'Mia schneidet Papier aus Sie faltet die Karte Sie klebt einen Stern darauf',
      ),
      isTrue,
    );
    expect(
      order.accepts(
        'Sie faltet die Karte Mia schneidet Papier aus Sie klebt einen Stern darauf',
      ),
      isFalse,
    );
  });

  test('listening touch feedback stays non-spoiling and audio-focused', () {
    final token = GermanListeningTouchTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g1-listen-mark-park',
    );
    final order = GermanListeningTouchTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g2-retell-order-card',
    );

    expect(
      GermanAnswerFeedback.forIncorrect(token, 'roter Ball · blauer Eimer'),
      contains('wirklich gesagt'),
    );
    expect(
      GermanAnswerFeedback.forIncorrect(order, 'falsche Reihenfolge'),
      contains('zuerst'),
    );
  });

  testWidgets(
    'audio token selection auto-plays, replays and corrects by touch',
    (tester) async {
      final task = GermanListeningTouchTaskCatalog.tasks.firstWhere(
        (task) => task.id == 'g1-listen-mark-park',
      );
      final autoSpoken = <String>[];
      final replayed = <String>[];
      GermanSessionResult? completed;

      await tester.pumpWidget(
        MaterialApp(
          home: GermanTrainingScreen(
            gradeLevel: GradeLevel.first,
            tasks: <GermanTask>[task],
            speak: (text) async => replayed.add(text),
            autoSpeak: (text) async => autoSpoken.add(text),
            onComplete: (result) => completed = result,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(autoSpoken, contains(task.spokenText));
      final replay = find.byKey(const ValueKey('german-listening-replay'));
      expect(replay, findsOneWidget);
      await tester.tap(replay);
      await tester.pump();
      expect(replayed, contains(task.spokenText));

      final redBall = find.widgetWithText(FilterChip, 'roter Ball');
      final blueBucket = find.widgetWithText(FilterChip, 'blauer Eimer');
      await tester.ensureVisible(redBall);
      await tester.tap(redBall);
      await tester.ensureVisible(blueBucket);
      await tester.tap(blueBucket);
      final submit = find.byKey(const ValueKey('german-token-submit'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();
      expect(completed, isNull);

      await tester.ensureVisible(blueBucket);
      await tester.tap(blueBucket);
      final yellowBlanket = find.widgetWithText(FilterChip, 'gelbe Decke');
      await tester.ensureVisible(yellowBlanket);
      await tester.tap(yellowBlanket);
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();
      expect(completed, isNotNull);
      expect(find.text('Runde geschafft'), findsWidgets);
    },
  );

  testWidgets(
    'audio word ordering stays usable on a compact large-text screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final task = GermanListeningTouchTaskCatalog.tasks.firstWhere(
        (task) => task.id == 'g3-retell-order-experiment',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: GermanTrainingScreen(
            gradeLevel: GradeLevel.third,
            tasks: <GermanTask>[task],
            speak: (_) async {},
            autoSpeak: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final taskList = find.byType(ListView);
      expect(taskList, findsOneWidget);
      final replay = find.byKey(
        const ValueKey('german-listening-replay'),
        skipOffstage: false,
      );
      await tester.scrollUntilVisible(
        replay,
        160,
        scrollable: find.byType(Scrollable).first,
      );
      expect(replay, findsOneWidget);
      final prompt = find.text(
        'Tippe die gehörten Schritte in der richtigen Reihenfolge an.',
        skipOffstage: false,
      );
      await tester.scrollUntilVisible(
        prompt,
        160,
        scrollable: find.byType(Scrollable).first,
      );
      expect(prompt, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
