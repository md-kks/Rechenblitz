import 'learner_profile.dart';
import 'micro_competency.dart';
import 'training.dart';

enum CurriculumCoverage { digitalPractice, digitalSupport }

extension CurriculumCoverageX on CurriculumCoverage {
  String get label => switch (this) {
    CurriculumCoverage.digitalPractice => 'digital üb- und prüfbar',
    CurriculumCoverage.digitalSupport =>
      'digital unterstützt – praktisch ergänzen',
  };
}

enum CurriculumDomainScheme {
  standardFour,
  thuringia,
  berlinBrandenburg,
  hamburgFive,
}

class CurriculumStateProfile {
  const CurriculumStateProfile({
    required this.state,
    required this.code,
    required this.sourceTitle,
    required this.sourceVersion,
    required this.authority,
    required this.structureNote,
    required this.domainScheme,
    this.transitionNote,
  });

  final GermanState state;
  final String code;
  final String sourceTitle;
  final String sourceVersion;
  final String authority;
  final String structureNote;
  final CurriculumDomainScheme domainScheme;
  final String? transitionNote;
}

class CurriculumObjective {
  const CurriculumObjective({
    required this.id,
    required this.label,
    required this.domain,
    required this.competency,
    required this.mode,
    required this.minGrade,
    required this.coverage,
    required this.note,
    this.processRelated = false,
  });

  final String id;
  final String label;
  final String domain;
  final MicroCompetencyId competency;
  final TrainingMode mode;
  final GradeLevel minGrade;
  final CurriculumCoverage coverage;
  final String note;
  final bool processRelated;

  bool appliesTo(GradeLevel grade) => grade.index >= minGrade.index;
}

class CurriculumAuditSummary {
  const CurriculumAuditSummary({
    required this.total,
    required this.digital,
    required this.supported,
    required this.missingCompetencies,
  });

  final int total;
  final int digital;
  final int supported;
  final List<MicroCompetencyId> missingCompetencies;

  bool get structurallyComplete => missingCompetencies.isEmpty;
}

class CurriculumAuditCatalog {
  const CurriculumAuditCatalog._();

  static const reviewedOn = '17.09.2026';

