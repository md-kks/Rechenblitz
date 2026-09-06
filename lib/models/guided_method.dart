import 'dart:math';

import 'german_number_words.dart';
import 'learning_methods.dart';
import 'math_fact.dart';
import 'micro_competency.dart';
import 'training.dart';

enum HelpLevel { none, nudge, visual, guided }

abstract final class ScaffoldFadingPolicy {
  static HelpLevel? initialLevelForTask(
    int completedTasks, {
    required bool enabled,
  }) {
    if (!enabled) return null;
    return switch (completedTasks) {
      0 => HelpLevel.visual,
      1 => HelpLevel.nudge,
      _ => null,
    };
  }
}

abstract final class IndependentArithmeticStepPolicy {
  static bool shouldProbeTask(
    int completedTasks, {
    required bool scaffoldFading,
  }) =>
      scaffoldFading
          ? completedTasks >= 2 && completedTasks < 4
          : completedTasks < 2;
}

extension HelpLevelX on HelpLevel {
  int get value => index;

  String get label => switch (this) {
        HelpLevel.none => 'Ohne Hilfe',
        HelpLevel.nudge => 'Denkhinweis',
        HelpLevel.visual => 'Darstellung',
        HelpLevel.guided => 'Geführter Rechenweg',
      };
}

class GuidedMethodStep {
  const GuidedMethodStep({
    required this.title,
    required this.instruction,
    this.question,
    this.choices = const <String>[],
    this.correctChoice,
    this.evidenceKey,
    this.evidenceCompetency,
    this.evidenceWeight = 0.35,
  });

  final String title;
  final String instruction;
  final String? question;
  final List<String> choices;
  final int? correctChoice;
  final String? evidenceKey;
  final MicroCompetencyId? evidenceCompetency;
  final double evidenceWeight;

  bool get isInteractive =>
      question != null && choices.isNotEmpty && correctChoice != null;

  bool get recordsIntermediateEvidence =>
      isInteractive &&
      evidenceKey != null &&
      evidenceCompetency != null &&
      evidenceWeight > 0;
}

class GuidedStepCatalog {
  const GuidedStepCatalog._();

  static const labels = <String, String>{
    'onesDigit': 'Einerziffer erkennen',
    'groupCount': 'Anzahl der Gruppen erkennen',
    'itemsPerGroup': 'Elemente je Gruppe erkennen',
    'bridgeAmount': 'Schritt bis zum vollen Zehner bestimmen',
    'remainingSubtrahend': 'verbleibenden Teil des Subtrahenden bestimmen',
    'remainingAddend': 'verbleibenden Teil des zweiten Summanden bestimmen',
    'firstPartialSubtraction': 'ersten Teil korrekt wegnehmen',
    'firstComplementJump': 'ersten Ergänzungssprung bestimmen',
    'secondComplementJump': 'zweiten Ergänzungssprung bestimmen',
    'partialGroups': 'erste Gruppen zusammenfassen',
    'firstPartialProduct': 'erstes Teilprodukt berechnen',
    'secondPartialProduct': 'zweites Teilprodukt berechnen',
    'anchorFact': 'Ankeraufgabe sicher nutzen',
    'onesAlignment': 'Einer in der richtigen Spalte ausrichten',
    'regroupDecision': 'notwendiges Entbündeln erkennen',
    'carryDecision': 'notwendigen Übertrag erkennen',
    'multiplicationCarry': 'Übertrag beim schriftlichen Multiplizieren bestimmen',
    'nextMultiplierDigit': 'nächste Multiplikatorziffer bestimmen',
    'firstQuotientDigit': 'erste Quotientenziffer bestimmen',
    'firstDivisionRemainder': 'Rest nach dem ersten Divisionsschritt bestimmen',
    'storyInfo': 'wichtige Angaben in der Sachaufgabe erkennen',
    'storyOperation': 'passende Rechenart aus der Sachaufgabe wählen',
    'storyEquation': 'Sachaufgabe als passende Rechnung darstellen',
    'storyCalculation': 'modellierte Sachaufgabe korrekt ausrechnen',
    'storyInterpretation': 'Ergebnis passend zur Sachfrage deuten',
    'divisionTargetQuantity':
        'gesuchte Größe beim Teilen erkennen',
    'matchingMultiplicationFact':
        'passende Mal-Umkehraufgabe erkennen',
    'inverseOperationChoice':
        'passende Umkehroperation erkennen',
    'wallOperationChoice':
        'Rechenrichtung in der Zahlenmauer erkennen',
    'moneyOperationChoice':
        'passende Rechenart bei Geldaufgaben erkennen',
    'measureOperationChoice':
        'passende Rechenart bei Längenaufgaben erkennen',
    'doubleHalfMeaning':
        'Bedeutung von Doppeln und Halbieren erkennen',
    'unitValue': 'Wert für eine Einheit bestimmen',
    'minutesToNextHour':
        'Minuten bis zur nächsten vollen Stunde bestimmen',
    'equalPartSize': 'Größe eines gleich großen Bruchteils bestimmen',
    'decidingPlace': 'erste unterschiedliche Stelle beim Vergleichen finden',
    'smallestOrderedNumber':
        'kleinste Zahl vor dem vollständigen Ordnen bestimmen',
    'numberWordTensOnes':
        'Einer und Zehner im deutschen Zahlwort zuordnen',
    'placeValueContribution':
        'Wert einer Ziffer an ihrer Stelle bestimmen',
    'gapToAnchor':
        'Ergänzung bis zur glatten Zielzahl bestimmen',
    'referenceEstimate':
        'Referenz-Überschlag für die Plausibilitätsprüfung bilden',
    'roundedSummands':
        'beide Summanden passend für den Überschlag runden',
    'errorPlace':
        'erste falsche Stellenwertstelle in einer Rechnung erkennen',
    'unitRelation': 'passende Beziehung zwischen zwei Einheiten erkennen',
    'minuteSecondRelation': 'Beziehung zwischen Minuten und Sekunden erkennen',
    'roundingDecisionDigit': 'entscheidende Ziffer beim Runden erkennen',
    'minuteHandMinutes': 'Minutenwert des langen Zeigers erkennen',
    'sequenceStepSize': 'Richtung und Schrittweite einer Zahlenfolge erkennen',
  };

  static String labelFor(String key) => labels[key] ?? key;

  static String? keyFromTaskKey(String taskKey) {
    for (final key in labels.keys) {
      if (taskKey.contains(':$key:') || taskKey.endsWith(':$key')) {
        return key;
      }
    }
    return null;
  }
}

class GuidedMethodGuide {
  const GuidedMethodGuide({
    required this.methodKey,
    required this.methodLabel,
    required this.nudge,
    required this.steps,
  });

  final String methodKey;
  final String methodLabel;
  final String nudge;
  final List<GuidedMethodStep> steps;
}

class GuidedMethodFactory {
  const GuidedMethodFactory._();

  static GuidedMethodGuide forTask({
    required TrainingMode mode,
    required String taskKey,
    required int expected,
    required MethodPreferences preferences,
    MicroCompetencyId? targetCompetency,
    MathFact? fact,
  }) {
    if (taskKey.startsWith('process:strategy:')) {
      return _strategyChoiceGuide(taskKey);
    }

    if (taskKey.startsWith('process:error:')) {
      return _errorCheckingGuide(taskKey);
    }

    if (taskKey.startsWith('process:plausibility:')) {
      return _plausibilityGuide(taskKey);
    }

    if (taskKey.startsWith('process:representation:') ||
        taskKey.contains(':process:representation:')) {
      return _representationGuide(taskKey);
    }

    if (fact != null &&
        fact.operation == MathOperation.plus &&
        _needsAdditionBridge(fact)) {
      return _additionBridge(fact);
    }

    if (fact != null && fact.operation == MathOperation.minus) {
      if (_needsSubtractionBridge(fact)) {
        return _subtractionBridge(fact, preferences);
      }
      return _subtractionWithoutBridge(fact, preferences);
    }

    if (fact != null && fact.operation == MathOperation.multiply) {
      return _multiplication(fact, preferences);
    }

    if (fact != null && fact.operation == MathOperation.divide) {
      return _divisionFact(fact);
    }

    if (mode == TrainingMode.writtenAddSub &&
        (taskKey.contains(':+:') || taskKey.contains(':-:'))) {
      final numbers = _numbers(taskKey);
      if (numbers.length >= 2) {
        final a = numbers[numbers.length - 2];
        final b = numbers.last;
        if (taskKey.contains(':+:')) {
          return _writtenAddition(a, b, expected);
        }
        return _writtenSubtraction(
          a,
          b,
          expected,
          preferences,
        );
      }
    }

    if (mode == TrainingMode.writtenMultiply &&
        taskKey.startsWith('written:x:')) {
      final numbers = _numbers(taskKey);
      if (numbers.length >= 2) {
        return _writtenMultiplication(
          numbers[numbers.length - 2],
          numbers.last,
          expected,
        );
      }
    }

    if (mode == TrainingMode.writtenDivide &&
        (taskKey.startsWith('written:divide:') ||
            taskKey.startsWith('written:divide-rest:'))) {
      final numbers = _numbers(taskKey);
      if (numbers.length >= 2) {
        return _writtenDivision(
          numbers[numbers.length - 2],
          numbers.last,
        );
      }
    }

    if (mode == TrainingMode.doublesHalves ||
        targetCompetency == MicroCompetencyId.doublesHalves ||
        taskKey.startsWith('double:') ||
        taskKey.startsWith('half:')) {
      return _doublesHalvesGuide(taskKey);
    }

    if (mode == TrainingMode.factFamilies ||
        targetCompetency == MicroCompetencyId.inverseRelationship ||
        taskKey.startsWith('family:')) {
      return _inverseRelationshipGuide(taskKey);
    }

    if (mode == TrainingMode.numberWall ||
        targetCompetency == MicroCompetencyId.numberRelations ||
        taskKey.startsWith('wall:')) {
      return _numberWallGuide(taskKey);
    }

    if (mode == TrainingMode.money ||
        targetCompetency == MicroCompetencyId.moneyCalculation ||
        taskKey.startsWith('money:')) {
      return _moneyGuide(taskKey);
    }

    if (mode == TrainingMode.wordProblems ||
        targetCompetency == MicroCompetencyId.wordProblemOperation ||
        taskKey.startsWith('story:')) {
      return _wordProblem(taskKey);
    }

    if (mode == TrainingMode.largeNumbers) {
      return _largeNumbers(taskKey);
    }

    if (mode == TrainingMode.estimation &&
        taskKey.startsWith('estimate:')) {
      return _estimationGuide(taskKey);
    }

    if (mode == TrainingMode.rounding ||
        targetCompetency == MicroCompetencyId.roundingPlace) {
      return _roundingGuide(taskKey, expected);
    }

    if (mode == TrainingMode.sequences ||
        targetCompetency == MicroCompetencyId.numberPatterns) {
      return _sequenceGuide(taskKey, expected);
    }

    if (mode == TrainingMode.clock ||
        targetCompetency == MicroCompetencyId.clockReading) {
      return _clockReadingGuide(taskKey);
    }

    if (targetCompetency == MicroCompetencyId.secondsConversion ||
        taskKey.startsWith('time:seconds:')) {
      return _minuteSecondConversion(taskKey);
    }

    if (targetCompetency == MicroCompetencyId.measurementCalculation ||
        taskKey.startsWith('measure:add:') ||
        taskKey.startsWith('measure:subtract:')) {
      return _measurementCalculationGuide(taskKey);
    }

    if (mode == TrainingMode.advancedMeasures ||
        mode == TrainingMode.measures ||
        targetCompetency == MicroCompetencyId.unitConversion) {
      return _unitConversion(taskKey);
    }

    if (mode == TrainingMode.fractions ||
        targetCompetency == MicroCompetencyId.fractionEqualParts) {
      return _fraction(taskKey, expected);
    }

    if (mode == TrainingMode.timeDurations ||
        targetCompetency == MicroCompetencyId.timeDuration) {
      return _timeDuration(taskKey);
    }

    if (mode == TrainingMode.proportionality ||
        targetCompetency == MicroCompetencyId.proportionalUnit) {
      return _proportionalUnit(taskKey);
    }

    if (mode == TrainingMode.perimeterArea) {
      return _perimeterArea(taskKey);
    }

    return GuidedMethodGuide(
      methodKey: 'general:${mode.name}',
      methodLabel: mode.title,
      nudge: 'Was weißt du schon? Teile die Aufgabe in einen kleinen ersten Schritt.',
      steps: const [
        GuidedMethodStep(
          title: 'Aufgabe lesen',
          instruction: 'Markiere, was gesucht ist und welche Angaben du wirklich brauchst.',
        ),
        GuidedMethodStep(
          title: 'Kleinen Schritt wählen',
          instruction: 'Beginne mit einem Teil, den du sicher lösen kannst.',
        ),
        GuidedMethodStep(
          title: 'Kontrollieren',
          instruction: 'Prüfe, ob dein Ergebnis zur Aufgabe und zum Zahlenraum passt.',
        ),
      ],
    );
  }

  static List<GuidedMethodStep> independentArithmeticStepsForTask({
    required TrainingMode mode,
    required MathFact fact,
    required MethodPreferences preferences,
    MicroCompetencyId? targetCompetency,
  }) {
    if (fact.operation == MathOperation.divide) {
      if ((mode != TrainingMode.divide && mode != TrainingMode.mixed) ||
          targetCompetency != MicroCompetencyId.divisionFacts) {
        return const <GuidedMethodStep>[];
      }
      return _divisionFact(fact)
          .steps
          .where(
            (step) =>
                step.recordsIntermediateEvidence &&
                step.evidenceCompetency == MicroCompetencyId.divisionFacts,
          )
          .take(1)
          .toList(growable: false);
    }

    if (fact.operation == MathOperation.multiply) {
      if ((mode != TrainingMode.multiply && mode != TrainingMode.mixed) ||
          targetCompetency != MicroCompetencyId.multiplicationFacts) {
        return const <GuidedMethodStep>[];
      }
      return _multiplication(fact, preferences)
          .steps
          .where(
            (step) =>
                step.recordsIntermediateEvidence &&
                step.evidenceCompetency ==
                    MicroCompetencyId.multiplicationFacts,
          )
          .take(2)
          .toList(growable: false);
    }

    if (mode != TrainingMode.practice &&
        mode != TrainingMode.minus &&
        mode != TrainingMode.mixed) {
      return const <GuidedMethodStep>[];
    }

    final target = switch (fact.operation) {
      MathOperation.plus => MicroCompetencyId.additionTenBridge,
      MathOperation.minus => MicroCompetencyId.subtractionTenBridge,
      _ => null,
    };
    if (target == null ||
        (targetCompetency != target &&
            targetCompetency != MicroCompetencyId.numberDecomposition)) {
      return const <GuidedMethodStep>[];
    }

    final GuidedMethodGuide guide;
    if (fact.operation == MathOperation.plus) {
      if (!_needsAdditionBridge(fact)) {
        return const <GuidedMethodStep>[];
      }
      guide = _additionBridge(fact);
    } else {
      if (!_needsSubtractionBridge(fact) || fact.a % 10 == 0) {
        return const <GuidedMethodStep>[];
      }
      guide = _subtractionBridge(fact, preferences);
    }

    final evidenceSteps = guide.steps
        .where((step) => step.recordsIntermediateEvidence);

    if (targetCompetency == MicroCompetencyId.numberDecomposition) {
      return evidenceSteps
          .where(
            (step) =>
                step.evidenceCompetency ==
                MicroCompetencyId.numberDecomposition,
          )
          .take(2)
          .toList(growable: false);
    }

    return evidenceSteps.take(2).toList(growable: false);
  }

