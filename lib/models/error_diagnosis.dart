import 'math_fact.dart';
import 'training.dart';

enum ErrorPattern {
  countingStep,
  tenBridge,
  numberBond,
  operationChoice,
  placeValue,
  multiplicationFact,
  divisionFact,
  inverseOperation,
  numberRelations,
  patternRule,
  wordProblem,
  moneyCalculation,
  clockReading,
  unitConversion,
  geometryProperty,
  roundingPlace,
  mentalStrategy,
  writtenRegrouping,
  writtenProcedure,
  estimation,
  arithmeticLaw,
  romanNumeral,
  fractionPart,
  timeDuration,
  dataReading,
  probabilityReasoning,
  combinatorics,
  proportionalReasoning,
  perimeterArea,
  spatialReasoning,
  symmetry,
  planScale,
  volume,
  unknown,
}

extension ErrorPatternX on ErrorPattern {
  String get label => switch (this) {
        ErrorPattern.countingStep => 'Zählschritt / Nachbarzahl',
        ErrorPattern.tenBridge => 'Zehnerübergang',
        ErrorPattern.numberBond => 'Zahlzerlegung / Grundaufgabe',
        ErrorPattern.operationChoice => 'Rechenart verwechselt',
        ErrorPattern.placeValue => 'Stellenwert',
        ErrorPattern.multiplicationFact => 'Einmaleins-Fakt',
        ErrorPattern.divisionFact => 'Geteilt-Fakt / Umkehraufgabe',
        ErrorPattern.inverseOperation => 'Umkehraufgabe / fehlende Zahl',
        ErrorPattern.numberRelations => 'Zahlbeziehungen',
        ErrorPattern.patternRule => 'Musterregel',
        ErrorPattern.wordProblem => 'Sachaufgabe in Rechnung übersetzen',
        ErrorPattern.moneyCalculation => 'Geld rechnen',
        ErrorPattern.clockReading => 'Uhrzeit lesen',
        ErrorPattern.unitConversion => 'Größen und Einheiten umwandeln',
        ErrorPattern.geometryProperty => 'Eigenschaften von Formen',
        ErrorPattern.roundingPlace => 'Rundungsstelle',
        ErrorPattern.mentalStrategy => 'Halbschriftlicher Rechenweg',
        ErrorPattern.writtenRegrouping => 'Übertrag / Entbündeln',
        ErrorPattern.writtenProcedure => 'Schriftliches Rechenverfahren',
        ErrorPattern.estimation => 'Überschlag',
        ErrorPattern.arithmeticLaw => 'Rechenvorteil / Rechengesetz',
        ErrorPattern.romanNumeral => 'Römische Zahl',
        ErrorPattern.fractionPart => 'Bruchteil einer Größe',
        ErrorPattern.timeDuration => 'Zeitspanne',
        ErrorPattern.dataReading => 'Daten und Diagramme lesen',
        ErrorPattern.probabilityReasoning => 'Wahrscheinlichkeit einschätzen',
        ErrorPattern.combinatorics => 'Möglichkeiten systematisch finden',
        ErrorPattern.proportionalReasoning => 'Proportionale Zuordnung',
        ErrorPattern.perimeterArea => 'Umfang und Fläche unterscheiden',
        ErrorPattern.spatialReasoning => 'Körper und räumliche Vorstellung',
        ErrorPattern.symmetry => 'Symmetrie',
        ErrorPattern.planScale => 'Plan, Weg oder Maßstab',
        ErrorPattern.volume => 'Rauminhalt',
        ErrorPattern.unknown => 'noch nicht eindeutig',
      };

