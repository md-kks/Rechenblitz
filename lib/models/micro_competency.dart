import 'math_fact.dart';
import 'training.dart';

enum MicroCompetencyDomain {
  numberSense,
  arithmetic,
  writtenMethods,
  measuresAndProblems,
  geometry,
  dataAndChance,
}

extension MicroCompetencyDomainX on MicroCompetencyDomain {
  String get label => switch (this) {
        MicroCompetencyDomain.numberSense => 'Zahlen & Zahlverständnis',
        MicroCompetencyDomain.arithmetic => 'Rechnen & Strategien',
        MicroCompetencyDomain.writtenMethods => 'Schriftliche Verfahren',
        MicroCompetencyDomain.measuresAndProblems =>
          'Größen & Sachrechnen',
        MicroCompetencyDomain.geometry => 'Geometrie',
        MicroCompetencyDomain.dataAndChance => 'Daten & Zufall',
      };
}

enum MicroCompetencyId {
  countingNeighbors,
  numberDecomposition,
  placeValueDigits,
  placeValueDecompose,
  largeNumberCompare,
  largeNumberOrder,
  numberWordReading,
  additionNoBridge,
  additionTenBridge,
  subtractionNoBridge,
  subtractionTenBridge,
  doublesHalves,
  multiplicationGroups,
  multiplicationFacts,
  divisionSharing,
  divisionFacts,
  inverseRelationship,
  numberPatterns,
  numberRelations,
  wordProblemRelevantInformation,
  wordProblemOperation,
  wordProblemModel,
  wordProblemCalculation,
  wordProblemInterpretation,
  moneyCalculation,
  clockReading,
  measurementCalculation,
  unitConversion,
  secondsConversion,
  shapeProperties,
  roundingPlace,
  mentalStrategy,
  strategyChoice,
  writtenAlignment,
  writtenRegrouping,
  errorChecking,
  writtenMultiplyProcedure,
  writtenDivideProcedure,
  estimation,
  plausibilityCheck,
  arithmeticLaw,
  reasoningJustification,
  representationTranslation,
  romanNumeral,
  fractionEqualParts,
  timeDuration,
  calendarDate,
  dataReading,
  tallyTableReading,
  dataRepresentationChoice,
  probabilityReasoning,
  probabilityExperiment,
  combinatoricsSystematic,
  proportionalUnit,
  perimeter,
  area,
  lineRelations,
  rightAngle,
  figureClassification,
  circleParts,
  geometryBodies,
  cubeNetFoldability,
  symmetryAxes,
  planDirections,
  scale,
  volumeCubes,
}

class MicroCompetencyDefinition {
  const MicroCompetencyDefinition({
    required this.id,
    required this.label,
    required this.description,
    required this.domain,
    required this.preferredMode,
    required this.minGrade,
    this.prerequisites = const <MicroCompetencyId>[],
  });

  final MicroCompetencyId id;
  final String label;
  final String description;
  final MicroCompetencyDomain domain;
  final TrainingMode preferredMode;
  final GradeLevel minGrade;
  final List<MicroCompetencyId> prerequisites;

  bool appliesTo(GradeLevel grade) => grade.index >= minGrade.index;
}

class MicroCompetencyTag {
  const MicroCompetencyTag(
    this.id, {
    this.weight = 1.0,
  });

  final MicroCompetencyId id;
  final double weight;
}

enum MicroEvidenceSource { practice, remediation, transfer }

class MicroCompetencyObservation {
  const MicroCompetencyObservation({
    required this.id,
    required this.occurredAt,
    required this.correct,
    required this.evidenceWeight,
    required this.source,
    required this.usedHelp,
    this.helpLevel = 0,
    this.methodKey,
    required this.mode,
    required this.gradeLevel,
    required this.numberRange,
    required this.taskKey,
  });

  final MicroCompetencyId id;
  final DateTime occurredAt;
  final bool correct;
  final double evidenceWeight;
  final MicroEvidenceSource source;
  final bool usedHelp;
  final int helpLevel;
  final String? methodKey;
  final TrainingMode mode;
  final GradeLevel gradeLevel;
  final NumberRangeLevel numberRange;
  final String taskKey;

  Map<String, dynamic> toJson() => {
        'id': id.name,
        'occurredAt': occurredAt.toIso8601String(),
        'correct': correct,
        'evidenceWeight': evidenceWeight,
        'source': source.name,
        'usedHelp': usedHelp,
        'helpLevel': helpLevel,
        'methodKey': methodKey,
        'mode': mode.name,
        'gradeLevel': gradeLevel.name,
        'numberRange': numberRange.name,
        'taskKey': taskKey,
      };

  factory MicroCompetencyObservation.fromJson(
    Map<String, dynamic> json,
  ) =>
      MicroCompetencyObservation(
        id: MicroCompetencyId.values.byName(json['id'] as String),
        occurredAt: DateTime.tryParse(
              json['occurredAt'] as String? ?? '',
            ) ??
            DateTime(2026, 1, 1),
        correct: json['correct'] as bool? ?? false,
        evidenceWeight:
            (json['evidenceWeight'] as num?)?.toDouble() ?? 1.0,
        source: json['source'] == null
            ? MicroEvidenceSource.practice
            : MicroEvidenceSource.values.byName(
                json['source'] as String,
              ),
        usedHelp: json['usedHelp'] as bool? ?? false,
        helpLevel: json['helpLevel'] as int? ?? ((json['usedHelp'] as bool? ?? false) ? 1 : 0),
        methodKey: json['methodKey'] as String?,
        mode: TrainingMode.values.byName(json['mode'] as String),
        gradeLevel: GradeLevel.values.byName(
          json['gradeLevel'] as String,
        ),
        numberRange: NumberRangeLevel.values.byName(
          json['numberRange'] as String,
        ),
        taskKey: json['taskKey'] as String? ?? '',
      );
}

enum MicroCompetencyState {
  newSkill,
  discovering,
  practicing,
  secure,
  mastered,
}

extension MicroCompetencyStateX on MicroCompetencyState {
  String get label => switch (this) {
        MicroCompetencyState.newSkill => 'Neu',
        MicroCompetencyState.discovering => 'Entdecken',
        MicroCompetencyState.practicing => 'Wird geübt',
        MicroCompetencyState.secure => 'Sicher',
        MicroCompetencyState.mastered => 'Gemeistert',
      };
}