  static List<GuidedMethodStep> independentWrittenStepsForTask({
    required TrainingMode mode,
    required String taskKey,
    required int expected,
    required MethodPreferences preferences,
    MicroCompetencyId? targetCompetency,
  }) {
    if (mode == TrainingMode.rounding) {
      if (targetCompetency != MicroCompetencyId.roundingPlace ||
          !taskKey.startsWith('round:')) {
        return const <GuidedMethodStep>[];
      }
      return _roundingGuide(taskKey, expected)
          .steps
          .where((step) => step.recordsIntermediateEvidence)
          .take(1)
          .toList(growable: false);
    }

    if (mode == TrainingMode.advancedMeasures) {
      if (targetCompetency == MicroCompetencyId.secondsConversion &&
          taskKey.startsWith('time:seconds:')) {
        return _minuteSecondConversion(taskKey)
            .steps
            .where((step) => step.recordsIntermediateEvidence)
            .take(1)
            .toList(growable: false);
      }
      if (targetCompetency != MicroCompetencyId.unitConversion ||
          taskKey.startsWith('time:seconds:')) {
        return const <GuidedMethodStep>[];
      }
      return _unitConversion(taskKey)
          .steps
          .where((step) => step.recordsIntermediateEvidence)
          .take(1)
          .toList(growable: false);
    }

    if (mode == TrainingMode.writtenAddSub &&
        targetCompetency == MicroCompetencyId.errorChecking &&
        taskKey.startsWith('process:error:')) {
      return _errorCheckingGuide(taskKey)
          .steps
          .where((step) => step.recordsIntermediateEvidence)
          .take(1)
          .toList(growable: false);
    }

    if (mode == TrainingMode.estimation) {
      final validPlausibility =
          targetCompetency == MicroCompetencyId.plausibilityCheck &&
              taskKey.startsWith('process:plausibility:');
      final validEstimation =
          targetCompetency == MicroCompetencyId.estimation &&
              taskKey.startsWith('estimate:');
      if (!validPlausibility && !validEstimation) {
        return const <GuidedMethodStep>[];
      }
      final guide = validEstimation
          ? _estimationGuide(taskKey)
          : _plausibilityGuide(taskKey);
      return guide.steps
          .where((step) => step.recordsIntermediateEvidence)
          .take(1)
          .toList(growable: false);
    }

    if (mode == TrainingMode.mentalStrategies) {
      if (targetCompetency != MicroCompetencyId.strategyChoice ||
          !taskKey.startsWith('process:strategy:')) {
        return const <GuidedMethodStep>[];
      }
      return _strategyChoiceGuide(taskKey)
          .steps
          .where((step) => step.recordsIntermediateEvidence)
          .take(1)
          .toList(growable: false);
    }

    if (mode == TrainingMode.largeNumbers) {
      final validCompare =
          targetCompetency == MicroCompetencyId.largeNumberCompare &&
              taskKey.startsWith('large:compare:');
      final validDecompose =
          targetCompetency == MicroCompetencyId.placeValueDecompose &&
              taskKey.startsWith('large:decompose:');
      final validOrder =
          targetCompetency == MicroCompetencyId.largeNumberOrder &&
              taskKey.startsWith('large:order:');
      final validNumberWord =
          targetCompetency == MicroCompetencyId.numberWordReading &&
              taskKey.startsWith('large:word:');
      if (!validCompare &&
          !validDecompose &&
          !validOrder &&
          !validNumberWord) {
        return const <GuidedMethodStep>[];
      }
      return _largeNumbers(taskKey)
          .steps
          .where((step) => step.recordsIntermediateEvidence)
          .take(1)
          .toList(growable: false);
    }

    if (mode == TrainingMode.fractions) {
      if (targetCompetency != MicroCompetencyId.fractionEqualParts ||
          !taskKey.startsWith('fraction:parts:')) {
        return const <GuidedMethodStep>[];
      }
      return _fraction(taskKey, expected)
          .steps
          .where((step) => step.recordsIntermediateEvidence)
          .take(1)
          .toList(growable: false);
    }

    if (mode == TrainingMode.timeDurations) {
      if (targetCompetency != MicroCompetencyId.timeDuration ||
          !taskKey.startsWith('duration:') ||
          taskKey.startsWith('duration:weeks:') ||
          taskKey.startsWith('duration:days:')) {
        return const <GuidedMethodStep>[];
      }
      return _timeDuration(taskKey)
          .steps
          .where((step) => step.recordsIntermediateEvidence)
          .take(1)
          .toList(growable: false);
    }

    if (mode == TrainingMode.proportionality) {
      if (targetCompetency != MicroCompetencyId.proportionalUnit ||
          !taskKey.startsWith('proportion:')) {
        return const <GuidedMethodStep>[];
      }
      return _proportionalUnit(taskKey)
          .steps
          .where((step) => step.recordsIntermediateEvidence)
          .take(1)
          .toList(growable: false);
    }

    if (mode == TrainingMode.writtenMultiply) {
      if (targetCompetency != MicroCompetencyId.writtenMultiplyProcedure ||
          !taskKey.startsWith('written:x:')) {
        return const <GuidedMethodStep>[];
      }
      final numbers = _numbers(taskKey);
      if (numbers.length < 2) return const <GuidedMethodStep>[];
      return _writtenMultiplication(
        numbers[numbers.length - 2],
        numbers.last,
        expected,
      )
          .steps
          .where((step) => step.recordsIntermediateEvidence)
          .take(2)
          .toList(growable: false);
    }

    if (mode == TrainingMode.writtenDivide) {
      if (targetCompetency != MicroCompetencyId.writtenDivideProcedure ||
          (!taskKey.startsWith('written:divide:') &&
              !taskKey.startsWith('written:divide-rest:'))) {
        return const <GuidedMethodStep>[];
      }
      final numbers = _numbers(taskKey);
      if (numbers.length < 2) return const <GuidedMethodStep>[];
      return _writtenDivision(
        numbers[numbers.length - 2],
        numbers.last,
      )
          .steps
          .where((step) => step.recordsIntermediateEvidence)
          .take(2)
          .toList(growable: false);
    }

    if (mode != TrainingMode.writtenAddSub ||
        (targetCompetency != MicroCompetencyId.writtenAlignment &&
            targetCompetency != MicroCompetencyId.writtenRegrouping) ||
        (!taskKey.startsWith('written:+:') &&
            !taskKey.startsWith('written:-:'))) {
      return const <GuidedMethodStep>[];
    }

    final numbers = _numbers(taskKey);
    if (numbers.length < 2) return const <GuidedMethodStep>[];
    final a = numbers[numbers.length - 2];
    final b = numbers.last;
    final guide = taskKey.contains(':+:')
        ? _writtenAddition(a, b, expected)
        : _writtenSubtraction(a, b, expected, preferences);
    final evidenceSteps =
        guide.steps.where((step) => step.recordsIntermediateEvidence).toList();

    if (targetCompetency == MicroCompetencyId.writtenAlignment) {
      return evidenceSteps
          .where(
            (step) =>
                step.evidenceCompetency == MicroCompetencyId.writtenAlignment,
          )
          .take(1)
          .toList(growable: false);
    }

    final hasRegrouping = evidenceSteps.any(
      (step) =>
          step.evidenceCompetency == MicroCompetencyId.writtenRegrouping,
    );
    if (!hasRegrouping) return const <GuidedMethodStep>[];

    return evidenceSteps
        .where(
          (step) =>
              step.evidenceCompetency == MicroCompetencyId.writtenAlignment ||
              step.evidenceCompetency == MicroCompetencyId.writtenRegrouping,
        )
        .take(2)
        .toList(growable: false);
  }

  static GuidedMethodGuide _sequenceGuide(
    String taskKey,
    int expected,
  ) {
    final parts = taskKey.split(':');
    if (!taskKey.startsWith('sequence:') || parts.length < 4) {
      return const GuidedMethodGuide(
        methodKey: 'sequence:constantStep',
        methodLabel: 'Musterregel finden',
        nudge:
            'Vergleiche immer zwei benachbarte Zahlen. Suche eine Veränderung, die jedes Mal gleich bleibt.',
        steps: [
          GuidedMethodStep(
            title: 'Nachbarzahlen vergleichen',
            instruction:
                'Prüfe, ob die Zahlen immer um denselben Betrag größer oder kleiner werden.',
          ),
          GuidedMethodStep(
            title: 'Regel anwenden',
            instruction:
                'Wende die gefundene Regel erst danach auf die letzte sichtbare Zahl an.',
          ),
        ],
      );
    }

    final direction = parts[1];
    final start = int.tryParse(parts[2]);
    final step = int.tryParse(parts[3]);
    if (start == null || step == null || step <= 0) {
      return const GuidedMethodGuide(
        methodKey: 'sequence:constantStep',
        methodLabel: 'Musterregel finden',
        nudge:
            'Vergleiche immer zwei benachbarte Zahlen. Suche eine Veränderung, die jedes Mal gleich bleibt.',
        steps: [
          GuidedMethodStep(
            title: 'Nachbarzahlen vergleichen',
            instruction:
                'Prüfe, ob die Zahlen immer um denselben Betrag größer oder kleiner werden.',
          ),
          GuidedMethodStep(
            title: 'Regel anwenden',
            instruction:
                'Wende die gefundene Regel erst danach auf die letzte sichtbare Zahl an.',
          ),
        ],
      );
    }

    final backwards = direction == '-';
    final alternative = [1, 2, 5, 10]
        .firstWhere((value) => value != step, orElse: () => step + 1);
    final choices = <String>[
      'immer +$step',
      'immer −$step',
      'immer +$alternative',
      'immer −$alternative',
    ];
    final correct = backwards ? 'immer −$step' : 'immer +$step';
    final second = backwards ? start - step : start + step;
    final third = backwards ? start - step * 2 : start + step * 2;

    return GuidedMethodGuide(
      methodKey: 'sequence:constantStep',
      methodLabel: 'Musterregel finden',
      nudge:
          'Vergleiche $start mit $second und danach $second mit $third. Dieselbe Veränderung muss beide Male passen.',
      steps: [
        GuidedMethodStep(
          title: 'Schrittweite erkennen',
          instruction:
              'Vergleiche die sichtbaren Nachbarzahlen. Entscheide gleichzeitig, ob die Folge wächst oder fällt.',
          question: 'Welche Regel beschreibt die Schrittweite der Folge?',
          choices: choices,
          correctChoice: choices.indexOf(correct),
          evidenceKey: 'sequenceStepSize',
          evidenceCompetency: MicroCompetencyId.numberPatterns,
          evidenceWeight: 0.40,
        ),
        GuidedMethodStep(
          title: 'Regel benennen',
          instruction: backwards
              ? 'Die Folge wird jedes Mal um $step kleiner: $correct.'
              : 'Die Folge wird jedes Mal um $step größer: $correct.',
        ),
        GuidedMethodStep(
          title: 'Regel fortsetzen',
          instruction: backwards
              ? '$third − $step = $expected.'
              : '$third + $step = $expected.',
        ),
      ],
    );
  }

  static GuidedMethodGuide _clockReadingGuide(String taskKey) {
    final parts = taskKey.split(':');
    if (!taskKey.startsWith('clock:') || parts.length < 3) {
      return const GuidedMethodGuide(
        methodKey: 'clock:readHands',
        methodLabel: 'Uhrzeiger lesen',
        nudge:
            'Lies zuerst den langen Minutenzeiger und danach den kurzen Stundenzeiger.',
        steps: [
          GuidedMethodStep(
            title: 'Langen Zeiger lesen',
            instruction:
                'Der lange Zeiger zeigt die Minuten. Lies ihn zuerst getrennt ab.',
          ),
          GuidedMethodStep(
            title: 'Kurzen Zeiger lesen',
            instruction:
                'Der kurze Zeiger zeigt die Stunde. Lies ihn erst nach den Minuten.',
          ),
        ],
      );
    }

    final hour = int.tryParse(parts[1]);
    final minute = int.tryParse(parts[2]);
    if (hour == null || minute == null) {
      return const GuidedMethodGuide(
        methodKey: 'clock:readHands',
        methodLabel: 'Uhrzeiger lesen',
        nudge:
            'Lies zuerst den langen Minutenzeiger und danach den kurzen Stundenzeiger.',
        steps: [
          GuidedMethodStep(
            title: 'Langen Zeiger lesen',
            instruction:
                'Der lange Zeiger zeigt die Minuten. Lies ihn zuerst getrennt ab.',
          ),
          GuidedMethodStep(
            title: 'Kurzen Zeiger lesen',
            instruction:
                'Der kurze Zeiger zeigt die Stunde. Lies ihn erst nach den Minuten.',
          ),
        ],
      );
    }

    final minuteChoices = (minute == 0 || minute == 30)
        ? const ['0 Minuten', '30 Minuten']
        : const ['0 Minuten', '15 Minuten', '30 Minuten', '45 Minuten'];

    return GuidedMethodGuide(
      methodKey: 'clock:readHands',
      methodLabel: 'Uhrzeiger lesen',
      nudge:
          'Lies die beiden Zeiger getrennt: zuerst den langen Minutenzeiger, dann den kurzen Stundenzeiger.',
      steps: [
        GuidedMethodStep(
          title: 'Minutenzeiger lesen',
          instruction:
              'Schau nur auf den langen Zeiger. Die Stunde ist für diesen Schritt noch nicht wichtig.',
          question: 'Wie viele Minuten zeigt der lange Zeiger?',
          choices: minuteChoices,
          correctChoice: minuteChoices.indexOf('$minute Minuten'),
          evidenceKey: 'minuteHandMinutes',
          evidenceCompetency: MicroCompetencyId.clockReading,
          evidenceWeight: 0.40,
        ),
        GuidedMethodStep(
          title: 'Stundenzeiger lesen',
          instruction: minute == 30
              ? 'Der kurze Zeiger steht bei einer halben Stunde schon zwischen zwei Zahlen. Die begonnene Stunde ist $hour.'
              : 'Lies jetzt den kurzen Zeiger als Stunde $hour.',
        ),
        GuidedMethodStep(
          title: 'Uhrzeit zusammensetzen',
          instruction:
              'Verbinde Stunde und Minuten zu $hour:${minute.toString().padLeft(2, '0')} Uhr.',
        ),
      ],
    );
  }

  static GuidedMethodGuide _roundingGuide(
    String taskKey,
    int expected,
  ) {
    final parts = taskKey.split(':');
    if (!taskKey.startsWith('round:') || parts.length < 3) {
      return const GuidedMethodGuide(
        methodKey: 'rounding:place',
        methodLabel: 'Runden',
        nudge:
            'Markiere die Rundungsstelle. Die Ziffer direkt rechts daneben entscheidet.',
        steps: [
          GuidedMethodStep(
            title: 'Rundungsstelle finden',
            instruction: 'Bestimme zuerst, auf welche Stelle gerundet wird.',
          ),
          GuidedMethodStep(
            title: 'Entscheidende Ziffer ansehen',
            instruction:
                'Schau genau eine Stelle nach rechts: 0–4 abrunden, 5–9 aufrunden.',
          ),
        ],
      );
    }

    final number = int.tryParse(parts[1]);
    final place = int.tryParse(parts[2]);
    if (number == null || place == null || place < 10) {
      return const GuidedMethodGuide(
        methodKey: 'rounding:place',
        methodLabel: 'Runden',
        nudge:
            'Markiere die Rundungsstelle. Die Ziffer direkt rechts daneben entscheidet.',
        steps: [
          GuidedMethodStep(
            title: 'Rundungsstelle finden',
            instruction: 'Bestimme zuerst, auf welche Stelle gerundet wird.',
          ),
          GuidedMethodStep(
            title: 'Entscheidende Ziffer ansehen',
            instruction:
                'Schau genau eine Stelle nach rechts: 0–4 abrunden, 5–9 aufrunden.',
          ),
        ],
      );
    }

    final decisionPlace = place ~/ 10;
    final decisionDigit = (number ~/ decisionPlace) % 10;
    final choices = _numberChoices(decisionDigit, maxValue: 9);
    final roundsUp = decisionDigit >= 5;
    final placeLabel = _largePlaceLabel(place);
    final decisionLabel = _largePlaceLabel(decisionPlace);

    return GuidedMethodGuide(
      methodKey: 'rounding:place',
      methodLabel: 'Runden',
      nudge:
          'Du rundest auf die $placeLabel. Entscheidend ist genau die Stelle rechts daneben.',
      steps: [
        GuidedMethodStep(
          title: 'Entscheidende Ziffer finden',
          instruction:
              'Suche zuerst die $placeLabel und gehe dann genau eine Stelle nach rechts zur $decisionLabel.',
          question: 'Welche Ziffer entscheidet bei $number über das Runden?',
          choices: choices,
          correctChoice: choices.indexOf('$decisionDigit'),
          evidenceKey: 'roundingDecisionDigit',
          evidenceCompetency: MicroCompetencyId.roundingPlace,
          evidenceWeight: 0.40,
        ),
        GuidedMethodStep(
          title: roundsUp ? 'Aufrunden' : 'Abrunden',
          instruction: roundsUp
              ? '$decisionDigit liegt zwischen 5 und 9. Deshalb wird aufgerundet.'
              : '$decisionDigit liegt zwischen 0 und 4. Deshalb wird abgerundet.',
        ),
        GuidedMethodStep(
          title: 'Gerundete Zahl bilden',
          instruction: 'Das Ergebnis ist $expected.',
        ),
      ],
    );
  }

