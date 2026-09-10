import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/guided_method.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/screens/curriculum_training_screen.dart';
import 'package:rechenblitz/screens/structured_training_screen.dart';
import 'package:rechenblitz/screens/training_screen.dart';
import 'package:rechenblitz/widgets/guided_method_panel.dart';
import 'package:rechenblitz/widgets/learning_visual_aid.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Schulmethode bleibt bei geführtem Minus verbindlich', () {
    const preferences = MethodPreferences(
      subtraction: SubtractionStrategy.bridgeToTen,
      selectionPreference: MethodSelectionPreference.schoolMethod,
    );
    final fact = MathFact(
      a: 13,
      b: 5,
      operation: MathOperation.minus,
    );

    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.minus,
      taskKey: fact.key,
      expected: 8,
      preferences: preferences,
      fact: fact,
    );

    expect(guide.methodKey, 'subtraction:bridgeToTen');
    expect(guide.methodLabel, 'Erst zum Zehner');
    expect(guide.steps.length, greaterThanOrEqualTo(3));
    expect(guide.steps.where((step) => step.isInteractive), isNotEmpty);
  });

  test('Minus von vollem Zehner vermeidet künstlichen Null-Schritt', () {
    const preferences = MethodPreferences(
      subtraction: SubtractionStrategy.bridgeToTen,
      selectionPreference: MethodSelectionPreference.schoolMethod,
    );
    final fact = MathFact(
      a: 10,
      b: 4,
      operation: MathOperation.minus,
    );

    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.minus,
      taskKey: fact.key,
      expected: 6,
      preferences: preferences,
      fact: fact,
    );

    expect(guide.methodKey, 'subtraction:fromFullTen');
    expect(guide.methodLabel, 'Direkt vom Zehner');
    expect(guide.nudge, contains('schon ein voller Zehner'));
    expect(guide.nudge, isNot(contains('unter 10')));
    expect(guide.steps.first.title, 'Voller Zehner ist schon da');
    expect(
      guide.steps.where((step) => step.evidenceKey == 'bridgeAmount'),
      isEmpty,
    );
  });

  test('Minus ohne Übergang bekommt eine passende eigene Hilfe', () {
    const preferences = MethodPreferences(
      subtraction: SubtractionStrategy.bridgeToTen,
      selectionPreference: MethodSelectionPreference.schoolMethod,
    );
    final fact = MathFact(
      a: 47,
      b: 3,
      operation: MathOperation.minus,
    );

    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.minus,
      taskKey: fact.key,
      expected: 44,
      preferences: preferences,
      fact: fact,
    );

    expect(guide.methodKey, 'subtraction:direct');
    expect(guide.methodLabel, 'Direkt abziehen');
    expect(guide.nudge, contains('keinen Zehner überschreiten'));
    expect(guide.steps.last.instruction, '47 − 3 = 44.');
  });







  test('Fehlerprüfung beobachtet zuerst die falsche Stellenwertstelle', () {
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.writtenAddSub,
      taskKey: 'process:error:add:place:10:462:337:809',
      expected: 1,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.errorChecking,
    );
    final evidence =
        guide.steps.where((step) => step.recordsIntermediateEvidence).single;

    expect(guide.methodKey, 'process:errorChecking');
    expect(evidence.evidenceKey, 'errorPlace');
    expect(evidence.evidenceCompetency, MicroCompetencyId.errorChecking);
    expect(evidence.evidenceWeight, 0.40);
    expect(evidence.choices[evidence.correctChoice!], 'Zehnerstelle');
    expect(evidence.instruction, isNot(contains('Zehnerstelle')));
    expect(guide.steps[1].instruction, contains('Zehnerstelle'));

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.writtenAddSub,
      taskKey: 'process:error:add:place:10:462:337:809',
      expected: 1,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.errorChecking,
    );
    expect(independent.map((step) => step.evidenceKey), ['errorPlace']);
  });

  test('Plausibilitätsprüfung beobachtet zuerst den Referenz-Überschlag', () {
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.estimation,
      taskKey: 'process:plausibility:462:337:1200:100',
      expected: 1,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.plausibilityCheck,
    );
    final evidence =
        guide.steps.where((step) => step.recordsIntermediateEvidence).single;

    expect(guide.methodKey, 'process:plausibility');
    expect(evidence.evidenceKey, 'referenceEstimate');
    expect(
      evidence.evidenceCompetency,
      MicroCompetencyId.plausibilityCheck,
    );
    expect(evidence.evidenceWeight, 0.40);
    expect(evidence.question, contains('462 + 337'));
    expect(evidence.question, contains('Hunderter'));
    expect(evidence.choices[evidence.correctChoice!], '800');
    expect(evidence.question, isNot(contains('1200')));

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.estimation,
      taskKey: 'process:plausibility:462:337:1200:100',
      expected: 1,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.plausibilityCheck,
    );
    expect(
      independent.map((step) => step.evidenceKey),
      ['referenceEstimate'],
    );
  });

  test('Zahlwort-Hilfe beobachtet zuerst die deutsche Einer-Zehner-Reihenfolge',
      () {
    for (final key in [
      'large:word:read:347',
      'large:word:write:347',
    ]) {
      final guide = GuidedMethodFactory.forTask(
        mode: TrainingMode.largeNumbers,
        taskKey: key,
        expected: 0,
        preferences: const MethodPreferences(),
        targetCompetency: MicroCompetencyId.numberWordReading,
      );
      final evidence =
          guide.steps.where((step) => step.recordsIntermediateEvidence).single;

      expect(guide.methodKey, 'largeNumbers:numberWord');
      expect(evidence.evidenceKey, 'numberWordTensOnes');
      expect(
        evidence.evidenceCompetency,
        MicroCompetencyId.numberWordReading,
      );
      expect(evidence.evidenceWeight, 0.40);
      expect(evidence.question, contains('siebenundvierzig'));
      expect(
        evidence.choices[evidence.correctChoice!],
        '4 Zehner und 7 Einer',
      );
      expect(evidence.instruction, isNot(contains('347')));

      final independent =
          GuidedMethodFactory.independentWrittenStepsForTask(
        mode: TrainingMode.largeNumbers,
        taskKey: key,
        expected: 0,
        preferences: const MethodPreferences(),
        targetCompetency: MicroCompetencyId.numberWordReading,
      );
      expect(
        independent.map((step) => step.evidenceKey),
        ['numberWordTensOnes'],
      );
    }
  });


  test('Pfeilroute beobachtet zuerst den ersten Wegabschnitt', () {
    const key = 'plan:route:right:3:up:2';
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.plansAndOrientation,
      taskKey: key,
      expected: 0,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.planDirections,
    );
    final evidence =
        guide.steps.where((step) => step.recordsIntermediateEvidence).single;

    expect(guide.methodKey, 'plan-route:first-segment');
    expect(evidence.evidenceKey, 'firstRouteSegment');
    expect(evidence.evidenceCompetency, MicroCompetencyId.planDirections);
    expect(evidence.evidenceWeight, 0.40);
    expect(
      evidence.choices[evidence.correctChoice!],
      '3 Felder nach rechts',
    );
    expect(evidence.instruction, contains('zweiten Block lässt du zunächst weg'));
    expect(evidence.choices.join(' '), isNot(contains('2 Felder nach oben')));

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.plansAndOrientation,
      taskKey: key,
      expected: 0,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.planDirections,
    );
    expect(
      independent.map((step) => step.evidenceKey),
      ['firstRouteSegment'],
    );

    final legacyPath =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.plansAndOrientation,
      taskKey: 'plan:path:6:4',
      expected: 10,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.planDirections,
    );
    expect(legacyPath, isEmpty);
  });

  test('Maßstab beobachtet zuerst die passende Operation', () {
    const key = 'plan:scale:100:6';
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.plansAndOrientation,
      taskKey: key,
      expected: 600,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.scale,
    );
    final evidence =
        guide.steps.where((step) => step.recordsIntermediateEvidence).single;

    expect(guide.methodKey, 'scale:operation-choice');
    expect(evidence.evidenceKey, 'scaleOperationChoice');
    expect(evidence.evidenceCompetency, MicroCompetencyId.scale);
    expect(evidence.evidenceWeight, 0.40);
    expect(
      evidence.choices[evidence.correctChoice!],
      'Planlänge × Meter pro Zentimeter',
    );
    expect(evidence.choices.join(' '), isNot(contains('600')));
    expect(evidence.instruction, contains('1 cm'));
    expect(evidence.instruction, contains('100 m'));
    expect(evidence.instruction, contains('6 cm'));

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.plansAndOrientation,
      taskKey: key,
      expected: 600,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.scale,
    );
    expect(
      independent.map((step) => step.evidenceKey),
      ['scaleOperationChoice'],
    );

    final pathIndependent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.plansAndOrientation,
      taskKey: 'plan:path:6:4',
      expected: 10,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.scale,
    );
    expect(pathIndependent, isEmpty);
  });

  test('Winkel beobachtet zuerst die Relation zur rechten Referenz', () {
    const key = 'geomrel:angle:smaller:reference:third';
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.geometryRelations,
      taskKey: key,
      expected: 1,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.rightAngle,
    );
    final evidence =
        guide.steps.where((step) => step.recordsIntermediateEvidence).single;

    expect(guide.methodKey, 'geometry:right-angle-reference');
    expect(evidence.evidenceKey, 'angleReferenceRelation');
    expect(evidence.evidenceCompetency, MicroCompetencyId.rightAngle);
    expect(evidence.evidenceWeight, 0.40);
    expect(
      evidence.choices[evidence.correctChoice!],
      'kleiner als ein rechter Winkel',
    );
    expect(evidence.choices.join(' '), isNot(contains('spitzer Winkel')));

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.geometryRelations,
      taskKey: key,
      expected: 1,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.rightAngle,
    );
    expect(
      independent.map((step) => step.evidenceKey),
      ['angleReferenceRelation'],
    );

    final otherGeometry =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.geometryRelations,
      taskKey: 'geomrel:lines:parallel:third',
      expected: 0,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.rightAngle,
    );
    expect(otherGeometry, isEmpty);
  });

  test('Zufallsexperiment beobachtet zuerst die Häufigkeitsrelation', () {
    const key = 'prob:experiment:compare:30:18:12';
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.probability,
      taskKey: key,
      expected: 0,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.probabilityExperiment,
    );
    final evidence =
        guide.steps.where((step) => step.recordsIntermediateEvidence).single;

    expect(
      guide.methodKey,
      'probability:observed-frequency-relation',
    );
    expect(evidence.evidenceKey, 'observedFrequencyRelation');
    expect(
      evidence.evidenceCompetency,
      MicroCompetencyId.probabilityExperiment,
    );
    expect(evidence.evidenceWeight, 0.40);
    expect(evidence.choices[evidence.correctChoice!], '18 > 12');
    expect(evidence.choices.join(' '), isNot(contains('häufiger')));

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.probability,
      taskKey: key,
      expected: 0,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.probabilityExperiment,
    );
    expect(
      independent.map((step) => step.evidenceKey),
      ['observedFrequencyRelation'],
    );

    final relativeIndependent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.probability,
      taskKey: 'prob:experiment:relative:30:18',
      expected: 60,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.probabilityExperiment,
    );
    expect(relativeIndependent, isEmpty);
  });

  test('Römische Zahlen beobachten zuerst den Zehnerblock', () {
    const key = 'roman:read:47';
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.romanNumerals,
      taskKey: key,
      expected: 47,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.romanNumeral,
    );
    final evidence =
        guide.steps.where((step) => step.recordsIntermediateEvidence).single;

    expect(guide.methodKey, 'roman:tens-block');
    expect(evidence.evidenceKey, 'romanTensBlockValue');
    expect(evidence.evidenceCompetency, MicroCompetencyId.romanNumeral);
    expect(evidence.evidenceWeight, 0.40);
    expect(evidence.question, contains('XL'));
    expect(evidence.choices[evidence.correctChoice!], '40');
    expect(evidence.choices, isNot(contains('47')));
    expect(evidence.instruction, contains('XLVII'));

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.romanNumerals,
      taskKey: key,
      expected: 47,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.romanNumeral,
    );
    expect(
      independent.map((step) => step.evidenceKey),
      ['romanTensBlockValue'],
    );

    final writeIndependent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.romanNumerals,
      taskKey: 'roman:write:47',
      expected: 0,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.romanNumeral,
    );
    expect(writeIndependent, isEmpty);
  });

  test('Würfelnetz beobachtet zuerst die lokale Lage von A und C', () {
    const oppositeKey =
        'body:cube-net:fold:yes:local:opposite:0,0;1,0;2,0;1,1;1,2;1,3';
    const adjacentKey =
        'body:cube-net:fold:no:local:adjacent:0,0;1,0;1,1;2,1;1,2;1,3';

    final oppositeGuide = GuidedMethodFactory.forTask(
      mode: TrainingMode.geometryBodies,
      taskKey: oppositeKey,
      expected: 0,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.cubeNetFoldability,
    );
    final oppositeEvidence = oppositeGuide.steps
        .where((step) => step.recordsIntermediateEvidence)
        .single;

    expect(oppositeGuide.methodKey, 'cube-net:local-face-relation');
    expect(oppositeEvidence.evidenceKey, 'cubeNetLocalFaceRelation');
    expect(
      oppositeEvidence.evidenceCompetency,
      MicroCompetencyId.cubeNetFoldability,
    );
    expect(oppositeEvidence.evidenceWeight, 0.40);
    expect(
      oppositeEvidence.choices[oppositeEvidence.correctChoice!],
      'A und C liegen sich gegenüber',
    );
    expect(oppositeEvidence.instruction, contains('drei übrigen Quadrate'));
    expect(
      oppositeEvidence.choices,
      isNot(contains('Ja, es lässt sich falten')),
    );

    final adjacentGuide = GuidedMethodFactory.forTask(
      mode: TrainingMode.geometryBodies,
      taskKey: adjacentKey,
      expected: 1,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.cubeNetFoldability,
    );
    final adjacentEvidence = adjacentGuide.steps
        .where((step) => step.recordsIntermediateEvidence)
        .single;
    expect(
      adjacentEvidence.choices[adjacentEvidence.correctChoice!],
      'A und C sind Nachbarflächen',
    );

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.geometryBodies,
      taskKey: oppositeKey,
      expected: 0,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.cubeNetFoldability,
    );
    expect(
      independent.map((step) => step.evidenceKey),
      ['cubeNetLocalFaceRelation'],
    );
  });

  test('Symmetrie beobachtet zuerst eine einzelne Kandidatenachse', () {
    const validKey = 'symmetry:target:1:0';
    const invalidKey = 'symmetry:target:1:1';

    final validGuide = GuidedMethodFactory.forTask(
      mode: TrainingMode.symmetry,
      taskKey: validKey,
      expected: 2,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.symmetryAxes,
    );
    final validEvidence = validGuide.steps
        .where((step) => step.recordsIntermediateEvidence)
        .single;

    expect(validGuide.methodKey, 'symmetry:candidate-axis');
    expect(validEvidence.evidenceKey, 'candidateSymmetryAxis');
    expect(
      validEvidence.evidenceCompetency,
      MicroCompetencyId.symmetryAxes,
    );
    expect(validEvidence.evidenceWeight, 0.40);
    expect(
      validEvidence.choices[validEvidence.correctChoice!],
      'Ja, sie teilt die Figur spiegelgleich',
    );
    expect(validEvidence.instruction, contains('Mittellinie'));
    expect(validEvidence.choices, isNot(contains('2')));

    final invalidGuide = GuidedMethodFactory.forTask(
      mode: TrainingMode.symmetry,
      taskKey: invalidKey,
      expected: 2,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.symmetryAxes,
    );
    final invalidEvidence = invalidGuide.steps
        .where((step) => step.recordsIntermediateEvidence)
        .single;
    expect(
      invalidEvidence.choices[invalidEvidence.correctChoice!],
      'Nein, sie ist keine Symmetrieachse',
    );
    expect(invalidEvidence.instruction, contains('Diagonale'));

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.symmetry,
      taskKey: validKey,
      expected: 2,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.symmetryAxes,
    );
    expect(
      independent.map((step) => step.evidenceKey),
      ['candidateSymmetryAxis'],
    );
  });

  test('Figurenklassifikation beobachtet zuerst Dreieck oder Viereck', () {
    const squareKey = 'geomrel:figure:0:third';
    const triangleKey = 'geomrel:figure:2:third';

    final squareGuide = GuidedMethodFactory.forTask(
      mode: TrainingMode.geometryRelations,
      taskKey: squareKey,
      expected: 0,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.figureClassification,
    );
    final squareEvidence = squareGuide.steps
        .where((step) => step.recordsIntermediateEvidence)
        .single;

    expect(squareGuide.methodKey, 'geometry:figure-family');
    expect(squareEvidence.evidenceKey, 'figureSideFamily');
    expect(
      squareEvidence.evidenceCompetency,
      MicroCompetencyId.figureClassification,
    );
    expect(squareEvidence.evidenceWeight, 0.40);
    expect(
      squareEvidence.choices[squareEvidence.correctChoice!],
      'Viereck',
    );
    expect(squareEvidence.choices, isNot(contains('Quadrat')));

    final triangleGuide = GuidedMethodFactory.forTask(
      mode: TrainingMode.geometryRelations,
      taskKey: triangleKey,
      expected: 2,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.figureClassification,
    );
    final triangleEvidence = triangleGuide.steps
        .where((step) => step.recordsIntermediateEvidence)
        .single;
    expect(
      triangleEvidence.choices[triangleEvidence.correctChoice!],
      'Dreieck',
    );

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.geometryRelations,
      taskKey: squareKey,
      expected: 0,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.figureClassification,
    );
    expect(
      independent.map((step) => step.evidenceKey),
      ['figureSideFamily'],
    );
  });

  test('Rauminhalt beobachtet zuerst eine einzelne Würfelschicht', () {
    const key = 'volume:3:4:2';
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.volumeCubes,
      taskKey: key,
      expected: 24,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.volumeCubes,
    );
    final evidence =
        guide.steps.where((step) => step.recordsIntermediateEvidence).single;

    expect(guide.methodKey, 'volume:single-layer');
    expect(evidence.evidenceKey, 'volumeLayerCount');
    expect(evidence.evidenceCompetency, MicroCompetencyId.volumeCubes);
    expect(evidence.evidenceWeight, 0.40);
    expect(evidence.choices[evidence.correctChoice!], '12');
    expect(evidence.choices, isNot(contains('24')));
    expect(evidence.instruction, contains('3 Würfel lang'));
    expect(evidence.instruction, contains('4 Würfel breit'));

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.volumeCubes,
      taskKey: key,
      expected: 24,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.volumeCubes,
    );
    expect(
      independent.map((step) => step.evidenceKey),
      ['volumeLayerCount'],
    );

    final singleLayerIndependent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.volumeCubes,
      taskKey: 'volume:3:4:1',
      expected: 12,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.volumeCubes,
    );
    expect(singleLayerIndependent, isEmpty);
  });

  test('Datendarstellungswahl beobachtet zuerst den Zweck', () {
    const key = 'data:representation:2';
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.dataCharts,
      taskKey: key,
      expected: 2,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.dataRepresentationChoice,
    );
    final evidence =
        guide.steps.where((step) => step.recordsIntermediateEvidence).single;

    expect(guide.methodKey, 'data:representation-purpose');
    expect(evidence.evidenceKey, 'representationPurpose');
    expect(
      evidence.evidenceCompetency,
      MicroCompetencyId.dataRepresentationChoice,
    );
    expect(evidence.evidenceWeight, 0.40);
    expect(
      evidence.choices[evidence.correctChoice!],
      'Größen auf einen Blick vergleichen',
    );
    expect(
      evidence.choices.join(' '),
      isNot(contains('Balkendiagramm')),
    );

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.dataCharts,
      taskKey: key,
      expected: 2,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.dataRepresentationChoice,
    );
    expect(
      independent.map((step) => step.evidenceKey),
      ['representationPurpose'],
    );

    final dataReadingIndependent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.dataCharts,
      taskKey: key,
      expected: 2,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.dataReading,
    );
    expect(dataReadingIndependent, isEmpty);
  });

  test('Kalender beobachtet zuerst Wochen und Resttage', () {
    const key = 'calendar:add:April:12:10';
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.timeDurations,
      taskKey: key,
      expected: 2,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.calendarDate,
    );
    final evidence =
        guide.steps.where((step) => step.recordsIntermediateEvidence).single;

    expect(guide.methodKey, 'calendar:week-remainder');
    expect(evidence.evidenceKey, 'calendarWeekRemainder');
    expect(evidence.evidenceCompetency, MicroCompetencyId.calendarDate);
    expect(evidence.evidenceWeight, 0.40);
    expect(
      evidence.choices[evidence.correctChoice!],
      '1 Woche + 3 Tage',
    );
    expect(evidence.instruction, isNot(contains('22. April')));

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.timeDurations,
      taskKey: key,
      expected: 2,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.calendarDate,
    );
    expect(
      independent.map((step) => step.evidenceKey),
      ['calendarWeekRemainder'],
    );

    final durationIndependent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.timeDurations,
      taskKey: key,
      expected: 2,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.timeDuration,
    );
    expect(durationIndependent, isEmpty);
  });

  test('Kombinatorik beobachtet zuerst einen vollständigen Ast', () {
    const key = 'combo:clothes:3:4:2';
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.combinatorics,
      taskKey: key,
      expected: 24,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.combinatoricsSystematic,
    );
    final evidence =
        guide.steps.where((step) => step.recordsIntermediateEvidence).single;

    expect(guide.methodKey, 'combinatorics:first-branch');
    expect(evidence.evidenceKey, 'comboFirstBranchCount');
    expect(
      evidence.evidenceCompetency,
      MicroCompetencyId.combinatoricsSystematic,
    );
    expect(evidence.evidenceWeight, 0.40);
    expect(evidence.choices[evidence.correctChoice!], '8');
    expect(evidence.instruction, contains('T-Shirt'));
    expect(evidence.instruction, contains('Hose'));
    expect(evidence.instruction, contains('Mütze'));
    expect(evidence.instruction, isNot(contains('24')));

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.combinatorics,
      taskKey: key,
      expected: 24,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.combinatoricsSystematic,
    );
    expect(
      independent.map((step) => step.evidenceKey),
      ['comboFirstBranchCount'],
    );
  });

  test('Wahrscheinlichkeitsvergleich beobachtet zuerst die Zahlenrelation',
      () {
    const key = 'prob:bag:kugeln:7:3';
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.probability,
      taskKey: key,
      expected: 0,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.probabilityReasoning,
    );
    final evidence =
        guide.steps.where((step) => step.recordsIntermediateEvidence).single;

    expect(guide.methodKey, 'probability:count-relation');
    expect(evidence.evidenceKey, 'chanceCountRelation');
    expect(
      evidence.evidenceCompetency,
      MicroCompetencyId.probabilityReasoning,
    );
    expect(evidence.evidenceWeight, 0.40);
    expect(evidence.choices[evidence.correctChoice!], '7 > 3');
    expect(
      evidence.choices[evidence.correctChoice!],
      isNot(contains('wahrscheinlicher')),
    );

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.probability,
      taskKey: key,
      expected: 0,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.probabilityReasoning,
    );
    expect(
      independent.map((step) => step.evidenceKey),
      ['chanceCountRelation'],
    );

    final experimentIndependent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.probability,
      taskKey: 'prob:experiment:compare:20:12:8',
      expected: 0,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.probabilityReasoning,
    );
    expect(experimentIndependent, isEmpty);
  });

  test('Diagrammlesen beobachtet zuerst die vier Balkenwerte', () {
    const key = 'data:sum:4-7-9-3';
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.dataCharts,
      taskKey: key,
      expected: 23,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.dataReading,
    );
    final evidence =
        guide.steps.where((step) => step.recordsIntermediateEvidence).single;

    expect(guide.methodKey, 'data:read-chart-values');
    expect(evidence.evidenceKey, 'chartValuesRead');
    expect(evidence.evidenceCompetency, MicroCompetencyId.dataReading);
    expect(evidence.evidenceWeight, 0.40);
    expect(
      evidence.choices[evidence.correctChoice!],
      'Rot 4 · Blau 7 · Grün 9 · Gelb 3',
    );
    expect(evidence.instruction, contains('vier Balken'));
    expect(evidence.instruction, isNot(contains('23')));

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.dataCharts,
      taskKey: key,
      expected: 23,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.dataReading,
    );
    expect(
      independent.map((step) => step.evidenceKey),
      ['chartValuesRead'],
    );

    final tallyIndependent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.dataCharts,
      taskKey: key,
      expected: 23,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.tallyTableReading,
    );
    expect(tallyIndependent, isEmpty);
  });

  test('Strichliste beobachtet zuerst vollständige Fünferblöcke', () {
    const key = 'data:tally:17';
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.dataCharts,
      taskKey: key,
      expected: 17,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.tallyTableReading,
    );
    final evidence =
        guide.steps.where((step) => step.recordsIntermediateEvidence).single;

    expect(guide.methodKey, 'data:tally-five-blocks');
    expect(evidence.evidenceKey, 'tallyFiveBlocks');
    expect(
      evidence.evidenceCompetency,
      MicroCompetencyId.tallyTableReading,
    );
    expect(evidence.evidenceWeight, 0.40);
    expect(evidence.choices[evidence.correctChoice!], '3');
    expect(evidence.instruction, contains('Fünferblöcke'));
    expect(evidence.instruction, isNot(contains('17')));

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.dataCharts,
      taskKey: key,
      expected: 17,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.tallyTableReading,
    );
    expect(
      independent.map((step) => step.evidenceKey),
      ['tallyFiveBlocks'],
    );

    final dataReading =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.dataCharts,
      taskKey: key,
      expected: 17,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.dataReading,
    );
    expect(dataReading, isEmpty);
  });

  test('Fläche modelliert zuerst Einheitsquadrate als Zeilen mal Spalten', () {
    const key = 'rect:area:beet:8:5';
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.perimeterArea,
      taskKey: key,
      expected: 40,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.area,
    );
    final evidence =
        guide.steps.where((step) => step.recordsIntermediateEvidence).single;

    expect(guide.methodKey, 'geometry:area');
    expect(evidence.evidenceKey, 'areaUnitSquareStructure');
    expect(evidence.evidenceCompetency, MicroCompetencyId.area);
    expect(evidence.evidenceWeight, 0.40);
    expect(evidence.choices[evidence.correctChoice!], '8 × 5');
    expect(evidence.instruction, contains('1-cm²-Quadraten'));
    expect(evidence.instruction, isNot(contains('40')));

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.perimeterArea,
      taskKey: key,
      expected: 40,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.area,
    );
    expect(
      independent.map((step) => step.evidenceKey),
      ['areaUnitSquareStructure'],
    );
  });

  test('Umfang beobachtet zuerst die vier Randstrecken', () {
    const key = 'rect:perimeter:beet:8:5';
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.perimeterArea,
      taskKey: key,
      expected: 26,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.perimeter,
    );
    final evidence =
        guide.steps.where((step) => step.recordsIntermediateEvidence).single;

    expect(guide.methodKey, 'geometry:perimeter');
    expect(evidence.evidenceKey, 'perimeterEdges');
    expect(evidence.evidenceCompetency, MicroCompetencyId.perimeter);
    expect(evidence.evidenceWeight, 0.40);
    expect(
      evidence.choices[evidence.correctChoice!],
      '8 cm + 5 cm + 8 cm + 5 cm',
    );
    expect(evidence.instruction, isNot(contains('26')));

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.perimeterArea,
      taskKey: key,
      expected: 26,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.perimeter,
    );
    expect(independent.map((step) => step.evidenceKey), ['perimeterEdges']);

    final areaIndependent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.perimeterArea,
      taskKey: 'rect:area:beet:8:5',
      expected: 40,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.area,
    );
    expect(
      areaIndependent.map((step) => step.evidenceKey),
      ['areaUnitSquareStructure'],
    );
  });

  test('Überschlag beobachtet zuerst die beiden gerundeten Summanden', () {
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.estimation,
      taskKey: 'estimate:672:245:100',
      expected: 900,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.estimation,
    );
    final evidence =
        guide.steps.where((step) => step.recordsIntermediateEvidence).single;

    expect(guide.methodKey, 'estimation:roundedSummands');
    expect(evidence.evidenceKey, 'roundedSummands');
    expect(evidence.evidenceCompetency, MicroCompetencyId.estimation);
    expect(evidence.evidenceWeight, 0.40);
    expect(evidence.choices[evidence.correctChoice!], '700 und 200');
    expect(evidence.question, contains('672'));
    expect(evidence.question, contains('245'));
    expect(evidence.instruction, isNot(contains('900')));

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.estimation,
      taskKey: 'estimate:672:245:100',
      expected: 900,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.estimation,
    );
    expect(independent.map((step) => step.evidenceKey), ['roundedSummands']);
  });




  test('Rechenbegründungen beobachten zuerst die Art der Beziehung', () {
    const cases = [
      (
        key: 'process:reasoning:compensate:27:35:2',
        correct: 'ein Summand kleiner, der andere gleich viel größer',
      ),
      (
        key: 'process:reasoning:commute:6:8',
        correct: 'gleiche Faktoren, nur vertauscht',
      ),
      (
        key: 'process:reasoning:distribute:7:38:40:2',
        correct: 'ein Faktor wird auf zwei Teile angewendet',
      ),
    ];

    for (final item in cases) {
      final guide = GuidedMethodFactory.forTask(
        mode: TrainingMode.arithmeticLaws,
        taskKey: item.key,
        expected: 0,
        preferences: const MethodPreferences(),
        targetCompetency: MicroCompetencyId.reasoningJustification,
      );
      final evidence =
          guide.steps.where((step) => step.recordsIntermediateEvidence).single;

      expect(guide.methodKey, 'reasoning:relation');
      expect(evidence.evidenceKey, 'reasoningRelationType');
      expect(
        evidence.evidenceCompetency,
        MicroCompetencyId.reasoningJustification,
      );
      expect(evidence.evidenceWeight, 0.40);
      expect(evidence.choices[evidence.correctChoice!], item.correct);

      final independent =
          GuidedMethodFactory.independentWrittenStepsForTask(
        mode: TrainingMode.arithmeticLaws,
        taskKey: item.key,
        expected: 0,
        preferences: const MethodPreferences(),
        targetCompetency: MicroCompetencyId.reasoningJustification,
      );
      expect(
        independent.map((step) => step.evidenceKey),
        ['reasoningRelationType'],
      );
    }
  });

  test('Rechengesetze beobachten zuerst die verwendete Rechenidee', () {
    const cases = [
      (
        key: 'law:distribute:6:47',
        correct: 'mit einer glatten Zahl zerlegen und verteilen',
      ),
      (
        key: 'law:associate:23:46:77',
        correct: 'zwei passende Summanden zuerst zusammenfassen',
      ),
      (
        key: 'law:commute:6:14',
        correct: 'Faktoren vertauschen',
      ),
    ];

    for (final item in cases) {
      final guide = GuidedMethodFactory.forTask(
        mode: TrainingMode.arithmeticLaws,
        taskKey: item.key,
        expected: 0,
        preferences: const MethodPreferences(),
        targetCompetency: MicroCompetencyId.arithmeticLaw,
      );
      final evidence =
          guide.steps.where((step) => step.recordsIntermediateEvidence).single;

      expect(guide.methodKey, 'arithmeticLaws:structure');
      expect(evidence.evidenceKey, 'lawStructureChoice');
      expect(
        evidence.evidenceCompetency,
        MicroCompetencyId.arithmeticLaw,
      );
      expect(evidence.evidenceWeight, 0.40);
      expect(evidence.choices[evidence.correctChoice!], item.correct);

      final independent =
          GuidedMethodFactory.independentWrittenStepsForTask(
        mode: TrainingMode.arithmeticLaws,
        taskKey: item.key,
        expected: 0,
        preferences: const MethodPreferences(),
        targetCompetency: MicroCompetencyId.arithmeticLaw,
      );
      expect(
        independent.map((step) => step.evidenceKey),
        ['lawStructureChoice'],
      );
    }
  });

  test('Halbschriftliches Rechnen beobachtet zuerst den größten Block', () {
    for (final item in [
      (key: 'mental:+:672:45', expected: 717, chunk: '40'),
      (key: 'mental:-:672:45', expected: 627, chunk: '40'),
      (key: 'mental:+:1200:345', expected: 1545, chunk: '300'),
    ]) {
      final guide = GuidedMethodFactory.forTask(
        mode: TrainingMode.mentalStrategies,
        taskKey: item.key,
        expected: item.expected,
        preferences: const MethodPreferences(),
        targetCompetency: MicroCompetencyId.mentalStrategy,
      );
      final evidence =
          guide.steps.where((step) => step.recordsIntermediateEvidence).single;

      expect(guide.methodKey, 'mental:placeChunks');
      expect(evidence.evidenceKey, 'firstMentalChunk');
      expect(
        evidence.evidenceCompetency,
        MicroCompetencyId.mentalStrategy,
      );
      expect(evidence.evidenceWeight, 0.40);
      expect(evidence.choices[evidence.correctChoice!], item.chunk);
      expect(
        evidence.instruction,
        isNot(contains(item.expected.toString())),
      );

      final independent =
          GuidedMethodFactory.independentWrittenStepsForTask(
        mode: TrainingMode.mentalStrategies,
        taskKey: item.key,
        expected: item.expected,
        preferences: const MethodPreferences(),
        targetCompetency: MicroCompetencyId.mentalStrategy,
      );
      expect(independent.map((step) => step.evidenceKey), ['firstMentalChunk']);
    }
  });

  test('Große Zahlen ordnen beobachtet zuerst die kleinste Zahl', () {
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.largeNumbers,
      taskKey: 'large:order:418-481-814',
      expected: 0,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.largeNumberOrder,
    );
    final evidence =
        guide.steps.where((step) => step.recordsIntermediateEvidence).single;

    expect(guide.methodKey, 'largeNumbers:order');
    expect(evidence.evidenceKey, 'smallestOrderedNumber');
    expect(
      evidence.evidenceCompetency,
      MicroCompetencyId.largeNumberOrder,
    );
    expect(evidence.evidenceWeight, 0.40);
    expect(evidence.choices.toSet(), {'418', '481', '814'});
    expect(evidence.choices[evidence.correctChoice!], '418');

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.largeNumbers,
      taskKey: 'large:order:418-481-814',
      expected: 0,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.largeNumberOrder,
    );
    expect(
      independent.map((step) => step.evidenceKey),
      ['smallestOrderedNumber'],
    );
  });

  test('Strategiewahl beobachtet zuerst die Ergänzung zur glatten Zielzahl',
      () {
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.mentalStrategies,
      taskKey: 'process:strategy:Hunderter:672:45:700',
      expected: 717,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.strategyChoice,
    );
    final evidence =
        guide.steps.where((step) => step.recordsIntermediateEvidence).single;

    expect(guide.methodKey, 'process:strategyChoice');
    expect(evidence.evidenceKey, 'gapToAnchor');
    expect(evidence.evidenceCompetency, MicroCompetencyId.strategyChoice);
    expect(evidence.evidenceWeight, 0.40);
    expect(evidence.question, contains('672'));
    expect(evidence.question, contains('700'));
    expect(evidence.choices[evidence.correctChoice!], '28');
    expect(evidence.instruction, isNot(contains('28')));
    expect(guide.steps[1].instruction, contains('17'));

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.mentalStrategies,
      taskKey: 'process:strategy:Hunderter:672:45:700',
      expected: 717,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.strategyChoice,
    );
    expect(independent.map((step) => step.evidenceKey), ['gapToAnchor']);
  });

  test('Stellenwertzerlegung beobachtet zuerst den Wert einer Ziffer', () {
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.largeNumbers,
      taskKey: 'large:decompose:724:100',
      expected: 724,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.placeValueDecompose,
    );
    final evidence =
        guide.steps.where((step) => step.recordsIntermediateEvidence).single;

    expect(guide.methodKey, 'largeNumbers:decompose');
    expect(evidence.evidenceKey, 'placeValueContribution');
    expect(
      evidence.evidenceCompetency,
      MicroCompetencyId.placeValueDecompose,
    );
    expect(evidence.evidenceWeight, 0.40);
    expect(evidence.question, contains('Ziffer 7'));
    expect(evidence.question, contains('Hunderterstelle'));
    expect(evidence.choices[evidence.correctChoice!], '700');
    expect(evidence.instruction, isNot(contains('700')));

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.largeNumbers,
      taskKey: 'large:decompose:724:100',
      expected: 724,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.placeValueDecompose,
    );
    expect(
      independent.map((step) => step.evidenceKey),
      ['placeValueContribution'],
    );
  });

  test('Normale Stellenwertzerlegung bleibt ohne Pflicht-Zwischenschritt', () {
    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.largeNumbers,
      taskKey: 'large:decompose:724',
      expected: 724,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.placeValueDecompose,
    );

    expect(independent, isEmpty);
  });

  test('Große Zahlen beobachten die erste unterschiedliche Stelle', () {
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.largeNumbers,
      taskKey: 'large:compare:722789:723383',
      expected: 0,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.largeNumberCompare,
    );
    final evidenceSteps = guide.steps
        .where((step) => step.recordsIntermediateEvidence)
        .toList();

    expect(guide.methodKey, 'largeNumbers:compare');
    expect(guide.methodLabel, 'Zahlen vergleichen');
    expect(guide.nudge, contains('von links nach rechts'));
    expect(evidenceSteps, hasLength(1));
    expect(evidenceSteps.single.evidenceKey, 'decidingPlace');
    expect(
      evidenceSteps.single.evidenceCompetency,
      MicroCompetencyId.largeNumberCompare,
    );
    expect(
      evidenceSteps.single.choices[evidenceSteps.single.correctChoice!],
      'Tausenderstelle',
    );
    expect(evidenceSteps.single.evidenceWeight, 0.40);
    expect(
      evidenceSteps.single.instruction,
      isNot(contains('Tausenderstelle')),
    );
    expect(guide.steps[1].instruction, contains('Tausenderstelle'));
    expect(guide.steps[1].instruction, contains('2'));
    expect(guide.steps[1].instruction, contains('3'));
    expect(
      GuidedStepCatalog.labelFor('decidingPlace'),
      contains('unterschiedliche Stelle'),
    );

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.largeNumbers,
      taskKey: 'large:compare:722789:723383',
      expected: 0,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.largeNumberCompare,
    );
    expect(independent.map((step) => step.evidenceKey), ['decidingPlace']);
  });

  testWidgets(
      'Curriculum speichert entscheidende Vergleichsstelle selbstständig',
      (tester) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.fourth;
    controller.numberRange = NumberRangeLevel.million;

    const exercise = CurriculumExercise(
      mode: TrainingMode.largeNumbers,
      prompt: 'Welches Zeichen passt?\n722.789  ?  723.383',
      answer: 0,
      hint:
          'Vergleiche von links nach rechts. Gleiche Stellen überspringst du.',
      key: 'large:compare:722789:723383',
      choices: ['<', '>', '='],
      method: 'Zahlen vergleichen',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.largeNumbers,
          targetTasks: 1,
          targetCompetency: MicroCompetencyId.largeNumberCompare,
          exerciseGenerator: _FixedCurriculumExerciseGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Schritt 1 von 1'), findsOneWidget);
    expect(find.text('<'), findsNothing);

    await tester.tap(
      find.widgetWithText(FilledButton, 'Tausenderstelle'),
    );
    await tester.pump(const Duration(milliseconds: 400));

    final steps = controller.microObservations
        .where((entry) => entry.source == MicroEvidenceSource.independentStep)
        .toList();
    expect(steps, hasLength(1));
    expect(steps.single.id, MicroCompetencyId.largeNumberCompare);
    expect(steps.single.correct, isTrue);
    expect(steps.single.usedHelp, isFalse);
    expect(
      steps.single.taskKey,
      'independent:decidingPlace:large:compare:722789:723383',
    );
    expect(find.text('<'), findsOneWidget);
  });

  testWidgets('Minus-Rechenweg läuft sichtbar von 87 über 80 zu 19',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningVisualAid(
            pattern: ErrorPattern.tenBridge,
            taskKey: 'minus:87:68',
            expected: 19,
            methodKey: 'subtraction:bridgeToTen',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Rechenweg'), findsOneWidget);
    expect(find.text('Zahlenstrahl'), findsNothing);
    expect(find.text('−7'), findsOneWidget);
    expect(find.text('−61'), findsOneWidget);

    final startX = tester.getCenter(find.text('87')).dx;
    final bridgeX = tester.getCenter(find.text('80')).dx;
    final endX = tester.getCenter(find.text('19')).dx;
    expect(startX, lessThan(bridgeX));
    expect(bridgeX, lessThan(endX));
  });

  testWidgets('Minus von 10 zeigt direkten visuellen Schritt zu 6',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningVisualAid(
            pattern: ErrorPattern.tenBridge,
            taskKey: 'minus:10:4',
            expected: 6,
            methodKey: 'subtraction:bridgeToTen',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('10'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('−4'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(find.textContaining('schon ein voller Zehner'), findsOneWidget);
  });

  testWidgets('Minus ohne Übergang hat echte Darstellung trotz numberBond',
      (tester) async {
    const guide = GuidedMethodGuide(
      methodKey: 'subtraction:direct',
      methodLabel: 'Direkt abziehen',
      nudge: 'Ziehe direkt ab.',
      steps: [
        GuidedMethodStep(
          title: 'Direkt rechnen',
          instruction: '47 − 3 = 44.',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuidedMethodPanel(
            guide: guide,
            pattern: ErrorPattern.numberBond,
            taskKey: 'minus:47:3',
            expected: 44,
            onHelpLevelChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('2 Darstellung'), findsOneWidget);
    await tester.tap(find.text('2 Darstellung'));
    await tester.pump();
    expect(find.text('Rechenweg'), findsOneWidget);
    expect(find.text('47'), findsOneWidget);
    expect(find.text('44'), findsOneWidget);
  });

  testWidgets('Panel verspricht keine Darstellung wenn keine existiert',
      (tester) async {
    const guide = GuidedMethodGuide(
      methodKey: 'general:test',
      methodLabel: 'Test',
      nudge: 'Ein Hinweis.',
      steps: [
        GuidedMethodStep(title: 'Schritt', instruction: 'Weiter.'),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuidedMethodPanel(
            guide: guide,
            pattern: ErrorPattern.unknown,
            taskKey: 'unknown:task',
            expected: 0,
            onHelpLevelChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('2 Darstellung'), findsNothing);
    expect(find.text('2 Schritt für Schritt'), findsOneWidget);
  });
  test('Automatisch vergleicht Methoden ohne gespeicherte Schulmethode zu ändern',
      () {
    const preferences = MethodPreferences(
      subtraction: SubtractionStrategy.complement,
      selectionPreference: MethodSelectionPreference.automatic,
    );
    final selected =
        preferences.effectiveSubtraction(taskKey: 'minus:13:5');

    expect(SubtractionStrategy.values, contains(selected));
    expect(preferences.subtraction, SubtractionStrategy.complement);
    expect(
      preferences.selectionPreference,
      MethodSelectionPreference.automatic,
    );
  });

  test('Hilfestufen gewichten Mikro-Evidenz abgestuft', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;

    final fact1 = MathFact(a: 13, b: 5, operation: MathOperation.minus);
    await controller.recordDiagnosticAttempt(
      mode: TrainingMode.minus,
      taskKey: fact1.key,
      expected: 8,
      actual: 8,
      fact: fact1,
      helpLevel: HelpLevel.none.value,
      methodKey: 'subtraction:bridgeToTen',
    );
    final noHelp = controller.microObservations.firstWhere(
      (entry) => entry.id == MicroCompetencyId.subtractionTenBridge,
    );

    final fact2 = MathFact(a: 14, b: 6, operation: MathOperation.minus);
    await controller.recordDiagnosticAttempt(
      mode: TrainingMode.minus,
      taskKey: fact2.key,
      expected: 8,
      actual: 8,
      fact: fact2,
      helpLevel: HelpLevel.guided.value,
      methodKey: 'subtraction:bridgeToTen',
    );
    final guided = controller.microObservations.firstWhere(
      (entry) =>
          entry.id == MicroCompetencyId.subtractionTenBridge &&
          entry.taskKey == fact2.key,
    );

    expect(noHelp.evidenceWeight, closeTo(1.0, 0.001));
    expect(guided.evidenceWeight, closeTo(0.50, 0.001));
    expect(guided.helpLevel, 3);
    expect(guided.methodKey, 'subtraction:bridgeToTen');
  });

  test('Methodenbeobachtung ändert Schulmethode nicht', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.methodPreferences = const MethodPreferences(
      subtraction: SubtractionStrategy.complement,
      selectionPreference: MethodSelectionPreference.automatic,
    );

    controller.microObservations = List.generate(
      4,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.subtractionTenBridge,
        occurredAt: DateTime(2026, 9, 5, 10, index),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        helpLevel: 0,
        methodKey: 'subtraction:bridgeToTen',
        mode: TrainingMode.minus,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'minus:${13 + index}:5',
      ),
    );

    final insight = controller.methodSupportInsight(
      MicroCompetencyId.subtractionTenBridge,
    );

    expect(insight, contains('Erst zum Zehner'));
    expect(
      controller.methodPreferences.subtraction,
      SubtractionStrategy.complement,
    );
  });
  test('Darstellungshilfe bleibt auch im Förderpfad darstellungsspezifisch', () {
    const preferences = MethodPreferences();

    final direct = GuidedMethodFactory.forTask(
      mode: TrainingMode.wordProblems,
      taskKey: 'process:representation:groups:3:4',
      expected: 0,
      preferences: preferences,
      targetCompetency: MicroCompetencyId.representationTranslation,
    );
    expect(direct.methodKey, 'representation:equalGroups');
    expect(direct.methodLabel, 'Gleiche Gruppen lesen');
    expect(direct.steps, hasLength(3));
    expect(direct.steps.last.instruction, contains('3 × 4'));

    final remediation = GuidedMethodFactory.forTask(
      mode: TrainingMode.wordProblems,
      taskKey:
          'remediation:representationTranslation:process:representation:place:407',
      expected: 0,
      preferences: preferences,
      targetCompetency: MicroCompetencyId.representationTranslation,
    );
    expect(remediation.methodKey, 'representation:placeValue');
    expect(remediation.methodLabel, 'Stellenwerte lesen');
    expect(remediation.steps[1].instruction, contains('407'));
  });

  test('Minus über den Zehner markiert echte Zwischenschritte', () {
    const preferences = MethodPreferences(
      subtraction: SubtractionStrategy.bridgeToTen,
      selectionPreference: MethodSelectionPreference.schoolMethod,
    );
    final fact = MathFact(
      a: 13,
      b: 5,
      operation: MathOperation.minus,
    );

    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.minus,
      taskKey: fact.key,
      expected: 8,
      preferences: preferences,
      fact: fact,
    );

    expect(guide.steps[0].recordsIntermediateEvidence, isTrue);
    expect(
      guide.steps[0].evidenceCompetency,
      MicroCompetencyId.subtractionTenBridge,
    );
    expect(guide.steps[0].evidenceKey, 'bridgeAmount');
    expect(guide.steps[1].recordsIntermediateEvidence, isTrue);
    expect(
      guide.steps[1].evidenceCompetency,
      MicroCompetencyId.numberDecomposition,
    );
    expect(guide.steps.last.recordsIntermediateEvidence, isFalse);
  });

  test('Darstellungswechsel zerlegt Gruppenlesen in beobachtbare Teilfragen', () {
    const preferences = MethodPreferences();

    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.wordProblems,
      taskKey: 'process:representation:groups:3:4',
      expected: 0,
      preferences: preferences,
      targetCompetency: MicroCompetencyId.representationTranslation,
    );

    expect(guide.steps[0].question, contains('Gruppen'));
    expect(guide.steps[0].recordsIntermediateEvidence, isTrue);
    expect(
      guide.steps[0].evidenceCompetency,
      MicroCompetencyId.multiplicationGroups,
    );
    expect(guide.steps[1].recordsIntermediateEvidence, isTrue);
    expect(
      guide.steps[1].evidenceCompetency,
      MicroCompetencyId.multiplicationGroups,
    );
    expect(guide.steps[2].recordsIntermediateEvidence, isFalse);
  });

  test('Schriftliches Minus beobachtet Ausrichtung und Entbündelentscheidung',
      () {
    const preferences = MethodPreferences(
      writtenSubtraction: WrittenSubtractionStrategy.regroup,
    );

    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.writtenAddSub,
      taskKey: 'written:-:402:187',
      expected: 215,
      preferences: preferences,
    );

    expect(guide.steps[0].recordsIntermediateEvidence, isTrue);
    expect(
      guide.steps[0].evidenceCompetency,
      MicroCompetencyId.writtenAlignment,
    );
    expect(guide.steps[1].recordsIntermediateEvidence, isTrue);
    expect(
      guide.steps[1].evidenceCompetency,
      MicroCompetencyId.writtenRegrouping,
    );
    expect(guide.steps[1].choices[guide.steps[1].correctChoice!], 'Ja');
  });

  test('Zerlegte Multiplikation beobachtet Teilprodukte statt nur Endergebnis',
      () {
    const preferences = MethodPreferences(
      multiplication: MultiplicationStrategy.decompose,
    );
    final fact = MathFact(
      a: 6,
      b: 7,
      operation: MathOperation.multiply,
    );

    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.multiply,
      taskKey: fact.key,
      expected: 42,
      preferences: preferences,
      fact: fact,
    );

    expect(guide.steps[0].recordsIntermediateEvidence, isTrue);
    expect(guide.steps[1].recordsIntermediateEvidence, isTrue);
    expect(
      guide.steps.take(2).every(
            (step) =>
                step.evidenceCompetency ==
                MicroCompetencyId.multiplicationFacts,
          ),
      isTrue,
    );
    expect(guide.steps.last.recordsIntermediateEvidence, isFalse);
  });

  testWidgets('Geführtes Panel meldet nur den ersten Versuch eines Schritts',
      (tester) async {
    const step = GuidedMethodStep(
      title: 'Teilfrage',
      instruction: 'Löse zuerst diesen Zwischenschritt.',
      question: 'Was ist richtig?',
      choices: ['3', '4'],
      correctChoice: 1,
      evidenceKey: 'firstStep',
      evidenceCompetency: MicroCompetencyId.numberDecomposition,
    );
    const guide = GuidedMethodGuide(
      methodKey: 'test:guided',
      methodLabel: 'Testweg',
      nudge: 'Ein kleiner Hinweis.',
      steps: [step],
    );
    final attempts = <bool>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuidedMethodPanel(
            guide: guide,
            pattern: ErrorPattern.numberBond,
            taskKey: 'test:task',
            expected: 4,
            onHelpLevelChanged: (_) {},
            onStepAttempt: (_, correct) async {
              attempts.add(correct);
            },
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('2 Schritt für Schritt'));
    await tester.pump();

    await tester.tap(find.widgetWithText(ChoiceChip, '3'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, '4'));
    await tester.pump();

    expect(attempts, [false]);
    expect(find.text('Genau. Dieser Schritt stimmt.'), findsOneWidget);
  });


  test('GuidedStepCatalog erkennt gespeicherte Teilsschlüssel zuverlässig', () {
    const taskKey =
        'guided:subtraction:bridgeToTen:remainingSubtrahend:minus:13:5';

    expect(
      GuidedStepCatalog.keyFromTaskKey(taskKey),
      'remainingSubtrahend',
    );
    expect(
      GuidedStepCatalog.labelFor('remainingSubtrahend'),
      contains('Subtrahenden'),
    );
    expect(GuidedStepCatalog.keyFromTaskKey('minus:13:5'), isNull);
  });


  test('Scaffold-Fading reduziert Darstellung zu Hinweis und dann ohne Hilfe',
      () {
    expect(
      ScaffoldFadingPolicy.initialLevelForTask(0, enabled: true),
      HelpLevel.visual,
    );
    expect(
      ScaffoldFadingPolicy.initialLevelForTask(1, enabled: true),
      HelpLevel.nudge,
    );
    expect(
      ScaffoldFadingPolicy.initialLevelForTask(2, enabled: true),
      isNull,
    );
    expect(
      ScaffoldFadingPolicy.initialLevelForTask(4, enabled: true),
      isNull,
    );
    expect(
      ScaffoldFadingPolicy.initialLevelForTask(0, enabled: false),
      isNull,
    );
  });

  testWidgets('Geführtes Panel kann direkt mit Darstellung starten',
      (tester) async {
    const guide = GuidedMethodGuide(
      methodKey: 'test:fading',
      methodLabel: 'Fading',
      nudge: 'Ein kurzer Hinweis.',
      steps: [],
    );
    final levels = <HelpLevel>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuidedMethodPanel(
            guide: guide,
            pattern: ErrorPattern.tenBridge,
            taskKey: 'plus:7:5',
            expected: 12,
            initialLevel: HelpLevel.visual,
            onHelpLevelChanged: levels.add,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(levels, [HelpLevel.visual]);
    final visualChip = tester.widget<ActionChip>(
      find.widgetWithText(ActionChip, '2 Darstellung'),
    );
    expect(visualChip.avatar, isNotNull);
  });



  test('Plus über den Zehner markiert echte unabhängige Zwischenschritte', () {
    final fact = MathFact(
      a: 47,
      b: 38,
      operation: MathOperation.plus,
    );

    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.practice,
      taskKey: fact.key,
      expected: 85,
      preferences: const MethodPreferences(),
      fact: fact,
    );

    expect(guide.methodKey, 'addition:bridgeToTen');
    expect(guide.steps[0].question, contains('47'));
    expect(guide.steps[0].choices[guide.steps[0].correctChoice!], '3');
    expect(guide.steps[0].evidenceKey, 'bridgeAmount');
    expect(
      guide.steps[0].evidenceCompetency,
      MicroCompetencyId.additionTenBridge,
    );
    expect(guide.steps[1].choices[guide.steps[1].correctChoice!], '35');
    expect(guide.steps[1].evidenceKey, 'remainingAddend');
    expect(
      guide.steps[1].evidenceCompetency,
      MicroCompetencyId.numberDecomposition,
    );
    expect(guide.steps.last.recordsIntermediateEvidence, isFalse);
  });

  test('Exakter Zehner erzeugt keine künstliche Übergangs-Evidenz', () {
    final fact = MathFact(
      a: 17,
      b: 3,
      operation: MathOperation.plus,
    );

    final steps = GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: TrainingMode.practice,
      fact: fact,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.additionTenBridge,
    );
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.practice,
      taskKey: fact.key,
      expected: fact.result,
      preferences: const MethodPreferences(),
      fact: fact,
    );

    expect(steps, isEmpty);
    expect(guide.methodKey, 'addition:toFullTen');
    expect(guide.methodLabel, 'Zum vollen Zehner');
    expect(guide.steps.where((step) => step.recordsIntermediateEvidence), isEmpty);
  });

  testWidgets('Exakter Plus-Zehner behält eine passende Darstellung',
      (tester) async {
    final fact = MathFact(a: 17, b: 3, operation: MathOperation.plus);
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.practice,
      taskKey: fact.key,
      expected: fact.result,
      preferences: const MethodPreferences(),
      fact: fact,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LearningVisualAid(
            pattern: ErrorPattern.numberBond,
            taskKey: fact.key,
            expected: fact.result,
            methodKey: guide.methodKey,
          ),
        ),
      ),
    );

    expect(find.text('Start'), findsOneWidget);
    expect(find.text('voller Zehner'), findsOneWidget);
    expect(find.text('17 + 3 = 20'), findsOneWidget);
  });

  test('Unabhängige Rechenschritte bleiben gezielt und untimed', () {
    final bridge = MathFact(
      a: 47,
      b: 38,
      operation: MathOperation.plus,
    );
    final noBridge = MathFact(
      a: 42,
      b: 3,
      operation: MathOperation.plus,
    );

    final targeted = GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: TrainingMode.practice,
      fact: bridge,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.additionTenBridge,
    );
    final decompositionOnly =
        GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: TrainingMode.practice,
      fact: bridge,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.numberDecomposition,
    );
    final untargeted = GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: TrainingMode.practice,
      fact: bridge,
      preferences: const MethodPreferences(),
    );
    final timed = GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: TrainingMode.speed,
      fact: bridge,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.additionTenBridge,
    );
    final simple = GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: TrainingMode.practice,
      fact: noBridge,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.additionTenBridge,
    );

    expect(targeted.map((step) => step.evidenceKey), [
      'bridgeAmount',
      'remainingAddend',
    ]);
    expect(
      decompositionOnly.map((step) => step.evidenceKey),
      ['remainingAddend'],
    );
    expect(untargeted, isEmpty);
    expect(timed, isEmpty);
    expect(simple, isEmpty);
  });

  test('Einmaleins-Teilfragen bleiben methodentreu und mikrogezielt', () {
    final fact = MathFact(
      a: 7,
      b: 6,
      operation: MathOperation.multiply,
    );

    final groups = GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: TrainingMode.multiply,
      fact: fact,
      preferences: const MethodPreferences(
        multiplication: MultiplicationStrategy.groups,
      ),
      targetCompetency: MicroCompetencyId.multiplicationFacts,
    );
    final decompose = GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: TrainingMode.multiply,
      fact: fact,
      preferences: const MethodPreferences(
        multiplication: MultiplicationStrategy.decompose,
      ),
      targetCompetency: MicroCompetencyId.multiplicationFacts,
    );
    final neighbor = GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: TrainingMode.multiply,
      fact: fact,
      preferences: const MethodPreferences(
        multiplication: MultiplicationStrategy.neighborFacts,
      ),
      targetCompetency: MicroCompetencyId.multiplicationFacts,
    );
    final wrongTarget = GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: TrainingMode.multiply,
      fact: fact,
      preferences: const MethodPreferences(
        multiplication: MultiplicationStrategy.decompose,
      ),
      targetCompetency: MicroCompetencyId.multiplicationGroups,
    );
    final timed = GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: TrainingMode.speed,
      fact: fact,
      preferences: const MethodPreferences(
        multiplication: MultiplicationStrategy.decompose,
      ),
      targetCompetency: MicroCompetencyId.multiplicationFacts,
    );

    expect(groups.map((step) => step.evidenceKey), ['anchorFact']);
    expect(groups.single.choices[groups.single.correctChoice!], '30');
    expect(
      decompose.map((step) => step.evidenceKey),
      ['firstPartialProduct', 'secondPartialProduct'],
    );
    expect(decompose[0].choices[decompose[0].correctChoice!], '21');
    expect(decompose[1].choices[decompose[1].correctChoice!], '21');
    expect(neighbor.map((step) => step.evidenceKey), ['anchorFact']);
    expect(neighbor.single.choices[neighbor.single.correctChoice!], '35');
    expect(
      [
        ...groups,
        ...decompose,
        ...neighbor,
      ].every(
        (step) =>
            step.evidenceCompetency ==
            MicroCompetencyId.multiplicationFacts,
      ),
      isTrue,
    );
    expect(wrongTarget, isEmpty);
    expect(timed, isEmpty);
  });

  test('Minus nutzt die gewählte Schulmethode und überspringt triviale Dekaden',
      () {
    const preferences = MethodPreferences(
      subtraction: SubtractionStrategy.bridgeToTen,
      selectionPreference: MethodSelectionPreference.schoolMethod,
    );
    final bridge = MathFact(
      a: 63,
      b: 28,
      operation: MathOperation.minus,
    );
    final fullDecade = MathFact(
      a: 20,
      b: 7,
      operation: MathOperation.minus,
    );

    final steps = GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: TrainingMode.minus,
      fact: bridge,
      preferences: preferences,
      targetCompetency: MicroCompetencyId.subtractionTenBridge,
    );
    final trivial = GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: TrainingMode.minus,
      fact: fullDecade,
      preferences: preferences,
      targetCompetency: MicroCompetencyId.subtractionTenBridge,
    );

    expect(steps.map((step) => step.evidenceKey), [
      'bridgeAmount',
      'remainingSubtrahend',
    ]);
    expect(steps[0].choices[steps[0].correctChoice!], '3');
    expect(steps[1].choices[steps[1].correctChoice!], '25');
    expect(trivial, isEmpty);
  });

  test('Arithmetische Teilfragen bleiben auf zwei Fokusaufgaben begrenzt', () {
    expect(
      IndependentArithmeticStepPolicy.shouldProbeTask(
        0,
        scaffoldFading: false,
      ),
      isTrue,
    );
    expect(
      IndependentArithmeticStepPolicy.shouldProbeTask(
        1,
        scaffoldFading: false,
      ),
      isTrue,
    );
    expect(
      IndependentArithmeticStepPolicy.shouldProbeTask(
        2,
        scaffoldFading: false,
      ),
      isFalse,
    );
    expect(
      IndependentArithmeticStepPolicy.shouldProbeTask(
        1,
        scaffoldFading: true,
      ),
      isFalse,
    );
    expect(
      IndependentArithmeticStepPolicy.shouldProbeTask(
        2,
        scaffoldFading: true,
      ),
      isTrue,
    );
    expect(
      IndependentArithmeticStepPolicy.shouldProbeTask(
        3,
        scaffoldFading: true,
      ),
      isTrue,
    );
    expect(
      IndependentArithmeticStepPolicy.shouldProbeTask(
        4,
        scaffoldFading: true,
      ),
      isFalse,
    );
  });

  test('GuidedStepCatalog erkennt auch den Rest des zweiten Summanden', () {
    const key = 'independent:remainingAddend:plus:47:38';

    expect(GuidedStepCatalog.keyFromTaskKey(key), 'remainingAddend');
    expect(
      GuidedStepCatalog.labelFor('remainingAddend'),
      contains('zweiten Summanden'),
    );
  });

  testWidgets(
      'Scaffold-Fading prüft erst nach zwei unterstützten Aufgaben selbstständig',
      (tester) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.facts = [
      MathFact(
        a: 47,
        b: 38,
        operation: MathOperation.plus,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: TrainingScreen(
          controller: controller,
          mode: TrainingMode.practice,
          targetTasks: 3,
          targetCompetency: MicroCompetencyId.additionTenBridge,
          scaffoldFading: true,
        ),
      ),
    );
    await tester.pump();

    Future<void> tapAnswerButton(String label) async {
      final button = find.widgetWithText(FilledButton, label);
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pump();
    }

    expect(find.textContaining('Schritt 1 von'), findsNothing);

    for (final label in ['8', '5', 'OK']) {
      await tapAnswerButton(label);
    }
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.textContaining('Schritt 1 von'), findsNothing);

    await tapAnswerButton('8');
    await tapAnswerButton('5');
    await tapAnswerButton('OK');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Schritt 1 von'), findsNothing);

    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Schritt 1 von 2'), findsOneWidget);
  });

  testWidgets(
      'Training speichert ersten Zehnerübergangsversuch und direkte Lösung getrennt',
      (tester) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.facts = [
      MathFact(
        a: 47,
        b: 38,
        operation: MathOperation.plus,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: TrainingScreen(
          controller: controller,
          mode: TrainingMode.practice,
          targetTasks: 1,
          targetCompetency: MicroCompetencyId.additionTenBridge,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Schritt 1 von 2'), findsOneWidget);
    expect(find.text('Antwort eingeben'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, '2'));
    await tester.pump();

    final failedStep = controller.microObservations.firstWhere(
      (entry) => entry.source == MicroEvidenceSource.independentStep,
    );
    expect(failedStep.id, MicroCompetencyId.additionTenBridge);
    expect(failedStep.correct, isFalse);
    expect(failedStep.usedHelp, isFalse);
    expect(
      failedStep.taskKey,
      'independent:bridgeAmount:plus:47:38',
    );

    await tester.tap(find.widgetWithText(FilledButton, '3'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Schritt 2 von 2'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '35'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Antwort eingeben'), findsOneWidget);

    for (final label in ['8', '5', 'OK']) {
      final button = find.widgetWithText(FilledButton, label);
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('0 davon waren direkt richtig.'), findsOneWidget);
    expect(
      controller
          .recentTaskKeys(TrainingMode.practice)
          .where((key) => key == 'plus:47:38')
          .length,
      1,
    );
  });


  test('Schriftliches Plus beobachtet Ausrichtung und echten Übertrag', () {
    const preferences = MethodPreferences();

    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.writtenAddSub,
      taskKey: 'written:+:342:381',
      expected: 723,
      preferences: preferences,
    );

    expect(guide.methodKey, 'writtenAddition:standard');
    expect(guide.steps[0].evidenceKey, 'onesAlignment');
    expect(
      guide.steps[0].evidenceCompetency,
      MicroCompetencyId.writtenAlignment,
    );
    expect(guide.steps[0].choices[guide.steps[0].correctChoice!], '1');
    expect(guide.steps[1].question, contains('Zehner-Spalte'));
    expect(guide.steps[1].choices[guide.steps[1].correctChoice!], 'Ja');
    expect(guide.steps[1].evidenceKey, 'carryDecision');
    expect(
      guide.steps[1].evidenceCompetency,
      MicroCompetencyId.writtenRegrouping,
    );
  });

  test('Schriftliche Teilfragen bleiben mikrogezielt und methodentreu', () {
    const standard = MethodPreferences();
    const complement = MethodPreferences(
      writtenSubtraction: WrittenSubtractionStrategy.complement,
    );

    final regrouping = GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.writtenAddSub,
      taskKey: 'written:+:47:38',
      expected: 85,
      preferences: standard,
      targetCompetency: MicroCompetencyId.writtenRegrouping,
    );
    final alignment = GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.writtenAddSub,
      taskKey: 'written:+:47:38',
      expected: 85,
      preferences: standard,
      targetCompetency: MicroCompetencyId.writtenAlignment,
    );
    final noCarry = GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.writtenAddSub,
      taskKey: 'written:+:42:13',
      expected: 55,
      preferences: standard,
      targetCompetency: MicroCompetencyId.writtenRegrouping,
    );
    final complementSteps =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.writtenAddSub,
      taskKey: 'written:-:352:168',
      expected: 184,
      preferences: complement,
      targetCompetency: MicroCompetencyId.writtenRegrouping,
    );

    expect(
      regrouping.map((step) => step.evidenceKey),
      ['onesAlignment', 'carryDecision'],
    );
    expect(alignment.map((step) => step.evidenceKey), ['onesAlignment']);
    expect(noCarry, isEmpty);
    expect(
      complementSteps.map((step) => step.evidenceKey),
      ['onesAlignment', 'carryDecision'],
    );
    expect(complementSteps[1].question, contains('über 10 ergänzen'));
  });

  test('GuidedStepCatalog erkennt Übertragsentscheidungen', () {
    const key = 'independent:carryDecision:written:+:47:38';

    expect(GuidedStepCatalog.keyFromTaskKey(key), 'carryDecision');
    expect(GuidedStepCatalog.labelFor('carryDecision'), contains('Übertrag'));
  });

  testWidgets(
      'Curriculum speichert schriftlichen Teilfehler getrennt von der Endlösung',
      (tester) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;

    const exercise = CurriculumExercise(
      mode: TrainingMode.writtenAddSub,
      prompt: 'Rechne schriftlich:\n47\n+ 38',
      answer: 85,
      hint: 'Achte auf Stellenwerte und Übertrag.',
      key: 'written:+:47:38',
      maxAnswerValue: 100,
      method: 'Schriftliche Addition',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.writtenAddSub,
          targetTasks: 1,
          targetCompetency: MicroCompetencyId.writtenRegrouping,
          exerciseGenerator: _FixedCurriculumExerciseGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Schritt 1 von 2'), findsOneWidget);
    expect(find.text('Antwort eingeben'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, '7'));
    await tester.pump();

    final failedStep = controller.microObservations.firstWhere(
      (entry) => entry.source == MicroEvidenceSource.independentStep,
    );
    expect(failedStep.id, MicroCompetencyId.writtenAlignment);
    expect(failedStep.correct, isFalse);
    expect(failedStep.usedHelp, isFalse);
    expect(
      failedStep.taskKey,
      'independent:onesAlignment:written:+:47:38',
    );

    await tester.tap(find.widgetWithText(FilledButton, '8'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Schritt 2 von 2'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Ja'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Antwort eingeben'), findsOneWidget);

    for (final label in ['8', '5', 'OK']) {
      final button = find.widgetWithText(FilledButton, label);
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('0 direkt richtig.'), findsOneWidget);
    expect(
      controller
          .recentTaskKeys(TrainingMode.writtenAddSub)
          .where((key) => key == 'written:+:47:38')
          .length,
      1,
    );
  });


  test('Schriftliches Mal beobachtet Spaltenprodukt und Übertrag', () {
    final steps = GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.writtenMultiply,
      taskKey: 'written:x:237:4',
      expected: 948,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.writtenMultiplyProcedure,
    );

    expect(steps.map((step) => step.evidenceKey), [
      'firstPartialProduct',
      'multiplicationCarry',
    ]);
    expect(steps[0].choices[steps[0].correctChoice!], '28');
    expect(steps[1].choices[steps[1].correctChoice!], '2');
    expect(
      steps.every(
        (step) =>
            step.evidenceCompetency ==
            MicroCompetencyId.writtenMultiplyProcedure,
      ),
      isTrue,
    );
  });

  test('Mehrstelliger Faktor nutzt Teilprodukt und nächste Faktorstelle', () {
    final steps = GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.writtenMultiply,
      taskKey: 'written:x:123:14',
      expected: 1722,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.writtenMultiplyProcedure,
    );

    expect(steps.map((step) => step.evidenceKey), [
      'firstPartialProduct',
      'nextMultiplierDigit',
    ]);
    expect(steps[0].choices[steps[0].correctChoice!], '492');
    expect(steps[1].choices[steps[1].correctChoice!], '1');
  });

  test('Schriftliches Teilen beobachtet erste Quotientenziffer und Rest', () {
    final steps = GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.writtenDivide,
      taskKey: 'written:divide:324:6',
      expected: 54,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.writtenDivideProcedure,
    );

    expect(steps.map((step) => step.evidenceKey), [
      'firstQuotientDigit',
      'firstDivisionRemainder',
    ]);
    expect(steps[0].question, contains('6 in 32'));
    expect(steps[0].choices[steps[0].correctChoice!], '5');
    expect(steps[1].choices[steps[1].correctChoice!], '2');
    expect(
      steps.every(
        (step) =>
            step.evidenceCompetency ==
            MicroCompetencyId.writtenDivideProcedure,
      ),
      isTrue,
    );
  });

  test('Schriftliche Mal/Geteilt-Teilfragen bleiben auf ihr Lernziel begrenzt',
      () {
    final wrongTarget = GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.writtenMultiply,
      taskKey: 'written:x:237:4',
      expected: 948,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.writtenAlignment,
    );
    final untargetedDivision =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.writtenDivide,
      taskKey: 'written:divide:324:6',
      expected: 54,
      preferences: const MethodPreferences(),
    );

    expect(wrongTarget, isEmpty);
    expect(untargetedDivision, isEmpty);
  });

  test('GuidedStepCatalog kennt schriftliche Mal- und Geteilt-Schritte', () {
    expect(
      GuidedStepCatalog.keyFromTaskKey(
        'independent:multiplicationCarry:written:x:237:4',
      ),
      'multiplicationCarry',
    );
    expect(
      GuidedStepCatalog.labelFor('firstQuotientDigit'),
      contains('Quotientenziffer'),
    );
    expect(
      GuidedStepCatalog.labelFor('firstDivisionRemainder'),
      contains('Divisionsschritt'),
    );
  });

  testWidgets(
      'Curriculum speichert schriftlichen Mal-Teilfehler vor der Endlösung',
      (tester) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;

    const exercise = CurriculumExercise(
      mode: TrainingMode.writtenMultiply,
      prompt: 'Rechne schriftlich:\n237 × 4',
      answer: 948,
      hint: 'Multipliziere Stelle für Stelle.',
      key: 'written:x:237:4',
      maxAnswerValue: 1000,
      method: 'Schriftliche Multiplikation',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.writtenMultiply,
          targetTasks: 1,
          targetCompetency: MicroCompetencyId.writtenMultiplyProcedure,
          exerciseGenerator: _FixedCurriculumExerciseGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Schritt 1 von 2'), findsOneWidget);
    expect(find.text('Antwort eingeben'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, '27'));
    await tester.pump();

    final failedStep = controller.microObservations.firstWhere(
      (entry) => entry.source == MicroEvidenceSource.independentStep,
    );
    expect(failedStep.id, MicroCompetencyId.writtenMultiplyProcedure);
    expect(failedStep.correct, isFalse);
    expect(
      failedStep.taskKey,
      'independent:firstPartialProduct:written:x:237:4',
    );

    await tester.tap(find.widgetWithText(FilledButton, '28'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Schritt 2 von 2'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '2'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Antwort eingeben'), findsOneWidget);

    for (final label in ['9', '4', '8', 'OK']) {
      final button = find.widgetWithText(FilledButton, label);
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('0 direkt richtig.'), findsOneWidget);
    expect(
      controller
          .recentTaskKeys(TrainingMode.writtenMultiply)
          .where((key) => key == 'written:x:237:4')
          .length,
      1,
    );
  });

  testWidgets(
      'Training speichert Einmaleins-Ankerfehler getrennt von der Endlösung',
      (tester) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    await controller.setMultiplicationStrategy(
      MultiplicationStrategy.neighborFacts,
    );
    controller.facts = [
      MathFact(
        a: 7,
        b: 6,
        operation: MathOperation.multiply,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: TrainingScreen(
          controller: controller,
          mode: TrainingMode.multiply,
          targetTasks: 1,
          targetCompetency: MicroCompetencyId.multiplicationFacts,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Schritt 1 von 1'), findsOneWidget);
    expect(find.text('Antwort eingeben'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, '34'));
    await tester.pump();

    final failedStep = controller.microObservations.firstWhere(
      (entry) => entry.source == MicroEvidenceSource.independentStep,
    );
    expect(failedStep.id, MicroCompetencyId.multiplicationFacts);
    expect(failedStep.correct, isFalse);
    expect(failedStep.usedHelp, isFalse);
    expect(
      failedStep.taskKey,
      'independent:anchorFact:multiply:7:6',
    );

    await tester.tap(find.widgetWithText(FilledButton, '35'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Antwort eingeben'), findsOneWidget);

    for (final label in ['4', '2', 'OK']) {
      final button = find.widgetWithText(FilledButton, label);
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('0 davon waren direkt richtig.'), findsOneWidget);
    expect(
      controller
          .recentTaskKeys(TrainingMode.multiply)
          .where((key) => key == 'multiply:7:6')
          .length,
      1,
    );
  });

  test('Zahlenfolgen beobachten die gerichtete Schrittweite', () {
    final forward = GuidedMethodFactory.forTask(
      mode: TrainingMode.sequences,
      taskKey: 'sequence:+:8:2',
      expected: 14,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.numberPatterns,
    );
    final forwardEvidence = forward.steps.singleWhere(
      (step) => step.evidenceKey == 'sequenceStepSize',
    );

    expect(forward.methodKey, 'sequence:constantStep');
    expect(forward.methodLabel, 'Musterregel finden');
    expect(
      forwardEvidence.evidenceCompetency,
      MicroCompetencyId.numberPatterns,
    );
    expect(forwardEvidence.evidenceWeight, 0.40);
    expect(
      forwardEvidence.choices[forwardEvidence.correctChoice!],
      'immer +2',
    );
    expect(forwardEvidence.instruction, isNot(contains('+2')));
    expect(forward.steps[1].instruction, contains('um 2 größer'));
    expect(forward.steps.last.instruction, contains('12 + 2 = 14'));
    expect(
      GuidedStepCatalog.labelFor('sequenceStepSize'),
      contains('Schrittweite'),
    );

    final backward = GuidedMethodFactory.forTask(
      mode: TrainingMode.sequences,
      taskKey: 'sequence:-:20:5',
      expected: 5,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.numberPatterns,
    );
    final backwardEvidence = backward.steps.singleWhere(
      (step) => step.evidenceKey == 'sequenceStepSize',
    );

    expect(
      backwardEvidence.choices[backwardEvidence.correctChoice!],
      'immer −5',
    );
    expect(backward.steps[1].instruction, contains('um 5 kleiner'));
    expect(backward.steps.last.instruction, contains('10 − 5 = 5'));
  });

  test('Uhrlesen trennt Minutenzeiger von der ganzen Uhrzeit', () {
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.clock,
      taskKey: 'clock:7:30',
      expected: 0,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.clockReading,
    );
    final evidence = guide.steps.singleWhere(
      (step) => step.evidenceKey == 'minuteHandMinutes',
    );

    expect(guide.methodKey, 'clock:readHands');
    expect(guide.methodLabel, 'Uhrzeiger lesen');
    expect(evidence.evidenceCompetency, MicroCompetencyId.clockReading);
    expect(evidence.evidenceWeight, 0.40);
    expect(evidence.choices, ['0 Minuten', '30 Minuten']);
    expect(evidence.choices[evidence.correctChoice!], '30 Minuten');
    expect(evidence.instruction, isNot(contains('30')));
    expect(guide.steps[1].instruction, contains('begonnene Stunde ist 7'));
    expect(guide.steps.last.instruction, contains('7:30 Uhr'));
    expect(
      GuidedStepCatalog.labelFor('minuteHandMinutes'),
      contains('langen Zeigers'),
    );
  });

  test('Uhrlesen unterstützt Viertelstunden ohne Klasse-1-Distraktoren', () {
    final quarter = GuidedMethodFactory.forTask(
      mode: TrainingMode.clock,
      taskKey: 'clock:4:45',
      expected: 0,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.clockReading,
    );
    final quarterStep = quarter.steps.singleWhere(
      (step) => step.evidenceKey == 'minuteHandMinutes',
    );

    expect(
      quarterStep.choices,
      ['0 Minuten', '15 Minuten', '30 Minuten', '45 Minuten'],
    );
    expect(
      quarterStep.choices[quarterStep.correctChoice!],
      '45 Minuten',
    );

    final half = GuidedMethodFactory.forTask(
      mode: TrainingMode.clock,
      taskKey: 'clock:4:30',
      expected: 0,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.clockReading,
    );
    expect(
      half.steps
          .singleWhere((step) => step.evidenceKey == 'minuteHandMinutes')
          .choices,
      ['0 Minuten', '30 Minuten'],
    );
  });

  test('Runden beobachtet die entscheidende Ziffer unabhängig', () {
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.rounding,
      taskKey: 'round:467:100',
      expected: 500,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.roundingPlace,
    );
    final evidence = guide.steps.singleWhere(
      (step) => step.evidenceKey == 'roundingDecisionDigit',
    );

    expect(guide.methodKey, 'rounding:place');
    expect(guide.methodLabel, 'Runden');
    expect(evidence.evidenceCompetency, MicroCompetencyId.roundingPlace);
    expect(evidence.evidenceWeight, 0.40);
    expect(evidence.choices[evidence.correctChoice!], '6');
    expect(evidence.instruction, isNot(contains('6')));
    expect(evidence.instruction, contains('Zehnerstelle'));
    expect(guide.steps[1].title, 'Aufrunden');
    expect(guide.steps.last.instruction, contains('500'));
    expect(
      GuidedStepCatalog.labelFor('roundingDecisionDigit'),
      contains('entscheidende Ziffer'),
    );

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.rounding,
      taskKey: 'round:467:100',
      expected: 500,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.roundingPlace,
    );
    expect(
      independent.map((step) => step.evidenceKey),
      ['roundingDecisionDigit'],
    );
  });

  test('Runden erkennt auch eine Abrund-Entscheidung', () {
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.rounding,
      taskKey: 'round:432:100',
      expected: 400,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.roundingPlace,
    );

    expect(
      guide.steps
          .singleWhere((step) => step.evidenceKey == 'roundingDecisionDigit')
          .choices
          .elementAt(
            guide.steps
                .singleWhere(
                  (step) => step.evidenceKey == 'roundingDecisionDigit',
                )
                .correctChoice!,
          ),
      '3',
    );
    expect(guide.steps[1].title, 'Abrunden');
  });

  testWidgets('Curriculum speichert Rundungs-Entscheidungsziffer selbstständig',
      (tester) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;

    const exercise = CurriculumExercise(
      mode: TrainingMode.rounding,
      prompt: 'Runde 467 auf Hunderter.',
      answer: 500,
      hint:
          'Schau auf die Stelle rechts daneben: 0–4 abrunden, 5–9 aufrunden.',
      key: 'round:467:100',
      maxAnswerValue: 1000,
      method: 'Runden',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.rounding,
          targetTasks: 1,
          targetCompetency: MicroCompetencyId.roundingPlace,
          exerciseGenerator: _FixedCurriculumExerciseGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Schritt 1 von 1'), findsOneWidget);
    expect(find.text('Antwort eingeben'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, '6'));
    await tester.pump(const Duration(milliseconds: 400));

    final steps = controller.microObservations
        .where((entry) => entry.source == MicroEvidenceSource.independentStep)
        .toList();
    expect(steps, hasLength(1));
    expect(steps.single.id, MicroCompetencyId.roundingPlace);
    expect(steps.single.correct, isTrue);
    expect(steps.single.usedHelp, isFalse);
    expect(
      steps.single.taskKey,
      'independent:roundingDecisionDigit:round:467:100',
    );
    expect(find.text('Antwort eingeben'), findsOneWidget);
  });



  test('Doppeln-und-Halbieren-Hilfe beobachtet zuerst die Begriffsbeziehung',
      () {
    const cases = [
      (
        key: 'double:7',
        expected: 14,
        correct: 'zweimal dieselbe Menge zusammen',
      ),
      (
        key: 'half:14',
        expected: 7,
        correct: 'in zwei gleich große Teile teilen',
      ),
    ];

    for (final item in cases) {
      final guide = GuidedMethodFactory.forTask(
        mode: TrainingMode.doublesHalves,
        taskKey: item.key,
        expected: item.expected,
        preferences: const MethodPreferences(),
        targetCompetency: MicroCompetencyId.doublesHalves,
      );
      final evidence =
          guide.steps.where((step) => step.recordsIntermediateEvidence).single;

      expect(guide.methodKey, 'doublesHalves:relationship');
      expect(evidence.evidenceKey, 'doubleHalfMeaning');
      expect(evidence.evidenceCompetency, MicroCompetencyId.doublesHalves);
      expect(evidence.evidenceWeight, 0.40);
      expect(evidence.choices[evidence.correctChoice!], item.correct);
      expect(
        evidence.instruction,
        isNot(contains(item.expected.toString())),
      );
    }
  });

  test('Längen-Hilfe trennt Rechenplan vom Ausrechnen', () {
    const cases = [
      (
        key: 'measure:add:ribbon:7:5',
        expected: 12,
        correct: 'Plus (+)',
        calculation: '7 + 5',
      ),
      (
        key: 'measure:subtract:rope:12:5',
        expected: 7,
        correct: 'Minus (−)',
        calculation: '12 − 5',
      ),
    ];

    for (final item in cases) {
      final guide = GuidedMethodFactory.forTask(
        mode: TrainingMode.measures,
        taskKey: item.key,
        expected: item.expected,
        preferences: const MethodPreferences(),
        targetCompetency: MicroCompetencyId.measurementCalculation,
      );

      expect(guide.methodKey, 'measure:calculationPlan');
      final evidenceStep =
          guide.steps.where((step) => step.recordsIntermediateEvidence).single;
      expect(evidenceStep.evidenceKey, 'measureOperationChoice');
      expect(
        evidenceStep.evidenceCompetency,
        MicroCompetencyId.measurementCalculation,
      );
      expect(evidenceStep.evidenceWeight, 0.40);
      expect(evidenceStep.choices.toSet(), {'Plus (+)', 'Minus (−)'});
      expect(
        evidenceStep.choices[evidenceStep.correctChoice!],
        item.correct,
      );
      expect(guide.steps.last.instruction, contains(item.calculation));
      expect(
        guide.steps.last.instruction,
        isNot(contains('= ${item.expected}')),
      );
    }
  });

  test('Normale Additions- und Subtraktionslängen nutzen keine Einheitenleiter',
      () {
    for (final item in [
      (key: 'measure:add:string:6:4', expected: 10),
      (key: 'measure:subtract:rope:10:4', expected: 6),
    ]) {
      final guide = GuidedMethodFactory.forTask(
        mode: TrainingMode.measures,
        taskKey: item.key,
        expected: item.expected,
        preferences: const MethodPreferences(),
      );

      expect(guide.methodKey, 'measure:calculationPlan');
      expect(guide.methodKey, isNot('measure:unitLadder'));
    }
  });

  test('Einheitenumrechnung beobachtet zuerst die feste Beziehung', () {
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.advancedMeasures,
      taskKey: 'length:m:7',
      expected: 700,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.unitConversion,
    );
    final evidenceSteps = guide.steps
        .where((step) => step.recordsIntermediateEvidence)
        .toList();

    expect(guide.methodKey, 'measure:unitLadder');
    expect(evidenceSteps, hasLength(1));
    expect(evidenceSteps.single.evidenceKey, 'unitRelation');
    expect(
      evidenceSteps.single.evidenceCompetency,
      MicroCompetencyId.unitConversion,
    );
    expect(
      evidenceSteps.single.choices[evidenceSteps.single.correctChoice!],
      '1 m = 100 cm',
    );
    expect(evidenceSteps.single.evidenceWeight, 0.40);
    expect(
      evidenceSteps.single.instruction,
      isNot(contains('1 m = 100 cm')),
    );
    expect(guide.steps.last.instruction, contains('7 × 100'));
    expect(
      GuidedStepCatalog.labelFor('unitRelation'),
      contains('Beziehung'),
    );

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.advancedMeasures,
      taskKey: 'length:m:7',
      expected: 700,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.unitConversion,
    );
    expect(independent.map((step) => step.evidenceKey), ['unitRelation']);
  });

  test('Minuten zu Stunden nutzt die Beziehung rückwärts', () {
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.advancedMeasures,
      taskKey: 'time:min:180',
      expected: 3,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.unitConversion,
    );
    final evidence = guide.steps.singleWhere(
      (step) => step.evidenceKey == 'unitRelation',
    );

    expect(
      evidence.choices[evidence.correctChoice!],
      '1 h = 60 min',
    );
    expect(guide.steps.last.instruction, contains('180 ÷ 60'));
  });

  test('Sekunden-Kompetenz beobachtet die 60er-Beziehung unabhängig',
      () {
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.advancedMeasures,
      taskKey: 'time:seconds:min-to-sec:4',
      expected: 240,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.secondsConversion,
    );
    final evidence = guide.steps.singleWhere(
      (step) => step.evidenceKey == 'minuteSecondRelation',
    );

    expect(guide.methodKey, 'measure:minuteSecond');
    expect(guide.methodLabel, 'Minuten und Sekunden');
    expect(
      evidence.evidenceCompetency,
      MicroCompetencyId.secondsConversion,
    );
    expect(evidence.evidenceWeight, 0.40);
    expect(
      evidence.choices[evidence.correctChoice!],
      '1 min = 60 s',
    );
    expect(evidence.instruction, isNot(contains('60')));
    expect(guide.steps.last.instruction, contains('4 × 60'));
    expect(
      GuidedStepCatalog.labelFor('minuteSecondRelation'),
      contains('Minuten und Sekunden'),
    );

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.advancedMeasures,
      taskKey: 'time:seconds:min-to-sec:4',
      expected: 240,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.secondsConversion,
    );
    expect(
      independent.map((step) => step.evidenceKey),
      ['minuteSecondRelation'],
    );
  });

  test('Sekunden zu Minuten wendet die 60er-Beziehung rückwärts an', () {
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.advancedMeasures,
      taskKey: 'time:seconds:sec-to-min:240',
      expected: 4,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.secondsConversion,
    );

    expect(
      guide.steps
          .singleWhere((step) => step.evidenceKey == 'minuteSecondRelation')
          .choices[1],
      '1 min = 60 s',
    );
    expect(guide.steps.last.instruction, contains('240 ÷ 60'));
  });

  testWidgets('Sekunden-Darstellung zeigt beide Einheiten in Rechenrichtung',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningVisualAid(
            pattern: ErrorPattern.unitConversion,
            taskKey: 'time:seconds:sec-to-min:240',
            expected: 4,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Minuten und Sekunden'), findsOneWidget);
    expect(find.text('1 min = 60 s'), findsOneWidget);
    final secondsX = tester.getCenter(find.text('s')).dx;
    final minutesX = tester.getCenter(find.text('min')).dx;
    expect(secondsX, lessThan(minutesX));
  });

  testWidgets('Curriculum speichert Minuten-Sekunden-Beziehung selbstständig',
      (tester) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;

    const exercise = CurriculumExercise(
      mode: TrainingMode.advancedMeasures,
      prompt: '4 min sind wie viele Sekunden?',
      answer: 240,
      hint: '1 Minute = 60 Sekunden.',
      key: 'time:seconds:min-to-sec:4',
      answerSuffix: 's',
      maxAnswerValue: 900,
      method: 'Größen umwandeln',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.advancedMeasures,
          targetTasks: 1,
          targetCompetency: MicroCompetencyId.secondsConversion,
          exerciseGenerator: _FixedCurriculumExerciseGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Schritt 1 von 1'), findsOneWidget);
    expect(find.text('Antwort eingeben'), findsNothing);

    await tester.tap(
      find.widgetWithText(FilledButton, '1 min = 60 s'),
    );
    await tester.pump(const Duration(milliseconds: 400));

    final steps = controller.microObservations
        .where((entry) => entry.source == MicroEvidenceSource.independentStep)
        .toList();
    expect(steps, hasLength(1));
    expect(steps.single.id, MicroCompetencyId.secondsConversion);
    expect(steps.single.correct, isTrue);
    expect(steps.single.usedHelp, isFalse);
    expect(
      steps.single.taskKey,
      'independent:minuteSecondRelation:time:seconds:min-to-sec:4',
    );
    expect(find.text('Antwort eingeben'), findsOneWidget);
  });

  testWidgets('Curriculum speichert Einheitenbeziehung selbstständig',
      (tester) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;

    const exercise = CurriculumExercise(
      mode: TrainingMode.advancedMeasures,
      prompt: '7 m sind wie viele cm?',
      answer: 700,
      hint: '1 m = 100 cm.',
      key: 'length:m:7',
      answerSuffix: 'cm',
      maxAnswerValue: 5000,
      method: 'Größen umwandeln',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.advancedMeasures,
          targetTasks: 1,
          targetCompetency: MicroCompetencyId.unitConversion,
          exerciseGenerator: _FixedCurriculumExerciseGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Schritt 1 von 1'), findsOneWidget);
    expect(find.text('Antwort eingeben'), findsNothing);

    await tester.tap(
      find.widgetWithText(FilledButton, '1 m = 100 cm'),
    );
    await tester.pump(const Duration(milliseconds: 400));

    final steps = controller.microObservations
        .where((entry) => entry.source == MicroEvidenceSource.independentStep)
        .toList();
    expect(steps, hasLength(1));
    expect(steps.single.id, MicroCompetencyId.unitConversion);
    expect(steps.single.correct, isTrue);
    expect(steps.single.usedHelp, isFalse);
    expect(
      steps.single.taskKey,
      'independent:unitRelation:length:m:7',
    );
    expect(find.text('Antwort eingeben'), findsOneWidget);
  });

  test('Bruchteile beobachten zuerst die Größe eines gleichen Teils', () {
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.fractions,
      taskKey: 'fraction:parts:3:4:20',
      expected: 15,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.fractionEqualParts,
    );
    final evidenceSteps = guide.steps
        .where((step) => step.recordsIntermediateEvidence)
        .toList();

    expect(guide.methodKey, 'fraction:equalParts');
    expect(evidenceSteps, hasLength(1));
    expect(evidenceSteps.single.evidenceKey, 'equalPartSize');
    expect(
      evidenceSteps.single.evidenceCompetency,
      MicroCompetencyId.fractionEqualParts,
    );
    expect(
      evidenceSteps.single.choices[evidenceSteps.single.correctChoice!],
      '5',
    );
    expect(evidenceSteps.single.evidenceWeight, 0.40);
    expect(guide.steps.last.instruction, contains('3 × 5 = 15'));
    expect(
      GuidedStepCatalog.labelFor('equalPartSize'),
      contains('gleich großen Bruchteils'),
    );

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.fractions,
      taskKey: 'fraction:parts:3:4:20',
      expected: 15,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.fractionEqualParts,
    );
    expect(independent.map((step) => step.evidenceKey), ['equalPartSize']);
  });

  test('Einfache Viertelaufgabe dupliziert die Endantwort nicht als Step', () {
    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.fractions,
      taskKey: 'fraction:quarter:20',
      expected: 5,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.fractionEqualParts,
    );

    expect(independent, isEmpty);
  });

  testWidgets('Bruchbild zeigt 3 von 4 gleich großen Teilen', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningVisualAid(
            pattern: ErrorPattern.fractionPart,
            taskKey: 'fraction:parts:3:4:20',
            expected: 15,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Bruchbild'), findsOneWidget);
    expect(
      find.text('3 von 4 gleich großen Teilen sind markiert.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'Curriculum speichert Größe eines Bruchteils selbstständig',
      (tester) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;

    const exercise = CurriculumExercise(
      mode: TrainingMode.fractions,
      prompt: 'Wie viel sind 3/4 von 20?',
      answer: 15,
      hint:
          'Teile 20 zuerst in 4 gleich große Teile. Bestimme dann den Wert von 3 Teilen.',
      key: 'fraction:parts:3:4:20',
      maxAnswerValue: 20,
      method: 'Bruchteile als gleich große Teile',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.fractions,
          targetTasks: 1,
          targetCompetency: MicroCompetencyId.fractionEqualParts,
          exerciseGenerator: _FixedCurriculumExerciseGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Schritt 1 von 1'), findsOneWidget);
    expect(find.text('Antwort eingeben'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, '5'));
    await tester.pump(const Duration(milliseconds: 400));

    final steps = controller.microObservations
        .where((entry) => entry.source == MicroEvidenceSource.independentStep)
        .toList();
    expect(steps, hasLength(1));
    expect(steps.single.id, MicroCompetencyId.fractionEqualParts);
    expect(steps.single.correct, isTrue);
    expect(steps.single.usedHelp, isFalse);
    expect(
      steps.single.taskKey,
      'independent:equalPartSize:fraction:parts:3:4:20',
    );
    expect(find.text('Antwort eingeben'), findsOneWidget);
  });

  test('Zeitspanne beobachtet den ersten Sprung bis zur vollen Stunde', () {
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.timeDurations,
      taskKey: 'duration:875:45',
      expected: 45,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.timeDuration,
    );
    final evidenceSteps = guide.steps
        .where((step) => step.recordsIntermediateEvidence)
        .toList();

    expect(evidenceSteps, hasLength(1));
    expect(evidenceSteps.single.evidenceKey, 'minutesToNextHour');
    expect(
      evidenceSteps.single.evidenceCompetency,
      MicroCompetencyId.timeDuration,
    );
    expect(
      evidenceSteps.single.choices[evidenceSteps.single.correctChoice!],
      '25',
    );
    expect(evidenceSteps.single.evidenceWeight, 0.40);
    expect(guide.nudge, contains('14:35'));
    expect(guide.nudge, contains('15:00'));
    expect(
      GuidedStepCatalog.labelFor('minutesToNextHour'),
      contains('vollen Stunde'),
    );

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.timeDurations,
      taskKey: 'duration:875:45',
      expected: 45,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.timeDuration,
    );
    expect(
      independent.map((step) => step.evidenceKey),
      ['minutesToNextHour'],
    );
  });

  test('Zeitspanne erfindet keinen Null-Schritt an voller Stunde', () {
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.timeDurations,
      taskKey: 'duration:840:45',
      expected: 45,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.timeDuration,
    );

    expect(guide.nudge, contains('schon eine volle Stunde'));
    expect(
      guide.steps.where((step) => step.recordsIntermediateEvidence),
      isEmpty,
    );
    expect(
      GuidedMethodFactory.independentWrittenStepsForTask(
        mode: TrainingMode.timeDurations,
        taskKey: 'duration:840:45',
        expected: 45,
        preferences: const MethodPreferences(),
        targetCompetency: MicroCompetencyId.timeDuration,
      ),
      isEmpty,
    );
  });

  test('Zeitspanne innerhalb einer Stunde nutzt keinen falschen Stundenstopp',
      () {
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.timeDurations,
      taskKey: 'duration:855:30',
      expected: 30,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.timeDuration,
    );

    expect(guide.nudge, contains('vor der nächsten vollen Stunde'));
    expect(
      guide.steps.where((step) => step.recordsIntermediateEvidence),
      isEmpty,
    );
  });

  testWidgets('Zeitlinie zeigt den konkreten Stundenübergang', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningVisualAid(
            pattern: ErrorPattern.timeDuration,
            taskKey: 'duration:875:45',
            expected: 45,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('14:35'), findsOneWidget);
    expect(find.text('15:00'), findsOneWidget);
    expect(find.text('15:20'), findsOneWidget);
    expect(find.text('+25 min'), findsOneWidget);
    expect(find.text('+20 min'), findsOneWidget);
    expect(find.text('volle Stunde'), findsOneWidget);
  });

  testWidgets(
      'Curriculum speichert ersten Zeitspannen-Sprung selbstständig',
      (tester) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;

    const exercise = CurriculumExercise(
      mode: TrainingMode.timeDurations,
      prompt:
          'Beginn: 14:35 Uhr\nEnde: 15:20 Uhr\nWie viele Minuten dauert es?',
      answer: 45,
      hint: 'Rechne zuerst 25 Minuten bis 15:00 Uhr und dann weiter.',
      key: 'duration:875:45',
      answerSuffix: 'min',
      maxAnswerValue: 240,
      method: 'Zeitdauer berechnen',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.timeDurations,
          targetTasks: 1,
          targetCompetency: MicroCompetencyId.timeDuration,
          exerciseGenerator: _FixedCurriculumExerciseGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Schritt 1 von 1'), findsOneWidget);
    expect(find.text('Antwort eingeben'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, '25'));
    await tester.pump(const Duration(milliseconds: 400));

    final steps = controller.microObservations
        .where((entry) => entry.source == MicroEvidenceSource.independentStep)
        .toList();
    expect(steps, hasLength(1));
    expect(steps.single.id, MicroCompetencyId.timeDuration);
    expect(steps.single.correct, isTrue);
    expect(steps.single.usedHelp, isFalse);
    expect(
      steps.single.taskKey,
      'independent:minutesToNextHour:duration:875:45',
    );
    expect(find.text('Antwort eingeben'), findsOneWidget);
  });

  test('Proportionalität beobachtet den Wert für eine Einheit getrennt', () {
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.proportionality,
      taskKey: 'proportion:notebooks:3:4:7',
      expected: 21,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.proportionalUnit,
    );
    final evidenceSteps = guide.steps
        .where((step) => step.recordsIntermediateEvidence)
        .toList();

    expect(guide.methodKey, 'proportion:unitValue');
    expect(evidenceSteps, hasLength(1));
    expect(evidenceSteps.single.evidenceKey, 'unitValue');
    expect(
      evidenceSteps.single.evidenceCompetency,
      MicroCompetencyId.proportionalUnit,
    );
    expect(
      evidenceSteps.single.choices[evidenceSteps.single.correctChoice!],
      '3',
    );
    expect(evidenceSteps.single.evidenceWeight, 0.40);
    expect(GuidedStepCatalog.labelFor('unitValue'), contains('Einheit'));

    final independent =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.proportionality,
      taskKey: 'proportion:notebooks:3:4:7',
      expected: 21,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.proportionalUnit,
    );
    expect(independent.map((step) => step.evidenceKey), ['unitValue']);
  });

  testWidgets(
      'Curriculum speichert proportionalen Einheitswert selbstständig',
      (tester) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;

    const exercise = CurriculumExercise(
      mode: TrainingMode.proportionality,
      prompt: '4 Hefte kosten 12 €. Was kosten 7 Hefte?',
      answer: 21,
      hint: 'Bestimme zuerst den Wert für 1 Einheit.',
      key: 'proportion:notebooks:3:4:7',
      answerSuffix: '€',
      maxAnswerValue: 100,
      method: 'Einfache Zuordnung',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.proportionality,
          targetTasks: 1,
          targetCompetency: MicroCompetencyId.proportionalUnit,
          exerciseGenerator: _FixedCurriculumExerciseGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Schritt 1 von 1'), findsOneWidget);
    expect(find.text('Antwort eingeben'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, '3'));
    await tester.pump(const Duration(milliseconds: 400));

    final steps = controller.microObservations
        .where((entry) => entry.source == MicroEvidenceSource.independentStep)
        .toList();
    expect(steps, hasLength(1));
    expect(steps.single.id, MicroCompetencyId.proportionalUnit);
    expect(steps.single.correct, isTrue);
    expect(steps.single.usedHelp, isFalse);
    expect(
      steps.single.taskKey,
      'independent:unitValue:proportion:notebooks:3:4:7',
    );
    expect(find.text('Antwort eingeben'), findsOneWidget);
  });

  test('Teilen-Hilfe unterscheidet gesuchte Gruppen und Gruppengröße', () {
    const cases = [
      (
        taskKey: 'story:sharing:children:12:3',
        correctChoice: 1,
      ),
      (
        taskKey: 'story:grouping:blocks:12:4',
        correctChoice: 0,
      ),
    ];

    for (final item in cases) {
      final guide = GuidedMethodFactory.forTask(
        mode: TrainingMode.wordProblems,
        taskKey: item.taskKey,
        expected: 4,
        preferences: const MethodPreferences(),
        targetCompetency: MicroCompetencyId.divisionSharing,
      );
      final evidenceSteps = guide.steps
          .where((step) => step.recordsIntermediateEvidence)
          .toList();

      expect(evidenceSteps, hasLength(1), reason: item.taskKey);
      expect(evidenceSteps.single.evidenceKey, 'divisionTargetQuantity');
      expect(
        evidenceSteps.single.evidenceCompetency,
        MicroCompetencyId.divisionSharing,
      );
      expect(evidenceSteps.single.correctChoice, item.correctChoice);
      expect(
        GuidedStepCatalog.labelFor('divisionTargetQuantity'),
        contains('gesuchte Größe'),
      );
    }
  });

  test('Sachaufgaben-Hilfe beobachtet die fünf Modellierungsschritte getrennt',
      () {
    const cases = [
      (
        taskKey: 'story:info:trip:5:2:3',
        competency: MicroCompetencyId.wordProblemRelevantInformation,
        stepKey: 'storyInfo',
      ),
      (
        taskKey: 'story:operation:-:9:4',
        competency: MicroCompetencyId.wordProblemOperation,
        stepKey: 'storyOperation',
      ),
      (
        taskKey: 'story:equation:+:7:5',
        competency: MicroCompetencyId.wordProblemModel,
        stepKey: 'storyEquation',
      ),
      (
        taskKey: 'story:calc:x:4:3',
        competency: MicroCompetencyId.wordProblemCalculation,
        stepKey: 'storyCalculation',
      ),
      (
        taskKey: 'story:interpret:+:7:5:12',
        competency: MicroCompetencyId.wordProblemInterpretation,
        stepKey: 'storyInterpretation',
      ),
    ];

    for (final item in cases) {
      final guide = GuidedMethodFactory.forTask(
        mode: TrainingMode.wordProblems,
        taskKey: item.taskKey,
        expected: 0,
        preferences: const MethodPreferences(),
        targetCompetency: item.competency,
      );
      final evidenceSteps = guide.steps
          .where((step) => step.recordsIntermediateEvidence)
          .toList();

      expect(evidenceSteps, hasLength(1), reason: item.taskKey);
      expect(evidenceSteps.single.evidenceKey, item.stepKey);
      expect(evidenceSteps.single.evidenceCompetency, item.competency);
      expect(
        evidenceSteps.single.correctChoice,
        inInclusiveRange(0, evidenceSteps.single.choices.length - 1),
      );
      expect(
        GuidedStepCatalog.labelFor(item.stepKey),
        isNot(item.stepKey),
      );
    }
  });

  testWidgets(
      'Structured Training speichert ersten Sachaufgaben-Teilschritt eigenständig',
      (tester) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.first;
    controller.numberRange = NumberRangeLevel.twenty;

    await tester.pumpWidget(
      MaterialApp(
        home: StructuredTrainingScreen(
          controller: controller,
          mode: TrainingMode.wordProblems,
          targetTasks: 1,
          targetCompetency: MicroCompetencyId.wordProblemOperation,
        ),
      ),
    );
    await tester.pump();

    final answerButtons = find.byType(FilledButton);
    expect(answerButtons, findsWidgets);
    await tester.tap(answerButtons.first);
    await tester.pump();

    final steps = controller.microObservations
        .where((entry) => entry.source == MicroEvidenceSource.independentStep)
        .toList();
    expect(steps, hasLength(1));
    expect(steps.single.id, MicroCompetencyId.wordProblemOperation);
    expect(steps.single.usedHelp, isFalse);
    expect(
      steps.single.taskKey,
      startsWith('independent:storyOperation:story:operation:'),
    );
    await tester.pump(const Duration(milliseconds: 600));
  });

  test(
      'Geteilt-Grundaufgabe prüft die Mal-Umkehraufgabe ohne Quotienten-Leak',
      () {
    final fact = MathFact(
      a: 42,
      b: 6,
      operation: MathOperation.divide,
    );

    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.divide,
      taskKey: fact.key,
      expected: fact.result,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.divisionFacts,
      fact: fact,
    );

    expect(guide.methodKey, 'division:inverseMultiplication');
    final evidenceStep =
        guide.steps.where((step) => step.recordsIntermediateEvidence).single;
    expect(evidenceStep.evidenceKey, 'matchingMultiplicationFact');
    expect(evidenceStep.evidenceCompetency, MicroCompetencyId.divisionFacts);
    expect(evidenceStep.evidenceWeight, 0.40);
    expect(
      evidenceStep.choices[evidenceStep.correctChoice!],
      '6 × ? = 42',
    );
    expect(evidenceStep.choices, hasLength(4));
    expect(evidenceStep.choices.toSet(), hasLength(4));
    expect(evidenceStep.choices.every((choice) => choice.contains('?')), isTrue);
    expect(guide.nudge, isNot(contains('7')));
    expect(
      guide.steps.map((step) => step.instruction).join(' '),
      isNot(contains('= 7')),
    );

    final independent =
        GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: TrainingMode.divide,
      fact: fact,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.divisionFacts,
    );
    expect(independent, hasLength(1));
    expect(independent.single.evidenceKey, 'matchingMultiplicationFact');

    final untargeted =
        GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: TrainingMode.divide,
      fact: fact,
      preferences: const MethodPreferences(),
    );
    expect(untargeted, isEmpty);
  });

  test('Umkehraufgaben-Hilfe diagnostiziert zuerst die Gegenoperation', () {
    const cases = [
      (
        key: 'family:+:7:5',
        expected: 7,
        correct: '−5',
        source: '+5',
      ),
      (
        key: 'family:x:6:4',
        expected: 6,
        correct: '÷4',
        source: '×4',
      ),
    ];

    for (final item in cases) {
      final guide = GuidedMethodFactory.forTask(
        mode: TrainingMode.factFamilies,
        taskKey: item.key,
        expected: item.expected,
        preferences: const MethodPreferences(),
        targetCompetency: MicroCompetencyId.inverseRelationship,
      );

      expect(guide.methodKey, 'inverse:operationRelationship');
      expect(guide.nudge, isNot(contains(item.correct)));
      final evidenceStep =
          guide.steps.where((step) => step.recordsIntermediateEvidence).single;
      expect(evidenceStep.evidenceKey, 'inverseOperationChoice');
      expect(
        evidenceStep.evidenceCompetency,
        MicroCompetencyId.inverseRelationship,
      );
      expect(evidenceStep.evidenceWeight, 0.40);
      expect(evidenceStep.question, contains(item.source));
      expect(
        evidenceStep.choices[evidenceStep.correctChoice!],
        item.correct,
      );
      expect(evidenceStep.choices.toSet(), hasLength(2));
    }
  });


  test('Zahlenmauer-Hilfe trennt Rechenrichtung vom Ausrechnen', () {
    const cases = [
      (
        key: 'wall:2-3-1-5-4-9:0',
        expected: 2,
        correct: 'Minus (−)',
        calculation: '5 − 3 = ?',
      ),
      (
        key: 'wall:2-3-1-5-4-9:4',
        expected: 4,
        correct: 'Plus (+)',
        calculation: '3 + 1 = ?',
      ),
      (
        key: 'wall:2-3-1-5-4-9:5',
        expected: 9,
        correct: 'Plus (+)',
        calculation: '5 + 4 = ?',
      ),
    ];

    for (final item in cases) {
      final guide = GuidedMethodFactory.forTask(
        mode: TrainingMode.numberWall,
        taskKey: item.key,
        expected: item.expected,
        preferences: const MethodPreferences(),
        targetCompetency: MicroCompetencyId.numberRelations,
      );

      expect(guide.methodKey, 'numberWall:relationDirection');
      final evidenceStep =
          guide.steps.where((step) => step.recordsIntermediateEvidence).single;
      expect(evidenceStep.evidenceKey, 'wallOperationChoice');
      expect(
        evidenceStep.evidenceCompetency,
        MicroCompetencyId.numberRelations,
      );
      expect(evidenceStep.evidenceWeight, 0.40);
      expect(evidenceStep.choices.toSet(), {'Plus (+)', 'Minus (−)'});
      expect(
        evidenceStep.choices[evidenceStep.correctChoice!],
        item.correct,
      );
      expect(guide.steps.last.instruction, contains(item.calculation));
    }
  });

  test('Geld-Hilfe trennt Rechenplan vom Ausrechnen', () {
    const cases = [
      (
        key: 'money:add:school:7:5',
        expected: 12,
        correct: 'Plus (+)',
      ),
      (
        key: 'money:change:kiosk:12:5',
        expected: 7,
        correct: 'Minus (−)',
      ),
      (
        key: 'money:missing:item:12:5',
        expected: 7,
        correct: 'Minus (−)',
      ),
    ];

    for (final item in cases) {
      final guide = GuidedMethodFactory.forTask(
        mode: TrainingMode.money,
        taskKey: item.key,
        expected: item.expected,
        preferences: const MethodPreferences(),
        targetCompetency: MicroCompetencyId.moneyCalculation,
      );

      expect(guide.methodKey, 'money:calculationPlan');
      final evidenceStep =
          guide.steps.where((step) => step.recordsIntermediateEvidence).single;
      expect(evidenceStep.evidenceKey, 'moneyOperationChoice');
      expect(
        evidenceStep.evidenceCompetency,
        MicroCompetencyId.moneyCalculation,
      );
      expect(evidenceStep.evidenceWeight, 0.40);
      expect(evidenceStep.choices.toSet(), {'Plus (+)', 'Minus (−)'});
      expect(
        evidenceStep.choices[evidenceStep.correctChoice!],
        item.correct,
      );
    }
  });

  test('Geldumwandlung behält eine eigene schulische Hilfe ohne Step-Evidenz',
      () {
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.money,
      taskKey: 'money:convert:euro-cent:4',
      expected: 400,
      preferences: const MethodPreferences(),
    );

    expect(guide.methodKey, 'money:representAndCalculate');
    expect(
      guide.steps.where((step) => step.recordsIntermediateEvidence),
      isEmpty,
    );
    expect(
      guide.steps.any((step) => step.instruction.contains('1 € = 100 ct')),
      isTrue,
    );
  });
  test('Hilfen bieten mehrere Rechenwege ohne Schulmethode zu verändern', () {
    const preferences = MethodPreferences(
      subtraction: SubtractionStrategy.bridgeToTen,
      selectionPreference: MethodSelectionPreference.schoolMethod,
    );
    final fact = MathFact(a: 43, b: 18, operation: MathOperation.minus);

    final alternatives = GuidedMethodFactory.alternativesForTask(
      mode: TrainingMode.minus,
      taskKey: fact.key,
      expected: 25,
      preferences: preferences,
      fact: fact,
    );

    expect(
      alternatives.map((guide) => guide.methodLabel).toSet(),
      {'Erst zum Zehner', 'Schrittweise wegnehmen', 'Ergänzen'},
    );
    expect(preferences.subtraction, SubtractionStrategy.bridgeToTen);
    expect(
      preferences.selectionPreference,
      MethodSelectionPreference.schoolMethod,
    );
  });

  test('Schrittweise wegnehmen zerlegt 43 minus 18 schulnah', () {
    final fact = MathFact(a: 43, b: 18, operation: MathOperation.minus);
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.minus,
      taskKey: fact.key,
      expected: 25,
      preferences: const MethodPreferences(
        subtraction: SubtractionStrategy.takeAway,
      ),
      fact: fact,
    );

    expect(guide.nudge, contains('10 + 3 + 5'));
    expect(guide.steps[0].instruction, 'Rechne jetzt 43 − 10.');
    expect(guide.steps[1].instruction, 'Rechne jetzt 33 − 3.');
    expect(guide.steps[2].instruction, 'Rechne jetzt 30 − 5.');
    expect(guide.steps[2].choices[guide.steps[2].correctChoice!], '25');
  });

  test('Ergänzen führt 18 über volle Zehner kleinschrittig zu 43', () {
    final fact = MathFact(a: 43, b: 18, operation: MathOperation.minus);
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.minus,
      taskKey: fact.key,
      expected: 25,
      preferences: const MethodPreferences(
        subtraction: SubtractionStrategy.complement,
      ),
      fact: fact,
    );

    expect(guide.steps[0].instruction, 'Ergänze von 18 bis 20.');
    expect(guide.steps[0].choices[guide.steps[0].correctChoice!], '2');
    expect(guide.steps[1].instruction, 'Ergänze von 20 bis 40.');
    expect(guide.steps[1].choices[guide.steps[1].correctChoice!], '20');
    expect(guide.steps[2].instruction, 'Ergänze von 40 bis 43.');
    expect(guide.steps[2].choices[guide.steps[2].correctChoice!], '3');
    expect(guide.steps.last.instruction, '2 + 20 + 3 = 25.');
  });

  testWidgets('Kind kann den Rechenweg direkt in der Hilfe wechseln',
      (tester) async {
    final fact = MathFact(a: 13, b: 5, operation: MathOperation.minus);
    const preferences = MethodPreferences(
      subtraction: SubtractionStrategy.bridgeToTen,
    );
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.minus,
      taskKey: fact.key,
      expected: 8,
      preferences: preferences,
      fact: fact,
    );
    final alternatives = GuidedMethodFactory.alternativesForTask(
      mode: TrainingMode.minus,
      taskKey: fact.key,
      expected: 8,
      preferences: preferences,
      fact: fact,
    );
    GuidedMethodGuide? chosen;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GuidedMethodPanel(
              guide: guide,
              alternativeGuides: alternatives,
              pattern: ErrorPattern.tenBridge,
              taskKey: fact.key,
              expected: 8,
              initialLevel: HelpLevel.guided,
              onHelpLevelChanged: (_) {},
              onGuideChanged: (value) => chosen = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('3 Schritt für Schritt'), findsOneWidget);
    await tester.tap(find.byKey(
      const ValueKey('guided-method-choice:subtraction:bridgeToTen'),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ergänzen').last);
    await tester.pumpAndSettle();

    expect(chosen?.methodKey, 'subtraction:complement');
    expect(find.text('Rechenweg: Ergänzen'), findsOneWidget);
  });


  test('Hilfen bieten auch Mal- und schriftliche Minus-Alternativen', () {
    final multiplication = MathFact(
      a: 6,
      b: 7,
      operation: MathOperation.multiply,
    );
    final multiplyGuides = GuidedMethodFactory.alternativesForTask(
      mode: TrainingMode.multiply,
      taskKey: multiplication.key,
      expected: 42,
      preferences: const MethodPreferences(),
      fact: multiplication,
    );
    expect(
      multiplyGuides.map((guide) => guide.methodLabel).toSet(),
      {'Gleich große Gruppen', 'Zerlegen', 'Nachbaraufgaben'},
    );

    final writtenGuides = GuidedMethodFactory.alternativesForTask(
      mode: TrainingMode.writtenAddSub,
      taskKey: 'written:-:402:187',
      expected: 215,
      preferences: const MethodPreferences(),
    );
    expect(
      writtenGuides.map((guide) => guide.methodLabel).toSet(),
      {'Entbündeln', 'Ergänzungsverfahren'},
    );
  });

}

class _FixedCurriculumExerciseGenerator extends CurriculumExerciseGenerator {
  _FixedCurriculumExerciseGenerator(this.exercise);

  final CurriculumExercise exercise;

  @override
  CurriculumExercise generate({
    required TrainingMode mode,
    required GradeLevel gradeLevel,
    required int maxValue,
    Iterable<String> recentKeys = const <String>[],
    MicroCompetencyId? targetCompetency,
  }) =>
      exercise;





}
