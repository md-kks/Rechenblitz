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
    this.rangeBridge = false,
    this.gradeBridge = false,
  });

  final GuidedRoundRole role;
  final TrainingMode mode;
  final int tasks;
  final String reason;
  final MicroCompetencyId? targetCompetency;
  final bool reviewEmphasis;
  final bool transferEmphasis;
  final bool scaffoldFading;
  final bool rangeBridge;
  final bool gradeBridge;

  bool get isBridge => rangeBridge || gradeBridge;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'role': role.name,
        'mode': mode.name,
        'tasks': tasks,
        'reason': reason,
        'targetCompetency': targetCompetency?.name,
        'reviewEmphasis': reviewEmphasis,
        'transferEmphasis': transferEmphasis,
        'scaffoldFading': scaffoldFading,
        'rangeBridge': rangeBridge,
        'gradeBridge': gradeBridge,
      };

  factory GuidedRoundSegment.fromJson(Map<String, dynamic> json) =>
      GuidedRoundSegment(
        role: GuidedRoundRole.values.byName(json['role'] as String),
        mode: TrainingMode.values.byName(json['mode'] as String),
        tasks: json['tasks'] as int,
        reason: json['reason'] as String,
        targetCompetency: json['targetCompetency'] == null
            ? null
            : MicroCompetencyId.values.byName(
                json['targetCompetency'] as String,
              ),
        reviewEmphasis: json['reviewEmphasis'] as bool? ?? false,
        transferEmphasis: json['transferEmphasis'] as bool? ?? false,
        scaffoldFading: json['scaffoldFading'] as bool? ?? false,
        rangeBridge: json['rangeBridge'] as bool? ?? false,
        gradeBridge: json['gradeBridge'] as bool? ?? false,
      );

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
        rangeBridge: rangeBridge,
        gradeBridge: gradeBridge,
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

class GuidedRoundProgress {
  const GuidedRoundProgress({
    required this.plan,
    required this.completedRoles,
    required this.gradeLevel,
    required this.numberRange,
    required this.startedAt,
    required this.updatedAt,
    required this.recoveryRequired,
    this.stepRecoveryAttempted = false,
    this.stepRecoveryCompleted = false,
    this.deferEmergingRecovery = false,
  });

  final List<GuidedRoundSegment> plan;
  final Set<GuidedRoundRole> completedRoles;
  final GradeLevel gradeLevel;
  final NumberRangeLevel numberRange;
  final DateTime startedAt;
  final DateTime updatedAt;
  final bool recoveryRequired;
  final bool stepRecoveryAttempted;
  final bool stepRecoveryCompleted;
  final bool deferEmergingRecovery;

  bool get isComplete =>
      plan.every((segment) => completedRoles.contains(segment.role)) &&
      (!recoveryRequired || stepRecoveryCompleted);

  bool isCompatible({
    required GradeLevel grade,
    required NumberRangeLevel range,
    DateTime? now,
  }) {
    if (grade != gradeLevel || range != numberRange) return false;
    final reference = now ?? DateTime.now();
    if (updatedAt.isAfter(reference.add(const Duration(minutes: 5)))) {
      return false;
    }
    if (isComplete) {
      return startedAt.year == reference.year &&
          startedAt.month == reference.month &&
          startedAt.day == reference.day;
    }
    return reference.difference(updatedAt) <= const Duration(hours: 24);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'plan': plan.map((segment) => segment.toJson()).toList(),
        'completedRoles': completedRoles.map((role) => role.name).toList(),
        'gradeLevel': gradeLevel.name,
        'numberRange': numberRange.name,
        'startedAt': startedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'recoveryRequired': recoveryRequired,
        'stepRecoveryAttempted': stepRecoveryAttempted,
        'stepRecoveryCompleted': stepRecoveryCompleted,
        'deferEmergingRecovery': deferEmergingRecovery,
      };

