import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/training.dart';

void main() {
  group('Bruchdiagnose folgt beweisbaren Fehlantworten', () {
    test('3/4: nur einen Viertelteil berechnet', () {
      expect(ErrorClassifier.classify(mode: TrainingMode.fractions, taskKey: 'fraction:parts:3:4:20', expected: 15, actual: 5), ErrorPattern.fractionPartCount);
    });
    test('3/4: Zähler statt gesuchtem Wert angegeben', () {
      expect(ErrorClassifier.classify(mode: TrainingMode.fractions, taskKey: 'fraction:parts:3:4:20', expected: 15, actual: 3), ErrorPattern.fractionPartCount);
    });
    test('3/4: Nenner statt gesuchtem Wert angegeben', () {
      expect(ErrorClassifier.classify(mode: TrainingMode.fractions, taskKey: 'fraction:parts:3:4:20', expected: 15, actual: 4), ErrorPattern.fractionPartCount);
    });
    test('1/4: multipliziert statt geteilt', () {
      expect(ErrorClassifier.classify(mode: TrainingMode.fractions, taskKey: 'fraction:quarter:20', expected: 5, actual: 80), ErrorPattern.operationChoice);
    });
    test('1/2: unklare Fehlzahl bleibt beim einzelnen Bruchteil', () {
      expect(ErrorClassifier.classify(mode: TrainingMode.fractions, taskKey: 'fraction:half:20', expected: 10, actual: 9), ErrorPattern.fractionSinglePart);
    });
    test('mehrteiliger Bruch: unklare Fehlzahl bleibt allgemein', () {
      expect(ErrorClassifier.classify(mode: TrainingMode.fractions, taskKey: 'fraction:parts:3:4:20', expected: 15, actual: 14), ErrorPattern.fractionPart);
    });
    test('Zeit- und Liter-Auswahlindex wird nicht überinterpretiert', () {
      for (final entry in [('fraction:time', 2, 0), ('fraction:volume', 0, 2)]) {
        expect(ErrorClassifier.classify(mode: TrainingMode.fractions, taskKey: entry.$1, expected: entry.$2, actual: entry.$3), ErrorPattern.fractionPart);
      }
    });
  });
}
