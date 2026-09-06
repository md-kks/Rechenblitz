import 'dart:math';

import 'curriculum_exercise.dart';
import 'german_number_words.dart';
import 'error_diagnosis.dart';
import 'learning_methods.dart';
import 'micro_competency.dart';
import 'structured_exercise.dart';
import 'training.dart';

enum RemediationStage { guided, supported, transfer, check }

extension RemediationStageX on RemediationStage {
  String get label => switch (this) {
        RemediationStage.guided => 'Mit Hilfe',
        RemediationStage.supported => 'Weniger Hilfe',
        RemediationStage.transfer => 'Selbst anwenden',
        RemediationStage.check => 'Kontrolle',
      };

  String get description => switch (this) {
        RemediationStage.guided =>
          'Der Rechenweg wird sichtbar und Schritt für Schritt begleitet.',
        RemediationStage.supported =>
          'Nur noch ein kurzer Hinweis hilft beim richtigen Einstieg.',
        RemediationStage.transfer =>
          'Der Rechenweg wird in einer etwas anderen Aufgabe selbst angewendet.',
        RemediationStage.check =>
          'Zum Schluss wird ohne Starthilfe geprüft, ob der Weg schon sicherer ist.',
      };
}

enum RemediationStatus { recurring, inProgress, improved, stable }

extension RemediationStatusX on RemediationStatus {
  String get label => switch (this) {
        RemediationStatus.recurring => 'wiederkehrend',
        RemediationStatus.inProgress => 'wird gefördert',
        RemediationStatus.improved => 'verbessert',
        RemediationStatus.stable => 'stabil',
      };
}

class RemediationProgress {
  const RemediationProgress({
    required this.pattern,
    required this.gradeLevel,
    required this.numberRange,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.nextReviewAt,
    this.checkCorrect = 0,
    this.checkTotal = 0,
    this.stabilityCorrect = 0,
  });

  final ErrorPattern pattern;
  final GradeLevel gradeLevel;
  final NumberRangeLevel numberRange;
  final RemediationStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime? nextReviewAt;
  final int checkCorrect;
  final int checkTotal;
  final int stabilityCorrect;

  double get checkAccuracy =>
      checkTotal == 0 ? 0 : checkCorrect / checkTotal;

  RemediationProgress copyWith({
    RemediationStatus? status,
    DateTime? completedAt,
    DateTime? nextReviewAt,
    int? checkCorrect,
    int? checkTotal,
    int? stabilityCorrect,
  }) =>
      RemediationProgress(
        pattern: pattern,
        gradeLevel: gradeLevel,
        numberRange: numberRange,
        status: status ?? this.status,
        startedAt: startedAt,
        completedAt: completedAt ?? this.completedAt,
        nextReviewAt: nextReviewAt ?? this.nextReviewAt,
        checkCorrect: checkCorrect ?? this.checkCorrect,
        checkTotal: checkTotal ?? this.checkTotal,
        stabilityCorrect: stabilityCorrect ?? this.stabilityCorrect,
      );

  Map<String, dynamic> toJson() => {
        'pattern': pattern.name,
        'gradeLevel': gradeLevel.name,
        'numberRange': numberRange.name,
        'status': status.name,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'nextReviewAt': nextReviewAt?.toIso8601String(),
        'checkCorrect': checkCorrect,
        'checkTotal': checkTotal,
        'stabilityCorrect': stabilityCorrect,
      };

  factory RemediationProgress.fromJson(Map<String, dynamic> json) =>
      RemediationProgress(
        pattern: ErrorPattern.values.byName(json['pattern'] as String),
        gradeLevel:
            GradeLevel.values.byName(json['gradeLevel'] as String),
        numberRange:
            NumberRangeLevel.values.byName(json['numberRange'] as String),
        status:
            RemediationStatus.values.byName(json['status'] as String),
        startedAt: DateTime.parse(json['startedAt'] as String),
        completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
        nextReviewAt: DateTime.tryParse(json['nextReviewAt'] as String? ?? ''),
        checkCorrect: json['checkCorrect'] as int? ?? 0,
        checkTotal: json['checkTotal'] as int? ?? 0,
        stabilityCorrect: json['stabilityCorrect'] as int? ?? 0,
      );
}

class RemediationTask {
  const RemediationTask({
    required this.stage,
    required this.mode,
    required this.taskKey,
    required this.prompt,
    required this.answer,
    required this.maxAnswerValue,
    required this.hint,
    this.choices,
    this.answerSuffix,
  });

  final RemediationStage stage;
  final TrainingMode mode;
  final String taskKey;
  final String prompt;
  final int answer;
  final int maxAnswerValue;
  final String hint;
  final List<String>? choices;
  final String? answerSuffix;

  bool get usesChoices => choices != null && choices!.isNotEmpty;
}

class RemediationPlan {
  const RemediationPlan({
    required this.pattern,
    required this.mode,
    required this.tasks,
  });

  final ErrorPattern pattern;
  final TrainingMode mode;
  final List<RemediationTask> tasks;

  String get title => '${pattern.label} gezielt üben';
}

class IndependentStepRecoveryFocus {
  const IndependentStepRecoveryFocus({
    required this.competencyId,
    required this.stepKey,
    required this.label,
    required this.mode,
    required this.lastSeen,
    required this.sourceTaskKey,
  });

  final MicroCompetencyId competencyId;
  final String stepKey;
  final String label;
  final TrainingMode mode;
  final DateTime lastSeen;
  final String sourceTaskKey;
}

class StepRecoveryPlan {
  const StepRecoveryPlan({
    required this.focus,
    required this.tasks,
  });

  final IndependentStepRecoveryFocus focus;
  final List<RemediationTask> tasks;

  String get title => '${focus.label} kurz festigen';
}

class StepRecoveryGenerator {
  StepRecoveryGenerator({Random? random}) : _random = random ?? Random();

  static const supportedStepKeys = <String>{
    'onesDigit',
    'groupCount',
    'itemsPerGroup',
    'bridgeAmount',
    'remainingAddend',
    'remainingSubtrahend',
    'onesAlignment',
    'regroupDecision',
    'carryDecision',
    'firstPartialProduct',
    'secondPartialProduct',
    'anchorFact',
    'multiplicationCarry',
    'nextMultiplierDigit',
    'firstQuotientDigit',
    'firstDivisionRemainder',
    'storyInfo',
    'storyOperation',
    'storyEquation',
    'storyCalculation',
    'storyInterpretation',
    'divisionTargetQuantity',
    'matchingMultiplicationFact',
    'inverseOperationChoice',
    'wallOperationChoice',
    'moneyOperationChoice',
    'measureOperationChoice',
    'doubleHalfMeaning',
    'unitValue',
    'minutesToNextHour',
    'equalPartSize',
    'decidingPlace',
    'smallestOrderedNumber',
    'numberWordTensOnes',
    'placeValueContribution',
    'gapToAnchor',
    'firstMentalChunk',
    'referenceEstimate',
    'roundedSummands',
    'errorPlace',
    'unitRelation',
    'minuteSecondRelation',
    'roundingDecisionDigit',
    'minuteHandMinutes',
    'sequenceStepSize',
  };

  static bool supports(String stepKey) => supportedStepKeys.contains(stepKey);

  final Random _random;

  StepRecoveryPlan generate({
    required IndependentStepRecoveryFocus focus,
    required NumberRangeLevel range,
  }) {
    if (!supports(focus.stepKey)) {
      throw ArgumentError.value(
        focus.stepKey,
        'focus.stepKey',
        'Für diesen Teilschritt gibt es noch keinen gezielten Recovery-Pfad.',
      );
    }
    return StepRecoveryPlan(
      focus: focus,
      tasks: [
        _task(
          focus,
          RemediationStage.supported,
          range,
        ),
        _task(
          focus,
          RemediationStage.transfer,
          range,
        ),
        _task(
          focus,
          RemediationStage.check,
          range,
        ),
      ],
    );
  }

  RemediationTask _task(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) =>
      switch (focus.stepKey) {
        'onesDigit' => _onesDigit(focus, stage, range),
        'groupCount' =>
          _groups(focus, stage, range, askForGroups: true),
        'itemsPerGroup' =>
          _groups(focus, stage, range, askForGroups: false),
        'bridgeAmount' => _bridgeAmount(focus, stage, range),
        'remainingAddend' => _remainingAddend(focus, stage, range),
        'remainingSubtrahend' =>
          _remainingSubtrahend(focus, stage, range),
        'onesAlignment' => _onesAlignment(focus, stage, range),
        'regroupDecision' =>
          _regroupDecision(focus, stage, range, complement: false),
        'carryDecision' => _carryDecision(focus, stage, range),
        'firstPartialProduct' =>
          focus.competencyId == MicroCompetencyId.multiplicationFacts
              ? _multiplicationFactPartialProduct(
                  focus,
                  stage,
                  range,
                  second: false,
                )
              : _firstPartialProduct(focus, stage, range),
        'secondPartialProduct' => _multiplicationFactPartialProduct(
            focus,
            stage,
            range,
            second: true,
          ),
        'anchorFact' => _multiplicationFactAnchor(
            focus,
            stage,
            range,
          ),
        'multiplicationCarry' =>
          _multiplicationCarry(focus, stage, range),
        'nextMultiplierDigit' =>
          _nextMultiplierDigit(focus, stage, range),
        'firstQuotientDigit' => _divisionStep(
            focus,
            stage,
            range,
            askForRemainder: false,
          ),
        'firstDivisionRemainder' => _divisionStep(
            focus,
            stage,
            range,
            askForRemainder: true,
          ),
        'storyInfo' => _storyInfoStep(focus, stage, range),
        'storyOperation' => _storyOperationStep(focus, stage, range),
        'storyEquation' => _storyEquationStep(focus, stage, range),
        'storyCalculation' => _storyCalculationStep(focus, stage, range),
        'storyInterpretation' =>
          _storyInterpretationStep(focus, stage, range),
        'divisionTargetQuantity' =>
          _divisionTargetQuantityStep(focus, stage, range),
        'matchingMultiplicationFact' =>
          _matchingMultiplicationFactStep(focus, stage, range),
        'inverseOperationChoice' =>
          _inverseOperationChoiceStep(focus, stage, range),
        'wallOperationChoice' =>
          _wallOperationChoiceStep(focus, stage, range),
        'moneyOperationChoice' =>
          _moneyOperationChoiceStep(focus, stage, range),
        'measureOperationChoice' =>
          _measureOperationChoiceStep(focus, stage, range),
        'doubleHalfMeaning' =>
          _doubleHalfMeaningStep(focus, stage, range),
        'unitValue' => _proportionalUnitValueStep(focus, stage, range),
        'minutesToNextHour' => _timeDurationFirstJump(focus, stage),
        'equalPartSize' => _fractionEqualPartSizeStep(focus, stage, range),
        'decidingPlace' => _largeNumberDecidingPlaceStep(focus, stage, range),
        'smallestOrderedNumber' =>
          _largeNumberSmallestStep(focus, stage, range),
        'numberWordTensOnes' =>
          _numberWordTensOnesStep(focus, stage),
        'placeValueContribution' =>
          _placeValueContributionStep(focus, stage, range),
        'gapToAnchor' => _strategyGapToAnchorStep(focus, stage, range),
        'firstMentalChunk' =>
          _firstMentalChunkStep(focus, stage, range),
        'referenceEstimate' =>
          _plausibilityReferenceEstimateStep(focus, stage, range),
        'roundedSummands' =>
          _estimationRoundedSummandsStep(focus, stage, range),
        'errorPlace' => _errorPlaceStep(focus, stage, range),
        'unitRelation' => _unitRelationStep(focus, stage, range),
        'minuteSecondRelation' => _minuteSecondRelationStep(focus, stage),
        'roundingDecisionDigit' =>
          _roundingDecisionDigitStep(focus, stage, range),
        'minuteHandMinutes' => _minuteHandMinutesStep(focus, stage, range),
        'sequenceStepSize' => _sequenceStepSizeStep(focus, stage, range),
        _ => throw StateError('Nicht unterstützter Teilschritt: ${focus.stepKey}'),
      };

  RemediationTask _onesDigit(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final limit = max(20, min(range.maxValue, 1000));
    final number = _between(10, limit);
    return _numeric(
      focus: focus,
      stage: stage,
      key: 'place:$number',
      prompt: 'Welche Ziffer steht bei $number an der Einerstelle?',
      answer: number % 10,
      max: 9,
      hint: 'Die Einerstelle ist immer ganz rechts.',
    );
  }

  RemediationTask _groups(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range, {
    required bool askForGroups,
  }) {
    final limit = max(10, min(range.maxValue, 100));
    var groups = _between(2, min(6, limit ~/ 2));
    var each = _between(2, min(6, max(2, limit ~/ groups)));
    for (var attempt = 0;
        attempt < 20 && groups * each > limit;
        attempt++) {
      groups = _between(2, min(6, limit ~/ 2));
      each = _between(2, min(6, max(2, limit ~/ groups)));
    }
    return _numeric(
      focus: focus,
      stage: stage,
      key: 'groups:$groups:$each',
      prompt: askForGroups
          ? '$groups gleich große Gruppen mit je $each Punkten: Wie viele Gruppen sind es?'
          : '$groups gleich große Gruppen mit je $each Punkten: Wie viele Punkte liegen in jeder Gruppe?',
      answer: askForGroups ? groups : each,
      max: 8,
      hint: askForGroups
          ? 'Zähle nur die Gruppen, noch nicht alle Punkte.'
          : 'Schau nur auf eine einzelne Gruppe.',
    );
  }

  RemediationTask _bridgeAmount(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final limit = max(20, min(range.maxValue, 100));
    final decade = _between(1, max(1, limit ~/ 10 - 1));
    final ones = _between(1, 9);
    final a = decade * 10 + ones;
    final nextTen = (decade + 1) * 10;
    return _numeric(
      focus: focus,
      stage: stage,
      key: 'bridge:$a:$nextTen',
      prompt: 'Wie viel fehlt von $a bis $nextTen?',
      answer: nextTen - a,
      max: 10,
      hint: 'Ergänze nur bis zum nächsten vollen Zehner.',
    );
  }

  RemediationTask _remainingAddend(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final limit = max(20, min(range.maxValue, 100));
    final decade = _between(1, max(1, limit ~/ 10 - 1));
    final ones = _between(2, 9);
    final a = decade * 10 + ones;
    final toTen = 10 - ones;
    final b = _between(toTen + 1, 9);
    return _numeric(
      focus: focus,
      stage: stage,
      key: 'add-rest:$a:$b',
      prompt:
          'Bei $a + $b werden zuerst $toTen bis zum nächsten Zehner genutzt. Wie viel von $b bleibt danach übrig?',
      answer: b - toTen,
      max: 9,
      hint: 'Ziehe den schon verwendeten Teil $toTen von $b ab.',
    );
  }

