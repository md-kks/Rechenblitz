import 'dart:math';

import '../models/micro_competency.dart';
import '../models/training.dart';
import '../models/task_diversity.dart';

enum ExerciseShape { triangle, square, rectangle, circle }

class StructuredExercise {
  const StructuredExercise({
    required this.mode,
    required this.prompt,
    required this.answer,
    required this.hint,
    required this.key,
    this.wallValues,
    this.hiddenWallIndex,
    this.choices,
    this.clockHour,
    this.clockMinute,
    this.shape,
    this.moneyPartsCents,
    this.answerSuffix,
    this.maxAnswerValue,
  });

  final TrainingMode mode;
  final String prompt;
  final int answer;
  final String hint;
  final String key;
  final List<int>? wallValues;
  final int? hiddenWallIndex;
  final List<String>? choices;
  final int? clockHour;
  final int? clockMinute;
  final ExerciseShape? shape;
  final List<int>? moneyPartsCents;
  final String? answerSuffix;
  final int? maxAnswerValue;

  bool get isNumberWall => wallValues != null && hiddenWallIndex != null;
  bool get usesChoices => choices != null && choices!.isNotEmpty;
  bool get hasClock => clockHour != null && clockMinute != null;
  bool get hasMoneyVisual => moneyPartsCents != null && moneyPartsCents!.isNotEmpty;
}

class StructuredExerciseGenerator {
  StructuredExerciseGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  StructuredExercise generate({
    required TrainingMode mode,
    required int maxValue,
    Iterable<String> recentKeys = const <String>[],
    MicroCompetencyId? targetCompetency,
  }) {
    final recent = recentKeys.toList();
    final exactWindow = TaskDiversity.recentExactWindow(
      mode: mode,
      maxValue: maxValue,
    );
    final exactAvoid = recent.take(exactWindow).toSet();
    final familyAvoid = recent
        .take(TaskDiversity.recentFamilyWindow(mode))
        .map(TaskDiversity.familyForKey)
        .toSet();

    StructuredExercise? firstExactNew;
    StructuredExercise? last;
    for (var attempt = 0; attempt < 28; attempt++) {
      final candidate = _generateOnce(mode: mode, maxValue: maxValue);
      last = candidate;
      final exactNew = !exactAvoid.contains(candidate.key);
      final familyNew =
          !familyAvoid.contains(TaskDiversity.familyForKey(candidate.key));
      final targetMatches = targetCompetency == null ||
          MicroCompetencyCatalog.tagsForTask(
            mode: mode,
            taskKey: candidate.key,
          ).any((tag) => tag.id == targetCompetency);
      if (targetMatches && exactNew && familyNew) return candidate;
      if (targetMatches && exactNew && firstExactNew == null) {
        firstExactNew = candidate;
      }
    }
    return firstExactNew ?? last ?? _generateOnce(mode: mode, maxValue: maxValue);
  }

  StructuredExercise _generateOnce({
    required TrainingMode mode,
    required int maxValue,
  }) =>
      switch (mode) {
        TrainingMode.numberWall => _numberWall(maxValue),
        TrainingMode.missingNumber => _missingNumber(maxValue),
        TrainingMode.neighbors => _neighbors(maxValue),
        TrainingMode.placeValue => _placeValue(maxValue),
        TrainingMode.doublesHalves => _doublesHalves(maxValue),
        TrainingMode.sequences => _sequence(maxValue),
        TrainingMode.factFamilies => _factFamily(maxValue),
        TrainingMode.wordProblems => _wordProblem(maxValue),
        TrainingMode.money => _money(maxValue),
        TrainingMode.clock => _clock(maxValue),
        TrainingMode.measures => _measures(maxValue),
        TrainingMode.geometry => _geometry(maxValue),
        _ => throw ArgumentError('$mode ist kein strukturierter Aufgabentyp.'),
      };

