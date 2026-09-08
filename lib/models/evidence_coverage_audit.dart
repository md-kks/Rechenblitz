import 'guided_method.dart';
import 'micro_competency.dart';
import 'remediation_path.dart';
import 'training.dart';

enum EvidenceCoverageDepth {
  atomicFullTask,
  fullTaskOnly,
  guidedStep,
  independentStep,
  targetedRecovery,
}

extension EvidenceCoverageDepthX on EvidenceCoverageDepth {
  String get label => switch (this) {
        EvidenceCoverageDepth.atomicFullTask =>
          'atomare Gesamtaufgabe',
        EvidenceCoverageDepth.fullTaskOnly =>
          'noch ohne sinnvollen Zwischenschritt',
        EvidenceCoverageDepth.guidedStep => 'geführter Zwischenschritt',
        EvidenceCoverageDepth.independentStep =>
          'selbstständiger Zwischenschritt',
        EvidenceCoverageDepth.targetedRecovery =>
          'selbstständiger Zwischenschritt mit gezielter Recovery',
      };
}

class EvidenceCoverageItem {
  const EvidenceCoverageItem({
    required this.definition,
    required this.fullTaskIndependent,
    required this.helpAware,
    required this.delayedReview,
    required this.transferEvidence,
    required this.atomicFullTask,
    required this.atomicReason,
    required this.guidedStepKeys,
    required this.independentStepKeys,
    required this.recoveryStepKeys,
  });

  final MicroCompetencyDefinition definition;
  final bool fullTaskIndependent;
  final bool helpAware;
  final bool delayedReview;
  final bool transferEvidence;
  final bool atomicFullTask;
  final String? atomicReason;
  final List<String> guidedStepKeys;
  final List<String> independentStepKeys;
  final List<String> recoveryStepKeys;

  bool get hasGuidedStep => guidedStepKeys.isNotEmpty;
  bool get hasIndependentStep => independentStepKeys.isNotEmpty;
  bool get hasTargetedRecovery => recoveryStepKeys.isNotEmpty;

  EvidenceCoverageDepth get depth {
    if (hasTargetedRecovery) {
      return EvidenceCoverageDepth.targetedRecovery;
    }
    if (hasIndependentStep) {
      return EvidenceCoverageDepth.independentStep;
    }
    if (hasGuidedStep) {
      return EvidenceCoverageDepth.guidedStep;
    }
    if (atomicFullTask) {
      return EvidenceCoverageDepth.atomicFullTask;
    }
    return EvidenceCoverageDepth.fullTaskOnly;
  }

  bool get masteryEvidenceReachable =>
      fullTaskIndependent && delayedReview && transferEvidence;

  bool get internallyConsistent =>
      independentStepKeys.every(guidedStepKeys.contains) &&
      recoveryStepKeys.every(independentStepKeys.contains) &&
      (!atomicFullTask ||
          (!hasGuidedStep &&
              atomicReason != null &&
              atomicReason!.trim().isNotEmpty));
}

class EvidenceCoverageAuditSummary {
  const EvidenceCoverageAuditSummary({
    required this.grade,
    required this.items,
  });

  final GradeLevel grade;
  final List<EvidenceCoverageItem> items;

  int get total => items.length;

  int count(EvidenceCoverageDepth depth) =>
      items.where((item) => item.depth == depth).length;

  int get atomicFullTaskCount =>
      count(EvidenceCoverageDepth.atomicFullTask);
  int get fullTaskOnlyCount =>
      count(EvidenceCoverageDepth.fullTaskOnly);
  int get guidedStepCount => count(EvidenceCoverageDepth.guidedStep);
  int get independentStepCount =>
      count(EvidenceCoverageDepth.independentStep);
  int get targetedRecoveryCount =>
      count(EvidenceCoverageDepth.targetedRecovery);

  List<EvidenceCoverageItem> get atomicFullTasks => items
      .where((item) => item.depth == EvidenceCoverageDepth.atomicFullTask)
      .toList(growable: false);

  List<EvidenceCoverageItem> get fineGrainedGaps => items
      .where((item) => item.depth == EvidenceCoverageDepth.fullTaskOnly)
      .toList(growable: false);