  static GuidedMethodGuide _representationGuide(String taskKey) {
    final parts = taskKey.split(':');
    final representationIndex = parts.indexOf('representation');
    final kind = representationIndex >= 0 &&
            representationIndex + 1 < parts.length
        ? parts[representationIndex + 1]
        : '';

    if (kind == 'place' || kind == 'decompose') {
      final valueIndex = representationIndex + 2;
      final number = valueIndex >= 0 && valueIndex < parts.length
          ? int.tryParse(parts[valueIndex])
          : null;
      final ones = number == null ? null : number % 10;
      final onesChoices = ones == null
          ? const <String>[]
          : _numberChoices(ones, maxValue: 9);
      return GuidedMethodGuide(
        methodKey: 'representation:placeValue',
        methodLabel: 'Stellenwerte lesen',
        nudge:
            'Lies jede Stelle einzeln: Einer, Zehner, Hunderter und weiter nach links.',
        steps: [
          GuidedMethodStep(
            title: 'Stellen benennen',
            instruction:
                'Ordne jede sichtbare Ziffer zuerst ihrer Stelle zu. Eine 0 hält eine Stelle frei und darf nicht übersprungen werden.',
            question: ones == null ? null : 'Welche Ziffer steht bei den Einern?',
            choices: onesChoices,
            correctChoice: ones == null ? null : onesChoices.indexOf('$ones'),
            evidenceKey: ones == null ? null : 'onesDigit',
            evidenceCompetency:
                ones == null ? null : MicroCompetencyId.placeValueDigits,
          ),
          GuidedMethodStep(
            title: 'Wert zusammensetzen',
            instruction: number == null
                ? 'Setze die Stellenwerte anschließend wieder zu einer Zahl oder Zerlegung zusammen.'
                : 'Setze danach alle Stellenwerte wieder zur Zahl $number zusammen.',
          ),
          const GuidedMethodStep(
            title: 'Darstellungen vergleichen',
            instruction:
                'Kontrolliere, ob Zahl, Stellenwerttafel und Zerlegung exakt dieselben Stellenwerte enthalten.',
          ),
        ],
      );
    }

    final groupsIndex = representationIndex + 2;
    final eachIndex = representationIndex + 3;
    final groups = groupsIndex >= 0 && groupsIndex < parts.length
        ? int.tryParse(parts[groupsIndex])
        : null;
    final each = eachIndex >= 0 && eachIndex < parts.length
        ? int.tryParse(parts[eachIndex])
        : null;
    final groupChoices = groups == null
        ? const <String>[]
        : _numberChoices(groups, maxValue: max(6, groups + 2));
    final eachChoices = each == null
        ? const <String>[]
        : _numberChoices(each, maxValue: max(6, each + 2));
    return GuidedMethodGuide(
      methodKey: 'representation:equalGroups',
      methodLabel: 'Gleiche Gruppen lesen',
      nudge:
          'Zähle zuerst die Gruppen und danach, wie viele Punkte in jeder Gruppe liegen.',
      steps: [
        GuidedMethodStep(
          title: 'Gruppen zählen',
          instruction: 'Bestimme zuerst nur die Anzahl der gleich großen Gruppen.',
          question: groups == null ? null : 'Wie viele Gruppen siehst du?',
          choices: groupChoices,
          correctChoice:
              groups == null ? null : groupChoices.indexOf('$groups'),
          evidenceKey: groups == null ? null : 'groupCount',
          evidenceCompetency:
              groups == null ? null : MicroCompetencyId.multiplicationGroups,
        ),
        GuidedMethodStep(
          title: 'Inhalt jeder Gruppe',
          instruction: 'Schau jetzt nur auf eine Gruppe und zähle ihren Inhalt.',
          question: each == null ? null : 'Wie viele Punkte sind in jeder Gruppe?',
          choices: eachChoices,
          correctChoice: each == null ? null : eachChoices.indexOf('$each'),
          evidenceKey: each == null ? null : 'itemsPerGroup',
          evidenceCompetency:
              each == null ? null : MicroCompetencyId.multiplicationGroups,
        ),
        GuidedMethodStep(
          title: 'In Symbolsprache übersetzen',
          instruction: groups == null || each == null
              ? 'Schreibe: Anzahl der Gruppen × Anzahl je Gruppe.'
              : '$groups Gruppen mit je $each Punkten entsprechen $groups × $each.',
        ),
      ],
    );
  }

  static GuidedMethodGuide _additionBridge(MathFact fact) {
    final a = fact.a;
    final b = fact.b;
    final result = a + b;
    final toTen = 10 - (a % 10);
    final bridge = a + toTen;
    final rest = b - toTen;
    final bridgeChoices = _numberChoices(
      toTen,
      maxValue: max(10, b),
    );
    final restChoices = _numberChoices(
      rest,
      maxValue: max(10, b),
    );
    final resultChoices = _numberChoices(
      result,
      maxValue: max(20, result),
    );

    return GuidedMethodGuide(
      methodKey: 'addition:bridgeToTen',
      methodLabel: 'Erst zum Zehner',
      nudge: 'Ergänze $a zuerst bis zum nächsten vollen Zehner.',
      steps: [
        GuidedMethodStep(
          title: 'Bis zum Zehner',
          instruction: 'Suche zuerst den nächsten vollen Zehner über $a.',
          question: 'Wie viel fehlt von $a bis $bridge?',
          choices: bridgeChoices,
          correctChoice: bridgeChoices.indexOf('$toTen'),
          evidenceKey: 'bridgeAmount',
          evidenceCompetency: MicroCompetencyId.additionTenBridge,
        ),
        GuidedMethodStep(
          title: 'Rest bestimmen',
          instruction: 'Von den $b wurden schon $toTen zum Auffüllen genutzt.',
          question: 'Wie viel von $b bleibt danach übrig?',
          choices: restChoices,
          correctChoice: restChoices.indexOf('$rest'),
          evidenceKey: rest > 0 ? 'remainingAddend' : null,
          evidenceCompetency:
              rest > 0 ? MicroCompetencyId.numberDecomposition : null,
        ),
        GuidedMethodStep(
          title: 'Weiterrechnen',
          instruction: '$bridge + $rest = $result.',
          question: 'Wie lautet das Ergebnis?',
          choices: resultChoices,
          correctChoice: resultChoices.indexOf('$result'),
        ),
      ],
    );
  }

  static GuidedMethodGuide _subtractionBridge(
    MathFact fact,
    MethodPreferences preferences,
  ) {
    final a = fact.a;
    final b = fact.b;
    final result = a - b;
    final toTen = a % 10;
    final bridge = a - toTen;
    final rest = b - toTen;

    final strategy = preferences.effectiveSubtraction(taskKey: fact.key);
    if (strategy == SubtractionStrategy.bridgeToTen && toTen == 0) {
      return _subtractionFromFullTen(fact);
    }

    switch (strategy) {
      case SubtractionStrategy.bridgeToTen:
        final choices1 = _numberChoices(toTen, maxValue: max(10, b));
        final choices2 = _numberChoices(rest, maxValue: max(10, b));
        final choices3 = _numberChoices(result, maxValue: max(20, a));
        return GuidedMethodGuide(
          methodKey: 'subtraction:${strategy.name}',
          methodLabel: strategy.label,
          nudge:
              'Gehe von $a zuerst bis zum vorherigen vollen Zehner $bridge.',
          steps: [
            GuidedMethodStep(
              title: 'Bis zum Zehner',
              instruction:
                  'Von $a gehst du zuerst bis $bridge. So wird der Zehner zum Zwischenstopp.',
              question: 'Wie viel musst du zuerst wegnehmen?',
              choices: choices1,
              correctChoice: choices1.indexOf('$toTen'),
              evidenceKey: 'bridgeAmount',
              evidenceCompetency: MicroCompetencyId.subtractionTenBridge,
            ),
            GuidedMethodStep(
              title: 'Rest bestimmen',
              instruction: 'Von den $b wurden schon $toTen weggenommen.',
              question: 'Wie viel musst du noch wegnehmen?',
              choices: choices2,
              correctChoice: choices2.indexOf('$rest'),
              evidenceKey: 'remainingSubtrahend',
              evidenceCompetency: MicroCompetencyId.numberDecomposition,
            ),
            GuidedMethodStep(
              title: 'Weiterrechnen',
              instruction: '$bridge − $rest = $result.',
              question: 'Wie lautet das Ergebnis?',
              choices: choices3,
              correctChoice: choices3.indexOf('$result'),
            ),
          ],
        );

      case SubtractionStrategy.takeAway:
        final first = min(b, max(1, b ~/ 2));
        final second = b - first;
        final middle = a - first;
        final choices1 = _numberChoices(middle, maxValue: max(20, a));
        final choices2 = _numberChoices(result, maxValue: max(20, a));
        return GuidedMethodGuide(
          methodKey: 'subtraction:${strategy.name}',
          methodLabel: strategy.label,
          nudge: 'Zerlege $b in zwei gut rechenbare Teile.',
          steps: [
            GuidedMethodStep(
              title: 'Ersten Teil wegnehmen',
              instruction: 'Nimm zuerst $first von $a weg.',
              question: 'Wo landest du nach dem ersten Schritt?',
              choices: choices1,
              correctChoice: choices1.indexOf('$middle'),
              evidenceKey: 'firstPartialSubtraction',
              evidenceCompetency: MicroCompetencyId.numberDecomposition,
            ),
            GuidedMethodStep(
              title: 'Rest wegnehmen',
              instruction: 'Jetzt fehlen noch $second.',
              question: '$middle − $second = ?',
              choices: choices2,
              correctChoice: choices2.indexOf('$result'),
            ),
          ],
        );

      case SubtractionStrategy.complement:
        final firstJump = bridge - b;
        final secondJump = a - bridge;
        final choices = _numberChoices(result, maxValue: max(20, a));
        final firstJumpChoices =
            _numberChoices(firstJump, maxValue: max(10, a));
        final secondJumpChoices =
            _numberChoices(secondJump, maxValue: max(10, a));
        return GuidedMethodGuide(
          methodKey: 'subtraction:${strategy.name}',
          methodLabel: strategy.label,
          nudge: 'Starte bei $b und ergänze schrittweise bis $a.',
          steps: [
            GuidedMethodStep(
              title: 'Bis zum Zehner ergänzen',
              instruction: 'Ergänze von $b bis zum nächsten vollen Zehner.',
              question: 'Wie groß ist der erste Sprung?',
              choices: firstJumpChoices,
              correctChoice: firstJumpChoices.indexOf('$firstJump'),
              evidenceKey: 'firstComplementJump',
              evidenceCompetency: MicroCompetencyId.subtractionTenBridge,
            ),
            GuidedMethodStep(
              title: 'Bis zur größeren Zahl',
              instruction: 'Ergänze vom vollen Zehner weiter bis $a.',
              question: 'Wie groß ist der zweite Sprung?',
              choices: secondJumpChoices,
              correctChoice: secondJumpChoices.indexOf('$secondJump'),
              evidenceKey: 'secondComplementJump',
              evidenceCompetency: MicroCompetencyId.subtractionTenBridge,
            ),
            GuidedMethodStep(
              title: 'Sprünge zusammenzählen',
              instruction: '$firstJump + $secondJump = $result.',
              question: 'Wie groß ist der Unterschied?',
              choices: choices,
              correctChoice: choices.indexOf('$result'),
            ),
          ],
        );
    }
  }

  static GuidedMethodGuide _subtractionFromFullTen(MathFact fact) {
    final a = fact.a;
    final b = fact.b;
    final result = a - b;
    final resultChoices = _numberChoices(result, maxValue: max(20, a));

    return GuidedMethodGuide(
      methodKey: 'subtraction:bridgeToTen',
      methodLabel: 'Erst zum Zehner',
      nudge:
          '$a ist schon ein voller Zehner. Du kannst $b direkt von $a wegnehmen.',
      steps: [
        GuidedMethodStep(
          title: 'Voller Zehner ist schon da',
          instruction:
              'Du startest bereits bei $a. Ein zusätzlicher Null-Schritt bis zum Zehner ist nicht nötig.',
        ),
        GuidedMethodStep(
          title: 'Direkt abziehen',
          instruction: '$a − $b = $result.',
          question: 'Wie lautet das Ergebnis?',
          choices: resultChoices,
          correctChoice: resultChoices.indexOf('$result'),
        ),
      ],
    );
  }

  static GuidedMethodGuide _subtractionWithoutBridge(
    MathFact fact,
    MethodPreferences preferences,
  ) {
    final a = fact.a;
    final b = fact.b;
    final result = a - b;
    final strategy = preferences.effectiveSubtraction(taskKey: fact.key);

    if (strategy == SubtractionStrategy.takeAway && b > 1) {
      final first = max(1, b ~/ 2);
      final second = b - first;
      final middle = a - first;
      final middleChoices = _numberChoices(middle, maxValue: max(20, a));
      final resultChoices = _numberChoices(result, maxValue: max(20, a));
      return GuidedMethodGuide(
        methodKey: 'subtraction:${strategy.name}',
        methodLabel: strategy.label,
        nudge: 'Zerlege $b in zwei kleine, gut rechenbare Teile.',
        steps: [
          GuidedMethodStep(
            title: 'Ersten Teil wegnehmen',
            instruction: '$a − $first = $middle.',
            question: 'Wo landest du zuerst?',
            choices: middleChoices,
            correctChoice: middleChoices.indexOf('$middle'),
          ),
          GuidedMethodStep(
            title: 'Rest wegnehmen',
            instruction: '$middle − $second = $result.',
            question: 'Wie lautet das Ergebnis?',
            choices: resultChoices,
            correctChoice: resultChoices.indexOf('$result'),
          ),
        ],
      );
    }

    if (strategy == SubtractionStrategy.complement) {
      final resultChoices = _numberChoices(result, maxValue: max(20, a));
      return GuidedMethodGuide(
        methodKey: 'subtraction:${strategy.name}',
        methodLabel: strategy.label,
        nudge:
            'Starte bei $b und ergänze bis $a. Die gesamte Ergänzung ist der Unterschied.',
        steps: [
          GuidedMethodStep(
            title: 'Von der kleineren Zahl starten',
            instruction: 'Beginne bei $b und ergänze schrittweise bis $a.',
          ),
          GuidedMethodStep(
            title: 'Unterschied bestimmen',
            instruction: 'Die Ergänzung von $b bis $a ist $result.',
            question: 'Wie groß ist der Unterschied?',
            choices: resultChoices,
            correctChoice: resultChoices.indexOf('$result'),
          ),
        ],
      );
    }

    final resultChoices = _numberChoices(result, maxValue: max(20, a));
    return GuidedMethodGuide(
      methodKey: 'subtraction:direct',
      methodLabel: 'Direkt abziehen',
      nudge:
          'Du musst keinen Zehner überschreiten. Ziehe $b direkt von $a ab.',
      steps: [
        const GuidedMethodStep(
          title: 'Einer prüfen',
          instruction:
              'Die Einer reichen aus. Du brauchst keinen Zehner als Zwischenstopp.',
        ),
        GuidedMethodStep(
          title: 'Direkt rechnen',
          instruction: '$a − $b = $result.',
          question: 'Wie lautet das Ergebnis?',
          choices: resultChoices,
          correctChoice: resultChoices.indexOf('$result'),
        ),
      ],
    );
  }
  static GuidedMethodGuide _multiplication(
    MathFact fact,
    MethodPreferences preferences,
  ) {
    final a = fact.a;
    final b = fact.b;
    final result = a * b;
    final strategy = preferences.effectiveMultiplication(taskKey: fact.key);

    switch (strategy) {
      case MultiplicationStrategy.groups:
        final choices = _numberChoices(result, maxValue: max(100, result + 10));
        final firstGroupCount = min(2, a);
        final partialGroups = b * firstGroupCount;
        final partialChoices =
            _numberChoices(partialGroups, maxValue: max(20, result));
        final anchorA = a > 5
            ? 5
            : a > 2
                ? 2
                : a > 1
                    ? 1
                    : a;
        final anchorB = anchorA != a
            ? b
            : b > 5
                ? 5
                : b > 2
                    ? 2
                    : b > 1
                        ? 1
                        : b;
        final hasAnchor = anchorA != a || anchorB != b;
        final anchorProduct = anchorA * anchorB;
        final anchorChoices = hasAnchor
            ? _numberChoices(anchorProduct, maxValue: max(100, result))
            : const <String>[];
        return GuidedMethodGuide(
          methodKey: 'multiplication:${strategy.name}',
          methodLabel: strategy.label,
          nudge: 'Stell dir $a gleich große Gruppen mit je $b Dingen vor.',
          steps: [
            GuidedMethodStep(
              title: 'Erste Gruppen zusammenfassen',
              instruction:
                  'Beginne mit $firstGroupCount gleich großen Gruppen mit je $b.',
              question:
                  'Wie viele sind in $firstGroupCount Gruppen zusammen?',
              choices: partialChoices,
              correctChoice: partialChoices.indexOf('$partialGroups'),
              evidenceKey: a > firstGroupCount ? 'partialGroups' : null,
              evidenceCompetency: a > firstGroupCount
                  ? MicroCompetencyId.multiplicationGroups
                  : null,
            ),
            if (hasAnchor)
              GuidedMethodStep(
                title: 'Bekannte Gruppen als Anker',
                instruction: anchorA != a
                    ? 'Nutze zuerst $anchorA bekannte Gruppen mit je $b.'
                    : 'Nutze in jeder der $a Gruppen zuerst $anchorB bekannte Elemente.',
                question:
                    'Wie groß ist die Ankeraufgabe $anchorA × $anchorB?',
                choices: anchorChoices,
                correctChoice: anchorChoices.indexOf('$anchorProduct'),
                evidenceKey: 'anchorFact',
                evidenceCompetency:
                    MicroCompetencyId.multiplicationFacts,
              ),
            GuidedMethodStep(
              title: 'Alle Gruppen sehen',
              instruction: '${List.filled(min(a, 6), '$b').join(' + ')}${a > 6 ? ' + …' : ''}',
            ),
            GuidedMethodStep(
              title: 'Ergebnis',
              instruction: '$a × $b = $result.',
              question: 'Wie viele sind es zusammen?',
              choices: choices,
              correctChoice: choices.indexOf('$result'),
            ),
          ],
        );

      case MultiplicationStrategy.decompose:
        final left = b ~/ 2;
        final right = b - left;
        final p1 = a * left;
        final p2 = a * right;
        final choices = _numberChoices(result, maxValue: max(100, result + 10));
        final p1Choices = _numberChoices(p1, maxValue: max(100, result));
        final p2Choices = _numberChoices(p2, maxValue: max(100, result));
        return GuidedMethodGuide(
          methodKey: 'multiplication:${strategy.name}',
          methodLabel: strategy.label,
          nudge: 'Zerlege $b in $left und $right.',
          steps: [
            GuidedMethodStep(
              title: 'Erstes Teilprodukt',
              instruction: 'Rechne zuerst $a × $left.',
              question: 'Wie groß ist das erste Teilprodukt?',
              choices: p1Choices,
              correctChoice: p1Choices.indexOf('$p1'),
              evidenceKey:
                  left > 0 && right > 0 ? 'firstPartialProduct' : null,
              evidenceCompetency: left > 0 && right > 0
                  ? MicroCompetencyId.multiplicationFacts
                  : null,
            ),
            GuidedMethodStep(
              title: 'Zweites Teilprodukt',
              instruction: 'Rechne jetzt $a × $right.',
              question: 'Wie groß ist das zweite Teilprodukt?',
              choices: p2Choices,
              correctChoice: p2Choices.indexOf('$p2'),
              evidenceKey:
                  left > 0 && right > 0 ? 'secondPartialProduct' : null,
              evidenceCompetency: left > 0 && right > 0
                  ? MicroCompetencyId.multiplicationFacts
                  : null,
            ),
            GuidedMethodStep(
              title: 'Zusammenfügen',
              instruction: '$p1 + $p2 = $result.',
              question: 'Wie lautet das Produkt?',
              choices: choices,
              correctChoice: choices.indexOf('$result'),
            ),
          ],
        );

      case MultiplicationStrategy.neighborFacts:
        final anchor = b <= 7 ? 5 : 10;
        final anchorProduct = a * anchor;
        final difference = b - anchor;
        final delta = a * difference.abs();
        final anchorChoices =
            _numberChoices(anchorProduct, maxValue: max(100, result + delta));
        return GuidedMethodGuide(
          methodKey: 'multiplication:${strategy.name}',
          methodLabel: strategy.label,
          nudge: 'Nimm eine leichte Nachbaraufgabe mit ×$anchor als Start.',
          steps: [
            GuidedMethodStep(
              title: 'Ankeraufgabe',
              instruction: 'Starte mit der leichteren Aufgabe $a × $anchor.',
              question: 'Wie groß ist das Ankerprodukt?',
              choices: anchorChoices,
              correctChoice: anchorChoices.indexOf('$anchorProduct'),
              evidenceKey: 'anchorFact',
              evidenceCompetency: MicroCompetencyId.multiplicationFacts,
            ),
            GuidedMethodStep(
              title: 'Zur Zielaufgabe',
              instruction: difference >= 0
                  ? 'Für ×$b kommen $delta dazu.'
                  : 'Für ×$b gehen $delta weg.',
            ),
            GuidedMethodStep(
              title: 'Ergebnis',
              instruction: '$a × $b = $result.',
            ),
          ],
        );
    }
  }

