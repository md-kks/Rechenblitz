import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/learner_profile.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/remediation_path.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('alte lokale Daten werden in ein Standardprofil übernommen', () async {
    final fact = MathFact(a: 8, b: 5, operation: MathOperation.minus);
    fact.registerAttempt(
      correct: true,
      responseTime: const Duration(seconds: 3),
      usedHelp: false,
    );
    SharedPreferences.setMockInitialValues({
      'grade_level_v1': 'third',
      'number_range_v1': 'thousand',
      'facts_v1': jsonEncode([fact.toJson()]),
    });

    final storage = StorageService();
    final profiles = await storage.initializeProfiles();

    expect(profiles, hasLength(1));
    expect(profiles.first.gradeLevel, GradeLevel.third);
    expect(profiles.first.onboardingComplete, isTrue);
    expect(storage.activeProfileId, 'default');
    expect(await storage.numberRange(), NumberRangeLevel.thousand);

    final restored = await storage.loadFacts();
    expect(restored, contains(fact.key));
    expect(restored[fact.key]!.attempts, 1);
  });

  test('Profile halten Lernstand und Rechenwege getrennt', () async {
    final storage = StorageService();
    var profiles = await storage.initializeProfiles();

    final result = TrainingSessionResult(
      mode: TrainingMode.practice,
      startedAt: DateTime(2026, 9, 4, 10),
      finishedAt: DateTime(2026, 9, 4, 10, 5),
      total: 10,
      correctFirstTry: 8,
      incorrectAttempts: 2,
      plusCorrect: 4,
      plusTotal: 5,
      minusCorrect: 4,
      minusTotal: 5,
      averageResponseMs: 2500,
      numberRange: NumberRangeLevel.twenty,
      gradeLevel: GradeLevel.second,
      starsEarned: 2,
    );
    await storage.saveHistory([result]);

    final second = LearnerProfile(
      id: 'second',
      name: 'Zweites Profil',
      gradeLevel: GradeLevel.fourth,
      createdAt: DateTime(2026, 9, 4),
    );
    profiles = [...profiles, second];
    await storage.saveProfiles(profiles);
    await storage.setActiveProfileId(second.id);
    await storage.setNumberRange(NumberRangeLevel.million);
    await storage.setMethodPreferences(
      const MethodPreferences(
        subtraction: SubtractionStrategy.complement,
      ),
    );

    expect(await storage.loadHistory(), isEmpty);
    expect(
      (await storage.methodPreferences()).subtraction,
      SubtractionStrategy.complement,
    );

    await storage.setActiveProfileId('default');
    expect(await storage.loadHistory(), hasLength(1));
    expect(
      (await storage.methodPreferences()).subtraction,
      SubtractionStrategy.bridgeToTen,
    );
  });

  test('neue Profile ohne Altdaten benötigen den Lernstart', () async {
    final storage = StorageService();
    final profiles = await storage.initializeProfiles();

    expect(profiles, hasLength(1));
    expect(profiles.first.onboardingComplete, isFalse);
  });

  test('alte Profil-JSONs ohne Lernstart-Feld bleiben freigeschaltet', () {
    final restored = LearnerProfile.fromJson({
      'id': 'legacy',
      'name': 'Alt',
      'gradeLevel': 'second',
      'createdAt': '2026-09-01T10:00:00.000',
    });

    expect(restored.onboardingComplete, isTrue);
    expect(restored.state, GermanState.thuringia);
  });


  test('Diagnosen bleiben zwischen Profilen getrennt', () async {
    final storage = StorageService();
    var profiles = await storage.initializeProfiles();

    await storage.saveDiagnostics([
      DiagnosticAttempt(
        occurredAt: DateTime(2026, 9, 4, 20),
        mode: TrainingMode.minus,
        taskKey: 'minus:13:5',
        expected: 8,
        actual: 9,
        correct: false,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        pattern: ErrorPattern.tenBridge,
      ),
    ]);

    final second = LearnerProfile(
      id: 'diagnostic-second',
      name: 'Zweites Diagnoseprofil',
      gradeLevel: GradeLevel.second,
      createdAt: DateTime(2026, 9, 4),
    );
    profiles = [...profiles, second];
    await storage.saveProfiles(profiles);
    await storage.setActiveProfileId(second.id);

    expect(await storage.loadDiagnostics(), isEmpty);

    await storage.setActiveProfileId('default');
    final first = await storage.loadDiagnostics();
    expect(first, hasLength(1));
    expect(first.single.pattern, ErrorPattern.tenBridge);
  });


  test('Förderpfad-Status bleibt zwischen Profilen getrennt', () async {
    final storage = StorageService();
    var profiles = await storage.initializeProfiles();

    await storage.saveRemediationProgress([
      RemediationProgress(
        pattern: ErrorPattern.tenBridge,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        status: RemediationStatus.improved,
        startedAt: DateTime(2026, 9, 4),
        completedAt: DateTime(2026, 9, 4),
        nextReviewAt: DateTime(2026, 9, 7),
      ),
    ]);

    final second = LearnerProfile(
      id: 'remediation-second',
      name: 'Zweites Förderprofil',
      gradeLevel: GradeLevel.second,
      createdAt: DateTime(2026, 9, 4),
    );
    profiles = [...profiles, second];
    await storage.saveProfiles(profiles);
    await storage.setActiveProfileId(second.id);

    expect(await storage.loadRemediationProgress(), isEmpty);

    await storage.setActiveProfileId('default');
    final first = await storage.loadRemediationProgress();
    expect(first, hasLength(1));
    expect(first.single.status, RemediationStatus.improved);
  });

}
