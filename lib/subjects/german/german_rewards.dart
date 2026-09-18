import '../../core/grade_level.dart';
import 'german_competency_catalog.dart';
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
    final sessions = history
        .where(
          (session) =>
              session.gradeLevel == gradeLevel &&
              session.kind != GermanSessionKind.assessment,
        )
        .toList(growable: false);

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
    final progress = GermanCompetencyCatalog.recommendedFor(gradeLevel)
        .map(
          (definition) =>
              GermanProgressAnalyzer.forCompetency(definition.id, sessions),
        )
        .toList(growable: false);
    final secureCount = progress
        .where((entry) => entry.state == GermanCompetencyState.secure)
        .length;

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