  RemediationTask _remainingSubtrahend(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final limit = max(20, min(range.maxValue, 100));
    var a = _between(11, limit);
    for (var attempt = 0;
        attempt < 20 && (a % 10 == 0 || a % 10 == 9);
        attempt++) {
      a = _between(11, limit);
    }
    if (a % 10 == 0 || a % 10 == 9) {
      a = min(limit, 18);
    }
    final ones = a % 10;
    final maxB = min(a - 1, 30);
    final b = _between(ones + 1, max(ones + 1, maxB));
    return _numeric(
      focus: focus,
      stage: stage,
      key: 'sub-rest:$a:$b',
      prompt:
          'Bei $a − $b werden zuerst $ones bis zum vollen Zehner weggenommen. Wie viel vom Subtrahenden $b bleibt danach?',
      answer: b - ones,
      max: max(10, b),
      hint: 'Ziehe vom Subtrahenden nur den bereits verwendeten Teil $ones ab.',
    );
  }

  RemediationTask _onesAlignment(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final limit = max(20, min(range.maxValue, 1000));
    final minus = focus.sourceTaskKey.contains(':-:');
    final b = _between(1, max(1, limit - 1));
    final a = minus
        ? _between(max(10, b), limit)
        : _between(1, max(1, limit - b));
    final symbol = minus ? '−' : '+';
    return _numeric(
      focus: focus,
      stage: stage,
      key: 'align:${minus ? '-' : '+'}:$a:$b',
      prompt:
          'Bei $a $symbol $b schriftlich: Welche Ziffer von $b steht unten in der Einer-Spalte?',
      answer: b % 10,
      max: 9,
      hint: 'Einer stehen unter Einern – nimm die ganz rechte Ziffer von $b.',
    );
  }

  RemediationTask _regroupDecision(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range, {
    required bool complement,
  }) {
    final limit = max(20, min(range.maxValue, 100));
    final needsRegrouping = _random.nextBool();
    var a = _between(10, limit);
    var b = _between(1, max(1, a - 1));
    for (var attempt = 0;
        attempt < 40 && ((a % 10) < (b % 10)) != needsRegrouping;
        attempt++) {
      a = _between(10, limit);
      b = _between(1, max(1, a - 1));
    }
    if (((a % 10) < (b % 10)) != needsRegrouping) {
      if (needsRegrouping) {
        a = min(limit, 12);
        b = 5;
      } else {
        a = min(limit, 18);
        b = 5;
      }
    }
    final topOnes = a % 10;
    final bottomOnes = b % 10;
    return _choice(
      focus: focus,
      stage: stage,
      key: 'regroup:$a:$b',
      prompt: complement
          ? 'Bei $a − $b: Musst du in der Einer-Spalte über 10 ergänzen und einen Übertrag beachten?'
          : 'Bei $a − $b: Musst du in der Einer-Spalte einen Zehner entbündeln?',
      choices: const ['Ja', 'Nein'],
      answer: needsRegrouping ? 0 : 1,
      hint:
          'Vergleiche nur die beiden Einerziffern: $topOnes und $bottomOnes.',
    );
  }

  RemediationTask _carryDecision(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    if (focus.sourceTaskKey.contains(':-:')) {
      return _regroupDecision(
        focus,
        stage,
        range,
        complement: true,
      );
    }

    final limit = max(20, min(range.maxValue, 100));
    final needsCarry = _random.nextBool();
    var a = _between(10, max(10, limit - 1));
    var b = _between(1, max(1, limit - a));
    for (var attempt = 0;
        attempt < 40 &&
            (((a % 10) + (b % 10) >= 10) != needsCarry);
        attempt++) {
      a = _between(10, max(10, limit - 1));
      b = _between(1, max(1, limit - a));
    }
    if ((((a % 10) + (b % 10) >= 10) != needsCarry)) {
      if (needsCarry) {
        a = min(limit - 8, 12);
        b = 8;
      } else {
        a = min(limit - 3, 13);
        b = 3;
      }
    }
    final aOnes = a % 10;
    final bOnes = b % 10;
    return _choice(
      focus: focus,
      stage: stage,
      key: 'carry:$a:$b',
      prompt:
          'Bei $a + $b: Entsteht in der Einer-Spalte ein Übertrag?',
      choices: const ['Ja', 'Nein'],
      answer: needsCarry ? 0 : 1,
      hint:
          'Addiere nur die Einer $aOnes + $bOnes. Ab 10 entsteht ein Übertrag.',
    );
  }

  RemediationTask _multiplicationFactPartialProduct(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range, {
    required bool second,
  }) {
    final limit = max(20, min(range.maxValue, 100));
    final maxA = min(9, max(2, limit ~/ 4));
    final a = _between(2, maxA);
    final maxB = min(10, max(4, limit ~/ a));
    final b = _between(4, maxB);
    final left = b ~/ 2;
    final right = b - left;
    final factor = second ? right : left;
    final product = a * factor;
    return _numeric(
      focus: focus,
      stage: stage,
      key: 'fact-partial:$a:$b:${second ? 'second' : 'first'}',
      prompt:
          'Zerlege $b in $left und $right. Wie viel ist $a × $factor?',
      answer: product,
      max: max(20, min(limit, product + 8)),
      hint:
          'Berechne nur dieses Teilprodukt. Danach kannst du beide Teilprodukte zusammenfügen.',
    );
  }

  RemediationTask _multiplicationFactAnchor(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final limit = max(20, min(range.maxValue, 100));
    final maxA = min(9, max(2, limit ~/ 6));
    final a = _between(2, maxA);
    final maxB = min(10, max(6, limit ~/ a));
    final b = _between(6, maxB);
    final anchorProduct = a * 5;
    return _numeric(
      focus: focus,
      stage: stage,
      key: 'fact-anchor:$a:$b',
      prompt:
          'Für $a × $b nutzt du die bekannte Ankeraufgabe $a × 5. Wie groß ist das Ankerprodukt?',
      answer: anchorProduct,
      max: max(20, min(limit, anchorProduct + 8)),
      hint:
          'Rechne zuerst sicher mit ×5. Von dort gehst du zur Zielaufgabe weiter.',
    );
  }

  RemediationTask _firstPartialProduct(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final limit = max(20, min(range.maxValue, 100));
    final ones = _between(2, min(9, max(2, limit ~/ 2)));
    final multiplier =
        _between(2, min(9, max(2, limit ~/ ones)));
    final a = min(limit, 10 + ones);
    final product = ones * multiplier;
    return _numeric(
      focus: focus,
      stage: stage,
      key: 'partial-product:$a:$multiplier',
      prompt:
          'Bei $a × $multiplier schriftlich: Was ergibt zuerst die Einer-Spalte $ones × $multiplier?',
      answer: product,
      max: max(20, min(limit, product + 5)),
      hint:
          'Rechne zunächst nur die beiden Ziffern der Einer-Spalte.',
    );
  }

  RemediationTask _multiplicationCarry(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final limit = max(20, min(range.maxValue, 100));
    final ones = _between(5, min(9, max(5, limit ~/ 2)));
    final minMultiplier = max(2, (10 + ones - 1) ~/ ones);
    final maxMultiplier = min(9, max(minMultiplier, limit ~/ ones));
    final multiplier = _between(minMultiplier, maxMultiplier);
    final product = ones * multiplier;
    return _numeric(
      focus: focus,
      stage: stage,
      key: 'mul-carry:$ones:$multiplier',
      prompt:
          'In der Einer-Spalte rechnest du $ones × $multiplier = $product. Welchen Übertrag schreibst du zur nächsten Stelle?',
      answer: product ~/ 10,
      max: 9,
      hint:
          'Die Einerziffer bleibt unten. Die Zehner des Teilprodukts werden übertragen.',
    );
  }

  RemediationTask _nextMultiplierDigit(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final limit = max(20, min(range.maxValue, 99));
    final multiplier = _between(11, limit);
    final tens = (multiplier ~/ 10) % 10;
    final ones = multiplier % 10;
    return _numeric(
      focus: focus,
      stage: stage,
      key: 'next-multiplier:$multiplier',
      prompt:
          'Beim Faktor $multiplier hast du schon mit der Einerziffer $ones gerechnet. Mit welcher Ziffer rechnest du als Nächstes?',
      answer: tens,
      max: 9,
      hint:
          'Nach den Einern folgt die Zehnerziffer des zweiten Faktors.',
    );
  }

  RemediationTask _divisionStep(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range, {
    required bool askForRemainder,
  }) {
    final limit = max(20, min(range.maxValue, 100));
    var divisor = _between(2, min(9, max(2, limit ~/ 2)));
    var quotientDigit = _between(2, 9);
    var remainder = _between(0, divisor - 1);
    var chunk = divisor * quotientDigit + remainder;
    for (var attempt = 0;
        attempt < 40 && (chunk < 10 || chunk > limit);
        attempt++) {
      divisor = _between(2, min(9, max(2, limit ~/ 2)));
      quotientDigit = _between(2, 9);
      remainder = _between(0, divisor - 1);
      chunk = divisor * quotientDigit + remainder;
    }
    if (chunk < 10 || chunk > limit) {
      divisor = 3;
      quotientDigit = 4;
      remainder = min(2, divisor - 1);
      chunk = divisor * quotientDigit + remainder;
    }
    final dividend = chunk;
    return _numeric(
      focus: focus,
      stage: stage,
      key: 'division:$dividend:$divisor:$chunk',
      prompt: askForRemainder
          ? 'Beim ersten Schritt von $dividend ÷ $divisor rechnest du mit $chunk. Welcher Rest bleibt nach $quotientDigit × $divisor?'
          : 'Beim ersten Schritt von $dividend ÷ $divisor: Wie oft passt $divisor in $chunk?',
      answer: askForRemainder ? remainder : quotientDigit,
      max: 9,
      hint: askForRemainder
          ? 'Rechne $chunk − ($quotientDigit × $divisor).'
          : 'Suche die größte Malaufgabe mit $divisor, die $chunk nicht überschreitet.',
    );
  }

  RemediationTask _wallOperationChoiceStep(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final limit = max(4, min(range.maxValue, 100));
    final sourceAddition =
        _wallSourceNeedsAddition(focus.sourceTaskKey) ?? true;
    final addition = switch (stage) {
      RemediationStage.supported => sourceAddition,
      RemediationStage.transfer => !sourceAddition,
      RemediationStage.check => _random.nextBool(),
      _ => sourceAddition,
    };

    final choices = <String>['Plus (+)', 'Minus (−)']..shuffle(_random);
    final correct = addition ? 'Plus (+)' : 'Minus (−)';

    if (addition) {
      final first = _between(1, max(1, limit ~/ 2));
      final second = _between(1, max(1, limit - first));
      return _choice(
        focus: focus,
        stage: stage,
        key: 'wall-direction:up:$first:$second',
        prompt:
            'In einer Zahlenmauer stehen $first und $second direkt nebeneinander. Der Stein direkt darüber fehlt. Welche Rechenart brauchst du?',
        choices: choices,
        answer: choices.indexOf(correct),
        hint:
            'Nach oben gilt die Zahlenmauer-Regel: Die beiden unteren Nachbarsteine werden zusammengezählt.',
      );
    }

    final upper = _between(2, limit);
    final knownLower = _between(1, upper - 1);
    return _choice(
      focus: focus,
      stage: stage,
      key: 'wall-direction:down:$upper:$knownLower',
      prompt:
          'In einer Zahlenmauer steht im oberen Stein $upper. Darunter ist ein Nachbarstein $knownLower bekannt, der andere fehlt. Welche Rechenart brauchst du?',
      choices: choices,
      answer: choices.indexOf(correct),
      hint:
          'Wenn ein unterer Stein fehlt, rechnest du von der Summe rückwärts: oberer Stein minus bekannter unterer Stein.',
    );
  }

  bool? _wallSourceNeedsAddition(String sourceTaskKey) {
    final parts = sourceTaskKey.split(':');
    final index = parts.indexOf('wall');
    if (index < 0 || index + 2 >= parts.length) return null;
    final hidden = int.tryParse(parts[index + 2]);
    if (hidden == null || hidden < 0 || hidden > 5) return null;
    return hidden >= 3;
  }

  RemediationTask _doubleHalfMeaningStep(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final sourceDouble = focus.sourceTaskKey.contains('double:');
    final useDouble = switch (stage) {
      RemediationStage.supported => sourceDouble,
      RemediationStage.transfer => !sourceDouble,
      RemediationStage.check => _random.nextBool(),
      _ => sourceDouble,
    };
    final maxHalf = max(1, min(range.maxValue, 100) ~/ 2);
    final base = _between(1, maxHalf);
    final shown = useDouble ? base : base * 2;
    final choices = <String>[
      'zweimal dieselbe Menge zusammen',
      'in zwei gleich große Teile teilen',
    ]..shuffle(_random);
    final correct = useDouble
        ? 'zweimal dieselbe Menge zusammen'
        : 'in zwei gleich große Teile teilen';

    return _choice(
      focus: focus,
      stage: stage,
      key: 'double-half-meaning:${useDouble ? 'double' : 'half'}:$shown',
      prompt: useDouble
          ? 'Bei „das Doppelte von $shown“: Was bedeutet „doppelt“?'
          : 'Bei „die Hälfte von $shown“: Was bedeutet „Hälfte“?',
      choices: choices,
      answer: choices.indexOf(correct),
      hint: useDouble
          ? 'Denke an zwei gleich große Mengen mit derselben Anzahl.'
          : 'Denke an zwei gleich große Teile, die zusammen wieder das Ganze ergeben.',
    );
  }