  static GuidedMethodGuide _numberWallGuide(String taskKey) {
    final parts = taskKey.split(':');
    if (parts.length < 3 || parts[0] != 'wall') {
      return const GuidedMethodGuide(
        methodKey: 'numberWall:relationDirection',
        methodLabel: 'Zahlenmauer vorwärts und rückwärts',
        nudge:
            'Nach oben werden die beiden Steine darunter addiert. Fehlt unten ein Stein, rechnest du von einem bekannten oberen Stein rückwärts.',
        steps: [
          GuidedMethodStep(
            title: 'Richtung prüfen',
            instruction:
                'Liegt der fehlende Stein über zwei bekannten Steinen, brauchst du Plus. Liegt er darunter, brauchst du Minus.',
          ),
        ],
      );
    }

    final values = parts[1]
        .split('-')
        .map(int.tryParse)
        .toList(growable: false);
    final hidden = int.tryParse(parts[2]);
    if (values.length != 6 ||
        values.any((value) => value == null) ||
        hidden == null ||
        hidden < 0 ||
        hidden > 5) {
      return const GuidedMethodGuide(
        methodKey: 'numberWall:relationDirection',
        methodLabel: 'Zahlenmauer vorwärts und rückwärts',
        nudge:
            'Nach oben werden die beiden Steine darunter addiert. Fehlt unten ein Stein, rechnest du rückwärts mit Minus.',
        steps: [
          GuidedMethodStep(
            title: 'Richtung prüfen',
            instruction:
                'Prüfe zuerst, ob du in der Zahlenmauer nach oben oder rückwärts nach unten rechnest.',
          ),
        ],
      );
    }

    final wall = values.cast<int>();
    final addition = hidden >= 3;
    final rawChoices = <String>['Plus (+)', 'Minus (−)'];
    final shift = wall.fold<int>(hidden, (sum, value) => sum + value) % 2;
    final choices = <String>[
      ...rawChoices.skip(shift),
      ...rawChoices.take(shift),
    ];
    final correct = addition ? 'Plus (+)' : 'Minus (−)';
    final calculation = switch (hidden) {
      0 => '${wall[3]} − ${wall[1]} = ?',
      1 => '${wall[3]} − ${wall[0]} = ?',
      2 => '${wall[4]} − ${wall[1]} = ?',
      3 => '${wall[0]} + ${wall[1]} = ?',
      4 => '${wall[1]} + ${wall[2]} = ?',
      _ => '${wall[3]} + ${wall[4]} = ?',
    };

    return GuidedMethodGuide(
      methodKey: 'numberWall:relationDirection',
      methodLabel: 'Zahlenmauer vorwärts und rückwärts',
      nudge:
          'Schau auf die Lage des fehlenden Steins: Nach oben wird addiert, nach unten rechnest du von einem bekannten Summenstein rückwärts.',
      steps: [
        GuidedMethodStep(
          title: 'Rechenrichtung erkennen',
          instruction:
              'Entscheide zuerst, ob du die Mauer nach oben aufbaust oder einen unteren Stein rückwärts bestimmst.',
          question:
              'Welche Rechenart hilft dir direkt beim fehlenden Stein?',
          choices: choices,
          correctChoice: choices.indexOf(correct),
          evidenceKey: 'wallOperationChoice',
          evidenceCompetency: MicroCompetencyId.numberRelations,
          evidenceWeight: 0.40,
        ),
        GuidedMethodStep(
          title: 'Passende Nachbarsteine verwenden',
          instruction:
              'Nutze jetzt genau die zusammengehörenden Steine: $calculation',
        ),
      ],
    );
  }

  static GuidedMethodGuide _moneyGuide(String taskKey) {
    final parts = taskKey.split(':');
    final family = parts.length >= 2 ? parts[1] : '';
    final addition = family == 'add';
    final subtraction = family == 'change' || family == 'missing';

    if (!addition && !subtraction) {
      return GuidedMethodGuide(
        methodKey: 'money:representAndCalculate',
        methodLabel: 'Geldbetrag darstellen und rechnen',
        nudge:
            'Stelle den Geldbetrag zuerst mit passenden Münzen oder der Beziehung zwischen Euro und Cent dar.',
        steps: [
          const GuidedMethodStep(
            title: 'Geldwert klären',
            instruction:
                'Achte darauf, welche Münzen oder welche Einheit angegeben sind.',
          ),
          GuidedMethodStep(
            title: 'Passend rechnen',
            instruction: family == 'convert'
                ? 'Nutze die Grundbeziehung 1 € = 100 ct.'
                : 'Bestimme danach den gesamten dargestellten Geldwert.',
          ),
        ],
      );
    }

    final numbers = _numbers(taskKey);
    final shift = numbers.fold<int>(0, (sum, value) => sum + value) % 2;
    final rawChoices = <String>['Plus (+)', 'Minus (−)'];
    final choices = <String>[
      ...rawChoices.skip(shift),
      ...rawChoices.take(shift),
    ];
    final correct = addition ? 'Plus (+)' : 'Minus (−)';

    return GuidedMethodGuide(
      methodKey: 'money:calculationPlan',
      methodLabel: 'Geldaufgabe zuerst als Rechenplan lesen',
      nudge:
          'Überlege zuerst: Werden Geldbeträge zusammengelegt, oder geht ein Betrag von einem vorhandenen bzw. gesamten Betrag weg?',
      steps: [
        GuidedMethodStep(
          title: 'Rechenart erkennen',
          instruction:
              'Entscheide vor dem Rechnen, welche Veränderung mit dem Geld beschrieben wird.',
          question: 'Welche Rechenart passt zu dieser Geldsituation?',
          choices: choices,
          correctChoice: choices.indexOf(correct),
          evidenceKey: 'moneyOperationChoice',
          evidenceCompetency: MicroCompetencyId.moneyCalculation,
          evidenceWeight: 0.40,
        ),
        GuidedMethodStep(
          title: 'Mit den Geldbeträgen rechnen',
          instruction: addition
              ? 'Lege beide Preise zusammen und addiere erst jetzt die Beträge.'
              : 'Ziehe den bekannten oder ausgegebenen Betrag erst jetzt vom vorhandenen Gesamtbetrag ab.',
        ),
      ],
    );
  }

  static GuidedMethodGuide _doublesHalvesGuide(String taskKey) {
    final isDouble = taskKey.startsWith('double:');
    final isHalf = taskKey.startsWith('half:');
    final values = _numbers(taskKey);
    final value = values.isEmpty ? null : values.last;

    if (!isDouble && !isHalf) {
      return const GuidedMethodGuide(
        methodKey: 'doublesHalves:relationship',
        methodLabel: 'Doppeln und Halbieren verstehen',
        nudge:
            'Überlege zuerst, ob dieselbe Menge zweimal gebraucht oder eine Menge in zwei gleich große Teile geteilt wird.',
        steps: [
          GuidedMethodStep(
            title: 'Beziehung klären',
            instruction:
                'Doppeln und Halbieren sind zwei verschiedene Beziehungen zwischen gleich großen Mengen.',
          ),
        ],
      );
    }

    final choices = <String>[
      'zweimal dieselbe Menge zusammen',
      'in zwei gleich große Teile teilen',
    ];
    final correct = isDouble
        ? 'zweimal dieselbe Menge zusammen'
        : 'in zwei gleich große Teile teilen';

    return GuidedMethodGuide(
      methodKey: 'doublesHalves:relationship',
      methodLabel: 'Doppeln und Halbieren verstehen',
      nudge: isDouble
          ? 'Beim Doppeln brauchst du dieselbe Menge zweimal.'
          : 'Bei der Hälfte entstehen zwei gleich große Teile.',
      steps: [
        GuidedMethodStep(
          title: 'Beziehung erkennen',
          instruction:
              'Entscheide zuerst, was das Wort in der Aufgabe mathematisch bedeutet.',
          question: isDouble
              ? 'Was bedeutet „das Doppelte“?'
              : 'Was bedeutet „die Hälfte“?',
          choices: choices,
          correctChoice: choices.indexOf(correct),
          evidenceKey: 'doubleHalfMeaning',
          evidenceCompetency: MicroCompetencyId.doublesHalves,
          evidenceWeight: 0.40,
        ),
        GuidedMethodStep(
          title: 'Beziehung anwenden',
          instruction: value == null
              ? 'Wende die erkannte Beziehung jetzt auf die Zahl an.'
              : isDouble
                  ? 'Nimm $value zweimal: $value + $value.'
                  : 'Teile $value in zwei gleich große Teile.',
        ),
      ],
    );
  }

  static GuidedMethodGuide _inverseRelationshipGuide(
    String taskKey,
  ) {
    final parts = taskKey.split(':');
    if (!taskKey.startsWith('family:') || parts.length < 4) {
      return const GuidedMethodGuide(
        methodKey: 'inverse:operationRelationship',
        methodLabel: 'Umkehraufgabe nutzen',
        nudge:
            'Suche die Gegenrechenart, die den letzten Rechenschritt wieder rückgängig macht.',
        steps: [
          GuidedMethodStep(
            title: 'Gegenrechenart finden',
            instruction:
                'Plus und Minus sowie Mal und Teilen gehören jeweils als Umkehroperationen zusammen.',
          ),
          GuidedMethodStep(
            title: 'Zurückrechnen',
            instruction:
                'Wende die passende Gegenrechenart auf das Ergebnis an.',
          ),
        ],
      );
    }

    final operation = parts[1];
    final a = int.tryParse(parts[2]);
    final b = int.tryParse(parts[3]);
    if (a == null || b == null || (operation != '+' && operation != 'x')) {
      return const GuidedMethodGuide(
        methodKey: 'inverse:operationRelationship',
        methodLabel: 'Umkehraufgabe nutzen',
        nudge:
            'Suche die Gegenrechenart, die den letzten Rechenschritt wieder rückgängig macht.',
        steps: [
          GuidedMethodStep(
            title: 'Gegenrechenart finden',
            instruction:
                'Überlege, welche Rechenart den vorherigen Schritt rückgängig macht.',
          ),
        ],
      );
    }

    final additive = operation == '+';
    final sourceOperation = additive ? '+$b' : '×$b';
    final inverseOperation = additive ? '−$b' : '÷$b';
    final rawChoices =
        additive ? <String>['+$b', '−$b'] : <String>['×$b', '÷$b'];
    final shift = (a + b) % rawChoices.length;
    final choices = <String>[
      ...rawChoices.skip(shift),
      ...rawChoices.take(shift),
    ];
    final result = additive ? a + b : a * b;

    return GuidedMethodGuide(
      methodKey: 'inverse:operationRelationship',
      methodLabel: 'Umkehraufgabe nutzen',
      nudge:
          'Gehe vom Ergebnis zurück. Suche dafür die Gegenrechenart zum letzten Rechenschritt.',
      steps: [
        GuidedMethodStep(
          title: 'Umkehroperation erkennen',
          instruction:
              'Entscheide zuerst, welche Operation $sourceOperation wieder rückgängig macht.',
          question:
              'Welche Rechenoperation macht $sourceOperation wieder rückgängig?',
          choices: choices,
          correctChoice: choices.indexOf(inverseOperation),
          evidenceKey: 'inverseOperationChoice',
          evidenceCompetency: MicroCompetencyId.inverseRelationship,
          evidenceWeight: 0.40,
        ),
        GuidedMethodStep(
          title: 'Zurückrechnen',
          instruction:
              'Wende $inverseOperation auf $result an. So kommst du wieder zur Ausgangszahl zurück.',
        ),
      ],
    );
  }

  static GuidedMethodGuide _divisionFact(MathFact fact) {
    final dividend = fact.a;
    final divisor = fact.b;
    final correct = '$divisor × ? = $dividend';
    final rawChoices = <String>[
      correct,
      '$dividend × ? = $divisor',
      '$divisor + ? = $dividend',
      '$dividend − ? = $divisor',
    ];
    final shift = (dividend + divisor) % rawChoices.length;
    final choices = <String>[
      ...rawChoices.skip(shift),
      ...rawChoices.take(shift),
    ];

    return GuidedMethodGuide(
      methodKey: 'division:inverseMultiplication',
      methodLabel: 'Geteilt mit der Mal-Umkehraufgabe',
      nudge:
          'Suche die passende Malaufgabe mit einer Lücke. Der Teiler wird dabei zu einem bekannten Faktor.',
      steps: [
        GuidedMethodStep(
          title: 'Mal-Umkehraufgabe finden',
          instruction:
              'Forme $dividend ÷ $divisor zuerst in eine passende Malaufgabe mit einer Lücke um.',
          question:
              'Welche Mal-Umkehraufgabe passt zu $dividend ÷ $divisor?',
          choices: choices,
          correctChoice: choices.indexOf(correct),
          evidenceKey: 'matchingMultiplicationFact',
          evidenceCompetency: MicroCompetencyId.divisionFacts,
          evidenceWeight: 0.40,
        ),
        const GuidedMethodStep(
          title: 'Fehlenden Faktor bestimmen',
          instruction:
              'Bestimme erst danach den fehlenden Faktor. Dieser ist der Quotient der Geteilt-Aufgabe.',
        ),
      ],
    );
  }