  StructuredExercise _numberWall(int maxValue) {
    for (var tries = 0; tries < 100; tries++) {
      final bottomMax = max(2, maxValue ~/ 4);
      final a = _random.nextInt(bottomMax + 1);
      final b = _random.nextInt(bottomMax + 1);
      final c = _random.nextInt(bottomMax + 1);
      final left = a + b;
      final right = b + c;
      final top = left + right;
      if (top == 0 || top > maxValue) continue;
      final values = [a, b, c, left, right, top];
      final candidates = maxValue <= 10 ? [3, 4, 5] : [0, 1, 2, 3, 4, 5];
      final hidden = candidates[_random.nextInt(candidates.length)];
      return StructuredExercise(
        mode: TrainingMode.numberWall,
        prompt: 'Welche Zahl fehlt in der Zahlenmauer?',
        answer: values[hidden],
        hint: 'Jeder Stein ist die Summe der beiden Steine direkt darunter.',
        key: 'wall:${values.join('-')}:$hidden',
        wallValues: values,
        hiddenWallIndex: hidden,
      );
    }
    return const StructuredExercise(
      mode: TrainingMode.numberWall,
      prompt: 'Welche Zahl fehlt in der Zahlenmauer?',
      answer: 4,
      hint: 'Jeder Stein ist die Summe der beiden Steine direkt darunter.',
      key: 'wall:fallback',
      wallValues: [1, 3, 1, 4, 4, 8],
      hiddenWallIndex: 3,
    );
  }

  StructuredExercise _missingNumber(int maxValue) {
    final usePlus = _random.nextBool();
    if (usePlus) {
      final a = _random.nextInt(maxValue + 1);
      final b = _random.nextInt(maxValue - a + 1);
      final sum = a + b;
      final hideB = _random.nextBool();
      return StructuredExercise(
        mode: TrainingMode.missingNumber,
        prompt: hideB ? '$a + ? = $sum' : '? + $b = $sum',
        answer: hideB ? b : a,
        hint: 'Überlege, welche Zahl noch bis $sum fehlt.',
        key: 'gap:+:$a:$b:${hideB ? 'b' : 'a'}',
      );
    }

    final a = _random.nextInt(maxValue + 1);
    final b = _random.nextInt(a + 1);
    final result = a - b;
    final hideB = _random.nextBool();
    return StructuredExercise(
      mode: TrainingMode.missingNumber,
      prompt: hideB ? '$a − ? = $result' : '? − $b = $result',
      answer: hideB ? b : a,
      hint: hideB
          ? 'Denke rückwärts: $result + ? = $a.'
          : 'Welche Zahl muss vorne stehen, damit nach dem Wegnehmen $result bleibt?',
      key: 'gap:-:$a:$b:${hideB ? 'b' : 'a'}',
    );
  }

  StructuredExercise _neighbors(int maxValue) {
    final number = maxValue <= 1 ? 1 : 1 + _random.nextInt(maxValue - 1);
    final predecessor = _random.nextBool();
    return StructuredExercise(
      mode: TrainingMode.neighbors,
      prompt: predecessor
          ? 'Was ist der Vorgänger von $number?'
          : 'Was ist der Nachfolger von $number?',
      answer: predecessor ? number - 1 : number + 1,
      hint: predecessor ? 'Gehe einen Schritt zurück.' : 'Gehe einen Schritt weiter.',
      key: 'neighbor:$number:${predecessor ? 'before' : 'after'}',
    );
  }

  StructuredExercise _placeValue(int maxValue) {
    final number = _random.nextInt(maxValue + 1);
    final tens = number ~/ 10;
    final ones = number % 10;
    return StructuredExercise(
      mode: TrainingMode.placeValue,
      prompt: '$tens Zehner und $ones Einer ergeben welche Zahl?',
      answer: number,
      hint: '$tens Zehner sind ${tens * 10}. Dazu kommen $ones Einer.',
      key: 'place:$number',
    );
  }

  StructuredExercise _doublesHalves(int maxValue) {
    final useDouble = _random.nextBool();
    if (useDouble) {
      final value = _random.nextInt(max(1, maxValue ~/ 2) + 1);
      return StructuredExercise(
        mode: TrainingMode.doublesHalves,
        prompt: 'Was ist das Doppelte von $value?',
        answer: value * 2,
        hint: 'Doppelt bedeutet: $value + $value.',
        key: 'double:$value',
      );
    }
    final half = _random.nextInt(max(1, maxValue ~/ 2) + 1);
    final value = half * 2;
    return StructuredExercise(
      mode: TrainingMode.doublesHalves,
      prompt: 'Was ist die Hälfte von $value?',
      answer: half,
      hint: 'Teile $value in zwei gleich große Teile.',
      key: 'half:$value',
    );
  }