  RemediationTask _measureOperationChoiceStep(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final limit = max(2, min(range.maxValue, 100));
    final source = _measurementCalculationSource(focus.sourceTaskKey);
    final sourceAddition = source?.addition ?? true;
    final addition = switch (stage) {
      RemediationStage.supported => sourceAddition,
      RemediationStage.transfer => !sourceAddition,
      RemediationStage.check => _random.nextBool(),
      _ => sourceAddition,
    };

    var first = addition
        ? _between(1, max(1, limit - 1))
        : _between(2, limit);
    var second = addition
        ? _between(1, max(1, limit - first))
        : _between(1, first - 1);

    if (source != null &&
        source.addition == addition &&
        source.first == first &&
        source.second == second) {
      if (addition) {
        if (second < limit - first) {
          second += 1;
        } else if (first > 1) {
          first -= 1;
        }
      } else if (second < first - 1) {
        second += 1;
      } else if (first < limit) {
        first += 1;
      }
    }

    final choices = <String>['Plus (+)', 'Minus (−)']..shuffle(_random);
    final correct = addition ? 'Plus (+)' : 'Minus (−)';

    return _choice(
      focus: focus,
      stage: stage,
      key:
          'measurement-plan:${addition ? 'add' : 'subtract'}:$first:$second',
      prompt: addition
          ? 'Ein Band ist $first cm lang, ein zweites $second cm. Welche Rechenart brauchst du für die Gesamtlänge?'
          : 'Ein Seil ist $first cm lang. $second cm werden abgeschnitten. Welche Rechenart brauchst du für die Restlänge?',
      choices: choices,
      answer: choices.indexOf(correct),
      hint:
          'Prüfe, ob gleichartige Längen zusammenkommen oder ob von einer ganzen Länge ein Stück weggenommen wird.',
    );
  }

  ({bool addition, int first, int second})? _measurementCalculationSource(
    String sourceTaskKey,
  ) {
    final parts = sourceTaskKey.split(':');
    final index = parts.indexOf('measure');
    if (index < 0 || index + 2 >= parts.length) return null;
    final family = parts[index + 1];
    if (family != 'add' && family != 'subtract') return null;
    final first = int.tryParse(parts[parts.length - 2]);
    final second = int.tryParse(parts.last);
    if (first == null || second == null) return null;
    return (
      addition: family == 'add',
      first: first,
      second: second,
    );
  }

  RemediationTask _moneyOperationChoiceStep(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final limit = max(2, min(range.maxValue, 100));
    final source = _moneyCalculationSource(focus.sourceTaskKey);
    final sourceAddition = source?.addition ?? false;
    final addition = switch (stage) {
      RemediationStage.supported => sourceAddition,
      RemediationStage.transfer => !sourceAddition,
      RemediationStage.check => _random.nextBool(),
      _ => sourceAddition,
    };

    var first = addition
        ? _between(1, max(1, limit - 1))
        : _between(2, limit);
    var second = addition
        ? _between(1, max(1, limit - first))
        : _between(1, first - 1);

    if (source != null &&
        source.addition == addition &&
        source.first == first &&
        source.second == second) {
      if (addition) {
        if (second < limit - first) {
          second += 1;
        } else if (first > 1) {
          first -= 1;
        }
      } else if (second < first - 1) {
        second += 1;
      } else if (first < limit) {
        first += 1;
      }
    }

    final choices = <String>['Plus (+)', 'Minus (−)']..shuffle(_random);
    final correct = addition ? 'Plus (+)' : 'Minus (−)';

    return _choice(
      focus: focus,
      stage: stage,
      key:
          'money-plan:${addition ? 'add' : 'change'}:$first:$second',
      prompt: addition
          ? 'Ein Heft kostet $first € und ein Stift $second €. Welche Rechenart brauchst du für den Gesamtpreis?'
          : 'Du hast $first € und gibst $second € aus. Welche Rechenart brauchst du für das Restgeld?',
      choices: choices,
      answer: choices.indexOf(correct),
      hint:
          'Prüfe zuerst, ob Geldbeträge zusammenkommen oder ob ein Betrag von einem vorhandenen Betrag weggeht.',
    );
  }

  ({bool addition, int first, int second})? _moneyCalculationSource(
    String sourceTaskKey,
  ) {
    final parts = sourceTaskKey.split(':');
    final index = parts.indexOf('money');
    if (index < 0 || index + 2 >= parts.length) return null;
    final family = parts[index + 1];
    if (family != 'add' && family != 'change' && family != 'missing') {
      return null;
    }
    final first = int.tryParse(parts[parts.length - 2]);
    final second = int.tryParse(parts.last);
    if (first == null || second == null) return null;
    return (
      addition: family == 'add',
      first: first,
      second: second,
    );
  }

  RemediationTask _inverseOperationChoiceStep(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final source = _inverseRelationshipSource(focus.sourceTaskKey);
    final multiplicative = source?.operation == 'x';
    final sourceAmount = source?.amount ??
        _between(1, max(1, min(10, range.maxValue ~/ 2)));
    final amount = stage == RemediationStage.check
        ? _differentValue(
            sourceAmount,
            1,
            max(1, min(10, range.maxValue ~/ 2)),
          )
        : sourceAmount;

    final sourceDirection = multiplicative ? 'x' : '+';
    final reverseDirection = multiplicative ? 'divide' : '-';
    final direction = switch (stage) {
      RemediationStage.supported => sourceDirection,
      RemediationStage.transfer => reverseDirection,
      RemediationStage.check =>
        _random.nextBool() ? sourceDirection : reverseDirection,
      _ => sourceDirection,
    };

    final shown = switch (direction) {
      '+' => '+$amount',
      '-' => '−$amount',
      'x' => '×$amount',
      _ => '÷$amount',
    };
    final correct = switch (direction) {
      '+' => '−$amount',
      '-' => '+$amount',
      'x' => '÷$amount',
      _ => '×$amount',
    };
    final choices = multiplicative
        ? <String>['×$amount', '÷$amount']
        : <String>['+$amount', '−$amount'];
    choices.shuffle(_random);

    return _choice(
      focus: focus,
      stage: stage,
      key:
          'inverse-operation:${multiplicative ? 'multiply-divide' : 'plus-minus'}:$direction:$amount',
      prompt:
          'Welche Rechenoperation macht $shown wieder rückgängig?',
      choices: choices,
      answer: choices.indexOf(correct),
      hint: multiplicative
          ? 'Mal und Teilen sind Gegenrechenarten.'
          : 'Plus und Minus sind Gegenrechenarten.',
    );
  }

  ({String operation, int amount})? _inverseRelationshipSource(
    String sourceTaskKey,
  ) {
    final parts = sourceTaskKey.split(':');
    final index = parts.indexOf('family');
    if (index < 0 || index + 3 >= parts.length) return null;
    final operation = parts[index + 1];
    if (operation != '+' && operation != 'x') return null;
    final amount = int.tryParse(parts[index + 3]);
    if (amount == null || amount <= 0) return null;
    return (operation: operation, amount: amount);
  }

  int _differentValue(int source, int low, int high) {
    if (high <= low) return low;
    final candidates = [
      for (var value = low; value <= high; value++)
        if (value != source) value,
    ];
    if (candidates.isEmpty) return source;
    return candidates[_random.nextInt(candidates.length)];
  }

  RemediationTask _matchingMultiplicationFactStep(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final limit = max(10, min(range.maxValue, 100));
    final maxDivisor = min(10, max(2, limit ~/ 2));
    final source = _divisionFactFromSource(focus.sourceTaskKey);
    final baseDivisor = source != null &&
            source.divisor >= 2 &&
            source.divisor <= maxDivisor
        ? source.divisor
        : min(5, maxDivisor);

    final divisor = switch (stage) {
      RemediationStage.supported => baseDivisor,
      RemediationStage.transfer => [
          for (var value = 2; value <= maxDivisor; value++)
            if (value != baseDivisor) value,
        ][_random.nextInt(maxDivisor - 2)],
      RemediationStage.check => _between(2, maxDivisor),
      _ => baseDivisor,
    };

    final maxQuotient = min(10, max(2, limit ~/ divisor));
    final sourceQuotient = source == null || source.divisor == 0
        ? null
        : source.dividend ~/ source.divisor;
    var quotientCandidates = [
      for (var value = 2; value <= maxQuotient; value++)
        if (!(stage == RemediationStage.supported &&
            divisor == source?.divisor &&
            value == sourceQuotient))
          value,
    ];
    if (quotientCandidates.isEmpty) {
      quotientCandidates = [
        for (var value = 2; value <= maxQuotient; value++) value,
      ];
    }
    final quotient =
        quotientCandidates[_random.nextInt(quotientCandidates.length)];
    final dividend = divisor * quotient;
    final correct = '$divisor × ? = $dividend';
    final choices = <String>[
      correct,
      '$dividend × ? = $divisor',
      '$divisor + ? = $dividend',
      '$dividend − ? = $divisor',
    ]..shuffle(_random);

    return _choice(
      focus: focus,
      stage: stage,
      key: 'division-inverse:$dividend:$divisor',
      prompt:
          'Welche Mal-Umkehraufgabe passt zu $dividend ÷ $divisor?',
      choices: choices,
      answer: choices.indexOf(correct),
      hint:
          'Der Teiler wird zum bekannten Faktor: Teiler × ? = Gesamtzahl.',
    );
  }

  ({int dividend, int divisor})? _divisionFactFromSource(
    String sourceTaskKey,
  ) {
    final parts = sourceTaskKey.split(':');
    final index = parts.indexOf('divide');
    if (index < 0 || index + 2 >= parts.length) return null;
    final dividend = int.tryParse(parts[index + 1]);
    final divisor = int.tryParse(parts[index + 2]);
    if (dividend == null || divisor == null || divisor <= 0) return null;
    return (dividend: dividend, divisor: divisor);
  }

  RemediationTask _divisionTargetQuantityStep(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final limit = max(10, min(range.maxValue, 100));
    final sourceSharing = focus.sourceTaskKey.contains(':story:sharing:');
    final sharing = switch (stage) {
      RemediationStage.supported => sourceSharing,
      RemediationStage.transfer => !sourceSharing,
      RemediationStage.check => _random.nextBool(),
      _ => sourceSharing,
    };
    final groups = _between(2, min(8, max(2, limit ~/ 2)));
    final maxEach = max(2, min(10, limit ~/ groups));
    final each = _between(2, maxEach);
    final total = groups * each;
    const choices = [
      'Anzahl der Gruppen',
      'Menge in jeder Gruppe',
      'Gesamtmenge',
    ];

    return _choice(
      focus: focus,
      stage: stage,
      key:
          'division-target:${sharing ? 'sharing' : 'grouping'}:$total:${sharing ? groups : each}',
      prompt: sharing
          ? '$total Plättchen werden gleichmäßig auf $groups Kinder verteilt. Welche Größe musst du herausfinden?'
          : '$total Plättchen werden in Gruppen zu je $each Plättchen gelegt. Welche Größe musst du herausfinden?',
      choices: choices,
      answer: sharing ? 1 : 0,
      hint: sharing
          ? 'Die Anzahl der Gruppen ist bekannt. Gesucht ist, wie viel jede Gruppe bekommt.'
          : 'Die Gruppengröße ist bekannt. Gesucht ist, wie viele Gruppen entstehen.',
    );
  }

  RemediationTask _sequenceStepSizeStep(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final limit = max(4, range.maxValue);
    var allowedSteps =
        [1, 2, 5, 10].where((step) => step * 3 <= limit).toList();
    if (allowedSteps.isEmpty) allowedSteps = [1];

    final parts = focus.sourceTaskKey.split(':');
    final sequenceIndex = parts.indexOf('sequence');
    final sourceDirection =
        sequenceIndex >= 0 && sequenceIndex + 1 < parts.length
            ? parts[sequenceIndex + 1]
            : '+';
    final parsedStep =
        sequenceIndex >= 0 && sequenceIndex + 3 < parts.length
            ? int.tryParse(parts[sequenceIndex + 3])
            : null;
    final sourceStep =
        parsedStep != null && allowedSteps.contains(parsedStep)
            ? parsedStep
            : allowedSteps.first;

    final backwards = switch (stage) {
      RemediationStage.supported => sourceDirection == '-',
      RemediationStage.transfer => sourceDirection != '-',
      RemediationStage.check => _random.nextBool(),
      _ => sourceDirection == '-',
    };
    final step = stage == RemediationStage.check
        ? allowedSteps[_random.nextInt(allowedSteps.length)]
        : sourceStep;

    final start = backwards
        ? _between(step * 2, limit)
        : _between(0, max(0, limit - step * 2));
    final second = backwards ? start - step : start + step;
    final third = backwards ? start - step * 2 : start + step * 2;
    final alternative = allowedSteps.firstWhere(
      (value) => value != step,
      orElse: () => step + 1,
    );
    final choices = <String>[
      'immer +$step',
      'immer −$step',
      'immer +$alternative',
      'immer −$alternative',
    ]..shuffle(_random);
    final correct = backwards ? 'immer −$step' : 'immer +$step';

    return _choice(
      focus: focus,
      stage: stage,
      key: 'sequence-rule:${backwards ? '-' : '+'}:$start:$step',
      prompt:
          '$start, $second, $third: Welche Regel beschreibt die Schrittweite?',
      choices: choices,
      answer: choices.indexOf(correct),
      hint:
          'Vergleiche zwei Nachbarzahlen. Prüfe zuerst, ob die Folge größer oder kleiner wird, und dann um wie viel.',
    );
  }

  RemediationTask _minuteHandMinutesStep(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final allowedMinutes =
        range.maxValue >= 100 ? <int>[0, 15, 30, 45] : <int>[0, 30];
    final parts = focus.sourceTaskKey.split(':');
    final clockIndex = parts.indexOf('clock');
    final sourceMinute = clockIndex >= 0 && clockIndex + 2 < parts.length
        ? int.tryParse(parts[clockIndex + 2])
        : null;
    final supportedMinute =
        sourceMinute != null && allowedMinutes.contains(sourceMinute)
            ? sourceMinute
            : allowedMinutes.last;
    final transferMinutes = allowedMinutes
        .where((minute) => minute != supportedMinute)
        .toList();
    final minute = switch (stage) {
      RemediationStage.supported => supportedMinute,
      RemediationStage.transfer => transferMinutes.isEmpty
          ? supportedMinute
          : transferMinutes[_random.nextInt(transferMinutes.length)],
      RemediationStage.check =>
        allowedMinutes[_random.nextInt(allowedMinutes.length)],
      _ => supportedMinute,
    };
    final clockNumber = switch (minute) {
      0 => 12,
      15 => 3,
      30 => 6,
      45 => 9,
      _ => 12,
    };
    final choices =
        allowedMinutes.map((value) => '$value Minuten').toList();

    return _choice(
      focus: focus,
      stage: stage,
      key: 'minute-hand:$clockNumber:$minute',
      prompt:
          'Der lange Zeiger zeigt auf die $clockNumber. Wie viele Minuten sind das?',
      choices: choices,
      answer: choices.indexOf('$minute Minuten'),
      hint: allowedMinutes.length == 2
          ? 'Beim langen Zeiger bedeutet die 12: 0 Minuten. Die 6 bedeutet: 30 Minuten.'
          : 'Beim langen Zeiger entsprechen die Zahlen 12, 3, 6 und 9 den Minuten 0, 15, 30 und 45.',
    );
  }

