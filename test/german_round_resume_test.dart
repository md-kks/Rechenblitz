import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/subjects/german/german_round_draft.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_storage_service.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_touch_task_catalog.dart';
import 'package:rechenblitz/subjects/german/screens/german_home_screen.dart';
import 'package:rechenblitz/subjects/german/screens/german_training_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  GermanRoundDraft draftForTwoTasks({
    String? assignmentPayload,
    String currentAnswer = '',
    List<String> currentOrderedWords = const <String>[],
  }) {
    final tasks = GermanTaskCatalog.forGrade(
      GradeLevel.second,
    ).take(2).toList();
    return GermanRoundDraft(
      gradeLevel: GradeLevel.second,
      taskIds: tasks.map((task) => task.id).toList(growable: false),
      currentIndex: 1,
      startedAt: DateTime(2026, 9, 17, 10),
      updatedAt: DateTime(2026, 9, 17, 10, 2),
      completedResults: <GermanTaskResult>[
        GermanTaskResult(
          taskId: tasks.first.id,
          competencyId: tasks.first.competencyId,
          correctFirstTry: true,
          incorrectAttempts: 0,
          responseMs: 900,
        ),
      ],
      currentAnswer: currentAnswer,
      currentOrderedWords: currentOrderedWords,
      assignmentPayload: assignmentPayload,
    );
  }

  test('German round draft round-trips and stays profile scoped', () async {
    final draft = draftForTwoTasks(
      currentAnswer: 'Angefangener Satz',
      currentOrderedWords: const <String>['eins', 'zwei'],
    );
    final first = GermanStorageService(profileId: 'first');
    final second = GermanStorageService(profileId: 'second');

    await first.saveRoundDraft(draft);
    final restored = await first.loadRoundDraft();

    expect(restored, isNotNull);
    expect(restored!.taskIds, draft.taskIds);
    expect(restored.currentIndex, 1);
    expect(restored.currentAnswer, 'Angefangener Satz');
    expect(restored.currentOrderedWords, const <String>['eins', 'zwei']);
    expect(
      restored.completedResults.single.taskId,
      draft.completedResults.single.taskId,
    );
    expect(await second.loadRoundDraft(), isNull);
  });

  test('German draft load waits for a queued save', () async {
    final storage = GermanStorageService(profileId: 'child');
    final draft = draftForTwoTasks(currentAnswer: 'noch nicht fertig');

    final save = storage.saveRoundDraft(draft);
    final restored = await storage.loadRoundDraft();
    await save;

    expect(restored, isNotNull);
    expect(restored!.currentAnswer, 'noch nicht fertig');
  });

  test('queued German draft saves preserve the latest state', () async {
    final storage = GermanStorageService(profileId: 'child');
    final first = draftForTwoTasks(currentAnswer: 'erster Stand');
    final latest = draftForTwoTasks(currentAnswer: 'letzter Stand');

    await Future.wait<void>(<Future<void>>[
      storage.saveRoundDraft(first),
      storage.saveRoundDraft(latest),
    ]);

    final restored = await storage.loadRoundDraft();
    expect(restored, isNotNull);
    expect(restored!.currentAnswer, 'letzter Stand');
  });

  test(
    'queued German draft clear cannot be overtaken by an older save',
    () async {
      final storage = GermanStorageService(profileId: 'child');
      final first = draftForTwoTasks(currentAnswer: 'erster Stand');
      final latest = draftForTwoTasks(currentAnswer: 'letzter Stand');

      final firstSave = storage.saveRoundDraft(first);
      final secondSave = storage.saveRoundDraft(latest);
      final clear = storage.clearRoundDraft();

      await Future.wait<void>(<Future<void>>[firstSave, secondSave, clear]);

      expect(await storage.loadRoundDraft(), isNull);
    },
  );

  test('older German drafts default partial input safely', () {
    final json = draftForTwoTasks().toJson()
      ..remove('currentAnswer')
      ..remove('currentOrderedWords')
      ..remove('currentReadAloudUsed');

    final restored = GermanRoundDraft.fromJson(json);

    expect(restored.currentAnswer, isEmpty);
    expect(restored.currentOrderedWords, isEmpty);
    expect(restored.currentReadAloudUsed, isFalse);
  });

  testWidgets('typed German draft restores and resaves partial text', (
    tester,
  ) async {
    final task = GermanTaskCatalog.tasks.firstWhere(
      (task) =>
          task.interaction == GermanTaskInteraction.typedText &&
          task.recommendedFromGrade == GradeLevel.third,
    );
    final draft = GermanRoundDraft(
      gradeLevel: GradeLevel.third,
      taskIds: <String>[task.id],
      currentIndex: 0,
      startedAt: DateTime(2026, 9, 18, 9),
      updatedAt: DateTime(2026, 9, 18, 9, 1),
      completedResults: const <GermanTaskResult>[],
      currentAnswer: 'Morgen bringt Sara',
    );
    GermanRoundDraft? saved;

    await tester.pumpWidget(
      MaterialApp(
        home: GermanTrainingScreen(
          gradeLevel: GradeLevel.third,
          tasks: <GermanTask>[task],
          speak: (_) async {},
          draft: draft,
          onDraftChanged: (value) => saved = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final input = find.byType(TextField);
    await tester.dragUntilVisible(
      input,
      find.byType(ListView),
      const Offset(0, -180),
    );
    expect(
      tester.widget<TextField>(input).controller!.text,
      'Morgen bringt Sara',
    );

    await tester.enterText(input, 'Morgen bringt Sara ihr Lieblingsbuch');
    await tester.pump(const Duration(milliseconds: 350));

    expect(saved, isNotNull);
    expect(saved!.currentAnswer, 'Morgen bringt Sara ihr Lieblingsbuch');
  });

  testWidgets('app switch flushes partial German text immediately', (
    tester,
  ) async {
    final task = GermanTaskCatalog.tasks.firstWhere(
      (task) =>
          task.interaction == GermanTaskInteraction.typedText &&
          task.recommendedFromGrade == GradeLevel.third,
    );
    GermanRoundDraft? saved;

    await tester.pumpWidget(
      MaterialApp(
        home: GermanTrainingScreen(
          gradeLevel: GradeLevel.third,
          tasks: <GermanTask>[task],
          speak: (_) async {},
          onDraftChanged: (value) => saved = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final input = find.byType(TextField);
    await tester.dragUntilVisible(
      input,
      find.byType(ListView),
      const Offset(0, -180),
    );
    await tester.enterText(input, 'Morgen bringt Sara');

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.currentAnswer, 'Morgen bringt Sara');

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
  });

  testWidgets('word-order draft restores and saves partial touch input', (
    tester,
  ) async {
    final task = GermanTaskCatalog.tasks.firstWhere(
      (task) => task.interaction == GermanTaskInteraction.wordOrder,
    );
    final partial = task.choices.take(2).toList(growable: false);
    final draft = GermanRoundDraft(
      gradeLevel: task.recommendedFromGrade,
      taskIds: <String>[task.id],
      currentIndex: 0,
      startedAt: DateTime(2026, 9, 18, 9),
      updatedAt: DateTime(2026, 9, 18, 9, 1),
      completedResults: const <GermanTaskResult>[],
      currentOrderedWords: partial,
    );
    GermanRoundDraft? saved;

    await tester.pumpWidget(
      MaterialApp(
        home: GermanTrainingScreen(
          gradeLevel: task.recommendedFromGrade,
          tasks: <GermanTask>[task],
          speak: (_) async {},
          draft: draft,
          onDraftChanged: (value) => saved = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(partial.join(' ')), findsOneWidget);
    final nextWord = task.choices.skip(2).first;
    await tester.tap(find.widgetWithText(FilledButton, nextWord));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.currentOrderedWords, <String>[...partial, nextWord]);
  });

  testWidgets('word-builder draft restores partial touch input', (
    tester,
  ) async {
    final task = GermanTouchTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-spell-forest-build',
    );
    final draft = GermanRoundDraft(
      gradeLevel: task.recommendedFromGrade,
      taskIds: <String>[task.id],
      currentIndex: 0,
      startedAt: DateTime(2026, 9, 18, 9),
      updatedAt: DateTime(2026, 9, 18, 9, 1),
      completedResults: const <GermanTaskResult>[],
      currentOrderedWords: const <String>['Wal'],
    );
    GermanRoundDraft? saved;

    await tester.pumpWidget(
      MaterialApp(
        home: GermanTrainingScreen(
          gradeLevel: task.recommendedFromGrade,
          tasks: <GermanTask>[task],
          speak: (_) async {},
          draft: draft,
          onDraftChanged: (value) => saved = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Wal'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'd'));
    await tester.pump();

    expect(find.text('Wald'), findsOneWidget);
    expect(saved, isNotNull);
    expect(saved!.currentOrderedWords, <String>['Wal', 'd']);
  });

  testWidgets('training resumes at the saved task and preserves evidence', (
    tester,
  ) async {
    final draft = draftForTwoTasks();
    final tasks = draft.resolveTasks()!;
    GermanSessionResult? completed;

    await tester.pumpWidget(
      MaterialApp(
        home: GermanTrainingScreen(
          gradeLevel: GradeLevel.second,
          tasks: tasks,
          speak: (_) async {},
          draft: draft,
          onComplete: (result) => completed = result,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 von 2'), findsOneWidget);
    await tester.tap(find.text(tasks.last.acceptedAnswers.first));
    await tester.pumpAndSettle();

    expect(completed, isNotNull);
    expect(completed!.taskResults.length, 2);
    expect(completed!.taskResults.first.taskId, tasks.first.id);
    expect(completed!.taskResults.last.taskId, tasks.last.id);
  });

  testWidgets('German home discards a draft from another grade', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.third;
    final storage = GermanStorageService(profileId: controller.activeProfileId);
    await storage.setIntroComplete(true);
    await storage.saveRoundDraft(draftForTwoTasks());

    await tester.pumpWidget(
      MaterialApp(home: GermanHomeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('german-resume-round')), findsNothing);
    expect(find.byKey(const ValueKey('german-daily-round')), findsOneWidget);
    expect(await storage.loadRoundDraft(), isNull);
  });

  testWidgets('German home offers an interrupted round to continue', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    final storage = GermanStorageService(profileId: controller.activeProfileId);
    final draft = draftForTwoTasks();
    await storage.saveRoundDraft(draft);

    await tester.pumpWidget(
      MaterialApp(
        home: GermanHomeScreen(
          controller: controller,
          now: () => DateTime(2026, 9, 17, 10, 3),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('german-resume-round')), findsOneWidget);
    expect(find.textContaining('Aufgabe 2 von 2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('german-resume-round')));
    await tester.pumpAndSettle();

    expect(find.text('Deutsch üben'), findsOneWidget);
    expect(find.text('2 von 2'), findsOneWidget);
  });
}