  StructuredExercise _sequence(int maxValue) {
    var allowedSteps = [1, 2, 5, 10].where((s) => s * 3 <= maxValue).toList();
    if (allowedSteps.isEmpty) allowedSteps = [1];
    final step = allowedSteps[_random.nextInt(allowedSteps.length)];
    final backwards = _random.nextBool();
    if (backwards) {
      final minStart = step * 3;
      final start = minStart + _random.nextInt(maxValue - minStart + 1);
      return StructuredExercise(
        mode: TrainingMode.sequences,
        prompt: '$start, ${start - step}, ${start - step * 2}, ?',
        answer: start - step * 3,
        hint: 'Die Zahlen werden immer um $step kleiner.',
        key: 'sequence:-:$start:$step',
      );
    }
    final maxStart = maxValue - step * 3;
    final start = _random.nextInt(maxStart + 1);
    return StructuredExercise(
      mode: TrainingMode.sequences,
      prompt: '$start, ${start + step}, ${start + step * 2}, ?',
      answer: start + step * 3,
      hint: 'Die Zahlen werden immer um $step größer.',
      key: 'sequence:+:$start:$step',
    );
  }

  StructuredExercise _factFamily(int maxValue) {
    final useMultiply = maxValue >= 20 && _random.nextDouble() < 0.30;
    if (useMultiply) {
      final a = 1 + _random.nextInt(10);
      final possibleB = [1, 2, 3, 4, 5, 10]
          .where((b) => a * b <= maxValue)
          .toList();
      final b = possibleB.isEmpty ? 1 : possibleB[_random.nextInt(possibleB.length)];
      final product = a * b;
      return StructuredExercise(
        mode: TrainingMode.factFamilies,
        prompt: 'Wenn $a × $b = $product, dann ist $product ÷ $b = ?',
        answer: a,
        hint: 'Malnehmen und Teilen sind Umkehraufgaben.',
        key: 'family:x:$a:$b',
      );
    }

    final a = _random.nextInt(maxValue + 1);
    final b = _random.nextInt(maxValue - a + 1);
    final sum = a + b;
    return StructuredExercise(
      mode: TrainingMode.factFamilies,
      prompt: 'Wenn $a + $b = $sum, dann ist $sum − $b = ?',
      answer: a,
      hint: 'Plus und Minus sind Umkehraufgaben.',
      key: 'family:+:$a:$b',
    );
  }

