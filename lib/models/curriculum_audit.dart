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

enum CurriculumProgressionModel {
  stateSequence,
  gradePairs,
  observedGradePair,
  schoolEntryPhaseThenAnnual,
  frameworkLevels,
  primaryEnd,
}

extension CurriculumProgressionModelX on CurriculumProgressionModel {
  String get label => switch (this) {
    CurriculumProgressionModel.stateSequence =>
      'Rechenblitz-Klassenstufenfolge auf Landesgrundlage',
    CurriculumProgressionModel.gradePairs => 'Lernbänder 1/2 und 3/4',
    CurriculumProgressionModel.observedGradePair =>
      'Beobachtung Ende 2 / Anforderungen Ende 4',
    CurriculumProgressionModel.schoolEntryPhaseThenAnnual =>
      'Schuleingangsphase 1/2, danach Jahrgang 3 und 4',
    CurriculumProgressionModel.frameworkLevels =>
      'Niveaustufen über Jahrgangsbänder',
    CurriculumProgressionModel.primaryEnd =>
      'verbindliche Erwartungen am Ende von Klasse 4',
  };
}

enum CurriculumProgressionStage { later, building, dueNow, catchUp }

class CurriculumProgressionInfo {
  const CurriculumProgressionInfo({
    required this.stage,
    required this.checkpointGrade,
    required this.label,
    required this.priority,
  });

