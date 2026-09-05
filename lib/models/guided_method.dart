import 'dart:math';

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

    if (fact != null &&
        fact.operation == MathOperation.minus &&
        _needsSubtractionBridge(fact)) {
      return _subtractionBridge(fact, preferences);
    }

    if (fact != null && fact.operation == MathOperation.multiply) {
      return _multiplication(fact, preferences);
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

    if (mode == TrainingMode.wordProblems ||
        targetCompetency == MicroCompetencyId.wordProblemOperation ||
        taskKey.startsWith('story:')) {
      return _wordProblem(taskKey);
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
      return _timeDuration();
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
    switch (strategy) {
      case SubtractionStrategy.bridgeToTen:
        final choices1 = _numberChoices(toTen, maxValue: max(10, b));
        final choices2 = _numberChoices(rest, maxValue: max(10, b));
        final choices3 = _numberChoices(result, maxValue: max(20, a));
        return GuidedMethodGuide(
          methodKey: 'subtraction:${strategy.name}',
          methodLabel: strategy.label,
          nudge: 'Wo liegt der nächste volle Zehner unter $a?',
          steps: [
            GuidedMethodStep(
              title: 'Bis zum Zehner',
              instruction: 'Suche zuerst den vollen Zehner unter $a.',
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
                : key.startsWith('story:divide:')
                    ? 'Geteilt'
                    : 'die passende Rechenart';
    return GuidedMethodGuide(
      methodKey: 'wordProblem:meaning',
      methodLabel: 'Text zuerst verstehen',
      nudge: 'Was verändert sich in der Geschichte: wird etwas mehr, weniger, gruppiert oder verteilt?',
      steps: [
        const GuidedMethodStep(
          title: 'Frage finden',
          instruction: 'Lies zuerst nur den letzten Satz: Was wird gesucht?',
        ),
        GuidedMethodStep(
          title: 'Handlung erkennen',
          instruction: 'Hier passt $operation.',
        ),
        const GuidedMethodStep(
          title: 'Angaben prüfen',
          instruction: 'Nimm nur die Zahlen, die für die Frage wirklich gebraucht werden.',
        ),
      ],
    );
  }

  static GuidedMethodGuide _unitConversion(String key) =>
      const GuidedMethodGuide(
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
            instruction: 'Nutze die bekannte Beziehung zwischen benachbarten Einheiten.',
          ),
        ],
      );

  static GuidedMethodGuide _fraction(String key, int expected) =>
      GuidedMethodGuide(
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
            instruction: 'Teile das Ganze in gleich große Teile.',
          ),
          GuidedMethodStep(
            title: 'Gesuchten Anteil nehmen',
            instruction: 'Ein gesuchter Teil hat hier den Wert $expected.',
          ),
        ],
      );

  static GuidedMethodGuide _timeDuration() => const GuidedMethodGuide(
        methodKey: 'time:timeline',
        methodLabel: 'Zeitlinie',
        nudge: 'Gehe vom Start zuerst zur nächsten gut erreichbaren Uhrzeit.',
        steps: [
          GuidedMethodStep(
            title: 'Start markieren',
            instruction: 'Markiere die Startzeit.',
          ),
          GuidedMethodStep(
            title: 'In Etappen gehen',
            instruction: 'Gehe zuerst zu einer vollen oder halben Stunde.',
          ),
          GuidedMethodStep(
            title: 'Etappen addieren',
            instruction: 'Zähle die Minuten aller Etappen zusammen.',
          ),
        ],
      );

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
    final numbers = _numbers(key);
    final anchor = numbers.isEmpty ? null : numbers.last;
    return GuidedMethodGuide(
      methodKey: 'process:strategyChoice',
      methodLabel: 'Günstigen Rechenweg wählen',
      nudge: anchor == null
          ? 'Suche eine runde Zwischenzahl, die das Rechnen einfacher macht.'
          : 'Welche Zerlegung bringt dich zuerst genau zu $anchor?',
      steps: [
        const GuidedMethodStep(
          title: 'Zielzahl erkennen',
          instruction:
              'Suche einen glatten Zehner, Hunderter oder Tausender in der Nähe.',
        ),
        const GuidedMethodStep(
          title: 'Passend zerlegen',
          instruction:
              'Zerlege nur so viel vom zweiten Summanden, wie bis zur Zielzahl fehlt.',
        ),
        const GuidedMethodStep(
          title: 'Rest weiterrechnen',
          instruction:
              'Rechne danach nur noch den verbleibenden Rest weiter.',
        ),
      ],
    );
  }

  static GuidedMethodGuide _errorCheckingGuide(String key) {
    final numbers = _numbers(key);
    final shown = numbers.length >= 3 ? numbers.last : null;
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

  static GuidedMethodGuide _plausibilityGuide(String key) {
    final numbers = _numbers(key);
    final candidate = numbers.length >= 3 ? numbers[numbers.length - 2] : null;
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
