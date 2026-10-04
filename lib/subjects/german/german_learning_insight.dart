import 'german_competency.dart';
import 'german_competency_catalog.dart';
import 'german_mistake_focus.dart';
import 'german_mistake_kind.dart';
import 'german_progress.dart';
import 'german_session.dart';

enum GermanLearningTrend {
  improving,
  steady,
  renewedAttention,
  insufficientEvidence,
}

enum GermanLearningInsightState {
  tentative,
  needsPractice,
  consolidating,
  transferCheck,
  independentlyConfirmed,
}

class GermanLearningInsight {
  const GermanLearningInsight({
    required this.competencyId,
    required this.state,
    required this.title,
    required this.explanation,
    required this.nextStep,
    required this.adultSupport,
    required this.trend,
    required this.trendText,
  });

  final GermanCompetencyId competencyId;
  final GermanLearningInsightState state;
  final String title;
  final String explanation;
  final String nextStep;
  final String adultSupport;
  final GermanLearningTrend trend;
  final String trendText;
}

class GermanLearningInsightAnalyzer {
  const GermanLearningInsightAnalyzer._();

  static List<GermanLearningInsight> analyze({
    required Iterable<GermanSessionResult> history,
    required Iterable<GermanCompetencyProgress> progress,
    DateTime? now,
  }) {
    final sessions = history.toList(growable: false);
    final focus = GermanMistakeFocusAnalyzer.analyze(
      history: sessions,
      now: now,
    );
    final focusByCompetency = <GermanCompetencyId, GermanMistakeFocusPattern>{};
    for (final pattern in focus.patterns) {
      focusByCompetency.putIfAbsent(pattern.competencyId, () => pattern);
    }
    final insights = <GermanLearningInsight>[];
    for (final entry in progress) {
      if (entry.attempts == 0) continue;
      final label = GermanCompetencyCatalog.definition(
        entry.competencyId,
      ).label;
      final pattern = focusByCompetency[entry.competencyId];
      final trend = _trend(entry.competencyId, sessions);
      final trendText = _trendText(trend);
      if (pattern != null) {
        if (pattern.needsGuidedPractice) {
          insights.add(
            GermanLearningInsight(
              competencyId: entry.competencyId,
              state: GermanLearningInsightState.needsPractice,
              title: 'Braucht noch Übung · $label',
              explanation:
                  'Bei mehreren unterschiedlichen Aufgaben zeigte sich dieselbe Stolperstelle. Wortblitz übt diesen Lernschritt deshalb gezielt und mit frischen Aufgaben.',
              nextStep:
                  'Als Nächstes: eine passende, stärker geführte Übung und danach eine neue selbstständige Aufgabe.',
              trend: trend,
              trendText: trendText,
              adultSupport: 'Unterstützung: ${pattern.kind.tip}',
            ),
          );
        } else {
          insights.add(
            GermanLearningInsight(
              competencyId: entry.competencyId,
              state: GermanLearningInsightState.transferCheck,
              title: 'Transfer wird geprüft · $label',
              explanation:
                  'Eine passende Übung gelang bereits selbstständig. Jetzt prüft Wortblitz, ob der Lernschritt auch in einer neuen Aufgabe sicher angewendet wird.',
              nextStep:
                  'Als Nächstes: eine neue Aufgabe, in der das Gelernte ohne direkte Vorgabe angewendet wird.',
              trend: trend,
              trendText: trendText,
              adultSupport:
                  'Unterstützung: Erst selbst versuchen lassen; nur bei Bedarf einen kurzen Denkhinweis geben.',
            ),
          );
        }
        continue;
      }
      if (entry.state == GermanCompetencyState.secure) {
        insights.add(
          GermanLearningInsight(
            competencyId: entry.competencyId,
            state: GermanLearningInsightState.independentlyConfirmed,
            title: 'Selbstständig bestätigt · $label',
            explanation:
                'Mehrere unterschiedliche Aufgaben wurden über verschiedene Runden hinweg überwiegend selbstständig direkt richtig gelöst.',
            nextStep:
                'Als Nächstes: im normalen Übungsrhythmus wiederholen, damit das Gelernte erhalten bleibt.',
            trend: trend,
            trendText: trendText,
            adultSupport:
                'Unterstützung: Keine zusätzliche Hilfe nötig; selbstständiges Anwenden reicht.',
          ),
        );
      } else if (entry.attention(now: now) ==
              GermanPracticeAttention.needsPractice &&
          !_hasResolvedRecentMistakeFocus(entry.competencyId, sessions)) {
        insights.add(
          GermanLearningInsight(
            competencyId: entry.competencyId,
            state: GermanLearningInsightState.needsPractice,
            title: 'Braucht noch Übung · $label',
            explanation:
                'Bei mindestens zwei unterschiedlichen Aufgaben gab es zuletzt selbstständige Fehlversuche. Wortblitz berücksichtigt das bei den nächsten Runden.',
            nextStep:
                'Als Nächstes: gezielte Wiederholung mit einer anderen Aufgabe desselben Lernschritts.',
            trend: trend,
            trendText: trendText,
            adultSupport:
                'Unterstützung: Nach dem Lösungsweg fragen und Zeit zum eigenen Verbessern geben.',
          ),
        );
      } else if (entry.needsMoreIndependentEvidence) {
        insights.add(
          GermanLearningInsight(
            competencyId: entry.competencyId,
            state: GermanLearningInsightState.consolidating,
            title: 'Wird gerade gefestigt · $label',
            explanation:
                'Der Lernschritt wurde bereits geübt, teilweise mit Unterstützung. Für eine sichere Einschätzung sammelt Wortblitz weitere selbstständige Belege.',
            nextStep:
                'Als Nächstes: ähnliche Aufgaben erneut ohne Vorlesen oder andere Hilfe bearbeiten.',
            trend: trend,
            trendText: trendText,
            adultSupport:
                'Unterstützung: Hilfe erst anbieten, nachdem das Kind einen eigenen Versuch gemacht hat.',
          ),
        );
      } else {
        insights.add(
          GermanLearningInsight(
            competencyId: entry.competencyId,
            state: GermanLearningInsightState.tentative,
            title: 'Einzelne Unsicherheit · $label',
            explanation:
                'Es gibt noch nicht genug wiederholte Hinweise für einen besonderen Förderbedarf. Wortblitz beobachtet den Lernschritt in weiteren Aufgaben.',
            nextStep:
                'Als Nächstes: normal weiterüben und erst bei wiederholten Schwierigkeiten gezielt fördern.',
            trend: trend,
            trendText: trendText,
            adultSupport:
                'Unterstützung: Nicht vorsagen; ruhig einen weiteren eigenen Versuch ermöglichen.',
          ),
        );
      }
    }
    insights.sort((a, b) => _priority(a.state).compareTo(_priority(b.state)));
    return List<GermanLearningInsight>.unmodifiable(insights);
  }