  factory GuidedRoundProgress.fromJson(Map<String, dynamic> json) =>
      GuidedRoundProgress(
        plan: (json['plan'] as List<dynamic>)
            .map(
              (entry) => GuidedRoundSegment.fromJson(
                entry as Map<String, dynamic>,
              ),
            )
            .toList(growable: false),
        completedRoles: (json['completedRoles'] as List<dynamic>? ?? const [])
            .map((name) => GuidedRoundRole.values.byName(name as String))
            .toSet(),
        gradeLevel: GradeLevel.values.byName(json['gradeLevel'] as String),
        numberRange:
            NumberRangeLevel.values.byName(json['numberRange'] as String),
        startedAt: DateTime.parse(json['startedAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        recoveryRequired: json['recoveryRequired'] as bool? ?? false,
        stepRecoveryAttempted:
            json['stepRecoveryAttempted'] as bool? ?? false,
        stepRecoveryCompleted:
            json['stepRecoveryCompleted'] as bool? ?? false,
        deferEmergingRecovery:
            json['deferEmergingRecovery'] as bool? ?? false,
      );
}

enum NumberRangeReadinessStatus { maximum, collecting, consolidate, ready }

class NumberRangeReadiness {
  const NumberRangeReadiness({
    required this.status,
    required this.currentRange,
    required this.nextRange,
    required this.evidencedCore,
    required this.secureCore,
    required this.confirmedCore,
    required this.averageIndependentAccuracy,
    required this.reason,
  });

  final NumberRangeReadinessStatus status;
  final NumberRangeLevel currentRange;
  final NumberRangeLevel? nextRange;
  final int evidencedCore;
  final int secureCore;
  final int confirmedCore;
  final double averageIndependentAccuracy;
  final String reason;

  bool get isReady => status == NumberRangeReadinessStatus.ready;
}

class NumberRangeBridgeStatus {
  const NumberRangeBridgeStatus({
    required this.previousRange,
    required this.currentRange,
    required this.foundationCompetencies,
    required this.confirmedCompetencies,
    required this.pendingCompetencies,
    required this.reason,
  });

  final NumberRangeLevel? previousRange;
  final NumberRangeLevel currentRange;
  final List<MicroCompetencyId> foundationCompetencies;
  final List<MicroCompetencyId> confirmedCompetencies;
  final List<MicroCompetencyId> pendingCompetencies;
  final String reason;

  bool get isActive =>
      previousRange != null &&
      foundationCompetencies.isNotEmpty &&
      pendingCompetencies.isNotEmpty;

  double get progress => foundationCompetencies.isEmpty
      ? 0
      : confirmedCompetencies.length / foundationCompetencies.length;
}

class GradeBridgeStatus {
  const GradeBridgeStatus({
    required this.previousGrade,
    required this.currentGrade,
    required this.foundationCompetencies,
    required this.confirmedCompetencies,
    required this.pendingCompetencies,
    required this.reason,
  });

  final GradeLevel? previousGrade;
  final GradeLevel currentGrade;
  final List<MicroCompetencyId> foundationCompetencies;
  final List<MicroCompetencyId> confirmedCompetencies;
  final List<MicroCompetencyId> pendingCompetencies;
  final String reason;

  bool get isActive =>
      previousGrade != null &&
      foundationCompetencies.isNotEmpty &&
      pendingCompetencies.isNotEmpty;

  double get progress => foundationCompetencies.isEmpty
      ? 0
      : confirmedCompetencies.length / foundationCompetencies.length;
}

class MicroCompetencyUnlockStatus {
  const MicroCompetencyUnlockStatus({
    required this.definition,
    required this.prerequisites,
    required this.unmetPrerequisites,
    required this.nextRequired,
    required this.reason,
  });

  final MicroCompetencyDefinition definition;
  final List<MicroCompetencyDefinition> prerequisites;
  final List<MicroCompetencyDefinition> unmetPrerequisites;
  final MicroCompetencyDefinition? nextRequired;
  final String reason;

  bool get hasPrerequisites => prerequisites.isNotEmpty;
  bool get isUnlocked => unmetPrerequisites.isEmpty;
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
    required this.stability,
    required this.mastery,
    required this.evidence,
    required this.selection,
  });

  final String good;
  final String focus;
  final String action;
  final String notYet;
  final String trend;
  final String stability;
  final String mastery;
  final String evidence;
  final String selection;
}
