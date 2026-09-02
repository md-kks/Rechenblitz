import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/training.dart';

void main() {
  test('MathFact JSON roundtrip erhält Statistik', () {
    final fact = MathFact(a: 8, b: 5, operation: MathOperation.minus);
    fact.registerAttempt(
      correct: true,
      responseTime: const Duration(milliseconds: 4200),
      usedHelp: false,
    );
    final restored = MathFact.fromJson(fact.toJson());
    expect(restored.key, fact.key);
    expect(restored.correctAttempts, 1);
    expect(restored.lastResponseMs, 4200);
  });

  test('Mal- und Geteilt-Aufgaben berechnen das Ergebnis korrekt', () {
    final multiply = MathFact(a: 7, b: 8, operation: MathOperation.multiply);
    final divide = MathFact(a: 56, b: 8, operation: MathOperation.divide);
    expect(multiply.result, 56);
    expect(divide.result, 7);
    expect(multiply.symbol, '×');
    expect(divide.symbol, '÷');
  });

  test('Antwortzeit-Ausreißer werden bei 30 Sekunden begrenzt', () {
    final fact = MathFact(a: 5, b: 2, operation: MathOperation.plus);
    fact.registerAttempt(
      correct: true,
      responseTime: const Duration(minutes: 4),
      usedHelp: false,
    );
    expect(fact.lastResponseMs, 30000);
  });

  test('alte Sitzungsdaten bleiben ohne neue Felder lesbar', () {
    final restored = TrainingSessionResult.fromJson({
      'mode': 'practice',
      'startedAt': '2026-09-01T10:00:00.000',
      'finishedAt': '2026-09-01T10:05:00.000',
      'total': 10,
      'correctFirstTry': 8,
      'incorrectAttempts': 2,
      'plusCorrect': 4,
      'plusTotal': 5,
      'minusCorrect': 4,
      'minusTotal': 5,
      'averageResponseMs': 3200,
    });
    expect(restored.numberRange, NumberRangeLevel.ten);
    expect(restored.starsEarned, 1);
    expect(restored.multiplyTotal, 0);
  });
}