  RemediationTask _roundingDecisionDigitStep(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final availablePlaces = [10, 100, 1000, 10000, 100000]
        .where((place) => place < max(20, range.maxValue))
        .toList();
    final parts = focus.sourceTaskKey.split(':');
    final roundIndex = parts.indexOf('round');
    final sourcePlace = roundIndex >= 0 && roundIndex + 2 < parts.length
        ? int.tryParse(parts[roundIndex + 2])
        : null;
    final supportedPlace = sourcePlace != null &&
            availablePlaces.contains(sourcePlace)
        ? sourcePlace
        : availablePlaces.first;
    final transferPlaces = availablePlaces
        .where((place) => place != supportedPlace)
        .toList();
    final place = switch (stage) {
      RemediationStage.supported => supportedPlace,
      RemediationStage.transfer => transferPlaces.isEmpty
          ? supportedPlace
          : transferPlaces[_random.nextInt(transferPlaces.length)],
      RemediationStage.check =>
        availablePlaces[_random.nextInt(availablePlaces.length)],
      _ => supportedPlace,
    };

    final limit = max(place + 1, range.maxValue);
    final decisionPlace = place ~/ 10;
    final decisionDigit = _between(1, 9);
    final suffix = decisionPlace == 1
        ? 0
        : _between(0, decisionPlace - 1);
    final maxMultiplier = max(
      1,
      (limit - 9 * decisionPlace - suffix) ~/ place,
    );
    final multiplier = _between(1, maxMultiplier);
    final number = multiplier * place +
        decisionDigit * decisionPlace +
        suffix;

    final placeLabel = switch (place) {
      10 => 'Zehner',
      100 => 'Hunderter',
      1000 => 'Tausender',
      10000 => 'Zehntausender',
      100000 => 'Hunderttausender',
      _ => 'Stelle',
    };
    final actualDecisionDigit = (number ~/ decisionPlace) % 10;

    return _numeric(
      focus: focus,
      stage: stage,
      key: 'rounding-decision:$number:$place',
      prompt:
          'Du rundest $number auf $placeLabel. Welche Ziffer entscheidet?',
      answer: actualDecisionDigit,
      max: 9,
      hint:
          'Suche die Rundungsstelle und gehe genau eine Stelle nach rechts.',
    );
  }

  RemediationTask _minuteSecondRelationStep(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
  ) {
    final sourceToSeconds =
        focus.sourceTaskKey.contains(':min-to-sec:');
    final toSeconds = switch (stage) {
      RemediationStage.supported => sourceToSeconds,
      RemediationStage.transfer => !sourceToSeconds,
      RemediationStage.check => _random.nextBool(),
      _ => sourceToSeconds,
    };
    final choices = <String>[
      '1 min = 6 s',
      '1 min = 60 s',
      '1 min = 100 s',
    ]..shuffle(_random);

    return _choice(
      focus: focus,
      stage: stage,
      key:
          'minute-second-relation:${toSeconds ? 'min-to-sec' : 'sec-to-min'}',
      prompt: toSeconds
          ? 'Du willst Minuten in Sekunden umwandeln. Welche Beziehung brauchst du?'
          : 'Du willst Sekunden in Minuten umwandeln. Welche Beziehung brauchst du?',
      choices: choices,
      answer: choices.indexOf('1 min = 60 s'),
      hint:
          'Denke an genau eine volle Minute auf der Uhr. Wie viele Sekunden vergehen in dieser Zeit?',
    );
  }

  RemediationTask _unitRelationStep(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final relations = <({
      String id,
      String start,
      String target,
      String correct,
      List<String> choices,
    })>[
      (
        id: 'm-cm',
        start: 'm',
        target: 'cm',
        correct: '1 m = 100 cm',
        choices: const [
          '1 m = 10 cm',
          '1 m = 100 cm',
          '1 m = 1000 cm',
        ],
      ),
      (
        id: 'km-m',
        start: 'km',
        target: 'm',
        correct: '1 km = 1000 m',
        choices: const [
          '1 km = 100 m',
          '1 km = 1000 m',
          '1 km = 10000 m',
        ],
      ),
      (
        id: 'cm-mm',
        start: 'cm',
        target: 'mm',
        correct: '1 cm = 10 mm',
        choices: const [
          '1 cm = 1 mm',
          '1 cm = 10 mm',
          '1 cm = 100 mm',
        ],
      ),
      (
        id: 'kg-g',
        start: 'kg',
        target: 'g',
        correct: '1 kg = 1000 g',
        choices: const [
          '1 kg = 100 g',
          '1 kg = 1000 g',
          '1 kg = 10000 g',
        ],
      ),
      (
        id: 'l-ml',
        start: 'l',
        target: 'ml',
        correct: '1 l = 1000 ml',
        choices: const [
          '1 l = 100 ml',
          '1 l = 1000 ml',
          '1 l = 10000 ml',
        ],
      ),
      (
        id: 'euro-ct',
        start: '€',
        target: 'ct',
        correct: '1 € = 100 ct',
        choices: const [
          '1 € = 10 ct',
          '1 € = 100 ct',
          '1 € = 1000 ct',
        ],
      ),
      if (range.maxValue >= 1000000) ...[
        (
          id: 't-kg',
          start: 't',
          target: 'kg',
          correct: '1 t = 1000 kg',
          choices: const [
            '1 t = 100 kg',
            '1 t = 1000 kg',
            '1 t = 10000 kg',
          ],
        ),
        (
          id: 'min-h',
          start: 'min',
          target: 'h',
          correct: '1 h = 60 min',
          choices: const [
            '1 h = 30 min',
            '1 h = 60 min',
            '1 h = 100 min',
          ],
        ),
      ],
    ];

    String sourceId() {
      final key = focus.sourceTaskKey;
      if (key.contains(':length:m:')) return 'm-cm';
      if (key.contains(':length:km:')) return 'km-m';
      if (key.contains(':length:cm-mm:')) return 'cm-mm';
      if (key.contains(':mass:kg:')) return 'kg-g';
      if (key.contains(':mass:t-kg:')) return 't-kg';
      if (key.contains(':volume:l:')) return 'l-ml';
      if (key.contains(':money:euro:')) return 'euro-ct';
      if (key.contains(':time:min:')) return 'min-h';
      return relations.first.id;
    }

    final source = relations.firstWhere(
      (relation) => relation.id == sourceId(),
      orElse: () => relations.first,
    );
    final transfer = relations
        .where((relation) => relation.id != source.id)
        .toList();
    final selected = switch (stage) {
      RemediationStage.supported => source,
      RemediationStage.transfer =>
        transfer[_random.nextInt(transfer.length)],
      RemediationStage.check =>
        relations[_random.nextInt(relations.length)],
      _ => source,
    };
    final choices = selected.choices;

    return _choice(
      focus: focus,
      stage: stage,
      key: 'unit-relation:${selected.id}',
      prompt:
          'Welche Beziehung brauchst du, um von ${selected.start} in ${selected.target} umzuwandeln?',
      choices: choices,
      answer: choices.indexOf(selected.correct),
      hint:
          'Merke dir zuerst die feste Beziehung zwischen den beiden Einheiten. Rechne den Zahlenwert erst danach um.',
    );
  }

  RemediationTask _errorPlaceStep(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final limit = max(100, min(range.maxValue, 999999));
    final places = <int>[
      1,
      10,
      if (limit >= 100) 100,
      if (limit >= 10000) 1000,
    ];
    final sourceParts = focus.sourceTaskKey.split(':');
    final placeIndex = sourceParts.indexOf('place');
    final sourcePlace = placeIndex >= 0 && placeIndex + 1 < sourceParts.length
        ? int.tryParse(sourceParts[placeIndex + 1])
        : null;
    final supportedPlace =
        sourcePlace != null && places.contains(sourcePlace)
            ? sourcePlace
            : places.first;
    final transferPlaces =
        places.where((place) => place != supportedPlace).toList();
    final place = switch (stage) {
      RemediationStage.supported => supportedPlace,
      RemediationStage.transfer => transferPlaces.isEmpty
          ? supportedPlace
          : transferPlaces[_random.nextInt(transferPlaces.length)],
      RemediationStage.check => places[_random.nextInt(places.length)],
      _ => supportedPlace,
    };

    final minimumCorrect = max(50, place);
    var correct = _between(minimumCorrect, limit);
    var digit = (correct ~/ place) % 10;
    var canGrow = digit < 9 && correct + place <= limit;
    var canShrink = digit > 0 && correct - place >= 50;
    for (var attempt = 0;
        attempt < 50 && !canGrow && !canShrink;
        attempt++) {
      correct = _between(minimumCorrect, limit);
      digit = (correct ~/ place) % 10;
      canGrow = digit < 9 && correct + place <= limit;
      canShrink = digit > 0 && correct - place >= 50;
    }
    if (!canGrow && !canShrink) {
      correct = max(minimumCorrect, limit - place);
      digit = (correct ~/ place) % 10;
      canGrow = digit < 9 && correct + place <= limit;
      canShrink = digit > 0 && correct - place >= 50;
    }
    final grow = canGrow && (!canShrink || _random.nextBool());
    final wrong = grow ? correct + place : correct - place;
    final a = _between(40, max(40, correct - 10));
    final b = correct - a;

    final choices = <String>[
      'Einerstelle',
      'Zehnerstelle',
      if (place >= 100 || correct >= 100) 'Hunderterstelle',
      if (place >= 1000 || correct >= 1000) 'Tausenderstelle',
    ];
    final correctLabel = switch (place) {
      1 => 'Einerstelle',
      10 => 'Zehnerstelle',
      100 => 'Hunderterstelle',
      1000 => 'Tausenderstelle',
      _ => 'Einerstelle',
    };

    return _choice(
      focus: focus,
      stage: stage,
      key: 'error-place:$place:$a:$b:$wrong',
      prompt:
          'Prüfe die Rechnung: $a + $b = $wrong. Welche Stelle ist in der angegebenen Summe falsch?',
      choices: choices,
      answer: choices.indexOf(correctLabel),
      hint:
          'Prüfe die schriftliche Addition von rechts nach links und suche zuerst die fehlerhafte Stellenwertstelle.',
    );
  }

  RemediationTask _estimationRoundedSummandsStep(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final limit = max(100, min(range.maxValue, 1000000));
    final sourcePlace = _estimationSourcePlace(focus.sourceTaskKey);
    final availablePlaces = <int>[
      10,
      if (limit >= 500) 100,
      if (limit >= 5000) 1000,
    ];
    final validSource =
        sourcePlace != null && availablePlaces.contains(sourcePlace)
            ? sourcePlace
            : null;
    final transferPlaces =
        availablePlaces.where((place) => place != validSource).toList();
    final place = switch (stage) {
      RemediationStage.supported => validSource ?? availablePlaces.first,
      RemediationStage.transfer => transferPlaces.isEmpty
          ? (validSource ?? availablePlaces.first)
          : transferPlaces[_random.nextInt(transferPlaces.length)],
      RemediationStage.check =>
        availablePlaces[_random.nextInt(availablePlaces.length)],
      _ => validSource ?? availablePlaces.first,
    };

    final minimum = max(1, place ~/ 2);
    var a = _between(minimum, max(minimum, limit ~/ 2));
    var b = _between(minimum, max(minimum, limit - a));
    for (var attempt = 0;
        attempt < 40 && (a % place == 0 || b % place == 0);
        attempt++) {
      a = _between(minimum, max(minimum, limit ~/ 2));
      b = _between(minimum, max(minimum, limit - a));
    }

    int rounded(int value) => ((value + place ~/ 2) ~/ place) * place;
    int down(int value) => (value ~/ place) * place;
    int up(int value) => ((value + place - 1) ~/ place) * place;
    final roundedA = rounded(a);
    final roundedB = rounded(b);
    final correct = '$roundedA und $roundedB';
    final values = <String>{
      correct,
      '${down(a)} und $roundedB',
      '${up(a)} und $roundedB',
      '$roundedA und ${down(b)}',
      '$roundedA und ${up(b)}',
      '${down(a)} und ${down(b)}',
      '${up(a)} und ${up(b)}',
    };
    var shift = place;
    while (values.length < 4) {
      values.add('${max(0, roundedA - shift)} und ${roundedB + shift}');
      shift += place;
    }
    final choices = values.take(4).toList()..shuffle(_random);
    final label = switch (place) {
      10 => 'Zehner',
      100 => 'Hunderter',
      _ => 'Tausender',
    };

    return _choice(
      focus: focus,
      stage: stage,
      key: 'estimation-rounded:$place:$a:$b',
      prompt:
          'Du willst $a + $b überschlagen und rundest auf $label. Auf welche beiden Zahlen rundest du zuerst?',
      choices: choices,
      answer: choices.indexOf(correct),
      hint:
          'Runde jeden Summanden für sich auf dieselbe Stelle. Addiere die gerundeten Werte noch nicht.',
    );
  }

  int? _estimationSourcePlace(String sourceTaskKey) {
    final parts = sourceTaskKey.split(':');
    final index = parts.indexOf('estimate');
    if (index < 0 || index + 3 >= parts.length) return null;
    return int.tryParse(parts[index + 3]);
  }

  RemediationTask _plausibilityReferenceEstimateStep(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final limit = max(100, min(range.maxValue, 1000000));
    final sourcePlace = _plausibilitySourcePlace(focus.sourceTaskKey);
    final availablePlaces = <int>[
      10,
      if (limit >= 400) 100,
      if (limit >= 4000) 1000,
    ];
    final validSource = sourcePlace != null &&
            availablePlaces.contains(sourcePlace)
        ? sourcePlace
        : null;
    final transferPlaces =
        availablePlaces.where((place) => place != validSource).toList();
    final place = switch (stage) {
      RemediationStage.supported => validSource ?? availablePlaces.first,
      RemediationStage.transfer => transferPlaces.isEmpty
          ? (validSource ?? availablePlaces.first)
          : transferPlaces[_random.nextInt(transferPlaces.length)],
      RemediationStage.check =>
        availablePlaces[_random.nextInt(availablePlaces.length)],
      _ => validSource ?? availablePlaces.first,
    };

    var a = _between(place, max(place, limit ~/ 2));
    var b = _between(place, max(place, limit - a));
    for (var attempt = 0;
        attempt < 30 && a % place == 0 && b % place == 0;
        attempt++) {
      a = _between(place, max(place, limit ~/ 2));
      b = _between(place, max(place, limit - a));
    }

    int rounded(int value) =>
        ((value + place ~/ 2) ~/ place) * place;
    final estimate = rounded(a) + rounded(b);
    final values = <int>{
      estimate,
      max(0, estimate - place),
      estimate + place,
      estimate + 2 * place,
    }.toList()
      ..shuffle(_random);
    final choices =
        values.map((value) => _formatLargeNumber(value)).toList();
    final placeLabel = switch (place) {
      10 => 'Zehner',
      100 => 'Hunderter',
      _ => 'Tausender',
    };

    return _choice(
      focus: focus,
      stage: stage,
      key: 'plausibility-estimate:$place:$a:$b',
      prompt:
          'Welcher Überschlag entsteht bei $a + $b, wenn du beide Zahlen auf $placeLabel rundest?',
      choices: choices,
      answer: values.indexOf(estimate),
      hint:
          'Runde beide Ausgangszahlen zuerst auf dieselbe Stelle und addiere erst dann die gerundeten Werte.',
    );
  }

