import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/training.dart';

void main() {
  group('Umfang-/Flächendiagnose folgt beweisbaren Fehlantworten', () {
    test('Flächenaufgabe mit Umfangsergebnis erkennt Begriffsverwechslung', () {
      expect(ErrorClassifier.classify(mode: TrainingMode.perimeterArea, taskKey: 'rect:area:beet:7:5', expected: 35, actual: 24), ErrorPattern.perimeterArea);
    });
    test('Umfangsaufgabe mit Flächenergebnis erkennt Begriffsverwechslung', () {
      expect(ErrorClassifier.classify(mode: TrainingMode.perimeterArea, taskKey: 'rect:perimeter:beet:7:5', expected: 24, actual: 35), ErrorPattern.perimeterArea);
    });
    test('Umfang mit nur Länge plus Breite erkennt fehlende Gegenkanten', () {
      expect(ErrorClassifier.classify(mode: TrainingMode.perimeterArea, taskKey: 'rect:perimeter:bild:7:5', expected: 24, actual: 12), ErrorPattern.perimeterEdges);
    });
    test('Umfang mit drei Seiten erkennt fehlende Randstrecke', () {
      expect(ErrorClassifier.classify(mode: TrainingMode.perimeterArea, taskKey: 'rect:perimeter:bild:7:5', expected: 24, actual: 19), ErrorPattern.perimeterEdges);
    });
    test('Fläche mit Länge plus Breite erkennt fehlende Zeilen-mal-Spalten-Struktur', () {
      expect(ErrorClassifier.classify(mode: TrainingMode.perimeterArea, taskKey: 'rect:area:bild:7:5', expected: 35, actual: 12), ErrorPattern.areaStructure);
    });
    test('unklare falsche Fläche bleibt bei Flächenstruktur', () {
      expect(ErrorClassifier.classify(mode: TrainingMode.perimeterArea, taskKey: 'rect:area:bild:7:5', expected: 35, actual: 34), ErrorPattern.areaStructure);
    });
    test('unklarer falscher Umfang bleibt bei Randstruktur', () {
      expect(ErrorClassifier.classify(mode: TrainingMode.perimeterArea, taskKey: 'rect:perimeter:bild:7:5', expected: 24, actual: 23), ErrorPattern.perimeterEdges);
    });
    test('Transfer-Key wird gleich sicher ausgewertet', () {
      expect(ErrorClassifier.classify(mode: TrainingMode.perimeterArea, taskKey: 'rect:area:beet:7:5:transfer', expected: 35, actual: 24), ErrorPattern.perimeterArea);
    });
  });
}