class MicroCompetencyProgress {
  const MicroCompetencyProgress({
    required this.definition,
    required this.state,
    required this.accuracy,
    required this.evidence,
    required this.observations,
    this.baseAccuracy = 0,
    this.transferAccuracy = 0,
    this.baseEvidence = 0,
    this.transferEvidence = 0,
    this.transferObservations = 0,
    this.lastSeen,
    this.lastTransferSeen,
  });

  final MicroCompetencyDefinition definition;
  final MicroCompetencyState state;
  final double accuracy;
  final double evidence;
  final int observations;
  final double baseAccuracy;
  final double transferAccuracy;
  final double baseEvidence;
  final double transferEvidence;
  final int transferObservations;
  final DateTime? lastSeen;
  final DateTime? lastTransferSeen;
}

class MicroCompetencyCatalog {
  const MicroCompetencyCatalog._();

  static const definitions = <MicroCompetencyDefinition>[
    MicroCompetencyDefinition(
      id: MicroCompetencyId.countingNeighbors,
      label: 'Nachbarzahlen sicher bestimmen',
      description: 'Einen Schritt vor oder zurück in der Zahlreihe gehen.',
      domain: MicroCompetencyDomain.numberSense,
      preferredMode: TrainingMode.neighbors,
      minGrade: GradeLevel.first,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.numberDecomposition,
      label: 'Zahlen sinnvoll zerlegen',
      description: 'Zahlen in passende Teilmengen zerlegen und ergänzen.',
      domain: MicroCompetencyDomain.numberSense,
      preferredMode: TrainingMode.numberFriends,
      minGrade: GradeLevel.first,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.placeValueDigits,
      label: 'Stellenwerte erkennen',
      description: 'Einer, Zehner, Hunderter und größere Stellen zuordnen.',
      domain: MicroCompetencyDomain.numberSense,
      preferredMode: TrainingMode.placeValue,
      minGrade: GradeLevel.first,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.placeValueDecompose,
      label: 'Zahlen nach Stellen zerlegen',
      description: 'Eine Zahl als Summe ihrer Stellenwerte darstellen.',
      domain: MicroCompetencyDomain.numberSense,
      preferredMode: TrainingMode.largeNumbers,
      minGrade: GradeLevel.third,
      prerequisites: [MicroCompetencyId.placeValueDigits],
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.largeNumberCompare,
      label: 'Große Zahlen vergleichen',
      description: 'Große Zahlen ordnen und ihre Größe vergleichen.',
      domain: MicroCompetencyDomain.numberSense,
      preferredMode: TrainingMode.largeNumbers,
      minGrade: GradeLevel.third,
      prerequisites: [MicroCompetencyId.placeValueDigits],
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.largeNumberOrder,
      label: 'Mehrere große Zahlen ordnen',
      description: 'Drei oder mehr große Zahlen der Größe nach anordnen.',
      domain: MicroCompetencyDomain.numberSense,
      preferredMode: TrainingMode.largeNumbers,
      minGrade: GradeLevel.third,
      prerequisites: [MicroCompetencyId.largeNumberCompare],
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.numberWordReading,
      label: 'Zahlwörter und Ziffern verbinden',
      description: 'Große Zahlen als deutsches Zahlwort lesen und der passenden Zifferndarstellung zuordnen.',
      domain: MicroCompetencyDomain.numberSense,
      preferredMode: TrainingMode.largeNumbers,
      minGrade: GradeLevel.third,
      prerequisites: [MicroCompetencyId.placeValueDigits],
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.additionNoBridge,
      label: 'Plus ohne Zehnerübergang',
      description: 'Additionsaufgaben ohne Übergang sicher lösen.',
      domain: MicroCompetencyDomain.arithmetic,
      preferredMode: TrainingMode.practice,
      minGrade: GradeLevel.first,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.additionTenBridge,
      label: 'Plus über den Zehner',
      description: 'Beim Addieren gezielt über einen Zehner rechnen.',
      domain: MicroCompetencyDomain.arithmetic,
      preferredMode: TrainingMode.practice,
      minGrade: GradeLevel.first,
      prerequisites: [
        MicroCompetencyId.numberDecomposition,
        MicroCompetencyId.additionNoBridge,
      ],
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.subtractionNoBridge,
      label: 'Minus ohne Zehnerübergang',
      description: 'Subtraktionsaufgaben ohne Übergang sicher lösen.',
      domain: MicroCompetencyDomain.arithmetic,
      preferredMode: TrainingMode.minus,
      minGrade: GradeLevel.first,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.subtractionTenBridge,
      label: 'Minus über den Zehner',
      description: 'Beim Subtrahieren gezielt über einen Zehner rechnen.',
      domain: MicroCompetencyDomain.arithmetic,
      preferredMode: TrainingMode.minus,
      minGrade: GradeLevel.first,
      prerequisites: [
        MicroCompetencyId.numberDecomposition,
        MicroCompetencyId.subtractionNoBridge,
      ],
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.doublesHalves,
      label: 'Doppelte und Hälften',
      description: 'Verdoppeln und Halbieren als Zahlbeziehungen nutzen.',
      domain: MicroCompetencyDomain.arithmetic,
      preferredMode: TrainingMode.doublesHalves,
      minGrade: GradeLevel.first,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.multiplicationGroups,
      label: 'Mal als gleich große Gruppen',
      description: 'Multiplikation als wiederholte gleich große Gruppen verstehen.',
      domain: MicroCompetencyDomain.arithmetic,
      preferredMode: TrainingMode.multiply,
      minGrade: GradeLevel.second,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.multiplicationFacts,
      label: 'Einmaleins-Grundaufgaben',
      description: 'Einmaleins-Fakten sicher abrufen oder herleiten.',
      domain: MicroCompetencyDomain.arithmetic,
      preferredMode: TrainingMode.multiply,
      minGrade: GradeLevel.second,
      prerequisites: [MicroCompetencyId.multiplicationGroups],
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.divisionSharing,
      label: 'Teilen als Verteilen und Gruppieren',
      description: 'Division als gleichmäßiges Verteilen verstehen.',
      domain: MicroCompetencyDomain.arithmetic,
      preferredMode: TrainingMode.divide,
      minGrade: GradeLevel.second,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.divisionFacts,
      label: 'Geteilt-Grundaufgaben',
      description: 'Divisionsaufgaben mit passenden Malaufgaben verknüpfen.',
      domain: MicroCompetencyDomain.arithmetic,
      preferredMode: TrainingMode.divide,
      minGrade: GradeLevel.second,
      prerequisites: [
        MicroCompetencyId.divisionSharing,
        MicroCompetencyId.multiplicationFacts,
      ],
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.inverseRelationship,
      label: 'Umkehraufgaben nutzen',
      description: 'Plus und Minus sowie Mal und Teilen miteinander verknüpfen.',
      domain: MicroCompetencyDomain.arithmetic,
      preferredMode: TrainingMode.factFamilies,
      minGrade: GradeLevel.first,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.numberPatterns,
      label: 'Musterregeln erkennen',
      description: 'Zahlenfolgen untersuchen und sinnvoll fortsetzen.',
      domain: MicroCompetencyDomain.numberSense,
      preferredMode: TrainingMode.sequences,
      minGrade: GradeLevel.first,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.numberRelations,
      label: 'Zahlbeziehungen nutzen',
      description: 'Beziehungen zwischen Zahlen in Strukturen erkennen.',
      domain: MicroCompetencyDomain.numberSense,
      preferredMode: TrainingMode.numberWall,
      minGrade: GradeLevel.first,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.wordProblemRelevantInformation,
      label: 'Wichtige Angaben in Sachaufgaben erkennen',
      description: 'Für eine Sachfrage benötigte Angaben von unwichtigen Informationen unterscheiden.',
      domain: MicroCompetencyDomain.measuresAndProblems,
      preferredMode: TrainingMode.wordProblems,
      minGrade: GradeLevel.first,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.wordProblemOperation,
      label: 'Passende Rechenart aus Text erkennen',
      description: 'Eine Handlung in einer Sachaufgabe der passenden Rechenart zuordnen.',
      domain: MicroCompetencyDomain.measuresAndProblems,
      preferredMode: TrainingMode.wordProblems,
      minGrade: GradeLevel.first,
      prerequisites: [MicroCompetencyId.wordProblemRelevantInformation],
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.wordProblemModel,
      label: 'Sachlage als Rechnung darstellen',
      description: 'Die wichtigen Angaben einer Sachaufgabe in eine passende Rechnung übersetzen.',
      domain: MicroCompetencyDomain.measuresAndProblems,
      preferredMode: TrainingMode.wordProblems,
      minGrade: GradeLevel.first,
      prerequisites: [MicroCompetencyId.wordProblemOperation],
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.wordProblemCalculation,
      label: 'Sachaufgabe rechnerisch lösen',
      description: 'Eine passend modellierte Sachaufgabe korrekt ausrechnen.',
      domain: MicroCompetencyDomain.measuresAndProblems,
      preferredMode: TrainingMode.wordProblems,
      minGrade: GradeLevel.first,
      prerequisites: [MicroCompetencyId.wordProblemModel],
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.wordProblemInterpretation,
      label: 'Ergebnis im Sachzusammenhang deuten',
      description: 'Ein Rechenergebnis passend zur Frage und Situation als Antwort verstehen.',
      domain: MicroCompetencyDomain.measuresAndProblems,
      preferredMode: TrainingMode.wordProblems,
      minGrade: GradeLevel.first,
      prerequisites: [MicroCompetencyId.wordProblemCalculation],
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.moneyCalculation,
      label: 'Mit Geld rechnen',
      description: 'Preise, Restgeld und Geldumwandlungen sicher bearbeiten.',
      domain: MicroCompetencyDomain.measuresAndProblems,
      preferredMode: TrainingMode.money,
      minGrade: GradeLevel.first,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.clockReading,
      label: 'Uhrzeiten lesen',
      description: 'Analoge und beschriebene Uhrzeiten sicher bestimmen.',
      domain: MicroCompetencyDomain.measuresAndProblems,
      preferredMode: TrainingMode.clock,
      minGrade: GradeLevel.first,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.measurementCalculation,
      label: 'Mit Größen rechnen',
      description: 'Längen und andere Größen in derselben Einheit verrechnen.',
      domain: MicroCompetencyDomain.measuresAndProblems,
      preferredMode: TrainingMode.measures,
      minGrade: GradeLevel.first,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.unitConversion,
      label: 'Einheiten umwandeln',
      description: 'Zwischen passenden Maßeinheiten sicher umrechnen.',
      domain: MicroCompetencyDomain.measuresAndProblems,
      preferredMode: TrainingMode.advancedMeasures,
      minGrade: GradeLevel.second,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.secondsConversion,
      label: 'Minuten und Sekunden umwandeln',
      description: 'Sekunden und Minuten bei Zeitangaben sicher ineinander umrechnen.',
      domain: MicroCompetencyDomain.measuresAndProblems,
      preferredMode: TrainingMode.advancedMeasures,
      minGrade: GradeLevel.third,
      prerequisites: [MicroCompetencyId.clockReading],
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.shapeProperties,
      label: 'Eigenschaften ebener Formen',
      description: 'Seiten, Ecken und Formen sicher unterscheiden.',
      domain: MicroCompetencyDomain.geometry,
      preferredMode: TrainingMode.geometry,
      minGrade: GradeLevel.first,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.roundingPlace,
      label: 'An der richtigen Stelle runden',
      description: 'Rundungsstelle erkennen und korrekt auf- oder abrunden.',
      domain: MicroCompetencyDomain.numberSense,
      preferredMode: TrainingMode.rounding,
      minGrade: GradeLevel.third,
      prerequisites: [MicroCompetencyId.placeValueDigits],
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.mentalStrategy,
      label: 'Halbschriftliche Strategien',
      description: 'Rechenwege in sinnvolle Teilschritte zerlegen.',
      domain: MicroCompetencyDomain.arithmetic,
      preferredMode: TrainingMode.mentalStrategies,
      minGrade: GradeLevel.third,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.strategyChoice,
      label: 'Günstigen Rechenweg auswählen',
      description: 'Zwischen mehreren möglichen Rechenwegen einen passenden Vorteil erkennen.',
      domain: MicroCompetencyDomain.arithmetic,
      preferredMode: TrainingMode.mentalStrategies,
      minGrade: GradeLevel.third,
      prerequisites: [MicroCompetencyId.mentalStrategy],
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.writtenAlignment,
      label: 'Stellen schriftlich richtig anordnen',
      description: 'Einer, Zehner und Hunderter sauber untereinander schreiben.',
      domain: MicroCompetencyDomain.writtenMethods,
      preferredMode: TrainingMode.writtenAddSub,
      minGrade: GradeLevel.third,
      prerequisites: [MicroCompetencyId.placeValueDigits],
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.writtenRegrouping,
      label: 'Übertrag und Entbündeln',
      description: 'Überträge oder Entbündelungen im schriftlichen Verfahren sicher ausführen.',
      domain: MicroCompetencyDomain.writtenMethods,
      preferredMode: TrainingMode.writtenAddSub,
      minGrade: GradeLevel.third,
      prerequisites: [MicroCompetencyId.writtenAlignment],
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.errorChecking,
      label: 'Rechenfehler erkennen',
      description: 'Eine vorgegebene Rechnung prüfen und einen Fehler gezielt beschreiben.',
      domain: MicroCompetencyDomain.writtenMethods,
      preferredMode: TrainingMode.writtenAddSub,
      minGrade: GradeLevel.third,
      prerequisites: [MicroCompetencyId.writtenAlignment],
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.writtenMultiplyProcedure,
      label: 'Schriftlich multiplizieren',
      description: 'Teilprodukte und Stellen im schriftlichen Malverfahren korrekt bearbeiten.',
      domain: MicroCompetencyDomain.writtenMethods,
      preferredMode: TrainingMode.writtenMultiply,
      minGrade: GradeLevel.third,
      prerequisites: [MicroCompetencyId.multiplicationFacts],
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.writtenDivideProcedure,
      label: 'Schriftlich dividieren',
      description: 'Schriftliche Division schrittweise und kontrolliert ausführen.',
      domain: MicroCompetencyDomain.writtenMethods,
      preferredMode: TrainingMode.writtenDivide,
      minGrade: GradeLevel.third,
      prerequisites: [MicroCompetencyId.divisionFacts],
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.estimation,
      label: 'Mit Überschlag kontrollieren',
      description: 'Ergebnisse durch sinnvolles Runden grob prüfen.',
      domain: MicroCompetencyDomain.arithmetic,
      preferredMode: TrainingMode.estimation,
      minGrade: GradeLevel.third,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.plausibilityCheck,
      label: 'Ergebnisse auf Plausibilität prüfen',
      description: 'Mit einem Überschlag beurteilen, ob ein Ergebnis zur Größenordnung passt.',
      domain: MicroCompetencyDomain.arithmetic,
      preferredMode: TrainingMode.estimation,
      minGrade: GradeLevel.third,
      prerequisites: [MicroCompetencyId.roundingPlace],
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.arithmeticLaw,
      label: 'Rechenvorteile erkennen',
      description: 'Tausch-, Klammer- und Verteilungsgesetze sinnvoll nutzen.',
      domain: MicroCompetencyDomain.arithmetic,
      preferredMode: TrainingMode.arithmeticLaws,
      minGrade: GradeLevel.third,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.reasoningJustification,
      label: 'Rechenbeziehungen begründen',
      description:
          'Zu einem Rechenweg eine mathematisch passende Begründung auswählen und nachvollziehen.',
      domain: MicroCompetencyDomain.arithmetic,
      preferredMode: TrainingMode.arithmeticLaws,
      minGrade: GradeLevel.third,
      prerequisites: [MicroCompetencyId.arithmeticLaw],
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.representationTranslation,
      label: 'Zwischen Darstellungen wechseln',
      description:
          'Dieselbe Zahl oder Rechenidee in Stellenwert-, Zerlegungs-, Gruppen- und Symbolform wiedererkennen und übertragen.',
      domain: MicroCompetencyDomain.arithmetic,
      preferredMode: TrainingMode.wordProblems,
      minGrade: GradeLevel.first,
      prerequisites: [MicroCompetencyId.numberDecomposition],
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.romanNumeral,
      label: 'Römische Zahlen lesen',
      description: 'Römische Zahlzeichen lesen und zusammensetzen.',
      domain: MicroCompetencyDomain.numberSense,
      preferredMode: TrainingMode.romanNumerals,
      minGrade: GradeLevel.third,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.fractionEqualParts,
      label: 'Bruchteile als gleiche Teile',
      description: 'Ein Ganzes in gleich große Teile zerlegen und Anteile bestimmen.',
      domain: MicroCompetencyDomain.arithmetic,
      preferredMode: TrainingMode.fractions,
      minGrade: GradeLevel.third,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.timeDuration,
      label: 'Zeitspannen berechnen',
      description: 'Dauer zwischen Start- und Endzeit bestimmen.',
      domain: MicroCompetencyDomain.measuresAndProblems,
      preferredMode: TrainingMode.timeDurations,
      minGrade: GradeLevel.third,
      prerequisites: [MicroCompetencyId.clockReading],
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.calendarDate,
      label: 'Mit Datum und Kalender rechnen',
      description: 'Tage, Wochen und Datumsangaben sicher miteinander verknüpfen.',
      domain: MicroCompetencyDomain.measuresAndProblems,
      preferredMode: TrainingMode.timeDurations,
      minGrade: GradeLevel.third,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.dataReading,
      label: 'Daten und Diagramme lesen',
      description: 'Werte aus Tabellen und Diagrammen entnehmen und vergleichen.',
      domain: MicroCompetencyDomain.dataAndChance,
      preferredMode: TrainingMode.dataCharts,
      minGrade: GradeLevel.third,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.tallyTableReading,
      label: 'Strichlisten und Tabellen auswerten',
      description: 'Gezählte Daten aus Strichlisten und einfachen Tabellen sicher ablesen.',
      domain: MicroCompetencyDomain.dataAndChance,
      preferredMode: TrainingMode.dataCharts,
      minGrade: GradeLevel.third,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.dataRepresentationChoice,
      label: 'Passende Datendarstellung wählen',
      description: 'Für eine Fragestellung sinnvoll zwischen Strichliste, Tabelle und Diagramm auswählen.',
      domain: MicroCompetencyDomain.dataAndChance,
      preferredMode: TrainingMode.dataCharts,
      minGrade: GradeLevel.third,
      prerequisites: [MicroCompetencyId.dataReading],
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.probabilityReasoning,
      label: 'Wahrscheinlichkeiten einschätzen',
      description: 'Sicher, möglich und unmöglich unterscheiden und Chancen vergleichen.',
      domain: MicroCompetencyDomain.dataAndChance,
      preferredMode: TrainingMode.probability,
      minGrade: GradeLevel.third,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.probabilityExperiment,
      label: 'Zufallsexperimente auswerten',
      description: 'Ergebnisse wiederholter Zufallsversuche zählen, vergleichen und vorsichtig deuten.',
      domain: MicroCompetencyDomain.dataAndChance,
      preferredMode: TrainingMode.probability,
      minGrade: GradeLevel.fourth,
      prerequisites: [MicroCompetencyId.probabilityReasoning],
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.combinatoricsSystematic,
      label: 'Möglichkeiten systematisch finden',
      description: 'Kombinationen vollständig und geordnet erfassen.',
      domain: MicroCompetencyDomain.dataAndChance,
      preferredMode: TrainingMode.combinatorics,
      minGrade: GradeLevel.third,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.proportionalUnit,
      label: 'Über eine Einheit zuordnen',
      description: 'Zuerst den Wert einer Einheit bestimmen und weiterrechnen.',
      domain: MicroCompetencyDomain.measuresAndProblems,
      preferredMode: TrainingMode.proportionality,
      minGrade: GradeLevel.third,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.perimeter,
      label: 'Umfang als Rand berechnen',
      description: 'Den Rand einer Figur erkennen und seine Länge bestimmen.',
      domain: MicroCompetencyDomain.geometry,
      preferredMode: TrainingMode.perimeterArea,
      minGrade: GradeLevel.third,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.area,
      label: 'Flächeninhalt bestimmen',
      description: 'Das Innere einer Fläche erfassen und berechnen.',
      domain: MicroCompetencyDomain.geometry,
      preferredMode: TrainingMode.perimeterArea,
      minGrade: GradeLevel.third,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.lineRelations,
      label: 'Parallel und senkrecht unterscheiden',
      description: 'Lagebeziehungen von Geraden sicher erkennen und benennen.',
      domain: MicroCompetencyDomain.geometry,
      preferredMode: TrainingMode.geometryRelations,
      minGrade: GradeLevel.third,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.rightAngle,
      label: 'Rechte Winkel erkennen',
      description: 'Rechte Winkel in Figuren und Alltagssituationen sicher erkennen.',
      domain: MicroCompetencyDomain.geometry,
      preferredMode: TrainingMode.geometryRelations,
      minGrade: GradeLevel.third,
      prerequisites: [MicroCompetencyId.lineRelations],
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.figureClassification,
      label: 'Dreiecke und Vierecke beschreiben',
      description: 'Figuren über Seiten, Winkel und besondere Eigenschaften einordnen.',
      domain: MicroCompetencyDomain.geometry,
      preferredMode: TrainingMode.geometryRelations,
      minGrade: GradeLevel.third,
      prerequisites: [MicroCompetencyId.rightAngle],
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.circleParts,
      label: 'Kreisbegriffe sicher verwenden',
      description: 'Mittelpunkt, Radius und Durchmesser unterscheiden.',
      domain: MicroCompetencyDomain.geometry,
      preferredMode: TrainingMode.geometryRelations,
      minGrade: GradeLevel.third,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.geometryBodies,
      label: 'Körper und Netze untersuchen',
      description: 'Ecken, Kanten, Flächen und Netze räumlicher Körper erkennen.',
      domain: MicroCompetencyDomain.geometry,
      preferredMode: TrainingMode.geometryBodies,
      minGrade: GradeLevel.third,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.cubeNetFoldability,
      label: 'Würfelnetze auf Faltbarkeit prüfen',
      description: 'Anordnungen aus sechs Quadraten darauf untersuchen, ob sie sich ohne Überlappung zu einem Würfel falten lassen.',
      domain: MicroCompetencyDomain.geometry,
      preferredMode: TrainingMode.geometryBodies,
      minGrade: GradeLevel.third,
      prerequisites: [MicroCompetencyId.geometryBodies],
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.symmetryAxes,
      label: 'Symmetrieachsen erkennen',
      description: 'Spiegelsymmetrie prüfen und passende Achsen bestimmen.',
      domain: MicroCompetencyDomain.geometry,
      preferredMode: TrainingMode.symmetry,
      minGrade: GradeLevel.third,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.planDirections,
      label: 'Pläne und Wege lesen',
      description: 'Richtungen und Wege in Gittern oder Plänen nachvollziehen.',
      domain: MicroCompetencyDomain.geometry,
      preferredMode: TrainingMode.plansAndOrientation,
      minGrade: GradeLevel.third,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.scale,
      label: 'Einfache Maßstäbe nutzen',
      description: 'Planstrecken und reale Strecken miteinander verknüpfen.',
      domain: MicroCompetencyDomain.geometry,
      preferredMode: TrainingMode.plansAndOrientation,
      minGrade: GradeLevel.fourth,
    ),
    MicroCompetencyDefinition(
      id: MicroCompetencyId.volumeCubes,
      label: 'Rauminhalt mit Würfeln',
      description: 'Schichten aus Einheitswürfeln erfassen und berechnen.',
      domain: MicroCompetencyDomain.geometry,
      preferredMode: TrainingMode.volumeCubes,
      minGrade: GradeLevel.third,
    ),
  ];

