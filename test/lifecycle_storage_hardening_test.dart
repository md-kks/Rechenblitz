import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/assessment.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/learner_profile.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/learning_path.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/remediation_path.dart';
import 'package:rechenblitz/models/teacher_assignment.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'Profilregister rettet gültige Profile trotz beschädigter Records',
    () async {
      final keep = LearnerProfile(
        id: 'keep',
        name: 'Bleibt erhalten',
        gradeLevel: GradeLevel.third,
        createdAt: DateTime(2026, 9, 17),
        onboardingComplete: true,
      );
      SharedPreferences.setMockInitialValues(<String, Object>{
        'learner_profiles_v1': jsonEncode(<Object?>[
          keep.toJson(),
          'kaputter Eintrag',
          keep.toJson(),
        ]),
        'active_learner_profile_v1': 'keep',
      });

      final storage = StorageService();
      final profiles = await storage.initializeProfiles();

      expect(profiles, hasLength(1));
      expect(profiles.single.id, 'keep');
      expect(profiles.single.name, 'Bleibt erhalten');
      expect(storage.activeProfileId, 'keep');
    },
  );

  test(
    'Fakten und Verlauf retten gültige Einträge aus beschädigtem JSON',
    () async {
      final storage = StorageService();
      await storage.initializeProfiles();
      final prefs = await SharedPreferences.getInstance();

      final fact = MathFact(a: 8, b: 5, operation: MathOperation.minus);
      final session = TrainingSessionResult(
        mode: TrainingMode.minus,
        startedAt: DateTime(2026, 9, 17, 8),
        finishedAt: DateTime(2026, 9, 17, 8, 5),
        total: 5,
        correctFirstTry: 4,
        incorrectAttempts: 1,
        plusCorrect: 0,
        plusTotal: 0,
        minusCorrect: 4,
        minusTotal: 5,
        averageResponseMs: 1500,
        numberRange: NumberRangeLevel.twenty,
        gradeLevel: GradeLevel.first,
        starsEarned: 2,
      );

      await prefs.setString(
        'profile:default:facts_v1',
        jsonEncode(<Object?>[fact.toJson(), 'defekt']),
      );
      await prefs.setString(
        'profile:default:history_v1',
        jsonEncode(<Object?>[session.toJson(), 17]),
      );

      final facts = await storage.loadFacts();
      final history = await storage.loadHistory();
      expect(facts.keys, contains(fact.key));
      expect(history, hasLength(1));
      expect(history.single.mode, TrainingMode.minus);

      await prefs.setString('profile:default:facts_v1', '{kein json');
      await prefs.setString('profile:default:history_v1', '{kein json');
      expect(await storage.loadFacts(), isEmpty);
      expect(await storage.loadHistory(), isEmpty);
    },
  );

  test(
    'weitere Profildaten retten gültige Records statt alles zu verwerfen',
    () async {
      final storage = StorageService();
      await storage.initializeProfiles();
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime(2026, 9, 17, 9);

      final diagnostic = DiagnosticAttempt(
        occurredAt: now,
        mode: TrainingMode.minus,
        taskKey: '-:8:5',
        expected: 3,
        actual: 4,
        correct: false,
        gradeLevel: GradeLevel.first,
        numberRange: NumberRangeLevel.twenty,
        pattern: ErrorPattern.countingStep,
      );
      final remediation = RemediationProgress(
        pattern: ErrorPattern.countingStep,
        gradeLevel: GradeLevel.first,
        numberRange: NumberRangeLevel.twenty,
        status: RemediationStatus.inProgress,
        startedAt: now,
      );
      final observation = MicroCompetencyObservation(
        id: MicroCompetencyId.subtractionNoBridge,
        occurredAt: now,
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        mode: TrainingMode.minus,
        gradeLevel: GradeLevel.first,
        numberRange: NumberRangeLevel.twenty,
        taskKey: '-:8:5',
      );

      await prefs.setString(
        'profile:default:diagnostics_v1',
        jsonEncode(<Object?>[diagnostic.toJson(), 'defekt']),
      );
      await prefs.setString(
        'profile:default:remediation_progress_v1',
        jsonEncode(<Object?>[remediation.toJson(), false]),
      );
      await prefs.setString(
        'profile:default:micro_competency_v1',
        jsonEncode(<Object?>[observation.toJson(), 'defekt']),
      );
      await prefs.setString(
        'profile:default:task_diversity_v1',
        jsonEncode(<String, Object?>{
          'minus': <Object?>['-:8:5', 17, '-:9:4'],
          'kaputt': 'keine Liste',
        }),
      );

      expect((await storage.loadDiagnostics()).single.taskKey, '-:8:5');
      expect(
        (await storage.loadRemediationProgress()).single.pattern,
        ErrorPattern.countingStep,
      );
      expect(
        (await storage.loadMicroCompetencyObservations()).single.id,
        MicroCompetencyId.subtractionNoBridge,
      );
      expect(await storage.loadTaskDiversity(), <String, List<String>>{
        'minus': <String>['-:8:5', '-:9:4'],
      });
    },
  );

  test(
    'Fortschrittsreset löscht transiente Lernzustände auch im RAM',
    () async {
      final controller = AppController();
      await controller.load();
      await controller.completeAssessment(const <AssessmentModeResult>[]);
      expect(controller.activeProfile.assessmentCompletedAt, isNotNull);

      final now = DateTime.now();
      final round = GuidedRoundProgress(
        plan: const <GuidedRoundSegment>[
          GuidedRoundSegment(
            role: GuidedRoundRole.warmUp,
            mode: TrainingMode.practice,
            tasks: 2,
            reason: 'Ankommen',
          ),
        ],
        completedRoles: const <GuidedRoundRole>{},
        gradeLevel: controller.gradeLevel,
        numberRange: controller.numberRange,
        startedAt: now,
        updatedAt: now,
        recoveryRequired: false,
      );
      await controller.saveGuidedRoundProgress(round);
      controller.beginTeacherAssignment(
        TeacherAssignment(
          gradeLevel: controller.gradeLevel,
          numberRange: NumberRangeLevel.twenty,
          mode: TrainingMode.practice,
          tasks: 4,
          methods: const MethodPreferences(),
        ),
      );

      expect(controller.resumableGuidedRound(now: now), isNotNull);
      expect(controller.hasTeacherAssignment, isTrue);

      await controller.resetProgress();

      expect(controller.guidedRoundProgress, isNull);
      expect(controller.resumableGuidedRound(now: now), isNull);
      expect(controller.hasTeacherAssignment, isFalse);
      expect(controller.activeProfile.onboardingComplete, isTrue);
      expect(controller.activeProfile.assessmentCompletedAt, isNull);

      final reloaded = AppController();
      await reloaded.load();
      expect(reloaded.guidedRoundProgress, isNull);
      expect(reloaded.activeProfile.onboardingComplete, isTrue);
      expect(reloaded.activeProfile.assessmentCompletedAt, isNull);
    },
  );

  test('Profil- und Lernkontextwechsel beenden einen Schulauftrag', () async {
    final controller = AppController();
    await controller.load();
    final firstProfile = controller.activeProfileId;
    await controller.createProfile(
      name: 'Zweites Profil',
      grade: GradeLevel.second,
    );
    final secondProfile = controller.activeProfileId;
    await controller.switchProfile(firstProfile);

    TeacherAssignment assignment() => TeacherAssignment(
      gradeLevel: controller.gradeLevel,
      numberRange: NumberRangeLevel.twenty,
      mode: TrainingMode.minus,
      tasks: 6,
      methods: const MethodPreferences(),
    );

    controller.beginTeacherAssignment(assignment());
    await controller.switchProfile(secondProfile);
    expect(controller.hasTeacherAssignment, isFalse);

    controller.beginTeacherAssignment(assignment());
    final nextRange = controller.numberRange == NumberRangeLevel.twenty
        ? NumberRangeLevel.hundred
        : NumberRangeLevel.twenty;
    await controller.setNumberRange(nextRange);
    expect(controller.hasTeacherAssignment, isFalse);

    controller.beginTeacherAssignment(assignment());
    await controller.setGradeLevel(GradeLevel.third);
    expect(controller.hasTeacherAssignment, isFalse);

    controller.beginTeacherAssignment(
      TeacherAssignment(
        gradeLevel: controller.gradeLevel,
        numberRange: controller.numberRange,
        mode: TrainingMode.largeNumbers,
        tasks: 4,
        methods: const MethodPreferences(),
      ),
    );
    await controller.deleteProfile(secondProfile);
    expect(controller.activeProfileId, firstProfile);
    expect(controller.hasTeacherAssignment, isFalse);
  });
}
