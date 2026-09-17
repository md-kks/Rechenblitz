import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/assessment.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/learning_path.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/remediation_path.dart';
import 'package:rechenblitz/models/support_session_progress.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('Lerncheck verwirft semantisch beschädigte Resume-Daten', () {
    final now = DateTime(2026, 9, 17, 18);
    final progress = AssessmentProgress(
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      tasks: const <AssessmentTask>[
        AssessmentTask(
          mode: TrainingMode.practice,
          taskKey: 'plus:2:3',
          prompt: '',
          answer: 5,
          maxAnswerValue: 10,
        ),
        AssessmentTask(
          mode: TrainingMode.minus,
          taskKey: 'minus:8:3',
          prompt: '8 − 3 = ?',
          answer: 5,
          maxAnswerValue: 10,
        ),
      ],
      taskResults: const <AssessmentTaskResult>[
        AssessmentTaskResult(
          mode: TrainingMode.practice,
          taskKey: 'plus:2:3',
          correct: true,
        ),
      ],
      nextIndex: 1,
      startedAt: now.subtract(const Duration(minutes: 4)),
      updatedAt: now,
    );

    expect(progress.hasSaneState(now: now), isFalse);
    expect(
      progress.isCompatible(
        grade: GradeLevel.second,
        range: NumberRangeLevel.hundred,
        now: now,
      ),
      isFalse,
    );
  });

  test('Meine Runde verwirft unmögliche Rollen und Aufgabenzähler', () {
    final now = DateTime(2026, 9, 17, 18);
    const segment = GuidedRoundSegment(
      role: GuidedRoundRole.warmUp,
      mode: TrainingMode.practice,
      tasks: 2,
      reason: 'Ankommen',
    );
    final foreignRole = GuidedRoundProgress(
      plan: const <GuidedRoundSegment>[segment],
      completedRoles: const <GuidedRoundRole>{GuidedRoundRole.focus},
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      startedAt: now.subtract(const Duration(minutes: 2)),
      updatedAt: now,
      recoveryRequired: false,
    );
    final impossibleCount = GuidedRoundProgress(
      plan: const <GuidedRoundSegment>[segment],
      completedRoles: const <GuidedRoundRole>{GuidedRoundRole.warmUp},
      completedTaskCounts: const <GuidedRoundRole, int>{
        GuidedRoundRole.warmUp: 3,
      },
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      startedAt: now.subtract(const Duration(minutes: 2)),
      updatedAt: now,
      recoveryRequired: false,
    );

    expect(foreignRole.hasSaneState(now: now), isFalse);
    expect(impossibleCount.hasSaneState(now: now), isFalse);
  });

  test('Support-Sitzungen verwerfen widersprüchliche Zähler', () {
    final now = DateTime(2026, 9, 17, 18);
    final remediation = RemediationSessionProgress(
      pattern: ErrorPattern.countingStep,
      mode: TrainingMode.minus,
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      reviewOnly: false,
      tasks: const <RemediationTask>[_supportTask],
      index: 0,
      wrongOnCurrent: 1,
      firstAttemptRecorded: false,
      checkCorrect: 2,
      checkTotal: 1,
      showHint: true,
      updatedAt: now,
    );
    final recovery = StepRecoverySessionProgress(
      focus: _focus(now),
      numberRange: NumberRangeLevel.hundred,
      tasks: const <RemediationTask>[_supportTask],
      index: 0,
      wrongOnCurrent: 1,
      firstAttemptRecorded: false,
      showHint: true,
      updatedAt: now,
    );

    expect(remediation.hasSaneState(now: now), isFalse);
    expect(recovery.hasSaneState(now: now), isFalse);
  });

  test(
    'Speicher heilt unlesbare Resume-Daten aller Nicht-Core-Flows',
    () async {
      final storage = StorageService();
      await storage.initializeProfiles();
      final prefs = await SharedPreferences.getInstance();
      const keys = <String>[
        'profile:default:guided_round_v1',
        'profile:default:assessment_progress_v1',
        'profile:default:remediation_session_v1',
        'profile:default:step_recovery_session_v1',
      ];
      for (final key in keys) {
        await prefs.setString(key, '{defekt');
      }

      expect(await storage.loadGuidedRoundProgress(), isNull);
      expect(await storage.loadAssessmentProgress(), isNull);
      expect(await storage.loadRemediationSession(), isNull);
      expect(await storage.loadStepRecoverySession(), isNull);
      for (final key in keys) {
        expect(prefs.containsKey(key), isFalse, reason: key);
      }
    },
  );

  test(
    'Controller räumt semantisch beschädigte Resume-Daten beim Laden auf',
    () async {
      final storage = StorageService();
      await storage.initializeProfiles();
      final now = DateTime.now();

      await storage.saveGuidedRoundProgress(
        GuidedRoundProgress(
          plan: const <GuidedRoundSegment>[
            GuidedRoundSegment(
              role: GuidedRoundRole.focus,
              mode: TrainingMode.minus,
              tasks: 0,
              reason: 'Fokus',
            ),
          ],
          completedRoles: const <GuidedRoundRole>{},
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          startedAt: now.subtract(const Duration(minutes: 2)),
          updatedAt: now,
          recoveryRequired: false,
        ),
      );
      await storage.saveAssessmentProgress(
        AssessmentProgress(
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          tasks: const <AssessmentTask>[
            AssessmentTask(
              mode: TrainingMode.practice,
              taskKey: 'plus:2:3',
              prompt: '',
              answer: 5,
              maxAnswerValue: 10,
            ),
            AssessmentTask(
              mode: TrainingMode.minus,
              taskKey: 'minus:8:3',
              prompt: '8 − 3 = ?',
              answer: 5,
              maxAnswerValue: 10,
            ),
          ],
          taskResults: const <AssessmentTaskResult>[
            AssessmentTaskResult(
              mode: TrainingMode.practice,
              taskKey: 'plus:2:3',
              correct: true,
            ),
          ],
          nextIndex: 1,
          startedAt: now.subtract(const Duration(minutes: 2)),
          updatedAt: now,
        ),
      );
      await storage.saveRemediationSession(
        RemediationSessionProgress(
          pattern: ErrorPattern.countingStep,
          mode: TrainingMode.minus,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          reviewOnly: false,
          tasks: const <RemediationTask>[_supportTask],
          index: 0,
          wrongOnCurrent: -1,
          firstAttemptRecorded: false,
          checkCorrect: 0,
          checkTotal: 0,
          showHint: false,
          updatedAt: now,
        ),
      );
      await storage.saveStepRecoverySession(
        StepRecoverySessionProgress(
          focus: _focus(now),
          numberRange: NumberRangeLevel.hundred,
          tasks: const <RemediationTask>[_supportTask],
          index: 0,
          wrongOnCurrent: -1,
          firstAttemptRecorded: false,
          showHint: false,
          updatedAt: now,
        ),
      );

      final controller = AppController(storage: storage);
      await controller.load();

      expect(controller.guidedRoundProgress, isNull);
      expect(controller.assessmentProgress, isNull);
      expect(controller.remediationSessionProgress, isNull);
      expect(controller.stepRecoverySessionProgress, isNull);
      expect(await storage.loadGuidedRoundProgress(), isNull);
      expect(await storage.loadAssessmentProgress(), isNull);
      expect(await storage.loadRemediationSession(), isNull);
      expect(await storage.loadStepRecoverySession(), isNull);
    },
  );
}

const _supportTask = RemediationTask(
  stage: RemediationStage.guided,
  mode: TrainingMode.minus,
  taskKey: 'remediation:countingStep:minus:8:3',
  prompt: '8 − 3 = ?',
  answer: 5,
  maxAnswerValue: 10,
  hint: 'Gehe drei Schritte zurück.',
);

IndependentStepRecoveryFocus _focus(DateTime now) =>
    IndependentStepRecoveryFocus(
      competencyId: MicroCompetencyId.subtractionNoBridge,
      stepKey: 'subtract-step',
      label: 'Minus-Schritt',
      mode: TrainingMode.minus,
      lastSeen: now.subtract(const Duration(minutes: 10)),
      sourceTaskKey: 'minus:8:3',
    );