  int? _plausibilitySourcePlace(String sourceTaskKey) {
    final parts = sourceTaskKey.split(':');
    final index = parts.indexOf('plausibility');
    if (index < 0 || index + 4 >= parts.length) return null;
    return int.tryParse(parts[index + 4]);
  }

  RemediationTask _firstMentalChunkStep(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final limit = max(100, min(range.maxValue, 1000000));
    final parts = focus.sourceTaskKey.split(':');
    final mentalIndex = parts.indexOf('mental');
    final sourceOperation =
        mentalIndex >= 0 && mentalIndex + 1 < parts.length
            ? parts[mentalIndex + 1]
            : '+';
    final sourceB = mentalIndex >= 0 && mentalIndex + 3 < parts.length
        ? int.tryParse(parts[mentalIndex + 3])
        : null;

    int leadingPlace(int value) {
      var place = 1;
      while (place * 10 <= value) {
        place *= 10;
      }
      return place;
    }

    final operandCap = min(limit - 1, limit >= 10000 ? 49999 : 999);
    final availablePlaces = [10, 100, 1000, 10000]
        .where((place) => place + 1 <= operandCap)
        .toList();
    final sourcePlace =
        sourceB != null && sourceB >= 10 ? leadingPlace(sourceB) : null;
    final supportedPlace =
        sourcePlace != null && availablePlaces.contains(sourcePlace)
            ? sourcePlace
            : availablePlaces.first;
    final transferPlaces =
        availablePlaces.where((place) => place != supportedPlace).toList();
    final place = switch (stage) {
      RemediationStage.supported => supportedPlace,
      RemediationStage.transfer => transferPlaces.isEmpty
          ? supportedPlace
          : transferPlaces[_random.nextInt(transferPlaces.length)],
      RemediationStage.check =>
        availablePlaces[_random.nextInt(availablePlaces.length)],
      _ => supportedPlace,
    };

    final maxDigit = min(9, (operandCap - 1) ~/ place);
    final digit = _between(1, maxDigit);
    final chunk = digit * place;
    final remainder =
        _between(1, min(place - 1, operandCap - chunk));
    final b = chunk + remainder;
    final operation = stage == RemediationStage.check
        ? (_random.nextBool() ? '+' : '-')
        : sourceOperation;
    final a = operation == '+'
        ? _between(1, max(1, limit - b))
        : _between(b, limit);

    final values = <int>{chunk, remainder, b, max(1, chunk ~/ 10)};
    var filler = 1;
    while (values.length < 4) {
      values.add(filler);
      filler += 1;
    }
    final choices = values.take(4).map((value) => '$value').toList()
      ..shuffle(_random);

    return _choice(
      focus: focus,
      stage: stage,
      key: 'mental-chunk:$operation:$a:$b:$place',
      prompt:
          '$a $operation $b: Welche Teilzahl von $b rechnest du beim halbschriftlichen Rechnen zuerst?',
      choices: choices,
      answer: choices.indexOf('$chunk'),
      hint:
          'Zerlege den zweiten Operanden nach Stellenwerten. Beginne mit seinem größten Stellenwertblock.',
    );
  }

  RemediationTask _strategyGapToAnchorStep(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final limit = max(100, min(range.maxValue, 1000000));
    final source = _strategyGapSource(focus.sourceTaskKey);
    final defaultStep = limit <= 100
        ? 10
        : limit >= 10000
            ? 1000
            : 100;
    final sourceStep = source?.step;
    final step = sourceStep != null && sourceStep * 2 <= limit
        ? sourceStep
        : defaultStep;
    final label = switch (step) {
      10 => 'Zehner',
      100 => 'Hunderter',
      _ => 'Tausender',
    };
    final maxGap = step == 10
        ? 9
        : step == 100
            ? 49
            : 499;

    int differentGap(int avoid) {
      var candidate = _between(2, maxGap);
      if (candidate == avoid) {
        candidate = candidate == maxGap ? 2 : candidate + 1;
      }
      return candidate;
    }

    final sourceGap =
        source != null && source.gap >= 2 && source.gap <= maxGap
            ? source.gap
            : null;
    final gap = switch (stage) {
      RemediationStage.supported => sourceGap ?? _between(2, maxGap),
      RemediationStage.transfer =>
        differentGap(sourceGap ?? _between(2, maxGap)),
      RemediationStage.check => _between(2, maxGap),
      _ => sourceGap ?? _between(2, maxGap),
    };

    final maxAnchorIndex =
        max(2, max(step * 2, limit - step) ~/ step);
    final anchor = _between(2, maxAnchorIndex) * step;
    final a = anchor - gap;
    final restMax = max(1, min(step, limit - anchor));
    final rest = _between(1, restMax);
    final b = gap + rest;

    final values = <int>{gap};
    for (final offset in [1, -1, 2, -2, 5, -5]) {
      final candidate = gap + offset;
      if (candidate >= 1 && candidate <= maxGap) values.add(candidate);
      if (values.length >= 4) break;
    }
    var filler = 1;
    while (values.length < 4) {
      if (filler <= maxGap) values.add(filler);
      filler += 1;
    }
    final choices = values.take(4).map((value) => '$value').toList()
      ..shuffle(_random);

    final prompt = stage == RemediationStage.transfer
        ? '$a + $b soll zuerst den glatten $label $anchor erreichen. Wie viel vom zweiten Summanden brauchst du für diesen ersten Schritt?'
        : 'Von $a bis zum glatten $label $anchor: Wie viel fehlt?';

    return _choice(
      focus: focus,
      stage: stage,
      key: 'strategy-gap:$label:$a:$b:$anchor',
      prompt: prompt,
      choices: choices,
      answer: choices.indexOf('$gap'),
      hint:
          'Ergänze nur vom ersten Summanden bis zur glatten Zielzahl. Den Rest des zweiten Summanden brauchst du erst danach.',
    );
  }

  ({int step, int gap})? _strategyGapSource(String sourceTaskKey) {
    final parts = sourceTaskKey.split(':');
    final index = parts.indexOf('strategy');
    if (index < 0 || index + 4 >= parts.length) return null;
    final label = parts[index + 1];
    final a = int.tryParse(parts[index + 2]);
    final anchor = int.tryParse(parts[index + 4]);
    if (a == null || anchor == null || anchor <= a) return null;
    final step = switch (label) {
      'Zehner' => 10,
      'Hunderter' => 100,
      'Tausender' => 1000,
      _ => 0,
    };
    if (step == 0) return null;
    return (step: step, gap: anchor - a);
  }

  RemediationTask _placeValueContributionStep(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final upper = max(999, min(range.maxValue, 999999));
    final sourcePlace = _placeValueContributionSourcePlace(
      focus.sourceTaskKey,
    );
    final places = <int>[];
    for (var place = 10; place * 10 <= upper; place *= 10) {
      places.add(place);
    }
    if (places.isEmpty) places.add(10);

    final validSource =
        sourcePlace != null && places.contains(sourcePlace) ? sourcePlace : null;
    final place = switch (stage) {
      RemediationStage.supported => validSource ?? places.first,
      RemediationStage.transfer =>
        places.firstWhere(
          (value) => value != validSource,
          orElse: () => places.last,
        ),
      RemediationStage.check => places[_random.nextInt(places.length)],
      _ => validSource ?? places.first,
    };

    final digit = _between(2, 9);
    final suffix = _between(1, max(1, place - 1));
    final number = digit * place + suffix;
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
    final label = _largePlaceLabelForRecovery(place);

    return _choice(
      focus: focus,
      stage: stage,
      key: 'place-value-contribution:$place:$number',
      prompt:
          'In ${_formatLargeNumber(number)} steht die Ziffer $digit an der $label. Welchen Wert trägt sie zur Zahl bei?',
      choices: choices,
      answer: choices.indexOf('$contribution'),
      hint:
          'Die Ziffer allein reicht nicht. Multipliziere sie gedanklich mit dem Wert ihrer Stelle.',
    );
  }

  int? _placeValueContributionSourcePlace(String sourceTaskKey) {
    final parts = sourceTaskKey.split(':');
    final index = parts.indexOf('decompose');
    if (index < 0 || index + 2 >= parts.length) return null;
    return int.tryParse(parts[index + 2]);
  }

  RemediationTask _numberWordTensOnesStep(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
  ) {
    final sourceNumbers = RegExp(r'\d+')
        .allMatches(focus.sourceTaskKey)
        .map((match) => int.parse(match.group(0)!))
        .toList();
    final sourceNumber =
        sourceNumbers.isEmpty ? null : sourceNumbers.last;
    final sourceSuffix = sourceNumber == null ? null : sourceNumber % 100;
    final sourceTens = sourceSuffix == null ? null : sourceSuffix ~/ 10;
    final sourceOnes = sourceSuffix == null ? null : sourceSuffix % 10;
    final validSource = sourceTens != null &&
            sourceOnes != null &&
            sourceTens >= 2 &&
            sourceOnes > 0 &&
            sourceTens != sourceOnes
        ? sourceSuffix
        : null;

    int freshSuffix({int? avoid}) {
      var tens = _between(2, 9);
      var ones = _between(1, 9);
      var suffix = tens * 10 + ones;
      for (var attempt = 0;
          attempt < 30 && (suffix == avoid || tens == ones);
          attempt++) {
        tens = _between(2, 9);
        ones = _between(1, 9);
        suffix = tens * 10 + ones;
      }
      if (tens == ones) {
        ones = ones == 9 ? 1 : ones + 1;
        suffix = tens * 10 + ones;
      }
      return suffix;
    }

    final suffix = switch (stage) {
      RemediationStage.supported => validSource ?? freshSuffix(),
      RemediationStage.transfer => freshSuffix(avoid: validSource),
      RemediationStage.check => freshSuffix(),
      _ => validSource ?? freshSuffix(),
    };
    final tens = suffix ~/ 10;
    final ones = suffix % 10;
    final word = GermanNumberWords.spell(suffix);
    final correct = '$tens Zehner und $ones Einer';
    final choices = <String>{
      correct,
      '$ones Zehner und $tens Einer',
      '$tens Zehner und $tens Einer',
      '$ones Zehner und $ones Einer',
    }.toList()
      ..shuffle(_random);

    return _choice(
      focus: focus,
      stage: stage,
      key: 'number-word-tens-ones:$suffix',
      prompt:
          'Im Wortteil „$word“: Welche Zuordnung zu Zehnern und Einern ist richtig?',
      choices: choices,
      answer: choices.indexOf(correct),
      hint:
          'Bei deutschen Zahlwörtern wie „siebenundvierzig“ wird der Einer vor dem Zehner gesprochen.',
    );
  }

  RemediationTask _largeNumberSmallestStep(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    var upper = max(99, min(range.maxValue, 999999));
    if (_isLargePowerOfTen(upper)) upper -= 1;

    var highestPlace = 1;
    while (highestPlace * 10 <= upper) {
      highestPlace *= 10;
    }
    final availablePlaces = <int>[];
    for (var place = highestPlace ~/ 10; place >= 1; place ~/= 10) {
      availablePlaces.add(place);
      if (place == 1) break;
    }

    final sourceNumbers = RegExp(r'\d+')
        .allMatches(focus.sourceTaskKey.split('order:').last)
        .map((match) => int.parse(match.group(0)!))
        .toList()
      ..sort();
    final sourcePlace = sourceNumbers.length >= 2
        ? _firstDifferentLargePlace(sourceNumbers[0], sourceNumbers[1])
        : availablePlaces.first;
    final supportedPlace = availablePlaces.contains(sourcePlace)
        ? sourcePlace
        : availablePlaces.first;
    final transferPlaces =
        availablePlaces.where((place) => place != supportedPlace).toList();
    final decidingPlace = switch (stage) {
      RemediationStage.supported => supportedPlace,
      RemediationStage.transfer => transferPlaces.isEmpty
          ? supportedPlace
          : transferPlaces[_random.nextInt(transferPlaces.length)],
      RemediationStage.check =>
        availablePlaces[_random.nextInt(availablePlaces.length)],
      _ => supportedPlace,
    };

    var pair = _largeComparisonPair(
      decidingPlace: decidingPlace,
      highestPlace: highestPlace,
      upper: upper,
    );
    var orderedPair = <int>[pair.$1, pair.$2]..sort();
    for (var attempt = 0;
        attempt < 30 && orderedPair.first >= upper - 1;
        attempt++) {
      pair = _largeComparisonPair(
        decidingPlace: decidingPlace,
        highestPlace: highestPlace,
        upper: upper,
      );
      orderedPair = <int>[pair.$1, pair.$2]..sort();
    }

    var third = _between(
      min(upper, orderedPair.first + 1),
      upper,
    );
    for (var attempt = 0;
        attempt < 30 &&
            (third == orderedPair.first || third == orderedPair.last);
        attempt++) {
      third = _between(
        min(upper, orderedPair.first + 1),
        upper,
      );
    }
    if (third == orderedPair.first || third == orderedPair.last) {
      third = orderedPair.first > 1
          ? orderedPair.first - 1
          : min(upper, orderedPair.last + 1);
    }

    final values = <int>{
      orderedPair.first,
      orderedPair.last,
      third,
    }.toList();
    if (values.length < 3) {
      var candidate = 1;
      while (values.length < 3 && candidate <= upper) {
        if (!values.contains(candidate)) values.add(candidate);
        candidate += 1;
      }
    }
    values.shuffle(_random);
    final smallest = values.reduce(min);
    final choices = values.map((value) => _formatLargeNumber(value)).toList();

    return _choice(
      focus: focus,
      stage: stage,
      key:
          'large-smallest:$decidingPlace:${values.join('-')}',
      prompt:
          'Welche dieser drei Zahlen ist die kleinste?',
      choices: choices,
      answer: values.indexOf(smallest),
      hint:
          'Vergleiche von links nach rechts. Suche nur die kleinste Zahl; die vollständige Reihenfolge kommt erst danach.',
    );
  }