  List<EvidenceCoverageItem> get guidedOnlyGaps => items
      .where(
        (item) => item.hasGuidedStep && !item.hasIndependentStep,
      )
      .toList(growable: false);

  bool get coreEvidenceComplete => items.every(
        (item) =>
            item.fullTaskIndependent &&
            item.helpAware &&
            item.delayedReview &&
            item.transferEvidence,
      );

  bool get internallyConsistent =>
      items.every((item) => item.internallyConsistent);
}

abstract final class EvidenceCoverageAuditCatalog {
  static const Map<MicroCompetencyId, String> _atomicFullTaskReasons = {
    MicroCompetencyId.countingNeighbors:
        'Vorgänger oder Nachfolger ist die direkte Zielbeobachtung; ein vorgeschalteter Pflichtschritt würde dieselbe Information erneut abfragen.',
    MicroCompetencyId.additionNoBridge:
        'Eine Plus-Grundaufgabe ohne Übergang ist bereits ein einzelner Rechenschritt und soll nicht künstlich zerlegt werden.',
    MicroCompetencyId.subtractionNoBridge:
        'Eine Minus-Grundaufgabe ohne Übergang ist bereits ein einzelner Rechenschritt und soll nicht künstlich zerlegt werden.',
    MicroCompetencyId.shapeProperties:
        'Formname oder einzelne Eigenschaft wird direkt am Bild erkannt; generische Vorfragen wären redundant oder würden die Endantwort verraten.',
    MicroCompetencyId.representationTranslation:
        'Die Übersetzung zwischen zwei Darstellungen ist selbst der Zielprozess; ihre inhaltlichen Bestandteile werden bereits durch Stellenwert- oder Gruppenkompetenzen separat beobachtet.',
    MicroCompetencyId.lineRelations:
        'Parallel oder senkrecht ist die direkte Lagebeziehung; Schnitt- oder Winkelvorfragen bestimmen die Endantwort bereits.',
    MicroCompetencyId.circleParts:
        'Radius und Durchmesser werden unmittelbar über ihre Lage zum Mittelpunkt unterschieden; ein zusätzlicher Pflichtschritt würde die Lösung vorwegnehmen.',
    MicroCompetencyId.geometryBodies:
        'Körpermerkmale wie Ecken, Kanten und Flächen sind direkte Wissensbeobachtungen; komplexes Würfelnetz-Falten besitzt bereits eine eigene tief diagnostizierte Kompetenz.',
  };