  String get action => switch (this) {
        ErrorPattern.countingStep =>
          'Kurz am Zahlenstrahl oder mit Nachbarzahlen arbeiten und jeden Schritt sichtbar machen.',
        ErrorPattern.tenBridge =>
          'Den Zehnerübergang mit dem gewählten Schul-Rechenweg langsam sichtbar machen; Tempo noch nicht trainieren.',
        ErrorPattern.numberBond =>
          'Zahlzerlegungen und passende Grundaufgaben in kleinen Mengen wiederholen.',
        ErrorPattern.operationChoice =>
          'Rechenzeichen und Bedeutung der Aufgabe vor dem Rechnen bewusst benennen.',
        ErrorPattern.placeValue =>
          'Mit Stellenwerttafel und Bündeln/Entbündeln arbeiten, bevor größere Zahlen gerechnet werden.',
        ErrorPattern.multiplicationFact =>
          'Die betroffene Malaufgabe über Punktefelder, Zerlegen oder Nachbaraufgaben herleiten.',
        ErrorPattern.divisionFact =>
          'Die passende Mal-Umkehraufgabe dazunehmen und Teilen als gleichmäßiges Verteilen darstellen.',
        ErrorPattern.inverseOperation =>
          'Vorwärts- und Umkehraufgabe direkt nebeneinander legen und die gesuchte Zahl markieren.',
        ErrorPattern.numberRelations =>
          'Zahlenmauer oder Zahlbeziehung zunächst mit kleineren Zahlen Schritt für Schritt aufbauen.',
        ErrorPattern.patternRule =>
          'Die Veränderung zwischen zwei benachbarten Zahlen markieren und erst dann fortsetzen.',
        ErrorPattern.wordProblem =>
          'Schlüsselhandlung der Geschichte in eigenen Worten sagen und erst danach die Rechenart auswählen.',
        ErrorPattern.moneyCalculation =>
          'Beträge mit echten oder gezeichneten Münzen darstellen und erst danach rechnen.',
        ErrorPattern.clockReading =>
          'Stunden- und Minutenzeiger getrennt lesen und mit vollen/halben Stunden beginnen.',
        ErrorPattern.unitConversion =>
          'Einheitenleiter oder Größentabelle verwenden und die Umwandlungsbeziehung sichtbar notieren.',
        ErrorPattern.geometryProperty =>
          'Formen anfassen/zeichnen und Seiten, Ecken oder Flächen direkt markieren.',
        ErrorPattern.roundingPlace =>
          'Die Rundungsstelle markieren und nur die direkt folgende Ziffer als Entscheidungshilfe betrachten.',
        ErrorPattern.mentalStrategy =>
          'Den Rechenweg in Teilschritte zerlegen und jeden Zwischenschritt notieren.',
        ErrorPattern.writtenRegrouping =>
          'Übertrag bzw. Entbündeln mit Stellenwertmaterial darstellen und anschließend schriftlich übertragen.',
        ErrorPattern.writtenProcedure =>
          'Stellen sauber untereinander schreiben und das Verfahren Schritt für Schritt mit Probe kontrollieren.',
        ErrorPattern.estimation =>
          'Zuerst beide Zahlen sinnvoll runden und den Überschlag getrennt vom exakten Ergebnis notieren.',
        ErrorPattern.arithmeticLaw =>
          'Die Aufgabe in zwei gleichwertige Rechenwege zerlegen und vergleichen, welcher einfacher ist.',
        ErrorPattern.romanNumeral =>
          'Römische Zeichen zunächst einzeln zuordnen und dann von links nach rechts zusammensetzen.',
        ErrorPattern.fractionPart =>
          'Die ganze Menge zuerst in gleich große Teile zerlegen und den gesuchten Anteil markieren.',
        ErrorPattern.timeDuration =>
          'Start- und Endzeit auf einer Zeitlinie markieren und die Dauer in Etappen berechnen.',
        ErrorPattern.dataReading =>
          'Achsen, Legende und Einheit zuerst lesen; danach genau die benötigten Werte markieren.',
        ErrorPattern.probabilityReasoning =>
          'Alle möglichen Ergebnisse sichtbar sammeln und erst danach vergleichen, was wahrscheinlicher ist.',
        ErrorPattern.combinatorics =>
          'Möglichkeiten systematisch mit Tabelle, Baum oder geordneter Liste sammeln.',
        ErrorPattern.proportionalReasoning =>
          'Zuerst den Wert für eine Einheit bestimmen und von dort weiterrechnen.',
        ErrorPattern.perimeterArea =>
          'Umfang als Rand und Fläche als Inneres sichtbar markieren und die passende Rechenregel dazu schreiben.',
        ErrorPattern.spatialReasoning =>
          'Körper drehen, Netz/Flächen markieren und Ecken, Kanten und Flächen getrennt zählen.',
        ErrorPattern.symmetry =>
          'Eine mögliche Achse einzeichnen und prüfen, ob beide Hälften beim Falten deckungsgleich wären.',
        ErrorPattern.planScale =>
          'Reale Strecke und Planstrecke getrennt notieren und die Maßstabsbeziehung daneben schreiben.',
        ErrorPattern.volume =>
          'Rauminhalt mit Schichten aus Einheitswürfeln aufbauen: Länge × Breite × Höhe.',
        ErrorPattern.unknown =>
          'Noch keine feste Ursache annehmen; erst weitere ähnliche Aufgaben beobachten.',
      };
}

class DiagnosticAttempt {
  const DiagnosticAttempt({
    required this.occurredAt,
    required this.mode,
    required this.taskKey,
    required this.expected,
    required this.actual,
    required this.correct,
    required this.gradeLevel,
    required this.numberRange,
    this.pattern,
  });

  final DateTime occurredAt;
  final TrainingMode mode;
  final String taskKey;
  final int expected;
  final int actual;
  final bool correct;
  final GradeLevel gradeLevel;
  final NumberRangeLevel numberRange;
  final ErrorPattern? pattern;