  StructuredExercise _wordProblem(int maxValue) {
    final allowGroups = maxValue >= 20;
    final kind = _random.nextInt(allowGroups ? 4 : 2);

    if (kind == 0) {
      final a = 1 + _random.nextInt(maxValue);
      final b = _random.nextInt(maxValue - a + 1);
      final templates = <(String, String)>[
        ('pencils', 'In einem Mäppchen sind $a Buntstifte. $b kommen dazu. Wie viele sind es jetzt?'),
        ('books', 'Im Regal stehen $a Bücher. $b weitere werden dazugestellt. Wie viele Bücher stehen nun im Regal?'),
        ('playground', 'Auf dem Schulhof spielen $a Kinder. $b Kinder kommen dazu. Wie viele Kinder sind jetzt dort?'),
        ('stickers', 'Eine Sammlung enthält $a Sticker. Es kommen $b neue Sticker hinzu. Wie groß ist die Sammlung jetzt?'),
        ('bus', 'Im Bus sitzen $a Personen. An der nächsten Haltestelle steigen $b ein. Wie viele fahren danach mit?'),
        ('craft', 'Für ein Bastelprojekt liegen $a Perlen bereit. $b weitere werden geholt. Wie viele Perlen sind es zusammen?'),
      ];
      final template = templates[_random.nextInt(templates.length)];
      return StructuredExercise(
        mode: TrainingMode.wordProblems,
        prompt: template.$2,
        answer: a + b,
        hint: 'Die Menge wird größer. Das passt zu Plus.',
        key: 'story:+:${template.$1}:$a:$b',
      );
    }

    if (kind == 1) {
      final a = 1 + _random.nextInt(maxValue);
      final b = _random.nextInt(a + 1);
      final templates = <(String, String)>[
        ('cards', 'Auf einem Tisch liegen $a Karten. $b werden weggenommen. Wie viele bleiben liegen?'),
        ('apples', 'In einem Korb sind $a Äpfel. $b werden verteilt. Wie viele bleiben im Korb?'),
        ('library', 'Eine Kiste enthält $a Bücher. $b werden ausgeliehen. Wie viele Bücher bleiben in der Kiste?'),
        ('blocks', 'Ein Turm besteht aus $a Bausteinen. $b Bausteine werden abgebaut. Wie viele bleiben?'),
        ('marbles', 'In einem Beutel sind $a Murmeln. $b Murmeln werden herausgenommen. Wie viele sind noch im Beutel?'),
        ('seats', 'In einer Reihe sind $a Plätze besetzt. $b Kinder gehen weg. Wie viele Plätze bleiben besetzt?'),
      ];
      final template = templates[_random.nextInt(templates.length)];
      return StructuredExercise(
        mode: TrainingMode.wordProblems,
        prompt: template.$2,
        answer: a - b,
        hint: 'Die Menge wird kleiner. Das passt zu Minus.',
        key: 'story:-:${template.$1}:$a:$b',
      );
    }

    if (kind == 2) {
      final groups = 2 + _random.nextInt(7);
      final maxEach = max(1, min(10, maxValue ~/ groups));
      final each = 1 + _random.nextInt(maxEach);
      final templates = <(String, String)>[
        ('bags', '$groups Tüten enthalten jeweils $each Murmeln. Wie viele Murmeln sind es zusammen?'),
        ('tables', 'An $groups Tischen sitzen jeweils $each Kinder. Wie viele Kinder sitzen insgesamt an den Tischen?'),
        ('boxes', '$groups Schachteln enthalten jeweils $each Stifte. Wie viele Stifte sind es insgesamt?'),
        ('rows', 'Es gibt $groups Reihen mit jeweils $each Stühlen. Wie viele Stühle sind das zusammen?'),
        ('packs', '$groups Päckchen enthalten jeweils $each Karten. Wie viele Karten sind in allen Päckchen?'),
      ];
      final template = templates[_random.nextInt(templates.length)];
      return StructuredExercise(
        mode: TrainingMode.wordProblems,
        prompt: template.$2,
        answer: groups * each,
        hint: 'Gleich große Gruppen kann man mit Mal rechnen.',
        key: 'story:x:${template.$1}:$groups:$each',
      );
    }

    final groups = 2 + _random.nextInt(7);
    final maxEach = max(1, min(10, maxValue ~/ groups));
    final each = 1 + _random.nextInt(maxEach);
    final total = groups * each;
    final templates = <(String, String)>[
      ('children', '$total Bausteine werden gleichmäßig auf $groups Kinder verteilt. Wie viele bekommt jedes Kind?'),
      ('bags', '$total Bonbons werden gleichmäßig auf $groups Tüten verteilt. Wie viele Bonbons kommen in jede Tüte?'),
      ('teams', '$total Kinder werden gleichmäßig auf $groups Teams verteilt. Wie viele Kinder sind in jedem Team?'),
      ('boxes', '$total Stifte werden gleichmäßig auf $groups Schachteln verteilt. Wie viele Stifte liegen in jeder Schachtel?'),
      ('plates', '$total Kekse werden gleichmäßig auf $groups Teller verteilt. Wie viele Kekse liegen auf jedem Teller?'),
    ];
    final template = templates[_random.nextInt(templates.length)];
    return StructuredExercise(
      mode: TrainingMode.wordProblems,
      prompt: template.$2,
      answer: each,
      hint: 'Gleichmäßig verteilen passt zu Teilen.',
      key: 'story:divide:${template.$1}:$total:$groups',
    );
  }

