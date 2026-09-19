import 'german_competency.dart';
import 'german_competency_catalog.dart';
import 'german_session.dart';

class GermanRoundFeedback {
  const GermanRoundFeedback({
    required this.headline,
    required this.detail,
    required this.spokenText,
  });

  final String headline;
  final String detail;
  final String spokenText;

  static GermanRoundFeedback forSession(GermanSessionResult result) {
    final total = result.total;
    final firstTry = result.correctFirstTry;
    final independentTotal = result.independentAttempts;
    final independentFirstTry = result.independentCorrectFirstTry;
    final assisted = result.readAloudAssistedAttempts;
    final extra = result.incorrectAttempts;

    if (total == 0) {
      return const GermanRoundFeedback(
        headline: 'Runde geschafft',
        detail: 'Deine nächste Runde wartet schon.',
        spokenText: 'Runde geschafft. Deine nächste Runde wartet schon.',
      );
    }
    final nextStepId = _nextStepId(result);
    final strengthId = _strengthId(result, except: nextStepId);
    final strength = strengthId == null
        ? null
        : GermanCompetencyCatalog.definition(strengthId).label;
    final nextStep = nextStepId == null
        ? null
        : GermanCompetencyCatalog.definition(nextStepId).label;
    final strengthSentence = strength == null
        ? ''
        : ' In dieser Runde lief „$strength“ besonders gut.';
    final nextStepSentence = nextStep == null
        ? ''
        : ' Als Nächstes üben wir „$nextStep“ weiter.';

    if (assisted > 0) {
      if (independentTotal == 0) {
        return GermanRoundFeedback(
          headline: 'Runde geschafft',
          detail:
              '$assisted ${assisted == 1 ? 'Aufgabe' : 'Aufgaben'} mit Vorlesen geübt. '
              'Das war eine hilfreiche Unterstützung; für selbstständiges Lesen sammeln wir beim nächsten Mal noch einen eigenen Beleg.$nextStepSentence',
          spokenText:
              'Runde geschafft. Du hast $assisted ${assisted == 1 ? 'Aufgabe' : 'Aufgaben'} mit Vorlesen geübt. '
              'Beim nächsten Mal schauen wir auch wieder auf selbstständiges Lesen.$nextStepSentence',
        );
      }
      final independentAccuracy = independentFirstTry / independentTotal;
      final supportSentence =
          ' $assisted ${assisted == 1 ? 'Aufgabe' : 'Aufgaben'} hast du mit Vorlesen geübt.';
      if (independentAccuracy >= 0.75) {
        return GermanRoundFeedback(
          headline: 'Gut gearbeitet',
          detail:
              '$independentFirstTry von $independentTotal selbstständigen Aufgaben waren direkt richtig.$supportSentence$strengthSentence$nextStepSentence',
          spokenText:
              'Gut gearbeitet. $independentFirstTry von $independentTotal selbstständigen Aufgaben waren direkt richtig.$supportSentence$strengthSentence$nextStepSentence',
        );
      }
      if (independentAccuracy >= 0.5) {
        return GermanRoundFeedback(
          headline: 'Gut drangeblieben',
          detail:
              '$independentFirstTry von $independentTotal selbstständigen Aufgaben waren direkt richtig.$supportSentence$strengthSentence$nextStepSentence',
          spokenText:
              'Du bist gut drangeblieben. $independentFirstTry von $independentTotal selbstständigen Aufgaben waren direkt richtig.$supportSentence$strengthSentence$nextStepSentence',
        );
      }
      return GermanRoundFeedback(
        headline: 'Weiter geht’s Schritt für Schritt',
        detail:
            'Heute waren einige selbstständige Aufgaben noch knifflig.$supportSentence$strengthSentence$nextStepSentence',
        spokenText:
            'Gut drangeblieben. Heute waren einige selbstständige Aufgaben noch knifflig.$supportSentence$strengthSentence$nextStepSentence',
      );
    }

    final accuracy = firstTry / total;
    if (firstTry == total) {
      return GermanRoundFeedback(
        headline: 'Alles direkt geschafft',
        detail:
            '$firstTry von $total Aufgaben waren gleich beim ersten Versuch richtig.$strengthSentence',
        spokenText:
            'Stark gemacht. Du hast alle $total Aufgaben direkt richtig gelöst.$strengthSentence',
      );
    }

    if (accuracy >= 0.75) {
      return GermanRoundFeedback(
        headline: 'Sehr sicher gearbeitet',
        detail:
            '$firstTry von $total Aufgaben waren direkt richtig. Die anderen hast du weitergelöst.$strengthSentence$nextStepSentence',
        spokenText:
            'Gut gearbeitet. $firstTry von $total Aufgaben hast du direkt richtig gelöst. Die übrigen hast du mit weiteren Versuchen geschafft.$strengthSentence$nextStepSentence',
      );
    }
    if (accuracy >= 0.5) {
      return GermanRoundFeedback(
        headline: 'Gut drangeblieben',
        detail:
            '$firstTry von $total Aufgaben waren direkt richtig.$strengthSentence$nextStepSentence',
        spokenText:
            'Du hast dich gut durch die Runde gearbeitet. $firstTry von $total Aufgaben waren direkt richtig.$strengthSentence$nextStepSentence',
      );
    }

    final effort = extra > 0 ? ' Du hast trotzdem weiterprobiert.' : '';
    return GermanRoundFeedback(
      headline: 'Weiter geht’s Schritt für Schritt',
      detail:
          'Heute waren einige Aufgaben noch knifflig.$effort$strengthSentence$nextStepSentence',
      spokenText:
          'Gut drangeblieben. Heute waren einige Aufgaben noch knifflig.$strengthSentence$nextStepSentence',
    );
  }

  static GermanCompetencyId? _nextStepId(GermanSessionResult result) {
    final scores = <GermanCompetencyId, int>{};
    for (final task in result.taskResults) {
      if (task.correctFirstTry) continue;
      scores[task.competencyId] =
          (scores[task.competencyId] ?? 0) + 1 + task.incorrectAttempts;
    }
    return _highestScore(scores);
  }

  static GermanCompetencyId? _strengthId(
    GermanSessionResult result, {
    GermanCompetencyId? except,
  }) {
    final scores = <GermanCompetencyId, int>{};
    for (final task in result.taskResults) {
      if (!task.independentCorrectFirstTry) continue;
      scores[task.competencyId] = (scores[task.competencyId] ?? 0) + 1;
    }
    if (except != null && scores.containsKey(except)) {
      if (scores.length == 1) return null;
      scores.remove(except);
    }
    return _highestScore(scores);
  }

  static GermanCompetencyId? _highestScore(
    Map<GermanCompetencyId, int> scores,
  ) {
    GermanCompetencyId? best;
    var bestScore = -1;
    for (final entry in scores.entries) {
      if (entry.value > bestScore) {
        best = entry.key;
        bestScore = entry.value;
      }
    }
    return best;
  }
}
