import 'dart:math';

import '../models/micro_competency.dart';
import '../models/training.dart';
import '../models/task_diversity.dart';

enum ExerciseShape { triangle, square, rectangle, circle }

enum ExerciseRepresentation { placeValue, equalGroups }

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
    this.representation,
    this.representationA,
    this.representationB,
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
  final ExerciseRepresentation? representation;
  final int? representationA;
  final int? representationB;

  bool get isNumberWall => wallValues != null && hiddenWallIndex != null;
  bool get usesChoices => choices != null && choices!.isNotEmpty;
  bool get hasClock => clockHour != null && clockMinute != null;
  bool get hasMoneyVisual =>
      moneyPartsCents != null && moneyPartsCents!.isNotEmpty;
  bool get hasRepresentationVisual => switch (representation) {
        ExerciseRepresentation.placeValue => representationA != null,
        ExerciseRepresentation.equalGroups =>
          representationA != null && representationB != null,
        null => false,
      };
}

class StructuredExerciseGenerator {
  StructuredExerciseGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  StructuredExercise generate({
    required TrainingMode mode,
    required int maxValue,
    Iterable<String> recentKeys = const <String>[],
    MicroCompetencyId? targetCompetency,
    GradeLevel gradeLevel = GradeLevel.second,
    bool transferEmphasis = false,
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
      final candidate = _generateOnce(
        mode: mode,
        maxValue: maxValue,
        gradeLevel: gradeLevel,
        transferEmphasis: transferEmphasis,
        targetCompetency: targetCompetency,
      );
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
    return firstExactNew ??
        last ??
        _generateOnce(
          mode: mode,
          maxValue: maxValue,
          gradeLevel: gradeLevel,
          transferEmphasis: transferEmphasis,
          targetCompetency: targetCompetency,
        );
  }

  StructuredExercise _generateOnce({
    required TrainingMode mode,
    required int maxValue,
    required GradeLevel gradeLevel,
    required bool transferEmphasis,
    required MicroCompetencyId? targetCompetency,
  }) =>
      switch (mode) {
        TrainingMode.numberWall => _numberWall(maxValue),
        TrainingMode.missingNumber => _missingNumber(maxValue),
        TrainingMode.neighbors => _neighbors(maxValue),
        TrainingMode.placeValue => _placeValue(maxValue),
        TrainingMode.doublesHalves => _doublesHalves(maxValue),
        TrainingMode.sequences => _sequence(maxValue),
        TrainingMode.factFamilies => _factFamily(maxValue),
        TrainingMode.wordProblems => _wordProblem(
            maxValue,
            gradeLevel,
            transferEmphasis,
            targetCompetency,
          ),
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

  StructuredExercise _wordProblem(
    int maxValue,
    GradeLevel gradeLevel,
    bool transferEmphasis,
    MicroCompetencyId? targetCompetency,
  ) {
    if (targetCompetency == MicroCompetencyId.representationTranslation) {
      return _representationTranslation(
        maxValue,
        gradeLevel,
      );
    }

    const modelingTargets = {
      MicroCompetencyId.wordProblemRelevantInformation,
      MicroCompetencyId.wordProblemOperation,
      MicroCompetencyId.wordProblemModel,
      MicroCompetencyId.wordProblemCalculation,
      MicroCompetencyId.wordProblemInterpretation,
    };
    if (targetCompetency != null &&
        modelingTargets.contains(targetCompetency)) {
      return _targetedWordProblem(
        maxValue,
        gradeLevel,
        targetCompetency,
      );
    }

    if (gradeLevel.index >= GradeLevel.third.index &&
        (transferEmphasis || _random.nextDouble() < 0.45)) {
      return _advancedWordProblem(maxValue);
    }

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

  StructuredExercise _representationTranslation(
    int maxValue,
    GradeLevel gradeLevel,
  ) {
    final limit = max(10, maxValue);
    final allowGroups =
        gradeLevel.index >= GradeLevel.second.index && limit >= 20;
    final kind = _random.nextInt(allowGroups ? 4 : 2);

    if (kind == 0) {
      final number = _between(1, limit);
      final correct = '$number';
      final choices = _numberRepresentationChoices(number, limit)
          .map((value) => '$value')
          .toList();
      return _choiceStory(
        prompt: 'Welche Zahl zeigt die Stellenwertdarstellung?',
        hint:
            'Lies die Stellen von links nach rechts und achte auch auf Stellen mit 0.',
        key: 'process:representation:place:$number',
        correct: correct,
        choices: choices,
        maxAnswerValue: 3,
        representation: ExerciseRepresentation.placeValue,
        representationA: number,
      );
    }

    if (kind == 1) {
      final number = _between(1, limit);
      final correct = _expandedNumber(number);
      final choices = _numberRepresentationChoices(number, limit)
          .map(_expandedNumber)
          .toList();
      return _choiceStory(
        prompt: 'Welche Zerlegung passt zur Stellenwertdarstellung?',
        hint:
            'Jede Ziffer steht für ihren Stellenwert: Einer, Zehner, Hunderter und so weiter.',
        key: 'process:representation:decompose:$number',
        correct: correct,
        choices: choices,
        maxAnswerValue: 3,
        representation: ExerciseRepresentation.placeValue,
        representationA: number,
      );
    }

    final groups = _between(2, min(5, max(2, limit ~/ 2)));
    final maxEach = min(5, max(2, limit ~/ groups));
    final each = _between(2, maxEach);

    if (kind == 2) {
      final correct = '$groups × $each';
      return _choiceStory(
        prompt: 'Welche Rechnung beschreibt das Punktefeld?',
        hint:
            'Zähle zuerst die gleich großen Gruppen und dann die Punkte in jeder Gruppe.',
        key: 'process:representation:groups:$groups:$each',
        correct: correct,
        choices: [
          correct,
          '$groups + $each',
          '${groups + 1} × $each',
          '$groups × ${each + 1}',
        ],
        maxAnswerValue: 3,
        representation: ExerciseRepresentation.equalGroups,
        representationA: groups,
        representationB: each,
      );
    }

    final correct = '$groups Gruppen mit je $each Punkten';
    return _choiceStory(
      prompt: 'Welche Darstellung passt zu $groups × $each?',
      hint:
          'Der erste Faktor sagt, wie viele gleich große Gruppen es gibt. Der zweite sagt, wie viele in jeder Gruppe sind.',
      key: 'process:representation:equation:$groups:$each',
      correct: correct,
      choices: [
        correct,
        '${groups + 1} Gruppen mit je $each Punkten',
        '$groups Gruppen mit je ${each + 1} Punkten',
        '$groups Gruppen mit je ${max(1, each - 1)} Punkten',
      ],
      maxAnswerValue: 3,
    );
  }

  List<int> _numberRepresentationChoices(int correct, int limit) {
    final values = <int>{correct};
    const offsets = [1, -1, 10, -10, 100, -100, 1000, -1000];
    for (final offset in offsets) {
      final candidate = correct + offset;
      if (candidate >= 0 && candidate <= limit) {
        values.add(candidate);
      }
      if (values.length >= 4) break;
    }
    while (values.length < 4) {
      values.add(_random.nextInt(limit + 1));
    }
    return values.take(4).toList();
  }

  String _expandedNumber(int number) {
    if (number == 0) return '0';
    final parts = <String>[];
    var remaining = number;
    var place = 1;
    while (remaining > 0) {
      final digit = remaining % 10;
      if (digit != 0) {
        parts.add('${digit * place}');
      }
      remaining ~/= 10;
      place *= 10;
    }
    return parts.reversed.join(' + ');
  }

  StructuredExercise _targetedWordProblem(
    int maxValue,
    GradeLevel gradeLevel,
    MicroCompetencyId targetCompetency,
  ) =>
      switch (targetCompetency) {
        MicroCompetencyId.wordProblemRelevantInformation =>
          _relevantInformationWordProblem(maxValue),
        MicroCompetencyId.wordProblemOperation =>
          _operationWordProblem(maxValue, gradeLevel),
        MicroCompetencyId.wordProblemModel =>
          _equationWordProblem(maxValue, gradeLevel),
        MicroCompetencyId.wordProblemCalculation =>
          _calculationWordProblem(maxValue, gradeLevel),
        MicroCompetencyId.wordProblemInterpretation =>
          _interpretationWordProblem(maxValue),
        _ => _calculationWordProblem(maxValue, gradeLevel),
      };

  StructuredExercise _relevantInformationWordProblem(int maxValue) {
    final limit = max(10, maxValue);
    final kind = _random.nextInt(3);

    if (kind == 0) {
      final children = _between(2, min(8, limit - 2));
      final adults = _between(1, min(4, limit - children));
      final balls = _between(1, min(5, limit));
      final correct = '$children Kinder und $adults Erwachsene';
      return _choiceStory(
        prompt:
            'Zu einem Ausflug fahren $children Kinder und $adults Erwachsene mit. Außerdem werden $balls Bälle eingepackt. Welche Angaben brauchst du, um herauszufinden, wie viele Personen mitfahren?',
        hint:
            'Achte auf die Frage nach Personen. Gegenstände brauchst du dafür nicht.',
        key: 'story:info:trip:$children:$adults:$balls',
        correct: correct,
        choices: [
          correct,
          '$children Kinder und $balls Bälle',
          '$adults Erwachsene und $balls Bälle',
          'Nur die $balls Bälle',
        ],
        maxAnswerValue: limit,
      );
    }

    if (kind == 1) {
      final red = _between(2, min(7, limit - 2));
      final blue = _between(1, min(5, limit - red));
      final boxes = _between(1, min(4, limit));
      final correct = '$red rote und $blue blaue Stifte';
      return _choiceStory(
        prompt:
            'In einem Fach liegen $red rote und $blue blaue Stifte. Daneben stehen $boxes leere Schachteln. Welche Angaben brauchst du, um die Anzahl aller Stifte zu bestimmen?',
        hint:
            'Gesucht ist die Anzahl der Stifte. Die leeren Schachteln ändern diese Anzahl nicht.',
        key: 'story:info:pencils:$red:$blue:$boxes',
        correct: correct,
        choices: [
          correct,
          '$red rote Stifte und $boxes Schachteln',
          '$blue blaue Stifte und $boxes Schachteln',
          'Nur die $boxes Schachteln',
        ],
        maxAnswerValue: limit,
      );
    }

    final first = _between(2, min(8, limit - 2));
    final second = _between(1, min(6, limit - first));
    final pages = _between(2, min(9, limit));
    final correct = '$first und $second Kinder';
    return _choiceStory(
      prompt:
          'In zwei Gruppen spielen $first und $second Kinder. Ein Buch daneben hat $pages Seiten im ersten Kapitel. Welche Angaben brauchst du für die Frage: Wie viele Kinder spielen zusammen?',
      hint:
          'Für die Frage nach Kindern zählen nur die beiden Kindergruppen.',
      key: 'story:info:groups:$first:$second:$pages',
      correct: correct,
      choices: [
        correct,
        '$first Kinder und $pages Seiten',
        '$second Kinder und $pages Seiten',
        'Nur die $pages Seiten',
      ],
      maxAnswerValue: limit,
    );
  }

  StructuredExercise _operationWordProblem(
    int maxValue,
    GradeLevel gradeLevel,
  ) {
    final limit = max(10, maxValue);
    final allowGroups =
        gradeLevel.index >= GradeLevel.second.index && limit >= 20;
    final operationChoices = gradeLevel == GradeLevel.first
        ? const ['Plus (+)', 'Minus (−)']
        : const ['Plus (+)', 'Minus (−)', 'Mal (×)', 'Geteilt (÷)'];
    final kind = _random.nextInt(allowGroups ? 4 : 2);

    if (kind == 0) {
      final a = _between(1, max(1, limit - 1));
      final b = _between(1, max(1, limit - a));
      return _choiceStory(
        prompt:
            'In einer Kiste liegen $a Bausteine. $b Bausteine kommen dazu. Welche Rechenart passt?',
        hint: 'Die Menge wird größer.',
        key: 'story:operation:+:$a:$b',
        correct: 'Plus (+)',
        choices: operationChoices,
        maxAnswerValue: limit,
      );
    }

    if (kind == 1) {
      final a = _between(2, limit);
      final b = _between(1, a - 1);
      return _choiceStory(
        prompt:
            'In einem Korb liegen $a Äpfel. $b werden herausgenommen. Welche Rechenart passt?',
        hint: 'Die Menge wird kleiner.',
        key: 'story:operation:-:$a:$b',
        correct: 'Minus (−)',
        choices: operationChoices,
        maxAnswerValue: limit,
      );
    }

    final groups = _between(2, min(6, max(2, limit ~/ 2)));
    final each = _between(2, min(8, max(2, limit ~/ groups)));
    if (kind == 2) {
      return _choiceStory(
        prompt:
            '$groups Tüten enthalten jeweils $each Murmeln. Welche Rechenart passt, um die Gesamtzahl zu bestimmen?',
        hint: 'Gleich große Gruppen passen zu Mal.',
        key: 'story:operation:x:$groups:$each',
        correct: 'Mal (×)',
        choices: operationChoices,
        maxAnswerValue: limit,
      );
    }

    final total = groups * each;
    return _choiceStory(
      prompt:
          '$total Karten werden gleichmäßig auf $groups Kinder verteilt. Welche Rechenart passt, um den Anteil pro Kind zu bestimmen?',
      hint: 'Gleichmäßig verteilen passt zu Geteilt.',
      key: 'story:operation:divide:$total:$groups',
      correct: 'Geteilt (÷)',
      choices: operationChoices,
      maxAnswerValue: limit,
    );
  }

  StructuredExercise _equationWordProblem(
    int maxValue,
    GradeLevel gradeLevel,
  ) {
    final limit = max(10, maxValue);
    final allowGroups =
        gradeLevel.index >= GradeLevel.second.index && limit >= 20;
    final kind = _random.nextInt(allowGroups ? 4 : 2);

    if (kind == 0) {
      final a = _between(1, max(1, limit - 1));
      final b = _between(1, max(1, limit - a));
      final correct = '$a + $b';
      return _choiceStory(
        prompt:
            'Auf dem Schulhof spielen $a Kinder. $b Kinder kommen dazu. Welche Rechnung passt?',
        hint: 'Beide Kindergruppen werden zusammengezählt.',
        key: 'story:equation:+:$a:$b',
        correct: correct,
        choices: gradeLevel == GradeLevel.first
            ? [
                correct,
                '$a − $b',
                '$a + ${max(0, b - 1)}',
                '${max(0, a - 1)} + $b',
              ]
            : [
                correct,
                '$a − $b',
                '$a × $b',
                '$a + ${b + 1}',
              ],
        maxAnswerValue: limit,
      );
    }

    if (kind == 1) {
      final a = _between(2, limit);
      final b = _between(1, a - 1);
      final correct = '$a − $b';
      return _choiceStory(
        prompt:
            'In einer Schachtel sind $a Karten. $b Karten werden weggenommen. Welche Rechnung passt?',
        hint: 'Von der Anfangsmenge wird die weggenommene Menge abgezogen.',
        key: 'story:equation:-:$a:$b',
        correct: correct,
        choices: [correct, '$a + $b', '$b − $a', '$a − ${max(0, b - 1)}'],
        maxAnswerValue: limit,
      );
    }

    final groups = _between(2, min(6, max(2, limit ~/ 2)));
    final each = _between(2, min(8, max(2, limit ~/ groups)));
    if (kind == 2) {
      final correct = '$groups × $each';
      return _choiceStory(
        prompt:
            '$groups Reihen haben jeweils $each Stühle. Welche Rechnung passt zur Gesamtzahl der Stühle?',
        hint: 'Gleich große Gruppen werden miteinander vervielfacht.',
        key: 'story:equation:x:$groups:$each',
        correct: correct,
        choices: [
          correct,
          '$groups + $each',
          '${groups * each} − $each',
          '$each ÷ $groups',
        ],
        maxAnswerValue: limit,
      );
    }

    final total = groups * each;
    final correct = '$total ÷ $groups';
    return _choiceStory(
      prompt:
          '$total Stifte werden gleichmäßig auf $groups Schachteln verteilt. Welche Rechnung passt für die Anzahl pro Schachtel?',
      hint: 'Die Gesamtmenge wird auf gleich große Gruppen verteilt.',
      key: 'story:equation:divide:$total:$groups',
      correct: correct,
      choices: [
        correct,
        '$total − $groups',
        '$total + $groups',
        '$groups ÷ $total',
      ],
      maxAnswerValue: limit,
    );
  }

  StructuredExercise _calculationWordProblem(
    int maxValue,
    GradeLevel gradeLevel,
  ) {
    final limit = max(10, maxValue);
    final allowGroups =
        gradeLevel.index >= GradeLevel.second.index && limit >= 20;
    final kind = _random.nextInt(allowGroups ? 4 : 2);

    if (kind == 0) {
      final a = _between(1, max(1, limit - 1));
      final b = _between(1, max(1, limit - a));
      return StructuredExercise(
        mode: TrainingMode.wordProblems,
        prompt:
            'Mara hat $a Sticker und bekommt $b Sticker dazu. Wie viele Sticker hat sie jetzt?',
        answer: a + b,
        hint: 'Die passende Rechnung ist $a + $b.',
        key: 'story:calc:+:$a:$b',
        maxAnswerValue: limit,
      );
    }

    if (kind == 1) {
      final a = _between(2, limit);
      final b = _between(1, a - 1);
      return StructuredExercise(
        mode: TrainingMode.wordProblems,
        prompt:
            'Auf einem Tisch liegen $a Karten. $b Karten werden weggenommen. Wie viele bleiben?',
        answer: a - b,
        hint: 'Die passende Rechnung ist $a − $b.',
        key: 'story:calc:-:$a:$b',
        maxAnswerValue: limit,
      );
    }

    final groups = _between(2, min(6, max(2, limit ~/ 2)));
    final each = _between(2, min(8, max(2, limit ~/ groups)));
    if (kind == 2) {
      return StructuredExercise(
        mode: TrainingMode.wordProblems,
        prompt:
            '$groups Schachteln enthalten jeweils $each Stifte. Wie viele Stifte sind es zusammen?',
        answer: groups * each,
        hint: 'Die passende Rechnung ist $groups × $each.',
        key: 'story:calc:x:$groups:$each',
        maxAnswerValue: limit,
      );
    }

    final total = groups * each;
    return StructuredExercise(
      mode: TrainingMode.wordProblems,
      prompt:
          '$total Bonbons werden gleichmäßig auf $groups Tüten verteilt. Wie viele Bonbons kommen in jede Tüte?',
      answer: each,
      hint: 'Die passende Rechnung ist $total ÷ $groups.',
      key: 'story:calc:divide:$total:$groups',
      maxAnswerValue: limit,
    );
  }

  StructuredExercise _interpretationWordProblem(int maxValue) {
    final limit = max(10, maxValue);
    final subtract = _random.nextBool();

    if (!subtract) {
      final a = _between(1, max(1, limit - 1));
      final b = _between(1, max(1, limit - a));
      final result = a + b;
      final correct = 'Mara hat jetzt $result Sticker.';
      return _choiceStory(
        prompt:
            'Mara hat $a Sticker und bekommt $b dazu. Die Rechnung $a + $b = $result ist schon gelöst. Welche Antwort passt zur Situation?',
        hint: 'Beziehe die Zahl $result auf die Frage und auf die Sticker.',
        key: 'story:interpret:+:$a:$b:$result',
        correct: correct,
        choices: [
          correct,
          'Mara hat $result Sticker abgegeben.',
          'Es kommen noch $result Sticker dazu.',
          'Im Raum sind $result Kinder.',
        ],
        maxAnswerValue: limit,
      );
    }

    final a = _between(2, limit);
    final b = _between(1, a - 1);
    final result = a - b;
    final correct = 'Es bleiben $result Karten übrig.';
    return _choiceStory(
      prompt:
          'Auf dem Tisch liegen $a Karten. $b werden weggenommen. Die Rechnung $a − $b = $result ist schon gelöst. Welche Antwort passt zur Situation?',
      hint: 'Das Ergebnis beschreibt die Karten, die nach dem Wegnehmen übrig bleiben.',
      key: 'story:interpret:-:$a:$b:$result',
      correct: correct,
      choices: [
        correct,
        'Es wurden $result Karten weggenommen.',
        'Am Anfang lagen $result Karten dort.',
        'Es kommen $result Karten dazu.',
      ],
      maxAnswerValue: limit,
    );
  }

  StructuredExercise _choiceStory({
    required String prompt,
    required String hint,
    required String key,
    required String correct,
    required List<String> choices,
    required int maxAnswerValue,
    ExerciseRepresentation? representation,
    int? representationA,
    int? representationB,
  }) {
    final shuffled = [...choices]..shuffle(_random);
    return StructuredExercise(
      mode: TrainingMode.wordProblems,
      prompt: prompt,
      answer: shuffled.indexOf(correct),
      hint: hint,
      key: key,
      choices: shuffled,
      maxAnswerValue: maxAnswerValue,
      representation: representation,
      representationA: representationA,
      representationB: representationB,
    );
  }

  StructuredExercise _advancedWordProblem(int maxValue) {
    final safeMax = max(30, maxValue);
    final kind = _random.nextInt(5);

    if (kind == 0) {
      final start = _between(15, min(250, safeMax));
      final add = _between(2, min(60, max(2, safeMax - start)));
      final afterAdd = start + add;
      final remove = _between(1, min(afterAdd, max(2, add + 15)));
      return StructuredExercise(
        mode: TrainingMode.wordProblems,
        prompt:
            'In der Schulbibliothek stehen $start Bücher in einem Regal. $add neue Bücher werden einsortiert. Später werden $remove Bücher ausgeliehen. Wie viele Bücher stehen danach im Regal?',
        answer: afterAdd - remove,
        hint:
            'Es passieren zwei Dinge nacheinander: zuerst wird die Menge größer, danach kleiner.',
        key: 'story:multi:library:$start:$add:$remove',
        maxAnswerValue: safeMax,
      );
    }

    if (kind == 1) {
      final groups = _between(3, 8);
      final each = _between(2, 10);
      final total = groups * each;
      final used = _between(1, min(total - 1, max(2, each + 3)));
      return StructuredExercise(
        mode: TrainingMode.wordProblems,
        prompt:
            '$groups Schachteln enthalten jeweils $each Kreidestücke. Für den Unterricht werden $used Kreidestücke verbraucht. Wie viele Kreidestücke bleiben insgesamt?',
        answer: total - used,
        hint:
            'Berechne zuerst die Gesamtmenge in allen Schachteln und ziehe danach die verbrauchten Stücke ab.',
        key: 'story:multi:boxes:$groups:$each:$used',
        maxAnswerValue: max(100, safeMax),
      );
    }

    if (kind == 2) {
      final children = _between(18, min(80, safeMax));
      final adults = _between(2, 12);
      final balls = _between(3, 15);
      final needed = children + adults;
      final options = [
        '$children + $adults',
        '$children + $balls',
        '$adults + $balls',
        '$children − $adults',
      ];
      return StructuredExercise(
        mode: TrainingMode.wordProblems,
        prompt:
            'Zu einem Ausflug fahren $children Kinder und $adults Erwachsene mit. Außerdem werden $balls Bälle eingepackt. Wie viele Personen fahren mit? Welche Rechnung passt?',
        answer: 0,
        hint:
            'Die Bälle sind für die Frage nach Personen eine unnötige Information.',
        key: 'story:transfer:irrelevant:$children:$adults:$balls',
        choices: options,
        maxAnswerValue: needed,
      );
    }

    if (kind == 3) {
      final first = _between(20, min(180, safeMax));
      final difference = _between(3, min(50, first));
      final second = first - difference;
      return StructuredExercise(
        mode: TrainingMode.wordProblems,
        prompt:
            'Eine Klasse sammelt $first Kastanien, eine andere $second. Um wie viele Kastanien hat die erste Klasse mehr gesammelt?',
        answer: difference,
        hint:
            '„Um wie viele mehr?“ fragt nach dem Unterschied zwischen zwei Mengen.',
        key: 'story:transfer:difference:$first:$second',
        maxAnswerValue: safeMax,
      );
    }

    final finalAmount = _between(12, min(120, safeMax));
    final gaveAway = _between(2, min(30, finalAmount));
    final start = finalAmount + gaveAway;
    return StructuredExercise(
      mode: TrainingMode.wordProblems,
      prompt:
          'Nach dem Verschenken von $gaveAway Stickern sind noch $finalAmount Sticker übrig. Wie viele Sticker waren vorher da?',
      answer: start,
      hint:
          'Denke rückwärts: Zur Restmenge müssen die verschenkten Sticker wieder dazugerechnet werden.',
      key: 'story:transfer:reverse:$finalAmount:$gaveAway',
      maxAnswerValue: max(safeMax, start),
    );
  }

  int _between(int low, int high) =>
      high <= low ? low : low + _random.nextInt(high - low + 1);

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
