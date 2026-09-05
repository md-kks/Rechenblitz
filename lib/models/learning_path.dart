import 'micro_competency.dart';
import 'training.dart';

enum CompetencyState { newSkill, learning, secure, mastered }

extension CompetencyStateX on CompetencyState {
  String get label => switch (this) {
        CompetencyState.newSkill => 'Neu',
        CompetencyState.learning => 'Wird geübt',
        CompetencyState.secure => 'Sicher',
        CompetencyState.mastered => 'Gemeistert',
      };
}

class CompetencyProgress {
  const CompetencyProgress({
    required this.mode,
    required this.state,
    required this.accuracy,
    required this.tasks,
  });

  final TrainingMode mode;
  final CompetencyState state;
  final double accuracy;
  final int tasks;
}

class GuidedRoundSegment {
  const GuidedRoundSegment({
    required this.mode,
    required this.tasks,
    required this.reason,
    this.targetCompetency,
    this.reviewEmphasis = false,
    this.transferEmphasis = false,
  });

  final TrainingMode mode;
  final int tasks;
  final String reason;
  final MicroCompetencyId? targetCompetency;
  final bool reviewEmphasis;
  final bool transferEmphasis;
}

class GuidedStepFocus {
  const GuidedStepFocus({
    required this.competencyId,
    required this.stepKey,
    required this.label,
    required this.observations,
    required this.incorrectFirstAttempts,
    required this.accuracy,
    required this.lastSeen,
  });

  final MicroCompetencyId competencyId;
  final String stepKey;
  final String label;
  final int observations;
  final int incorrectFirstAttempts;
  final double accuracy;
  final DateTime lastSeen;
}

class ParentLearningInsight {
  const ParentLearningInsight({
    required this.good,
    required this.focus,
    required this.action,
    required this.notYet,
    required this.trend,
    required this.mastery,
    required this.evidence,
    required this.selection,
  });

  final String good;
  final String focus;
  final String action;
  final String notYet;
  final String trend;
  final String mastery;
  final String evidence;
  final String selection;
}
