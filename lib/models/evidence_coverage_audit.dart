import 'guided_method.dart';
import 'micro_competency.dart';
import 'remediation_path.dart';
import 'training.dart';

enum EvidenceCoverageDepth {
  fullTaskOnly,
  guidedStep,
  independentStep,
  targetedRecovery,
}

extension EvidenceCoverageDepthX on EvidenceCoverageDepth {
  String get label => switch (this) {
        EvidenceCoverageDepth.fullTaskOnly => 'nur Gesamtaufgabe',
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
    required this.guidedStepKeys,
    required this.independentStepKeys,
    required this.recoveryStepKeys,
  });

  final MicroCompetencyDefinition definition;
  final bool fullTaskIndependent;
  final bool helpAware;
  final bool delayedReview;
  final bool transferEvidence;
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
    return EvidenceCoverageDepth.fullTaskOnly;
  }

  bool get masteryEvidenceReachable =>
      fullTaskIndependent && delayedReview && transferEvidence;

  bool get internallyConsistent =>
      independentStepKeys.every(guidedStepKeys.contains) &&
      recoveryStepKeys.every(independentStepKeys.contains);
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

  int get fullTaskOnlyCount =>
      count(EvidenceCoverageDepth.fullTaskOnly);
  int get guidedStepCount => count(EvidenceCoverageDepth.guidedStep);
  int get independentStepCount =>
      count(EvidenceCoverageDepth.independentStep);
  int get targetedRecoveryCount =>
      count(EvidenceCoverageDepth.targetedRecovery);

  List<EvidenceCoverageItem> get fineGrainedGaps => items
      .where((item) => !item.hasIndependentStep)
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
  static const Map<MicroCompetencyId, List<String>> _guidedSteps = {
    MicroCompetencyId.numberDecomposition: [
      'remainingAddend',
      'remainingSubtrahend',
      'firstPartialSubtraction',
    ],
    MicroCompetencyId.placeValueDigits: [
      'onesDigit',
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