  StructuredExercise _money(int maxValue) {
    final budget = max(2, maxValue);
    final kind = _random.nextInt(maxValue >= 100 ? 5 : 4);

    if (kind == 0) {
      final paid = 1 + _random.nextInt(budget);
      final price = _random.nextInt(paid + 1);
      final contexts = <(String, String)>[
        ('kiosk', 'Du hast $paid €. Am Kiosk gibst du $price € aus. Wie viele Euro bleiben?'),
        ('bookshop', 'Du hast $paid €. Ein Buch kostet $price €. Wie viel Geld bleibt übrig?'),
        ('market', 'Du hast $paid €. Auf dem Markt bezahlst du $price €. Wie viel bleibt?'),
      ];
      final context = contexts[_random.nextInt(contexts.length)];
      return StructuredExercise(
        mode: TrainingMode.money,
        prompt: context.$2,
        answer: paid - price,
        hint: 'Vom vorhandenen Geld wird der Preis abgezogen.',
        key: 'money:change:${context.$1}:$paid:$price',
        answerSuffix: '€',
        moneyPartsCents: _moneyPartsForEuros(paid),
      );
    }

    if (kind == 1) {
      final first = _random.nextInt(budget + 1);
      final second = _random.nextInt(budget - first + 1);
      final contexts = <(String, String)>[
        ('school', 'Ein Heft kostet $first € und ein Buch $second €. Wie viel kosten beide zusammen?'),
        ('toys', 'Ein Ball kostet $first € und ein Springseil $second €. Wie viel kosten beide zusammen?'),
        ('craft', 'Bastelpapier kostet $first € und Stifte kosten $second €. Wie hoch ist der Gesamtpreis?'),
      ];
      final context = contexts[_random.nextInt(contexts.length)];
      return StructuredExercise(
        mode: TrainingMode.money,
        prompt: context.$2,
        answer: first + second,
        hint: 'Für den Gesamtpreis werden beide Beträge addiert.',
        key: 'money:add:${context.$1}:$first:$second',
        answerSuffix: '€',
        moneyPartsCents: _moneyPartsForEuros(first + second),
      );
    }

    if (kind == 2) {
      final total = 2 + _random.nextInt(max(1, budget - 1));
      final known = _random.nextInt(total + 1);
      return StructuredExercise(
        mode: TrainingMode.money,
        prompt:
            'Zwei Dinge kosten zusammen $total €. Eines kostet $known €. Wie viel kostet das andere?',
        answer: total - known,
        hint: 'Vom Gesamtpreis wird der bekannte Preis abgezogen.',
        key: 'money:missing:item:$total:$known',
        answerSuffix: '€',
      );
    }

    if (kind == 3) {
      final value = 1 + _random.nextInt(min(20, budget));
      return StructuredExercise(
        mode: TrainingMode.money,
        prompt: 'Du legst $value Münzen zu je 1 € hin. Wie viel Geld ist das?',
        answer: value,
        hint: 'Jede Münze ist genau 1 € wert.',
        key: 'money:coins:one:$value',
        answerSuffix: '€',
        moneyPartsCents: List<int>.filled(min(value, 8), 100),
      );
    }

    final euros = 1 + _random.nextInt(min(9, max(1, budget ~/ 10)));
    return StructuredExercise(
      mode: TrainingMode.money,
      prompt: '$euros € sind wie viele Cent?',
      answer: euros * 100,
      hint: '1 € = 100 ct.',
      key: 'money:convert:euro-cent:$euros',
      answerSuffix: 'ct',
      maxAnswerValue: euros * 100,
      moneyPartsCents: _moneyPartsForEuros(euros),
    );
  }

  List<int> _moneyPartsForEuros(int value) {
    var remaining = value;
    final parts = <int>[];
    for (final euro in [20, 10, 5, 2, 1]) {
      while (remaining >= euro && parts.length < 8) {
        parts.add(euro * 100);
        remaining -= euro;
      }
    }
    return parts;
  }

  StructuredExercise _clock(int maxValue) {
    final minuteOptions = maxValue >= 100 ? [0, 15, 30, 45] : [0, 30];
    final hour = 1 + _random.nextInt(12);
    final minute = minuteOptions[_random.nextInt(minuteOptions.length)];
    final correct = _formatTime(hour, minute);
    final optionSet = <String>{correct};
    while (optionSet.length < 4) {
      final otherHour = 1 + _random.nextInt(12);
      final otherMinute = minuteOptions[_random.nextInt(minuteOptions.length)];
      optionSet.add(_formatTime(otherHour, otherMinute));
    }
    final options = optionSet.toList()..shuffle(_random);
    return StructuredExercise(
      mode: TrainingMode.clock,
      prompt: 'Welche Uhrzeit zeigt die Uhr?',
      answer: options.indexOf(correct),
      hint: 'Der kurze Zeiger zeigt die Stunde, der lange Zeiger die Minuten.',
      key: 'clock:$hour:$minute',
      choices: options,
      clockHour: hour,
      clockMinute: minute,
    );
  }

  String _formatTime(int hour, int minute) =>
      '$hour:${minute.toString().padLeft(2, '0')} Uhr';

