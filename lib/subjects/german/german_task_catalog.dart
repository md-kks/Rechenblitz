import '../../core/grade_level.dart';
import 'german_competency.dart';
import 'german_competency_catalog.dart';
import 'german_extra_task_catalog.dart';
import 'german_grade_four_diversity_task_catalog.dart';
import 'german_grade_four_listening_diversity_task_catalog.dart';
import 'german_grade_four_extension_task_catalog.dart';
import 'german_grade_one_diversity_task_catalog.dart';
import 'german_grade_three_diversity_task_catalog.dart';
import 'german_grade_three_extension_task_catalog.dart';
import 'german_grade_two_diversity_task_catalog.dart';
import 'german_grammar_touch_task_catalog.dart';
import 'german_learning_domain.dart';
import 'german_listening_touch_task_catalog.dart';
import 'german_lower_primary_depth_task_catalog.dart';
import 'german_lower_primary_task_catalog.dart';
import 'german_more_task_catalog.dart';
import 'german_morphology_touch_task_catalog.dart';
import 'german_ordering_touch_task_catalog.dart';
import 'german_phonics_listening_task_catalog.dart';
import 'german_punctuation_touch_task_catalog.dart';
import 'german_reading_diversity_task_catalog.dart';
import 'german_reading_evidence_task_catalog.dart';
import 'german_sentence_constituent_touch_task_catalog.dart';
import 'german_sentence_structure_expansion_task_catalog.dart';
import 'german_speaking_task_catalog.dart';
import 'german_starter_task_catalog.dart';
import 'german_task.dart';
import 'german_thin_pool_expansion_task_catalog.dart';
import 'german_touch_task_catalog.dart';
import 'german_two_round_completion_task_catalog.dart';
import 'german_upper_primary_expansion_task_catalog.dart';
import 'german_vocabulary_touch_task_catalog.dart';
import 'german_word_recognition_task_catalog.dart';
import 'german_upper_primary_task_catalog.dart';
import 'german_writing_production_task_catalog.dart';
import 'german_writing_revision_expansion_task_catalog.dart';

class GermanTaskCatalog {
  const GermanTaskCatalog._();

  static const tasks = <GermanTask>[
    ...GermanStarterTaskCatalog.tasks,
    ...GermanExtraTaskCatalog.tasks,
    ...GermanMoreTaskCatalog.tasks,
    ...GermanSpeakingTaskCatalog.tasks,
    ...GermanTouchTaskCatalog.tasks,
    ...GermanGrammarTouchTaskCatalog.tasks,
    ...GermanListeningTouchTaskCatalog.tasks,
    ...GermanLowerPrimaryDepthTaskCatalog.tasks,
    ...GermanMorphologyTouchTaskCatalog.tasks,
    ...GermanOrderingTouchTaskCatalog.tasks,
    ...GermanPhonicsListeningTaskCatalog.tasks,
    ...GermanPunctuationTouchTaskCatalog.tasks,
    ...GermanReadingDiversityTaskCatalog.tasks,
    ...GermanReadingEvidenceTaskCatalog.tasks,
    ...GermanSentenceConstituentTouchTaskCatalog.tasks,
    ...GermanSentenceStructureExpansionTaskCatalog.tasks,
    ...GermanThinPoolExpansionTaskCatalog.tasks,
    ...GermanTwoRoundCompletionTaskCatalog.tasks,
    ...GermanVocabularyTouchTaskCatalog.tasks,
    ...GermanWordRecognitionTaskCatalog.tasks,
    ...GermanGradeOneDiversityTaskCatalog.tasks,
    ...GermanGradeTwoDiversityTaskCatalog.tasks,
    ...GermanLowerPrimaryTaskCatalog.tasks,
    ...GermanGradeThreeDiversityTaskCatalog.tasks,
    ...GermanGradeThreeExtensionTaskCatalog.tasks,
    ...GermanGradeFourDiversityTaskCatalog.tasks,
    ...GermanGradeFourListeningDiversityTaskCatalog.tasks,
    ...GermanGradeFourExtensionTaskCatalog.tasks,
    ...GermanWritingProductionTaskCatalog.tasks,
    ...GermanWritingRevisionExpansionTaskCatalog.tasks,
    ...GermanUpperPrimaryTaskCatalog.tasks,
    ...GermanUpperPrimaryExpansionTaskCatalog.tasks,
  ];

  static final Map<String, GermanTask> _tasksById =
      Map<String, GermanTask>.unmodifiable(<String, GermanTask>{
        for (final task in tasks) task.id: task,
      });

  static final Map<GermanCompetencyId, List<GermanTask>> _tasksByCompetency =
      Map<GermanCompetencyId, List<GermanTask>>.unmodifiable(
        <GermanCompetencyId, List<GermanTask>>{
          for (final competencyId in GermanCompetencyId.values)
            competencyId: List<GermanTask>.unmodifiable(
              tasks.where((task) => task.competencyId == competencyId),
            ),
        },
      );

  static final Map<GradeLevel, List<GermanTask>> _tasksThroughGrade =
      Map<GradeLevel, List<GermanTask>>.unmodifiable(
        <GradeLevel, List<GermanTask>>{
          for (final grade in GradeLevel.values)
            grade: List<GermanTask>.unmodifiable(
              tasks.where(
                (task) => task.recommendedFromGrade.index <= grade.index,
              ),
            ),
        },
      );

  static final Map<GradeLevel, Map<GermanLearningDomain, List<GermanTask>>>
  _tasksByDomainThroughGrade =
      Map<GradeLevel, Map<GermanLearningDomain, List<GermanTask>>>.unmodifiable(
        <GradeLevel, Map<GermanLearningDomain, List<GermanTask>>>{
          for (final grade in GradeLevel.values)
            grade: Map<GermanLearningDomain, List<GermanTask>>.unmodifiable(
              <GermanLearningDomain, List<GermanTask>>{
                for (final domain in GermanLearningDomain.values)
                  domain: List<GermanTask>.unmodifiable(
                    tasks.where(
                      (task) =>
                          task.recommendedFromGrade.index <= grade.index &&
                          GermanCompetencyCatalog.definition(
                                task.competencyId,
                              ).domain ==
                              domain,
                    ),
                  ),
              },
            ),
        },
      );

  static GermanTask? byId(String id) => _tasksById[id];

  static List<GermanTask> forGrade(GradeLevel grade) =>
      _tasksThroughGrade[grade]!;

  static List<GermanTask> forDomain(
    GermanLearningDomain domain,
    GradeLevel grade,
  ) => _tasksByDomainThroughGrade[grade]![domain]!;

  static List<GermanTask> forCompetency(GermanCompetencyId competencyId) =>
      _tasksByCompetency[competencyId]!;
}
