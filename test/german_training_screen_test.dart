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
  void Function(GermanSessionResult)? onComplete,
  bool speakCompletion = false,
}) => MaterialApp(
  theme: LearningAppTheme.build(
    subject: LearningSubject.german,
    accessibility: const AccessibilityPreferences(),
  ),
  home: GermanTrainingScreen(
    gradeLevel: task.recommendedFromGrade,
    tasks: <GermanTask>[task],
    speak: speak,
    speakCompletion: speakCompletion,
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

  testWidgets('typed answer accepts normalized child input', (tester) async {
    final task = GermanStarterTaskCatalog.tasks.firstWhere(
      (task) => task.interaction == GermanTaskInteraction.typedText,
    );
    await tester.pumpWidget(_app(task: task, speak: (_) async {}));

    await tester.enterText(find.byType(TextField), 'heute   REGNET es.');
    await tester.tap(find.text('Prüfen'));
    await tester.pump();

    expect(find.text('Runde geschafft'), findsWidgets);
  });
}