  static MicroCompetencyDefinition definition(MicroCompetencyId id) =>
      definitions.firstWhere((value) => value.id == id);

  static List<MicroCompetencyDefinition> forGrade(GradeLevel grade) =>
      definitions.where((value) => value.appliesTo(grade)).toList();

  static List<MicroCompetencyTag> tagsForTask({
    required TrainingMode mode,
    required String taskKey,
    MathFact? fact,
  }) {
    if (fact != null) return _factTags(mode, fact);

    if (taskKey.startsWith('remediation:')) {
      final parts = taskKey.split(':');
      final pattern = parts.length > 1 ? parts[1] : '';
      return switch (pattern) {
        'tenBridge' ||
        'carryOmitted' ||
        'borrowAvoided' => [
            MicroCompetencyTag(
              taskKey.contains(':-:')
                  ? MicroCompetencyId.subtractionTenBridge
                  : MicroCompetencyId.additionTenBridge,
            ),
            const MicroCompetencyTag(
              MicroCompetencyId.numberDecomposition,
              weight: 0.45,
            ),
          ],
        'partialOperand' => const [
            MicroCompetencyTag(MicroCompetencyId.placeValueDigits),
            MicroCompetencyTag(
              MicroCompetencyId.numberDecomposition,
              weight: 0.65,
            ),
          ],
        'numberBond' => const [
            MicroCompetencyTag(MicroCompetencyId.numberDecomposition),
          ],
        'countingStep' => const [
            MicroCompetencyTag(MicroCompetencyId.countingNeighbors),
          ],
        'placeValue' => const [
            MicroCompetencyTag(MicroCompetencyId.placeValueDigits),
          ],
        'multiplicationFact' ||
        'multiplicationAsAddition' => const [
            MicroCompetencyTag(MicroCompetencyId.multiplicationFacts),
            MicroCompetencyTag(
              MicroCompetencyId.multiplicationGroups,
              weight: 0.45,
            ),
          ],
        'divisionFact' ||
        'divisionAsSubtraction' => const [
            MicroCompetencyTag(MicroCompetencyId.divisionFacts),
            MicroCompetencyTag(
              MicroCompetencyId.divisionSharing,
              weight: 0.45,
            ),
          ],
        'inverseOperation' => const [
            MicroCompetencyTag(MicroCompetencyId.inverseRelationship),
          ],
        'wordProblem' => const [
            MicroCompetencyTag(MicroCompetencyId.wordProblemOperation),
            MicroCompetencyTag(
              MicroCompetencyId.wordProblemCalculation,
              weight: 0.65,
            ),
          ],
        'wordProblemRelevantInformation' => const [
            MicroCompetencyTag(
              MicroCompetencyId.wordProblemRelevantInformation,
            ),
          ],
        'wordProblemModel' => const [
            MicroCompetencyTag(MicroCompetencyId.wordProblemModel),
            MicroCompetencyTag(
              MicroCompetencyId.wordProblemOperation,
              weight: 0.45,
            ),
          ],
        'wordProblemInterpretation' => const [
            MicroCompetencyTag(
              MicroCompetencyId.wordProblemInterpretation,
            ),
            MicroCompetencyTag(
              MicroCompetencyId.wordProblemCalculation,
              weight: 0.35,
            ),
          ],
        'representationTranslation' => const [
            MicroCompetencyTag(
              MicroCompetencyId.representationTranslation,
            ),
          ],
        'unitConversion' => const [
            MicroCompetencyTag(MicroCompetencyId.unitConversion),
          ],
        'roundingPlace' => const [
            MicroCompetencyTag(MicroCompetencyId.roundingPlace),
          ],
        'writtenRegrouping' => const [
            MicroCompetencyTag(MicroCompetencyId.writtenRegrouping),
            MicroCompetencyTag(
              MicroCompetencyId.writtenAlignment,
              weight: 0.4,
            ),
          ],
        'fractionPart' => const [
            MicroCompetencyTag(MicroCompetencyId.fractionEqualParts),
          ],
        'timeDuration' => const [
            MicroCompetencyTag(MicroCompetencyId.timeDuration),
          ],
        'perimeterArea' => [
            MicroCompetencyTag(
              taskKey.contains(':area:')
                  ? MicroCompetencyId.area
                  : MicroCompetencyId.perimeter,
            ),
          ],
        _ => const <MicroCompetencyTag>[],
      };
    }

    if (mode == TrainingMode.numberFriends) {
      return const [
        MicroCompetencyTag(MicroCompetencyId.numberDecomposition),
      ];
    }
    if (taskKey.startsWith('wall:')) {
      return const [
        MicroCompetencyTag(MicroCompetencyId.numberRelations),
      ];
    }
    if (taskKey.startsWith('gap:')) {
      return const [
        MicroCompetencyTag(MicroCompetencyId.inverseRelationship),
      ];
    }
    if (taskKey.startsWith('neighbor:')) {
      return const [
        MicroCompetencyTag(MicroCompetencyId.countingNeighbors),
      ];
    }
    if (taskKey.startsWith('place:')) {
      return const [
        MicroCompetencyTag(MicroCompetencyId.placeValueDigits),
      ];
    }
    if (taskKey.startsWith('double:') ||
        taskKey.startsWith('half:')) {
      return const [
        MicroCompetencyTag(MicroCompetencyId.doublesHalves),
      ];
    }
    if (taskKey.startsWith('sequence:')) {
      return const [
        MicroCompetencyTag(MicroCompetencyId.numberPatterns),
      ];
    }
    if (taskKey.startsWith('family:')) {
      return const [
        MicroCompetencyTag(MicroCompetencyId.inverseRelationship),
      ];
    }
    if (taskKey.startsWith('process:representation:')) {
      final groups = taskKey.startsWith('process:representation:groups:') ||
          taskKey.startsWith('process:representation:equation:');
      final tags = <MicroCompetencyTag>[
        const MicroCompetencyTag(
          MicroCompetencyId.representationTranslation,
        ),
      ];
      if (groups) {
        tags.add(
          const MicroCompetencyTag(
            MicroCompetencyId.multiplicationGroups,
            weight: 0.45,
          ),
        );
      } else {
        tags.addAll(
          const [
            MicroCompetencyTag(
              MicroCompetencyId.placeValueDigits,
              weight: 0.45,
            ),
            MicroCompetencyTag(
              MicroCompetencyId.numberDecomposition,
              weight: 0.35,
            ),
          ],
        );
      }
      return tags;
    }
    if (taskKey.startsWith('story:')) {
      return _storyTags(taskKey);
    }
    if (taskKey.startsWith('money:')) {
      return const [
        MicroCompetencyTag(MicroCompetencyId.moneyCalculation),
      ];
    }
    if (taskKey.startsWith('clock:')) {
      return const [
        MicroCompetencyTag(MicroCompetencyId.clockReading),
      ];
    }
    if (taskKey.startsWith('measure:')) {
      final convert = taskKey.contains(':convert:') ||
          taskKey.contains('dm-cm') ||
          taskKey.contains('m-cm') ||
          taskKey.contains('cm-mm') ||
          taskKey.contains('cm-m');
      return [
        MicroCompetencyTag(
          convert
              ? MicroCompetencyId.unitConversion
              : MicroCompetencyId.measurementCalculation,
        ),
      ];
    }
    if (taskKey.startsWith('geometry:')) {
      return const [
        MicroCompetencyTag(MicroCompetencyId.shapeProperties),
      ];
    }

    return _upperPrimaryTags(mode, taskKey);
  }