  final CurriculumProgressionStage stage;
  final GradeLevel checkpointGrade;
  final String label;
  final int priority;
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
    this.progressionModel = CurriculumProgressionModel.stateSequence,
    this.transitionNote,
    this.earlyProgressionNote,
  });

  final GermanState state;
  final String code;
  final String sourceTitle;
  final String sourceVersion;
  final String authority;
  final String structureNote;
  final CurriculumDomainScheme domainScheme;
  final CurriculumProgressionModel progressionModel;
  final String? transitionNote;
  final String? earlyProgressionNote;
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

  static const reviewedOn = '18.09.2026';

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
      progressionModel: CurriculumProgressionModel.gradePairs,
      earlyProgressionNote:
          'Bis Ende Klasse 2 sind Daten sowie erste Zufallsexperimente ausdrücklich vorgesehen.',
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
      progressionModel: CurriculumProgressionModel.gradePairs,
      earlyProgressionNote:
          'Im Lernband 1/2 sind Daten, einfache Zufallsexperimente und erste kombinatorische Aufgaben vorgesehen.',
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
      progressionModel: CurriculumProgressionModel.frameworkLevels,
      earlyProgressionNote:
          'Niveaustufe B umfasst Daten, einfache Zufallsexperimente und kombinatorische Fragestellungen.',
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
      progressionModel: CurriculumProgressionModel.frameworkLevels,
      earlyProgressionNote:
          'Niveaustufe B umfasst Daten, einfache Zufallsexperimente und kombinatorische Fragestellungen.',
    ),
    GermanState.bremen: CurriculumStateProfile(
      state: GermanState.bremen,
      code: 'HB',
      sourceTitle:
          'Bildungsplan 0 bis 10 – Mathematische Bildung / Mathematik',
      sourceVersion: 'Stand 2025, gültig seit Schuljahr 2025/26',
      authority: 'Die Senatorin für Kinder und Bildung Bremen',
      structureNote:
          'Der Bildungsplan verbindet Elementar- und Primarbereich und formuliert verbindliche Standards am Ende der Jahrgangsstufen 2 und 4.',
      domainScheme: CurriculumDomainScheme.standardFour,
      progressionModel: CurriculumProgressionModel.gradePairs,
      earlyProgressionNote:
          'Am Ende von Klasse 2 sind Daten aus Tabellen und Diagrammen, einfache kombinatorische Probleme sowie grundlegende Wahrscheinlichkeitsaussagen verbindlich.',
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
      progressionModel: CurriculumProgressionModel.observedGradePair,
      earlyProgressionNote:
          'Die Beobachtungskriterien am Ende von Klasse 2 umfassen Daten, erste kombinatorische Fragestellungen und einfache Zufallsexperimente.',
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
      progressionModel: CurriculumProgressionModel.primaryEnd,
      earlyProgressionNote:
          'Der offizielle Leitfaden konkretisiert für Klasse 1/2 bereits Daten, Tabellen und Diagramme, einfache Zufallsexperimente sowie kombinatorische Aufgaben; der verbindliche Regelstandard bleibt Ende Klasse 4.',
    ),
    GermanState.mecklenburgVorpommern: CurriculumStateProfile(
      state: GermanState.mecklenburgVorpommern,
      code: 'MV',
      sourceTitle: 'Rahmenplan Mathematik Primarbereich Klasse 1 bis 4',
      sourceVersion: '2024, aufwachsend seit 01.08.2024',
      authority: 'Ministerium für Bildung und Kindertagesförderung M-V',
      structureNote:
          'Der Rahmenplan gliedert verbindliche Inhalte in die Schuleingangsphase sowie anschließend getrennt in Jahrgangsstufe 3 und Jahrgangsstufe 4.',
      domainScheme: CurriculumDomainScheme.standardFour,
      progressionModel:
          CurriculumProgressionModel.schoolEntryPhaseThenAnnual,
      transitionNote:
          'Der vorherige Grundschul-Rahmenplan läuft parallel jahrgangsweise bis 31.07.2027 aus.',
      earlyProgressionNote:
          'In der Schuleingangsphase sind Datenerfassung mit Strichlisten, einfache Diagramme, erste kombinatorische Systematik und grundlegende Wahrscheinlichkeitsvergleiche verbindlich.',
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
      progressionModel: CurriculumProgressionModel.gradePairs,
      earlyProgressionNote:
          'Bis Ende Klasse 2 sind Daten, Wahrscheinlichkeit und einfache kombinatorische Fragestellungen vorgesehen.',
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
      progressionModel: CurriculumProgressionModel.gradePairs,
      earlyProgressionNote:
          'Die Kompetenzerwartungen am Ende des 2. Schuljahres umfassen Daten sowie erste Wahrscheinlichkeitsaussagen und einfache Zufallsexperimente.',
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
      sourceVersion: '2004/2009/2019/2025/2026, Anpassung 2026',
      authority: 'Sächsisches Landesamt für Schule und Bildung',
      structureNote:
          'Die jeweils gültigen Ziele und Inhalte werden in der dynamischen Lehrplandatenbank des Freistaates geführt.',
      domainScheme: CurriculumDomainScheme.standardFour,
      earlyProgressionNote:
          'Die Klassenstufen 1/2 enthalten Daten, einfache Kombinatorik und erste Zufallsexperimente.',
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
      progressionModel: CurriculumProgressionModel.gradePairs,
      earlyProgressionNote:
          'Die Eingangsphase umfasst Daten, einfache Zufallsexperimente und kombinatorische Fragestellungen durch Probieren.',
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

  static const Map<GermanState, Map<MicroCompetencyId, GradeLevel>>
  _earlierStateCompetencies = {
    GermanState.badenWuerttemberg: {
      MicroCompetencyId.dataReading: GradeLevel.second,
      MicroCompetencyId.tallyTableReading: GradeLevel.second,
      MicroCompetencyId.probabilityReasoning: GradeLevel.second,
    },
    GermanState.bavaria: {
      MicroCompetencyId.dataReading: GradeLevel.second,
      MicroCompetencyId.tallyTableReading: GradeLevel.second,
      MicroCompetencyId.probabilityReasoning: GradeLevel.second,
      MicroCompetencyId.combinatoricsSystematic: GradeLevel.second,
    },
    GermanState.berlin: {
      MicroCompetencyId.dataReading: GradeLevel.second,
      MicroCompetencyId.tallyTableReading: GradeLevel.second,
      MicroCompetencyId.probabilityReasoning: GradeLevel.second,
      MicroCompetencyId.combinatoricsSystematic: GradeLevel.second,
    },
    GermanState.brandenburg: {
      MicroCompetencyId.dataReading: GradeLevel.second,
      MicroCompetencyId.tallyTableReading: GradeLevel.second,
      MicroCompetencyId.probabilityReasoning: GradeLevel.second,
      MicroCompetencyId.combinatoricsSystematic: GradeLevel.second,
    },
    GermanState.bremen: {
      MicroCompetencyId.dataReading: GradeLevel.second,
      MicroCompetencyId.tallyTableReading: GradeLevel.second,
      MicroCompetencyId.probabilityReasoning: GradeLevel.second,
      MicroCompetencyId.combinatoricsSystematic: GradeLevel.second,
    },
    GermanState.hesse: {
      MicroCompetencyId.dataReading: GradeLevel.second,
      MicroCompetencyId.tallyTableReading: GradeLevel.second,
      MicroCompetencyId.probabilityReasoning: GradeLevel.second,
      MicroCompetencyId.combinatoricsSystematic: GradeLevel.second,
    },
    GermanState.mecklenburgVorpommern: {
      MicroCompetencyId.dataReading: GradeLevel.second,
      MicroCompetencyId.tallyTableReading: GradeLevel.second,
      MicroCompetencyId.probabilityReasoning: GradeLevel.second,
      MicroCompetencyId.combinatoricsSystematic: GradeLevel.second,
    },
    GermanState.northRhineWestphalia: {
      MicroCompetencyId.dataReading: GradeLevel.second,
      MicroCompetencyId.tallyTableReading: GradeLevel.second,
      MicroCompetencyId.probabilityReasoning: GradeLevel.second,
      MicroCompetencyId.combinatoricsSystematic: GradeLevel.second,
    },
    GermanState.hamburg: {
      MicroCompetencyId.dataReading: GradeLevel.second,
      MicroCompetencyId.tallyTableReading: GradeLevel.second,
      MicroCompetencyId.probabilityReasoning: GradeLevel.second,
      MicroCompetencyId.combinatoricsSystematic: GradeLevel.second,
    },
    GermanState.rhinelandPalatinate: {
      MicroCompetencyId.dataReading: GradeLevel.second,
      MicroCompetencyId.tallyTableReading: GradeLevel.second,
      MicroCompetencyId.probabilityReasoning: GradeLevel.second,
    },
    GermanState.saxony: {
      MicroCompetencyId.dataReading: GradeLevel.second,
      MicroCompetencyId.tallyTableReading: GradeLevel.second,
      MicroCompetencyId.probabilityReasoning: GradeLevel.second,
      MicroCompetencyId.combinatoricsSystematic: GradeLevel.second,
    },
    GermanState.schleswigHolstein: {
      MicroCompetencyId.dataReading: GradeLevel.second,
      MicroCompetencyId.tallyTableReading: GradeLevel.second,
      MicroCompetencyId.probabilityReasoning: GradeLevel.second,
      MicroCompetencyId.combinatoricsSystematic: GradeLevel.second,
    },
  };

  static Map<MicroCompetencyId, GradeLevel> earlyStateCompetencies(
    GermanState state,
  ) => Map.unmodifiable(
        _earlierStateCompetencies[state] ??
            const <MicroCompetencyId, GradeLevel>{},
      );

  static GradeLevel effectiveMinGrade(
    GermanState state,
    MicroCompetencyId competency,
  ) =>
      _earlierStateCompetencies[state]?[competency] ??
      MicroCompetencyCatalog.definition(competency).minGrade;

  static List<MicroCompetencyDefinition> definitionsForGrade(
    GermanState state,
    GradeLevel grade,
  ) => MicroCompetencyCatalog.definitions
      .where(
        (definition) =>
            grade.index >= effectiveMinGrade(state, definition.id).index,
      )
      .toList(growable: false);

  static List<MicroCompetencyDefinition> definitionsForContext(
    GermanState state,
    GradeLevel grade,
    NumberRangeLevel range,
  ) => definitionsForGrade(state, grade)
      .where((definition) => definition.appliesToNumberRange(range))
      .toList(growable: false);

  static GradeLevel checkpointGradeFor(
    GermanState state,
    MicroCompetencyDefinition definition,
  ) {
    final model = profileFor(state).progressionModel;
    final earliest = effectiveMinGrade(state, definition.id);
    return switch (model) {
      CurriculumProgressionModel.gradePairs ||
      CurriculumProgressionModel.observedGradePair ||
      CurriculumProgressionModel.frameworkLevels =>
        earliest.index <= GradeLevel.second.index
            ? GradeLevel.second
            : GradeLevel.fourth,
      CurriculumProgressionModel.schoolEntryPhaseThenAnnual =>
        earliest.index <= GradeLevel.second.index ? GradeLevel.second : earliest,
      CurriculumProgressionModel.primaryEnd => GradeLevel.fourth,
      CurriculumProgressionModel.stateSequence => earliest,
    };
  }

  static CurriculumProgressionInfo progressionFor(
    GermanState state,
    GradeLevel grade,
    MicroCompetencyId competency,
  ) {
    final definition = MicroCompetencyCatalog.definition(competency);
    final profile = profileFor(state);
    final earliest = effectiveMinGrade(state, competency);
    final checkpoint = checkpointGradeFor(state, definition);
    if (grade.index < earliest.index) {
      return CurriculumProgressionInfo(
        stage: CurriculumProgressionStage.later,
        checkpointGrade: checkpoint,
        label: 'ab ${earliest.label} vorgesehen',
        priority: 0,
      );
    }
    if (grade.index > checkpoint.index) {
      return CurriculumProgressionInfo(
        stage: CurriculumProgressionStage.catchUp,
        checkpointGrade: checkpoint,
        label: 'bereits vorgesehen – weiter festigen',
        priority: 500,
      );
    }
    if (grade == checkpoint) {
      final label = switch (profile.progressionModel) {
        CurriculumProgressionModel.gradePairs =>
          'bis Ende ${checkpoint.label} im Lernband sichern',
        CurriculumProgressionModel.observedGradePair =>
          checkpoint == GradeLevel.second
              ? 'Beobachtungskriterien bis Ende Klasse 2 berücksichtigen'
              : 'Regelanforderungen bis Ende Klasse 4 sichern',
        CurriculumProgressionModel.schoolEntryPhaseThenAnnual =>
          checkpoint == GradeLevel.second
              ? 'bis Ende der Schuleingangsphase sichern'
              : 'im Jahrgang ${checkpoint.label} sichern',
        CurriculumProgressionModel.frameworkLevels =>
          'Niveaustufe des Jahrgangsbands sichern',
        CurriculumProgressionModel.primaryEnd => 'bis Ende Klasse 4 sichern',
        CurriculumProgressionModel.stateSequence =>
          'Rechenblitz ordnet diesen Schritt ab ${earliest.label} ein',
      };
      return CurriculumProgressionInfo(
        stage: CurriculumProgressionStage.dueNow,
        checkpointGrade: checkpoint,
        label: label,
        priority: 450,
      );
    }
    final label = switch (profile.progressionModel) {
      CurriculumProgressionModel.gradePairs =>
        'im Lernband bis ${checkpoint.label} aufbauen',
      CurriculumProgressionModel.observedGradePair =>
        checkpoint == GradeLevel.second
            ? 'auf die Beobachtungskriterien Ende Klasse 2 hinarbeiten'
            : 'auf die Regelanforderungen Ende Klasse 4 hinarbeiten',
      CurriculumProgressionModel.schoolEntryPhaseThenAnnual =>
        checkpoint == GradeLevel.second
            ? 'in der Schuleingangsphase bis Ende Klasse 2 aufbauen'
            : 'im Jahrgang ${checkpoint.label} aufbauen',
      CurriculumProgressionModel.frameworkLevels =>
        'im aktuellen Niveaustufen-Band aufbauen',
      CurriculumProgressionModel.primaryEnd =>
        'auf die Erwartungen am Ende von Klasse 4 aufbauen',
      CurriculumProgressionModel.stateSequence =>
        'in der Rechenblitz-Klassenstufenfolge weiter aufbauen',
    };
    return CurriculumProgressionInfo(
      stage: CurriculumProgressionStage.building,
      checkpointGrade: checkpoint,
      label: label,
      priority: 250,
    );
  }

  static int discoveryPriority(
    GermanState state,
    GradeLevel grade,
    MicroCompetencyId competency,
  ) => progressionFor(state, grade, competency).priority;

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
            minGrade: effectiveMinGrade(state, definition.id),
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
    final applicableDefinitions = definitionsForGrade(state, grade);
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
