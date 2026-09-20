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
      if (!task.requiresSpeech) return 6;
      return switch (task.interaction) {
        GermanTaskInteraction.wordOrder => 0,
        GermanTaskInteraction.tokenSelection => 1,
        GermanTaskInteraction.listeningChoice => 2,
        GermanTaskInteraction.typedText => 3,
        GermanTaskInteraction.wordBuilder => 4,
        GermanTaskInteraction.singleChoice => 5,
      };
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