  static List<MicroCompetencyTag> _factTags(
    TrainingMode mode,
    MathFact fact,
  ) {
    if (mode == TrainingMode.numberFriends) {
      return const [
        MicroCompetencyTag(MicroCompetencyId.numberDecomposition),
      ];
    }

    switch (fact.operation) {
      case MathOperation.plus:
        final bridge = (fact.a % 10) + (fact.b % 10) >= 10;
        return [
          MicroCompetencyTag(
            bridge
                ? MicroCompetencyId.additionTenBridge
                : MicroCompetencyId.additionNoBridge,
          ),
          if (bridge)
            const MicroCompetencyTag(
              MicroCompetencyId.numberDecomposition,
              weight: 0.45,
            ),
        ];
      case MathOperation.minus:
        final bridge = (fact.a % 10) < (fact.b % 10);
        return [
          MicroCompetencyTag(
            bridge
                ? MicroCompetencyId.subtractionTenBridge
                : MicroCompetencyId.subtractionNoBridge,
          ),
          if (bridge)
            const MicroCompetencyTag(
              MicroCompetencyId.numberDecomposition,
              weight: 0.45,
            ),
        ];
      case MathOperation.multiply:
        return const [
          MicroCompetencyTag(MicroCompetencyId.multiplicationFacts),
          MicroCompetencyTag(
            MicroCompetencyId.multiplicationGroups,
            weight: 0.35,
          ),
        ];
      case MathOperation.divide:
        return const [
          MicroCompetencyTag(MicroCompetencyId.divisionFacts),
          MicroCompetencyTag(
            MicroCompetencyId.inverseRelationship,
            weight: 0.4,
          ),
        ];
    }
  }

