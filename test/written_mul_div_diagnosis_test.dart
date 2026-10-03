import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/training.dart';

void main() {
  group('schriftliche Multiplikation antwortsensitiv', () {
    test('Plus statt Mal wird als Additionsverwechslung erkannt', () {
      expect(
        ErrorClassifier.classify(
          mode: TrainingMode.writtenMultiply,
          taskKey: 'written:x:23:4',
          expected: 92,
          actual: 27,
        ),
        ErrorPattern.multiplicationAsAddition,
      );
    });

    test('Minus statt Mal wird als Rechenart-Verwechslung erkannt', () {
      expect(
        ErrorClassifier.classify(
          mode: TrainingMode.writtenMultiply,
          taskKey: 'written:x:23:4',
          expected: 92,
          actual: 19,
        ),
        ErrorPattern.operationChoice,
      );
    });

    test('nicht erklärbarer Fehler bleibt beim schriftlichen Verfahren', () {
      expect(
        ErrorClassifier.classify(
          mode: TrainingMode.writtenMultiply,
          taskKey: 'written:x:23:4',
          expected: 92,
          actual: 82,
        ),
        ErrorPattern.writtenProcedure,
      );
    });
  });

  group('schriftliche Division antwortsensitiv', () {
    test('Minus statt Teilen wird konkret erkannt', () {
      expect(
        ErrorClassifier.classify(
          mode: TrainingMode.writtenDivide,
          taskKey: 'written:divide:84:7',
          expected: 12,
          actual: 77,
        ),
        ErrorPattern.divisionAsSubtraction,
      );
    });

    test('Mal statt Teilen wird als Rechenart-Verwechslung erkannt', () {
      expect(
        ErrorClassifier.classify(
          mode: TrainingMode.writtenDivide,
          taskKey: 'written:divide:84:7',
          expected: 12,
          actual: 588,
        ),
        ErrorPattern.operationChoice,
      );
    });

    test('nicht erklärbarer Quotientenfehler bleibt beim Verfahren', () {
      expect(
        ErrorClassifier.classify(
          mode: TrainingMode.writtenDivide,
          taskKey: 'written:divide:84:7',
          expected: 12,
          actual: 13,
        ),
        ErrorPattern.writtenProcedure,
      );
    });

    test('Rest-Aufgabe wird ohne erfundene Signatur konservativ behandelt', () {
      expect(
        ErrorClassifier.classify(
          mode: TrainingMode.writtenDivide,
          taskKey: 'written:divide-rest:86:7',
          expected: 1,
          actual: 0,
        ),
        ErrorPattern.writtenProcedure,
      );
    });
  });
}
