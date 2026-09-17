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
  }) {
    if (taskCount < 1) return const <GermanTask>[];
    final selected = <GermanTask>[];
    final usedIds = <String>{};
    final usedCompetencies = <Object>{};
    for (final domain in GermanLearningDomain.values) {
      final domainTasks = GermanTaskCatalog.forDomain(domain, gradeLevel);
      for (final task in domainTasks) {
        if (usedCompetencies.contains(task.competencyId)) continue;
        selected.add(task);
        usedIds.add(task.id);
        usedCompetencies.add(task.competencyId);
        break;
      }
    }

    var cursor = 0;
    while (selected.length < taskCount) {
      var added = false;
      for (final domain in GermanLearningDomain.values) {
        final candidates = GermanTaskCatalog.forDomain(domain, gradeLevel);
        if (candidates.isEmpty) continue;
        for (var offset = 0; offset < candidates.length; offset++) {
          final task = candidates[(cursor + offset) % candidates.length];
          if (!usedIds.add(task.id)) continue;
          selected.add(task);
          usedCompetencies.add(task.competencyId);
          added = true;
          break;
        }
        if (selected.length == taskCount) break;
      }
      cursor += 1;
      if (!added) break;
    }
    return selected.take(taskCount).toList(growable: false);
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
