import '../../core/grade_level.dart';
import 'german_competency.dart';
import 'german_competency_catalog.dart';
import 'german_grade_bridge.dart';
import 'german_history_scope.dart';
import 'german_learning_domain.dart';
import 'german_progress.dart';
import 'german_session.dart';

class GermanRewardBadge {
  const GermanRewardBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.iconKey,
  });

  final String id;
  final String title;
  final String description;
  final String iconKey;
}

class GermanRewardSummary {
  const GermanRewardSummary({required this.stars, required this.badges});

  final int stars;
  final List<GermanRewardBadge> badges;
  factory GermanRewardSummary.fromHistory({
    required GradeLevel gradeLevel,
    required Iterable<GermanSessionResult> history,
  }) {
    final sessions = GermanHistoryScope.unique(
      history.where(
        (session) =>
            session.gradeLevel.index <= gradeLevel.index &&
            session.kind != GermanSessionKind.assessment,
      ),
    );

    var stars = 0;
    for (final session in sessions) {
      stars += 1;
      if (session.total >= 4 && session.accuracy >= 0.8) stars += 1;
      if (session.incorrectAttempts >= 2) stars += 1;
    }

    final competencyIds = sessions
        .expand((session) => session.taskResults)
        .map((result) => result.competencyId)
        .toSet();
    final domains = competencyIds
        .map((id) => GermanCompetencyCatalog.definition(id).domain)
        .toSet();
    final everSecure = <GermanCompetencyId>{};
    var everConfirmedGradeBridge = false;
    for (final grade in GradeLevel.values) {
      if (grade.index > gradeLevel.index) break;
      final gradeHistory = sessions
          .where((session) => session.gradeLevel.index <= grade.index)
          .toList(growable: false);
      for (final definition in GermanCompetencyCatalog.recommendedFor(grade)) {
        final progress = GermanProgressAnalyzer.forCompetency(
          definition.id,
          gradeHistory,
        );
        final bridge = GermanGradeBridgeAnalyzer.forCompetency(
          competencyId: definition.id,
          currentGrade: grade,
          history: gradeHistory,
        );
        if (bridge.isConfirmed) everConfirmedGradeBridge = true;
        if (progress.state == GermanCompetencyState.secure &&
            !bridge.isPending) {
          everSecure.add(definition.id);
        }
      }
    }
    final secureCount = everSecure.length;

    final badges = <GermanRewardBadge>[];
    void add(String id, String title, String description, String iconKey) {
      badges.add(
        GermanRewardBadge(
          id: id,
          title: title,
          description: description,
          iconKey: iconKey,
        ),
      );
    }

    if (sessions.isNotEmpty) {
      add(
        'first_round',
        'Erste Deutsch-Runde',
        'Du hast deine erste Deutsch-Runde abgeschlossen.',
        'flag',
      );
    }
    if (sessions.any((session) => session.incorrectAttempts >= 2)) {
      add(
        'keep_going',
        'Drangeblieben',
        'Du hast auch nach mehreren Fehlversuchen weitergemacht.',
        'courage',
      );
    }
    if (competencyIds.length >= 5) {
      add(
        'explorer',
        'Wortentdecker',
        'Du hast mindestens fünf verschiedene Deutsch-Lernschritte geübt.',
        'explore',
      );
    }
    if (domains.length == GermanLearningDomain.values.length) {
      add(
        'all_domains',
        'Deutsch-Entdecker',
        'Du hast in allen Deutsch-Lernbereichen gearbeitet.',
        'domains',
      );
    }
    if (everConfirmedGradeBridge) {
      add(
        'grade_step',
        'Stufensteiger',
        'Du hast einen bekannten Deutsch-Lernschritt auf einer höheren Klassenstufe bestätigt.',
        'stairs',
      );
    }
    if (secureCount >= 1) {
      add(
        'first_secure',
        'Erster sicherer Lernschritt',
        'Ein Deutsch-Lernschritt ist über mehrere Aufgaben und Runden sicher.',
        'secure',
      );
    }
    if (secureCount >= 5) {
      add(
        'five_secure',
        'Lernschritt-Meister',
        'Fünf Deutsch-Lernschritte sind sicher geworden.',
        'mastery',
      );
    }
    if (sessions.length >= 10) {
      add(
        'ten_rounds',
        'Zehn Runden',
        'Du hast zehn Deutsch-Runden abgeschlossen.',
        'rounds',
      );
    }
    if (sessions.any(
      (session) => session.total >= 5 && session.accuracy == 1,
    )) {
      add(
        'perfect_round',
        'Starke Runde',
        'Mindestens fünf Aufgaben waren beim ersten Versuch richtig.',
        'perfect',
      );
    }

    return GermanRewardSummary(
      stars: stars,
      badges: List<GermanRewardBadge>.unmodifiable(badges),
    );
  }
}
