import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/training.dart';

void main() {
  group('Wahrscheinlichkeitsdiagnose folgt der beobachtbaren Teilanforderung', () {
    ErrorPattern? classify(String key, int expected, int actual) =>
        ErrorClassifier.classify(
          mode: TrainingMode.probability,
          taskKey: key,
          expected: expected,
          actual: actual,
        );

    test('sicher/möglich/unmöglich erhält eigenes Diagnoseziel', () {
      expect(
        classify('prob:sure:below:8', 0, 1),
        ErrorPattern.probabilityEventClass,
      );
      expect(
        classify('prob:possible:face:4', 1, 2),
        ErrorPattern.probabilityEventClass,
      );
      expect(
        classify('prob:impossible:face:9', 2, 1),
        ErrorPattern.probabilityEventClass,
      );
    });

    test('Mengenvergleich im Beutel erhält eigenes Diagnoseziel', () {
      expect(
        classify('prob:bag:kugeln:7:3', 0, 1),
        ErrorPattern.probabilityChanceComparison,
      );
      expect(
        classify('prob:bag:spielsteine:4:4', 2, 0),
        ErrorPattern.probabilityChanceComparison,
      );
    });

    test('Spinner-Transfer bleibt Chancenvergleich', () {
      expect(
        classify('prob:bag:spinner:3:7:transfer', 1, 0),
        ErrorPattern.probabilityChanceComparison,
      );
    });

    test('beobachtete Versuchshäufigkeit wird nicht mit Chance vermischt', () {
      expect(
        classify('prob:experiment:compare:30:18:12', 0, 1),
        ErrorPattern.probabilityExperimentComparison,
      );
    });

    test('relative Häufigkeit erhält eigenes Diagnoseziel', () {
      expect(
        classify('prob:experiment:relative:20:8', 2, 1),
        ErrorPattern.probabilityRelativeFrequency,
      );
      expect(
        classify('prob:experiment:relative:20:8:transfer', 2, 0),
        ErrorPattern.probabilityRelativeFrequency,
      );
    });

    test('unbekannter Probability-Key bleibt konservativ allgemein', () {
      expect(
        classify('prob:future:unknown', 1, 0),
        ErrorPattern.probabilityReasoning,
      );
    });
  });
}