  static const Map<MicroCompetencyId, List<String>> _guidedSteps = {
    MicroCompetencyId.numberDecomposition: [
      'remainingAddend',
      'remainingSubtrahend',
      'firstPartialSubtraction',
    ],
    MicroCompetencyId.placeValueDigits: [
      'onesDigit',
    ],
    MicroCompetencyId.largeNumberCompare: [
      'decidingPlace',
    ],
    MicroCompetencyId.largeNumberOrder: [
      'smallestOrderedNumber',
    ],
    MicroCompetencyId.numberWordReading: [
      'numberWordTensOnes',
    ],
    MicroCompetencyId.placeValueDecompose: [
      'placeValueContribution',
    ],
    MicroCompetencyId.strategyChoice: [
      'gapToAnchor',
    ],
    MicroCompetencyId.mentalStrategy: [
      'firstMentalChunk',
    ],
    MicroCompetencyId.arithmeticLaw: [
      'lawStructureChoice',
    ],
    MicroCompetencyId.reasoningJustification: [
      'reasoningRelationType',
    ],
    MicroCompetencyId.plausibilityCheck: [
      'referenceEstimate',
    ],
    MicroCompetencyId.estimation: [
      'roundedSummands',
    ],
    MicroCompetencyId.errorChecking: [
      'errorPlace',
    ],
    MicroCompetencyId.roundingPlace: [
      'roundingDecisionDigit',
    ],
    MicroCompetencyId.clockReading: [
      'minuteHandMinutes',
    ],
    MicroCompetencyId.numberPatterns: [
      'sequenceStepSize',
    ],
    MicroCompetencyId.additionTenBridge: [
      'bridgeAmount',
    ],
    MicroCompetencyId.subtractionTenBridge: [
      'bridgeAmount',
      'firstComplementJump',
      'secondComplementJump',
    ],
    MicroCompetencyId.multiplicationGroups: [
      'groupCount',
      'itemsPerGroup',
      'partialGroups',
    ],
    MicroCompetencyId.multiplicationFacts: [
      'firstPartialProduct',
      'secondPartialProduct',
      'anchorFact',
    ],
    MicroCompetencyId.divisionSharing: [
      'divisionTargetQuantity',
    ],
    MicroCompetencyId.divisionFacts: [
      'matchingMultiplicationFact',
    ],
    MicroCompetencyId.inverseRelationship: [
      'inverseOperationChoice',
    ],
    MicroCompetencyId.numberRelations: [
      'wallOperationChoice',
    ],
    MicroCompetencyId.moneyCalculation: [
      'moneyOperationChoice',
    ],
    MicroCompetencyId.measurementCalculation: [
      'measureOperationChoice',
    ],
    MicroCompetencyId.doublesHalves: [
      'doubleHalfMeaning',
    ],
    MicroCompetencyId.proportionalUnit: [
      'unitValue',
    ],
    MicroCompetencyId.perimeter: [
      'perimeterEdges',
    ],
    MicroCompetencyId.area: [
      'areaUnitSquareStructure',
    ],
    MicroCompetencyId.tallyTableReading: [
      'tallyFiveBlocks',
    ],
    MicroCompetencyId.dataReading: [
      'chartValuesRead',
    ],
    MicroCompetencyId.probabilityReasoning: [
      'chanceCountRelation',
    ],
    MicroCompetencyId.combinatoricsSystematic: [
      'comboFirstBranchCount',
    ],
    MicroCompetencyId.calendarDate: [
      'calendarWeekRemainder',
    ],
    MicroCompetencyId.dataRepresentationChoice: [
      'representationPurpose',
    ],
    MicroCompetencyId.volumeCubes: [
      'volumeLayerCount',
    ],
    MicroCompetencyId.romanNumeral: [
      'romanTensBlockValue',
    ],
    MicroCompetencyId.probabilityExperiment: [
      'observedFrequencyRelation',
    ],
    MicroCompetencyId.scale: [
      'scaleOperationChoice',
    ],
    MicroCompetencyId.planDirections: [
      'firstRouteSegment',
    ],
    MicroCompetencyId.rightAngle: [
      'angleReferenceRelation',
    ],
    MicroCompetencyId.figureClassification: [
      'figureSideFamily',
    ],
    MicroCompetencyId.symmetryAxes: [
      'candidateSymmetryAxis',
    ],
    MicroCompetencyId.cubeNetFoldability: [
      'cubeNetLocalFaceRelation',
    ],
    MicroCompetencyId.unitConversion: [
      'unitRelation',
    ],
    MicroCompetencyId.secondsConversion: [
      'minuteSecondRelation',
    ],
    MicroCompetencyId.fractionEqualParts: [
      'equalPartSize',
    ],
    MicroCompetencyId.timeDuration: [
      'minutesToNextHour',
    ],
    MicroCompetencyId.writtenAlignment: [
      'onesAlignment',
    ],
    MicroCompetencyId.writtenRegrouping: [
      'regroupDecision',
      'carryDecision',
    ],
    MicroCompetencyId.writtenMultiplyProcedure: [
      'firstPartialProduct',
      'multiplicationCarry',
      'nextMultiplierDigit',
    ],
    MicroCompetencyId.writtenDivideProcedure: [
      'firstQuotientDigit',
      'firstDivisionRemainder',
    ],
    MicroCompetencyId.wordProblemRelevantInformation: [
      'storyInfo',
    ],
    MicroCompetencyId.wordProblemOperation: [
      'storyOperation',
    ],
    MicroCompetencyId.wordProblemModel: [
      'storyEquation',
    ],
    MicroCompetencyId.wordProblemCalculation: [
      'storyCalculation',
    ],
    MicroCompetencyId.wordProblemInterpretation: [
      'storyInterpretation',
    ],
  };

