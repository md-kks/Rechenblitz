import '../../core/grade_level.dart';
import 'german_competency.dart';
import 'german_competency_catalog.dart';
import 'german_grade_bridge.dart';
import 'german_learning_domain.dart';
import 'german_progress.dart';
import 'german_session.dart';

class GermanDomainProgressSummary {
  const GermanDomainProgressSummary({
    required this.domain,
    required this.totalCompetencies,
    required this.practicedCompetencies,
    required this.secureCompetencies,
    required this.gradeBridgeCompetencies,
    required this.reviewDueCompetencies,
    required this.attempts,
    required this.correctFirstTry,
  });

  final GermanLearningDomain domain;
  final int totalCompetencies;
  final int practicedCompetencies;
  final int secureCompetencies;
  final int gradeBridgeCompetencies;
  final int reviewDueCompetencies;
  final int attempts;
  final int correctFirstTry;

  double get accuracy => attempts == 0 ? 0 : correctFirstTry / attempts;
}

class GermanParentOverview {
  const GermanParentOverview({
    required this.gradeLevel,
    required this.sessionCount,
    required this.totalTasks,
    required this.correctFirstTry,
    required this.incorrectAttempts,
    required this.progress,
    required this.domains,
    required this.gradeBridges,
    this.assessmentCount = 0,
    this.latestAssessment,
    this.referenceNow,
  });

  final GradeLevel gradeLevel;
  final int sessionCount;
  final int totalTasks;
  final int correctFirstTry;
  final int incorrectAttempts;
  final List<GermanCompetencyProgress> progress;
  final List<GermanDomainProgressSummary> domains;
  final List<GermanGradeBridgeStatus> gradeBridges;
  final int assessmentCount;
  final GermanSessionResult? latestAssessment;
  final DateTime? referenceNow;

  DateTime get _now => referenceNow ?? DateTime.now();

  double get accuracy => totalTasks == 0 ? 0 : correctFirstTry / totalTasks;

  int get practicedCompetencies =>
      progress.where((entry) => entry.attempts > 0).length;

  Set<GermanCompetencyId> get _pendingBridgeIds =>
      gradeBridges.map((entry) => entry.competencyId).toSet();

  int get secureCompetencies => progress
      .where(
        (entry) =>
            entry.state == GermanCompetencyState.secure &&
            !_pendingBridgeIds.contains(entry.competencyId),
      )
      .length;

  int get learningCompetencies => progress
      .where((entry) => entry.state == GermanCompetencyState.learning)
      .length;

  List<GermanCompetencyProgress> get strengths {
    final values = progress
        .where(
          (entry) =>
              entry.state == GermanCompetencyState.secure &&
              !_pendingBridgeIds.contains(entry.competencyId) &&
              entry.attention(now: _now) != GermanPracticeAttention.reviewDue,
        )
        .toList();
    values.sort((a, b) {
      final recent = b.recentAccuracy.compareTo(a.recentAccuracy);
      if (recent != 0) return recent;
      final overall = b.accuracy.compareTo(a.accuracy);
      if (overall != 0) return overall;
      return b.attempts.compareTo(a.attempts);
    });
    return values.take(3).toList(growable: false);
  }

  List<GermanCompetencyProgress> get reviewDue {
    final values = progress
        .where(
          (entry) =>
              !_pendingBridgeIds.contains(entry.competencyId) &&
              entry.attention(now: _now) == GermanPracticeAttention.reviewDue,
        )
        .toList();
    values.sort((a, b) {
      final aLast = a.lastPracticedAt;
      final bLast = b.lastPracticedAt;
      if (aLast == null && bLast != null) return -1;
      if (aLast != null && bLast == null) return 1;
      if (aLast != null && bLast != null) return aLast.compareTo(bLast);
      return a.competencyId.index.compareTo(b.competencyId.index);
    });
    return values.take(3).toList(growable: false);
  }

