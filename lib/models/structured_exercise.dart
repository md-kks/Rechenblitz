import 'dart:math';

import '../models/training.dart';

class StructuredExercise {
  const StructuredExercise({
    required this.mode,
    required this.prompt,
    required this.answer,
    required this.hint,
    required this.key,
    this.wallValues,
    this.hiddenWallIndex,
  });

  final TrainingMode mode;
  final String prompt;
  final int answer;
  final String hint;
  final String key;
  final List<int>? wallValues;
  final int? hiddenWallIndex;

  bool get isNumberWall => wallValues != null && hiddenWallIndex != null;
}

class StructuredExerciseGenerator {
  StructuredExerciseGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  StructuredExercise generate({
    required TrainingMode mode,
    required int maxValue,
  }) => switch (mode) {
        TrainingMode.numberWall => _numberWall(maxValue),
        TrainingMode.missingNumber => _missingNumber(maxValue),
        TrainingMode.neighbors => _neighbors(maxValue),
        TrainingMode.placeValue => _placeValue(maxValue),
        TrainingMode.doublesHalves => _doublesHalves(maxValue),
        TrainingMode.sequences => _sequence(maxValue),
        TrainingMode.factFamilies => _factFamily(maxValue),
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
}
