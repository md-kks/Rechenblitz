// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:math';

import 'training.dart';
import 'task_diversity.dart';

class CurriculumBar {
  const CurriculumBar(this.label, this.value);
  final String label;
  final int value;
}

class CurriculumExercise {
  const CurriculumExercise({
    required this.mode,
    required this.prompt,
    required this.answer,
    required this.hint,
    required this.key,
    this.choices,
    this.answerSuffix,
    this.maxAnswerValue,
    this.method,
    this.bars,
  });

  final TrainingMode mode;
  final String prompt;
  final int answer;
  final String hint;
  final String key;
  final List<String>? choices;
  final String? answerSuffix;
  final int? maxAnswerValue;
  final String? method;
  final List<CurriculumBar>? bars;

  bool get usesChoices => choices != null && choices!.isNotEmpty;
  bool get hasBars => bars != null && bars!.isNotEmpty;
}

class CurriculumExerciseGenerator {
  CurriculumExerciseGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  CurriculumExercise generate({
    required TrainingMode mode,
    required GradeLevel gradeLevel,
    required int maxValue,
    Iterable<String> recentKeys = const <String>[],
  }) {
    if (!mode.isUpperPrimary) {
      throw ArgumentError('$mode ist kein Lernbereich für Klasse 3/4.');
    }

    final recent = recentKeys.toList();
    final exactAvoid = recent
        .take(
          TaskDiversity.recentExactWindow(
            mode: mode,
            maxValue: maxValue,
          ),
        )
        .toSet();
    final familyAvoid = recent
        .take(TaskDiversity.recentFamilyWindow(mode))
        .map(TaskDiversity.familyForKey)
        .toSet();

    CurriculumExercise? firstExactNew;
    CurriculumExercise? last;
    for (var attempt = 0; attempt < 32; attempt++) {
      final candidate = _generateOnce(
        mode: mode,
        gradeLevel: gradeLevel,
        maxValue: maxValue,
      );
      last = candidate;
      final exactNew = !exactAvoid.contains(candidate.key);
      final familyNew =
          !familyAvoid.contains(TaskDiversity.familyForKey(candidate.key));
      if (exactNew && familyNew) return candidate;
      if (exactNew && firstExactNew == null) firstExactNew = candidate;
    }
    return firstExactNew ??
        last ??
        _generateOnce(
          mode: mode,
          gradeLevel: gradeLevel,
          maxValue: maxValue,
        );
  }

  CurriculumExercise _generateOnce({
    required TrainingMode mode,
    required GradeLevel gradeLevel,
    required int maxValue,
  }) =>
      switch (mode) {
        TrainingMode.largeNumbers => _largeNumbers(gradeLevel, maxValue),
        TrainingMode.rounding => _rounding(gradeLevel, maxValue),
        TrainingMode.mentalStrategies => _mentalStrategies(gradeLevel, maxValue),
        TrainingMode.writtenAddSub => _writtenAddSub(gradeLevel, maxValue),
        TrainingMode.writtenMultiply => _writtenMultiply(gradeLevel, maxValue),
        TrainingMode.writtenDivide => _writtenDivide(gradeLevel, maxValue),
        TrainingMode.estimation => _estimation(gradeLevel, maxValue),
        TrainingMode.arithmeticLaws => _arithmeticLaws(gradeLevel),
        TrainingMode.romanNumerals => _romanNumerals(gradeLevel),
        TrainingMode.fractions => _fractions(gradeLevel, maxValue),
        TrainingMode.advancedMeasures => _advancedMeasures(gradeLevel),
        TrainingMode.timeDurations => _timeDurations(gradeLevel),
        TrainingMode.dataCharts => _dataCharts(gradeLevel),
        TrainingMode.probability => _probability(),
        TrainingMode.combinatorics => _combinatorics(gradeLevel),
        TrainingMode.proportionality => _proportionality(gradeLevel, maxValue),
        TrainingMode.perimeterArea => _perimeterArea(gradeLevel),
        TrainingMode.geometryBodies => _geometryBodies(),
        TrainingMode.symmetry => _symmetry(),
        TrainingMode.plansAndOrientation => _plansAndOrientation(gradeLevel),
        TrainingMode.volumeCubes => _volumeCubes(gradeLevel),
        _ => throw ArgumentError('$mode ist kein Lernbereich für Klasse 3/4.'),
      };

  int _safeMax(int maxValue, GradeLevel grade) => max(maxValue, 100);

  int _between(int low, int high) =>
      high <= low ? low : low + _random.nextInt(high - low + 1);