  static const Map<GermanState, CurriculumStateProfile> profiles = {
    GermanState.badenWuerttemberg: CurriculumStateProfile(
      state: GermanState.badenWuerttemberg,
      code: 'BW',
      sourceTitle: 'Bildungsplan Grundschule – Mathematik',
      sourceVersion: '2016, Fassung vom 29.02.2024',
      authority: 'Kultusverwaltung Baden-Württemberg',
      structureNote:
          'Inhaltsbezogene Kompetenzen sind nach Zahlen und Operationen, Raum und Form, Größen und Messen sowie Daten und Zufall gegliedert.',
      domainScheme: CurriculumDomainScheme.standardFour,
    ),
    GermanState.bavaria: CurriculumStateProfile(
      state: GermanState.bavaria,
      code: 'BY',
      sourceTitle: 'LehrplanPLUS Grundschule – Mathematik',
      sourceVersion: 'Fachlehrpläne 1/2 und 3/4',
      authority: 'Freistaat Bayern',
      structureNote:
          'Die Lernbereiche sind Zahlen und Operationen, Raum und Form, Größen und Messen sowie Daten und Zufall; Muster und Strukturen wirken übergreifend.',
      domainScheme: CurriculumDomainScheme.standardFour,
    ),
    GermanState.berlin: CurriculumStateProfile(
      state: GermanState.berlin,
      code: 'BE',
      sourceTitle: 'Rahmenlehrplan Jahrgangsstufen 1–10 – Mathematik',
      sourceVersion: 'amtliche Fassung, Fachteil Mathematik 2023 angepasst',
      authority: 'Länder Berlin und Brandenburg / LISUM',
      structureNote:
          'Fünf Leitideen: Zahlen und Operationen, Größen und Messen, Raum und Form, Gleichungen und Funktionen sowie Daten und Zufall.',
      domainScheme: CurriculumDomainScheme.berlinBrandenburg,
    ),
    GermanState.brandenburg: CurriculumStateProfile(
      state: GermanState.brandenburg,
      code: 'BB',
      sourceTitle: 'Rahmenlehrplan Jahrgangsstufen 1–10 – Mathematik',
      sourceVersion: 'amtliche Fassung, Fachteil Mathematik 2023 angepasst',
      authority: 'Länder Berlin und Brandenburg / LISUM',
      structureNote:
          'Fünf Leitideen: Zahlen und Operationen, Größen und Messen, Raum und Form, Gleichungen und Funktionen sowie Daten und Zufall.',
      domainScheme: CurriculumDomainScheme.berlinBrandenburg,
    ),
    GermanState.bremen: CurriculumStateProfile(
      state: GermanState.bremen,
      code: 'HB',
      sourceTitle: 'Bildungsplan 0–10 – Bildungskonzeption Mathematik',
      sourceVersion:
          'Bildungskonzeption veröffentlicht im Kita- und Schuljahr 2024/25',
      authority: 'Der Senator für Kinder und Bildung Bremen',
      structureNote:
          'Die Bildungskonzeption Mathematische Bildung/Mathematik verbindet Elementar- und Primarbereich zu einem durchgängigen Kompetenzaufbau bis zum Ende der Grundschule.',
      domainScheme: CurriculumDomainScheme.standardFour,
    ),
    GermanState.hamburg: CurriculumStateProfile(
      state: GermanState.hamburg,
      code: 'HH',
      sourceTitle: 'Bildungsplan Grundschule – Mathematik',
      sourceVersion: 'Bildungsplan 2022, in Kraft seit 01.08.2023',
      authority: 'Freie und Hansestadt Hamburg',
      structureNote:
          'Fünf Leitideen: Zahl und Operation, Muster/Strukturen/funktionaler Zusammenhang, Größen und Messen, Raum und Form sowie Daten und Zufall.',
      domainScheme: CurriculumDomainScheme.hamburgFive,
    ),
    GermanState.hesse: CurriculumStateProfile(
      state: GermanState.hesse,
      code: 'HE',
      sourceTitle: 'Kerncurriculum Mathematik – Primarstufe',
      sourceVersion: 'curriculare Grundlage seit Schuljahr 2011/2012',
      authority: 'Hessische Kultusverwaltung',
      structureNote:
          'Bildungsstandards und Inhaltsfelder beschreiben die verbindlichen Leistungserwartungen am Ende der Jahrgangsstufe 4.',
      domainScheme: CurriculumDomainScheme.standardFour,
    ),
    GermanState.mecklenburgVorpommern: CurriculumStateProfile(
      state: GermanState.mecklenburgVorpommern,
      code: 'MV',
      sourceTitle: 'Rahmenplan Mathematik Primarbereich Klasse 1 bis 4',
      sourceVersion: '2024, aufwachsend seit 01.08.2024',
      authority: 'Ministerium für Bildung und Kindertagesförderung M-V',
      structureNote:
          'Der neue Rahmenplan orientiert den Primarbereich an den aktuellen Bildungsstandards Mathematik.',
      domainScheme: CurriculumDomainScheme.standardFour,
      transitionNote:
          'Der vorherige Grundschul-Rahmenplan läuft parallel jahrgangsweise bis 31.07.2027 aus.',
    ),
    GermanState.lowerSaxony: CurriculumStateProfile(
      state: GermanState.lowerSaxony,
      code: 'NI',
      sourceTitle: 'Kerncurriculum Mathematik – Primarbereich',
      sourceVersion: 'in Kraft seit 01.08.2025',
      authority: 'Niedersächsische Kultusverwaltung',
      structureNote:
          'Das Kerncurriculum verbindet prozessbezogene und inhaltsbezogene Kompetenzen auf Grundlage der aktuellen Bildungsstandards.',
      domainScheme: CurriculumDomainScheme.standardFour,
    ),
    GermanState.northRhineWestphalia: CurriculumStateProfile(
      state: GermanState.northRhineWestphalia,
      code: 'NW',
      sourceTitle: 'Lehrplan Mathematik für die Primarstufe',
      sourceVersion: 'Erlass vom 01.07.2021',
      authority: 'Ministerium für Schule und Bildung Nordrhein-Westfalen',
      structureNote:
          'Der Lehrplan beschreibt Kompetenzbereiche, verbindliche Inhalte und Kompetenzerwartungen für die Primarstufe.',
      domainScheme: CurriculumDomainScheme.standardFour,
    ),
    GermanState.rhinelandPalatinate: CurriculumStateProfile(
      state: GermanState.rhinelandPalatinate,
      code: 'RP',
      sourceTitle: 'Rahmenplan Grundschule – Teilrahmenplan Mathematik',
      sourceVersion: 'Fassung 01.08.2015',
      authority: 'Ministerium für Bildung Rheinland-Pfalz',
      structureNote:
          'Der Teilrahmenplan konkretisiert die mathematische Kompetenzentwicklung für die Grundschule.',
      domainScheme: CurriculumDomainScheme.standardFour,
    ),
    GermanState.saarland: CurriculumStateProfile(
      state: GermanState.saarland,
      code: 'SL',
      sourceTitle: 'Kernlehrplan Mathematik Grundschule',
      sourceVersion: 'neue Fassung ab 01.08.2026',
      authority: 'Ministerium für Bildung und Kultur Saarland',
      structureNote:
          'Der aktuelle Kernlehrplan greift die Bildungsstandards auf und ordnet die Kompetenzentwicklung für die Grundschule.',
      domainScheme: CurriculumDomainScheme.standardFour,
    ),
    GermanState.saxony: CurriculumStateProfile(
      state: GermanState.saxony,
      code: 'SN',
      sourceTitle: 'Lehrplan Grundschule – Mathematik',
      sourceVersion: 'aktuelle Fassung der dynamischen Lehrplandatenbank',
      authority: 'Sächsisches Landesamt für Schule und Bildung',
      structureNote:
          'Die jeweils gültigen Ziele und Inhalte werden in der dynamischen Lehrplandatenbank des Freistaates geführt.',
      domainScheme: CurriculumDomainScheme.standardFour,
    ),
    GermanState.saxonyAnhalt: CurriculumStateProfile(
      state: GermanState.saxonyAnhalt,
      code: 'ST',
      sourceTitle: 'Fachlehrplan Grundschule – Mathematik',
      sourceVersion: 'überarbeitete Fassung, in Kraft seit 01.08.2026',
      authority:
          'Landesinstitut für Schulqualität und Lehrerbildung Sachsen-Anhalt',
      structureNote:
          'Inhaltsbezogene Kompetenzen sind nach Zahlen und Operationen, Größen und Messen, Raum und Form sowie Daten, Häufigkeit und Wahrscheinlichkeit gegliedert.',
      domainScheme: CurriculumDomainScheme.standardFour,
    ),
    GermanState.schleswigHolstein: CurriculumStateProfile(
      state: GermanState.schleswigHolstein,
      code: 'SH',
      sourceTitle: 'Fachanforderungen Mathematik Primarstufe',
      sourceVersion: '2024, aufwachsend seit Schuljahr 2024/25',
      authority:
          'Ministerium für Allgemeine und Berufliche Bildung Schleswig-Holstein / IQSH',
      structureNote:
          'Die Fachanforderungen wurden auf Grundlage der KMK-Bildungsstandards 2022 für die Primarstufe überarbeitet.',
      domainScheme: CurriculumDomainScheme.standardFour,
    ),
    GermanState.thuringia: CurriculumStateProfile(
      state: GermanState.thuringia,
      code: 'TH',
      sourceTitle:
          'Lehrplan für die Grundschule und Förderschule mit Bildungsgang Grundschule – Mathematik',
      sourceVersion: '2010',
      authority: 'Thüringer Kultusverwaltung / ThILLM',
      structureNote:
          'Drei Lernbereiche: Arithmetik, Größen und Geometrie. Die KMK-Leitideen einschließlich Daten und Zufall sind darin integriert.',
      domainScheme: CurriculumDomainScheme.thuringia,
    ),
  };

