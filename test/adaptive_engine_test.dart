import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/adaptive_engine.dart';

void main() {
  group('Aufgabenpool bis 100', () {
    final facts = AdaptiveEngine.buildFactPool(maxValue: 100);

    test('alle Ergebnisse bleiben zwischen 0 und 100', () {
      expect(facts, isNotEmpty);
      expect(facts.every((f) => f.result >= 0 && f.result <= 100), isTrue);
    });

    test('Minus erzeugt niemals negative Ergebnisse', () {
      final minus = facts.where((f) => f.operation == MathOperation.minus);
      expect(minus.every((f) => f.a >= f.b && f.result >= 0), isTrue);
    });

    test('Mal und Geteilt enthalten nur passende Grundaufgaben', () {
      final multiply = facts.where((f) => f.operation == MathOperation.multiply);
      final divide = facts.where((f) => f.operation == MathOperation.divide);
      expect(multiply.every((f) => f.a <= 10 && f.b <= 10 && f.result <= 100), isTrue);
      expect(divide.every((f) => f.b > 0 && f.a % f.b == 0 && f.a <= 100), isTrue);
    });
  });

  test('Auswahl respektiert Zahlenraum 10, 20 und 100', () {
    final engine = AdaptiveEngine(random: Random(4));
    final facts = AdaptiveEngine.buildFactPool(maxValue: 100);
    for (final maxValue in [10, 20, 100]) {
      for (var i = 0; i < 100; i++) {
        final fact = engine.selectNext(
          facts: facts,
          mode: TrainingMode.tempo,
          maxValue: maxValue,
        );
        expect(AdaptiveEngine.isValid(fact, maxValue: maxValue), isTrue);
      }
    }
  });

  test('Zahlenraum 100 beginnt weiterhin mit Grundlagen bis 10', () {
    final engine = AdaptiveEngine(random: Random(3));
    final facts = AdaptiveEngine.buildFactPool(maxValue: 100);
    expect(engine.progressionTier(facts), 1);
    for (var i = 0; i < 40; i++) {
      final fact = engine.selectNext(
        facts: facts,
        mode: TrainingMode.practice,
        maxValue: 100,
      );
      expect(engine.difficultyTier(fact), 1);
      expect(fact.a, lessThanOrEqualTo(10));
      expect(fact.b, lessThanOrEqualTo(10));
      expect(fact.result, lessThanOrEqualTo(10));
    }
  });

  test('Mastery steigt bei wiederholten schnellen richtigen Antworten', () {
    final fact = MathFact(a: 8, b: 3, operation: MathOperation.minus);
    final before = fact.masteryScore;
    for (var i = 0; i < 6; i++) {
      fact.registerAttempt(
        correct: true,
        responseTime: const Duration(milliseconds: 2200),
        usedHelp: false,
      );
    }
    expect(fact.masteryScore, greaterThan(before));
    expect(fact.masteryScore, greaterThan(0.75));
  });

  test('Hilfebedarf und Fehler halten Mastery niedrig', () {
    final fact = MathFact(a: 10, b: 6, operation: MathOperation.minus);
    for (var i = 0; i < 5; i++) {
      fact.registerAttempt(
        correct: i == 4,
        responseTime: const Duration(seconds: 9),
        usedHelp: true,
      );
    }
    expect(fact.masteryScore, lessThan(0.5));
  });

  test('Unsichere Aufgabe wird stärker gewichtet ausgewählt', () {
    final engine = AdaptiveEngine(random: Random(7));
    final weak = MathFact(a: 9, b: 5, operation: MathOperation.minus);
    final strong = MathFact(a: 8, b: 2, operation: MathOperation.minus);
    for (var i = 0; i < 7; i++) {
      strong.registerAttempt(
        correct: true,
        responseTime: const Duration(seconds: 2),
        usedHelp: false,
      );
    }
    for (var i = 0; i < 4; i++) {
      weak.registerAttempt(
        correct: false,
        responseTime: const Duration(seconds: 8),
        usedHelp: true,
      );
    }

    var weakCount = 0;
    var strongCount = 0;
    for (var i = 0; i < 400; i++) {
      final selected = engine.selectNext(
        facts: [weak, strong],
        mode: TrainingMode.minus,
        maxValue: 10,
      );
      if (selected.key == weak.key) weakCount++;
      if (selected.key == strong.key) strongCount++;
    }
    expect(weakCount, greaterThan(strongCount));
  });

  test('Minus-Anteil liegt adaptiv zwischen 50 und 75 Prozent', () {
    final engine = AdaptiveEngine(random: Random(1));
    final facts = AdaptiveEngine.buildFactPool(maxValue: 10);
    final share = engine.minusTargetShare(facts);
    expect(share, inInclusiveRange(0.50, 0.75));
    expect(share, closeTo(0.65, 0.001));
  });

  test('Minus-Anteil nähert sich bei hoher Sicherheit 50/50', () {
    final engine = AdaptiveEngine(random: Random(2));
    final facts = AdaptiveEngine.buildFactPool(maxValue: 10)
        .where((f) => f.isPlus || f.isMinus)
        .toList();
    for (final fact in facts) {
      for (var i = 0; i < 6; i++) {
        fact.registerAttempt(
          correct: true,
          responseTime: const Duration(milliseconds: 1800),
          usedHelp: false,
        );
      }
    }
    expect(engine.minusTargetShare(facts), lessThan(0.56));
  });
}
