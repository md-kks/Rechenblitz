import '../../core/grade_level.dart';
import 'german_competency.dart';
import 'german_competency_catalog.dart';
import 'german_extra_task_catalog.dart';
import 'german_grade_four_extension_task_catalog.dart';
import 'german_grade_three_extension_task_catalog.dart';
import 'german_grammar_touch_task_catalog.dart';
import 'german_learning_domain.dart';
import 'german_lower_primary_task_catalog.dart';
import 'german_more_task_catalog.dart';
import 'german_morphology_touch_task_catalog.dart';
import 'german_speaking_task_catalog.dart';
import 'german_starter_task_catalog.dart';
import 'german_task.dart';
import 'german_touch_task_catalog.dart';
import 'german_upper_primary_expansion_task_catalog.dart';
import 'german_upper_primary_task_catalog.dart';
import 'german_writing_production_task_catalog.dart';

class GermanTaskCatalog {
  const GermanTaskCatalog._();

  static const tasks = <GermanTask>[
    ...GermanStarterTaskCatalog.tasks,
    ...GermanExtraTaskCatalog.tasks,
    ...GermanMoreTaskCatalog.tasks,
    ...GermanSpeakingTaskCatalog.tasks,
    ...GermanTouchTaskCatalog.tasks,
    ...GermanGrammarTouchTaskCatalog.tasks,
    ...GermanMorphologyTouchTaskCatalog.tasks,
    ...GermanLowerPrimaryTaskCatalog.tasks,
    ...GermanGradeThreeExtensionTaskCatalog.tasks,
    ...GermanGradeFourExtensionTaskCatalog.tasks,
    ...GermanWritingProductionTaskCatalog.tasks,
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