  static List<MicroCompetencyTag> _storyTags(String key) {
    if (key.startsWith('story:transfer:skill:')) {
      return _transferStoryTags(key);
    }

    if (key.startsWith('story:info:') ||
        key.startsWith('story:transfer:irrelevant:')) {
      return const [
        MicroCompetencyTag(
          MicroCompetencyId.wordProblemRelevantInformation,
        ),
        MicroCompetencyTag(
          MicroCompetencyId.wordProblemModel,
          weight: 0.45,
        ),
      ];
    }

    if (key.startsWith('story:operation:')) {
      return const [
        MicroCompetencyTag(MicroCompetencyId.wordProblemOperation),
        MicroCompetencyTag(
          MicroCompetencyId.wordProblemRelevantInformation,
          weight: 0.35,
        ),
      ];
    }

    if (key.startsWith('story:equation:')) {
      return const [
        MicroCompetencyTag(MicroCompetencyId.wordProblemModel),
        MicroCompetencyTag(
          MicroCompetencyId.wordProblemOperation,
          weight: 0.45,
        ),
        MicroCompetencyTag(
          MicroCompetencyId.wordProblemRelevantInformation,
          weight: 0.25,
        ),
      ];
    }

    if (key.startsWith('story:interpret:')) {
      return const [
        MicroCompetencyTag(MicroCompetencyId.wordProblemInterpretation),
        MicroCompetencyTag(
          MicroCompetencyId.wordProblemCalculation,
          weight: 0.35,
        ),
        MicroCompetencyTag(
          MicroCompetencyId.wordProblemModel,
          weight: 0.25,
        ),
      ];
    }

    final tags = <MicroCompetencyTag>[
      const MicroCompetencyTag(MicroCompetencyId.wordProblemCalculation),
      const MicroCompetencyTag(
        MicroCompetencyId.wordProblemModel,
        weight: 0.65,
      ),
      const MicroCompetencyTag(
        MicroCompetencyId.wordProblemOperation,
        weight: 0.4,
      ),
    ];
    if (key.startsWith('story:x:')) {
      tags.add(
        const MicroCompetencyTag(
          MicroCompetencyId.multiplicationGroups,
          weight: 0.35,
        ),
      );
    } else if (key.startsWith('story:divide:')) {
      tags.add(
        const MicroCompetencyTag(
          MicroCompetencyId.divisionSharing,
          weight: 0.35,
        ),
      );
    }
    return tags;
  }

