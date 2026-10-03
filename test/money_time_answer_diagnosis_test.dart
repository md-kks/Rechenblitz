import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/training.dart';

void main() {
  group('Geldfehler werden nach Ursache getrennt', () {
    test('Gesamtpreis: Minus statt Plus ist Rechenart-Verwechslung', () {
      expect(
        ErrorClassifier.classify(
          mode: TrainingMode.money,
          taskKey: 'money:add:school:7:5',
          expected: 12,
          actual: 2,
        ),
        ErrorPattern.operationChoice,
      );
    });

    test('Rückgeld: Plus statt Minus ist Rechenart-Verwechslung', () {
      expect(
        ErrorClassifier.classify(
          mode: TrainingMode.money,
          taskKey: 'money:change:kiosk:12:5',
          expected: 7,
          actual: 17,
        ),
        ErrorPattern.operationChoice,
      );
    });

    test('fehlender Preis: Plus statt Ergänzen/Subtrahieren wird erkannt', () {
      expect(
        ErrorClassifier.classify(
          mode: TrainingMode.money,
          taskKey: 'money:missing:item:12:5',
          expected: 7,
          actual: 17,
        ),
        ErrorPattern.operationChoice,
      );
    });

    test('Euro in Cent ist echte Einheitenumrechnung', () {
      expect(
        ErrorClassifier.classify(
          mode: TrainingMode.money,
          taskKey: 'money:convert:euro-cent:4',
          expected: 400,
          actual: 4,
        ),
        ErrorPattern.unitConversion,
      );
    });

    test('unklarer Geld-Rechenfehler bleibt Geldrechnung', () {
      expect(
        ErrorClassifier.classify(
          mode: TrainingMode.money,
          taskKey: 'money:add:school:7:5',
          expected: 12,
          actual: 11,
        ),
        ErrorPattern.moneyCalculation,
      );
    });
  });

  group('Zeitaufgaben werden nach Kompetenz getrennt', () {
    test('Wochen in Tage ist Einheitenumrechnung', () {
      expect(
        ErrorClassifier.classify(
          mode: TrainingMode.timeDurations,
          taskKey: 'duration:weeks:4',
          expected: 28,
          actual: 24,
        ),
        ErrorPattern.unitConversion,
      );
    });

    test('Tage in Stunden ist Einheitenumrechnung', () {
      expect(
        ErrorClassifier.classify(
          mode: TrainingMode.timeDurations,
          taskKey: 'duration:days:3',
          expected: 72,
          actual: 30,
        ),
        ErrorPattern.unitConversion,
      );
    });

    test('Kalendersprung ist Kalenderkompetenz', () {
      expect(
        ErrorClassifier.classify(
          mode: TrainingMode.timeDurations,
          taskKey: 'calendar:add:März:12:7',
          expected: 0,
          actual: 1,
        ),
        ErrorPattern.calendarDate,
      );
    });

    test('echte Dauer bleibt Zeitspanne', () {
      expect(
        ErrorClassifier.classify(
          mode: TrainingMode.timeDurations,
          taskKey: 'duration:510:75',
          expected: 75,
          actual: 60,
        ),
        ErrorPattern.timeDuration,
      );
    });
  });
}
