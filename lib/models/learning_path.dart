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
    this.fluencyEmphasis = false,
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
  final bool fluencyEmphasis;
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
        'fluencyEmphasis': fluencyEmphasis,
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
        fluencyEmphasis: json['fluencyEmphasis'] as bool? ?? false,
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
        fluencyEmphasis: fluencyEmphasis,
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
    Map<GuidedRoundRole, int> completedTaskCounts = const <GuidedRoundRole, int>{},
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
        .fold<int>(
          0,
          (sum, segment) =>
              sum + (completedTaskCounts[segment.role] ?? segment.tasks),
        );
    var remaining = regularTaskBudget - completedTasks;
    final open = merged
        .where((segment) => !completedRoles.contains(segment.role))
        .toList(growable: false);
    if (remaining <= 0 || open.isEmpty) {
      return merged
          .where((segment) => completedRoles.contains(segment.role))
          .toList(growable: false);
    }
    final openTotal = open.fold<int>(0, (sum, segment) => sum + segment.tasks);
    if (remaining >= openTotal) return merged;

    final allocations = <GuidedRoundRole, int>{};
    if (remaining >= open.length) {
      for (final segment in open) {
        allocations[segment.role] = 1;
      }
      remaining -= open.length;
      while (remaining > 0) {
        var changed = false;
        for (final segment in open) {
          final current = allocations[segment.role] ?? 0;
          if (current >= segment.tasks || remaining <= 0) continue;
          allocations[segment.role] = current + 1;
          remaining -= 1;
          changed = true;
        }
        if (!changed) break;
      }
    } else {
      for (final segment in open.take(remaining)) {
        allocations[segment.role] = 1;
      }
      remaining = 0;
    }

    return <GuidedRoundSegment>[
      for (final segment in merged)
        if (completedRoles.contains(segment.role))
          segment
        else if ((allocations[segment.role] ?? 0) > 0)
          (allocations[segment.role] == segment.tasks
              ? segment
              : segment.copyWith(
                  tasks: allocations[segment.role],
                  reason:
                      '${segment.reason} Die restliche Runde bleibt bewusst kompakt.',
                )),
    ];
  }

  static List<GuidedRoundSegment> trimOptionalRepetition({
    required List<GuidedRoundSegment> plan,
    required Set<GuidedRoundRole> completedRoles,
    int reductions = 1,
  }) {
    if (reductions <= 0) return List<GuidedRoundSegment>.from(plan);
    final result = List<GuidedRoundSegment>.from(plan);
    var remaining = reductions;
    const order = <GuidedRoundRole>[
      GuidedRoundRole.review,
      GuidedRoundRole.apply,
      GuidedRoundRole.warmUp,
      GuidedRoundRole.focus,
    ];
    for (final role in order) {
      if (remaining <= 0 || completedRoles.contains(role)) continue;
      final index = result.indexWhere((segment) => segment.role == role);
      if (index < 0) continue;
      final segment = result[index];
      if (segment.tasks <= 1 ||
          segment.reviewEmphasis ||
          segment.transferEmphasis ||
          segment.fluencyEmphasis ||
          segment.isBridge) {
        continue;
      }
      final reduction = remaining < segment.tasks - 1
          ? remaining
          : segment.tasks - 1;
      result[index] = segment.copyWith(
        tasks: segment.tasks - reduction,
        reason:
            '${segment.reason} Aktuelle sichere Evidenz erlaubt hier weniger Wiederholung.',
      );
      remaining -= reduction;
    }
    return result;
  }
}

enum GuidedRoundAdaptationKind {
  steady,
  reprioritized,
  confirmed,
  support,
}

extension GuidedRoundAdaptationKindX on GuidedRoundAdaptationKind {
  String get label => switch (this) {
        GuidedRoundAdaptationKind.steady => 'Plan aktualisiert',
        GuidedRoundAdaptationKind.reprioritized => 'Priorität angepasst',
        GuidedRoundAdaptationKind.confirmed => 'Sicher bestätigt',
        GuidedRoundAdaptationKind.support => 'Runde entlastet',
      };
}

class GuidedRoundAdaptation {
  const GuidedRoundAdaptation({
    required this.plan,
    required this.kind,
    required this.message,
  });

  final List<GuidedRoundSegment> plan;
  final GuidedRoundAdaptationKind kind;
  final String message;
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
    this.decisionTrace = const GuidedRoundDecisionTrace(items: <GuidedRoundDecisionItem>[]),
    this.lastAdaptationKind,
    this.lastAdaptationMessage,
    this.completedTaskCounts = const <GuidedRoundRole, int>{},
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
  final GuidedRoundDecisionTrace decisionTrace;
  final GuidedRoundAdaptationKind? lastAdaptationKind;
  final String? lastAdaptationMessage;
  final Map<GuidedRoundRole, int> completedTaskCounts;

  int completedTasksFor(GuidedRoundSegment segment) {
    if (!completedRoles.contains(segment.role)) return 0;
    return completedTaskCounts[segment.role] ?? segment.tasks;
  }

  int get completedRegularTasks => plan.fold<int>(
        0,
        (sum, segment) => sum + completedTasksFor(segment),
      );