  RemediationTask _largeNumberDecidingPlaceStep(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    var upper = max(99, min(range.maxValue, 999999));
    if (_isLargePowerOfTen(upper)) upper -= 1;

    var highestPlace = 1;
    while (highestPlace * 10 <= upper) {
      highestPlace *= 10;
    }
    final availablePlaces = <int>[];
    for (var place = highestPlace ~/ 10; place >= 1; place ~/= 10) {
      availablePlaces.add(place);
      if (place == 1) break;
    }

    final parts = focus.sourceTaskKey.split(':');
    final largeIndex = parts.indexOf('large');
    final sourceA = largeIndex >= 0 && largeIndex + 3 < parts.length
        ? int.tryParse(parts[largeIndex + 2])
        : null;
    final sourceB = largeIndex >= 0 && largeIndex + 3 < parts.length
        ? int.tryParse(parts[largeIndex + 3])
        : null;
    final sourcePlace = sourceA == null || sourceB == null
        ? availablePlaces.first
        : _firstDifferentLargePlace(sourceA, sourceB);
    final supportedPlace = availablePlaces.contains(sourcePlace)
        ? sourcePlace
        : availablePlaces.first;
    final transferPlaces =
        availablePlaces.where((place) => place != supportedPlace).toList();
    final decidingPlace = switch (stage) {
      RemediationStage.supported => supportedPlace,
      RemediationStage.transfer => transferPlaces.isEmpty
          ? supportedPlace
          : transferPlaces[_random.nextInt(transferPlaces.length)],
      RemediationStage.check =>
        availablePlaces[_random.nextInt(availablePlaces.length)],
      _ => supportedPlace,
    };

    final pair = _largeComparisonPair(
      decidingPlace: decidingPlace,
      highestPlace: highestPlace,
      upper: upper,
    );
    final choices = _largePlaceChoicesForRecovery(highestPlace);
    final label = _largePlaceLabelForRecovery(decidingPlace);

    return _choice(
      focus: focus,
      stage: stage,
      key:
          'large-deciding-place:$decidingPlace:${pair.$1}:${pair.$2}',
      prompt:
          '${_formatLargeNumber(pair.$1)} und ${_formatLargeNumber(pair.$2)}: Welche Stelle entscheidet beim Vergleich zuerst?',
      choices: choices,
      answer: choices.indexOf(label),
      hint:
          'Vergleiche von links nach rechts. Gleiche Ziffern überspringst du, bis sich zwei Ziffern unterscheiden.',
    );
  }

  (int, int) _largeComparisonPair({
    required int decidingPlace,
    required int highestPlace,
    required int upper,
  }) {
    final block = decidingPlace * 10;
    final minPrefix = max(1, highestPlace ~/ block);
    final maxPrefix = upper ~/ block;
    final prefix = _between(minPrefix, max(minPrefix, maxPrefix));
    final firstDigit = _between(0, 9);
    var secondDigit = _between(0, 8);
    if (secondDigit >= firstDigit) secondDigit += 1;
    final suffixA =
        decidingPlace == 1 ? 0 : _between(0, decidingPlace - 1);
    final suffixB =
        decidingPlace == 1 ? 0 : _between(0, decidingPlace - 1);
    return (
      prefix * block + firstDigit * decidingPlace + suffixA,
      prefix * block + secondDigit * decidingPlace + suffixB,
    );
  }

  int _firstDifferentLargePlace(int a, int b) {
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

  List<String> _largePlaceChoicesForRecovery(int highestPlace) {
    final choices = <String>[];
    for (var place = highestPlace; place >= 1; place ~/= 10) {
      choices.add(_largePlaceLabelForRecovery(place));
      if (place == 1) break;
    }
    return choices;
  }

  String _largePlaceLabelForRecovery(int place) => switch (place) {
        100000 => 'Hunderttausenderstelle',
        10000 => 'Zehntausenderstelle',
        1000 => 'Tausenderstelle',
        100 => 'Hunderterstelle',
        10 => 'Zehnerstelle',
        _ => 'Einerstelle',
      };

  bool _isLargePowerOfTen(int value) {
    if (value < 10) return false;
    var current = value;
    while (current % 10 == 0) {
      current ~/= 10;
    }
    return current == 1;
  }

  String _formatLargeNumber(int value) {
    final raw = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buffer.write('.');
      buffer.write(raw[i]);
    }
    return buffer.toString();
  }

  RemediationTask _fractionEqualPartSizeStep(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    const denominators = [2, 4];
    final parts = focus.sourceTaskKey.split(':');
    final fractionIndex = parts.indexOf('fraction');
    final sourceDenominator = fractionIndex >= 0 &&
            fractionIndex + 3 < parts.length &&
            parts[fractionIndex + 1] == 'parts'
        ? int.tryParse(parts[fractionIndex + 3])
        : null;
    final validSourceDenominator =
        denominators.contains(sourceDenominator) ? sourceDenominator! : 4;
    final transferDenominators = denominators
        .where((value) => value != validSourceDenominator)
        .toList();
    final denominator = switch (stage) {
      RemediationStage.supported => validSourceDenominator,
      RemediationStage.transfer =>
        transferDenominators[_random.nextInt(transferDenominators.length)],
      RemediationStage.check =>
        denominators[_random.nextInt(denominators.length)],
      _ => validSourceDenominator,
    };
    final limit = max(20, min(range.maxValue, 100));
    final maxPart = max(2, min(20, limit ~/ denominator));
    final partSize = _between(2, maxPart);
    final whole = partSize * denominator;
    final family = switch (stage) {
      RemediationStage.supported => 'plaettchen',
      RemediationStage.transfer => 'band',
      RemediationStage.check => _random.nextBool() ? 'wuerfel' : 'plaettchen',
      _ => 'plaettchen',
    };
    final prompt = switch (family) {
      'band' =>
        'Ein $whole cm langes Band wird in $denominator gleich lange Teile geteilt. Wie lang ist genau 1 Teil?',
      'wuerfel' =>
        '$whole Würfel werden in $denominator gleich große Mengen aufgeteilt. Wie viele Würfel gehören zu genau 1 Teil?',
      _ =>
        'Ein Ganzes aus $whole Plättchen wird in $denominator gleich große Teile geteilt. Wie viele Plättchen gehören zu genau 1 Teil?',
    };

    return _numeric(
      focus: focus,
      stage: stage,
      key: 'equal-part:$family:$denominator:$whole',
      prompt: prompt,
      answer: partSize,
      max: maxPart,
      hint:
          'Alle Teile müssen gleich groß sein. Teile das Ganze $whole durch $denominator.',
    );
  }

  RemediationTask _timeDurationFirstJump(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
  ) {
    const minuteOptions = [10, 15, 20, 25, 30, 35, 40, 45, 50];
    final parts = focus.sourceTaskKey.split(':');
    final durationIndex = parts.indexOf('duration');
    final sourceStart = durationIndex >= 0 &&
            durationIndex + 1 < parts.length
        ? int.tryParse(parts[durationIndex + 1])
        : null;
    final sourceMinute = sourceStart == null ? null : sourceStart % 60;
    final validSourceMinute =
        sourceMinute != null && sourceMinute > 0 && sourceMinute < 60
            ? sourceMinute
            : 30;
    final transferMinutes = minuteOptions
        .where((value) => value != validSourceMinute)
        .toList();
    final minute = switch (stage) {
      RemediationStage.supported => validSourceMinute,
      RemediationStage.transfer =>
        transferMinutes[_random.nextInt(transferMinutes.length)],
      RemediationStage.check =>
        minuteOptions[_random.nextInt(minuteOptions.length)],
      _ => validSourceMinute,
    };
    final hour = _between(8, 16);
    final start = hour * 60 + minute;
    final nextFullHour = (hour + 1) * 60;
    final answer = 60 - minute;

    String clock(int value) {
      final h = (value ~/ 60) % 24;
      final m = value % 60;
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }

    return _numeric(
      focus: focus,
      stage: stage,
      key: 'time-first-jump:$start:$nextFullHour',
      prompt:
          'Beginn: ${clock(start)} Uhr. Wie viele Minuten sind es bis ${clock(nextFullHour)} Uhr?',
      answer: answer,
      max: 60,
      hint:
          'Zähle nur den ersten Zeitabschnitt bis zur nächsten vollen Stunde.',
    );
  }

  RemediationTask _proportionalUnitValueStep(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    const families = ['notebooks', 'tickets', 'packs', 'ribbon'];
    final parts = focus.sourceTaskKey.split(':');
    final proportionIndex = parts.indexOf('proportion');
    final sourceFamily =
        proportionIndex >= 0 && proportionIndex + 1 < parts.length
            ? parts[proportionIndex + 1]
            : 'notebooks';
    final alternatives =
        families.where((family) => family != sourceFamily).toList();
    final family = switch (stage) {
      RemediationStage.supported =>
        families.contains(sourceFamily) ? sourceFamily : 'notebooks',
      RemediationStage.transfer =>
        alternatives[_random.nextInt(alternatives.length)],
      RemediationStage.check => families[_random.nextInt(families.length)],
      _ => families.contains(sourceFamily) ? sourceFamily : 'notebooks',
    };
    final limit = max(12, min(range.maxValue, 100));
    final unitValue = _between(2, min(12, limit));
    final firstAmount = _between(2, 5);
    final total = unitValue * firstAmount;
    final subject = switch (family) {
      'tickets' => '$firstAmount Eintrittskarten kosten zusammen $total €.',
      'packs' => '$firstAmount gleiche Packungen kosten zusammen $total €.',
      'ribbon' => '$firstAmount Meter Band kosten zusammen $total €.',
      _ => '$firstAmount Hefte kosten zusammen $total €.',
    };

    return _numeric(
      focus: focus,
      stage: stage,
      key: 'unit-value:$family:$unitValue:$firstAmount',
      prompt: '$subject Was kostet genau 1 Einheit?',
      answer: unitValue,
      max: 12,
      hint:
          'Teile den Gesamtpreis $total durch die bekannte Anzahl $firstAmount.',
    );
  }

  RemediationTask _storyInfoStep(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final limit = max(10, min(range.maxValue, 100));
    final first = _between(2, min(8, max(2, limit - 2)));
    final second = _between(1, min(6, max(1, limit - first)));
    final distractor = _between(1, min(9, limit));
    final correct = '$first und $second Kinder';
    final choices = <String>[
      correct,
      '$first Kinder und $distractor Seiten',
      '$second Kinder und $distractor Seiten',
      'Nur die $distractor Seiten',
    ]..shuffle(_random);
    return _choice(
      focus: focus,
      stage: stage,
      key: 'story-info:$first:$second:$distractor',
      prompt:
          'In zwei Gruppen spielen $first und $second Kinder. Ein Buch daneben hat $distractor Seiten. Welche Angaben brauchst du, um zu bestimmen, wie viele Kinder zusammen spielen?',
      choices: choices,
      answer: choices.indexOf(correct),
      hint:
          'Prüfe jede Zahl daran, ob sie zur Frage nach den Kindern gehört.',
    );
  }

  RemediationTask _storyOperationStep(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final operation = _storyOperationFromSource(focus.sourceTaskKey);
    final limit = max(10, min(range.maxValue, 100));
    final a = _between(2, min(9, limit));
    final b = _between(1, min(6, max(1, limit - a)));
    final groups = _between(2, min(5, max(2, limit ~/ 2)));
    final each = _between(2, min(6, max(2, limit ~/ groups)));
    final total = groups * each;
    final (prompt, correct, rawChoices) = switch (operation) {
      'x' => (
          '$groups Schachteln enthalten jeweils $each Stifte. Welche Rechenart passt für die Gesamtzahl?',
          'Mal (×)',
          <String>['Plus (+)', 'Minus (−)', 'Mal (×)', 'Geteilt (÷)'],
        ),
      'divide' => (
          '$total Karten werden gleichmäßig auf $groups Kinder verteilt. Welche Rechenart passt für den Anteil pro Kind?',
          'Geteilt (÷)',
          <String>['Plus (+)', 'Minus (−)', 'Mal (×)', 'Geteilt (÷)'],
        ),
      '-' => (
          'In einer Kiste liegen $a Bausteine. $b werden herausgenommen. Welche Rechenart passt?',
          'Minus (−)',
          <String>['Plus (+)', 'Minus (−)'],
        ),
      _ => (
          'In einer Kiste liegen $a Bausteine. $b kommen dazu. Welche Rechenart passt?',
          'Plus (+)',
          <String>['Plus (+)', 'Minus (−)'],
        ),
    };
    final choices = [...rawChoices]..shuffle(_random);
    return _choice(
      focus: focus,
      stage: stage,
      key: 'story-operation:$operation:$a:$b:$groups:$each',
      prompt: prompt,
      choices: choices,
      answer: choices.indexOf(correct),
      hint:
          'Entscheide nach der Handlung: mehr, weniger, gleich große Gruppen oder gleichmäßig verteilen.',
    );
  }

  RemediationTask _storyEquationStep(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final operation = _storyOperationFromSource(focus.sourceTaskKey);
    final limit = max(10, min(range.maxValue, 100));
    final a = _between(2, min(9, limit));
    final b = _between(1, min(6, max(1, limit - a)));
    final groups = _between(2, min(5, max(2, limit ~/ 2)));
    final each = _between(2, min(6, max(2, limit ~/ groups)));
    final total = groups * each;
    final (prompt, correct, rawChoices) = switch (operation) {
      'x' => (
          '$groups Reihen haben jeweils $each Stühle. Welche Rechnung beschreibt die Gesamtzahl?',
          '$groups × $each',
          <String>[
            '$groups × $each',
            '$groups + $each',
            '$groups − $each',
            '$each ÷ $groups',
          ],
        ),
      'divide' => (
          '$total Stifte werden gleichmäßig auf $groups Schachteln verteilt. Welche Rechnung beschreibt die Anzahl pro Schachtel?',
          '$total ÷ $groups',
          <String>[
            '$total ÷ $groups',
            '$total − $groups',
            '$total + $groups',
            '$groups ÷ $total',
          ],
        ),
      '-' => (
          'In einer Schachtel sind $a Karten. $b werden weggenommen. Welche Rechnung beschreibt die Situation?',
          '$a − $b',
          <String>[
            '$a − $b',
            '$a + $b',
            '$b − $a',
            '$a × $b',
          ],
        ),
      _ => (
          'Auf dem Schulhof spielen $a Kinder. $b kommen dazu. Welche Rechnung beschreibt die Situation?',
          '$a + $b',
          <String>[
            '$a + $b',
            '$a − $b',
            '$a × $b',
            '$b − $a',
          ],
        ),
    };
    final choices = [...rawChoices]..shuffle(_random);
    return _choice(
      focus: focus,
      stage: stage,
      key: 'story-equation:$operation:$a:$b:$groups:$each',
      prompt: prompt,
      choices: choices,
      answer: choices.indexOf(correct),
      hint:
          'Ordne die wichtigen Zahlen so an, dass die Rechnung genau zur Handlung passt.',
    );
  }

