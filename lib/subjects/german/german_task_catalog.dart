import '../../core/grade_level.dart';
import 'german_competency.dart';
import 'german_competency_catalog.dart';
import 'german_extra_task_catalog.dart';
import 'german_learning_domain.dart';
import 'german_more_task_catalog.dart';
import 'german_speaking_task_catalog.dart';
import 'german_starter_task_catalog.dart';
import 'german_task.dart';
import 'german_upper_primary_task_catalog.dart';

class GermanTaskCatalog {
  const GermanTaskCatalog._();

  static const tasks = <GermanTask>[
    ...GermanStarterTaskCatalog.tasks,
    ...GermanExtraTaskCatalog.tasks,
    ...GermanMoreTaskCatalog.tasks,
    ...GermanSpeakingTaskCatalog.tasks,
    ...GermanUpperPrimaryTaskCatalog.tasks,
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