  static GuidedMethodGuide _writtenMultiplication(
    int a,
    int b,
    int expected,
  ) {
    if (b < 10) {
      final ones = a % 10;
      final columnProduct = ones * b;
      final carry = columnProduct ~/ 10;
      final productChoices = _numberChoices(
        columnProduct,
        maxValue: max(20, columnProduct + 10),
      );
      final carryChoices = _numberChoices(
        carry,
        maxValue: max(9, carry + 2),
      );
      return GuidedMethodGuide(
        methodKey: 'writtenMultiplication:singleDigit',
        methodLabel: 'Schriftliche Multiplikation',
        nudge:
            'Beginne rechts bei den Einern. Multipliziere Stelle für Stelle und notiere jeden Übertrag.',
        steps: [
          GuidedMethodStep(
            title: 'Einer-Spalte',
            instruction:
                'Rechne zuerst nur die Einerziffer $ones × $b.',
            question: 'Was ergibt $ones × $b in der ersten Spalte?',
            choices: productChoices,
            correctChoice: productChoices.indexOf('$columnProduct'),
            evidenceKey: 'firstPartialProduct',
            evidenceCompetency:
                MicroCompetencyId.writtenMultiplyProcedure,
          ),
          GuidedMethodStep(
            title: 'Übertrag notieren',
            instruction:
                'Die Einerziffer bleibt unten. Alles darüber wird in die nächste Spalte übertragen.',
            question: 'Welchen Übertrag gibst du in die nächste Spalte?',
            choices: carryChoices,
            correctChoice: carryChoices.indexOf('$carry'),
            evidenceKey: 'multiplicationCarry',
            evidenceCompetency:
                MicroCompetencyId.writtenMultiplyProcedure,
          ),
          GuidedMethodStep(
            title: 'Probe',
            instruction:
                'Prüfe $expected mit einem Überschlag oder durch Zerlegen des Faktors.',
          ),
        ],
      );
    }

    final onesMultiplier = b % 10;
    final tensMultiplier = (b ~/ 10) % 10;
    final firstPartialProduct = a * onesMultiplier;
    final productChoices = _numberChoices(
      firstPartialProduct,
      maxValue: max(20, firstPartialProduct + 10),
    );
    final digitChoices = _numberChoices(
      tensMultiplier,
      maxValue: 9,
    );
    return GuidedMethodGuide(
      methodKey: 'writtenMultiplication:partialProducts',
      methodLabel: 'Schriftliche Multiplikation mit Teilprodukten',
      nudge:
          'Beginne mit der Einerziffer des zweiten Faktors. Danach folgt die Zehnerziffer in der nächsten Stellenlage.',
      steps: [
        GuidedMethodStep(
          title: 'Erstes Teilprodukt',
          instruction:
              'Multipliziere $a zuerst mit der Einerziffer $onesMultiplier von $b.',
          question:
              'Welches erste Teilprodukt ergibt $a × $onesMultiplier?',
          choices: productChoices,
          correctChoice:
              productChoices.indexOf('$firstPartialProduct'),
          evidenceKey: 'firstPartialProduct',
          evidenceCompetency:
              MicroCompetencyId.writtenMultiplyProcedure,
        ),
        GuidedMethodStep(
          title: 'Nächste Ziffer',
          instruction:
              'Für die nächste Teilproduktzeile gehst du eine Stelle nach links.',
          question:
              'Mit welcher Ziffer von $b rechnest du als Nächstes?',
          choices: digitChoices,
          correctChoice: digitChoices.indexOf('$tensMultiplier'),
          evidenceKey: 'nextMultiplierDigit',
          evidenceCompetency:
              MicroCompetencyId.writtenMultiplyProcedure,
        ),
        GuidedMethodStep(
          title: 'Teilprodukte addieren',
          instruction:
              'Richte die Teilprodukte stellenrichtig aus und addiere sie zu $expected.',
        ),
      ],
    );
  }

  static GuidedMethodGuide _writtenDivision(
    int dividend,
    int divisor,
  ) {
    final firstChunk = _firstDivisionChunk(dividend, divisor);
    final quotientDigit = firstChunk ~/ divisor;
    final remainder = firstChunk % divisor;
    final quotientChoices = _numberChoices(
      quotientDigit,
      maxValue: max(9, quotientDigit + 2),
    );
    final remainderChoices = _numberChoices(
      remainder,
      maxValue: max(divisor - 1, remainder + 2),
    );
    return GuidedMethodGuide(
      methodKey: 'writtenDivision:standard',
      methodLabel: 'Schriftliche Division',
      nudge:
          'Arbeite von links nach rechts: teilen, multiplizieren, abziehen und die nächste Ziffer herunterholen.',
      steps: [
        GuidedMethodStep(
          title: 'Erste Quotientenziffer',
          instruction:
              'Nimm von links so viele Ziffern, bis die Zahl mindestens so groß wie $divisor ist. Hier startest du mit $firstChunk.',
          question: 'Wie oft passt $divisor in $firstChunk?',
          choices: quotientChoices,
          correctChoice: quotientChoices.indexOf('$quotientDigit'),
          evidenceKey: 'firstQuotientDigit',
          evidenceCompetency:
              MicroCompetencyId.writtenDivideProcedure,
        ),
        GuidedMethodStep(
          title: 'Rest des ersten Schritts',
          instruction:
              'Multipliziere $quotientDigit × $divisor und ziehe dieses Ergebnis von $firstChunk ab.',
          question:
              'Welcher Rest bleibt nach diesem ersten Divisionsschritt?',
          choices: remainderChoices,
          correctChoice: remainderChoices.indexOf('$remainder'),
          evidenceKey: 'firstDivisionRemainder',
          evidenceCompetency:
              MicroCompetencyId.writtenDivideProcedure,
        ),
        const GuidedMethodStep(
          title: 'Weiterführen',
          instruction:
              'Hole die nächste Ziffer herunter und wiederhole dieselben vier Schritte bis zum Ende.',
        ),
      ],
    );
  }

  static GuidedMethodGuide _writtenAddition(
    int a,
    int b,
    int expected,
  ) {
    final lowerOnes = b % 10;
    final onesChoices = _numberChoices(lowerOnes, maxValue: 9);
    final carryPlace = _firstDirectRegroupingPlace(
      a,
      b,
      addition: true,
    );
    final needsCarry = carryPlace != null;
    return GuidedMethodGuide(
      methodKey: 'writtenAddition:standard',
      methodLabel: 'Schriftliche Addition',
      nudge:
          'Schreibe Einer unter Einer, Zehner unter Zehner und rechne von rechts nach links.',
      steps: [
        GuidedMethodStep(
          title: 'Stellen ausrichten',
          instruction:
              'Kontrolliere zuerst die Einer-Spalte, bevor du rechnest.',
          question: 'Welche Ziffer steht unten in der Einer-Spalte?',
          choices: onesChoices,
          correctChoice: onesChoices.indexOf('$lowerOnes'),
          evidenceKey: 'onesAlignment',
          evidenceCompetency: MicroCompetencyId.writtenAlignment,
        ),
        GuidedMethodStep(
          title: 'Übertrag prüfen',
          instruction: needsCarry
              ? 'Prüfe die ${_placeLabel(carryPlace)} und notiere den Übertrag in die nächste Stelle.'
              : 'Prüfe jede Spalte, ob ein Übertrag entsteht.',
          question: needsCarry
              ? 'Entsteht in der ${_placeLabel(carryPlace)} ein Übertrag?'
              : 'Entsteht bei dieser Aufgabe ein Übertrag?',
          choices: const ['Ja', 'Nein'],
          correctChoice: needsCarry ? 0 : 1,
          evidenceKey: needsCarry ? 'carryDecision' : null,
          evidenceCompetency:
              needsCarry ? MicroCompetencyId.writtenRegrouping : null,
        ),
        GuidedMethodStep(
          title: 'Probe',
          instruction:
              'Prüfe dein Ergebnis $expected mit einer Überschlagsrechnung.',
        ),
      ],
    );
  }

  static GuidedMethodGuide _writtenSubtraction(
    int a,
    int b,
    int expected,
    MethodPreferences preferences,
  ) {
    final strategy = preferences.writtenSubtraction;
    final lowerOnes = b % 10;
    final onesChoices = _numberChoices(lowerOnes, maxValue: 9);
    final regroupPlace = _firstDirectRegroupingPlace(
      a,
      b,
      addition: false,
    );
    final needsRegrouping = regroupPlace != null;
    final usesEntbuendeln = strategy == WrittenSubtractionStrategy.regroup;
    return GuidedMethodGuide(
      methodKey: 'writtenSubtraction:${strategy.name}',
      methodLabel: strategy.label,
      nudge: 'Schreibe Einer unter Einer, Zehner unter Zehner und Hunderter unter Hunderter.',
      steps: [
        GuidedMethodStep(
          title: 'Stellen ausrichten',
          instruction:
              'Kontrolliere zuerst die Einer-Spalte, bevor du rechnest.',
          question: 'Welche Ziffer steht unten in der Einer-Spalte?',
          choices: onesChoices,
          correctChoice: onesChoices.indexOf('$lowerOnes'),
          evidenceKey: 'onesAlignment',
          evidenceCompetency: MicroCompetencyId.writtenAlignment,
        ),
        GuidedMethodStep(
          title: usesEntbuendeln ? 'Entbündeln' : 'Ergänzen',
          instruction: strategy.description,
          question: needsRegrouping
              ? usesEntbuendeln
                  ? 'Musst du in der ${_placeLabel(regroupPlace)} entbündeln?'
                  : 'Musst du in der ${_placeLabel(regroupPlace)} über 10 ergänzen und einen Übertrag beachten?'
              : usesEntbuendeln
                  ? 'Musst du bei dieser Aufgabe entbündeln?'
                  : 'Brauchst du bei dieser Aufgabe einen Übertrag?',
          choices: const ['Ja', 'Nein'],
          correctChoice: needsRegrouping ? 0 : 1,
          evidenceKey: needsRegrouping
              ? usesEntbuendeln
                  ? 'regroupDecision'
                  : 'carryDecision'
              : null,
          evidenceCompetency:
              needsRegrouping ? MicroCompetencyId.writtenRegrouping : null,
        ),
        GuidedMethodStep(
          title: 'Probe',
          instruction: 'Prüfe dein Ergebnis $expected mit der passenden Umkehraufgabe.',
        ),
      ],
    );
  }

  static GuidedMethodGuide _wordProblem(String key) {
    final operation = key.startsWith('story:+:')
        ? 'Plus'
        : key.startsWith('story:-:')
            ? 'Minus'
            : key.startsWith('story:x:')
                ? 'Mal'
                : key.startsWith('story:divide:') ||
                        key.startsWith('story:sharing:') ||
                        key.startsWith('story:grouping:')
                    ? 'Geteilt'
                    : 'die passende Rechenart';
    final evidenceStep = _wordProblemEvidenceStep(key);
    return GuidedMethodGuide(
      methodKey: 'wordProblem:meaning',
      methodLabel: 'Text zuerst verstehen',
      nudge:
          'Was verändert sich in der Geschichte: wird etwas mehr, weniger, gruppiert oder verteilt?',
      steps: [
        const GuidedMethodStep(
          title: 'Frage finden',
          instruction: 'Lies zuerst nur den letzten Satz: Was wird gesucht?',
        ),
        if (evidenceStep != null)
          evidenceStep
        else
          GuidedMethodStep(
            title: 'Handlung erkennen',
            instruction: 'Hier passt $operation.',
          ),
        const GuidedMethodStep(
          title: 'Angaben prüfen',
          instruction:
              'Nimm nur die Zahlen, die für die Frage wirklich gebraucht werden.',
        ),
      ],
    );
  }

  static GuidedMethodStep? _wordProblemEvidenceStep(String key) {
    final parts = key.split(':');
    if (parts.length < 3 || parts.first != 'story') return null;

    if ((parts[1] == 'sharing' || parts[1] == 'grouping') &&
        parts.length >= 5) {
      final sharing = parts[1] == 'sharing';
      const choices = [
        'Anzahl der Gruppen',
        'Menge in jeder Gruppe',
        'Gesamtmenge',
      ];
      return GuidedMethodStep(
        title: sharing ? 'Verteilen verstehen' : 'Gruppieren verstehen',
        instruction: sharing
            ? 'Die Anzahl der Gruppen ist schon bekannt. Gesucht ist, wie viel jede Gruppe bekommt.'
            : 'Die Größe jeder Gruppe ist schon bekannt. Gesucht ist, wie viele Gruppen entstehen.',
        question: 'Welche Größe musst du herausfinden?',
        choices: choices,
        correctChoice: sharing ? 1 : 0,
        evidenceKey: 'divisionTargetQuantity',
        evidenceCompetency: MicroCompetencyId.divisionSharing,
        evidenceWeight: 0.40,
      );
    }

    if (parts[1] == 'info' && parts.length >= 6) {
      final kind = parts[2];
      final a = int.tryParse(parts[3]);
      final b = int.tryParse(parts[4]);
      final distractor = int.tryParse(parts[5]);
      if (a == null || b == null || distractor == null) return null;

      final (question, correct, choices) = switch (kind) {
        'trip' => (
            'Welche Angaben brauchst du für die Anzahl der Personen?',
            '$a Kinder und $b Erwachsene',
            <String>[
              '$a Kinder und $b Erwachsene',
              '$a Kinder und $distractor Bälle',
              '$b Erwachsene und $distractor Bälle',
              'Nur die $distractor Bälle',
            ],
          ),
        'pencils' => (
            'Welche Angaben brauchst du für die Anzahl aller Stifte?',
            '$a rote und $b blaue Stifte',
            <String>[
              '$a rote und $b blaue Stifte',
              '$a rote Stifte und $distractor Schachteln',
              '$b blaue Stifte und $distractor Schachteln',
              'Nur die $distractor Schachteln',
            ],
          ),
        'groups' => (
            'Welche Angaben brauchst du für die Anzahl aller Kinder?',
            '$a und $b Kinder',
            <String>[
              '$a und $b Kinder',
              '$a Kinder und $distractor Seiten',
              '$b Kinder und $distractor Seiten',
              'Nur die $distractor Seiten',
            ],
          ),
        _ => ('', '', const <String>[]),
      };
      if (choices.isEmpty) return null;
      return GuidedMethodStep(
        title: 'Wichtige Angaben auswählen',
        instruction:
            'Prüfe jede Zahl daran, ob sie wirklich zur gestellten Frage gehört.',
        question: question,
        choices: choices,
        correctChoice: choices.indexOf(correct),
        evidenceKey: 'storyInfo',
        evidenceCompetency:
            MicroCompetencyId.wordProblemRelevantInformation,
      );
    }

    if (parts[1] == 'operation' && parts.length >= 5) {
      final operation = parts[2];
      final choices = operation == 'x' || operation == 'divide'
          ? const ['Plus (+)', 'Minus (−)', 'Mal (×)', 'Geteilt (÷)']
          : const ['Plus (+)', 'Minus (−)'];
      final correct = switch (operation) {
        '+' => 'Plus (+)',
        '-' => 'Minus (−)',
        'x' => 'Mal (×)',
        'divide' => 'Geteilt (÷)',
        _ => '',
      };
      if (correct.isEmpty) return null;
      return GuidedMethodStep(
        title: 'Rechenart wählen',
        instruction:
            'Entscheide nach der Handlung im Text, nicht nur nach einzelnen Signalwörtern.',
        question: 'Welche Rechenart passt zur Handlung?',
        choices: choices,
        correctChoice: choices.indexOf(correct),
        evidenceKey: 'storyOperation',
        evidenceCompetency: MicroCompetencyId.wordProblemOperation,
      );
    }

    if (parts[1] == 'equation' && parts.length >= 5) {
      final operation = parts[2];
      final a = int.tryParse(parts[3]);
      final b = int.tryParse(parts[4]);
      if (a == null || b == null) return null;
      final correct = switch (operation) {
        '+' => '$a + $b',
        '-' => '$a − $b',
        'x' => '$a × $b',
        'divide' => '$a ÷ $b',
        _ => '',
      };
      if (correct.isEmpty) return null;
      final choices = switch (operation) {
        '+' => <String>[correct, '$a − $b', '$a × $b', '$b + $a'],
        '-' => <String>[correct, '$a + $b', '$b − $a', '$a × $b'],
        'x' => <String>[correct, '$a + $b', '$a − $b', '$b ÷ $a'],
        'divide' => <String>[correct, '$a − $b', '$a + $b', '$b ÷ $a'],
        _ => <String>[],
      };
      return GuidedMethodStep(
        title: 'Rechnung aufschreiben',
        instruction:
            'Ordne die wichtigen Zahlen in genau der Reihenfolge an, die zur Handlung passt.',
        question: 'Welche Rechnung beschreibt die Sachlage?',
        choices: choices,
        correctChoice: choices.indexOf(correct),
        evidenceKey: 'storyEquation',
        evidenceCompetency: MicroCompetencyId.wordProblemModel,
      );
    }

    if (parts[1] == 'calc' && parts.length >= 5) {
      final operation = parts[2];
      final a = int.tryParse(parts[3]);
      final b = int.tryParse(parts[4]);
      if (a == null || b == null) return null;
      final result = switch (operation) {
        '+' => a + b,
        '-' => a - b,
        'x' => a * b,
        'divide' when b != 0 => a ~/ b,
        _ => null,
      };
      if (result == null) return null;
      final choices = _numberChoices(
        result,
        maxValue: max(20, result + 10),
      );
      return GuidedMethodStep(
        title: 'Rechnung ausführen',
        instruction:
            'Die Sachlage ist modelliert. Rechne jetzt nur noch die passende Rechnung korrekt aus.',
        question: 'Welches Rechenergebnis erhältst du?',
        choices: choices,
        correctChoice: choices.indexOf('$result'),
        evidenceKey: 'storyCalculation',
        evidenceCompetency: MicroCompetencyId.wordProblemCalculation,
      );
    }

    if (parts[1] == 'interpret' && parts.length >= 6) {
      final operation = parts[2];
      final result = int.tryParse(parts[5]);
      if (result == null) return null;
      final correct = operation == '+'
          ? 'Mara hat jetzt $result Sticker.'
          : 'Es bleiben $result Karten übrig.';
      final choices = operation == '+'
          ? <String>[
              correct,
              'Mara hat $result Sticker abgegeben.',
              'Es kommen noch $result Sticker dazu.',
              'Im Raum sind $result Kinder.',
            ]
          : <String>[
              correct,
              'Es wurden $result Karten weggenommen.',
              'Am Anfang lagen $result Karten dort.',
              'Es kommen $result Karten dazu.',
            ];
      return GuidedMethodStep(
        title: 'Ergebnis deuten',
        instruction:
            'Verbinde die Ergebniszahl wieder mit der Frage und der Sache, um die es geht.',
        question: 'Welche Antwort passt wirklich zur Situation?',
        choices: choices,
        correctChoice: 0,
        evidenceKey: 'storyInterpretation',
        evidenceCompetency: MicroCompetencyId.wordProblemInterpretation,
      );
    }

    return null;
  }