  static CurriculumStateProfile profileFor(GermanState state) =>
      profiles[state] ?? profiles[GermanState.thuringia]!;

  static List<CurriculumObjective> get objectives =>
      objectivesFor(GermanState.thuringia);

  static List<CurriculumObjective> objectivesFor(GermanState state) {
    final profile = profileFor(state);
    return MicroCompetencyCatalog.definitions
        .map(
          (definition) => CurriculumObjective(
            id: 'RB-${profile.code}-${definition.id.name}',
            label: definition.label,
            domain: _domainFor(profile, definition),
            competency: definition.id,
            mode: definition.preferredMode,
            minGrade: definition.minGrade,
            coverage: _coverageFor(definition.id),
            note: _noteFor(definition.id),
            processRelated: _isProcessRelated(definition.id),
          ),
        )
        .toList(growable: false);
  }

  static List<CurriculumObjective> forGrade(
    GradeLevel grade, {
    GermanState state = GermanState.thuringia,
  }) => objectivesFor(
    state,
  ).where((objective) => objective.appliesTo(grade)).toList(growable: false);

  static CurriculumAuditSummary audit(
    GradeLevel grade, {
    GermanState state = GermanState.thuringia,
  }) {
    final applicableDefinitions = MicroCompetencyCatalog.forGrade(grade);
    final items = forGrade(grade, state: state);
    final mapped = items.map((item) => item.competency).toSet();
    final missing = applicableDefinitions
        .where((definition) => !mapped.contains(definition.id))
        .map((definition) => definition.id)
        .toList(growable: false);

    return CurriculumAuditSummary(
      total: items.length,
      digital: items
          .where((item) => item.coverage == CurriculumCoverage.digitalPractice)
          .length,
      supported: items
          .where((item) => item.coverage == CurriculumCoverage.digitalSupport)
          .length,
      missingCompetencies: missing,
    );
  }

