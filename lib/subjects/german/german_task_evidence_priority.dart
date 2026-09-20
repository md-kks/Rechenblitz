import 'german_competency.dart';
import 'german_competency_catalog.dart';
import 'german_learning_domain.dart';
import 'german_task.dart';

class GermanTaskEvidencePriority {
  const GermanTaskEvidencePriority._();

  static int rank(GermanTask task) {
    if (task.competencyId == GermanCompetencyId.letterSoundMatch) {
      return switch (task.interaction) {
        GermanTaskInteraction.listeningChoice => 0,
        GermanTaskInteraction.singleChoice => 1,
        _ => 2,
      };
    }

    final domain = GermanCompetencyCatalog.definition(task.competencyId).domain;
    if (domain == GermanLearningDomain.listening) {
      return task.interaction == GermanTaskInteraction.listeningChoice ? 0 : 1;
    }

    return switch (task.interaction) {
      GermanTaskInteraction.typedText => 0,
      GermanTaskInteraction.wordOrder => 1,
      GermanTaskInteraction.tokenSelection => 2,
      GermanTaskInteraction.wordBuilder => 3,
      GermanTaskInteraction.singleChoice => 4,
      GermanTaskInteraction.listeningChoice => 5,
    };
  }
}