  static bool _hasResolvedRecentMistakeFocus(
    GermanCompetencyId competencyId,
    List<GermanSessionResult> sessions,
  ) {
    final relevant = <({GermanTaskResult result, DateTime at})>[];
    for (final session in sessions) {
      for (final result in session.taskResults) {
        if (result.competencyId == competencyId && !result.usedReadAloud) {
          relevant.add((result: result, at: session.finishedAt));
        }
      }
    }
    final mistakes = relevant
        .where((entry) => entry.result.firstMistakeKind != null)
        .toList(growable: false);
    if (mistakes.length < 2) return false;
    mistakes.sort((a, b) => b.at.compareTo(a.at));
    final latestKind = mistakes.first.result.firstMistakeKind;
    final sameKind = mistakes
        .where((entry) => entry.result.firstMistakeKind == latestKind)
        .toList(growable: false);
    if (sameKind.length < 2 ||
        sameKind.map((entry) => entry.result.taskId).toSet().length < 2) {
      return false;
    }
    final latestMistakeAt = sameKind
        .map((entry) => entry.at)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final confirmationCutoff = latestMistakeAt.add(const Duration(hours: 12));
    final cleanIds = relevant
        .where(
          (entry) =>
              !entry.at.isBefore(confirmationCutoff) &&
              entry.result.independentCorrectFirstTry &&
              entry.result.incorrectAttempts == 0 &&
              entry.result.firstMistakeKind == null,
        )
        .map((entry) => entry.result.taskId)
        .toSet();
    return cleanIds.length >= 2;
  }

  static GermanLearningTrend _trend(
    GermanCompetencyId competencyId,
    List<GermanSessionResult> sessions,
  ) {
    final independent = <GermanTaskResult>[];
    final ordered = sessions.toList()
      ..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
    for (final session in ordered) {
      for (final result in session.taskResults.reversed) {
        if (result.competencyId == competencyId && !result.usedReadAloud) {
          independent.add(result);
        }
      }
    }
    if (independent.length < 4) return GermanLearningTrend.insufficientEvidence;
    final recent = independent.take(3).toList(growable: false);
    final previous = independent.skip(3).take(3).toList(growable: false);
    if (previous.length < 2) return GermanLearningTrend.insufficientEvidence;
    double accuracy(List<GermanTaskResult> values) =>
        values.where((result) => result.correctFirstTry).length / values.length;
    final recentAccuracy = accuracy(recent);
    final previousAccuracy = accuracy(previous);
    if (recentAccuracy >= previousAccuracy + 0.25) {
      return GermanLearningTrend.improving;
    }
    if (previousAccuracy >= 0.75 && recentAccuracy <= previousAccuracy - 0.25) {
      return GermanLearningTrend.renewedAttention;
    }
    return GermanLearningTrend.steady;
  }

  static String _trendText(GermanLearningTrend trend) => switch (trend) {
    GermanLearningTrend.improving =>
      'Verlauf: In den letzten selbstständigen Aufgaben zeigt sich eine positive Entwicklung.',
    GermanLearningTrend.steady =>
      'Verlauf: Die letzten selbstständigen Aufgaben zeigen derzeit ein ähnliches Bild.',
    GermanLearningTrend.renewedAttention =>
      'Verlauf: Nach früher sichereren Aufgaben braucht dieser Lernschritt wieder etwas Aufmerksamkeit.',
    GermanLearningTrend.insufficientEvidence =>
      'Verlauf: Für einen belastbaren zeitlichen Vergleich gibt es noch zu wenige selbstständige Aufgaben.',
  };

  static int _priority(GermanLearningInsightState state) => switch (state) {
    GermanLearningInsightState.needsPractice => 0,
    GermanLearningInsightState.transferCheck => 1,
    GermanLearningInsightState.consolidating => 2,
    GermanLearningInsightState.tentative => 3,
    GermanLearningInsightState.independentlyConfirmed => 4,
  };
}