  static String _domainFor(
    CurriculumStateProfile profile,
    MicroCompetencyDefinition definition,
  ) {
    if (profile.domainScheme == CurriculumDomainScheme.thuringia) {
      return switch (definition.domain) {
        MicroCompetencyDomain.measuresAndProblems => 'Größen',
        MicroCompetencyDomain.geometry => 'Geometrie',
        _ => 'Arithmetik',
      };
    }

    if (profile.domainScheme == CurriculumDomainScheme.berlinBrandenburg &&
        const {
          MicroCompetencyId.numberPatterns,
          MicroCompetencyId.numberRelations,
        }.contains(definition.id)) {
      return 'Gleichungen und Funktionen';
    }

    if (profile.domainScheme == CurriculumDomainScheme.hamburgFive &&
        const {
          MicroCompetencyId.numberPatterns,
          MicroCompetencyId.numberRelations,
          MicroCompetencyId.proportionalUnit,
        }.contains(definition.id)) {
      return 'Muster, Strukturen und funktionaler Zusammenhang';
    }

    return switch (definition.domain) {
      MicroCompetencyDomain.numberSense ||
      MicroCompetencyDomain.arithmetic ||
      MicroCompetencyDomain.writtenMethods => 'Zahlen und Operationen',
      MicroCompetencyDomain.measuresAndProblems => 'Größen und Messen',
      MicroCompetencyDomain.geometry => 'Raum und Form',
      MicroCompetencyDomain.dataAndChance => 'Daten und Zufall',
    };
  }

  static CurriculumCoverage _coverageFor(MicroCompetencyId id) {
    const needsPracticalComplement = {
      MicroCompetencyId.measurementCalculation,
      MicroCompetencyId.shapeProperties,
      MicroCompetencyId.geometryBodies,
      MicroCompetencyId.symmetryAxes,
      MicroCompetencyId.planDirections,
      MicroCompetencyId.lineRelations,
      MicroCompetencyId.rightAngle,
      MicroCompetencyId.cubeNetFoldability,
      MicroCompetencyId.probabilityExperiment,
      MicroCompetencyId.reasoningJustification,
    };
    return needsPracticalComplement.contains(id)
        ? CurriculumCoverage.digitalSupport
        : CurriculumCoverage.digitalPractice;
  }

