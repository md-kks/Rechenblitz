import '../../core/grade_level.dart';
import 'german_competency.dart';
import 'german_competency_catalog.dart';
import 'german_extra_task_catalog.dart';
import 'german_grade_four_diversity_task_catalog.dart';
import 'german_grade_four_listening_diversity_task_catalog.dart';
import 'german_grade_four_extension_task_catalog.dart';
import 'german_grade_one_diversity_task_catalog.dart';
import 'german_grade_three_extension_task_catalog.dart';
import 'german_grammar_touch_task_catalog.dart';
import 'german_learning_domain.dart';
import 'german_listening_touch_task_catalog.dart';
import 'german_lower_primary_task_catalog.dart';
import 'german_more_task_catalog.dart';
import 'german_morphology_touch_task_catalog.dart';
import 'german_ordering_touch_task_catalog.dart';
import 'german_phonics_listening_task_catalog.dart';
import 'german_punctuation_touch_task_catalog.dart';
import 'german_reading_evidence_task_catalog.dart';
import 'german_sentence_constituent_touch_task_catalog.dart';
import 'german_sentence_structure_expansion_task_catalog.dart';
import 'german_speaking_task_catalog.dart';
import 'german_starter_task_catalog.dart';
import 'german_task.dart';
import 'german_thin_pool_expansion_task_catalog.dart';
import 'german_touch_task_catalog.dart';
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
    ...GermanMorphologyTouchTaskCatalog.tasks,
    ...GermanOrderingTouchTaskCatalog.tasks,
    ...GermanPhonicsListeningTaskCatalog.tasks,
    ...GermanPunctuationTouchTaskCatalog.tasks,
    ...GermanReadingEvidenceTaskCatalog.tasks,
    ...GermanSentenceConstituentTouchTaskCatalog.tasks,
    ...GermanSentenceStructureExpansionTaskCatalog.tasks,
    ...GermanThinPoolExpansionTaskCatalog.tasks,
    ...GermanVocabularyTouchTaskCatalog.tasks,
    ...GermanWordRecognitionTaskCatalog.tasks,
    ...GermanGradeOneDiversityTaskCatalog.tasks,
    ...GermanLowerPrimaryTaskCatalog.tasks,
    ...GermanGradeThreeExtensionTaskCatalog.tasks,
    ...GermanGradeFourDiversityTaskCatalog.tasks,
    ...GermanGradeFourListeningDiversityTaskCatalog.tasks,
    ...GermanGradeFourExtensionTaskCatalog.tasks,
    ...GermanWritingProductionTaskCatalog.tasks,
    ...GermanWritingRevisionExpansionTaskCatalog.tasks,
    ...GermanUpperPrimaryTaskCatalog.tasks,
    ...GermanUpperPrimaryExpansionTaskCatalog.tasks,
  ];

  static List<GermanTask> forGrade(GradeLevel grade) => tasks
      .where((task) => task.recommendedFromGrade.index <= grade.index)
      .toList();

  static List<GermanTask> forDomain(
    GermanLearningDomain domain,
    GradeLevel grade,
  ) => forGrade(grade)
      .where(
        (task) =>
            GermanCompetencyCatalog.definition(task.competencyId).domain ==
            domain,
      )
      .toList();

  static List<GermanTask> forCompetency(GermanCompetencyId competencyId) =>
      tasks.where((task) => task.competencyId == competencyId).toList();
}