  static List<MicroCompetencyTag> _transferStoryTags(String key) {
    final parts = key.split(':');
    if (parts.length < 5) return const <MicroCompetencyTag>[];
    MicroCompetencyId? target;
    for (final id in MicroCompetencyId.values) {
      if (id.name == parts[3]) {
        target = id;
        break;
      }
    }
    if (target == null) return const <MicroCompetencyTag>[];

    final tags = <MicroCompetencyTag>[
      MicroCompetencyTag(target),
      const MicroCompetencyTag(
        MicroCompetencyId.wordProblemModel,
        weight: 0.35,
      ),
    ];

    if (target == MicroCompetencyId.multiplicationGroups) {
      tags.add(
        const MicroCompetencyTag(
          MicroCompetencyId.multiplicationFacts,
          weight: 0.35,
        ),
      );
    } else if (target == MicroCompetencyId.multiplicationFacts) {
      tags.add(
        const MicroCompetencyTag(
          MicroCompetencyId.multiplicationGroups,
          weight: 0.45,
        ),
      );
    } else if (target == MicroCompetencyId.divisionSharing) {
      tags.add(
        const MicroCompetencyTag(
          MicroCompetencyId.divisionFacts,
          weight: 0.35,
        ),
      );
    } else if (target == MicroCompetencyId.divisionFacts) {
      tags.add(
        const MicroCompetencyTag(
          MicroCompetencyId.divisionSharing,
          weight: 0.45,
        ),
      );
    }
    return tags;
  }

