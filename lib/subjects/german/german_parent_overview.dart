import '../../core/grade_level.dart';
import 'german_competency.dart';
import 'german_competency_catalog.dart';
import 'german_learning_domain.dart';
import 'german_progress.dart';
import 'german_session.dart';

class GermanDomainProgressSummary {
  const GermanDomainProgressSummary({
    required this.domain,
    required this.totalCompetencies,
    required this.practicedCompetencies,
    required this.secureCompetencies,
    required this.attempts,
    required this.correctFirstTry,
  });

  final GermanLearningDomain domain;
  final int totalCompetencies;
  final int practicedCompetencies;
  final int secureCompetencies;
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
    this.assessmentCount = 0,
    this.latestAssessment,
  });

  final GradeLevel gradeLevel;
  final int sessionCount;
  final int totalTasks;
  final int correctFirstTry;
  final int incorrectAttempts;
  final List<GermanCompetencyProgress> progress;
  final List<GermanDomainProgressSummary> domains;
  final int assessmentCount;
  final GermanSessionResult? latestAssessment;

  double get accuracy => totalTasks == 0 ? 0 : correctFirstTry / totalTasks;

  int get practicedCompetencies =>
      progress.where((entry) => entry.attempts > 0).length;

  int get secureCompetencies => progress
      .where((entry) => entry.state == GermanCompetencyState.secure)
      .length;

  int get learningCompetencies => progress
      .where((entry) => entry.state == GermanCompetencyState.learning)
      .length;

  List<GermanCompetencyProgress> get strengths {
    final values = progress.where((entry) => entry.attempts >= 3).toList();
    values.sort((a, b) {
      final accuracy = b.accuracy.compareTo(a.accuracy);
      if (accuracy != 0) return accuracy;
      return b.attempts.compareTo(a.attempts);
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
      final accuracy = a.accuracy.compareTo(b.accuracy);
      if (accuracy != 0) return accuracy;
      return b.attempts.compareTo(a.attempts);
    });
    return values.take(3).toList(growable: false);
  }

  static GermanParentOverview analyze({
    required GradeLevel gradeLevel,
    required Iterable<GermanSessionResult> history,
  }) {
    final sessions = history
        .where((session) => session.gradeLevel == gradeLevel)
        .toList(growable: false);
    final assessments = sessions
        .where((session) => session.kind == GermanSessionKind.assessment)
        .toList(growable: false);
    assessments.sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
    final definitions = GermanCompetencyCatalog.recommendedFor(gradeLevel);
    final progress = definitions
        .map(
          (definition) =>
              GermanProgressAnalyzer.forCompetency(definition.id, sessions),
        )
        .toList(growable: false);
    final byId = <GermanCompetencyId, GermanCompetencyProgress>{
      for (final entry in progress) entry.competencyId: entry,
    };
    final domains = GermanLearningDomain.values
        .map((domain) {
          final domainDefinitions = definitions
              .where((definition) => definition.domain == domain)
              .toList(growable: false);
          final domainProgress = domainDefinitions
              .map((definition) => byId[definition.id]!)
              .toList(growable: false);
          return GermanDomainProgressSummary(
            domain: domain,
            totalCompetencies: domainDefinitions.length,
            practicedCompetencies: domainProgress
                .where((entry) => entry.attempts > 0)
                .length,
            secureCompetencies: domainProgress
                .where((entry) => entry.state == GermanCompetencyState.secure)
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
      sessionCount: sessions.length,
      totalTasks: sessions.fold<int>(0, (sum, session) => sum + session.total),
      correctFirstTry: sessions.fold<int>(
        0,
        (sum, session) => sum + session.correctFirstTry,
      ),
      incorrectAttempts: sessions.fold<int>(
        0,
        (sum, session) => sum + session.incorrectAttempts,
      ),
      progress: progress,
      domains: domains,
      assessmentCount: assessments.length,
      latestAssessment: assessments.isEmpty ? null : assessments.first,
    );
  }
}
