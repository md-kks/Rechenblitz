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

enum GuidedRoundRole { warmUp, focus, review, apply }

extension GuidedRoundRoleX on GuidedRoundRole {
  String get label => switch (this) {
        GuidedRoundRole.warmUp => 'Ankommen',
        GuidedRoundRole.focus => 'Heute wichtig',
        GuidedRoundRole.review => 'Wiederholen',
        GuidedRoundRole.apply => 'Anwenden',
      };
}

class GuidedRoundSegment {
  const GuidedRoundSegment({
    required this.role,
    required this.mode,
    required this.tasks,
    required this.reason,
    this.targetCompetency,
    this.reviewEmphasis = false,
    this.transferEmphasis = false,
    this.scaffoldFading = false,
  });

  final GuidedRoundRole role;
  final TrainingMode mode;
  final int tasks;
  final String reason;
  final MicroCompetencyId? targetCompetency;
  final bool reviewEmphasis;
  final bool transferEmphasis;
  final bool scaffoldFading;

  GuidedRoundSegment copyWith({
    int? tasks,
    String? reason,
  }) =>
      GuidedRoundSegment(
        role: role,
        mode: mode,
        tasks: tasks ?? this.tasks,
        reason: reason ?? this.reason,
        targetCompetency: targetCompetency,
        reviewEmphasis: reviewEmphasis,
        transferEmphasis: transferEmphasis,
        scaffoldFading: scaffoldFading,
      );
}

class GuidedRoundOrchestrator {
  const GuidedRoundOrchestrator._();

  static List<GuidedRoundSegment> mergeRemaining({
    required List<GuidedRoundSegment> current,
    required List<GuidedRoundSegment> updated,
    required Set<GuidedRoundRole> completedRoles,
    int? regularTaskBudget,
  }) {
    final completedSegments = <GuidedRoundRole, GuidedRoundSegment>{
      for (final segment in current)
        if (completedRoles.contains(segment.role)) segment.role: segment,
    };
    final merged = <GuidedRoundSegment>[
      for (final segment in updated)
        completedSegments[segment.role] ?? segment,
    ];
    if (regularTaskBudget == null) return merged;

    final completedTasks = merged
        .where((segment) => completedRoles.contains(segment.role))
        .fold<int>(0, (sum, segment) => sum + segment.tasks);
    var remaining = regularTaskBudget - completedTasks;
    final compacted = <GuidedRoundSegment>[];
    for (final segment in merged) {
      if (completedRoles.contains(segment.role)) {
        compacted.add(segment);
        continue;
      }
      if (remaining <= 0) continue;
      final allocated = segment.tasks <= remaining ? segment.tasks : remaining;
      compacted.add(
        allocated == segment.tasks
            ? segment
            : segment.copyWith(
                tasks: allocated,
                reason:
                    '${segment.reason} Die Runde bleibt trotz Kurz-Übung kompakt.',
              ),
      );
      remaining -= allocated;
    }
    return compacted;
  }
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