  int get effectiveRegularTaskTotal => plan.fold<int>(
        0,
        (sum, segment) =>
            sum +
            (completedRoles.contains(segment.role)
                ? completedTasksFor(segment)
                : segment.tasks),
      );

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
        'decisionTrace': decisionTrace.toJson(),
        'lastAdaptationKind': lastAdaptationKind?.name,
        'lastAdaptationMessage': lastAdaptationMessage,
        'completedTaskCounts': <String, int>{
          for (final entry in completedTaskCounts.entries)
            entry.key.name: entry.value,
        },
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
        decisionTrace: json['decisionTrace'] is Map<String, dynamic>
            ? GuidedRoundDecisionTrace.fromJson(
                json['decisionTrace'] as Map<String, dynamic>,
              )
            : const GuidedRoundDecisionTrace(items: <GuidedRoundDecisionItem>[]),
        lastAdaptationKind: json['lastAdaptationKind'] == null
            ? null
            : GuidedRoundAdaptationKind.values.byName(
                json['lastAdaptationKind'] as String,
              ),
        lastAdaptationMessage: json['lastAdaptationMessage'] as String?,
        completedTaskCounts: json['completedTaskCounts'] is Map
            ? <GuidedRoundRole, int>{
                for (final entry in
                    (json['completedTaskCounts'] as Map).entries)
                  GuidedRoundRole.values.byName(entry.key as String):
                      (entry.value as num).toInt(),
              }
            : const <GuidedRoundRole, int>{},
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

enum GuidedRoundDecisionKind {
  recovery,
  focus,
  prerequisite,
  dueReview,
  dueTransfer,
  gradeBridge,
  rangeBridge,
  maintenance,
  fluency,
  discovery,
  fallback,
}

extension GuidedRoundDecisionKindX on GuidedRoundDecisionKind {
  String get label => switch (this) {
        GuidedRoundDecisionKind.recovery => 'Unsicherheit zuerst klären',
        GuidedRoundDecisionKind.focus => 'Aktueller Lernfokus',
        GuidedRoundDecisionKind.prerequisite => 'Voraussetzung zuerst',
        GuidedRoundDecisionKind.dueReview => 'Abstandskontrolle fällig',
        GuidedRoundDecisionKind.dueTransfer => 'Transfer fällig',
        GuidedRoundDecisionKind.gradeBridge => 'Klassenstufen-Brücke',
        GuidedRoundDecisionKind.rangeBridge => 'Zahlenraum-Brücke',
        GuidedRoundDecisionKind.maintenance => 'Sichere Grundlage erhalten',
        GuidedRoundDecisionKind.fluency => 'Automatisierung aufbauen',
        GuidedRoundDecisionKind.discovery => 'Neues vorsichtig entdecken',
        GuidedRoundDecisionKind.fallback => 'Abwechslungsreich weiterüben',
      };
}

class GuidedRoundDecisionItem {
  const GuidedRoundDecisionItem({
    required this.kind,
    required this.detail,
    required this.priority,
    required this.selected,
    this.competencyId,
  });

  final GuidedRoundDecisionKind kind;
  final String detail;
  final int priority;
  final bool selected;
  final MicroCompetencyId? competencyId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'kind': kind.name,
        'detail': detail,
        'priority': priority,
        'selected': selected,
        'competencyId': competencyId?.name,
      };

  factory GuidedRoundDecisionItem.fromJson(Map<String, dynamic> json) =>
      GuidedRoundDecisionItem(
        kind: GuidedRoundDecisionKind.values.byName(json['kind'] as String),
        detail: json['detail'] as String,
        priority: json['priority'] as int,
        selected: json['selected'] as bool,
        competencyId: json['competencyId'] == null
            ? null
            : MicroCompetencyId.values.byName(json['competencyId'] as String),
      );
}

class GuidedRoundDecisionTrace {
  const GuidedRoundDecisionTrace({required this.items});

  final List<GuidedRoundDecisionItem> items;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'items': items.map((item) => item.toJson()).toList(),
      };

  factory GuidedRoundDecisionTrace.fromJson(Map<String, dynamic> json) =>
      GuidedRoundDecisionTrace(
        items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
            .map((item) => GuidedRoundDecisionItem.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
      );

  List<GuidedRoundDecisionItem> get selected =>
      items.where((item) => item.selected).toList(growable: false);

  List<GuidedRoundDecisionItem> get deferred =>
      items.where((item) => !item.selected).toList(growable: false);

  GuidedRoundDecisionItem? get primary {
    final chosen = selected.toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
    return chosen.isEmpty ? null : chosen.first;
  }

  String get summary {
    if (items.isEmpty) {
      return 'Für diese Runde liegen noch zu wenige Mikro-Daten für eine detaillierte Prioritätsentscheidung vor.';
    }
    final chosen = selected;
    final held = deferred;
    final chosenText = chosen.isEmpty
        ? 'keine spezielle Priorität'
        : chosen
            .map((item) => '${item.kind.label}: ${item.detail}')
            .join(' · ');
    if (held.isEmpty) return 'Gewählt: $chosenText.';
    final heldText = held
        .map((item) => '${item.kind.label}: ${item.detail}')
        .join(' · ');
    return 'Gewählt: $chosenText. Zurückgestellt: $heldText.';
  }
}

class LearningCompletionInsight {
  const LearningCompletionInsight({
    required this.title,
    required this.detail,
    required this.nextStep,
    this.fluency = false,
  });

  final String title;
  final String detail;
  final String nextStep;
  final bool fluency;
}

class ParentLearningInsight {
  const ParentLearningInsight({
    required this.good,
    required this.focus,
    required this.action,
    required this.notYet,
    required this.trend,
    required this.confidence,
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
  final String confidence;
  final String stability;
  final String mastery;
  final String evidence;
  final String selection;
}