  CurriculumExercise _largeNumbers(GradeLevel grade, int maxValue) {
    final limit = _safeMax(maxValue, grade);
    final kind = _random.nextInt(4);
    if (kind == 0) {
      final a = _between(max(100, limit ~/ 10), limit);
      var b = _between(max(100, limit ~/ 10), limit);
      if (b == a) b = b == limit ? b - 1 : b + 1;
      const choices = ['<', '>', '='];
      final correct = a > b ? '>' : '<';
      return CurriculumExercise(
        mode: TrainingMode.largeNumbers,
        prompt: 'Welches Zeichen passt?\n' + _fmt(a) + '  ?  ' + _fmt(b),
        answer: choices.indexOf(correct),
        hint: 'Vergleiche zuerst die höchste Stelle, an der sich die Zahlen unterscheiden.',
        key: 'large:compare:$a:$b',
        choices: choices,
        method: 'Zahlen vergleichen',
      );
    }
    if (kind == 1) {
      final number = _between(10, limit - 1);
      final next = _random.nextBool();
      return CurriculumExercise(
        mode: TrainingMode.largeNumbers,
        prompt: (next ? 'Wie heißt der Nachfolger von ' : 'Wie heißt der Vorgänger von ') +
            _fmt(number) +
            '?',
        answer: next ? number + 1 : number - 1,
        hint: next ? 'Gehe genau 1 weiter.' : 'Gehe genau 1 zurück.',
        key: 'large:neighbor:$number:$next',
        maxAnswerValue: limit,
        method: 'Im Zahlenraum orientieren',
      );
    }
    if (kind == 2) {
      final number = _between(100, limit);
      final powers = [1, 10, 100, 1000, 10000, 100000, 1000000]
          .where((value) => value <= limit)
          .toList();
      final place = powers[_random.nextInt(powers.length)];
      final digit = (number ~/ place) % 10;
      final name = switch (place) {
        1 => 'Einerstelle',
        10 => 'Zehnerstelle',
        100 => 'Hunderterstelle',
        1000 => 'Tausenderstelle',
        10000 => 'Zehntausenderstelle',
        100000 => 'Hunderttausenderstelle',
        1000000 => 'Millionenstelle',
        _ => 'Stelle',
      };
      return CurriculumExercise(
        mode: TrainingMode.largeNumbers,
        prompt: 'Welche Ziffer steht bei ' + _fmt(number) + ' an der $name?',
        answer: digit,
        hint: 'Nutze gedanklich eine Stellenwerttafel.',
        key: 'large:place:$number:$place',
        maxAnswerValue: 9,
        method: 'Stellenwert',
      );
    }
    final number = _between(100, limit);
    final labels = [
      (1000000, 'M'),
      (100000, 'HT'),
      (10000, 'ZT'),
      (1000, 'T'),
      (100, 'H'),
      (10, 'Z'),
      (1, 'E'),
    ];
    final parts = <String>[];
    for (final item in labels) {
      final digit = (number ~/ item.$1) % 10;
      if (digit > 0) parts.add('$digit ' + item.$2);
    }
    return CurriculumExercise(
      mode: TrainingMode.largeNumbers,
      prompt: parts.join(' + ') + ' ergeben welche Zahl?',
      answer: number,
      hint: 'M = Million, HT = Hunderttausender, ZT = Zehntausender, T = Tausender, H = Hunderter, Z = Zehner, E = Einer.',
      key: 'large:decompose:$number',
      maxAnswerValue: limit,
      method: 'Stellenwerttafel',
    );
  }

  CurriculumExercise _rounding(GradeLevel grade, int maxValue) {
    final limit = _safeMax(maxValue, grade);
    final places = [10, 100, 1000, 10000, 100000]
        .where((value) => value <= limit)
        .toList();
    final place = places[_random.nextInt(places.length)];
    final number = _between(place, limit);
    final rounded = _roundTo(number, place);
    final label = switch (place) {
      10 => 'Zehner',
      100 => 'Hunderter',
      1000 => 'Tausender',
      10000 => 'Zehntausender',
      100000 => 'Hunderttausender',
      _ => 'Stelle',
    };
    return CurriculumExercise(
      mode: TrainingMode.rounding,
      prompt: 'Runde ' + _fmt(number) + ' auf $label.',
      answer: rounded,
      hint: 'Schau auf die Stelle rechts daneben: 0–4 abrunden, 5–9 aufrunden.',
      key: 'round:$number:$place',
      maxAnswerValue: max(limit, rounded),
      method: 'Runden',
    );
  }