  static List<MicroCompetencyTag> _upperPrimaryTags(
    TrainingMode mode,
    String key,
  ) =>
      switch (mode) {
        TrainingMode.largeNumbers => [
            MicroCompetencyTag(
              key.contains(':order:')
                  ? MicroCompetencyId.largeNumberOrder
                  : key.contains(':word:')
                      ? MicroCompetencyId.numberWordReading
                      : key.contains(':compare:')
                          ? MicroCompetencyId.largeNumberCompare
                          : key.contains(':decompose:')
                              ? MicroCompetencyId.placeValueDecompose
                              : key.contains(':neighbor:')
                                  ? MicroCompetencyId.countingNeighbors
                                  : MicroCompetencyId.placeValueDigits,
            ),
          ],
        TrainingMode.rounding => const [
            MicroCompetencyTag(MicroCompetencyId.roundingPlace),
          ],
        TrainingMode.mentalStrategies =>
          key.startsWith('process:strategy:')
              ? const [
                  MicroCompetencyTag(MicroCompetencyId.strategyChoice),
                  MicroCompetencyTag(
                    MicroCompetencyId.mentalStrategy,
                    weight: 0.45,
                  ),
                ]
              : [
                  const MicroCompetencyTag(MicroCompetencyId.mentalStrategy),
                  if (_keyNeedsBridge(key))
                    MicroCompetencyTag(
                      key.contains(':+:')
                          ? MicroCompetencyId.additionTenBridge
                          : MicroCompetencyId.subtractionTenBridge,
                      weight: 0.45,
                    ),
                ],
        TrainingMode.writtenAddSub =>
          key.startsWith('process:error:')
              ? const [
                  MicroCompetencyTag(MicroCompetencyId.errorChecking),
                  MicroCompetencyTag(
                    MicroCompetencyId.writtenAlignment,
                    weight: 0.35,
                  ),
                ]
              : _keyNeedsRegrouping(key)
                  ? const [
                MicroCompetencyTag(
                  MicroCompetencyId.writtenRegrouping,
                ),
                MicroCompetencyTag(
                  MicroCompetencyId.writtenAlignment,
                  weight: 0.4,
                ),
                  ]
                  : const [
                      MicroCompetencyTag(
                        MicroCompetencyId.writtenAlignment,
                      ),
                    ],
        TrainingMode.writtenMultiply => const [
            MicroCompetencyTag(
              MicroCompetencyId.writtenMultiplyProcedure,
            ),
          ],
        TrainingMode.writtenDivide => const [
            MicroCompetencyTag(
              MicroCompetencyId.writtenDivideProcedure,
            ),
          ],
        TrainingMode.estimation =>
          key.startsWith('process:plausibility:')
              ? const [
                  MicroCompetencyTag(MicroCompetencyId.plausibilityCheck),
                  MicroCompetencyTag(
                    MicroCompetencyId.estimation,
                    weight: 0.45,
                  ),
                ]
              : const [
                  MicroCompetencyTag(MicroCompetencyId.estimation),
                ],
        TrainingMode.arithmeticLaws =>
          key.startsWith('process:reasoning:')
              ? const [
                  MicroCompetencyTag(
                    MicroCompetencyId.reasoningJustification,
                  ),
                  MicroCompetencyTag(
                    MicroCompetencyId.arithmeticLaw,
                    weight: 0.45,
                  ),
                ]
              : const [
                  MicroCompetencyTag(MicroCompetencyId.arithmeticLaw),
                ],
        TrainingMode.romanNumerals => const [
            MicroCompetencyTag(MicroCompetencyId.romanNumeral),
          ],
        TrainingMode.fractions => const [
            MicroCompetencyTag(MicroCompetencyId.fractionEqualParts),
          ],
        TrainingMode.advancedMeasures =>
          key.startsWith('time:seconds:')
              ? const [
                  MicroCompetencyTag(MicroCompetencyId.secondsConversion),
                ]
              : const [
                  MicroCompetencyTag(MicroCompetencyId.unitConversion),
                ],
        TrainingMode.timeDurations =>
          key.startsWith('calendar:')
              ? const [
                  MicroCompetencyTag(MicroCompetencyId.calendarDate),
                ]
              : const [
                  MicroCompetencyTag(MicroCompetencyId.timeDuration),
                ],
        TrainingMode.dataCharts =>
          key.startsWith('data:tally:')
              ? const [
                  MicroCompetencyTag(MicroCompetencyId.tallyTableReading),
                ]
              : key.startsWith('data:representation:')
                  ? const [
                      MicroCompetencyTag(
                        MicroCompetencyId.dataRepresentationChoice,
                      ),
                      MicroCompetencyTag(
                        MicroCompetencyId.dataReading,
                        weight: 0.35,
                      ),
                    ]
                  : const [
                      MicroCompetencyTag(MicroCompetencyId.dataReading),
                    ],
        TrainingMode.probability =>
          key.startsWith('prob:experiment:')
              ? const [
                  MicroCompetencyTag(
                    MicroCompetencyId.probabilityExperiment,
                  ),
                  MicroCompetencyTag(
                    MicroCompetencyId.probabilityReasoning,
                    weight: 0.35,
                  ),
                ]
              : const [
                  MicroCompetencyTag(
                    MicroCompetencyId.probabilityReasoning,
                  ),
                ],
        TrainingMode.combinatorics => const [
            MicroCompetencyTag(
              MicroCompetencyId.combinatoricsSystematic,
            ),
          ],
        TrainingMode.proportionality => const [
            MicroCompetencyTag(MicroCompetencyId.proportionalUnit),
          ],
        TrainingMode.perimeterArea => [
            MicroCompetencyTag(
              key.contains('area')
                  ? MicroCompetencyId.area
                  : MicroCompetencyId.perimeter,
            ),
          ],
        TrainingMode.geometryRelations => [
            MicroCompetencyTag(
              key.startsWith('geomrel:lines:')
                  ? MicroCompetencyId.lineRelations
                  : key.startsWith('geomrel:angle:')
                      ? MicroCompetencyId.rightAngle
                      : key.startsWith('geomrel:figure:')
                          ? MicroCompetencyId.figureClassification
                          : MicroCompetencyId.circleParts,
            ),
          ],
        TrainingMode.geometryBodies =>
          key.startsWith('body:cube-net:fold:')
              ? const [
                  MicroCompetencyTag(
                    MicroCompetencyId.cubeNetFoldability,
                  ),
                  MicroCompetencyTag(
                    MicroCompetencyId.geometryBodies,
                    weight: 0.35,
                  ),
                ]
              : const [
                  MicroCompetencyTag(MicroCompetencyId.geometryBodies),
                ],
        TrainingMode.symmetry => const [
            MicroCompetencyTag(MicroCompetencyId.symmetryAxes),
          ],
        TrainingMode.plansAndOrientation => [
            MicroCompetencyTag(
              key.contains('scale')
                  ? MicroCompetencyId.scale
                  : MicroCompetencyId.planDirections,
            ),
          ],
        TrainingMode.volumeCubes => const [
            MicroCompetencyTag(MicroCompetencyId.volumeCubes),
          ],
        _ => const <MicroCompetencyTag>[],
      };

  static bool _keyNeedsBridge(String key) {
    final parts = key.split(':');
    if (parts.length < 4) return false;
    final a = int.tryParse(parts[parts.length - 2]);
    final b = int.tryParse(parts.last);
    if (a == null || b == null) return false;
    if (key.contains(':+:')) return (a % 10) + (b % 10) >= 10;
    if (key.contains(':-:')) return (a % 10) < (b % 10);
    return false;
  }

  static bool _keyNeedsRegrouping(String key) {
    final parts = key.split(':');
    if (parts.length < 4) return false;
    final a = int.tryParse(parts[parts.length - 2]);
    final b = int.tryParse(parts.last);
    if (a == null || b == null) return false;

    var left = a;
    var right = b;
    while (left > 0 || right > 0) {
      if (key.contains(':+:')) {
        if ((left % 10) + (right % 10) >= 10) return true;
      } else if (key.contains(':-:')) {
        if ((left % 10) < (right % 10)) return true;
      }
      left ~/= 10;
      right ~/= 10;
    }
    return false;
  }
}