  Map<String, dynamic> toJson() => {
        'occurredAt': occurredAt.toIso8601String(),
        'mode': mode.name,
        'taskKey': taskKey,
        'expected': expected,
        'actual': actual,
        'correct': correct,
        'gradeLevel': gradeLevel.name,
        'numberRange': numberRange.name,
        'pattern': pattern?.name,
      };

  factory DiagnosticAttempt.fromJson(Map<String, dynamic> json) {
    final rawPattern = json['pattern'] as String?;
    ErrorPattern? pattern;
    if (rawPattern != null) {
      for (final value in ErrorPattern.values) {
        if (value.name == rawPattern) {
          pattern = value;
          break;
        }
      }
    }
    return DiagnosticAttempt(
      occurredAt: DateTime.tryParse(json['occurredAt'] as String? ?? '') ??
          DateTime(2026, 1, 1),
      mode: TrainingMode.values.byName(json['mode'] as String),
      taskKey: json['taskKey'] as String? ?? '',
      expected: json['expected'] as int? ?? 0,
      actual: json['actual'] as int? ?? 0,
      correct: json['correct'] as bool? ?? false,
      gradeLevel: json['gradeLevel'] == null
          ? GradeLevel.second
          : GradeLevel.values.byName(json['gradeLevel'] as String),
      numberRange: json['numberRange'] == null
          ? NumberRangeLevel.hundred
          : NumberRangeLevel.values.byName(json['numberRange'] as String),
      pattern: pattern,
    );
  }
}

class DiagnosticSummary {
  const DiagnosticSummary({
    required this.pattern,
    required this.errors,
    required this.lastSeen,
    required this.modes,
  });

  final ErrorPattern pattern;
  final int errors;
  final DateTime lastSeen;
  final Set<TrainingMode> modes;

  bool get isRecurring => errors >= 2;

  String get confidenceLabel => switch (errors) {
        >= 4 => 'wiederholt auffällig',
        3 => 'mehrfach auffällig',
        2 => 'zweimal aufgefallen',
        _ => 'einmal aufgefallen',
      };
}

class ErrorClassifier {
  const ErrorClassifier._();

  static ErrorPattern? classify({
    required TrainingMode mode,
    required String taskKey,
    required int expected,
    required int actual,
    MathFact? fact,
  }) {
    if (actual == expected) return null;

    if (fact != null) {
      return _classifyFact(
        mode: mode,
        fact: fact,
        expected: expected,
        actual: actual,
      );
    }

    if (taskKey.startsWith('wall:')) return ErrorPattern.numberRelations;
    if (taskKey.startsWith('gap:')) return ErrorPattern.inverseOperation;
    if (taskKey.startsWith('neighbor:')) return ErrorPattern.countingStep;
    if (taskKey.startsWith('place:')) return ErrorPattern.placeValue;
    if (taskKey.startsWith('double:') || taskKey.startsWith('half:')) {
      return ErrorPattern.numberBond;
    }
    if (taskKey.startsWith('sequence:')) return ErrorPattern.patternRule;
    if (taskKey.startsWith('family:')) return ErrorPattern.inverseOperation;
    if (taskKey.startsWith('story:')) return ErrorPattern.wordProblem;
    if (taskKey.startsWith('money:')) return ErrorPattern.moneyCalculation;
    if (taskKey.startsWith('clock:')) return ErrorPattern.clockReading;
    if (taskKey.startsWith('measure:')) return ErrorPattern.unitConversion;
    if (taskKey.startsWith('geometry:')) return ErrorPattern.geometryProperty;

    return switch (mode) {
      TrainingMode.largeNumbers => taskKey.startsWith('large:neighbor:')
          ? ErrorPattern.countingStep
          : ErrorPattern.placeValue,
      TrainingMode.rounding => ErrorPattern.roundingPlace,
      TrainingMode.mentalStrategies => _mentalPattern(taskKey),
      TrainingMode.writtenAddSub => _writtenAddSubPattern(taskKey),
      TrainingMode.writtenMultiply ||
      TrainingMode.writtenDivide => ErrorPattern.writtenProcedure,
      TrainingMode.estimation => ErrorPattern.estimation,
      TrainingMode.arithmeticLaws => ErrorPattern.arithmeticLaw,
      TrainingMode.romanNumerals => ErrorPattern.romanNumeral,
      TrainingMode.fractions => ErrorPattern.fractionPart,
      TrainingMode.advancedMeasures => ErrorPattern.unitConversion,
      TrainingMode.timeDurations => ErrorPattern.timeDuration,
      TrainingMode.dataCharts => ErrorPattern.dataReading,
      TrainingMode.probability => ErrorPattern.probabilityReasoning,
      TrainingMode.combinatorics => ErrorPattern.combinatorics,
      TrainingMode.proportionality => ErrorPattern.proportionalReasoning,
      TrainingMode.perimeterArea => ErrorPattern.perimeterArea,
      TrainingMode.geometryBodies => ErrorPattern.spatialReasoning,
      TrainingMode.symmetry => ErrorPattern.symmetry,
      TrainingMode.plansAndOrientation => ErrorPattern.planScale,
      TrainingMode.volumeCubes => ErrorPattern.volume,
      TrainingMode.wordProblems => ErrorPattern.wordProblem,
      TrainingMode.money => ErrorPattern.moneyCalculation,
      TrainingMode.clock => ErrorPattern.clockReading,
      TrainingMode.measures => ErrorPattern.unitConversion,
      TrainingMode.geometry => ErrorPattern.geometryProperty,
      TrainingMode.numberWall => ErrorPattern.numberRelations,
      TrainingMode.missingNumber => ErrorPattern.inverseOperation,
      TrainingMode.neighbors => ErrorPattern.countingStep,
      TrainingMode.placeValue => ErrorPattern.placeValue,
      TrainingMode.doublesHalves => ErrorPattern.numberBond,
      TrainingMode.sequences => ErrorPattern.patternRule,
      TrainingMode.factFamilies => ErrorPattern.inverseOperation,
      _ => ErrorPattern.unknown,
    };
  }

