import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/accessibility_preferences.dart';
import 'package:rechenblitz/core/learning_app_theme.dart';
import 'package:rechenblitz/core/learning_subject.dart';
import 'package:rechenblitz/subjects/german/german_round_draft.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_starter_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_support_catalog.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/screens/german_training_screen.dart';

Widget _app({
  required GermanTask task,
  required Future<void> Function(String) speak,
  Future<void> Function(String)? autoSpeak,
  bool readAloudEnabled = false,
  void Function(GermanSessionResult)? onComplete,
  void Function(GermanRoundDraft)? onDraftChanged,
  bool speakCompletion = false,
  bool supportEnabled = true,
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
    readAloudEnabled: readAloudEnabled,
    speakCompletion: speakCompletion,
    supportEnabled: supportEnabled,
    now: now ?? DateTime.now,
    onComplete: onComplete,
    onDraftChanged: onDraftChanged,
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
    expect(find.textContaining('Vergleiche deine Auswahl'), findsOneWidget);
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
        readAloudEnabled: true,
      ),
    );
    await tester.pump();

    expect(spoken, hasLength(1));
    expect(spoken.single, contains(task.instruction));
    expect(spoken.single, contains(task.prompt));
  });

  testWidgets('visual word clue uses non-spoiling accessibility text', (
    tester,
  ) async {
    final task = GermanStarterTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g1-read-word-sonne',
    );
    final spoken = <String>[];

    await tester.pumpWidget(
      _app(
        task: task,
        speak: (_) async {},
        autoSpeak: (text) async => spoken.add(text),
        readAloudEnabled: true,
      ),
    );
    await tester.pump();

    expect(task.accessiblePrompt, isNotNull);
    expect(spoken, hasLength(1));
    expect(spoken.single, contains(task.accessiblePrompt!));
    expect(spoken.single, isNot(contains(task.prompt)));
    expect(spoken.single, isNot(contains(task.acceptedAnswers.single)));

    final visualPrompt = find.text(task.prompt);
    final semanticsFinder = find.ancestor(
      of: visualPrompt,
      matching: find.byType(Semantics),
    );
    final semantics = tester.widget<Semantics>(semanticsFinder.first);
    expect(semantics.properties.label, task.accessiblePrompt);
    expect(semantics.excludeSemantics, isTrue);
  });

  testWidgets(
    'manual read-aloud marks only the selected reading task as assisted',
    (tester) async {
      final task = GermanStarterTaskCatalog.tasks.firstWhere(
        (task) => task.id == 'g1-read-word-sonne',
      );
      final spoken = <String>[];
      GermanRoundDraft? draft;
      GermanSessionResult? completed;

      await tester.pumpWidget(
        _app(
          task: task,
          speak: (text) async => spoken.add(text),
          readAloudEnabled: false,
          onDraftChanged: (value) => draft = value,
          onComplete: (result) => completed = result,
        ),
      );
      await tester.pump();

      expect(spoken, isEmpty);
      expect(draft?.currentReadAloudUsed ?? false, isFalse);

      await tester.tap(find.byKey(const ValueKey('german-task-read-aloud')));
      await tester.pump();

      expect(spoken, hasLength(1));
      expect(spoken.single, contains(task.instruction));
      expect(spoken.single, contains(task.promptForSpeech));
      expect(draft, isNotNull);
      expect(draft!.currentReadAloudUsed, isTrue);

      await tester.tap(
        find.widgetWithText(FilledButton, task.acceptedAnswers.single),
      );
      await tester.pump();

      expect(completed, isNotNull);
      expect(completed!.taskResults.single.usedReadAloud, isTrue);
      expect(completed!.taskResults.single.independentCorrectFirstTry, isFalse);
    },
  );

  testWidgets('manual read-aloud keeps non-reading evidence independent', (
    tester,
  ) async {
    final task = GermanStarterTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g2-noun-article-tree',
    );
    final spoken = <String>[];
    GermanSessionResult? completed;

    await tester.pumpWidget(
      _app(
        task: task,
        speak: (text) async => spoken.add(text),
        readAloudEnabled: false,
        onComplete: (result) => completed = result,
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('german-task-read-aloud')));
    await tester.pump();
    await tester.tap(
      find.widgetWithText(FilledButton, task.acceptedAnswers.single),
    );
    await tester.pump();

    expect(spoken, hasLength(1));
    expect(completed, isNotNull);
    expect(completed!.taskResults.single.usedReadAloud, isFalse);
    expect(completed!.taskResults.single.independentCorrectFirstTry, isTrue);
  });

  testWidgets('read-aloud reading task is stored as assisted evidence', (
    tester,
  ) async {
    final task = GermanStarterTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g1-read-word-sonne',
    );
    GermanSessionResult? completed;

    await tester.pumpWidget(
      _app(
        task: task,
        speak: (_) async {},
        autoSpeak: (_) async {},
        readAloudEnabled: true,
        onComplete: (result) => completed = result,
      ),
    );
    await tester.pump();

    await tester.tap(
      find.widgetWithText(FilledButton, task.acceptedAnswers.single),
    );
    await tester.pump();

    final result = completed!.taskResults.single;
    expect(result.correctFirstTry, isTrue);
    expect(result.usedReadAloud, isTrue);
    expect(result.independentCorrectFirstTry, isFalse);
  });

  testWidgets('read-aloud state is persisted in the current German draft', (
    tester,
  ) async {
    final task = GermanStarterTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g1-read-word-sonne',
    );
    GermanRoundDraft? draft;

    await tester.pumpWidget(
      _app(
        task: task,
        speak: (_) async {},
        autoSpeak: (_) async {},
        readAloudEnabled: true,
        onDraftChanged: (value) => draft = value,
      ),
    );
    await tester.pump();

    expect(draft, isNotNull);
    expect(draft!.currentReadAloudUsed, isTrue);
    final restored = GermanRoundDraft.fromJson(draft!.toJson());
    expect(restored.currentReadAloudUsed, isTrue);
  });

  testWidgets(
    'intrinsic listening audio plays without general read-aloud and is independent',
    (tester) async {
      final task = GermanStarterTaskCatalog.tasks.firstWhere(
        (task) => task.interaction == GermanTaskInteraction.listeningChoice,
      );
      GermanSessionResult? completed;
      final spoken = <String>[];

      await tester.pumpWidget(
        _app(
          task: task,
          speak: (_) async {},
          autoSpeak: (text) async => spoken.add(text),
          readAloudEnabled: false,
          onComplete: (result) => completed = result,
        ),
      );
      await tester.pump();

      expect(spoken, <String>[task.spokenText!]);
      await tester.tap(
        find.widgetWithText(FilledButton, task.acceptedAnswers.single),
      );
      await tester.pump();

      final result = completed!.taskResults.single;
      expect(result.correctFirstTry, isTrue);
      expect(result.usedReadAloud, isFalse);
      expect(result.independentCorrectFirstTry, isTrue);
    },
  );

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

  testWidgets('listening hint can replay the task without scrolling back', (
    tester,
  ) async {
    final task = GermanStarterTaskCatalog.tasks.firstWhere(
      (task) => task.interaction == GermanTaskInteraction.listeningChoice,
    );
    final spoken = <String>[];
    await tester.pumpWidget(
      _app(task: task, speak: (text) async => spoken.add(text)),
    );

    final wrong = task.choices.firstWhere(
      (choice) => !task.acceptedAnswers.contains(choice),
    );
    final wrongButton = find.widgetWithText(FilledButton, wrong);
    await tester.ensureVisible(wrongButton);
    await tester.pump();
    await tester.tap(wrongButton);
    await tester.pump();

    final replay = find.byKey(const ValueKey('german-listening-replay-hint'));
    await tester.scrollUntilVisible(
      replay,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Denkhinweis'), findsOneWidget);
    expect(replay.hitTestable(), findsOneWidget);
    await tester.tap(replay);
    await tester.pump();

    expect(spoken, <String>[task.spokenText!]);

    final hintSpeak = find.byKey(const ValueKey('german-hint-speak'));
    await tester.ensureVisible(hintSpeak);
    await tester.tap(hintSpeak);
    await tester.pump();

    expect(spoken, hasLength(2));
    expect(spoken.last, GermanSupportCatalog.firstHintForTask(task));
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

  testWidgets('word-order touch can undo one chunk without clearing progress', (
    tester,
  ) async {
    final task = GermanStarterTaskCatalog.tasks.firstWhere(
      (task) => task.interaction == GermanTaskInteraction.wordOrder,
    );
    GermanRoundDraft? saved;
    await tester.pumpWidget(
      _app(
        task: task,
        speak: (_) async {},
        onDraftChanged: (draft) => saved = draft,
      ),
    );

    final first = task.choices.first;
    final second = task.choices[1];
    await tester.tap(find.widgetWithText(FilledButton, first));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, second));
    await tester.pump();

    expect(find.text('$first $second'), findsOneWidget);
    expect(saved!.currentOrderedWords, <String>[first, second]);

    await tester.tap(find.byKey(const ValueKey('german-word-undo')));
    await tester.pump();

    expect(find.text(first), findsWidgets);
    expect(find.widgetWithText(FilledButton, second), findsOneWidget);
    expect(saved!.currentOrderedWords, <String>[first]);
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
    expect(spoken.single, contains('Nomen und Artikel erkennen'));
    expect(find.textContaining('Nomen und Artikel erkennen'), findsOneWidget);
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

  testWidgets('typed answer gets a concrete non-spoiling correction hint', (
    tester,
  ) async {
    final task = GermanStarterTaskCatalog.tasks.firstWhere(
      (task) => task.interaction == GermanTaskInteraction.typedText,
    );
    await tester.pumpWidget(_app(task: task, speak: (_) async {}));

    await tester.enterText(find.byType(TextField), 'heute regnet es.');
    await tester.tap(find.text('Prüfen'));
    await tester.pump();

    expect(find.textContaining('Groß- und Kleinschreibung'), findsOneWidget);
    expect(find.text('Denkhinweis'), findsOneWidget);
    expect(find.text(task.acceptedAnswers.first), findsNothing);
  });

  testWidgets('support-free round keeps wrong-answer feedback neutral', (
    tester,
  ) async {
    final task = GermanStarterTaskCatalog.tasks.firstWhere(
      (task) => task.interaction == GermanTaskInteraction.typedText,
    );
    await tester.pumpWidget(
      _app(task: task, speak: (_) async {}, supportEnabled: false),
    );

    await tester.enterText(find.byType(TextField), 'heute regnet es.');
    await tester.tap(find.text('Prüfen'));
    await tester.pump();

    expect(find.text('Noch nicht. Versuch es noch einmal.'), findsOneWidget);
    expect(find.text('Denkhinweis'), findsNothing);
  });
}
