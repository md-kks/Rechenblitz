import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/models/training_session_progress.dart';
import 'package:rechenblitz/screens/training_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test(
    'dieselbe Fact-Antwort wird auch nach Neustart nur einmal gezählt',
    () async {
      final storage = StorageService();
      final controller = AppController(storage: storage);
      await controller.load();
      final fact = _fact(controller);

      await controller.recordAttempt(
        fact,
        correct: true,
        responseTime: const Duration(milliseconds: 1200),
        usedHelp: true,
        attemptId: 'attempt:stable:1',
      );
      expect(fact.attempts, 1);
      expect(fact.correctAttempts, 1);
      expect(fact.helpCount, 1);

      final reloaded = AppController();
      await reloaded.load();
      final restored = reloaded.facts.firstWhere(
        (entry) => entry.key == fact.key,
      );
      expect(restored.lastAttemptId, 'attempt:stable:1');

      await reloaded.recordAttempt(
        restored,
        correct: true,
        responseTime: const Duration(milliseconds: 1200),
        usedHelp: true,
        attemptId: 'attempt:stable:1',
      );

      expect(restored.attempts, 1);
      expect(restored.correctAttempts, 1);
      expect(restored.helpCount, 1);
    },
  );

  test(
    'Pending-Fact-Antwort roundtript und bindet sich an dieselbe Aufgabe',
    () {
      final now = DateTime(2026, 9, 17, 18);
      const pending = PendingFactAttempt(
        id: 'round:plus:2:3:1',
        taskKey: 'plus:2:3',
        correct: false,
        actualAnswer: 6,
        responseMs: 1800,
        usedHelp: false,
      );
      final progress = CoreTrainingSessionProgress(
        kind: CoreTrainingKind.fact,
        mode: TrainingMode.practice,
        targetTasks: 4,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        startedAt: now.subtract(const Duration(minutes: 2)),
        updatedAt: now,
        currentTask: const {'key': 'plus:2:3'},
        factAttemptSequence: 1,
        pendingFactAttempt: pending,
      );

      final restored = CoreTrainingSessionProgress.fromJson(progress.toJson());
      expect(restored.pendingFactAttempt?.id, pending.id);
      expect(restored.pendingFactAttempt?.actualAnswer, 6);
      expect(restored.hasSaneState(now: now), isTrue);

      final broken = CoreTrainingSessionProgress(
        kind: CoreTrainingKind.fact,
        mode: TrainingMode.practice,
        targetTasks: 4,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        startedAt: now.subtract(const Duration(minutes: 2)),
        updatedAt: now,
        currentTask: const {'key': 'plus:4:4'},
        factAttemptSequence: 1,
        pendingFactAttempt: pending,
      );
      expect(broken.hasSaneState(now: now), isFalse);
    },
  );

  testWidgets(
    'bereits gespeicherte Pending-Antwort wird beim Resume nicht doppelt gezählt',
    (tester) async {
      final controller = AppController();
      await controller.load();
      final fact = _fact(controller);
      const attemptId = 'resume:committed:1';

      await controller.recordAttempt(
        fact,
        correct: false,
        responseTime: const Duration(milliseconds: 900),
        usedHelp: false,
        attemptId: attemptId,
      );
      expect(fact.attempts, 1);

      final now = DateTime.now();
      controller.coreTrainingSessionProgress = CoreTrainingSessionProgress(
        kind: CoreTrainingKind.fact,
        mode: TrainingMode.practice,
        targetTasks: 2,
        gradeLevel: controller.gradeLevel,
        numberRange: controller.numberRange,
        startedAt: now.subtract(const Duration(minutes: 1)),
        updatedAt: now,
        currentTask: {'key': fact.key},
        taskFirstAttemptRecorded: true,
        factAttemptSequence: 1,
        pendingFactAttempt: PendingFactAttempt(
          id: attemptId,
          taskKey: fact.key,
          correct: false,
          actualAnswer: fact.result + 1,
          responseMs: 900,
          usedHelp: false,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TrainingScreen(
            controller: controller,
            mode: TrainingMode.practice,
            targetTasks: 2,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(fact.attempts, 1);
      expect(controller.coreTrainingSessionProgress?.wrongOnCurrent, 1);
      expect(
        controller.coreTrainingSessionProgress?.pendingFactAttempt,
        isNull,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'noch nicht angewendete Pending-Antwort wird beim Resume genau einmal nachgetragen',
    (tester) async {
      final controller = AppController();
      await controller.load();
      final fact = _fact(controller);
      final now = DateTime.now();
      controller.coreTrainingSessionProgress = CoreTrainingSessionProgress(
        kind: CoreTrainingKind.fact,
        mode: TrainingMode.practice,
        targetTasks: 2,
        gradeLevel: controller.gradeLevel,
        numberRange: controller.numberRange,
        startedAt: now.subtract(const Duration(minutes: 1)),
        updatedAt: now,
        currentTask: {'key': fact.key},
        taskFirstAttemptRecorded: true,
        factAttemptSequence: 1,
        pendingFactAttempt: PendingFactAttempt(
          id: 'resume:pending:1',
          taskKey: fact.key,
          correct: false,
          actualAnswer: fact.result + 1,
          responseMs: 1100,
          usedHelp: false,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TrainingScreen(
            controller: controller,
            mode: TrainingMode.practice,
            targetTasks: 2,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(fact.attempts, 1);
      expect(fact.incorrectAttempts, 1);
      expect(fact.lastAttemptId, 'resume:pending:1');
      expect(controller.coreTrainingSessionProgress?.wrongOnCurrent, 1);
      expect(
        controller.coreTrainingSessionProgress?.pendingFactAttempt,
        isNull,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}

MathFact _fact(AppController controller) => controller.facts.firstWhere(
  (fact) => fact.operation == MathOperation.plus && fact.a == 2 && fact.b == 3,
);