  static const Map<MicroCompetencyId, List<String>> _independentSteps = {
    MicroCompetencyId.numberDecomposition: [
      'remainingAddend',
      'remainingSubtrahend',
      'firstPartialSubtraction',
    ],
    MicroCompetencyId.placeValueDigits: [
      'onesDigit',
    ],
    MicroCompetencyId.largeNumberCompare: [
      'decidingPlace',
    ],
    MicroCompetencyId.largeNumberOrder: [
      'smallestOrderedNumber',
    ],
    MicroCompetencyId.numberWordReading: [
      'numberWordTensOnes',
    ],
    MicroCompetencyId.placeValueDecompose: [
      'placeValueContribution',
    ],
    MicroCompetencyId.strategyChoice: [
      'gapToAnchor',
    ],
    MicroCompetencyId.mentalStrategy: [
      'firstMentalChunk',
    ],
    MicroCompetencyId.arithmeticLaw: [
      'lawStructureChoice',
    ],
    MicroCompetencyId.reasoningJustification: [
      'reasoningRelationType',
    ],
    MicroCompetencyId.plausibilityCheck: [
      'referenceEstimate',
    ],
    MicroCompetencyId.estimation: [
      'roundedSummands',
    ],
    MicroCompetencyId.errorChecking: [
      'errorPlace',
    ],
    MicroCompetencyId.roundingPlace: [
      'roundingDecisionDigit',
    ],
    MicroCompetencyId.clockReading: [
      'minuteHandMinutes',
    ],
    MicroCompetencyId.numberPatterns: [
      'sequenceStepSize',
    ],
    MicroCompetencyId.additionTenBridge: [
      'bridgeAmount',
    ],
    MicroCompetencyId.subtractionTenBridge: [
      'bridgeAmount',
      'firstComplementJump',
      'secondComplementJump',
    ],
    MicroCompetencyId.multiplicationGroups: [
      'groupCount',
      'itemsPerGroup',
    ],
    MicroCompetencyId.multiplicationFacts: [
      'firstPartialProduct',
      'secondPartialProduct',
      'anchorFact',
    ],
    MicroCompetencyId.divisionSharing: [
      'divisionTargetQuantity',
    ],
    MicroCompetencyId.divisionFacts: [
      'matchingMultiplicationFact',
    ],
    MicroCompetencyId.inverseRelationship: [
      'inverseOperationChoice',
    ],
    MicroCompetencyId.numberRelations: [
      'wallOperationChoice',
    ],
    MicroCompetencyId.moneyCalculation: [
      'moneyOperationChoice',
    ],
    MicroCompetencyId.measurementCalculation: [
      'measureOperationChoice',
    ],
    MicroCompetencyId.doublesHalves: [
      'doubleHalfMeaning',
    ],
    MicroCompetencyId.proportionalUnit: [
      'unitValue',
    ],
    MicroCompetencyId.perimeter: [
      'perimeterEdges',
    ],
    MicroCompetencyId.area: [
      'areaUnitSquareStructure',
    ],
    MicroCompetencyId.tallyTableReading: [
      'tallyFiveBlocks',
    ],
    MicroCompetencyId.dataReading: [
      'chartValuesRead',
    ],
    MicroCompetencyId.probabilityReasoning: [
      'chanceCountRelation',
    ],
    MicroCompetencyId.combinatoricsSystematic: [
      'comboFirstBranchCount',
    ],
    MicroCompetencyId.calendarDate: [
      'calendarWeekRemainder',
    ],
    MicroCompetencyId.dataRepresentationChoice: [
      'representationPurpose',
    ],
    MicroCompetencyId.volumeCubes: [
      'volumeLayerCount',
    ],
    MicroCompetencyId.romanNumeral: [
      'romanTensBlockValue',
    ],
    MicroCompetencyId.probabilityExperiment: [
      'observedFrequencyRelation',
    ],
    MicroCompetencyId.scale: [
      'scaleOperationChoice',
    ],
    MicroCompetencyId.planDirections: [
      'firstRouteSegment',
    ],
    MicroCompetencyId.rightAngle: [
      'angleReferenceRelation',
    ],
    MicroCompetencyId.figureClassification: [
      'figureSideFamily',
    ],
    MicroCompetencyId.symmetryAxes: [
      'candidateSymmetryAxis',
    ],
    MicroCompetencyId.cubeNetFoldability: [
      'cubeNetLocalFaceRelation',
    ],
    MicroCompetencyId.unitConversion: [
      'unitRelation',
    ],
    MicroCompetencyId.secondsConversion: [
      'minuteSecondRelation',
    ],
    MicroCompetencyId.fractionEqualParts: [
      'equalPartSize',
    ],
    MicroCompetencyId.timeDuration: [
      'minutesToNextHour',
    ],
    MicroCompetencyId.writtenAlignment: [
      'onesAlignment',
    ],
    MicroCompetencyId.writtenRegrouping: [
      'regroupDecision',
      'carryDecision',
    ],
    MicroCompetencyId.writtenMultiplyProcedure: [
      'firstPartialProduct',
      'multiplicationCarry',
      'nextMultiplierDigit',
    ],
    MicroCompetencyId.writtenDivideProcedure: [
      'firstQuotientDigit',
      'firstDivisionRemainder',
    ],
    MicroCompetencyId.wordProblemRelevantInformation: [
      'storyInfo',
    ],
    MicroCompetencyId.wordProblemOperation: [
      'storyOperation',
    ],
    MicroCompetencyId.wordProblemModel: [
      'storyEquation',
    ],
    MicroCompetencyId.wordProblemCalculation: [
      'storyCalculation',
    ],
    MicroCompetencyId.wordProblemInterpretation: [
      'storyInterpretation',
    ],
  };

