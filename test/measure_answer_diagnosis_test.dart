import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/training.dart';

void main() {
  group('Größenrechnungen unterscheiden Rechenart von Umrechnung', () {
    test('Bandstücke addieren: Minusantwort erkennt Rechenart-Verwechslung', () {
      expect(
        ErrorClassifier.classify(
          mode: TrainingMode.measures,
          taskKey: 'measure:add:ribbon:7:5',
          expected: 12,
          actual: 2,
        ),
        ErrorPattern.operationChoice,
      );
    });

    test('Seil abschneiden: Plusantwort erkennt Rechenart-Verwechslung', () {
      expect(
        ErrorClassifier.classify(
          mode: TrainingMode.measures,
          taskKey: 'measure:subtract:rope:12:5',
          expected: 7,
          actual: 17,
        ),
        ErrorPattern.operationChoice,
      );
    });

    test('unklarer Rechenfehler wird nicht als Rechenart erfunden', () {
      expect(
        ErrorClassifier.classify(
          mode: TrainingMode.measures,
          taskKey: 'measure:add:string:7:5',
          expected: 12,
          actual: 11,
        ),
        ErrorPattern.measurementCalculation,
      );
    });
  });

  group('echte Einheitenumrechnungen bleiben gezielt', () {
    final cases = <({String key, int expected, int actual})>[
      (key: 'measure:convert:dm-cm:4', expected: 40, actual: 4),
      (key: 'measure:convert:m-cm:3', expected: 300, actual: 30),
      (key: 'measure:convert:cm-mm:8', expected: 80, actual: 8),
      (key: 'measure:convert:cm-m:500', expected: 5, actual: 500),
    ];

    for (final item in cases) {
      test(item.key, () {
        expect(
          ErrorClassifier.classify(
            mode: TrainingMode.measures,
            taskKey: item.key,
            expected: item.expected,
            actual: item.actual,
          ),
          ErrorPattern.unitConversion,
        );
      });
    }

    test('60er-Beziehung Sekunden bleibt Einheitenumrechnung', () {
      expect(
        ErrorClassifier.classify(
          mode: TrainingMode.advancedMeasures,
          taskKey: 'time:seconds:min-to-sec:4',
          expected: 240,
          actual: 400,
        ),
        ErrorPattern.unitConversion,
      );
    });
  });
}
