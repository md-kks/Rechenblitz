import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/math_fact.dart';

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

  test('Antwortzeit-Ausreißer werden bei 30 Sekunden begrenzt', () {
    final fact = MathFact(a: 5, b: 2, operation: MathOperation.plus);
    fact.registerAttempt(
      correct: true,
      responseTime: const Duration(minutes: 4),
      usedHelp: false,
    );
    expect(fact.lastResponseMs, 30000);
  });
}