  List<GermanCompetencyProgress> get practiceNeeds {
    final values = progress
        .where(
          (entry) =>
              entry.attempts > 0 && entry.state != GermanCompetencyState.secure,
        )
        .toList();
    values.sort((a, b) {
      final recent = a.recentAccuracy.compareTo(b.recentAccuracy);
      if (recent != 0) return recent;
      final overall = a.accuracy.compareTo(b.accuracy);
      if (overall != 0) return overall;
      return b.attempts.compareTo(a.attempts);
    });
    return values.take(3).toList(growable: false);
  }

  static GermanParentOverview analyze({
    required GradeLevel gradeLevel,
    required Iterable<GermanSessionResult> history,
    DateTime? now,
  }) {
    final eligibleSessions = history
        .where((session) => session.gradeLevel.index <= gradeLevel.index)
        .toList(growable: false);
    final currentGradeSessions = eligibleSessions
        .where((session) => session.gradeLevel == gradeLevel)
        .toList(growable: false);
    final assessments = currentGradeSessions
        .where((session) => session.kind == GermanSessionKind.assessment)
        .toList(growable: false);
    assessments.sort((a, b) => b.finishedAt.compareTo(a.finishedAt));

    final definitions = GermanCompetencyCatalog.recommendedFor(gradeLevel);
    final progress = definitions
        .map(
          (definition) => GermanProgressAnalyzer.forCompetency(
            definition.id,
            eligibleSessions,
          ),
        )
        .toList(growable: false);
    final byId = <GermanCompetencyId, GermanCompetencyProgress>{
      for (final entry in progress) entry.competencyId: entry,
    };
    final gradeBridges = definitions
        .map(
          (definition) => GermanGradeBridgeAnalyzer.forCompetency(
            competencyId: definition.id,
            currentGrade: gradeLevel,
            history: eligibleSessions,
          ),
        )
        .where(
          (bridge) =>
              bridge.isPending &&
              byId[bridge.competencyId]?.state == GermanCompetencyState.secure,
        )
        .toList(growable: false);
    final bridgeIds = gradeBridges.map((bridge) => bridge.competencyId).toSet();

    final domains = GermanLearningDomain.values
        .map((domain) {
          final domainDefinitions = definitions
              .where((definition) => definition.domain == domain)
              .toList(growable: false);
          final domainProgress = domainDefinitions
              .map((definition) => byId[definition.id]!)
              .toList(growable: false);
          final domainBridgeIds = domainDefinitions
              .map((definition) => definition.id)
              .where(bridgeIds.contains)
              .toSet();
          return GermanDomainProgressSummary(
            domain: domain,
            totalCompetencies: domainDefinitions.length,
            practicedCompetencies: domainProgress
                .where((entry) => entry.attempts > 0)
                .length,
            secureCompetencies: domainProgress
                .where(
                  (entry) =>
                      entry.state == GermanCompetencyState.secure &&
                      !domainBridgeIds.contains(entry.competencyId),
                )
                .length,
            gradeBridgeCompetencies: domainBridgeIds.length,
            reviewDueCompetencies: domainProgress
                .where(
                  (entry) =>
                      !domainBridgeIds.contains(entry.competencyId) &&
                      entry.attention(now: now) ==
                          GermanPracticeAttention.reviewDue,
                )
                .length,
            attempts: domainProgress.fold<int>(
              0,
              (sum, entry) => sum + entry.attempts,
            ),
            correctFirstTry: domainProgress.fold<int>(
              0,
              (sum, entry) => sum + entry.correctFirstTry,
            ),
          );
        })
        .toList(growable: false);

    return GermanParentOverview(
      gradeLevel: gradeLevel,
      sessionCount: currentGradeSessions.length,
      totalTasks: currentGradeSessions.fold<int>(
        0,
        (sum, session) => sum + session.total,
      ),
      correctFirstTry: currentGradeSessions.fold<int>(
        0,
        (sum, session) => sum + session.correctFirstTry,
      ),
      incorrectAttempts: currentGradeSessions.fold<int>(
        0,
        (sum, session) => sum + session.incorrectAttempts,
      ),
      progress: progress,
      domains: domains,
      gradeBridges: gradeBridges,
      assessmentCount: assessments.length,
      latestAssessment: assessments.isEmpty ? null : assessments.first,
      referenceNow: now,
    );
  }
}