  static ErrorPattern _classifyFact({
    required TrainingMode mode,
    required MathFact fact,
    required int expected,
    required int actual,
  }) {
    if (mode == TrainingMode.numberFriends) return ErrorPattern.numberBond;

    switch (fact.operation) {
      case MathOperation.plus:
        if (fact.a >= fact.b && actual == fact.a - fact.b) {
          return ErrorPattern.operationChoice;
        }
        if ((fact.a % 10) + (fact.b % 10) >= 10) {
          return ErrorPattern.tenBridge;
        }
        if ((actual - expected).abs() == 1) return ErrorPattern.countingStep;
        if ((actual - expected).abs() >= 10 &&
            (actual - expected).abs() % 10 == 0) {
          return ErrorPattern.placeValue;
        }
        return ErrorPattern.numberBond;

      case MathOperation.minus:
        if (actual == fact.a + fact.b) return ErrorPattern.operationChoice;
        if ((fact.a % 10) < (fact.b % 10)) {
          return ErrorPattern.tenBridge;
        }
        if ((actual - expected).abs() == 1) return ErrorPattern.countingStep;
        if ((actual - expected).abs() >= 10 &&
            (actual - expected).abs() % 10 == 0) {
          return ErrorPattern.placeValue;
        }
        return ErrorPattern.numberBond;

      case MathOperation.multiply:
        if (actual == fact.a + fact.b) return ErrorPattern.operationChoice;
        return ErrorPattern.multiplicationFact;

      case MathOperation.divide:
        if (actual == fact.a * fact.b) return ErrorPattern.operationChoice;
        return ErrorPattern.divisionFact;
    }
  }

  static ErrorPattern _mentalPattern(String key) {
    final parts = key.split(':');
    if (parts.length < 4) return ErrorPattern.mentalStrategy;
    final a = int.tryParse(parts[2]);
    final b = int.tryParse(parts[3]);
    if (a == null || b == null) return ErrorPattern.mentalStrategy;

    if (parts[1] == '+' && (a % 10) + (b % 10) >= 10) {
      return ErrorPattern.tenBridge;
    }
    if (parts[1] == '-' && (a % 10) < (b % 10)) {
      return ErrorPattern.tenBridge;
    }
    return ErrorPattern.mentalStrategy;
  }

  static ErrorPattern _writtenAddSubPattern(String key) {
    final parts = key.split(':');
    if (parts.length < 4) return ErrorPattern.writtenProcedure;
    final a = int.tryParse(parts[2]);
    final b = int.tryParse(parts[3]);
    if (a == null || b == null) return ErrorPattern.writtenProcedure;

    final needsRegrouping = parts[1] == '+'
        ? _additionNeedsCarry(a, b)
        : _subtractionNeedsBorrow(a, b);
    return needsRegrouping
        ? ErrorPattern.writtenRegrouping
        : ErrorPattern.writtenProcedure;
  }

  static bool _additionNeedsCarry(int a, int b) {
    var left = a;
    var right = b;
    while (left > 0 || right > 0) {
      if ((left % 10) + (right % 10) >= 10) return true;
      left ~/= 10;
      right ~/= 10;
    }
    return false;
  }

  static bool _subtractionNeedsBorrow(int a, int b) {
    var left = a;
    var right = b;
    while (left > 0 || right > 0) {
      if ((left % 10) < (right % 10)) return true;
      left ~/= 10;
      right ~/= 10;
    }
    return false;
  }
}
