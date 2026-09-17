import '../../core/grade_level.dart';
import 'german_competency_catalog.dart';
import 'german_learning_domain.dart';
import 'german_session.dart';
import 'german_task.dart';
import 'german_task_catalog.dart';

class GermanAssessmentPlanner {
  const GermanAssessmentPlanner._();

  static List<GermanTask> buildRound(
    GradeLevel gradeLevel, {
    int taskCount = 12,
    Iterable<GermanSessionResult> history = const <GermanSessionResult>[],
  }) {
    if (taskCount < 1) return const <GermanTask>[];
    final usage = _assessmentUsage(history);
    final selected = <GermanTask>[];
    final usedIds = <String>{};
    final usedCompetencies = <Object>{};

    for (final domain in GermanLearningDomain.values) {
      final candidates = _rankCandidates(
        GermanTaskCatalog.forDomain(domain, gradeLevel),
        usage,
        usedCompetencies,
      );
      if (candidates.isEmpty) continue;
      final task = candidates.first;
      selected.add(task);
      usedIds.add(task.id);
      usedCompetencies.add(task.competencyId);
    }

    while (selected.length < taskCount) {
      var added = false;
      for (final domain in GermanLearningDomain.values) {
        final candidates = _rankCandidates(
          GermanTaskCatalog.forDomain(
            domain,
            gradeLevel,
          ).where((task) => !usedIds.contains(task.id)),
          usage,
          usedCompetencies,
        );
        if (candidates.isEmpty) continue;
        final task = candidates.first;
        selected.add(task);
        usedIds.add(task.id);
        usedCompetencies.add(task.competencyId);
        added = true;
        if (selected.length == taskCount) break;
      }
      if (!added) break;
    }
    return selected.take(taskCount).toList(growable: false);
  }

  static List<GermanTask> _rankCandidates(
    Iterable<GermanTask> source,
    Map<String, ({int count, DateTime lastSeen})> usage,
    Set<Object> usedCompetencies,
  ) {
    final result = source.toList();
    result.sort((a, b) {
      final aUsedCompetency = usedCompetencies.contains(a.competencyId);
      final bUsedCompetency = usedCompetencies.contains(b.competencyId);
      if (aUsedCompetency != bUsedCompetency) {
        return aUsedCompetency ? 1 : -1;
      }
      final aUsage = usage[a.id];
      final bUsage = usage[b.id];
      final aCount = aUsage?.count ?? 0;
      final bCount = bUsage?.count ?? 0;
      if (aCount != bCount) return aCount.compareTo(bCount);
      if (aUsage == null && bUsage != null) return -1;
      if (aUsage != null && bUsage == null) return 1;
      if (aUsage != null &&
          bUsage != null &&
          aUsage.lastSeen != bUsage.lastSeen) {
        return aUsage.lastSeen.compareTo(bUsage.lastSeen);
      }
      return a.id.compareTo(b.id);
    });
    return result;
  }

  static Map<String, ({int count, DateTime lastSeen})> _assessmentUsage(
    Iterable<GermanSessionResult> history,
  ) {
    final result = <String, ({int count, DateTime lastSeen})>{};
    for (final session in history) {
      if (session.kind != GermanSessionKind.assessment) continue;
      for (final task in session.taskResults) {
        final previous = result[task.taskId];
        result[task.taskId] = (
          count: (previous?.count ?? 0) + 1,
          lastSeen:
              previous == null || session.finishedAt.isAfter(previous.lastSeen)
              ? session.finishedAt
              : previous.lastSeen,
        );
      }
    }
    return result;
  }
}

class GermanAssessmentDomainResult {
  const GermanAssessmentDomainResult({
    required this.domain,
    required this.total,
    required this.correctFirstTry,
  });
  final GermanLearningDomain domain;
  final int total;
  final int correctFirstTry;

  double get accuracy => total == 0 ? 0 : correctFirstTry / total;
}

class GermanAssessmentSummary {
  const GermanAssessmentSummary({required this.session, required this.domains});

  final GermanSessionResult session;
  final List<GermanAssessmentDomainResult> domains;

  List<GermanAssessmentDomainResult> get strongestDomains {
    final values = domains.where((value) => value.total > 0).toList();
    values.sort((a, b) => b.accuracy.compareTo(a.accuracy));
    return values.take(2).toList(growable: false);
  }

  List<GermanAssessmentDomainResult> get nextDomains {
    final values = domains.where((value) => value.total > 0).toList();
    values.sort((a, b) => a.accuracy.compareTo(b.accuracy));
    return values.take(2).toList(growable: false);
  }

  static GermanAssessmentSummary fromSession(GermanSessionResult session) {
    final byDomain = <GermanLearningDomain, List<GermanTaskResult>>{
      for (final domain in GermanLearningDomain.values)
        domain: <GermanTaskResult>[],
    };
    for (final result in session.taskResults) {
      final domain = GermanCompetencyCatalog.definition(
        result.competencyId,
      ).domain;
      byDomain[domain]!.add(result);
    }
    return GermanAssessmentSummary(
      session: session,
      domains: GermanLearningDomain.values
          .map((domain) {
            final results = byDomain[domain]!;
            return GermanAssessmentDomainResult(
              domain: domain,
              total: results.length,
              correctFirstTry: results
                  .where((value) => value.correctFirstTry)
                  .length,
            );
          })
          .toList(growable: false),
    );
  }
}