  RemediationTask _storyCalculationStep(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final operation = _storyOperationFromSource(focus.sourceTaskKey);
    final limit = max(10, min(range.maxValue, 100));
    if (operation == 'x' || operation == 'divide') {
      final groups = _between(2, min(5, max(2, limit ~/ 2)));
      final each = _between(2, min(6, max(2, limit ~/ groups)));
      final total = groups * each;
      return _numeric(
        focus: focus,
        stage: stage,
        key: 'story-calc:$operation:$groups:$each',
        prompt: operation == 'x'
            ? 'Die passende Rechnung ist $groups × $each. Wie lautet das Ergebnis?'
            : 'Die passende Rechnung ist $total ÷ $groups. Wie lautet das Ergebnis?',
        answer: operation == 'x' ? total : each,
        max: limit,
        hint:
            'Die Sachlage ist schon modelliert. Rechne jetzt nur die angegebene Rechnung aus.',
      );
    }

    final a = operation == '-'
        ? _between(2, min(12, limit))
        : _between(1, max(1, min(12, limit - 1)));
    final b = operation == '-'
        ? _between(1, max(1, a - 1))
        : _between(1, max(1, min(9, limit - a)));
    return _numeric(
      focus: focus,
      stage: stage,
      key: 'story-calc:$operation:$a:$b',
      prompt: operation == '-'
          ? 'Die passende Rechnung ist $a − $b. Wie lautet das Ergebnis?'
          : 'Die passende Rechnung ist $a + $b. Wie lautet das Ergebnis?',
      answer: operation == '-' ? a - b : a + b,
      max: limit,
      hint:
          'Die Sachlage ist schon modelliert. Rechne jetzt nur die angegebene Rechnung aus.',
    );
  }

  RemediationTask _storyInterpretationStep(
    IndependentStepRecoveryFocus focus,
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final subtract = _storyOperationFromSource(focus.sourceTaskKey) == '-';
    final limit = max(10, min(range.maxValue, 100));
    final a = subtract
        ? _between(2, min(12, limit))
        : _between(1, max(1, min(12, limit - 1)));
    final b = subtract
        ? _between(1, max(1, a - 1))
        : _between(1, max(1, min(9, limit - a)));
    final result = subtract ? a - b : a + b;
    final correct = subtract
        ? 'Es bleiben $result Karten übrig.'
        : 'Mara hat jetzt $result Sticker.';
    final choices = subtract
        ? <String>[
            correct,
            'Es wurden $result Karten weggenommen.',
            'Am Anfang lagen $result Karten dort.',
            'Es kommen $result Karten dazu.',
          ]
        : <String>[
            correct,
            'Mara hat $result Sticker abgegeben.',
            'Es kommen noch $result Sticker dazu.',
            'Im Raum sind $result Kinder.',
          ];
    choices.shuffle(_random);
    return _choice(
      focus: focus,
      stage: stage,
      key: 'story-interpret:${subtract ? '-' : '+'}:$a:$b:$result',
      prompt: subtract
          ? 'Auf dem Tisch liegen $a Karten. $b werden weggenommen. $a − $b = $result. Welche Antwort passt zur Situation?'
          : 'Mara hat $a Sticker und bekommt $b dazu. $a + $b = $result. Welche Antwort passt zur Situation?',
      choices: choices,
      answer: choices.indexOf(correct),
      hint:
          'Verbinde die Ergebniszahl wieder mit der Frage und dem Gegenstand der Geschichte.',
    );
  }

  String _storyOperationFromSource(String sourceTaskKey) {
    if (sourceTaskKey.contains(':divide:')) return 'divide';
    if (sourceTaskKey.contains(':x:')) return 'x';
    if (sourceTaskKey.contains(':-:')) return '-';
    return '+';
  }

  RemediationTask _numeric({
    required IndependentStepRecoveryFocus focus,
    required RemediationStage stage,
    required String key,
    required String prompt,
    required int answer,
    required int max,
    required String hint,
  }) =>
      RemediationTask(
        stage: stage,
        mode: focus.mode,
        taskKey: 'step-recovery:${focus.stepKey}:$key',
        prompt: prompt,
        answer: answer,
        maxAnswerValue: max,
        hint: hint,
      );

  RemediationTask _choice({
    required IndependentStepRecoveryFocus focus,
    required RemediationStage stage,
    required String key,
    required String prompt,
    required List<String> choices,
    required int answer,
    required String hint,
  }) =>
      RemediationTask(
        stage: stage,
        mode: focus.mode,
        taskKey: 'step-recovery:${focus.stepKey}:$key',
        prompt: prompt,
        answer: answer,
        maxAnswerValue: choices.length - 1,
        hint: hint,
        choices: choices,
      );

  int _between(int low, int high) =>
      high <= low ? low : low + _random.nextInt(high - low + 1);
}

class RemediationGenerator {
  RemediationGenerator({Random? random})
      : _random = random ?? Random(),
        _structured = StructuredExerciseGenerator(
          random: random == null ? Random() : Random(random.nextInt(1 << 31)),
        ),
        _curriculum = CurriculumExerciseGenerator(
          random: random == null ? Random() : Random(random.nextInt(1 << 31)),
        );

  final Random _random;
  final StructuredExerciseGenerator _structured;
  final CurriculumExerciseGenerator _curriculum;

  RemediationPlan generate({
    required ErrorPattern pattern,
    required TrainingMode preferredMode,
    required GradeLevel grade,
    required NumberRangeLevel range,
    required MethodPreferences methods,
    bool reviewOnly = false,
  }) {
    final tasks = <RemediationTask>[];
    final usedKeys = <String>{};
    final stages = reviewOnly
        ? const [RemediationStage.check]
        : RemediationStage.values;
    for (final stage in stages) {
      for (var i = 0; i < 2; i++) {
        RemediationTask? chosen;
        for (var attempt = 0; attempt < 24; attempt++) {
          final candidate = _task(
            pattern: pattern,
            stage: stage,
            preferredMode: preferredMode,
            grade: grade,
            range: range,
            methods: methods,
          );
          chosen ??= candidate;
          if (usedKeys.add(candidate.taskKey)) {
            chosen = candidate;
            break;
          }
        }
        tasks.add(chosen!);
      }
    }
    return RemediationPlan(
      pattern: pattern,
      mode: preferredMode,
      tasks: tasks,
    );
  }

  RemediationTask _task({
    required ErrorPattern pattern,
    required RemediationStage stage,
    required TrainingMode preferredMode,
    required GradeLevel grade,
    required NumberRangeLevel range,
    required MethodPreferences methods,
  }) =>
      switch (pattern) {
        ErrorPattern.tenBridge ||
        ErrorPattern.carryOmitted ||
        ErrorPattern.borrowAvoided =>
          _tenBridge(
            stage,
            preferredMode,
            range,
            methods,
            pattern,
          ),
        ErrorPattern.partialOperand =>
          _partialOperand(stage, preferredMode, range),
        ErrorPattern.numberBond => _numberBond(stage, range),
        ErrorPattern.countingStep => _countingStep(stage, range),
        ErrorPattern.operationChoice =>
          _operationChoice(stage, range, grade),
        ErrorPattern.placeValue => _placeValue(stage, range),
        ErrorPattern.multiplicationFact ||
        ErrorPattern.multiplicationAsAddition =>
          _multiplication(stage, methods.multiplication, pattern),
        ErrorPattern.divisionFact ||
        ErrorPattern.divisionAsSubtraction =>
          _division(stage, pattern),
        ErrorPattern.inverseOperation => _inverse(stage, range),
        ErrorPattern.wordProblem => _wordProblem(stage, grade, range),
        ErrorPattern.wordProblemRelevantInformation =>
          _targetedWordProblem(
            stage,
            grade,
            range,
            pattern,
            MicroCompetencyId.wordProblemRelevantInformation,
          ),
        ErrorPattern.wordProblemModel =>
          _targetedWordProblem(
            stage,
            grade,
            range,
            pattern,
            MicroCompetencyId.wordProblemModel,
          ),
        ErrorPattern.wordProblemInterpretation =>
          _targetedWordProblem(
            stage,
            grade,
            range,
            pattern,
            MicroCompetencyId.wordProblemInterpretation,
          ),
        ErrorPattern.representationTranslation =>
          _targetedWordProblem(
            stage,
            grade,
            range,
            pattern,
            MicroCompetencyId.representationTranslation,
          ),
        ErrorPattern.unitConversion => _unitConversion(stage, grade),
        ErrorPattern.roundingPlace => _rounding(stage, range),
        ErrorPattern.writtenRegrouping =>
          _writtenRegrouping(stage, range, methods.writtenSubtraction),
        ErrorPattern.fractionPart => _fraction(stage),
        ErrorPattern.timeDuration => _timeDuration(stage),
        ErrorPattern.perimeterArea => _perimeterArea(stage),
        _ => _fallback(
            pattern: pattern,
            stage: stage,
            preferredMode: preferredMode,
            grade: grade,
            range: range,
          ),
      };

  RemediationTask _tenBridge(
    RemediationStage stage,
    TrainingMode preferredMode,
    NumberRangeLevel range,
    MethodPreferences methods,
    ErrorPattern pattern,
  ) {
    final limit = min(range.maxValue, 100);
    if (limit <= 10) {
      return _numberBond(stage, range);
    }

    final subtraction = pattern == ErrorPattern.borrowAvoided ||
        (pattern != ErrorPattern.carryOmitted &&
            (preferredMode == TrainingMode.minus ||
                (preferredMode == TrainingMode.practice &&
                    _random.nextBool())));

    if (subtraction) {
      final decade = _between(1, max(1, limit ~/ 10 - 1)) * 10;
      final ones = _between(1, min(8, max(1, limit - decade)));
      final a = decade + ones;
      final b = _between(ones + 1, min(a, ones + 9));
      final answer = a - b;
      final bridge = a - ones;
      final rest = b - ones;
      final methodHint = switch (methods.subtraction) {
        SubtractionStrategy.bridgeToTen =>
          '$a − $ones = $bridge, dann $bridge − $rest = $answer.',
        SubtractionStrategy.takeAway =>
          'Zerlege $b in $ones und $rest und nimm beide Teile nacheinander weg.',
        SubtractionStrategy.complement =>
          'Starte bei $b und ergänze in passenden Schritten bis $a.',
      };
      return _numeric(
        stage: stage,
        mode: TrainingMode.minus,
        key: 'remediation:${pattern.name}:-:$a:$b',
        prompt: '$a − $b = ?',
        answer: answer,
        max: limit,
        hint: '${methods.subtraction.label}: $methodHint',
      );
    }

    var a = 2;
    var needed = 8;
    for (var attempt = 0; attempt < 40; attempt++) {
      final candidate = _between(2, min(49, max(2, limit - 1)));
      final candidateNeeded = 10 - (candidate % 10);
      if (candidate % 10 == 0 ||
          candidateNeeded > 9 ||
          candidate + candidateNeeded > limit) {
        continue;
      }
      a = candidate;
      needed = candidateNeeded;
      break;
    }
    final b = _between(needed, min(9, limit - a));
    return _numeric(
      stage: stage,
      mode: TrainingMode.practice,
      key: 'remediation:${pattern.name}:+:$a:$b',
      prompt: '$a + $b = ?',
      answer: a + b,
      max: limit,
      hint:
          'Ergänze zuerst bis zum nächsten Zehner und rechne danach den Rest weiter.',
    );
  }

  RemediationTask _partialOperand(
    RemediationStage stage,
    TrainingMode preferredMode,
    NumberRangeLevel range,
  ) {
    final limit = min(range.maxValue, 100);
    if (limit < 20) {
      return _numberBond(stage, range);
    }
    final subtraction = preferredMode == TrainingMode.minus ||
        (preferredMode != TrainingMode.practice && _random.nextBool());
    final tens = _between(1, max(1, limit ~/ 10 - 1)) * 10;
    final ones = _between(1, 9);
    final b = tens + ones;

    if (subtraction) {
      final a = _between(b, limit);
      return _numeric(
        stage: stage,
        mode: TrainingMode.minus,
        key: 'remediation:partialOperand:-:$a:$b',
        prompt: '$a − $b = ?',
        answer: a - b,
        max: limit,
        hint:
            'Zerlege $b in $tens und $ones. Ziehe beide Teile nacheinander ab.',
      );
    }

    final maxA = max(1, limit - b);
    final a = _between(1, maxA);
    return _numeric(
      stage: stage,
      mode: TrainingMode.practice,
      key: 'remediation:partialOperand:+:$a:$b',
      prompt: '$a + $b = ?',
      answer: a + b,
      max: limit,
      hint:
          'Zerlege $b in $tens und $ones. Addiere beide Teile nacheinander.',
    );
  }

  RemediationTask _numberBond(
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final target = range.maxValue <= 10 ? 10 : 20;
    final a = _between(0, target);
    return _numeric(
      stage: stage,
      mode: TrainingMode.numberFriends,
      key: 'remediation:numberBond:$a:$target',
      prompt: '$a + ? = $target',
      answer: target - a,
      max: target,
      hint: 'Stelle dir $target als Ganzes vor. Welcher Teil fehlt noch?',
    );
  }

  RemediationTask _countingStep(
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final limit = max(10, min(range.maxValue, 1000));
    final value = _between(2, limit - 2);
    final forward = _random.nextBool();
    return _numeric(
      stage: stage,
      mode: TrainingMode.neighbors,
      key: 'remediation:count:${forward ? '+' : '-'}:$value',
      prompt: forward
          ? 'Welche Zahl kommt direkt nach $value?'
          : 'Welche Zahl kommt direkt vor $value?',
      answer: forward ? value + 1 : value - 1,
      max: limit,
      hint: forward
          ? 'Gehe genau einen Schritt weiter.'
          : 'Gehe genau einen Schritt zurück.',
    );
  }

