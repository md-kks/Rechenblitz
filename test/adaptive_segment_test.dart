import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/adaptive_segment.dart';
import 'package:rechenblitz/models/learning_path.dart';
import 'package:rechenblitz/models/training.dart';

void main() {
  group('AdaptiveSegmentPolicy', () {
    AdaptiveSegmentDecision decide({
      bool enabled = true,
      TrainingMode mode = TrainingMode.practice,
      int plannedTasks = 5,
      int completed = 3,
      int correctFirstTry = 3,
      int incorrectAttempts = 0,
      bool usedHelp = false,
      bool targetStable = true,
      bool reviewEmphasis = false,
      bool transferEmphasis = false,
    }) => AdaptiveSegmentPolicy.evaluate(
      enabled: enabled,
      mode: mode,
      plannedTasks: plannedTasks,
      completed: completed,
      correctFirstTry: correctFirstTry,
      incorrectAttempts: incorrectAttempts,
      usedHelp: usedHelp,
      targetStable: targetStable,
      reviewEmphasis: reviewEmphasis,
      transferEmphasis: transferEmphasis,
    );

    test(
      'ends a stable ordinary segment after three independent successes',
      () {
        final result = decide();

        expect(result.shouldStop, isTrue);
        expect(result.kind, AdaptiveSegmentStopKind.confirmed);
        expect(result.message, contains('Drei selbstständige Aufgaben'));
      },
    );

    test('never stops before three completed tasks', () {
      final result = decide(completed: 2, correctFirstTry: 2);
      expect(result.shouldStop, isFalse);
    });

    test('does not shorten disabled or already short segments', () {
      expect(decide(enabled: false).shouldStop, isFalse);
      expect(decide(plannedTasks: 4).shouldStop, isFalse);
    });

    test('protects timed fluency modes from adaptive shortening', () {
      for (final mode in <TrainingMode>[
        TrainingMode.speed,
        TrainingMode.tempo,
        TrainingMode.blitz,
      ]) {
        expect(decide(mode: mode).shouldStop, isFalse, reason: mode.name);
      }
    });

    test(
      'help, unstable evidence, review and transfer block confirmation stop',
      () {
        expect(decide(usedHelp: true).shouldStop, isFalse);
        expect(decide(targetStable: false).shouldStop, isFalse);
        expect(decide(reviewEmphasis: true).shouldStop, isFalse);
        expect(decide(transferEmphasis: true).shouldStop, isFalse);
      },
    );

    test('stops an overloaded segment instead of drilling on', () {
      final result = decide(
        completed: 3,
        correctFirstTry: 1,
        incorrectAttempts: 3,
        targetStable: false,
      );

      expect(result.shouldStop, isTrue);
      expect(result.kind, AdaptiveSegmentStopKind.overload);
      expect(result.message, contains('weiteres Wiederholen'));
    });

    test('does not stop once the planned segment is already complete', () {
      expect(
        decide(completed: 5, correctFirstTry: 5, plannedTasks: 5).shouldStop,
        isFalse,
      );
    });
  });

  test('adaptive TrainingSessionResult survives local JSON round-trip', () {
    final original = TrainingSessionResult(
      mode: TrainingMode.practice,
      startedAt: DateTime(2026, 9, 16, 8),
      finishedAt: DateTime(2026, 9, 16, 8, 2),
      total: 3,
      correctFirstTry: 3,
      incorrectAttempts: 0,
      plusCorrect: 3,
      plusTotal: 3,
      minusCorrect: 0,
      minusTotal: 0,
      averageResponseMs: 2100,
      numberRange: NumberRangeLevel.twenty,
      gradeLevel: GradeLevel.second,
      plannedTotal: 5,
      adaptiveStopReason: 'Sicher bestätigt.',
    );

    final restored = TrainingSessionResult.fromJson(original.toJson());

    expect(restored.total, 3);
    expect(restored.plannedTotal, 5);
    expect(restored.adaptiveStopReason, 'Sicher bestätigt.');
    expect(restored.endedAdaptively, isTrue);
  });

  test(
    'guided-round progress stores actual task counts and legacy fallback',
    () {
      const warmUp = GuidedRoundSegment(
        role: GuidedRoundRole.warmUp,
        mode: TrainingMode.practice,
        tasks: 5,
        reason: 'Ankommen',
      );
      const focus = GuidedRoundSegment(
        role: GuidedRoundRole.focus,
        mode: TrainingMode.minus,
        tasks: 5,
        reason: 'Fokus',
      );
      final now = DateTime(2026, 9, 16, 9);
      final progress = GuidedRoundProgress(
        plan: const <GuidedRoundSegment>[warmUp, focus],
        completedRoles: const <GuidedRoundRole>{GuidedRoundRole.warmUp},
        completedTaskCounts: const <GuidedRoundRole, int>{
          GuidedRoundRole.warmUp: 3,
        },
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.twenty,
        startedAt: now,
        updatedAt: now,
        recoveryRequired: false,
      );

      expect(progress.completedRegularTasks, 3);
      expect(progress.effectiveRegularTaskTotal, 8);

      final restored = GuidedRoundProgress.fromJson(progress.toJson());
      expect(restored.completedTaskCounts[GuidedRoundRole.warmUp], 3);
      expect(restored.completedRegularTasks, 3);
      expect(restored.effectiveRegularTaskTotal, 8);

      final legacy = GuidedRoundProgress.fromJson(<String, dynamic>{
        'plan': <Map<String, dynamic>>[warmUp.toJson(), focus.toJson()],
        'completedRoles': <String>['warmUp'],
        'gradeLevel': GradeLevel.second.name,
        'numberRange': NumberRangeLevel.twenty.name,
        'startedAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'recoveryRequired': false,
      });
      expect(legacy.completedRegularTasks, 5);
      expect(legacy.effectiveRegularTaskTotal, 10);
    },
  );

  test('round compaction budgets use actual completed tasks', () {
    const current = <GuidedRoundSegment>[
      GuidedRoundSegment(
        role: GuidedRoundRole.warmUp,
        mode: TrainingMode.practice,
        tasks: 5,
        reason: 'Ankommen',
      ),
      GuidedRoundSegment(
        role: GuidedRoundRole.focus,
        mode: TrainingMode.minus,
        tasks: 5,
        reason: 'Fokus',
      ),
      GuidedRoundSegment(
        role: GuidedRoundRole.review,
        mode: TrainingMode.numberFriends,
        tasks: 2,
        reason: 'Wiederholen',
      ),
    ];

    final compacted = GuidedRoundOrchestrator.mergeRemaining(
      current: current,
      updated: current,
      completedRoles: const <GuidedRoundRole>{GuidedRoundRole.warmUp},
      completedTaskCounts: const <GuidedRoundRole, int>{
        GuidedRoundRole.warmUp: 3,
      },
      regularTaskBudget: 9,
    );

    final open = compacted
        .where((segment) => segment.role != GuidedRoundRole.warmUp)
        .fold<int>(0, (sum, segment) => sum + segment.tasks);
    expect(open, 6);
    expect(
      compacted.any((segment) => segment.role == GuidedRoundRole.review),
      isTrue,
    );
  });
}
