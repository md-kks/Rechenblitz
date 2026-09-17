import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/subjects/german/german_round_draft.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_storage_service.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';
import 'package:rechenblitz/subjects/german/screens/german_home_screen.dart';
import 'package:rechenblitz/subjects/german/screens/german_training_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  GermanRoundDraft draftForTwoTasks({String? assignmentPayload}) {
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
      assignmentPayload: assignmentPayload,
    );
  }

  test('German round draft round-trips and stays profile scoped', () async {
    final draft = draftForTwoTasks();
    final first = GermanStorageService(profileId: 'first');
    final second = GermanStorageService(profileId: 'second');

    await first.saveRoundDraft(draft);
    final restored = await first.loadRoundDraft();

    expect(restored, isNotNull);
    expect(restored!.taskIds, draft.taskIds);
    expect(restored.currentIndex, 1);
    expect(
      restored.completedResults.single.taskId,
      draft.completedResults.single.taskId,
    );
    expect(await second.loadRoundDraft(), isNull);
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

  testWidgets('German home offers an interrupted round to continue', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    final storage = GermanStorageService(profileId: controller.activeProfileId);
    final draft = draftForTwoTasks();
    await storage.saveRoundDraft(draft);

    await tester.pumpWidget(
      MaterialApp(home: GermanHomeScreen(controller: controller)),
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