  static GuidedMethodGuide _largeNumbers(String taskKey) {
    final parts = taskKey.split(':');

    if (taskKey.startsWith('large:compare:') && parts.length >= 4) {
      final a = int.tryParse(parts[2]);
      final b = int.tryParse(parts[3]);
      if (a != null && b != null) {
        final place = _firstDifferentPlace(a, b);
        final aDigit = (a ~/ place) % 10;
        final bDigit = (b ~/ place) % 10;
        final placeChoices = _largePlaceChoices(a, b);
        final placeLabel = _largePlaceLabel(place);
        return GuidedMethodGuide(
          methodKey: 'largeNumbers:compare',
          methodLabel: 'Zahlen vergleichen',
          nudge:
              'Vergleiche von links nach rechts. Überspringe Stellen, an denen beide Ziffern gleich sind.',
          steps: [
            GuidedMethodStep(
              title: 'Erste unterschiedliche Stelle finden',
              instruction:
                  'Beginne ganz links und gehe erst eine Stelle weiter, wenn beide Ziffern dort gleich sind.',
              question: 'Welche Stelle entscheidet bei diesem Vergleich zuerst?',
              choices: placeChoices,
              correctChoice: placeChoices.indexOf(placeLabel),
              evidenceKey: 'decidingPlace',
              evidenceCompetency: MicroCompetencyId.largeNumberCompare,
              evidenceWeight: 0.40,
            ),
            GuidedMethodStep(
              title: 'Ziffern an dieser Stelle vergleichen',
              instruction:
                  'An der $placeLabel stehen $aDigit und $bDigit gegenüber.',
            ),
            GuidedMethodStep(
              title: 'Zeichen wählen',
              instruction: aDigit > bDigit
                  ? '$aDigit ist größer als $bDigit. Deshalb ist die erste Zahl größer.'
                  : '$aDigit ist kleiner als $bDigit. Deshalb ist die erste Zahl kleiner.',
            ),
          ],
        );
      }
    }

    if (taskKey.startsWith('large:place:') && parts.length >= 4) {
      final number = int.tryParse(parts[2]);
      final place = int.tryParse(parts[3]);
      if (number != null && place != null) {
        final digit = (number ~/ place) % 10;
        return GuidedMethodGuide(
          methodKey: 'largeNumbers:placeValue',
          methodLabel: 'Stellenwert lesen',
          nudge:
              'Suche zuerst die ${_largePlaceLabel(place)} und lies dann nur die Ziffer an dieser Stelle ab.',
          steps: [
            GuidedMethodStep(
              title: 'Stelle finden',
              instruction:
                  'Gehe in der Stellenwerttafel zur ${_largePlaceLabel(place)}.',
            ),
            GuidedMethodStep(
              title: 'Ziffer ablesen',
              instruction: 'Bei $number steht dort die Ziffer $digit.',
            ),
          ],
        );
      }
    }

    if (taskKey.startsWith('large:decompose:')) {
      final number = parts.length >= 3 ? int.tryParse(parts[2]) : null;
      final place = parts.length >= 4 ? int.tryParse(parts[3]) : null;
      if (number != null && place != null && place >= 10) {
        final digit = (number ~/ place) % 10;
        final contribution = digit * place;
        final values = <int>{
          contribution,
          digit,
          digit * 10,
          digit * 100,
          digit * 1000,
          digit * 10000,
          digit * 100000,
        }.where((value) => value > 0).toList()
          ..sort();
        var next = contribution + place;
        while (values.length < 4) {
          if (!values.contains(next)) values.add(next);
          next += place;
        }
        final choices = values.take(4).map((value) => '$value').toList();
        if (!choices.contains('$contribution')) {
          choices[choices.length - 1] = '$contribution';
          choices.sort(
            (a, b) => int.parse(a).compareTo(int.parse(b)),
          );
        }
        final placeLabel = _largePlaceLabel(place);
        return GuidedMethodGuide(
          methodKey: 'largeNumbers:decompose',
          methodLabel: 'Stellenwerte zusammensetzen',
          nudge:
              'Bestimme zuerst den Wert einer einzelnen Ziffer an ihrer Stelle, bevor du die ganze Zahl zusammensetzt.',
          steps: [
            GuidedMethodStep(
              title: 'Stellenwertbeitrag bestimmen',
              instruction:
                  'Eine Ziffer erhält ihren Wert erst durch ihre Stelle. Bestimme nur diesen einen Stellenwertbeitrag.',
              question:
                  'Welchen Wert trägt die Ziffer $digit an der $placeLabel bei?',
              choices: choices,
              correctChoice: choices.indexOf('$contribution'),
              evidenceKey: 'placeValueContribution',
              evidenceCompetency: MicroCompetencyId.placeValueDecompose,
              evidenceWeight: 0.40,
            ),
            GuidedMethodStep(
              title: 'Übrige Stellen ergänzen',
              instruction:
                  'Der Beitrag an der $placeLabel ist $contribution. Bestimme danach die Werte der übrigen Ziffern.',
            ),
            const GuidedMethodStep(
              title: 'Zahl zusammensetzen',
              instruction:
                  'Addiere die Stellenwertbeiträge erst am Ende zur vollständigen Zahl.',
            ),
          ],
        );
      }
      return const GuidedMethodGuide(
        methodKey: 'largeNumbers:decompose',
        methodLabel: 'Stellenwerte zusammensetzen',
        nudge:
            'Ordne jede Ziffer ihrer Stelle zu und setze die Zahl von links nach rechts zusammen.',
        steps: [
          GuidedMethodStep(
            title: 'Stellen zuordnen',
            instruction:
                'M, HT, ZT, T, H, Z und E haben feste Plätze. Fehlende Stellen werden mit 0 besetzt.',
          ),
          GuidedMethodStep(
            title: 'Zahl lesen',
            instruction:
                'Lies die vollständig zusammengesetzte Zahl anschließend von links nach rechts.',
          ),
        ],
      );
    }

    if (taskKey.startsWith('large:order:')) {
      final values = _numbers(taskKey);
      if (values.length >= 3) {
        final ordered = values.toList()..sort();
        final choices = ordered.map((value) => '$value').toList();
        return GuidedMethodGuide(
          methodKey: 'largeNumbers:order',
          methodLabel: 'Große Zahlen ordnen',
          nudge:
              'Finde zuerst sicher die kleinste Zahl. Erst danach ordnest du die beiden übrigen.',
          steps: [
            GuidedMethodStep(
              title: 'Kleinste Zahl bestimmen',
              instruction:
                  'Vergleiche die Zahlen von links nach rechts. Die erste unterschiedliche Stelle entscheidet.',
              question:
                  'Welche der drei Zahlen muss beim Ordnen von klein nach groß zuerst stehen?',
              choices: choices,
              correctChoice: choices.indexOf('${ordered.first}'),
              evidenceKey: 'smallestOrderedNumber',
              evidenceCompetency: MicroCompetencyId.largeNumberOrder,
              evidenceWeight: 0.40,
            ),
            const GuidedMethodStep(
              title: 'Übrige Zahlen ordnen',
              instruction:
                  'Vergleiche danach die beiden übrigen Zahlen auf dieselbe Weise.',
            ),
            const GuidedMethodStep(
              title: 'Reihenfolge prüfen',
              instruction:
                  'Lies die fertige Reihe von links nach rechts: Jede Zahl muss größer als die vorherige sein.',
            ),
          ],
        );
      }
      return const GuidedMethodGuide(
        methodKey: 'largeNumbers:order',
        methodLabel: 'Große Zahlen ordnen',
        nudge:
            'Vergleiche die Zahlen von links nach rechts und entscheide an der ersten unterschiedlichen Stelle.',
        steps: [
          GuidedMethodStep(
            title: 'Paarweise vergleichen',
            instruction:
                'Beginne mit der höchsten Stelle. Erst wenn sie gleich ist, gehst du eine Stelle nach rechts.',
          ),
          GuidedMethodStep(
            title: 'Reihenfolge bilden',
            instruction:
                'Setze danach die kleinste Zahl zuerst und ordne die übrigen entsprechend ein.',
          ),
        ],
      );
    }

    if (taskKey.startsWith('large:neighbor:')) {
      return const GuidedMethodGuide(
        methodKey: 'largeNumbers:neighbor',
        methodLabel: 'Nachbarzahl finden',
        nudge: 'Nachfolger bedeutet genau 1 weiter, Vorgänger genau 1 zurück.',
        steps: [
          GuidedMethodStep(
            title: 'Richtung klären',
            instruction:
                'Entscheide zuerst, ob du einen Schritt vorwärts oder rückwärts gehst.',
          ),
          GuidedMethodStep(
            title: 'Genau einen Schritt gehen',
            instruction: 'Verändere die Zahl anschließend nur um 1.',
          ),
        ],
      );
    }

    if (taskKey.startsWith('large:word:')) {
      final values = _numbers(taskKey);
      final number = values.isEmpty ? null : values.last;
      if (number != null) {
        final suffix = number % 100;
        final tens = suffix ~/ 10;
        final ones = suffix % 10;
        if (tens >= 2 && ones > 0 && tens != ones) {
          final suffixWord = GermanNumberWords.spell(suffix);
          final correct = '$tens Zehner und $ones Einer';
          final rawChoices = <String>[
            correct,
            '$ones Zehner und $tens Einer',
            '$tens Zehner und $tens Einer',
            '$ones Zehner und $ones Einer',
          ];
          final shift = number % rawChoices.length;
          final choices = <String>[
            ...rawChoices.skip(shift),
            ...rawChoices.take(shift),
          ];
          return GuidedMethodGuide(
            methodKey: 'largeNumbers:numberWord',
            methodLabel: 'Zahlwort lesen',
            nudge:
                'Achte beim letzten zweistelligen Wortteil besonders auf die deutsche Reihenfolge von Einern und Zehnern.',
            steps: [
              GuidedMethodStep(
                title: 'Einer und Zehner entschlüsseln',
                instruction:
                    'Bestimme nur die beiden letzten Stellen. Die übrigen Stellenwertgruppen brauchst du erst danach.',
                question:
                    'Im Wortteil „$suffixWord“: Welche Zuordnung zu Zehnern und Einern ist richtig?',
                choices: choices,
                correctChoice: choices.indexOf(correct),
                evidenceKey: 'numberWordTensOnes',
                evidenceCompetency: MicroCompetencyId.numberWordReading,
                evidenceWeight: 0.40,
              ),
              GuidedMethodStep(
                title: 'Übrige Stellenwertgruppen ergänzen',
                instruction:
                    'Im Deutschen wird bei $suffixWord der Einer vor dem Zehner gesprochen. Ergänze danach Hunderter, Tausender und weitere Gruppen.',
              ),
              const GuidedMethodStep(
                title: 'Gesamte Zahl zuordnen',
                instruction:
                    'Setze erst am Ende alle Stellenwertgruppen zur vollständigen Zahl oder zum vollständigen Zahlwort zusammen.',
              ),
            ],
          );
        }
      }
      return const GuidedMethodGuide(
        methodKey: 'largeNumbers:numberWord',
        methodLabel: 'Zahlwort lesen',
        nudge:
            'Zerlege die Zahl gedanklich in Tausender, Hunderter, Zehner und Einer.',
        steps: [
          GuidedMethodStep(
            title: 'Stellenwertgruppen erkennen',
            instruction:
                'Lies zuerst Millionen- und Tausendergruppen, danach Hunderter, Zehner und Einer.',
          ),
          GuidedMethodStep(
            title: 'Zusammensetzen',
            instruction:
                'Verbinde die Stellenwertgruppen erst am Ende zur vollständigen Zahl.',
          ),
        ],
      );
    }

    return const GuidedMethodGuide(
      methodKey: 'largeNumbers:placeValue',
      methodLabel: 'Große Zahlen',
      nudge:
          'Lies große Zahlen von links nach rechts und orientiere dich an den Stellenwerten.',
      steps: [
        GuidedMethodStep(
          title: 'Stellenwerte ansehen',
          instruction:
              'Beginne links bei der größten Stelle und arbeite dich nach rechts vor.',
        ),
        GuidedMethodStep(
          title: 'Aufgabe beantworten',
          instruction:
              'Nutze nur die Stellenwerte, die für die konkrete Frage gebraucht werden.',
        ),
      ],
    );
  }

  static int _firstDifferentPlace(int a, int b) {
    var place = 1;
    var largest = max(a, b);
    while (largest >= 10) {
      place *= 10;
      largest ~/= 10;
    }
    while (place > 1 && (a ~/ place) % 10 == (b ~/ place) % 10) {
      place ~/= 10;
    }
    return place;
  }

  static List<String> _largePlaceChoices(int a, int b) {
    var highest = 1;
    var largest = max(a, b);
    while (largest >= 10) {
      highest *= 10;
      largest ~/= 10;
    }
    final values = <String>[];
    for (var place = highest; place >= 1; place ~/= 10) {
      values.add(_largePlaceLabel(place));
      if (place == 1) break;
    }
    return values;
  }

  static String _largePlaceLabel(int place) => switch (place) {
        1000000 => 'Millionenstelle',
        100000 => 'Hunderttausenderstelle',
        10000 => 'Zehntausenderstelle',
        1000 => 'Tausenderstelle',
        100 => 'Hunderterstelle',
        10 => 'Zehnerstelle',
        _ => 'Einerstelle',
      };
  static GuidedMethodGuide _minuteSecondConversion(String key) {
    final parts = key.split(':');
    if (!key.startsWith('time:seconds:') || parts.length < 4) {
      return const GuidedMethodGuide(
        methodKey: 'measure:minuteSecond',
        methodLabel: 'Minuten und Sekunden',
        nudge:
            'Prüfe zuerst die feste Beziehung zwischen Minuten und Sekunden.',
        steps: [
          GuidedMethodStep(
            title: 'Einheitenbeziehung erkennen',
            instruction:
                'Überlege, wie viele Sekunden zu genau einer Minute gehören.',
          ),
          GuidedMethodStep(
            title: 'Richtung beachten',
            instruction:
                'Entscheide danach, ob du mit 60 multiplizieren oder durch 60 teilen musst.',
          ),
        ],
      );
    }

    final direction = parts[2];
    final value = int.tryParse(parts.last);
    const choices = [
      '1 min = 6 s',
      '1 min = 60 s',
      '1 min = 100 s',
    ];
    final toSeconds = direction == 'min-to-sec';
    final calculationHint = value == null
        ? (toSeconds
            ? 'Von Minuten zu Sekunden wird mit 60 multipliziert.'
            : 'Von Sekunden zu Minuten wird durch 60 geteilt.')
        : (toSeconds
            ? '$value × 60 ergibt die Anzahl der Sekunden.'
            : '$value ÷ 60 ergibt die Anzahl der Minuten.');

    return GuidedMethodGuide(
      methodKey: 'measure:minuteSecond',
      methodLabel: 'Minuten und Sekunden',
      nudge:
          'Bestimme zuerst die feste Beziehung zwischen Minute und Sekunde.',
      steps: [
        const GuidedMethodStep(
          title: 'Minuten-Sekunden-Beziehung erkennen',
          instruction:
              'Denke an genau eine volle Minute und entscheide, welche Beziehung stimmt.',
          question: 'Welche Beziehung zwischen Minuten und Sekunden stimmt?',
          choices: choices,
          correctChoice: 1,
          evidenceKey: 'minuteSecondRelation',
          evidenceCompetency: MicroCompetencyId.secondsConversion,
          evidenceWeight: 0.40,
        ),
        GuidedMethodStep(
          title: 'Umrechnungsrichtung anwenden',
          instruction: calculationHint,
        ),
      ],
    );
  }