  StructuredExercise _measures(int maxValue) {
    final kind = _random.nextInt(maxValue >= 100 ? 6 : 3);

    if (kind == 0) {
      final first = _random.nextInt(maxValue + 1);
      final second = _random.nextInt(maxValue - first + 1);
      final contexts = <(String, String)>[
        ('ribbon', 'Ein Band ist $first cm lang. Ein zweites Stück ist $second cm lang. Wie lang sind beide zusammen?'),
        ('string', 'Eine Schnur misst $first cm, eine zweite $second cm. Wie lang sind beide zusammen?'),
        ('track', 'Ein Wegstück ist $first cm lang, das nächste $second cm. Wie lang sind beide Stücke zusammen?'),
      ];
      final context = contexts[_random.nextInt(contexts.length)];
      return StructuredExercise(
        mode: TrainingMode.measures,
        prompt: context.$2,
        answer: first + second,
        hint: 'Längen mit derselben Einheit können direkt addiert werden.',
        key: 'measure:add:${context.$1}:$first:$second',
        answerSuffix: 'cm',
      );
    }

    if (kind == 1) {
      final whole = 1 + _random.nextInt(max(1, maxValue));
      final cut = _random.nextInt(whole + 1);
      return StructuredExercise(
        mode: TrainingMode.measures,
        prompt: 'Ein Seil ist $whole cm lang. $cut cm werden abgeschnitten. Wie viele cm bleiben?',
        answer: whole - cut,
        hint: 'Die abgeschnittene Länge wird von der ganzen Länge abgezogen.',
        key: 'measure:subtract:rope:$whole:$cut',
        answerSuffix: 'cm',
      );
    }

    if (kind == 2) {
      final dm = 1 + _random.nextInt(min(10, max(1, maxValue ~/ 10)));
      return StructuredExercise(
        mode: TrainingMode.measures,
        prompt: '$dm dm sind wie viele cm?',
        answer: dm * 10,
        hint: '1 dm = 10 cm.',
        key: 'measure:convert:dm-cm:$dm',
        answerSuffix: 'cm',
        maxAnswerValue: dm * 10,
      );
    }

    if (kind == 3) {
      final meters = 1 + _random.nextInt(min(9, max(1, maxValue ~/ 10)));
      return StructuredExercise(
        mode: TrainingMode.measures,
        prompt: '$meters m sind wie viele cm?',
        answer: meters * 100,
        hint: '1 m = 100 cm.',
        key: 'measure:convert:m-cm:$meters',
        answerSuffix: 'cm',
        maxAnswerValue: meters * 100,
      );
    }

    if (kind == 4) {
      final cm = 1 + _random.nextInt(9);
      return StructuredExercise(
        mode: TrainingMode.measures,
        prompt: '$cm cm sind wie viele mm?',
        answer: cm * 10,
        hint: '1 cm = 10 mm.',
        key: 'measure:convert:cm-mm:$cm',
        answerSuffix: 'mm',
        maxAnswerValue: cm * 10,
      );
    }

    final meters = 1 + _random.nextInt(9);
    final centimeters = meters * 100;
    return StructuredExercise(
      mode: TrainingMode.measures,
      prompt:
          'Ein Weg ist $centimeters cm lang. Wie viele ganze Meter sind das?',
      answer: meters,
      hint: '100 cm ergeben 1 m.',
      key: 'measure:convert:cm-m:$centimeters',
      answerSuffix: 'm',
      maxAnswerValue: meters,
    );
  }

  StructuredExercise _geometry(int maxValue) {
    final shapes = ExerciseShape.values;
    final shape = shapes[_random.nextInt(shapes.length)];
    if (_random.nextBool()) {
      final names = <ExerciseShape, String>{
        ExerciseShape.triangle: 'Dreieck',
        ExerciseShape.square: 'Quadrat',
        ExerciseShape.rectangle: 'Rechteck',
        ExerciseShape.circle: 'Kreis',
      };
      final correct = names[shape]!;
      final options = names.values.toList()..shuffle(_random);
      return StructuredExercise(
        mode: TrainingMode.geometry,
        prompt: 'Welche Form siehst du?',
        answer: options.indexOf(correct),
        hint: 'Achte auf Seiten, Ecken und die Form der Begrenzung.',
        key: 'geometry:name:${shape.name}',
        choices: options,
        shape: shape,
      );
    }

    final corners = switch (shape) {
      ExerciseShape.triangle => 3,
      ExerciseShape.square || ExerciseShape.rectangle => 4,
      ExerciseShape.circle => 0,
    };
    return StructuredExercise(
      mode: TrainingMode.geometry,
      prompt: 'Wie viele Ecken hat diese Form?',
      answer: corners,
      hint: shape == ExerciseShape.circle
          ? 'Ein Kreis hat keine Ecken.'
          : 'Zähle die Stellen, an denen zwei Seiten zusammentreffen.',
      key: 'geometry:corners:${shape.name}',
      shape: shape,
      maxAnswerValue: max(10, maxValue),
    );
  }
}