  CurriculumExercise _mentalStrategies(GradeLevel grade, int maxValue) {
    final limit = _safeMax(maxValue, grade);
    final addition = _random.nextBool();
    final lowA = min(100, max(10, limit ~/ 4));
    final highA = max(lowA, min(limit - 10, grade == GradeLevel.third ? 900 : 900000));
    final a = _between(lowA, highA);
    final b = _between(1, min(max(1, limit - a), grade == GradeLevel.third ? 99 : 49999));
    if (addition) {
      final add = min(b, max(1, limit - a));
      return CurriculumExercise(
        mode: TrainingMode.mentalStrategies,
        prompt: _fmt(a) + ' + ' + _fmt(add) + ' = ?',
        answer: a + add,
        hint: 'Zerlege den zweiten Summanden in Hunderter, Zehner und Einer.',
        key: 'mental:+:$a:$add',
        maxAnswerValue: limit,
        method: 'Halbschriftlich addieren',
      );
    }
    final sub = min(b, a);
    return CurriculumExercise(
      mode: TrainingMode.mentalStrategies,
      prompt: _fmt(a) + ' − ' + _fmt(sub) + ' = ?',
      answer: a - sub,
      hint: 'Ziehe schrittweise ab oder ergänze geschickt.',
      key: 'mental:-:$a:$sub',
      maxAnswerValue: limit,
      method: 'Halbschriftlich subtrahieren',
    );
  }

  CurriculumExercise _writtenAddSub(GradeLevel grade, int maxValue) {
    final limit = _safeMax(maxValue, grade);
    if (_random.nextBool()) {
      final a = _between(min(50, max(10, limit ~/ 3)), max(10, limit - 1));
      final b = _between(1, max(1, limit - a));
      return CurriculumExercise(
        mode: TrainingMode.writtenAddSub,
        prompt: 'Rechne schriftlich:\n' + _fmt(a) + '\n+ ' + _fmt(b),
        answer: a + b,
        hint: 'Schreibe Einer unter Einer, Zehner unter Zehner usw. und beachte Überträge.',
        key: 'written:+:$a:$b',
        maxAnswerValue: limit,
        method: 'Schriftliche Addition',
      );
    }
    final a = _between(min(200, max(20, limit ~/ 2)), limit);
    final b = _between(1, a);
    return CurriculumExercise(
      mode: TrainingMode.writtenAddSub,
      prompt: 'Rechne schriftlich:\n' + _fmt(a) + '\n− ' + _fmt(b),
      answer: a - b,
      hint: 'Achte auf Stellenwerte und notwendige Überträge.',
      key: 'written:-:$a:$b',
      maxAnswerValue: limit,
      method: 'Schriftliche Subtraktion',
    );
  }

  CurriculumExercise _writtenMultiply(GradeLevel grade, int maxValue) {
    final limit = _safeMax(maxValue, grade);
    final b = _between(2, grade == GradeLevel.third ? 9 : 25);
    final a = _between(2, max(2, min(limit ~/ b, grade == GradeLevel.third ? 999 : 9999)));
    return CurriculumExercise(
      mode: TrainingMode.writtenMultiply,
      prompt: 'Rechne:\n' + _fmt(a) + ' × $b = ?',
      answer: a * b,
      hint: b < 10
          ? 'Multipliziere Stelle für Stelle und notiere Überträge.'
          : 'Zerlege den zweiten Faktor oder nutze Teilprodukte.',
      key: 'written:x:$a:$b',
      maxAnswerValue: limit,
      method: b < 10 ? 'Schriftliche Multiplikation' : 'Multiplikation mit Teilprodukten',
    );
  }

  CurriculumExercise _writtenDivide(GradeLevel grade, int maxValue) {
    final limit = _safeMax(maxValue, grade);
    final divisor = _between(2, 9);
    final quotient = _between(
      2,
      max(2, min(limit ~/ divisor, grade == GradeLevel.third ? 999 : 99999)),
    );
    if (grade == GradeLevel.fourth && _random.nextDouble() < 0.35) {
      final rest = _between(1, divisor - 1);
      final dividend = quotient * divisor + rest;
      final correct = '$quotient Rest $rest';
      final options = <String>{
        correct,
        '${quotient + 1} Rest $rest',
        '$quotient Rest ${rest == 1 ? 2 : rest - 1}',
        '${max(1, quotient - 1)} Rest $rest',
      }.toList()
        ..shuffle(_random);
      return CurriculumExercise(
        mode: TrainingMode.writtenDivide,
        prompt: 'Rechne schriftlich:\n' + _fmt(dividend) + ' ÷ $divisor = ?',
        answer: options.indexOf(correct),
        hint: 'Der Rest muss kleiner als der Divisor sein. Prüfe: Quotient × Divisor + Rest.',
        key: 'written:divide-rest:$dividend:$divisor',
        choices: options,
        method: 'Schriftliche Division mit Rest',
      );
    }
    final dividend = quotient * divisor;
    return CurriculumExercise(
      mode: TrainingMode.writtenDivide,
      prompt: 'Rechne schriftlich:\n' + _fmt(dividend) + ' ÷ $divisor = ?',
      answer: quotient,
      hint: 'Teile von links nach rechts. Prüfe danach mit der Umkehraufgabe.',
      key: 'written:divide:$dividend:$divisor',
      maxAnswerValue: quotient,
      method: 'Schriftliche Division ohne Rest',
    );
  }