  static EvidenceCoverageItem forDefinition(
    MicroCompetencyDefinition definition,
  ) {
    final guided =
        _guidedSteps[definition.id] ?? const <String>[];
    final independent =
        _independentSteps[definition.id] ?? const <String>[];
    final recovery = independent
        .where(StepRecoveryGenerator.supports)
        .toList(growable: false);
    final atomicReason = _atomicFullTaskReasons[definition.id];

    return EvidenceCoverageItem(
      definition: definition,
      // Every curriculum objective is exercised through the normal task
      // screens. Release-readiness tests verify targeted generation.
      fullTaskIndependent: true,
      // All normal task screens preserve first-attempt help state.
      helpAware: true,
      // Review scheduling is generic at micro-competency level.
      delayedReview: true,
      // Transfer scheduling is generic; arithmetic targets receive
      // contextual story transfer, other targets use a changed task in
      // their preferred learning mode.
      transferEvidence: true,
      atomicFullTask: atomicReason != null,
      atomicReason: atomicReason,
      guidedStepKeys: List.unmodifiable(guided),
      independentStepKeys: List.unmodifiable(independent),
      recoveryStepKeys: List.unmodifiable(recovery),
    );
  }

  static EvidenceCoverageAuditSummary audit(GradeLevel grade) {
    final items = MicroCompetencyCatalog.forGrade(grade)
        .map(forDefinition)
        .toList(growable: false);
    return EvidenceCoverageAuditSummary(
      grade: grade,
      items: items,
    );
  }

  static EvidenceCoverageItem item(MicroCompetencyId id) =>
      forDefinition(MicroCompetencyCatalog.definition(id));

  static Set<String> get declaredGuidedStepKeys => {
        for (final keys in _guidedSteps.values) ...keys,
      };

  static Set<String> get declaredIndependentStepKeys => {
        for (final keys in _independentSteps.values) ...keys,
      };

  static Set<String> get recoverableDeclaredStepKeys => {
        for (final key in declaredIndependentStepKeys)
          if (StepRecoveryGenerator.supports(key)) key,
      };

  static bool get declaredStepKeysAreKnown =>
      declaredGuidedStepKeys.every(GuidedStepCatalog.labels.containsKey) &&
      declaredIndependentStepKeys.every(
        GuidedStepCatalog.labels.containsKey,
      );
}
