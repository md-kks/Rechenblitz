import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/active_response_timer.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/models/training_session_progress.dart';
import 'package:rechenblitz/screens/training_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CaptureController extends AppController {
  Duration? lastFactResponse;

  @override
  Future<void> recordAttempt(
    MathFact fact, {
    required bool correct,
    required Duration responseTime,
    required bool usedHelp,
  }) async {
    lastFactResponse = responseTime;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('aktive Antwortzeit zählt Hintergrundpausen nicht mit', () {
    final start = DateTime(2026, 9, 17, 10);
    final timer = ActiveResponseTimer(startedAt: start);

    expect(
      timer.elapsed(at: start.add(const Duration(seconds: 3))),
      const Duration(seconds: 3),
    );

    timer.pause(at: start.add(const Duration(seconds: 3)));
    expect(timer.isPaused, isTrue);
    expect(
      timer.elapsed(at: start.add(const Duration(minutes: 5))),
      const Duration(seconds: 3),
    );

    timer.resume(at: start.add(const Duration(minutes: 5)));
    expect(timer.isPaused, isFalse);
    expect(
      timer.elapsed(at: start.add(const Duration(minutes: 5, seconds: 2))),
      const Duration(seconds: 5),
    );

    timer.reset(at: start.add(const Duration(minutes: 10)));
    expect(
      timer.elapsed(at: start.add(const Duration(minutes: 10, seconds: 4))),
      const Duration(seconds: 4),
    );
  });

  test('semantisch beschädigte Trainingsentwürfe werden abgelehnt', () {
    final now = DateTime(2026, 9, 17, 12);

    CoreTrainingSessionProgress factDraft({
      int completed = 0,
      int correctFirstTry = 0,
      int helpLevel = 0,
      DateTime? updatedAt,
      Map<String, dynamic> currentTask = const {'key': 'plus:2:3'},
    }) => CoreTrainingSessionProgress(
      kind: CoreTrainingKind.fact,
      mode: TrainingMode.practice,
      targetTasks: 4,
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.twenty,
      startedAt: now.subtract(const Duration(minutes: 2)),
      updatedAt: updatedAt ?? now,
      currentTask: currentTask,
      completed: completed,
      correctFirstTry: correctFirstTry,
      helpLevel: helpLevel,
    );

    expect(factDraft().hasSaneState(now: now), isTrue);
    expect(factDraft(completed: -1).hasSaneState(now: now), isFalse);
    expect(
      factDraft(completed: 1, correctFirstTry: 2).hasSaneState(now: now),
      isFalse,
    );
    expect(factDraft(helpLevel: 4).hasSaneState(now: now), isFalse);
    expect(factDraft(currentTask: const {}).hasSaneState(now: now), isFalse);
    expect(
      factDraft(
        updatedAt: now.add(const Duration(minutes: 1)),
      ).hasSaneState(now: now),
      isFalse,
    );

    final brokenStructured = CoreTrainingSessionProgress(
      kind: CoreTrainingKind.structured,
      mode: TrainingMode.money,
      targetTasks: 3,
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.twenty,
      startedAt: now.subtract(const Duration(minutes: 2)),
      updatedAt: now,
      currentTask: const {'mode': 'money'},
    );
    expect(brokenStructured.hasSaneState(now: now), isFalse);
  });

  test(
    'nicht lesbarer Trainingsentwurf wird beim Laden selbst geheilt',
    () async {
      final storage = StorageService();
      await storage.initializeProfiles();
      final prefs = await SharedPreferences.getInstance();
      const key = 'profile:default:core_training_session_v1';
      await prefs.setString(key, '{kaputt');

      expect(await storage.loadCoreTrainingSession(), isNull);
      expect(prefs.containsKey(key), isFalse);
    },
  );

  test(
    'Controller entfernt beschädigten gespeicherten Entwurf beim Laden',
    () async {
      final storage = StorageService();
      await storage.initializeProfiles();
      final now = DateTime.now();
      await storage.saveCoreTrainingSession(
        CoreTrainingSessionProgress(
          kind: CoreTrainingKind.fact,
          mode: TrainingMode.practice,
          targetTasks: 4,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.twenty,
          startedAt: now.subtract(const Duration(minutes: 2)),
          updatedAt: now,
          currentTask: const {'key': 'plus:2:3'},
          completed: -1,
        ),
      );

      final controller = AppController(storage: storage);
      await controller.load();

      expect(controller.coreTrainingSessionProgress, isNull);
      expect(await storage.loadCoreTrainingSession(), isNull);
    },
  );

  testWidgets('Grundrechnen pausiert die Antwortzeit im Hintergrund', (
    tester,
  ) async {
    final controller = _CaptureController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.ten;
    controller.facts = <MathFact>[
      MathFact(a: 2, b: 3, operation: MathOperation.plus),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: TrainingScreen(
          controller: controller,
          mode: TrainingMode.practice,
          targetTasks: 1,
        ),
      ),
    );
    await tester.pump();

    final keypadSwitch = find.byKey(const ValueKey('touch-switch-keypad'));
    if (keypadSwitch.evaluate().isNotEmpty) {
      await tester.tap(keypadSwitch);
      await tester.pump();
    }

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1200)),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, '5').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(controller.lastFactResponse, isNotNull);
    expect(controller.lastFactResponse!, lessThan(const Duration(seconds: 1)));

    await tester.pump(const Duration(milliseconds: 650));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