  CurriculumExercise _estimation(GradeLevel grade, int maxValue) {
    final limit = _safeMax(maxValue, grade);
    final place = limit <= 500
        ? 10
        : limit >= 10000
            ? 1000
            : 100;
    final minimum = max(1, place ~/ 2);
    final a = _between(minimum, max(minimum, limit ~/ 2));
    final b = _between(minimum, max(minimum, limit - a));
    final estimate = _roundTo(a, place) + _roundTo(b, place);
    final values = <int>{estimate, max(0, estimate - place), estimate + place, estimate + 2 * place}.toList()
      ..shuffle(_random);
    return CurriculumExercise(
      mode: TrainingMode.estimation,
      prompt: 'Welcher Überschlag passt am besten zu\n' + _fmt(a) + ' + ' + _fmt(b) + '?',
      answer: values.indexOf(estimate),
      hint: 'Runde beide Zahlen zuerst sinnvoll.',
      key: 'estimate:$a:$b:$place',
      choices: values.map(_fmt).toList(),
      method: 'Überschlagsrechnung',
    );
  }

  CurriculumExercise _arithmeticLaws(GradeLevel grade) {
    final kind = _random.nextInt(3);
    if (kind == 0) {
      final a = _between(2, 9);
      final b = _between(11, grade == GradeLevel.third ? 49 : 99);
      final rounded = ((b + 9) ~/ 10) * 10;
      final diff = rounded - b;
      return CurriculumExercise(
        mode: TrainingMode.arithmeticLaws,
        prompt: '$a × $b = $a × $rounded − ?',
        answer: a * diff,
        hint: 'Nutze das Distributivgesetz.',
        key: 'law:distribute:$a:$b',
        maxAnswerValue: 1000,
        method: 'Distributivgesetz',
      );
    }
    if (kind == 1) {
      final a = _between(10, 90);
      final c = 100 - a;
      final b = _between(10, 90);
      const choices = ['erste und dritte Zahl', 'erste und zweite Zahl', 'zweite und dritte Zahl'];
      return CurriculumExercise(
        mode: TrainingMode.arithmeticLaws,
        prompt: '$a + $b + $c\nWelche Zahlen rechnest du günstig zuerst?',
        answer: 0,
        hint: '$a + $c = 100.',
        key: 'law:associate:$a:$b:$c',
        choices: choices,
        method: 'Rechenvorteile',
      );
    }
    final a = _between(2, 20);
    final b = _between(2, 20);
    return CurriculumExercise(
      mode: TrainingMode.arithmeticLaws,
      prompt: '$a × $b = $b × ?',
      answer: a,
      hint: 'Beim Malnehmen darfst du die Faktoren vertauschen.',
      key: 'law:commute:$a:$b',
      maxAnswerValue: 100,
      method: 'Kommutativgesetz',
    );
  }

  CurriculumExercise _romanNumerals(GradeLevel grade) {
    final limit = grade == GradeLevel.third ? 50 : 100;
    final value = _between(1, limit);
    final roman = _roman(value);
    if (_random.nextBool()) {
      return CurriculumExercise(
        mode: TrainingMode.romanNumerals,
        prompt: 'Welche Zahl bedeutet $roman?',
        answer: value,
        hint: 'I = 1, V = 5, X = 10, L = 50, C = 100.',
        key: 'roman:read:$value',
        maxAnswerValue: limit,
        method: 'Römische Zahlen lesen',
      );
    }
    final options = <String>{roman};
    while (options.length < 4) {
      options.add(_roman(_between(1, limit)));
    }
    final choices = options.toList()..shuffle(_random);
    return CurriculumExercise(
      mode: TrainingMode.romanNumerals,
      prompt: 'Wie schreibt man $value als römische Zahl?',
      answer: choices.indexOf(roman),
      hint: 'I = 1, V = 5, X = 10, L = 50, C = 100.',
      key: 'roman:write:$value',
      choices: choices,
      method: 'Römische Zahlen darstellen',
    );
  }

  CurriculumExercise _fractions(GradeLevel grade, int maxValue) {
    final kind = _random.nextInt(4);
    if (kind == 0) {
      final whole = _between(1, 100) * 2;
      return CurriculumExercise(
        mode: TrainingMode.fractions,
        prompt: 'Wie viel ist 1/2 von $whole?',
        answer: whole ~/ 2,
        hint: 'Halbiere die Menge in zwei gleich große Teile.',
        key: 'fraction:half:$whole',
        maxAnswerValue: whole,
        method: 'Bruchteil einer Menge',
      );
    }
    if (kind == 1) {
      final part = _between(1, 25);
      final whole = part * 4;
      return CurriculumExercise(
        mode: TrainingMode.fractions,
        prompt: 'Wie viel ist 1/4 von $whole?',
        answer: part,
        hint: 'Teile die Menge in vier gleich große Teile.',
        key: 'fraction:quarter:$whole',
        maxAnswerValue: whole,
        method: 'Bruchteil einer Menge',
      );
    }
    if (kind == 2) {
      const choices = ['15 min', '30 min', '45 min', '60 min'];
      return const CurriculumExercise(
        mode: TrainingMode.fractions,
        prompt: 'Wie lange sind 3/4 Stunde?',
        answer: 2,
        hint: 'Eine Stunde hat 60 Minuten. Ein Viertel sind 15 Minuten.',
        key: 'fraction:time',
        choices: choices,
        method: 'Bruchteile bei Größen',
      );
    }
    const choices = ['250 ml', '500 ml', '750 ml', '1000 ml'];
    return const CurriculumExercise(
      mode: TrainingMode.fractions,
      prompt: 'Wie viel sind 1/4 Liter?',
      answer: 0,
      hint: '1 Liter = 1000 ml.',
      key: 'fraction:volume',
      choices: choices,
      method: 'Bruchteile bei Größen',
    );
  }

