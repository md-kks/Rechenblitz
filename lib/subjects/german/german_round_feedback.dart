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
    final extra = result.incorrectAttempts;

    if (total == 0) {
      return const GermanRoundFeedback(
        headline: 'Runde geschafft',
        detail: 'Deine nächste Runde wartet schon.',
        spokenText: 'Runde geschafft. Deine nächste Runde wartet schon.',
      );
    }
    final accuracy = firstTry / total;
    if (firstTry == total) {
      return GermanRoundFeedback(
        headline: 'Alles direkt geschafft',
        detail: '$firstTry von $total Aufgaben waren gleich beim ersten Versuch richtig.',
        spokenText:
            'Stark gemacht. Du hast alle $total Aufgaben direkt richtig gelöst.',
      );
    }

    if (accuracy >= 0.75) {
      return GermanRoundFeedback(
        headline: 'Sehr sicher gearbeitet',
        detail:
            '$firstTry von $total Aufgaben waren direkt richtig. Die anderen hast du weitergelöst.',
        spokenText:
            'Gut gearbeitet. $firstTry von $total Aufgaben hast du direkt richtig gelöst. Die übrigen hast du mit weiteren Versuchen geschafft.',
      );
    }
    if (accuracy >= 0.5) {
      return GermanRoundFeedback(
        headline: 'Gut drangeblieben',
        detail:
            '$firstTry von $total Aufgaben waren direkt richtig. Die kniffligen Stellen kommen später noch einmal.',
        spokenText:
            'Du hast dich gut durch die Runde gearbeitet. $firstTry von $total Aufgaben waren direkt richtig. Die anderen üben wir weiter.',
      );
    }

    final effort = extra > 0 ? ' Du hast trotzdem weiterprobiert.' : '';
    return GermanRoundFeedback(
      headline: 'Weiter geht’s Schritt für Schritt',
      detail:
          'Heute waren einige Aufgaben noch knifflig.$effort Die nächste Runde übt passende Stellen erneut.',
      spokenText:
          'Gut drangeblieben. Heute waren einige Aufgaben noch knifflig. In der nächsten Runde üben wir die passenden Stellen noch einmal.',
    );
  }
}
