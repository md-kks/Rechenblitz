import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/training.dart';

void main() {
  group('Datendiagnose bleibt an der beobachtbaren Aufgabenanforderung', () {
    ErrorPattern? classify(String key, int expected, int actual) =>
        ErrorClassifier.classify(
          mode: TrainingMode.dataCharts,
          taskKey: key,
          expected: expected,
          actual: actual,
        );

    test('Maximum bleibt beim Ablesen und Auswählen von Diagrammwerten', () {
      expect(classify('data:max:4-7-3-6', 7, 6), ErrorPattern.dataReading);
    });

    test('Gesamtmenge wird als Aggregation diagnostiziert', () {
      expect(classify('data:sum:4-7-3-6', 20, 19), ErrorPattern.dataAggregation);
    });

    test('Differenz wird als Datenvergleich diagnostiziert', () {
      expect(classify('data:diff:9-5-4-7', 4, 14), ErrorPattern.dataComparison);
    });

    test('Strichliste erhält eigenes Diagnoseziel', () {
      expect(classify('data:tally:17', 17, 12), ErrorPattern.tallyReading);
    });

    test('Strichlisten-Transfer behält eigenes Diagnoseziel', () {
      expect(
        classify('data:tally:17:transfer:observation', 17, 16),
        ErrorPattern.tallyReading,
      );
    });

    test('Darstellungswahl erhält eigenes Diagnoseziel', () {
      expect(
        classify('data:representation:5:2', 2, 1),
        ErrorPattern.dataRepresentationChoice,
      );
    });

    test('Transfer-Diagramme behalten ihre Auswertungsart', () {
      expect(
        classify('data:sum:4-7-3-6:transfer:context', 20, 18),
        ErrorPattern.dataAggregation,
      );
      expect(
        classify('data:diff:9-5-4-7:transfer:context', 4, 5),
        ErrorPattern.dataComparison,
      );
    });

    test('unbekannter Daten-Key fällt konservativ auf Diagrammlesen zurück', () {
      expect(classify('data:future:4-7-3-6', 7, 6), ErrorPattern.dataReading);
    });
  });
}
