import 'micro_competency.dart';
import 'training.dart';

enum CurriculumCoverage {
  digitalPractice,
  digitalSupport,
}

extension CurriculumCoverageX on CurriculumCoverage {
  String get label => switch (this) {
        CurriculumCoverage.digitalPractice => 'digital üb- und prüfbar',
        CurriculumCoverage.digitalSupport =>
          'digital unterstützt – praktisch ergänzen',
      };
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

  static List<CurriculumObjective> get objectives =>
      MicroCompetencyCatalog.definitions
          .map(
            (definition) => CurriculumObjective(
              id: 'RB-TH-${definition.id.name}',
              label: definition.label,
              domain: _domainFor(definition),
              competency: definition.id,
              mode: definition.preferredMode,
              minGrade: definition.minGrade,
              coverage: _coverageFor(definition.id),
              note: _noteFor(definition.id),
              processRelated: _isProcessRelated(definition.id),
            ),
          )
          .toList(growable: false);

  static List<CurriculumObjective> forGrade(GradeLevel grade) =>
      objectives.where((objective) => objective.appliesTo(grade)).toList();

  static CurriculumAuditSummary audit(GradeLevel grade) {
    final applicableDefinitions =
        MicroCompetencyCatalog.forGrade(grade);
    final mapped = forGrade(grade).map((item) => item.competency).toSet();
    final missing = applicableDefinitions
        .where((definition) => !mapped.contains(definition.id))
        .map((definition) => definition.id)
        .toList();

    final items = forGrade(grade);
    return CurriculumAuditSummary(
      total: items.length,
      digital: items
          .where(
            (item) =>
                item.coverage == CurriculumCoverage.digitalPractice,
          )
          .length,
      supported: items
          .where(
            (item) =>
                item.coverage == CurriculumCoverage.digitalSupport,
          )
          .length,
      missingCompetencies: missing,
    );
  }

  static String _domainFor(MicroCompetencyDefinition definition) {
    if (definition.id == MicroCompetencyId.numberPatterns) {
      return 'Muster und Strukturen';
    }
    return switch (definition.domain) {
      MicroCompetencyDomain.numberSense ||
      MicroCompetencyDomain.arithmetic ||
      MicroCompetencyDomain.writtenMethods =>
        'Zahlen und Operationen',
      MicroCompetencyDomain.measuresAndProblems => 'Größen und Messen',
      MicroCompetencyDomain.geometry => 'Raum und Form',
      MicroCompetencyDomain.dataAndChance =>
        'Daten, Häufigkeit und Wahrscheinlichkeit',
    };
  }

  static CurriculumCoverage _coverageFor(MicroCompetencyId id) {
    const physical = {
      MicroCompetencyId.measurementCalculation,
      MicroCompetencyId.shapeProperties,
      MicroCompetencyId.geometryBodies,
      MicroCompetencyId.symmetryAxes,
      MicroCompetencyId.planDirections,
      MicroCompetencyId.lineRelations,
      MicroCompetencyId.rightAngle,
      MicroCompetencyId.cubeNetFoldability,
      MicroCompetencyId.probabilityExperiment,
    };
    return physical.contains(id)
        ? CurriculumCoverage.digitalSupport
        : CurriculumCoverage.digitalPractice;
  }

  static bool _isProcessRelated(MicroCompetencyId id) => const {
        MicroCompetencyId.strategyChoice,
        MicroCompetencyId.errorChecking,
        MicroCompetencyId.plausibilityCheck,
        MicroCompetencyId.wordProblemOperation,
        MicroCompetencyId.wordProblemCalculation,
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
        _ =>
          'Das Lernziel wird mit generierten Aufgaben, Mikro-Evidenz und gezielter Wiederholung digital unterstützt.',
      };
}