  CurriculumExercise _advancedMeasures(GradeLevel grade) {
    final kind = _random.nextInt(grade == GradeLevel.fourth ? 8 : 6);
    if (kind == 0) {
      final value = _between(1, grade == GradeLevel.third ? 9 : 50);
      return _conversion('$value m sind wie viele cm?', value * 100, '1 m = 100 cm.', 'cm', 'length:m:$value', 5000);
    }
    if (kind == 1) {
      final value = _between(1, grade == GradeLevel.third ? 5 : 20);
      return _conversion('$value km sind wie viele m?', value * 1000, '1 km = 1000 m.', 'm', 'length:km:$value', 20000);
    }
    if (kind == 2) {
      final value = _between(1, 20);
      return _conversion('$value kg sind wie viele g?', value * 1000, '1 kg = 1000 g.', 'g', 'mass:kg:$value', 20000);
    }
    if (kind == 3) {
      final value = _between(1, 10);
      return _conversion('$value l sind wie viele ml?', value * 1000, '1 l = 1000 ml.', 'ml', 'volume:l:$value', 10000);
    }
    if (kind == 4) {
      final value = _between(1, 9);
      return _conversion('$value cm sind wie viele mm?', value * 10, '1 cm = 10 mm.', 'mm', 'length:cm-mm:$value', 100);
    }
    if (kind == 5 && grade == GradeLevel.fourth) {
      final value = _between(1, 9);
      return _conversion('$value t sind wie viele kg?', value * 1000, '1 t = 1000 kg.', 'kg', 'mass:t-kg:$value', 10000);
    }
    if (kind == 6) {
      final value = _between(1, 5) * 60;
      return _conversion('$value min sind wie viele Stunden?', value ~/ 60, '60 min = 1 h.', 'h', 'time:min:$value', 10);
    }
    final value = _between(1, 50);
    return _conversion('$value € sind wie viele Cent?', value * 100, '1 € = 100 ct.', 'ct', 'money:euro:$value', 5000);
  }

  CurriculumExercise _conversion(
    String prompt,
    int answer,
    String hint,
    String suffix,
    String key,
    int maxAnswer,
  ) =>
      CurriculumExercise(
        mode: TrainingMode.advancedMeasures,
        prompt: prompt,
        answer: answer,
        hint: hint,
        key: key,
        answerSuffix: suffix,
        maxAnswerValue: maxAnswer,
        method: 'Größen umwandeln',
      );

  CurriculumExercise _timeDurations(GradeLevel grade) {
    if (grade == GradeLevel.fourth && _random.nextDouble() < 0.25) {
      if (_random.nextBool()) {
        final weeks = _between(1, 6);
        return CurriculumExercise(
          mode: TrainingMode.timeDurations,
          prompt: '$weeks Wochen sind wie viele Tage?',
          answer: weeks * 7,
          hint: 'Eine Woche hat 7 Tage.',
          key: 'duration:weeks:$weeks',
          answerSuffix: 'Tage',
          maxAnswerValue: 50,
          method: 'Kalender und Zeitspannen',
        );
      }
      final days = _between(1, 5);
      return CurriculumExercise(
        mode: TrainingMode.timeDurations,
        prompt: '$days Tage sind wie viele Stunden?',
        answer: days * 24,
        hint: 'Ein Tag hat 24 Stunden.',
        key: 'duration:days:$days',
        answerSuffix: 'h',
        maxAnswerValue: 120,
        method: 'Zeiteinheiten',
      );
    }
    final hour = _between(7, 17);
    final minute = [0, 15, 30, 45][_random.nextInt(4)];
    final options = grade == GradeLevel.third
        ? [15, 30, 45, 60, 75, 90]
        : [15, 25, 30, 45, 60, 75, 90, 105, 120, 135];
    final duration = options[_random.nextInt(options.length)];
    final start = hour * 60 + minute;
    final end = start + duration;
    final endHour = (end ~/ 60) % 24;
    final endMinute = end % 60;
    return CurriculumExercise(
      mode: TrainingMode.timeDurations,
      prompt: 'Beginn: ' +
          _clock(hour, minute) +
          ' Uhr\nEnde: ' +
          _clock(endHour, endMinute) +
          ' Uhr\nWie viele Minuten dauert es?',
      answer: duration,
      hint: 'Rechne zuerst bis zur nächsten vollen Stunde und dann weiter.',
      key: 'duration:$start:$duration',
      answerSuffix: 'min',
      maxAnswerValue: 240,
      method: 'Zeitdauer berechnen',
    );
  }

