import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/accessibility_preferences.dart';
import 'package:rechenblitz/core/learning_app_theme.dart';
import 'package:rechenblitz/core/learning_subject.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_starter_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/screens/german_training_screen.dart';

Widget _app({
  required GermanTask task,
  required Future<void> Function(String) speak,
  Future<void> Function(String)? autoSpeak,
  void Function(GermanSessionResult)? onComplete,
  bool speakCompletion = false,
  DateTime Function()? now,
}) => MaterialApp(
  theme: LearningAppTheme.build(
    subject: LearningSubject.german,
    accessibility: const AccessibilityPreferences(),
  ),
  home: GermanTrainingScreen(
    gradeLevel: task.recommendedFromGrade,
    tasks: <GermanTask>[task],
    speak: speak,
    autoSpeak: autoSpeak,
    speakCompletion: speakCompletion,
    now: now ?? DateTime.now,
    onComplete: onComplete,
  ),
);

void main() {
  testWidgets('choice task records retry and completes the German round', (
    tester,
  ) async {
    final task = GermanStarterTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g2-noun-article-tree',
    );
    GermanSessionResult? completed;
    await tester.pumpWidget(
      _app(
        task: task,
        speak: (_) async {},
        onComplete: (result) => completed = result,
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'die'));
    await tester.pump();
    expect(find.text('Noch nicht. Versuch es noch einmal.'), findsOneWidget);
    expect(find.text('Denkhinweis'), findsOneWidget);
    expect(find.textContaining('der, die und das'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'der'));
    await tester.pump();
    expect(find.text('Runde geschafft'), findsWidgets);
    expect(completed, isNotNull);
    expect(completed!.taskResults.single.correctFirstTry, isFalse);
    expect(completed!.incorrectAttempts, 1);
  });

  testWidgets('shared read-aloud callback reads the current German task', (
    tester,
  ) async {
    final task = GermanStarterTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g2-noun-article-tree',
    );
    final spoken = <String>[];
    await tester.pumpWidget(
      _app(
        task: task,
        speak: (_) async {},
        autoSpeak: (text) async => spoken.add(text),
      ),
    );
    await tester.pump();

    expect(spoken, hasLength(1));
    expect(spoken.single, contains(task.instruction));
    expect(spoken.single, contains(task.prompt));
  });

  testWidgets('listening task uses supplied local speech callback', (
    tester,
  ) async {
    final task = GermanStarterTaskCatalog.tasks.firstWhere(
      (task) => task.interaction == GermanTaskInteraction.listeningChoice,
    );
    String? spoken;
    await tester.pumpWidget(
      _app(task: task, speak: (text) async => spoken = text),
    );

    await tester.tap(find.text('Anhören'));
    await tester.pump();
    expect(spoken, task.spokenText);
  });

  testWidgets('listening time is not counted as answer time', (tester) async {
    final task = GermanStarterTaskCatalog.tasks.firstWhere(
      (task) => task.interaction == GermanTaskInteraction.listeningChoice,
    );
    var clock = DateTime(2026, 9, 18, 9);
    final speechDone = Completer<void>();
    GermanSessionResult? completed;
    await tester.pumpWidget(
      _app(
        task: task,
        speak: (_) => speechDone.future,
        now: () => clock,
        onComplete: (result) => completed = result,
      ),
    );

    await tester.tap(find.text('Anhören'));
    await tester.pump();
    clock = clock.add(const Duration(seconds: 20));
    speechDone.complete();
    await tester.pump();
    clock = clock.add(const Duration(milliseconds: 1200));
    await tester.tap(
      find.widgetWithText(FilledButton, task.acceptedAnswers.first),
    );
    await tester.pump();

    expect(completed, isNotNull);
    expect(completed!.taskResults.single.responseMs, 1200);
  });

  testWidgets('word-order choices are not shown in answer order', (
    tester,
  ) async {
    final task = GermanStarterTaskCatalog.tasks.firstWhere(
      (task) => task.interaction == GermanTaskInteraction.wordOrder,
    );
    final fixedNow = DateTime(2026, 9, 18, 9);
    await tester.pumpWidget(
      _app(task: task, speak: (_) async {}, now: () => fixedNow),
    );

    final shown = <String>[];
    for (var index = 0; index < task.choices.length; index++) {
      final button = tester.widget<FilledButton>(
        find.byKey(ValueKey('german-word-choice-${task.id}-$index')),
      );
      shown.add((button.child! as Text).data!);
    }

    expect(shown, isNot(orderedEquals(task.choices)));
    expect(shown.toSet(), task.choices.toSet());
  });

  testWidgets('word-order task can be solved entirely by touch', (
    tester,
  ) async {
    final task = GermanStarterTaskCatalog.tasks.firstWhere(
      (task) => task.interaction == GermanTaskInteraction.wordOrder,
    );
    await tester.pumpWidget(_app(task: task, speak: (_) async {}));

    for (final word in task.choices) {
      await tester.tap(find.widgetWithText(FilledButton, word));
      await tester.pump();
    }
    await tester.tap(find.text('Prüfen'));
    await tester.pump();

    expect(find.text('Runde geschafft'), findsWidgets);
  });

  testWidgets('completion feedback can speak automatically and be replayed', (
    tester,
  ) async {
    final task = GermanStarterTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g2-noun-article-tree',
    );
    final spoken = <String>[];
    await tester.pumpWidget(
      _app(
        task: task,
        speak: (text) async => spoken.add(text),
        speakCompletion: true,
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'der'));
    await tester.pump();
    expect(spoken, hasLength(1));
    expect(spoken.single, contains('direkt richtig'));
    expect(find.text('Feedback anhören'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('german-round-feedback-replay')),
    );
    await tester.pump();
    expect(spoken, hasLength(2));
  });

  testWidgets('completed German round returns its session result to caller', (
    tester,
  ) async {
    final task = GermanStarterTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g2-noun-article-tree',
    );
    GermanSessionResult? returned;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              returned = await Navigator.of(context).push<GermanSessionResult>(
                MaterialPageRoute<GermanSessionResult>(
                  builder: (_) => GermanTrainingScreen(
                    gradeLevel: task.recommendedFromGrade,
                    tasks: <GermanTask>[task],
                    speak: (_) async {},
                  ),
                ),
              );
            },
            child: const Text('Start'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'der'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('german-round-done')));
    await tester.pumpAndSettle();

    expect(returned, isNotNull);
    expect(returned!.total, 1);
    expect(returned!.correctFirstTry, 1);
  });

  testWidgets('typed answer accepts correct sentence form with extra spaces', (
    tester,
  ) async {
    final task = GermanStarterTaskCatalog.tasks.firstWhere(
      (task) => task.interaction == GermanTaskInteraction.typedText,
    );
    await tester.pumpWidget(_app(task: task, speak: (_) async {}));

    await tester.enterText(find.byType(TextField), 'Heute   regnet es.');
    await tester.tap(find.text('Prüfen'));
    await tester.pump();

    expect(find.text('Runde geschafft'), findsWidgets);
  });
}
