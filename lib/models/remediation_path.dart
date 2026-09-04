import 'dart:math';

import 'curriculum_exercise.dart';
import 'error_diagnosis.dart';
import 'learning_methods.dart';
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
        ErrorPattern.tenBridge =>
          _tenBridge(stage, preferredMode, range, methods),
        ErrorPattern.numberBond => _numberBond(stage, range),
        ErrorPattern.countingStep => _countingStep(stage, range),
        ErrorPattern.operationChoice => _operationChoice(stage, range),
        ErrorPattern.placeValue => _placeValue(stage, range),
        ErrorPattern.multiplicationFact =>
          _multiplication(stage, methods.multiplication),
        ErrorPattern.divisionFact => _division(stage),
        ErrorPattern.inverseOperation => _inverse(stage, range),
        ErrorPattern.wordProblem => _wordProblem(stage, grade, range),
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
  ) {
    final limit = min(range.maxValue, 100);
    if (limit <= 10) {
      return _numberBond(stage, range);
    }

    final subtraction = preferredMode == TrainingMode.minus ||
        (preferredMode == TrainingMode.practice && _random.nextBool());

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
        key: 'remediation:tenBridge:-:$a:$b',
        prompt: '$a − $b = ?',
        answer: answer,
        max: limit,
        hint: '${methods.subtraction.label}: $methodHint',
      );
    }

    final a = _between(2, min(49, max(2, limit - 10)));
    final needed = 10 - (a % 10);
    final b = _between(max(needed, 1), min(9, max(needed, limit - a)));
    return _numeric(
      stage: stage,
      mode: TrainingMode.practice,
      key: 'remediation:tenBridge:+:$a:$b',
      prompt: '$a + $b = ?',
      answer: a + b,
      max: limit,
      hint:
          'Ergänze zuerst bis zum nächsten Zehner und rechne danach den Rest weiter.',
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
  ) {
    final limit = min(range.maxValue, 100);
    final a = _between(5, max(5, limit ~/ 2));
    final b = _between(1, min(a - 1, 9));
    final plus = _random.nextBool();
    const choices = ['Plus (+)', 'Minus (−)', 'Mal (×)', 'Geteilt (÷)'];
    return RemediationTask(
      stage: stage,
      mode: TrainingMode.mixed,
      taskKey: 'remediation:operation:${plus ? '+' : '-'}:$a:$b',
      prompt: plus
          ? 'Eine Menge von $a wird um $b größer. Welche Rechenart passt?'
          : 'Von $a werden $b weggenommen. Welche Rechenart passt?',
      answer: plus ? 0 : 1,
      maxAnswerValue: 3,
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
      key: 'remediation:multiply:$a:$b',
      prompt: '$a × $b = ?',
      answer: answer,
      max: 100,
      hint: '${strategy.label}: $hint',
    );
  }

  RemediationTask _division(RemediationStage stage) {
    final divisor = _between(2, 10);
    final quotient = _between(2, 10);
    final dividend = divisor * quotient;
    return _numeric(
      stage: stage,
      mode: TrainingMode.divide,
      key: 'remediation:divide:$dividend:$divisor',
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