  CurriculumExercise _dataCharts(GradeLevel grade) {
    final labels = ['Rot', 'Blau', 'Grün', 'Gelb'];
    final values = List<int>.generate(
      4,
      (_) => _between(2, grade == GradeLevel.third ? 20 : 40),
    );
    final bars = List<CurriculumBar>.generate(
      4,
      (i) => CurriculumBar(labels[i], values[i]),
    );
    final kind = _random.nextInt(3);
    if (kind == 0) {
      return CurriculumExercise(
        mode: TrainingMode.dataCharts,
        prompt: 'Welche Anzahl ist im Diagramm am größten?',
        answer: values.reduce(max),
        hint: 'Suche den höchsten Balken.',
        key: 'data:max:' + values.join('-'),
        maxAnswerValue: 100,
        bars: bars,
        method: 'Diagramme lesen',
      );
    }
    if (kind == 1) {
      return CurriculumExercise(
        mode: TrainingMode.dataCharts,
        prompt: 'Wie viele Stimmen wurden insgesamt abgegeben?',
        answer: values.reduce((a, b) => a + b),
        hint: 'Addiere alle Balkenwerte.',
        key: 'data:sum:' + values.join('-'),
        maxAnswerValue: 200,
        bars: bars,
        method: 'Daten auswerten',
      );
    }
    return CurriculumExercise(
      mode: TrainingMode.dataCharts,
      prompt: 'Um wie viele Stimmen unterscheiden sich Rot und Blau?',
      answer: (values[0] - values[1]).abs(),
      hint: 'Bilde die Differenz der beiden Werte.',
      key: 'data:diff:' + values.join('-'),
      maxAnswerValue: 100,
      bars: bars,
      method: 'Diagramme vergleichen',
    );
  }

  CurriculumExercise _probability() {
    final kind = _random.nextInt(4);
    const choices = ['sicher', 'möglich', 'unmöglich'];

    if (kind == 0) {
      final boundary = _between(7, 12);
      return CurriculumExercise(
        mode: TrainingMode.probability,
        prompt:
            'Normaler Würfel: Es fällt eine Zahl kleiner als $boundary.',
        answer: 0,
        hint: 'Ein normaler Würfel zeigt nur die Zahlen 1 bis 6.',
        key: 'prob:sure:below:$boundary',
        choices: choices,
        method: 'Sicher – möglich – unmöglich',
      );
    }

    if (kind == 1) {
      final face = _between(1, 6);
      return CurriculumExercise(
        mode: TrainingMode.probability,
        prompt: 'Normaler Würfel: Es fällt eine $face.',
        answer: 1,
        hint: 'Diese Zahl ist auf dem Würfel vorhanden, muss aber nicht fallen.',
        key: 'prob:possible:face:$face',
        choices: choices,
        method: 'Sicher – möglich – unmöglich',
      );
    }

    if (kind == 2) {
      final impossible = _between(7, 12);
      return CurriculumExercise(
        mode: TrainingMode.probability,
        prompt: 'Normaler Würfel: Es fällt eine $impossible.',
        answer: 2,
        hint: 'Ein normaler Würfel hat nur die Zahlen 1 bis 6.',
        key: 'prob:impossible:face:$impossible',
        choices: choices,
        method: 'Sicher – möglich – unmöglich',
      );
    }

    final red = _between(1, 9);
    final blue = _between(1, 9);
    final context = _random.nextBool() ? 'Kugeln' : 'Spielsteine';
    const compare = [
      'Rot wahrscheinlicher',
      'Blau wahrscheinlicher',
      'gleich wahrscheinlich',
    ];
    return CurriculumExercise(
      mode: TrainingMode.probability,
      prompt:
          'Im Beutel liegen $red rote und $blue blaue $context. Was stimmt?',
      answer: red == blue ? 2 : red > blue ? 0 : 1,
      hint: 'Mehr Stücke einer Farbe bedeuten eine größere Ziehchance.',
      key: 'prob:bag:${context.toLowerCase()}:$red:$blue',
      choices: compare,
      method: 'Chancen einschätzen',
    );
  }