  static bool _isProcessRelated(MicroCompetencyId id) => const {
    MicroCompetencyId.strategyChoice,
    MicroCompetencyId.errorChecking,
    MicroCompetencyId.plausibilityCheck,
    MicroCompetencyId.reasoningJustification,
    MicroCompetencyId.representationTranslation,
    MicroCompetencyId.wordProblemRelevantInformation,
    MicroCompetencyId.wordProblemOperation,
    MicroCompetencyId.wordProblemModel,
    MicroCompetencyId.wordProblemCalculation,
    MicroCompetencyId.wordProblemInterpretation,
    MicroCompetencyId.estimation,
  }.contains(id);

  static String _noteFor(MicroCompetencyId id) => switch (id) {
    MicroCompetencyId.measurementCalculation =>
      'Digitale Größenaufgaben unterstützen das Verständnis; reales Messen mit Lineal, Waage oder Gefäßen muss praktisch ergänzt werden.',
    MicroCompetencyId.shapeProperties =>
      'Formeigenschaften sind digital übbar; Konstruieren und Zeichnen mit Werkzeugen benötigt praktische Aufgaben.',
    MicroCompetencyId.geometryBodies =>
      'Körpermerkmale und Netze sind digital übbar; reales Bauen, Falten und Drehen ergänzt die Raumvorstellung.',
    MicroCompetencyId.symmetryAxes =>
      'Symmetrie ist digital erkennbar; Falten, Spiegeln und Zeichnen sollte praktisch ergänzt werden.',
    MicroCompetencyId.planDirections =>
      'Pläne und Wege sind digital übbar; reale Orientierung bleibt eine praktische Kompetenz.',
    MicroCompetencyId.lineRelations =>
      'Parallel und senkrecht sind digital erkennbar; das Zeichnen mit Lineal oder Geodreieck muss praktisch ergänzt werden.',
    MicroCompetencyId.rightAngle =>
      'Rechte Winkel sind digital erkennbar; Prüfen und Konstruieren mit Zeichengeräten sollte praktisch ergänzt werden.',
    MicroCompetencyId.reasoningJustification =>
      'Passende mathematische Begründungen können digital beurteilt und nachvollzogen werden; eigene Begründungen formulieren, austauschen und verteidigen muss im Unterricht praktisch ergänzt werden.',
    MicroCompetencyId.representationTranslation =>
      'Vorgegebene Stellenwert-, Zerlegungs-, Gruppen- und Symbolformen können digital zugeordnet und ineinander übertragen werden; eigene Darstellungen entwickeln, auswählen und begründen sollte praktisch ergänzt werden.',
    MicroCompetencyId.wordProblemRelevantInformation =>
      'Relevante und irrelevante Angaben einer Sachsituation werden gezielt getrennt geprüft.',
    MicroCompetencyId.wordProblemOperation =>
      'Die mathematische Beziehung einer Sachsituation wird über die passende Rechenart gezielt geprüft.',
    MicroCompetencyId.wordProblemModel =>
      'Das Übersetzen einer Sachsituation in eine passende Rechnung wird getrennt vom Ausrechnen geprüft.',
    MicroCompetencyId.wordProblemCalculation =>
      'Das rechnerische Lösen einer bereits verstandenen Sachsituation wird als eigener Lernschritt beobachtet.',
    MicroCompetencyId.wordProblemInterpretation =>
      'Das Rechenergebnis wird gezielt auf Frage, Einheit und Sachsituation zurückbezogen.',
    _ =>
      'Das Lernziel wird mit generierten Aufgaben, Mikro-Evidenz und gezielter Wiederholung digital unterstützt.',
  };
}