  static GuidedMethodGuide _measurementCalculationGuide(
    String taskKey,
  ) {
    final addition = taskKey.startsWith('measure:add:');
    final subtraction = taskKey.startsWith('measure:subtract:');

    if (!addition && !subtraction) {
      return const GuidedMethodGuide(
        methodKey: 'measure:calculationPlan',
        methodLabel: 'Längenaufgabe zuerst als Rechenplan lesen',
        nudge:
            'Prüfe zuerst, ob gleichartige Längen zusammengefügt werden oder ob von einer ganzen Länge ein Stück weggenommen wird.',
        steps: [
          GuidedMethodStep(
            title: 'Situation erkennen',
            instruction:
                'Gleiche Einheiten darfst du direkt miteinander verrechnen. Entscheide zuerst, was mit den Längen passiert.',
          ),
        ],
      );
    }

    final numbers = _numbers(taskKey);
    final shift = numbers.fold<int>(0, (sum, value) => sum + value) % 2;
    final rawChoices = <String>['Plus (+)', 'Minus (−)'];
    final choices = <String>[
      ...rawChoices.skip(shift),
      ...rawChoices.take(shift),
    ];
    final correct = addition ? 'Plus (+)' : 'Minus (−)';
    final calculation = numbers.length >= 2
        ? addition
            ? '${numbers[numbers.length - 2]} + ${numbers.last}'
            : '${numbers[numbers.length - 2]} − ${numbers.last}'
        : null;

    return GuidedMethodGuide(
      methodKey: 'measure:calculationPlan',
      methodLabel: 'Längenaufgabe zuerst als Rechenplan lesen',
      nudge:
          'Überlege zuerst: Werden gleichartige Längen zusammengefügt, oder wird von einer ganzen Länge ein Stück weggenommen?',
      steps: [
        GuidedMethodStep(
          title: 'Rechenart erkennen',
          instruction:
              'Entscheide vor dem Rechnen, welche Veränderung mit der Länge beschrieben wird.',
          question: 'Welche Rechenart passt zu dieser Längensituation?',
          choices: choices,
          correctChoice: choices.indexOf(correct),
          evidenceKey: 'measureOperationChoice',
          evidenceCompetency: MicroCompetencyId.measurementCalculation,
          evidenceWeight: 0.40,
        ),
        GuidedMethodStep(
          title: 'Längen verrechnen',
          instruction: calculation == null
              ? 'Rechne jetzt mit den beiden Längen in derselben Einheit.'
              : 'Rechne jetzt $calculation. Die Einheit cm bleibt erhalten.',
        ),
      ],
    );
  }

  static GuidedMethodGuide _unitConversion(String key) {
    final relation = _unitRelationForKey(key);
    if (relation == null) {
      return const GuidedMethodGuide(
        methodKey: 'measure:unitLadder',
        methodLabel: 'Einheitenleiter',
        nudge: 'Welche Einheit hast du – und zu welcher Einheit willst du?',
        steps: [
          GuidedMethodStep(
            title: 'Start markieren',
            instruction: 'Markiere die Ausgangseinheit.',
          ),
          GuidedMethodStep(
            title: 'Ziel markieren',
            instruction: 'Markiere die gesuchte Einheit.',
          ),
          GuidedMethodStep(
            title: 'Schrittweise umwandeln',
            instruction:
                'Nutze die bekannte Beziehung zwischen den beiden Einheiten.',
          ),
        ],
      );
    }

    final choices = relation.choices;
    return GuidedMethodGuide(
      methodKey: 'measure:unitLadder',
      methodLabel: 'Einheitenleiter',
      nudge:
          'Bestimme zuerst die feste Beziehung zwischen ${relation.startUnit} und ${relation.targetUnit}.',
      steps: [
        GuidedMethodStep(
          title: 'Einheitenbeziehung erkennen',
          instruction:
              'Lies Ausgangs- und Zieleinheit genau. Entscheide erst über ihre Beziehung, bevor du den Zahlenwert veränderst.',
          question: 'Welche Beziehung zwischen den Einheiten stimmt?',
          choices: choices,
          correctChoice: choices.indexOf(relation.correctRelation),
          evidenceKey: 'unitRelation',
          evidenceCompetency: MicroCompetencyId.unitConversion,
          evidenceWeight: 0.40,
        ),
        GuidedMethodStep(
          title: 'Zahlenwert passend verändern',
          instruction: relation.calculationHint,
        ),
      ],
    );
  }

  static ({
    String startUnit,
    String targetUnit,
    String correctRelation,
    List<String> choices,
    String calculationHint,
  })? _unitRelationForKey(String key) {
    final value = int.tryParse(key.split(':').last);

    if (key.startsWith('length:m:')) {
      return (
        startUnit: 'm',
        targetUnit: 'cm',
        correctRelation: '1 m = 100 cm',
        choices: const [
          '1 m = 10 cm',
          '1 m = 100 cm',
          '1 m = 1000 cm',
        ],
        calculationHint: value == null
            ? 'Von m zu cm wird der Zahlenwert mit 100 multipliziert.'
            : '$value × 100 ergibt den Zahlenwert in cm.',
      );
    }
    if (key.startsWith('length:km:')) {
      return (
        startUnit: 'km',
        targetUnit: 'm',
        correctRelation: '1 km = 1000 m',
        choices: const [
          '1 km = 100 m',
          '1 km = 1000 m',
          '1 km = 10000 m',
        ],
        calculationHint: value == null
            ? 'Von km zu m wird der Zahlenwert mit 1000 multipliziert.'
            : '$value × 1000 ergibt den Zahlenwert in m.',
      );
    }
    if (key.startsWith('length:cm-mm:')) {
      return (
        startUnit: 'cm',
        targetUnit: 'mm',
        correctRelation: '1 cm = 10 mm',
        choices: const [
          '1 cm = 1 mm',
          '1 cm = 10 mm',
          '1 cm = 100 mm',
        ],
        calculationHint: value == null
            ? 'Von cm zu mm wird der Zahlenwert mit 10 multipliziert.'
            : '$value × 10 ergibt den Zahlenwert in mm.',
      );
    }
    if (key.startsWith('mass:kg:')) {
      return (
        startUnit: 'kg',
        targetUnit: 'g',
        correctRelation: '1 kg = 1000 g',
        choices: const [
          '1 kg = 100 g',
          '1 kg = 1000 g',
          '1 kg = 10000 g',
        ],
        calculationHint: value == null
            ? 'Von kg zu g wird der Zahlenwert mit 1000 multipliziert.'
            : '$value × 1000 ergibt den Zahlenwert in g.',
      );
    }
    if (key.startsWith('mass:t-kg:')) {
      return (
        startUnit: 't',
        targetUnit: 'kg',
        correctRelation: '1 t = 1000 kg',
        choices: const [
          '1 t = 100 kg',
          '1 t = 1000 kg',
          '1 t = 10000 kg',
        ],
        calculationHint: value == null
            ? 'Von t zu kg wird der Zahlenwert mit 1000 multipliziert.'
            : '$value × 1000 ergibt den Zahlenwert in kg.',
      );
    }
    if (key.startsWith('volume:l:')) {
      return (
        startUnit: 'l',
        targetUnit: 'ml',
        correctRelation: '1 l = 1000 ml',
        choices: const [
          '1 l = 100 ml',
          '1 l = 1000 ml',
          '1 l = 10000 ml',
        ],
        calculationHint: value == null
            ? 'Von l zu ml wird der Zahlenwert mit 1000 multipliziert.'
            : '$value × 1000 ergibt den Zahlenwert in ml.',
      );
    }
    if (key.startsWith('money:euro:')) {
      return (
        startUnit: '€',
        targetUnit: 'ct',
        correctRelation: '1 € = 100 ct',
        choices: const [
          '1 € = 10 ct',
          '1 € = 100 ct',
          '1 € = 1000 ct',
        ],
        calculationHint: value == null
            ? 'Von Euro zu Cent wird der Zahlenwert mit 100 multipliziert.'
            : '$value × 100 ergibt den Zahlenwert in Cent.',
      );
    }
    if (key.startsWith('time:min:') && !key.startsWith('time:seconds:')) {
      return (
        startUnit: 'min',
        targetUnit: 'h',
        correctRelation: '1 h = 60 min',
        choices: const [
          '1 h = 30 min',
          '1 h = 60 min',
          '1 h = 100 min',
        ],
        calculationHint: value == null
            ? 'Teile die Minuten durch 60, um die Anzahl ganzer Stunden zu erhalten.'
            : '$value ÷ 60 ergibt die Anzahl ganzer Stunden.',
      );
    }
    return null;
  }

  static GuidedMethodGuide _fraction(String key, int expected) {
    final parts = key.split(':');
    if (key.startsWith('fraction:parts:') && parts.length >= 5) {
      final numerator = int.tryParse(parts[2]);
      final denominator = int.tryParse(parts[3]);
      final whole = int.tryParse(parts[4]);
      if (numerator != null &&
          denominator != null &&
          whole != null &&
          denominator > 1 &&
          numerator > 0 &&
          numerator < denominator &&
          whole % denominator == 0) {
        final partSize = whole ~/ denominator;
        final choices = _numberChoices(
          partSize,
          maxValue: max(12, partSize + 4),
        );
        return GuidedMethodGuide(
          methodKey: 'fraction:equalParts',
          methodLabel: 'Gleich große Teile',
          nudge:
              'Teile $whole zuerst in $denominator wirklich gleich große Teile.',
          steps: [
            GuidedMethodStep(
              title: 'Einen gleich großen Teil bestimmen',
              instruction:
                  '$whole wird auf $denominator gleich große Teile verteilt.',
              question:
                  'Wie groß ist genau 1 von $denominator gleich großen Teilen?',
              choices: choices,
              correctChoice: choices.indexOf('$partSize'),
              evidenceKey: 'equalPartSize',
              evidenceCompetency: MicroCompetencyId.fractionEqualParts,
              evidenceWeight: 0.40,
            ),
            GuidedMethodStep(
              title: 'Gesuchte Teile zusammensetzen',
              instruction:
                  '$numerator Teile mit je $partSize ergeben $numerator × $partSize = $expected.',
            ),
          ],
        );
      }
    }

    return GuidedMethodGuide(
      methodKey: 'fraction:equalParts',
      methodLabel: 'Gleich große Teile',
      nudge: 'Wie viele gleich große Teile hat das Ganze?',
      steps: [
        const GuidedMethodStep(
          title: 'Ganzes erkennen',
          instruction: 'Bestimme zuerst die gesamte Menge.',
        ),
        const GuidedMethodStep(
          title: 'Gleichmäßig teilen',
          instruction:
              'Der Nenner sagt, in wie viele gleich große Teile das Ganze zerlegt wird.',
        ),
        GuidedMethodStep(
          title: 'Gesuchten Anteil nehmen',
          instruction: 'Bestimme anschließend den gefragten Bruchteil.',
        ),
      ],
    );
  }

  static GuidedMethodGuide _timeDuration(String key) {
    final parts = key.split(':');
    if (!key.startsWith('duration:') ||
        key.startsWith('duration:weeks:') ||
        key.startsWith('duration:days:') ||
        parts.length < 3) {
      return const GuidedMethodGuide(
        methodKey: 'time:timeline',
        methodLabel: 'Zeitlinie',
        nudge: 'Markiere Start und Ende und gehe in passenden Zeit-Etappen.',
        steps: [
          GuidedMethodStep(
            title: 'Start markieren',
            instruction: 'Markiere die Startzeit.',
          ),
          GuidedMethodStep(
            title: 'Passende Etappen wählen',
            instruction:
                'Nutze volle oder halbe Stunden nur dann als Zwischenstopp, wenn sie auf dem Weg liegen.',
          ),
          GuidedMethodStep(
            title: 'Etappen addieren',
            instruction: 'Zähle die Minuten aller Etappen zusammen.',
          ),
        ],
      );
    }

    final start = int.tryParse(parts[1]);
    final duration = int.tryParse(parts[2]);
    if (start == null || duration == null) {
      return const GuidedMethodGuide(
        methodKey: 'time:timeline',
        methodLabel: 'Zeitlinie',
        nudge: 'Markiere Start und Ende und gehe in passenden Zeit-Etappen.',
        steps: [
          GuidedMethodStep(
            title: 'Start markieren',
            instruction: 'Markiere die Startzeit.',
          ),
          GuidedMethodStep(
            title: 'Ende markieren',
            instruction: 'Markiere die Endzeit.',
          ),
          GuidedMethodStep(
            title: 'Zeitstücke addieren',
            instruction: 'Addiere die Zeitstücke zwischen Start und Ende.',
          ),
        ],
      );
    }

    final end = start + duration;
    final minute = start % 60;
    final nextFullHour = ((start ~/ 60) + 1) * 60;
    final crossesFullHour = minute != 0 && nextFullHour < end;

    if (!crossesFullHour) {
      final startLabel = _clockMinutes(start);
      final endLabel = _clockMinutes(end);
      final message = minute == 0
          ? '$startLabel Uhr ist schon eine volle Stunde. Ein 0-Minuten-Zwischenschritt ist nicht nötig.'
          : end == nextFullHour
              ? 'Die Zeitspanne endet genau um $endLabel Uhr. Zähle direkt bis zur vollen Stunde.'
              : 'Start und Ende liegen vor der nächsten vollen Stunde. Zähle die Minuten direkt von $startLabel bis $endLabel.';
      return GuidedMethodGuide(
        methodKey: 'time:timeline',
        methodLabel: 'Zeitlinie',
        nudge: message,
        steps: [
          GuidedMethodStep(
            title: 'Start und Ende markieren',
            instruction: '$startLabel Uhr → $endLabel Uhr.',
          ),
          const GuidedMethodStep(
            title: 'Direkte Zeitspanne',
            instruction:
                'Hier brauchst du keinen künstlichen Zwischenstopp an einer vollen Stunde.',
          ),
          GuidedMethodStep(
            title: 'Minuten bestimmen',
            instruction: 'Die gesamte Zeitspanne beträgt $duration Minuten.',
          ),
        ],
      );
    }

    final firstPart = nextFullHour - start;
    final rest = end - nextFullHour;
    final firstChoices = _numberChoices(firstPart, maxValue: 60);

    return GuidedMethodGuide(
      methodKey: 'time:timeline',
      methodLabel: 'Zeitlinie',
      nudge:
          'Gehe zuerst von ${_clockMinutes(start)} Uhr bis ${_clockMinutes(nextFullHour)} Uhr.',
      steps: [
        GuidedMethodStep(
          title: 'Bis zur vollen Stunde',
          instruction:
              'Der erste Zeitabschnitt geht von ${_clockMinutes(start)} Uhr bis ${_clockMinutes(nextFullHour)} Uhr.',
          question:
              'Wie viele Minuten sind es bis ${_clockMinutes(nextFullHour)} Uhr?',
          choices: firstChoices,
          correctChoice: firstChoices.indexOf('$firstPart'),
          evidenceKey: 'minutesToNextHour',
          evidenceCompetency: MicroCompetencyId.timeDuration,
          evidenceWeight: 0.40,
        ),
        GuidedMethodStep(
          title: 'Von der vollen Stunde bis zum Ende',
          instruction:
              'Von ${_clockMinutes(nextFullHour)} Uhr bis ${_clockMinutes(end)} Uhr sind es noch $rest Minuten.',
        ),
        GuidedMethodStep(
          title: 'Zeitstücke addieren',
          instruction: '$firstPart + $rest = $duration Minuten.',
        ),
      ],
    );
  }