  CurriculumExercise _combinatorics(GradeLevel grade) {
    final first = _between(2, grade == GradeLevel.third ? 4 : 6);
    final second = _between(2, grade == GradeLevel.third ? 4 : 5);
    final third =
        grade == GradeLevel.fourth && _random.nextBool() ? _between(2, 3) : 1;
    final kind = _random.nextInt(3);

    final prompt = switch (kind) {
      0 => third == 1
          ? '$first T-Shirts und $second Hosen: Wie viele verschiedene Kombinationen gibt es?'
          : '$first T-Shirts, $second Hosen und $third Mützen: Wie viele Kombinationen gibt es?',
      1 => third == 1
          ? 'Eine Eisdiele hat $first Eissorten und $second Soßen. Wie viele Kombinationen aus einer Sorte und einer Soße sind möglich?'
          : 'Es gibt $first Eissorten, $second Soßen und $third Streuselarten. Wie viele Kombinationen sind möglich?',
      _ => third == 1
          ? 'Für ein Zeichen gibt es $first Symbole und $second Farben. Wie viele verschiedene Zeichen können entstehen?'
          : 'Es gibt $first Symbole, $second Farben und $third Rahmen. Wie viele Varianten können entstehen?',
    };
    final family = ['clothes', 'icecream', 'symbols'][kind];

    return CurriculumExercise(
      mode: TrainingMode.combinatorics,
      prompt: prompt,
      answer: first * second * third,
      hint: 'Verbinde jede Möglichkeit systematisch mit jeder anderen.',
      key: 'combo:$family:$first:$second:$third',
      maxAnswerValue: 300,
      method: 'Systematisch kombinieren',
    );
  }

  CurriculumExercise _proportionality(GradeLevel grade, int maxValue) {
    final unit = _between(1, grade == GradeLevel.third ? 5 : 12);
    final first = _between(2, 5);
    final second = _between(2, grade == GradeLevel.third ? 8 : 12);
    final kind = _random.nextInt(4);
    final total = first * unit;

    final prompt = switch (kind) {
      0 => '$first Hefte kosten $total €. Was kosten $second Hefte?',
      1 => '$first Eintrittskarten kosten zusammen $total €. Was kosten $second gleich teure Karten?',
      2 => '$first gleiche Packungen kosten zusammen $total €. Was kosten $second Packungen?',
      _ => '$first Meter Band kosten zusammen $total €. Was kosten $second Meter zum gleichen Meterpreis?',
    };
    final family = ['notebooks', 'tickets', 'packs', 'ribbon'][kind];

    return CurriculumExercise(
      mode: TrainingMode.proportionality,
      prompt: prompt,
      answer: second * unit,
      hint: 'Bestimme zuerst den Wert für 1 Einheit.',
      key: 'proportion:$family:$unit:$first:$second',
      answerSuffix: '€',
      maxAnswerValue: max(100, maxValue),
      method: 'Einfache Zuordnung',
    );
  }

  CurriculumExercise _perimeterArea(GradeLevel grade) {
    final width = _between(2, grade == GradeLevel.third ? 12 : 25);
    final height = _between(2, grade == GradeLevel.third ? 12 : 25);
    final area = _random.nextBool();
    final context = _random.nextInt(4);
    final object = ['Rechteck', 'Bild', 'Beet', 'Spielteppich'][context];
    final prompt = area
        ? '$object: $width cm lang und $height cm breit. Wie groß ist die Fläche?'
        : '$object: $width cm lang und $height cm breit. Wie groß ist der Umfang?';
    return CurriculumExercise(
      mode: TrainingMode.perimeterArea,
      prompt: prompt,
      answer: area ? width * height : 2 * (width + height),
      hint: area
          ? 'Fläche: Länge × Breite bzw. Einheitsquadrate zählen.'
          : 'Umfang: Addiere alle vier Seiten.',
      key:
          'rect:${area ? 'area' : 'perimeter'}:${object.toLowerCase()}:$width:$height',
      answerSuffix: area ? 'cm²' : 'cm',
      maxAnswerValue: 2000,
      method: area ? 'Flächeninhalt' : 'Umfang',
    );
  }

