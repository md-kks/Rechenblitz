import 'dart:math';

import 'curriculum_exercise.dart';
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