  RemediationTask _operationChoice(
    RemediationStage stage,
    NumberRangeLevel range,
    GradeLevel grade,
  ) {
    final limit = min(range.maxValue, 100);
    final a = _between(5, max(5, limit ~/ 2));
    final b = _between(1, min(a - 1, 9));
    final plus = _random.nextBool();
    final choices = grade == GradeLevel.first
        ? const ['Plus (+)', 'Minus (−)']
        : const ['Plus (+)', 'Minus (−)', 'Mal (×)', 'Geteilt (÷)'];
    return RemediationTask(
      stage: stage,
      mode: TrainingMode.mixed,
      taskKey: 'remediation:operation:${plus ? '+' : '-'}:$a:$b',
      prompt: plus
          ? 'Eine Menge von $a wird um $b größer. Welche Rechenart passt?'
          : 'Von $a werden $b weggenommen. Welche Rechenart passt?',
      answer: plus ? 0 : 1,
      maxAnswerValue: choices.length - 1,
      choices: choices,
      hint:
          'Achte zuerst auf die Handlung: größer/dazukommen oder kleiner/wegnehmen.',
    );
  }

  RemediationTask _placeValue(
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final limit = max(20, range.maxValue);
    final number = _between(limit >= 100 ? 100 : 10, limit);
    final places = [1, 10, 100, 1000, 10000, 100000]
        .where((value) => value <= limit)
        .toList();
    final place = places[_random.nextInt(places.length)];
    final digit = (number ~/ place) % 10;
    final label = switch (place) {
      1 => 'Einerstelle',
      10 => 'Zehnerstelle',
      100 => 'Hunderterstelle',
      1000 => 'Tausenderstelle',
      10000 => 'Zehntausenderstelle',
      _ => 'Hunderttausenderstelle',
    };
    return _numeric(
      stage: stage,
      mode: TrainingMode.placeValue,
      key: 'remediation:place:$number:$place',
      prompt: 'Welche Ziffer steht bei $number an der $label?',
      answer: digit,
      max: 9,
      hint:
          'Ordne die Zahl von rechts nach links in Einer, Zehner, Hunderter usw.',
    );
  }

  RemediationTask _multiplication(
    RemediationStage stage,
    MultiplicationStrategy strategy,
    ErrorPattern pattern,
  ) {
    final a = _between(2, 10);
    final b = _between(2, 10);
    final answer = a * b;
    final hint = switch (strategy) {
      MultiplicationStrategy.groups =>
        '$a Gruppen mit je $b ergeben zusammen $answer.',
      MultiplicationStrategy.decompose =>
        'Zerlege einen Faktor in zwei leichte Teile und addiere die Teilprodukte.',
      MultiplicationStrategy.neighborFacts =>
        'Nutze eine bekannte ×5- oder ×10-Aufgabe und gehe zur Nachbaraufgabe.',
    };
    return _numeric(
      stage: stage,
      mode: TrainingMode.multiply,
      key: 'remediation:${pattern.name}:x:$a:$b',
      prompt: '$a × $b = ?',
      answer: answer,
      max: 100,
      hint: '${strategy.label}: $hint',
    );
  }

  RemediationTask _division(
    RemediationStage stage,
    ErrorPattern pattern,
  ) {
    final divisor = _between(2, 10);
    final quotient = _between(2, 10);
    final dividend = divisor * quotient;
    return _numeric(
      stage: stage,
      mode: TrainingMode.divide,
      key: 'remediation:${pattern.name}:divide:$dividend:$divisor',
      prompt: '$dividend ÷ $divisor = ?',
      answer: quotient,
      max: 10,
      hint: 'Nutze die Umkehraufgabe: $divisor × ? = $dividend.',
    );
  }

  RemediationTask _inverse(
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final limit = min(range.maxValue, 100);
    final answer = _between(1, max(1, limit ~/ 2));
    final add = _between(1, max(1, limit - answer));
    return _numeric(
      stage: stage,
      mode: TrainingMode.missingNumber,
      key: 'remediation:inverse:$answer:$add',
      prompt: '? + $add = ${answer + add}',
      answer: answer,
      max: limit,
      hint:
          'Markiere die gesuchte Zahl und nutze die passende Umkehraufgabe.',
    );
  }

  RemediationTask _wordProblem(
    RemediationStage stage,
    GradeLevel grade,
    NumberRangeLevel range,
  ) {
    final limit = min(range.maxValue, grade.index < 2 ? 100 : 1000);
    final a = _between(5, max(5, min(200, limit ~/ 2)));
    final b = _between(2, max(2, min(a - 1, 50)));
    final minus = _random.nextBool();
    return _numeric(
      stage: stage,
      mode: TrainingMode.wordProblems,
      key: 'remediation:story:${minus ? '-' : '+'}:$a:$b',
      prompt: minus
          ? 'In einer Kiste liegen $a Bausteine. $b werden herausgenommen. Wie viele bleiben?'
          : 'In einer Kiste liegen $a Bausteine. $b kommen dazu. Wie viele sind es jetzt?',
      answer: minus ? a - b : a + b,
      max: limit,
      hint:
          'Sage zuerst: Wird die Menge größer oder kleiner? Wähle erst danach die Rechenart.',
    );
  }

  RemediationTask _targetedWordProblem(
    RemediationStage stage,
    GradeLevel grade,
    NumberRangeLevel range,
    ErrorPattern pattern,
    MicroCompetencyId competency,
  ) {
    final exerciseMaxValue =
        competency == MicroCompetencyId.representationTranslation
            ? range.maxValue
            : min(range.maxValue, 100);
    final exercise = _structured.generate(
      mode: TrainingMode.wordProblems,
      maxValue: exerciseMaxValue,
      gradeLevel: grade,
      targetCompetency: competency,
    );
    return RemediationTask(
      stage: stage,
      mode: TrainingMode.wordProblems,
      taskKey: 'remediation:${pattern.name}:${exercise.key}',
      prompt: exercise.prompt,
      answer: exercise.answer,
      maxAnswerValue:
          exercise.maxAnswerValue ?? exerciseMaxValue,
      choices: exercise.choices,
      answerSuffix: exercise.answerSuffix,
      hint: '${pattern.firstResponseHint} ${exercise.hint}',
    );
  }

  RemediationTask _unitConversion(
    RemediationStage stage,
    GradeLevel grade,
  ) {
    final kind = _random.nextInt(grade.index >= 2 ? 4 : 2);
    if (kind == 0) {
      final value = _between(1, 9);
      return _numeric(
        stage: stage,
        mode: TrainingMode.measures,
        key: 'remediation:unit:m-cm:$value',
        prompt: '$value m sind wie viele cm?',
        answer: value * 100,
        max: 900,
        suffix: 'cm',
        hint: '1 m = 100 cm. Multipliziere mit 100.',
      );
    }
    if (kind == 1) {
      final value = _between(1, 9);
      return _numeric(
        stage: stage,
        mode: TrainingMode.measures,
        key: 'remediation:unit:cm-mm:$value',
        prompt: '$value cm sind wie viele mm?',
        answer: value * 10,
        max: 90,
        suffix: 'mm',
        hint: '1 cm = 10 mm.',
      );
    }
    if (kind == 2) {
      final value = _between(1, 8);
      return _numeric(
        stage: stage,
        mode: TrainingMode.advancedMeasures,
        key: 'remediation:unit:kg-g:$value',
        prompt: '$value kg sind wie viele g?',
        answer: value * 1000,
        max: 8000,
        suffix: 'g',
        hint: '1 kg = 1000 g.',
      );
    }
    final value = _between(1, 8);
    return _numeric(
      stage: stage,
      mode: TrainingMode.advancedMeasures,
      key: 'remediation:unit:l-ml:$value',
      prompt: '$value l sind wie viele ml?',
      answer: value * 1000,
      max: 8000,
      suffix: 'ml',
      hint: '1 l = 1000 ml.',
    );
  }

  RemediationTask _rounding(
    RemediationStage stage,
    NumberRangeLevel range,
  ) {
    final limit = max(20, range.maxValue);
    final place = limit >= 1000 && _random.nextBool() ? 100 : 10;
    final number = _between(place, limit);
    final answer = ((number + place ~/ 2) ~/ place) * place;
    return _numeric(
      stage: stage,
      mode: TrainingMode.rounding,
      key: 'remediation:round:$number:$place',
      prompt:
          'Runde $number auf den nächsten ${place == 10 ? 'Zehner' : 'Hunderter'}.',
      answer: answer,
      max: max(limit, answer),
      hint:
          'Markiere die Rundungsstelle. Die Ziffer direkt rechts entscheidet: 0–4 ab, 5–9 auf.',
    );
  }

  RemediationTask _writtenRegrouping(
    RemediationStage stage,
    NumberRangeLevel range,
    WrittenSubtractionStrategy strategy,
  ) {
    final limit = max(20, range.maxValue);
    if (limit < 100) {
      final ones = _between(0, 4);
      final a = _between(10 + ones, limit);
      final bOnes = _between(ones + 1, min(9, a - 1));
      return _numeric(
        stage: stage,
        mode: TrainingMode.writtenAddSub,
        key: 'remediation:written:-:$a:$bOnes',
        prompt: 'Rechne schriftlich:\n$a\n− $bOnes',
        answer: a - bOnes,
        max: limit,
        hint: '${strategy.label}: ${strategy.description}',
      );
    }
    final hundreds = _between(2, max(2, min(9, limit ~/ 100)));
    final ones = _between(0, 4);
    final a = min(limit, hundreds * 100 + _between(0, 4) * 10 + ones);
    final bOnes = _between(ones + 1, 9);
    final b = min(
      a,
      _between(0, min(9, max(0, (a - bOnes) ~/ 10))) * 10 + bOnes,
    );
    return _numeric(
      stage: stage,
      mode: TrainingMode.writtenAddSub,
      key: 'remediation:written:-:$a:$b',
      prompt: 'Rechne schriftlich:\n$a\n− $b',
      answer: a - b,
      max: limit,
      hint: '${strategy.label}: ${strategy.description}',
    );
  }

  RemediationTask _fraction(RemediationStage stage) {
    final denominator = _random.nextBool() ? 2 : 4;
    final part = _between(2, 20);
    final whole = part * denominator;
    return _numeric(
      stage: stage,
      mode: TrainingMode.fractions,
      key: 'remediation:fraction:$denominator:$whole',
      prompt: 'Wie viel ist 1/$denominator von $whole?',
      answer: part,
      max: whole,
      hint:
          'Teile die ganze Menge zuerst in $denominator gleich große Teile.',
    );
  }

  RemediationTask _timeDuration(RemediationStage stage) {
    final start = _between(8, 15);
    final duration = [30, 45, 60, 90][_random.nextInt(4)];
    final endMinutes = start * 60 + duration;
    final endHour = endMinutes ~/ 60;
    final endMinute = endMinutes % 60;
    return _numeric(
      stage: stage,
      mode: TrainingMode.timeDurations,
      key: 'remediation:duration:$start:$duration',
      prompt:
          'Beginn: $start:00 Uhr\nEnde: $endHour:${endMinute.toString().padLeft(2, '0')} Uhr\nWie viele Minuten dauert es?',
      answer: duration,
      max: 120,
      suffix: 'min',
      hint:
          'Markiere Start und Ende auf einer Zeitlinie und rechne die Strecke in Etappen.',
    );
  }

  RemediationTask _perimeterArea(RemediationStage stage) {
    final width = _between(2, 12);
    final height = _between(2, 12);
    final area = _random.nextBool();
    return _numeric(
      stage: stage,
      mode: TrainingMode.perimeterArea,
      key: 'remediation:rect:$width:$height:$area',
      prompt: area
          ? 'Rechteck: $width cm lang und $height cm breit. Wie groß ist die Fläche?'
          : 'Rechteck: $width cm lang und $height cm breit. Wie groß ist der Umfang?',
      answer: area ? width * height : 2 * (width + height),
      max: 500,
      suffix: area ? 'cm²' : 'cm',
      hint: area
          ? 'Fläche ist das Innere: Länge × Breite.'
          : 'Umfang ist der Rand: alle vier Seiten addieren.',
    );
  }

  RemediationTask _fallback({
    required ErrorPattern pattern,
    required RemediationStage stage,
    required TrainingMode preferredMode,
    required GradeLevel grade,
    required NumberRangeLevel range,
  }) {
    if (preferredMode.isStructured) {
      final exercise = _structured.generate(
        mode: preferredMode,
        maxValue: min(range.maxValue, 100),
      );
      return RemediationTask(
        stage: stage,
        mode: preferredMode,
        taskKey: 'remediation:${pattern.name}:${exercise.key}',
        prompt: exercise.prompt,
        answer: exercise.answer,
        maxAnswerValue:
            exercise.maxAnswerValue ?? min(range.maxValue, 100),
        choices: exercise.choices,
        answerSuffix: exercise.answerSuffix,
        hint: '${pattern.action} ${exercise.hint}',
      );
    }
    if (preferredMode.isUpperPrimary) {
      final exercise = _curriculum.generate(
        mode: preferredMode,
        gradeLevel: grade,
        maxValue: range.maxValue,
      );
      return RemediationTask(
        stage: stage,
        mode: preferredMode,
        taskKey: 'remediation:${pattern.name}:${exercise.key}',
        prompt: exercise.prompt,
        answer: exercise.answer,
        maxAnswerValue: exercise.maxAnswerValue ?? range.maxValue,
        choices: exercise.choices,
        answerSuffix: exercise.answerSuffix,
        hint: '${pattern.action} ${exercise.hint}',
      );
    }
    final a = _between(2, 10);
    final b = _between(1, a);
    return _numeric(
      stage: stage,
      mode: preferredMode,
      key: 'remediation:${pattern.name}:basic:$a:$b',
      prompt: '$a + $b = ?',
      answer: a + b,
      max: 20,
      hint: pattern.action,
    );
  }

  RemediationTask _numeric({
    required RemediationStage stage,
    required TrainingMode mode,
    required String key,
    required String prompt,
    required int answer,
    required int max,
    required String hint,
    String? suffix,
  }) =>
      RemediationTask(
        stage: stage,
        mode: mode,
        taskKey: key,
        prompt: prompt,
        answer: answer,
        maxAnswerValue: max,
        hint: hint,
        answerSuffix: suffix,
      );

  int _between(int low, int high) =>
      high <= low ? low : low + _random.nextInt(high - low + 1);
}
