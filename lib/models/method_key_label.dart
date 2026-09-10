import 'learning_methods.dart';
import 'training.dart';

abstract final class MethodKeyLabel {
  static const Map<String, String> _exact = {
    'addition:bridgeToTen': 'Erst zum Zehner',
    'addition:toFullTen': 'Zum vollen Zehner',
    'arithmeticLaws:structure': 'Rechenvorteil erkennen',
    'calendar:week-remainder': 'Kalendersprung in Wochen und Resttage zerlegen',
    'clock:readHands': 'Uhrzeiger lesen',
    'combinatorics:first-branch': 'Einen Ast systematisch vollständig bilden',
    'cube-net:local-face-relation': 'Drei Flächen falten, dann das ganze Netz prüfen',
    'data:read-chart-values': 'Balkenwerte sicher ablesen',
    'data:representation-purpose': 'Zweck erkennen, dann Darstellung wählen',
    'data:tally-five-blocks': 'Strichliste in Fünferblöcken lesen',
    'division:inverseMultiplication': 'Geteilt mit der Mal-Umkehraufgabe',
    'doublesHalves:relationship': 'Doppeln und Halbieren verstehen',
    'estimation:roundedSummands': 'Überschlag schrittweise bilden',
    'fraction:equalParts': 'Gleich große Teile',
    'geometry:area': 'Fläche = Inneres',
    'geometry:figure-family': 'Grundfamilie erkennen, dann genauer einordnen',
    'geometry:perimeter': 'Umfang = Rand',
    'geometry:right-angle-reference': 'Mit der Rechteck-Ecke vergleichen, dann benennen',
    'inverse:operationRelationship': 'Umkehraufgabe nutzen',
    'largeNumbers:compare': 'Zahlen vergleichen',
    'largeNumbers:decompose': 'Stellenwerte zusammensetzen',
    'largeNumbers:neighbor': 'Nachbarzahl finden',
    'largeNumbers:numberWord': 'Zahlwort lesen',
    'largeNumbers:order': 'Große Zahlen ordnen',
    'largeNumbers:placeValue': 'Stellenwert lesen',
    'measure:calculationPlan': 'Längenaufgabe zuerst als Rechenplan lesen',
    'measure:minuteSecond': 'Minuten und Sekunden',
    'measure:unitLadder': 'Einheitenleiter',
    'mental:placeChunks': 'Halbschriftlich in Stellenwertblöcken rechnen',
    'money:calculationPlan': 'Geldaufgabe zuerst als Rechenplan lesen',
    'money:representAndCalculate': 'Geldbetrag darstellen und rechnen',
    'numberWall:relationDirection': 'Zahlenmauer vorwärts und rückwärts',
    'plan-route:first-segment': 'Pfeilroute abschnittsweise lesen',
    'probability:count-relation': 'Anzahlen vergleichen, dann Chance deuten',
    'probability:observed-frequency-relation': 'Beobachtung erst numerisch vergleichen',
    'process:errorChecking': 'Rechenfehler finden',
    'process:plausibility': 'Mit Überschlag kontrollieren',
    'process:strategyChoice': 'Günstigen Rechenweg wählen',
    'proportion:unitValue': 'Über eine Einheit zuordnen',
    'reasoning:relation': 'Rechenbeziehung begründen',
    'representation:equalGroups': 'Gleiche Gruppen lesen',
    'representation:placeValue': 'Stellenwerte lesen',
    'roman:tens-block': 'Zehnerblock lesen, dann Einer ergänzen',
    'rounding:place': 'Runden',
    'scale:operation-choice': 'Zuordnung lesen, dann maßstäblich hochrechnen',
    'sequence:constantStep': 'Musterregel finden',
    'subtraction:direct': 'Direkt abziehen',
    'subtraction:fromFullTen': 'Direkt vom Zehner',
    'symmetry:candidate-axis': 'Eine Achse prüfen, dann alle Achsen finden',
    'time:timeline': 'Zeitlinie',
    'volume:single-layer': 'Eine Schicht erfassen, dann Schichten vervielfachen',
    'wordProblem:meaning': 'Text zuerst verstehen',
    'writtenAddition:standard': 'Schriftliche Addition',
    'writtenDivision:standard': 'Schriftliche Division',
    'writtenMultiplication:partialProducts': 'Schriftliche Multiplikation mit Teilprodukten',
    'writtenMultiplication:singleDigit': 'Schriftliche Multiplikation',
  };

  static String? resolve(String methodKey) {
    final exact = _exact[methodKey];
    if (exact != null) return exact;

    if (methodKey.startsWith('subtraction:')) {
      final name = methodKey.substring('subtraction:'.length);
      for (final strategy in SubtractionStrategy.values) {
        if (strategy.name == name) return strategy.label;
      }
    }
    if (methodKey.startsWith('multiplication:')) {
      final name = methodKey.substring('multiplication:'.length);
      for (final strategy in MultiplicationStrategy.values) {
        if (strategy.name == name) return strategy.label;
      }
    }
    if (methodKey.startsWith('writtenSubtraction:')) {
      final name = methodKey.substring('writtenSubtraction:'.length);
      for (final strategy in WrittenSubtractionStrategy.values) {
        if (strategy.name == name) return strategy.label;
      }
    }
    if (methodKey.startsWith('general:')) {
      final name = methodKey.substring('general:'.length);
      for (final mode in TrainingMode.values) {
        if (mode.name == name) return mode.title;
      }
    }
    return null;
  }
}
