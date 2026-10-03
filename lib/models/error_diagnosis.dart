import 'math_fact.dart';
import 'training.dart';

enum ErrorPattern {
  countingStep,
  tenBridge,
  carryOmitted,
  borrowAvoided,
  partialOperand,
  numberBond,
  operationChoice,
  placeValue,
  multiplicationFact,
  multiplicationAsAddition,
  divisionFact,
  divisionAsSubtraction,
  inverseOperation,
  numberRelations,
  patternRule,
  wordProblem,
  wordProblemRelevantInformation,
  wordProblemModel,
  wordProblemInterpretation,
  representationTranslation,
  moneyCalculation,
  clockReading,
  unitConversion,
  measurementCalculation,
  geometryProperty,
  roundingPlace,
  mentalStrategy,
  writtenRegrouping,
  writtenProcedure,
  estimation,
  arithmeticLaw,
  romanNumeral,
  fractionPart,
  fractionSinglePart,
  fractionPartCount,
  timeDuration,
  calendarDate,
  dataReading,
  probabilityReasoning,
  combinatorics,
  proportionalReasoning,
  perimeterArea,
  perimeterEdges,
  areaStructure,
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
        ErrorPattern.carryOmitted => 'Übertrag beim Plus vergessen',
        ErrorPattern.borrowAvoided => 'Entbündeln beim Minus vermieden',
        ErrorPattern.partialOperand => 'Nur einen Zahlenteil verrechnet',
        ErrorPattern.numberBond => 'Zahlzerlegung / Grundaufgabe',
        ErrorPattern.operationChoice => 'Rechenart verwechselt',
        ErrorPattern.placeValue => 'Stellenwert',
        ErrorPattern.multiplicationFact => 'Einmaleins-Fakt',
        ErrorPattern.multiplicationAsAddition =>
          'Malaufgabe wie Plus gerechnet',
        ErrorPattern.divisionFact => 'Geteilt-Fakt / Umkehraufgabe',
        ErrorPattern.divisionAsSubtraction =>
          'Geteiltaufgabe wie Minus gerechnet',
        ErrorPattern.inverseOperation => 'Umkehraufgabe / fehlende Zahl',
        ErrorPattern.numberRelations => 'Zahlbeziehungen',
        ErrorPattern.patternRule => 'Musterregel',
        ErrorPattern.wordProblem => 'Sachaufgabe in Rechnung übersetzen',
        ErrorPattern.wordProblemRelevantInformation =>
          'Wichtige Angaben in der Sachaufgabe',
        ErrorPattern.wordProblemModel =>
          'Sachaufgabe als Rechnung darstellen',
        ErrorPattern.wordProblemInterpretation =>
          'Ergebnis im Sachzusammenhang deuten',
        ErrorPattern.representationTranslation =>
          'Zwischen Darstellungen wechseln',
        ErrorPattern.moneyCalculation => 'Geld rechnen',
        ErrorPattern.clockReading => 'Uhrzeit lesen',
        ErrorPattern.unitConversion => 'Größen und Einheiten umwandeln',
        ErrorPattern.measurementCalculation => 'Mit Größen rechnen',
        ErrorPattern.geometryProperty => 'Eigenschaften von Formen',
        ErrorPattern.roundingPlace => 'Rundungsstelle',
        ErrorPattern.mentalStrategy => 'Halbschriftlicher Rechenweg',
        ErrorPattern.writtenRegrouping => 'Übertrag / Entbündeln',
        ErrorPattern.writtenProcedure => 'Schriftliches Rechenverfahren',
        ErrorPattern.estimation => 'Überschlag',
        ErrorPattern.arithmeticLaw => 'Rechenvorteil / Rechengesetz',
        ErrorPattern.romanNumeral => 'Römische Zahl',
        ErrorPattern.fractionPart => 'Bruchteil einer Größe',
        ErrorPattern.fractionSinglePart => 'Größe eines Bruchteils',
        ErrorPattern.fractionPartCount => 'Anzahl der Bruchteile',
        ErrorPattern.timeDuration => 'Zeitspanne',
        ErrorPattern.calendarDate => 'Datum und Kalender',
        ErrorPattern.dataReading => 'Daten und Diagramme lesen',
        ErrorPattern.probabilityReasoning => 'Wahrscheinlichkeit einschätzen',
        ErrorPattern.combinatorics => 'Möglichkeiten systematisch finden',
        ErrorPattern.proportionalReasoning => 'Proportionale Zuordnung',
        ErrorPattern.perimeterArea => 'Umfang und Fläche unterscheiden',
        ErrorPattern.perimeterEdges => 'Alle Randstrecken erfassen',
        ErrorPattern.areaStructure => 'Fläche als Zeilen × Spalten',
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
        ErrorPattern.carryOmitted =>
          'Den Einerübertrag sichtbar notieren: erst die Einer bündeln, den neuen Zehner weitergeben und dann die Zehner addieren.',
        ErrorPattern.borrowAvoided =>
          'Vor dem Subtrahieren einen Zehner entbündeln und Einer sowie Zehner getrennt sichtbar bearbeiten.',
        ErrorPattern.partialOperand =>
          'Die zweite Zahl in Zehner und Einer zerlegen und beide Teile nacheinander verrechnen.',
        ErrorPattern.numberBond =>
          'Zahlzerlegungen und passende Grundaufgaben in kleinen Mengen wiederholen.',
        ErrorPattern.operationChoice =>
          'Rechenzeichen und Bedeutung der Aufgabe vor dem Rechnen bewusst benennen.',
        ErrorPattern.placeValue =>
          'Mit Stellenwerttafel und Bündeln/Entbündeln arbeiten, bevor größere Zahlen gerechnet werden.',
        ErrorPattern.multiplicationFact =>
          'Die betroffene Malaufgabe über Punktefelder, Zerlegen oder Nachbaraufgaben herleiten.',
        ErrorPattern.multiplicationAsAddition =>
          'Multiplikation als mehrere gleich große Gruppen darstellen und erst danach zur Malaufgabe zurückkehren.',
        ErrorPattern.divisionFact =>
          'Die passende Mal-Umkehraufgabe dazunehmen und Teilen als gleichmäßiges Verteilen darstellen.',
        ErrorPattern.divisionAsSubtraction =>
          'Teilen als gleichmäßiges Verteilen darstellen und die passende Mal-Umkehraufgabe danebenlegen.',
        ErrorPattern.inverseOperation =>
          'Vorwärts- und Umkehraufgabe direkt nebeneinander legen und die gesuchte Zahl markieren.',
        ErrorPattern.numberRelations =>
          'Zahlenmauer oder Zahlbeziehung zunächst mit kleineren Zahlen Schritt für Schritt aufbauen.',
        ErrorPattern.patternRule =>
          'Die Veränderung zwischen zwei benachbarten Zahlen markieren und erst dann fortsetzen.',
        ErrorPattern.wordProblem =>
          'Schlüsselhandlung der Geschichte in eigenen Worten sagen und erst danach die Rechenart auswählen.',
        ErrorPattern.wordProblemRelevantInformation =>
          'Nur die Frage markieren und anschließend jede Angabe darauf prüfen, ob sie zum Beantworten wirklich gebraucht wird.',
        ErrorPattern.wordProblemModel =>
          'Die wichtigen Angaben zuerst markieren und danach eine Rechnung wählen, die genau die Handlung der Geschichte abbildet.',
        ErrorPattern.wordProblemInterpretation =>
          'Das Rechenergebnis mit Einheit oder Gegenstand in einen Antwortsatz zurück zur ursprünglichen Frage setzen.',
        ErrorPattern.representationTranslation =>
          'Dieselbe Zahl oder Rechenidee nacheinander als Stellenwertdarstellung, Zerlegung, Gruppenbild und Symbolform lesen und vergleichen.',
        ErrorPattern.moneyCalculation =>
          'Beträge mit echten oder gezeichneten Münzen darstellen und erst danach rechnen.',
        ErrorPattern.clockReading =>
          'Stunden- und Minutenzeiger getrennt lesen und mit vollen/halben Stunden beginnen.',
        ErrorPattern.unitConversion =>
          'Einheitenleiter oder Größentabelle verwenden und die Umwandlungsbeziehung sichtbar notieren.',
        ErrorPattern.measurementCalculation =>
          'Zuerst prüfen, ob die Größen zusammengelegt oder voneinander abgezogen werden, und dann mit derselben Einheit rechnen.',
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
        ErrorPattern.fractionSinglePart =>
          'Zuerst nur einen gleich großen Teil bestimmen: Ganzes durch den Nenner teilen. Danach erst mehrere Teile zusammensetzen.',
        ErrorPattern.fractionPartCount =>
          'Zähler und Nenner getrennt lesen: Der Nenner bestimmt die gleich großen Teile, der Zähler sagt, wie viele davon genommen werden.',
        ErrorPattern.timeDuration =>
          'Start- und Endzeit auf einer Zeitlinie markieren und die Dauer in Etappen berechnen.',
        ErrorPattern.calendarDate =>
          'Im Kalender vom Startdatum aus die Tage schrittweise weiterzählen und Monatsgrenzen beachten.',
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
        ErrorPattern.perimeterEdges =>
          'Beim Umfang jede der vier Randstrecken genau einmal erfassen: zwei Längen und zwei Breiten.',
        ErrorPattern.areaStructure =>
          'Die Fläche als Reihen und Spalten von Einheitsquadraten denken: Länge × Breite.',
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

