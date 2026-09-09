import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
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
import 'package:rechenblitz/screens/privacy_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Android launcher icon supports adaptive and themed icons', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final adaptiveIcon = File(
      'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
    ).readAsStringSync();
    final legacyIcon = File(
      'android/app/src/main/res/mipmap-anydpi/ic_launcher.xml',
    );

    expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));
    expect(legacyIcon.existsSync(), isTrue);
    expect(adaptiveIcon, contains('<adaptive-icon'));
    expect(adaptiveIcon, contains('<background'));
    expect(adaptiveIcon, contains('<foreground'));
    expect(adaptiveIcon, contains('<monochrome'));
  });

  test('Android camera hardware stays optional for Play filtering', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    for (final feature in const [
      'android.hardware.camera.any',
      'android.hardware.camera',
      'android.hardware.camera.autofocus',
      'android.hardware.camera.flash',
    ]) {
      expect(
        manifest,
        contains('android:name="$feature"\n        android:required="false"'),
      );
    }
    expect(manifest, contains('tools:node="replace"'));
  });

  testWidgets('Datenschutzerklärung ist direkt in der App lesbar',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PrivacyScreen()),
    );

    expect(find.text('Datenschutzerklärung'), findsOneWidget);
    expect(find.text('Datenschutz bei Rechenblitz'), findsOneWidget);
    expect(
      find.textContaining('Lernprofile bleiben auf dem Gerät'),
      findsOneWidget,
    );
  });

  test('Web-Datenschutz und Data-Safety-Hilfe bleiben releasefähig', () {
    final webPolicy = File('docs/privacy-policy.html').readAsStringSync();
    final dataSafety =
        File('docs/google-play-data-safety.md').readAsStringSync();

    expect(
      PrivacyScreen.publicPolicyUrl,
      'https://md-kks.github.io/Rechenblitz/privacy-policy.html',
    );
    expect(webPolicy, contains('Datenschutzerklärung für Rechenblitz'));
    expect(webPolicy, contains('Kamera und QR-Codes'));
    expect(webPolicy, contains('Vorlesen über System-TTS'));
    expect(webPolicy, contains('Aufbewahrung und Löschen'));
    expect(dataSafety, contains('Werden Nutzerdaten erhoben oder geteilt?'));
    expect(dataSafety, contains('android.permission.CAMERA'));
    expect(dataSafety, contains(PrivacyScreen.publicPolicyUrl));
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
        atomicFullTask: 5,
        fullTaskOnly: 0,
        guidedOnly: 0,
        independentOnly: 0,
        targetedRecovery: 16,
      ),
      GradeLevel.second: (
        total: 26,
        atomicFullTask: 5,
        fullTaskOnly: 0,
        guidedOnly: 0,
        independentOnly: 0,
        targetedRecovery: 21,
      ),
      GradeLevel.third: (
        total: 64,
        atomicFullTask: 8,
        fullTaskOnly: 0,
        guidedOnly: 0,
        independentOnly: 0,
        targetedRecovery: 56,
      ),
      GradeLevel.fourth: (
        total: 66,
        atomicFullTask: 8,
        fullTaskOnly: 0,
        guidedOnly: 0,
        independentOnly: 0,
        targetedRecovery: 58,
      ),
    };

    for (final grade in GradeLevel.values) {
      final audit = EvidenceCoverageAuditCatalog.audit(grade);
      final baseline = expected[grade]!;

      expect(audit.total, baseline.total, reason: grade.name);
      expect(
        audit.atomicFullTaskCount,
        baseline.atomicFullTask,
        reason: grade.name,
      );
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
      expect(audit.fineGrainedGaps, isEmpty, reason: grade.name);
      expect(audit.coreEvidenceComplete, isTrue, reason: grade.name);
      expect(audit.internallyConsistent, isTrue, reason: grade.name);
    }
  });

  test('Audit dokumentiert atomare Gesamtkompetenzen ohne Fake-Steps', () {
    const sharedAtomic = <MicroCompetencyId>{
      MicroCompetencyId.countingNeighbors,
      MicroCompetencyId.additionNoBridge,
      MicroCompetencyId.subtractionNoBridge,
      MicroCompetencyId.shapeProperties,
      MicroCompetencyId.representationTranslation,
    };
    const upperPrimaryAtomic = <MicroCompetencyId>{
      ...sharedAtomic,
      MicroCompetencyId.lineRelations,
      MicroCompetencyId.circleParts,
      MicroCompetencyId.geometryBodies,
    };

    for (final grade in GradeLevel.values) {
      final audit = EvidenceCoverageAuditCatalog.audit(grade);
      final expected = grade.index >= GradeLevel.third.index
          ? upperPrimaryAtomic
          : sharedAtomic;
      final actual = audit.atomicFullTasks
          .map((item) => item.definition.id)
          .toSet();

      expect(actual, expected, reason: grade.name);
      for (final item in audit.atomicFullTasks) {
        expect(item.depth, EvidenceCoverageDepth.atomicFullTask);
        expect(item.atomicFullTask, isTrue);
        expect(item.atomicReason, isNotNull);
        expect(item.atomicReason!.trim(), isNotEmpty);
        expect(item.guidedStepKeys, isEmpty);
        expect(item.independentStepKeys, isEmpty);
        expect(item.recoveryStepKeys, isEmpty);
      }
    }
  });

  test('Audit führt Pläne und Wege bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.planDirections,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('firstRouteSegment'));
    expect(item.independentStepKeys, contains('firstRouteSegment'));
    expect(item.recoveryStepKeys, contains('firstRouteSegment'));
  });

  test('Audit führt Würfelnetze bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.cubeNetFoldability,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('cubeNetLocalFaceRelation'));
    expect(item.independentStepKeys, contains('cubeNetLocalFaceRelation'));
    expect(item.recoveryStepKeys, contains('cubeNetLocalFaceRelation'));
  });

  test('Audit führt Symmetrieachsen bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.symmetryAxes,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('candidateSymmetryAxis'));
    expect(item.independentStepKeys, contains('candidateSymmetryAxis'));
    expect(item.recoveryStepKeys, contains('candidateSymmetryAxis'));
  });

  test('Audit führt Figurenklassifikation bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.figureClassification,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('figureSideFamily'));
    expect(item.independentStepKeys, contains('figureSideFamily'));
    expect(item.recoveryStepKeys, contains('figureSideFamily'));
  });

  test('Audit führt rechte Winkel bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.rightAngle,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('angleReferenceRelation'));
    expect(item.independentStepKeys, contains('angleReferenceRelation'));
    expect(item.recoveryStepKeys, contains('angleReferenceRelation'));
  });

  test('Audit führt Maßstab bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.scale,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('scaleOperationChoice'));
    expect(item.independentStepKeys, contains('scaleOperationChoice'));
    expect(item.recoveryStepKeys, contains('scaleOperationChoice'));
  });

  test('Audit führt Zufallsexperimente bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.probabilityExperiment,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('observedFrequencyRelation'));
    expect(item.independentStepKeys, contains('observedFrequencyRelation'));
    expect(item.recoveryStepKeys, contains('observedFrequencyRelation'));
  });

  test('Audit führt römische Zahlen bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.romanNumeral,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('romanTensBlockValue'));
    expect(item.independentStepKeys, contains('romanTensBlockValue'));
    expect(item.recoveryStepKeys, contains('romanTensBlockValue'));
  });

  test('Audit führt Rauminhalt mit Würfeln bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.volumeCubes,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('volumeLayerCount'));
    expect(item.independentStepKeys, contains('volumeLayerCount'));
    expect(item.recoveryStepKeys, contains('volumeLayerCount'));
  });

  test('Audit führt Datendarstellungswahl bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.dataRepresentationChoice,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('representationPurpose'));
    expect(item.independentStepKeys, contains('representationPurpose'));
    expect(item.recoveryStepKeys, contains('representationPurpose'));
  });

  test('Audit führt Datumsrechnen bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.calendarDate,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('calendarWeekRemainder'));
    expect(item.independentStepKeys, contains('calendarWeekRemainder'));
    expect(item.recoveryStepKeys, contains('calendarWeekRemainder'));
  });

  test('Audit führt systematische Kombinatorik bis zur gezielten Recovery',
      () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.combinatoricsSystematic,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('comboFirstBranchCount'));
    expect(item.independentStepKeys, contains('comboFirstBranchCount'));
    expect(item.recoveryStepKeys, contains('comboFirstBranchCount'));
  });

  test('Audit führt Wahrscheinlichkeitsdenken bis zur gezielten Recovery',
      () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.probabilityReasoning,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('chanceCountRelation'));
    expect(item.independentStepKeys, contains('chanceCountRelation'));
    expect(item.recoveryStepKeys, contains('chanceCountRelation'));
  });

  test('Audit führt Diagrammlesen bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.dataReading,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('chartValuesRead'));
    expect(item.independentStepKeys, contains('chartValuesRead'));
    expect(item.recoveryStepKeys, contains('chartValuesRead'));
  });

  test('Audit führt Strichlistenlesen bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.tallyTableReading,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('tallyFiveBlocks'));
    expect(item.independentStepKeys, contains('tallyFiveBlocks'));
    expect(item.recoveryStepKeys, contains('tallyFiveBlocks'));
  });

  test('Audit führt Flächeninhalt bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.area,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('areaUnitSquareStructure'));
    expect(item.independentStepKeys, contains('areaUnitSquareStructure'));
    expect(item.recoveryStepKeys, contains('areaUnitSquareStructure'));
  });

  test('Audit führt Umfang bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.perimeter,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('perimeterEdges'));
    expect(item.independentStepKeys, contains('perimeterEdges'));
    expect(item.recoveryStepKeys, contains('perimeterEdges'));
  });

  test('Audit führt Zahlenfolgen-Regel bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.numberPatterns,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('sequenceStepSize'));
    expect(item.independentStepKeys, contains('sequenceStepSize'));
    expect(item.recoveryStepKeys, contains('sequenceStepSize'));
  });

  test('Audit führt Uhr-Minutenzeiger bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.clockReading,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('minuteHandMinutes'));
    expect(item.independentStepKeys, contains('minuteHandMinutes'));
    expect(item.recoveryStepKeys, contains('minuteHandMinutes'));
  });

  test('Audit führt Rundungsentscheidung bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.roundingPlace,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('roundingDecisionDigit'));
    expect(item.independentStepKeys, contains('roundingDecisionDigit'));
    expect(item.recoveryStepKeys, contains('roundingDecisionDigit'));
  });

  test('Audit führt Minuten-Sekunden-Beziehung bis zur Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.secondsConversion,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('minuteSecondRelation'));
    expect(item.independentStepKeys, contains('minuteSecondRelation'));
    expect(item.recoveryStepKeys, contains('minuteSecondRelation'));
  });

  test('Audit führt Einheitenbeziehungen bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.unitConversion,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('unitRelation'));
    expect(item.independentStepKeys, contains('unitRelation'));
    expect(item.recoveryStepKeys, contains('unitRelation'));
  });

  test('Audit führt Fehlerprüfung bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.errorChecking,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('errorPlace'));
    expect(item.independentStepKeys, contains('errorPlace'));
    expect(item.recoveryStepKeys, contains('errorPlace'));
  });

  test('Audit führt Überschlag bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.estimation,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('roundedSummands'));
    expect(item.independentStepKeys, contains('roundedSummands'));
    expect(item.recoveryStepKeys, contains('roundedSummands'));
  });

  test('Audit führt Plausibilitätsprüfung bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.plausibilityCheck,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('referenceEstimate'));
    expect(item.independentStepKeys, contains('referenceEstimate'));
    expect(item.recoveryStepKeys, contains('referenceEstimate'));
  });

  test('Audit führt Zahlwortlesen bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.numberWordReading,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('numberWordTensOnes'));
    expect(item.independentStepKeys, contains('numberWordTensOnes'));
    expect(item.recoveryStepKeys, contains('numberWordTensOnes'));
  });

  test('Audit führt Rechenbegründungen bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.reasoningJustification,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('reasoningRelationType'));
    expect(item.independentStepKeys, contains('reasoningRelationType'));
    expect(item.recoveryStepKeys, contains('reasoningRelationType'));
  });

  test('Audit führt Rechengesetze bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.arithmeticLaw,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('lawStructureChoice'));
    expect(item.independentStepKeys, contains('lawStructureChoice'));
    expect(item.recoveryStepKeys, contains('lawStructureChoice'));
  });

  test('Audit führt halbschriftliche Strategien bis zur gezielten Recovery',
      () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.mentalStrategy,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('firstMentalChunk'));
    expect(item.independentStepKeys, contains('firstMentalChunk'));
    expect(item.recoveryStepKeys, contains('firstMentalChunk'));
  });

  test('Audit führt das Ordnen großer Zahlen bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.largeNumberOrder,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('smallestOrderedNumber'));
    expect(item.independentStepKeys, contains('smallestOrderedNumber'));
    expect(item.recoveryStepKeys, contains('smallestOrderedNumber'));
  });

  test('Audit führt Strategiewahl bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.strategyChoice,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('gapToAnchor'));
    expect(item.independentStepKeys, contains('gapToAnchor'));
    expect(item.recoveryStepKeys, contains('gapToAnchor'));
  });

  test('Audit führt Stellenwertzerlegung bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.placeValueDecompose,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('placeValueContribution'));
    expect(item.independentStepKeys, contains('placeValueContribution'));
    expect(item.recoveryStepKeys, contains('placeValueContribution'));
  });

  test('Audit führt Zahlenvergleich bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.largeNumberCompare,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('decidingPlace'));
    expect(item.independentStepKeys, contains('decidingPlace'));
    expect(item.recoveryStepKeys, contains('decidingPlace'));
  });

  test('Audit führt gleich große Bruchteile bis zur gezielten Recovery',
      () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.fractionEqualParts,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('equalPartSize'));
    expect(item.independentStepKeys, contains('equalPartSize'));
    expect(item.recoveryStepKeys, contains('equalPartSize'));
  });

  test('Audit führt Zeitspannen bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.timeDuration,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('minutesToNextHour'));
    expect(item.independentStepKeys, contains('minutesToNextHour'));
    expect(item.recoveryStepKeys, contains('minutesToNextHour'));
  });

  test('Audit führt proportionalen Einheitswert bis zur gezielten Recovery',
      () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.proportionalUnit,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('unitValue'));
    expect(item.independentStepKeys, contains('unitValue'));
    expect(item.recoveryStepKeys, contains('unitValue'));
  });

  test('Audit führt Divisionsverständnis bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.divisionSharing,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('divisionTargetQuantity'));
    expect(item.independentStepKeys, contains('divisionTargetQuantity'));
    expect(item.recoveryStepKeys, contains('divisionTargetQuantity'));
  });

  test('Audit führt Geteilt-Grundaufgaben bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.divisionFacts,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('matchingMultiplicationFact'));
    expect(item.independentStepKeys, contains('matchingMultiplicationFact'));
    expect(item.recoveryStepKeys, contains('matchingMultiplicationFact'));
  });

  test('Audit führt Umkehroperationen bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.inverseRelationship,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('inverseOperationChoice'));
    expect(item.independentStepKeys, contains('inverseOperationChoice'));
    expect(item.recoveryStepKeys, contains('inverseOperationChoice'));
  });

  test('Audit führt Zahlenmauer-Rechenrichtung bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.numberRelations,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('wallOperationChoice'));
    expect(item.independentStepKeys, contains('wallOperationChoice'));
    expect(item.recoveryStepKeys, contains('wallOperationChoice'));
  });

  test('Audit führt Doppeln und Halbieren bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.doublesHalves,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('doubleHalfMeaning'));
    expect(item.independentStepKeys, contains('doubleHalfMeaning'));
    expect(item.recoveryStepKeys, contains('doubleHalfMeaning'));
  });

  test('Audit führt Längen-Rechenplan bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.measurementCalculation,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('measureOperationChoice'));
    expect(item.independentStepKeys, contains('measureOperationChoice'));
    expect(item.recoveryStepKeys, contains('measureOperationChoice'));
  });

  test('Audit führt Geld-Rechenplan bis zur gezielten Recovery', () {
    final item = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.moneyCalculation,
    );

    expect(item.depth, EvidenceCoverageDepth.targetedRecovery);
    expect(item.guidedStepKeys, contains('moneyOperationChoice'));
    expect(item.independentStepKeys, contains('moneyOperationChoice'));
    expect(item.recoveryStepKeys, contains('moneyOperationChoice'));
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

  test('Audit weist alle Sachaufgaben-Modellierungsschritte als Recovery aus',
      () {
    const modeling = {
      MicroCompetencyId.wordProblemRelevantInformation: 'storyInfo',
      MicroCompetencyId.wordProblemOperation: 'storyOperation',
      MicroCompetencyId.wordProblemModel: 'storyEquation',
      MicroCompetencyId.wordProblemCalculation: 'storyCalculation',
      MicroCompetencyId.wordProblemInterpretation: 'storyInterpretation',
    };

    for (final entry in modeling.entries) {
      final item = EvidenceCoverageAuditCatalog.item(entry.key);
      expect(
        item.depth,
        EvidenceCoverageDepth.targetedRecovery,
        reason: entry.key.name,
      );
      expect(item.independentStepKeys, contains(entry.value));
      expect(item.guidedStepKeys, contains(entry.value));
      expect(item.recoveryStepKeys, contains(entry.value));
    }

    final multiplicationFacts = EvidenceCoverageAuditCatalog.item(
      MicroCompetencyId.multiplicationFacts,
    );
    expect(
      multiplicationFacts.depth,
      EvidenceCoverageDepth.targetedRecovery,
    );
  });

}
