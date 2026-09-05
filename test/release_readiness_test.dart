import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/accessibility_preferences.dart';
import 'package:rechenblitz/models/beta_feedback.dart';
import 'package:rechenblitz/models/curriculum_audit.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/evidence_coverage_audit.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/remediation_path.dart';
import 'package:rechenblitz/models/structured_exercise.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/services/adaptive_engine.dart';
import 'package:rechenblitz/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Transfer-Sachaufgaben Klasse 3/4 enthalten anspruchsvollere Strukturen',
      () {
    final generator = StructuredExerciseGenerator(random: Random(20260905));
    final keys = <String>[];

    for (var i = 0; i < 40; i++) {
      final exercise = generator.generate(
        mode: TrainingMode.wordProblems,
        maxValue: 1000,
        gradeLevel: GradeLevel.third,
        transferEmphasis: true,
      );
      keys.add(exercise.key);
    }

    expect(
      keys.every(
        (key) =>
            key.startsWith('story:multi:') ||
            key.startsWith('story:transfer:'),
      ),
      isTrue,
    );
    expect(keys.toSet().length, greaterThan(20));
  });

  test('Klasse 1/2 bleiben bei altersgerechten einfachen Sachaufgaben', () {
    final generator = StructuredExerciseGenerator(random: Random(25));

    for (var i = 0; i < 30; i++) {
      final exercise = generator.generate(
        mode: TrainingMode.wordProblems,
        maxValue: 100,
        gradeLevel: GradeLevel.second,
        transferEmphasis: false,
      );
      expect(exercise.key, isNot(startsWith('story:multi:')));
      expect(exercise.key, isNot(startsWith('story:transfer:')));
    }
  });

  test('Thüringen-Audit deckt jede Mikro-Kompetenz strukturell ab', () {
    for (final grade in GradeLevel.values) {
      final summary = CurriculumAuditCatalog.audit(grade);
      final expected = MicroCompetencyCatalog.forGrade(grade).length;
      expect(summary.structurallyComplete, isTrue, reason: grade.name);
      expect(summary.total, expected, reason: grade.name);
      expect(summary.missingCompetencies, isEmpty, reason: grade.name);
    }
  });

  test('Lehrplan-Audit markiert reale Handlungsanteile transparent', () {
    final items = CurriculumAuditCatalog.objectives;

    final measuring = items.firstWhere(
      (item) =>
          item.competency == MicroCompetencyId.measurementCalculation,
    );
    final rounding = items.firstWhere(
      (item) => item.competency == MicroCompetencyId.roundingPlace,
    );

    expect(measuring.coverage, CurriculumCoverage.digitalSupport);
    expect(measuring.note, contains('reales Messen'));
    expect(rounding.coverage, CurriculumCoverage.digitalPractice);
  });

  test('Accessibility-Einstellungen bleiben geräteweit gespeichert', () async {
    final storage = StorageService();
    await storage.setAccessibilityPreferences(
      const AccessibilityPreferences(
        largeText: true,
        highContrast: true,
        reducedMotion: true,
        readAloud: true,
        speechRate: 0.55,
      ),
    );

    final loaded = await storage.accessibilityPreferences();
    expect(loaded.largeText, isTrue);
    expect(loaded.highContrast, isTrue);
    expect(loaded.reducedMotion, isTrue);
    expect(loaded.readAloud, isTrue);
    expect(loaded.speechRate, closeTo(0.55, 0.001));
  });

  test('Beta-Export hängt keine Profil- oder Lerndaten automatisch an',
      () async {
    final controller = AppController();
    await controller.load();
    await controller.addBetaFeedback(
      BetaFeedbackEntry(
        createdAt: DateTime(2026, 9, 5, 12),
        role: BetaTesterRole.teacher,
        area: BetaFeedbackArea.explanations,
        rating: 4,
        note: 'Die zweite Hilfestufe war gut verständlich.',
      ),
    );

    final export = controller.betaFeedbackExport();

    expect(export, contains('"attachesProfileOrLearningData": false'));
    expect(export, contains('"freeTextMayContainUserEnteredPersonalData": true'));
    expect(export, isNot(contains(controller.activeProfileId)));
    expect(export, isNot(contains(controller.activeProfileName)));
    expect(export, isNot(contains('"facts"')));
    expect(export, isNot(contains('"history"')));
  });

  test('Evidence-Audit klassifiziert jede Mikro-Kompetenz Klasse 1–4', () {
    const expected = {
      GradeLevel.first: (
        total: 21,
        fullTaskOnly: 17,
        guidedOnly: 0,
        independentOnly: 0,
        targetedRecovery: 4,
      ),
      GradeLevel.second: (
        total: 26,
        fullTaskOnly: 20,
        guidedOnly: 0,
        independentOnly: 0,
        targetedRecovery: 6,
      ),
      GradeLevel.third: (
        total: 64,
        fullTaskOnly: 54,
        guidedOnly: 0,
        independentOnly: 0,
        targetedRecovery: 10,
      ),
      GradeLevel.fourth: (
        total: 66,
        fullTaskOnly: 56,
        guidedOnly: 0,
        independentOnly: 0,
        targetedRecovery: 10,
      ),
    };

    for (final grade in GradeLevel.values) {
      final audit = EvidenceCoverageAuditCatalog.audit(grade);
      final baseline = expected[grade]!;

      expect(audit.total, baseline.total, reason: grade.name);
      expect(
        audit.fullTaskOnlyCount,
        baseline.fullTaskOnly,
        reason: grade.name,
      );
      expect(
        audit.guidedStepCount,
        baseline.guidedOnly,
        reason: grade.name,
      );
      expect(
        audit.independentStepCount,
        baseline.independentOnly,
        reason: grade.name,
      );
      expect(
        audit.targetedRecoveryCount,
        baseline.targetedRecovery,
        reason: grade.name,
      );
      expect(audit.coreEvidenceComplete, isTrue, reason: grade.name);
      expect(audit.internallyConsistent, isTrue, reason: grade.name);
    }
  });

  test('Evidence-Audit prüft bekannte Step-Keys und Recovery-Konsistenz', () {
    expect(EvidenceCoverageAuditCatalog.declaredStepKeysAreKnown, isTrue);

    for (final definition in MicroCompetencyCatalog.definitions) {
      final item = EvidenceCoverageAuditCatalog.forDefinition(definition);
      expect(
        item.independentStepKeys.every(item.guidedStepKeys.contains),
        isTrue,
        reason: definition.id.name,
      );
      expect(
        item.recoveryStepKeys.every(
          StepRecoveryGenerator.supports,
        ),
        isTrue,
        reason: definition.id.name,
      );
    }
  });

  test('jede Mikro-Kompetenz ist gezielt als Gesamtaufgabe generierbar', () {
    final structured =
        StructuredExerciseGenerator(random: Random(202609051));
    final curriculum =
        CurriculumExerciseGenerator(random: Random(202609052));
    final adaptive = AdaptiveEngine(random: Random(202609053));

    for (final definition in MicroCompetencyCatalog.definitions) {
      final grade = definition.minGrade;
      final mode = definition.preferredMode;
      final maxValue = grade.recommendedRange.maxValue;

      if (mode.isUpperPrimary) {
        final exercise = curriculum.generate(
          mode: mode,
          gradeLevel: grade,
          maxValue: maxValue,
          targetCompetency: definition.id,
        );
        final tags = MicroCompetencyCatalog.tagsForTask(
          mode: mode,
          taskKey: exercise.key,
        );
        expect(
          tags.map((tag) => tag.id),
          contains(definition.id),
          reason:
              '${definition.id.name}: ${exercise.key}',
        );
        continue;
      }

      if (mode.isStructured) {
        final exercise = structured.generate(
          mode: mode,
          gradeLevel: grade,
          maxValue: maxValue,
          targetCompetency: definition.id,
        );
        final tags = MicroCompetencyCatalog.tagsForTask(
          mode: mode,
          taskKey: exercise.key,
        );
        expect(
          tags.map((tag) => tag.id),
          contains(definition.id),
          reason:
              '${definition.id.name}: ${exercise.key}',
        );
        continue;
      }

      final factMax = min(maxValue, 100);
      final facts = AdaptiveEngine.buildFactPool(maxValue: factMax);
      final fact = adaptive.selectNext(
        facts: facts,
        mode: mode,
        maxValue: factMax,
        targetCompetency: definition.id,
      );
      final tags = MicroCompetencyCatalog.tagsForTask(
        mode: mode,
        taskKey: fact.key,
        fact: fact,
      );
      expect(
        tags.map((tag) => tag.id),
        contains(definition.id),
        reason: '${definition.id.name}: ${fact.key}',
      );
    }
  });

  test('Audit zeigt nach Einmaleins-Recovery die nächste Evidence-Lücke', () {
    final multiplicationFacts = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.multiplicationFacts,
    );
    expect(
      multiplicationFacts.depth,
      EvidenceCoverageDepth.targetedRecovery,
    );
    expect(
      multiplicationFacts.independentStepKeys,
      containsAll([
        'firstPartialProduct',
        'secondPartialProduct',
        'anchorFact',
      ]),
    );
    expect(
      multiplicationFacts.recoveryStepKeys,
      containsAll([
        'firstPartialProduct',
        'secondPartialProduct',
        'anchorFact',
      ]),
    );

    final modeling = [
      MicroCompetencyId.wordProblemRelevantInformation,
      MicroCompetencyId.wordProblemOperation,
      MicroCompetencyId.wordProblemModel,
      MicroCompetencyId.wordProblemCalculation,
      MicroCompetencyId.wordProblemInterpretation,
    ];
    for (final id in modeling) {
      final item = EvidenceCoverageAuditCatalog.item(id);
      expect(item.fullTaskIndependent, isTrue, reason: id.name);
      expect(item.hasIndependentStep, isFalse, reason: id.name);
    }
  });

}
