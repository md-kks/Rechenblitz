import 'german_competency.dart';
import 'german_competency_catalog.dart';
import 'german_mistake_focus.dart';
import 'german_progress.dart';
import 'german_session.dart';

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
  });

  final GermanCompetencyId competencyId;
  final GermanLearningInsightState state;
  final String title;
  final String explanation;
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
      if (pattern != null) {
        if (pattern.needsGuidedPractice) {
          insights.add(
            GermanLearningInsight(
              competencyId: entry.competencyId,
              state: GermanLearningInsightState.needsPractice,
              title: 'Braucht noch Übung · $label',
              explanation:
                  'Bei mehreren unterschiedlichen Aufgaben zeigte sich dieselbe Stolperstelle. Wortblitz übt diesen Lernschritt deshalb gezielt und mit frischen Aufgaben.',
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
          ),
        );
      } else if (entry.attention(now: now) ==
          GermanPracticeAttention.needsPractice) {
        insights.add(
          GermanLearningInsight(
            competencyId: entry.competencyId,
            state: GermanLearningInsightState.needsPractice,
            title: 'Braucht noch Übung · $label',
            explanation:
                'Bei mindestens zwei unterschiedlichen Aufgaben gab es zuletzt selbstständige Fehlversuche. Wortblitz berücksichtigt das bei den nächsten Runden.',
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
          ),
        );
      }
    }
    insights.sort((a, b) => _priority(a.state).compareTo(_priority(b.state)));
    return List<GermanLearningInsight>.unmodifiable(insights);
  }

  static int _priority(GermanLearningInsightState state) => switch (state) {
    GermanLearningInsightState.needsPractice => 0,
    GermanLearningInsightState.transferCheck => 1,
    GermanLearningInsightState.consolidating => 2,
    GermanLearningInsightState.tentative => 3,
    GermanLearningInsightState.independentlyConfirmed => 4,
  };
}
