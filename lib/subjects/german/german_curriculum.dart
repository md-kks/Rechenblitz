import '../../core/german_state.dart';
import '../../core/grade_level.dart';
import 'german_competency.dart';
import 'german_competency_catalog.dart';
import 'german_task_catalog.dart';

enum GermanCurriculumCoverage {
  digitalPractice,
  guidedDigitalPractice,
  classroomExtension,
}

extension GermanCurriculumCoverageX on GermanCurriculumCoverage {
  String get label => switch (this) {
    GermanCurriculumCoverage.digitalPractice => 'digital übbar',
    GermanCurriculumCoverage.guidedDigitalPractice => 'digital unterstützt',
    GermanCurriculumCoverage.classroomExtension => 'praktisch ergänzen',
  };
}

class GermanCurriculumProfile {
  const GermanCurriculumProfile({
    required this.state,
    required this.detailedMapping,
    required this.referenceLabel,
  });

  final GermanState state;
  final bool detailedMapping;
  final String referenceLabel;

  List<GermanCompetencyDefinition> competenciesFor(GradeLevel grade) =>
      GermanCompetencyCatalog.recommendedFor(grade);

  String get statusText => detailedMapping
      ? 'Detaillierte Zuordnung für ${state.label}.'
      : 'Gemeinsamer Grundschul-Deutsch-Kern für ${state.label}.';
}

class GermanCurriculumRegistry {
  const GermanCurriculumRegistry._();

  static GermanCurriculumProfile forState(GermanState state) =>
      GermanCurriculumProfile(
        state: state,
        detailedMapping: state == GermanState.thuringia,
        referenceLabel: state == GermanState.thuringia
            ? 'Thüringer Lehrplan Grundschule Deutsch'
            : 'Gemeinsamer Grundschul-Deutsch-Kern',
      );
}

class GermanCurriculumAuditSummary {
  const GermanCurriculumAuditSummary({
    required this.total,
    required this.digitalPractice,
    required this.guidedDigitalPractice,
    required this.classroomExtension,
    required this.missingTaskCompetencies,
  });

  final int total;
  final int digitalPractice;
  final int guidedDigitalPractice;
  final int classroomExtension;
  final List<GermanCompetencyId> missingTaskCompetencies;

  bool get structurallyComplete => missingTaskCompetencies.isEmpty;
}

class GermanCurriculumAudit {
  const GermanCurriculumAudit._();

  static GermanCurriculumCoverage coverageFor(GermanCompetencyId id) =>
      switch (id) {
        GermanCompetencyId.conversationRules ||
        GermanCompetencyId.oralRetelling ||
        GermanCompetencyId.presentationStructure ||
        GermanCompetencyId.discussionReasoning =>
          GermanCurriculumCoverage.classroomExtension,
        GermanCompetencyId.sentenceWriting || GermanCompetencyId.textRevision =>
          GermanCurriculumCoverage.guidedDigitalPractice,
        _ => GermanCurriculumCoverage.digitalPractice,
      };

  static GermanCurriculumAuditSummary summarize(GradeLevel grade) {
    final definitions = GermanCompetencyCatalog.recommendedFor(grade);
    var digital = 0;
    var guided = 0;
    var classroom = 0;
    final missing = <GermanCompetencyId>[];

    for (final definition in definitions) {
      switch (coverageFor(definition.id)) {
        case GermanCurriculumCoverage.digitalPractice:
          digital += 1;
        case GermanCurriculumCoverage.guidedDigitalPractice:
          guided += 1;
        case GermanCurriculumCoverage.classroomExtension:
          classroom += 1;
      }
      if (GermanTaskCatalog.forCompetency(definition.id).isEmpty) {
        missing.add(definition.id);
      }
    }

    return GermanCurriculumAuditSummary(
      total: definitions.length,
      digitalPractice: digital,
      guidedDigitalPractice: guided,
      classroomExtension: classroom,
      missingTaskCompetencies: List<GermanCompetencyId>.unmodifiable(missing),
    );
  }
}