  CurriculumExercise _geometryBodies() {
    if (_random.nextDouble() < 0.25) {
      if (_random.nextBool()) {
        return const CurriculumExercise(
          mode: TrainingMode.geometryBodies,
          prompt: 'Aus wie vielen Quadraten besteht jedes Würfelnetz?',
          answer: 6,
          hint: 'Ein Würfel hat 6 quadratische Flächen. Im Netz sind alle 6 zu sehen.',
          key: 'body:cube-net:faces',
          maxAnswerValue: 12,
          method: 'Würfelnetze',
        );
      }
      const options = [
        '6 Quadrate, die sich ohne Überlappung zum Würfel falten lassen',
        '5 Quadrate in einer Reihe',
        '4 Quadrate und 2 Dreiecke',
      ];
      return const CurriculumExercise(
        mode: TrainingMode.geometryBodies,
        prompt: 'Welche Beschreibung kann zu einem Würfelnetz gehören?',
        answer: 0,
        hint: 'Ein Würfelnetz besteht immer aus genau 6 Quadraten.',
        key: 'body:cube-net:description',
        choices: options,
        method: 'Würfelnetze',
      );
    }
    const bodies = ['Würfel', 'Quader', 'Kugel', 'Zylinder', 'Kegel', 'Pyramide'];
    const corners = [8, 8, 0, 0, 1, 5];
    const edges = [12, 12, 0, 2, 1, 8];
    const faces = [6, 6, 1, 3, 2, 5];
    final index = _random.nextInt(bodies.length);
    final kind = _random.nextInt(3);
    final property = ['Ecken', 'Kanten', 'Flächen'][kind];
    final answer = [corners[index], edges[index], faces[index]][kind];
    return CurriculumExercise(
      mode: TrainingMode.geometryBodies,
      prompt: 'Wie viele $property hat ein ' + bodies[index] + '?',
      answer: answer,
      hint: 'Stelle dir den Körper vor und zähle systematisch.',
      key: 'body:' + bodies[index] + ':$property',
      maxAnswerValue: 20,
      method: 'Körper und Eigenschaften',
    );
  }

  CurriculumExercise _symmetry() {
    const names = ['Quadrat', 'Rechteck', 'gleichseitiges Dreieck', 'gleichschenkliges Dreieck'];
    const axes = [4, 2, 3, 1];
    final index = _random.nextInt(names.length);
    return CurriculumExercise(
      mode: TrainingMode.symmetry,
      prompt: 'Wie viele Symmetrieachsen hat ein ' + names[index] + '?',
      answer: axes[index],
      hint: 'Eine Symmetrieachse teilt die Figur in zwei spiegelgleiche Hälften.',
      key: 'symmetry:' + names[index],
      maxAnswerValue: 6,
      method: 'Achsensymmetrie',
    );
  }

  CurriculumExercise _plansAndOrientation(GradeLevel grade) {
    final right = _between(1, grade == GradeLevel.third ? 8 : 15);
    final up = _between(1, grade == GradeLevel.third ? 8 : 15);
    if (grade == GradeLevel.fourth && _random.nextBool()) {
      final scale = [10, 100, 1000][_random.nextInt(3)];
      final cm = _between(2, 8);
      return CurriculumExercise(
        mode: TrainingMode.plansAndOrientation,
        prompt: 'Im Plan entsprechen 1 cm genau $scale m. Eine Strecke ist $cm cm lang. Wie viele Meter sind das?',
        answer: cm * scale,
        hint: 'Multipliziere die Planlänge mit der Zuordnung pro Zentimeter.',
        key: 'plan:scale:$scale:$cm',
        answerSuffix: 'm',
        maxAnswerValue: 10000,
        method: 'Pläne und Maßstabsbeziehungen',
      );
    }
    return CurriculumExercise(
      mode: TrainingMode.plansAndOrientation,
      prompt: 'Ein Weg führt $right Felder nach rechts und $up Felder nach oben. Wie viele Felder gehst du insgesamt?',
      answer: right + up,
      hint: 'Addiere beide Wegabschnitte.',
      key: 'plan:path:$right:$up',
      maxAnswerValue: 40,
      method: 'Wege und Lagebeziehungen',
    );
  }

  CurriculumExercise _volumeCubes(GradeLevel grade) {
    final length = _between(2, grade == GradeLevel.third ? 4 : 8);
    final width = _between(2, grade == GradeLevel.third ? 4 : 6);
    final height = _between(1, grade == GradeLevel.third ? 3 : 5);
    return CurriculumExercise(
      mode: TrainingMode.volumeCubes,
      prompt: 'Quader aus Einheitswürfeln: $length lang, $width breit, $height hoch. Wie viele Würfel sind es?',
      answer: length * width * height,
      hint: 'Eine Schicht hat Länge × Breite Würfel. Multipliziere mit der Zahl der Schichten.',
      key: 'volume:$length:$width:$height',
      maxAnswerValue: 300,
      method: 'Rauminhalt mit Einheitswürfeln',
    );
  }

  int _roundTo(int number, int place) =>
      ((number + place ~/ 2) ~/ place) * place;

  String _clock(int hour, int minute) =>
      hour.toString().padLeft(2, '0') + ':' + minute.toString().padLeft(2, '0');

  String _fmt(int value) {
    final digits = value.toString();
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write('.');
      out.write(digits[i]);
    }
    return out.toString();
  }

  String _roman(int value) {
    var rest = value;
    final out = StringBuffer();
    const values = [100, 90, 50, 40, 10, 9, 5, 4, 1];
    const symbols = ['C', 'XC', 'L', 'XL', 'X', 'IX', 'V', 'IV', 'I'];
    for (var i = 0; i < values.length; i++) {
      while (rest >= values[i]) {
        out.write(symbols[i]);
        rest -= values[i];
      }
    }
    return out.toString();
  }
}