  String get firstResponseHint => switch (this) {
        ErrorPattern.carryOmitted =>
          'Schau auf die Einer: Entsteht dort ein neuer Zehner, der weitergegeben werden muss?',
        ErrorPattern.borrowAvoided =>
          'Bei den Einern reicht die obere Ziffer nicht. Entbündele zuerst einen Zehner.',
        ErrorPattern.partialOperand =>
          'Prüfe die zweite Zahl: Hast du ihre Zehner und Einer beide verrechnet?',
        ErrorPattern.multiplicationAsAddition =>
          '× bedeutet gleich große Gruppen. Addiere nicht nur die beiden Faktoren.',
        ErrorPattern.divisionAsSubtraction =>
          '÷ bedeutet gleichmäßig aufteilen. Suche die passende Mal-Umkehraufgabe.',
        ErrorPattern.wordProblemRelevantInformation =>
          'Lies nur die Frage: Welche Angaben werden dafür wirklich gebraucht?',
        ErrorPattern.wordProblemModel =>
          'Welche Rechnung beschreibt genau die Handlung und die wichtigen Angaben?',
        ErrorPattern.wordProblemInterpretation =>
          'Was bedeutet das Ergebnis für die ursprüngliche Frage?',
        ErrorPattern.representationTranslation =>
          'Beschreibe zuerst, was du siehst: Stellenwerte oder gleich große Gruppen. Übersetze erst danach in Zahl oder Rechnung.',
        ErrorPattern.operationChoice =>
          'Prüfe zuerst die Handlung: Wird etwas mehr, weniger, vervielfacht oder verteilt?',
        ErrorPattern.tenBridge =>
          'Suche den nächsten glatten Zehner und rechne den Übergang in zwei Schritten.',
        ErrorPattern.placeValue =>
          'Prüfe Einer, Zehner und Hunderter getrennt.',
        ErrorPattern.multiplicationFact =>
          'Stelle die Malaufgabe als gleich große Gruppen vor.',
        ErrorPattern.divisionFact =>
          'Welche Malaufgabe ist die Umkehrung dieser Geteiltaufgabe?',
        ErrorPattern.numberRelations =>
          'Welche beiden Steine oder Zahlen gehören direkt zusammen?',
        ErrorPattern.patternRule =>
          'Vergleiche zwei Nachbarzahlen: Um wie viel verändert sich die Folge jedes Mal?',
        ErrorPattern.moneyCalculation =>
          'Stelle zuerst nur die vorhandenen Geldbeträge dar. Was wird zusammengelegt oder weggenommen?',
        ErrorPattern.clockReading =>
          'Lies zuerst nur den langen Minutenzeiger. Danach kommt die Stunde.',
        ErrorPattern.unitConversion =>
          'Welche Einheit ist gegeben und in welche Einheit soll umgewandelt werden?',
        ErrorPattern.measurementCalculation =>
          'Bleibt die Einheit gleich? Entscheide dann zuerst, welche Rechnung zur Situation passt.',
        ErrorPattern.geometryProperty =>
          'Markiere zuerst direkt an der Figur die Eigenschaft, nach der gefragt wird.',
        ErrorPattern.roundingPlace =>
          'Markiere die Rundungsstelle und schau nur auf die Ziffer direkt rechts daneben.',
        ErrorPattern.mentalStrategy =>
          'Welcher erste Teilschritt macht die Zahl glatter oder leichter?',
        ErrorPattern.writtenRegrouping =>
          'Prüfe die aktuelle Spalte: Muss hier gebündelt oder entbündelt werden?',
        ErrorPattern.writtenProcedure =>
          'Beginne an der richtigen Stelle und prüfe jeden schriftlichen Teilschritt einzeln.',
        ErrorPattern.estimation =>
          'Runde zuerst beide Zahlen passend. Rechne den Überschlag noch nicht exakt.',
        ErrorPattern.arithmeticLaw =>
          'Was verändert sich an der Rechnung – und was bleibt dabei gleich?',
        ErrorPattern.romanNumeral =>
          'Lies die römische Zahl in Blöcken. Prüfe besonders IV, IX, XL und XC.',
        ErrorPattern.fractionPart =>
          'Wie viele gleich große Teile hat das Ganze? Bestimme zuerst die Größe eines Teils.',
        ErrorPattern.fractionSinglePart =>
          'Bestimme zuerst genau einen Teil: Teile das Ganze durch den Nenner.',
        ErrorPattern.fractionPartCount =>
          'Wie viele gleich große Teile werden gefragt? Schau dafür auf den Zähler.',
        ErrorPattern.timeDuration =>
          'Markiere Start und Ende und gehe zuerst bis zu einer gut erreichbaren Uhrzeit.',
        ErrorPattern.dataReading =>
          'Lies zuerst Beschriftung und Einheit. Welche Werte brauchst du wirklich?',
        ErrorPattern.probabilityReasoning =>
          'Welche Ergebnisse sind überhaupt möglich? Zähle sie, bevor du die Chance vergleichst.',
        ErrorPattern.combinatorics =>
          'Halte eine Möglichkeit fest und variiere danach nur einen Bestandteil systematisch.',
        ErrorPattern.proportionalReasoning =>
          'Bestimme zuerst den Wert für genau eine Einheit.',
        ErrorPattern.perimeterArea =>
          'Geht es um den Rand oder um das Innere der Figur?',
        ErrorPattern.perimeterEdges =>
          'Welche vier Seiten bilden den Rand? Nimm zwei Längen und zwei Breiten.',
        ErrorPattern.areaStructure =>
          'Wie viele Reihen und Spalten aus 1-cm²-Quadraten hat das Rechteck?',
        ErrorPattern.spatialReasoning =>
          'Betrachte den Körper aus einer zweiten Richtung und prüfe nur eine Eigenschaft zugleich.',
        ErrorPattern.symmetry =>
          'Würde die Figur an dieser Linie beim Falten genau auf sich selbst liegen?',
        ErrorPattern.planScale =>
          'Trenne Planstrecke und reale Strecke. Welche Beziehung verbindet beide?',
        ErrorPattern.volume =>
          'Bestimme zuerst, wie viele Würfel in einer einzigen Schicht liegen.',
        _ => 'Prüfe genau den Rechenschritt, bei dem sich dein Ergebnis verändert hat.',
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
    this.evidenceId,
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
  final String? evidenceId;

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
        'evidenceId': evidenceId,
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
      evidenceId: json['evidenceId'] as String?,
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
    if (fact != null) {
      return _classifyFact(
        mode: mode,
        fact: fact,
        expected: expected,
        actual: actual,
      );
    }

    if (taskKey.startsWith('remediation:')) {
      final parts = taskKey.split(':');
      if (parts.length > 1) {
        for (final value in ErrorPattern.values) {
          if (value.name == parts[1]) return value;
        }
      }
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
    if (taskKey.startsWith('process:representation:')) {
      return ErrorPattern.representationTranslation;
    }
    if (taskKey.startsWith('story:transfer:skill:')) {
      return _transferStoryPattern(
        taskKey,
        expected: expected,
        actual: actual,
      );
    }
    if (taskKey.startsWith('story:info:') ||
        taskKey.startsWith('story:transfer:irrelevant:')) {
      return ErrorPattern.wordProblemRelevantInformation;
    }
    if (taskKey.startsWith('story:operation:')) {
      return ErrorPattern.operationChoice;
    }
    if (taskKey.startsWith('story:equation:')) {
      return ErrorPattern.wordProblemModel;
    }
    if (taskKey.startsWith('story:interpret:')) {
      return ErrorPattern.wordProblemInterpretation;
    }
    if (taskKey.startsWith('story:calc:')) {
      return _storyCalculationPattern(
        taskKey,
        expected: expected,
        actual: actual,
      );
    }
    if (taskKey.startsWith('story:')) return ErrorPattern.wordProblem;
    if (taskKey.startsWith('money:')) {
      return _moneyPattern(taskKey, expected: expected, actual: actual);
    }
    if (taskKey.startsWith('clock:')) return ErrorPattern.clockReading;
    if (taskKey.startsWith('measure:')) {
      return _measurePattern(taskKey, expected: expected, actual: actual);
    }
    if (taskKey.startsWith('geometry:')) return ErrorPattern.geometryProperty;

    return switch (mode) {
      TrainingMode.largeNumbers => taskKey.startsWith('large:neighbor:')
          ? ErrorPattern.countingStep
          : ErrorPattern.placeValue,
      TrainingMode.rounding => ErrorPattern.roundingPlace,
      TrainingMode.mentalStrategies => _mentalPattern(
          taskKey,
          expected: expected,
          actual: actual,
        ),
      TrainingMode.writtenAddSub => _writtenAddSubPattern(
          taskKey,
          expected: expected,
          actual: actual,
        ),
      TrainingMode.writtenMultiply => _writtenMultiplyPattern(
          taskKey,
          expected: expected,
          actual: actual,
        ),
      TrainingMode.writtenDivide => _writtenDividePattern(
          taskKey,
          expected: expected,
          actual: actual,
        ),
      TrainingMode.estimation => ErrorPattern.estimation,
      TrainingMode.arithmeticLaws => ErrorPattern.arithmeticLaw,
      TrainingMode.romanNumerals => ErrorPattern.romanNumeral,
      TrainingMode.fractions => _fractionPattern(
          taskKey,
          expected: expected,
          actual: actual,
        ),
      TrainingMode.advancedMeasures => ErrorPattern.unitConversion,
      TrainingMode.timeDurations => _timePattern(taskKey),
      TrainingMode.dataCharts => ErrorPattern.dataReading,
      TrainingMode.probability => ErrorPattern.probabilityReasoning,
      TrainingMode.combinatorics => ErrorPattern.combinatorics,
      TrainingMode.proportionality => ErrorPattern.proportionalReasoning,
      TrainingMode.perimeterArea => _perimeterAreaPattern(
          taskKey,
          expected: expected,
          actual: actual,
        ),
      TrainingMode.geometryRelations => ErrorPattern.geometryProperty,
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
        if (actual != expected && _usedOnlyPartOfSecondOperand(fact, actual)) {
          return ErrorPattern.partialOperand;
        }
        final crossesTen = needsAdditionTenBridge(fact.a, fact.b);
        if (actual != expected &&
            crossesTen &&
            actual == expected - 10) {
          return ErrorPattern.carryOmitted;
        }
        if (crossesTen) return ErrorPattern.tenBridge;
        if ((actual - expected).abs() == 1) return ErrorPattern.countingStep;
        if ((actual - expected).abs() >= 10 &&
            (actual - expected).abs() % 10 == 0) {
          return ErrorPattern.placeValue;
        }
        return ErrorPattern.numberBond;

      case MathOperation.minus:
        if (actual == fact.a + fact.b) return ErrorPattern.operationChoice;
        if (actual != expected && _usedOnlyPartOfSecondOperand(fact, actual)) {
          return ErrorPattern.partialOperand;
        }
        final needsBorrow = needsSubtractionTenBridge(fact.a, fact.b);
        if (actual != expected &&
            needsBorrow &&
            _looksLikeDigitwiseSubtraction(fact, actual)) {
          return ErrorPattern.borrowAvoided;
        }
        if (needsBorrow) return ErrorPattern.tenBridge;
        if ((actual - expected).abs() == 1) return ErrorPattern.countingStep;
        if ((actual - expected).abs() >= 10 &&
            (actual - expected).abs() % 10 == 0) {
          return ErrorPattern.placeValue;
        }
        return ErrorPattern.numberBond;

      case MathOperation.multiply:
        if (actual != expected && actual == fact.a + fact.b) {
          return ErrorPattern.multiplicationAsAddition;
        }
        return ErrorPattern.multiplicationFact;

      case MathOperation.divide:
        if (actual != expected && actual == fact.a - fact.b) {
          return ErrorPattern.divisionAsSubtraction;
        }
        if (actual == fact.a * fact.b) return ErrorPattern.operationChoice;
        return ErrorPattern.divisionFact;
    }
  }

  static bool _usedOnlyPartOfSecondOperand(
    MathFact fact,
    int actual,
  ) {
    if (fact.b < 10) return false;
    final ones = fact.b % 10;
    final higherPlaces = fact.b - ones;
    return switch (fact.operation) {
      MathOperation.plus =>
        actual == fact.a + ones || actual == fact.a + higherPlaces,
      MathOperation.minus =>
        actual == fact.a - ones || actual == fact.a - higherPlaces,
      _ => false,
    };
  }

  static bool _looksLikeDigitwiseSubtraction(
    MathFact fact,
    int actual,
  ) {
    if (fact.a < 10 || fact.b < 0 || actual < 0) return false;
    var left = fact.a;
    var right = fact.b;
    var place = 1;
    var digitwise = 0;
    while (left > 0 || right > 0) {
      digitwise += ((left % 10) - (right % 10)).abs() * place;
      left ~/= 10;
      right ~/= 10;
      place *= 10;
    }
    return actual == digitwise;
  }

  static ErrorPattern _transferStoryPattern(
    String key, {
    required int expected,
    required int actual,
  }) {
    final parts = key.split(':');
    if (parts.length < 8) return ErrorPattern.wordProblem;
    final a = int.tryParse(parts[6]);
    final b = int.tryParse(parts[7]);
    if (a == null || b == null) return ErrorPattern.wordProblem;
    final operation = switch (parts[4]) {
      '+' => MathOperation.plus,
      '-' => MathOperation.minus,
      'x' => MathOperation.multiply,
      'divide' => MathOperation.divide,
      _ => null,
    };
    if (operation == null) return ErrorPattern.wordProblem;
    return _classifyFact(
      mode: TrainingMode.wordProblems,
      fact: MathFact(a: a, b: b, operation: operation),
      expected: expected,
      actual: actual,
    );
  }

  static ErrorPattern _storyCalculationPattern(
    String key, {
    required int expected,
    required int actual,
  }) {
    final parts = key.split(':');
    if (parts.length < 5) return ErrorPattern.wordProblem;
    final a = int.tryParse(parts[3]);
    final b = int.tryParse(parts[4]);
    if (a == null || b == null) return ErrorPattern.wordProblem;
    final operation = switch (parts[2]) {
      '+' => MathOperation.plus,
      '-' => MathOperation.minus,
      'x' => MathOperation.multiply,
      'divide' => MathOperation.divide,
      _ => null,
    };
    if (operation == null) return ErrorPattern.wordProblem;
    return _classifyFact(
      mode: TrainingMode.wordProblems,
      fact: MathFact(a: a, b: b, operation: operation),
      expected: expected,
      actual: actual,
    );
  }

  static ErrorPattern _mentalPattern(
    String key, {
    required int expected,
    required int actual,
  }) {
    final parts = key.split(':');
    if (parts.length < 4) return ErrorPattern.mentalStrategy;
    final a = int.tryParse(parts[2]);
    final b = int.tryParse(parts[3]);
    if (a == null || b == null) return ErrorPattern.mentalStrategy;

    final operation = switch (parts[1]) {
      '+' => MathOperation.plus,
      '-' => MathOperation.minus,
      _ => null,
    };
    if (operation == null) return ErrorPattern.mentalStrategy;

    final fact = MathFact(a: a, b: b, operation: operation);
    if (operation == MathOperation.plus && a >= b && actual == a - b) {
      return ErrorPattern.operationChoice;
    }
    if (operation == MathOperation.minus && actual == a + b) {
      return ErrorPattern.operationChoice;
    }
    if (_usedOnlyPartOfSecondOperand(fact, actual)) {
      return ErrorPattern.partialOperand;
    }
    if (operation == MathOperation.plus &&
        needsAdditionTenBridge(a, b) &&
        actual == expected - 10) {
      return ErrorPattern.carryOmitted;
    }
    if (operation == MathOperation.minus &&
        needsSubtractionTenBridge(a, b) &&
        _looksLikeDigitwiseSubtraction(fact, actual)) {
      return ErrorPattern.borrowAvoided;
    }
    if ((actual - expected).abs() == 1) return ErrorPattern.countingStep;
    if ((actual - expected).abs() >= 10 &&
        (actual - expected).abs() % 10 == 0) {
      return ErrorPattern.placeValue;
    }
    return ErrorPattern.mentalStrategy;
  }

  static ErrorPattern _writtenAddSubPattern(
    String key, {
    required int expected,
    required int actual,
  }) {
    final parts = key.split(':');
    if (parts.length < 4) return ErrorPattern.writtenProcedure;
    final a = int.tryParse(parts[2]);
    final b = int.tryParse(parts[3]);
    if (a == null || b == null) return ErrorPattern.writtenProcedure;

    final operation = switch (parts[1]) {
      '+' => MathOperation.plus,
      '-' => MathOperation.minus,
      _ => null,
    };
    if (operation == null) return ErrorPattern.writtenProcedure;

    final fact = MathFact(a: a, b: b, operation: operation);
    if (operation == MathOperation.plus && a >= b && actual == a - b) {
      return ErrorPattern.operationChoice;
    }
    if (operation == MathOperation.minus && actual == a + b) {
      return ErrorPattern.operationChoice;
    }
    if (_usedOnlyPartOfSecondOperand(fact, actual)) {
      return ErrorPattern.partialOperand;
    }
    if (operation == MathOperation.plus &&
        _additionNeedsCarry(a, b) &&
        actual == expected - 10) {
      return ErrorPattern.carryOmitted;
    }
    if (operation == MathOperation.minus &&
        _subtractionNeedsBorrow(a, b) &&
        _looksLikeDigitwiseSubtraction(fact, actual)) {
      return ErrorPattern.borrowAvoided;
    }
    if ((actual - expected).abs() >= 10 &&
        (actual - expected).abs() % 10 == 0) {
      return ErrorPattern.placeValue;
    }
    return ErrorPattern.writtenProcedure;
  }

  static ErrorPattern _moneyPattern(
    String key, {
    required int expected,
    required int actual,
  }) {
    final parts = key.split(':');
    if (parts.length >= 4 &&
        parts[1] == 'convert' &&
        parts[2] == 'euro-cent') {
      return ErrorPattern.unitConversion;
    }
    if (parts.length >= 5 &&
        (parts[1] == 'add' || parts[1] == 'change')) {
      final first = int.tryParse(parts[parts.length - 2]);
      final second = int.tryParse(parts.last);
      if (first != null && second != null && actual != expected) {
        if (parts[1] == 'add' && first >= second && actual == first - second) {
          return ErrorPattern.operationChoice;
        }
        if (parts[1] == 'change' && actual == first + second) {
          return ErrorPattern.operationChoice;
        }
      }
    }
    if (parts.length >= 5 && parts[1] == 'missing') {
      final total = int.tryParse(parts[parts.length - 2]);
      final known = int.tryParse(parts.last);
      if (total != null &&
          known != null &&
          actual != expected &&
          actual == total + known) {
        return ErrorPattern.operationChoice;
      }
    }
    return ErrorPattern.moneyCalculation;
  }

  static ErrorPattern _perimeterAreaPattern(
    String key, {
    required int expected,
    required int actual,
  }) {
    final parts = key.split(':');
    if (parts.length < 5 || parts[0] != 'rect') {
      return ErrorPattern.perimeterArea;
    }
    final width = int.tryParse(parts[3]);
    final height = int.tryParse(parts[4]);
    if (width == null || height == null || width <= 0 || height <= 0) {
      return ErrorPattern.perimeterArea;
    }
    final area = width * height;
    final perimeter = 2 * (width + height);
    if (parts[1] == 'area') {
      if (actual == perimeter && actual != expected) {
        return ErrorPattern.perimeterArea;
      }
      if (actual == width + height && actual != expected) {
        return ErrorPattern.areaStructure;
      }
      return ErrorPattern.areaStructure;
    }
    if (parts[1] == 'perimeter') {
      if (actual == area && actual != expected) {
        return ErrorPattern.perimeterArea;
      }
      if (actual == width + height && actual != expected) {
        return ErrorPattern.perimeterEdges;
      }
      if ((actual == 2 * width + height || actual == width + 2 * height) &&
          actual != expected) {
        return ErrorPattern.perimeterEdges;
      }
      return ErrorPattern.perimeterEdges;
    }
    return ErrorPattern.perimeterArea;
  }

  static ErrorPattern _fractionPattern(
    String key, {
    required int expected,
    required int actual,
  }) {
    final parts = key.split(':');
    if (parts.length == 3 &&
        (parts[1] == 'half' || parts[1] == 'quarter')) {
      final whole = int.tryParse(parts[2]);
      final denominator = parts[1] == 'half' ? 2 : 4;
      if (whole != null && whole > 0 && actual != expected) {
        if (actual == whole * denominator) {
          return ErrorPattern.operationChoice;
        }
        if (actual == denominator) {
          return ErrorPattern.fractionPartCount;
        }
      }
      return ErrorPattern.fractionSinglePart;
    }
    if (parts.length == 5 && parts[1] == 'parts') {
      final numerator = int.tryParse(parts[2]);
      final denominator = int.tryParse(parts[3]);
      final whole = int.tryParse(parts[4]);
      if (numerator != null &&
          denominator != null &&
          whole != null &&
          denominator > 0 &&
          whole % denominator == 0 &&
          actual != expected) {
        final onePart = whole ~/ denominator;
        if (numerator > 1 && actual == onePart) {
          return ErrorPattern.fractionPartCount;
        }
        if (actual == whole * denominator || actual == whole * numerator) {
          return ErrorPattern.operationChoice;
        }
        if (actual == denominator || actual == numerator) {
          return ErrorPattern.fractionPartCount;
        }
      }
      return ErrorPattern.fractionPart;
    }
    return ErrorPattern.fractionPart;
  }

  static ErrorPattern _timePattern(String key) {
    if (key.startsWith('duration:weeks:') ||
        key.startsWith('duration:days:')) {
      return ErrorPattern.unitConversion;
    }
    if (key.startsWith('calendar:add:')) {
      return ErrorPattern.calendarDate;
    }
    return ErrorPattern.timeDuration;
  }

  static ErrorPattern _measurePattern(
    String key, {
    required int expected,
    required int actual,
  }) {
    final parts = key.split(':');
    if (parts.length >= 5 && parts[1] == 'add') {
      final a = int.tryParse(parts[parts.length - 2]);
      final b = int.tryParse(parts.last);
      if (a != null &&
          b != null &&
          actual != expected &&
          a >= b &&
          actual == a - b) {
        return ErrorPattern.operationChoice;
      }
    }
    if (parts.length >= 5 && parts[1] == 'subtract') {
      final a = int.tryParse(parts[parts.length - 2]);
      final b = int.tryParse(parts.last);
      if (a != null &&
          b != null &&
          actual != expected &&
          actual == a + b) {
        return ErrorPattern.operationChoice;
      }
    }
    if (parts.length >= 5 &&
        (parts[1] == 'add' || parts[1] == 'subtract')) {
      return ErrorPattern.measurementCalculation;
    }
    return ErrorPattern.unitConversion;
  }

  static ErrorPattern _writtenMultiplyPattern(
    String key, {
    required int expected,
    required int actual,
  }) {
    final parts = key.split(':');
    if (parts.length < 4 || parts[1] != 'x') {
      return ErrorPattern.writtenProcedure;
    }
    final a = int.tryParse(parts[2]);
    final b = int.tryParse(parts[3]);
    if (a == null || b == null) return ErrorPattern.writtenProcedure;

    if (actual != expected && actual == a + b) {
      return ErrorPattern.multiplicationAsAddition;
    }
    if (a >= b && actual == a - b) return ErrorPattern.operationChoice;
    if (b != 0 && a % b == 0 && actual == a ~/ b) {
      return ErrorPattern.operationChoice;
    }
    return ErrorPattern.writtenProcedure;
  }

  static ErrorPattern _writtenDividePattern(
    String key, {
    required int expected,
    required int actual,
  }) {
    final parts = key.split(':');
    if (parts.length < 4 ||
        (parts[1] != 'divide' && parts[1] != 'divide-rest')) {
      return ErrorPattern.writtenProcedure;
    }
    final dividend = int.tryParse(parts[2]);
    final divisor = int.tryParse(parts[3]);
    if (dividend == null || divisor == null || divisor == 0) {
      return ErrorPattern.writtenProcedure;
    }

    if (actual != expected && actual == dividend - divisor) {
      return ErrorPattern.divisionAsSubtraction;
    }
    if (actual == dividend * divisor || actual == dividend + divisor) {
      return ErrorPattern.operationChoice;
    }
    return ErrorPattern.writtenProcedure;
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