  static String _clockMinutes(int value) {
    final normalized = value % (24 * 60);
    final hour = normalized ~/ 60;
    final minute = normalized % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  static GuidedMethodGuide _proportionalUnit(String key) {
    final numbers = _numbers(key);
    final unitValue = numbers.length >= 3 ? numbers[numbers.length - 3] : null;
    final firstAmount = numbers.length >= 2 ? numbers[numbers.length - 2] : null;
    final total = unitValue == null || firstAmount == null
        ? null
        : unitValue * firstAmount;
    final choices = unitValue == null
        ? const <String>[]
        : _numberChoices(
            unitValue,
            maxValue: max(12, unitValue + 3),
          );

    return GuidedMethodGuide(
      methodKey: 'proportion:unitValue',
      methodLabel: 'Über eine Einheit zuordnen',
      nudge: 'Bestimme zuerst den Wert für genau 1 Einheit.',
      steps: [
        GuidedMethodStep(
          title: 'Wert für 1 Einheit',
          instruction: total == null || firstAmount == null
              ? 'Teile den bekannten Gesamtwert durch die bekannte Anzahl.'
              : '$firstAmount gleiche Einheiten haben zusammen den Wert $total. Teile $total durch $firstAmount.',
          question: unitValue == null
              ? null
              : 'Welchen Wert hat genau 1 Einheit?',
          choices: choices,
          correctChoice:
              unitValue == null ? null : choices.indexOf('$unitValue'),
          evidenceKey: unitValue == null ? null : 'unitValue',
          evidenceCompetency:
              unitValue == null ? null : MicroCompetencyId.proportionalUnit,
          evidenceWeight: 0.40,
        ),
        const GuidedMethodStep(
          title: 'Auf die gesuchte Anzahl übertragen',
          instruction:
              'Multipliziere den Wert für 1 Einheit anschließend mit der gesuchten Anzahl.',
        ),
      ],
    );
  }

  static GuidedMethodGuide _perimeterArea(String key) {
    final area = key.contains('area');
    return GuidedMethodGuide(
      methodKey: area ? 'geometry:area' : 'geometry:perimeter',
      methodLabel: area ? 'Fläche = Inneres' : 'Umfang = Rand',
      nudge: area
          ? 'Gesucht ist das Innere der Figur.'
          : 'Gesucht ist die Länge des Randes.',
      steps: [
        GuidedMethodStep(
          title: area ? 'Innenfläche markieren' : 'Rand nachfahren',
          instruction: area
              ? 'Markiere die Fläche innerhalb des Rechtecks.'
              : 'Fahre alle vier Seiten einmal entlang.',
        ),
        GuidedMethodStep(
          title: 'Passende Rechnung',
          instruction: area
              ? 'Länge × Breite.'
              : 'Alle Seiten addieren oder 2 × (Länge + Breite).',
        ),
      ],
    );
  }

  static GuidedMethodGuide _strategyChoiceGuide(String key) {
    final parts = key.split(':');
    final strategyIndex = parts.indexOf('strategy');
    final label = strategyIndex >= 0 && strategyIndex + 1 < parts.length
        ? parts[strategyIndex + 1]
        : 'Zielzahl';
    final numbers = _numbers(key);

    if (numbers.length < 3) {
      return const GuidedMethodGuide(
        methodKey: 'process:strategyChoice',
        methodLabel: 'Günstigen Rechenweg wählen',
        nudge:
            'Suche eine runde Zwischenzahl, die das Rechnen einfacher macht.',
        steps: [
          GuidedMethodStep(
            title: 'Zielzahl erkennen',
            instruction:
                'Suche einen glatten Zehner, Hunderter oder Tausender in der Nähe.',
          ),
          GuidedMethodStep(
            title: 'Passend zerlegen',
            instruction:
                'Zerlege nur so viel vom zweiten Summanden, wie bis zur Zielzahl fehlt.',
          ),
        ],
      );
    }

    final a = numbers[numbers.length - 3];
    final b = numbers[numbers.length - 2];
    final anchor = numbers.last;
    final gap = anchor - a;
    final rest = b - gap;
    if (gap <= 0 || rest < 0) {
      return const GuidedMethodGuide(
        methodKey: 'process:strategyChoice',
        methodLabel: 'Günstigen Rechenweg wählen',
        nudge:
            'Suche eine runde Zwischenzahl, die das Rechnen einfacher macht.',
        steps: [
          GuidedMethodStep(
            title: 'Zielzahl erkennen',
            instruction:
                'Suche zuerst eine passende glatte Zwischenzahl.',
          ),
        ],
      );
    }

    final choices = _numberChoices(
      gap,
      maxValue: max(b, gap + 10),
    );

    return GuidedMethodGuide(
      methodKey: 'process:strategyChoice',
      methodLabel: 'Günstigen Rechenweg wählen',
      nudge:
          'Bestimme zuerst genau die Ergänzung von $a bis zum glatten $label $anchor.',
      steps: [
        GuidedMethodStep(
          title: 'Ergänzung zur Zielzahl bestimmen',
          instruction:
              'Bestimme zunächst nur, wie viel vom ersten Summanden bis zur glatten Zielzahl fehlt.',
          question:
              'Von $a bis zum glatten $label $anchor: Wie viel fehlt?',
          choices: choices,
          correctChoice: choices.indexOf('$gap'),
          evidenceKey: 'gapToAnchor',
          evidenceCompetency: MicroCompetencyId.strategyChoice,
          evidenceWeight: 0.40,
        ),
        GuidedMethodStep(
          title: 'Zweiten Summanden passend zerlegen',
          instruction:
              'Von $b nutzt du zuerst $gap für den Weg bis $anchor. Danach bleiben $rest übrig.',
        ),
        GuidedMethodStep(
          title: 'Rechenweg fertigstellen',
          instruction:
              'Der günstige Weg beginnt deshalb mit $a + $gap und rechnet anschließend den Rest $rest weiter.',
        ),
      ],
    );
  }

  static GuidedMethodGuide _errorCheckingGuide(String key) {
    final numbers = _numbers(key);
    final parts = key.split(':');
    final placeIndex = parts.indexOf('place');
    final targeted = placeIndex >= 0 && placeIndex + 1 < parts.length;
    final shown = numbers.length >= 3 ? numbers.last : null;

    if (targeted) {
      final place = int.tryParse(parts[placeIndex + 1]) ?? 1;
      final label = switch (place) {
        1 => 'Einerstelle',
        10 => 'Zehnerstelle',
        100 => 'Hunderterstelle',
        1000 => 'Tausenderstelle',
        _ => 'betroffene Stelle',
      };
      final choices = <String>[
        'Einerstelle',
        'Zehnerstelle',
        if (place >= 100 || numbers.take(2).any((value) => value >= 100))
          'Hunderterstelle',
        if (place >= 1000 || numbers.take(2).any((value) => value >= 1000))
          'Tausenderstelle',
      ];
      if (!choices.contains(label)) choices.add(label);

      return GuidedMethodGuide(
        methodKey: 'process:errorChecking',
        methodLabel: 'Rechenfehler finden',
        nudge:
            'Prüfe die Rechnung von rechts nach links und lokalisiere zuerst die falsche Stelle.',
        steps: [
          GuidedMethodStep(
            title: 'Fehlerstelle finden',
            instruction:
                'Rechne die Spalten einzeln. Entscheide zunächst nur, an welcher Stellenwertstelle die angegebene Summe falsch wird.',
            question: 'Welche Stelle ist in der angegebenen Summe falsch?',
            choices: choices,
            correctChoice: choices.indexOf(label),
            evidenceKey: 'errorPlace',
            evidenceCompetency: MicroCompetencyId.errorChecking,
            evidenceWeight: 0.40,
          ),
          GuidedMethodStep(
            title: 'Abweichung an der Stelle prüfen',
            instruction:
                'Die $label ist betroffen. Prüfe jetzt, ob die angegebene Ziffer dort zu groß oder zu klein ist.',
          ),
          const GuidedMethodStep(
            title: 'Fehler beschreiben',
            instruction:
                'Benenne anschließend die Richtung und Größe des Fehlers.',
          ),
        ],
      );
    }

    return GuidedMethodGuide(
      methodKey: 'process:errorChecking',
      methodLabel: 'Rechenfehler finden',
      nudge: shown == null
          ? 'Prüfe zuerst die Stellen, statt die ganze Aufgabe sofort neu zu rechnen.'
          : 'Prüfe, ob $shown zu Einer- und Zehnerstelle der Aufgabe passen kann.',
      steps: const [
        GuidedMethodStep(
          title: 'Einer prüfen',
          instruction:
              'Vergleiche zuerst nur die Einerstelle mit der vorgegebenen Rechnung.',
        ),
        GuidedMethodStep(
          title: 'Zehner prüfen',
          instruction:
              'Prüfe danach Zehner und mögliche Überträge oder Entbündelungen.',
        ),
        GuidedMethodStep(
          title: 'Fehler beschreiben',
          instruction:
              'Benenne möglichst genau, ob das Ergebnis zu groß, zu klein oder korrekt ist.',
        ),
      ],
    );
  }

  static GuidedMethodGuide _estimationGuide(String key) {
    final numbers = _numbers(key);
    if (numbers.length < 3) {
      return const GuidedMethodGuide(
        methodKey: 'estimation:roundedSummands',
        methodLabel: 'Überschlag schrittweise bilden',
        nudge:
            'Runde zuerst beide Ausgangszahlen auf dieselbe sinnvolle Stelle.',
        steps: [
          GuidedMethodStep(
            title: 'Beide Zahlen runden',
            instruction:
                'Bestimme für jeden Summanden getrennt den passenden Rundungswert.',
          ),
          GuidedMethodStep(
            title: 'Gerundete Werte addieren',
            instruction:
                'Erst danach addierst du die beiden gerundeten Werte zum Überschlag.',
          ),
        ],
      );
    }

    final a = numbers[numbers.length - 3];
    final b = numbers[numbers.length - 2];
    final place = numbers.last;
    int rounded(int value) => ((value + place ~/ 2) ~/ place) * place;
    int down(int value) => (value ~/ place) * place;
    int up(int value) => ((value + place - 1) ~/ place) * place;
    final roundedA = rounded(a);
    final roundedB = rounded(b);
    final correct = '$roundedA und $roundedB';
    final pairs = <String>{
      correct,
      '${down(a)} und $roundedB',
      '${up(a)} und $roundedB',
      '$roundedA und ${down(b)}',
      '$roundedA und ${up(b)}',
      '${down(a)} und ${down(b)}',
      '${up(a)} und ${up(b)}',
    };
    var shift = place;
    while (pairs.length < 4) {
      pairs.add('${max(0, roundedA - shift)} und ${roundedB + shift}');
      shift += place;
    }
    final choices = pairs.take(4).toList();
    final placeLabel = switch (place) {
      10 => 'Zehner',
      100 => 'Hunderter',
      1000 => 'Tausender',
      10000 => 'Zehntausender',
      100000 => 'Hunderttausender',
      _ => 'gleiche Stelle',
    };

    return GuidedMethodGuide(
      methodKey: 'estimation:roundedSummands',
      methodLabel: 'Überschlag schrittweise bilden',
      nudge:
          'Runde $a und $b zuerst getrennt auf $placeLabel. Addiere noch nicht.',
      steps: [
        GuidedMethodStep(
          title: 'Rundungswerte bestimmen',
          instruction:
              'Bestimme nur die beiden gerundeten Summanden. Der Überschlag selbst kommt erst im nächsten Schritt.',
          question:
              'Auf welche beiden Zahlen rundest du $a und $b für diesen Überschlag?',
          choices: choices,
          correctChoice: choices.indexOf(correct),
          evidenceKey: 'roundedSummands',
          evidenceCompetency: MicroCompetencyId.estimation,
          evidenceWeight: 0.40,
        ),
        GuidedMethodStep(
          title: 'Überschlag bilden',
          instruction:
              'Addiere jetzt $roundedA und $roundedB. So erhältst du eine grobe Erwartung.',
        ),
      ],
    );
  }

  static GuidedMethodGuide _plausibilityGuide(String key) {
    final numbers = _numbers(key);
    final candidate = numbers.length >= 3 ? numbers[numbers.length - 2] : null;

    if (numbers.length >= 4) {
      final a = numbers[numbers.length - 4];
      final b = numbers[numbers.length - 3];
      final place = numbers.last;
      if (place > 0) {
        int rounded(int value) =>
            ((value + place ~/ 2) ~/ place) * place;
        final roundedA = rounded(a);
        final roundedB = rounded(b);
        final estimate = roundedA + roundedB;
        final placeLabel = switch (place) {
          10 => 'Zehner',
          100 => 'Hunderter',
          1000 => 'Tausender',
          10000 => 'Zehntausender',
          100000 => 'Hunderttausender',
          _ => 'passende Stelle',
        };
        final choices = _numberChoices(
          estimate,
          maxValue: max(
            estimate + 2 * place,
            (candidate ?? estimate) + 2 * place,
          ),
        );

        return GuidedMethodGuide(
          methodKey: 'process:plausibility',
          methodLabel: 'Mit Überschlag kontrollieren',
          nudge:
              'Bilde zuerst eine grobe Referenz. Erst danach vergleichst du das vorgeschlagene Ergebnis damit.',
          steps: [
            GuidedMethodStep(
              title: 'Referenz-Überschlag bilden',
              instruction:
                  'Runde beide Ausgangszahlen auf $placeLabel und addiere nur die gerundeten Werte.',
              question:
                  'Welcher Überschlag passt zu $a + $b beim Runden auf $placeLabel?',
              choices: choices,
              correctChoice: choices.indexOf('$estimate'),
              evidenceKey: 'referenceEstimate',
              evidenceCompetency: MicroCompetencyId.plausibilityCheck,
              evidenceWeight: 0.40,
            ),
            GuidedMethodStep(
              title: 'Vorschlag vergleichen',
              instruction: candidate == null
                  ? 'Vergleiche das vorgeschlagene Ergebnis mit dem Referenz-Überschlag.'
                  : 'Vergleiche $candidate mit dem Referenz-Überschlag $estimate.',
            ),
            const GuidedMethodStep(
              title: 'Plausibilität entscheiden',
              instruction:
                  'Erst jetzt entscheidest du, ob das vorgeschlagene Ergebnis zur erwarteten Größenordnung passt.',
            ),
          ],
        );
      }
    }

    return GuidedMethodGuide(
      methodKey: 'process:plausibility',
      methodLabel: 'Mit Überschlag kontrollieren',
      nudge: candidate == null
          ? 'Runde die Ausgangszahlen grob und vergleiche die Größenordnung.'
          : 'Passt $candidate ungefähr zu den gerundeten Ausgangszahlen?',
      steps: const [
        GuidedMethodStep(
          title: 'Ausgangszahlen runden',
          instruction:
              'Runde beide Zahlen auf eine sinnvolle Stelle, ohne exakt auszurechnen.',
        ),
        GuidedMethodStep(
          title: 'Überschlag bilden',
          instruction:
              'Rechne mit den gerundeten Zahlen eine grobe Erwartung.',
        ),
        GuidedMethodStep(
          title: 'Vergleichen',
          instruction:
              'Liegt das vorgeschlagene Ergebnis in derselben Größenordnung?',
        ),
      ],
    );
  }

  static int _firstDivisionChunk(int dividend, int divisor) {
    var chunk = 0;
    for (final codeUnit in '$dividend'.codeUnits) {
      chunk = chunk * 10 + (codeUnit - 48);
      if (chunk >= divisor) return chunk;
    }
    return dividend;
  }

  static int? _firstDirectRegroupingPlace(
    int a,
    int b, {
    required bool addition,
  }) {
    var left = a;
    var right = b;
    var place = 1;
    while (left > 0 || right > 0) {
      final needsRegrouping = addition
          ? (left % 10) + (right % 10) >= 10
          : (left % 10) < (right % 10);
      if (needsRegrouping) return place;
      left ~/= 10;
      right ~/= 10;
      place *= 10;
    }
    return null;
  }

  static String _placeLabel(int place) => switch (place) {
        1 => 'Einer-Spalte',
        10 => 'Zehner-Spalte',
        100 => 'Hunderter-Spalte',
        1000 => 'Tausender-Spalte',
        10000 => 'Zehntausender-Spalte',
        100000 => 'Hunderttausender-Spalte',
        _ => 'betroffenen Stelle',
      };

  static bool _needsAdditionBridge(MathFact fact) =>
      (fact.a % 10) + (fact.b % 10) >= 10;

  static bool _needsSubtractionBridge(MathFact fact) =>
      (fact.a % 10) < (fact.b % 10);

  static List<int> _numbers(String value) => RegExp(r'\d+')
      .allMatches(value)
      .map((match) => int.parse(match.group(0)!))
      .toList();

  static List<String> _numberChoices(
    int correct, {
    required int maxValue,
  }) {
    final values = <int>{correct};
    for (final offset in [1, -1, 2, -2, 10, -10]) {
      final candidate = correct + offset;
      if (candidate >= 0 && candidate <= maxValue) values.add(candidate);
      if (values.length >= 4) break;
    }
    var next = 0;
    while (values.length < 4) {
      if (next <= maxValue) values.add(next);
      next += 1;
    }
    final list = values.take(4).toList()..sort();
    return list.map((value) => '$value').toList();
  }
}
