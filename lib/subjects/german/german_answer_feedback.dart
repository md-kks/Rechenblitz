import 'german_task.dart';

class GermanAnswerFeedback {
  const GermanAnswerFeedback._();

  static const retry = 'Noch nicht. Versuch es noch einmal.';

  static String forIncorrect(GermanTask task, String answer) {
    if (task.acceptedAnswers.isEmpty) return retry;

    switch (task.interaction) {
      case GermanTaskInteraction.singleChoice:
        return 'Noch nicht. Vergleiche deine Auswahl noch einmal genau mit '
            'der Aufgabe.';
      case GermanTaskInteraction.listeningChoice:
        return 'Noch nicht. Hör die Aufgabe noch einmal an und achte nur auf '
            'die gesuchte Information.';
      case GermanTaskInteraction.wordOrder:
        return 'Alle Satzbausteine sind da. Prüfe noch einmal ihre '
            'Reihenfolge.';
      case GermanTaskInteraction.wordBuilder:
        return 'Noch nicht. Sprich das Wort langsam und prüfe die '
            'Bausteine von links nach rechts.';
      case GermanTaskInteraction.typedText:
        break;
    }

    final given = _spaces(answer);
    final expected = task.acceptedAnswers.map(_spaces).toList(growable: false);

    if (expected.any((value) => given.toLowerCase() == value.toLowerCase())) {
      return 'Fast richtig. Prüfe die Groß- und Kleinschreibung.';
    }

    if (expected.any(
      (value) =>
          _withoutEnding(given).toLowerCase() ==
          _withoutEnding(value).toLowerCase(),
    )) {
      return 'Fast richtig. Prüfe das Satzzeichen am Ende.';
    }

    final givenWords = _words(given);
    if (expected.any((value) => _sameWordBag(givenWords, _words(value)))) {
      return 'Die passenden Wörter sind da. Prüfe ihre Reihenfolge.';
    }

    return 'Noch nicht. Prüfe, ob du alle vorgegebenen Wörter '
        'vollständig und richtig verwendet hast.';
  }

  static String _spaces(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');

  static String _withoutEnding(String value) =>
      value.replaceFirst(RegExp(r'[.!?]+$'), '').trim();

  static List<String> _words(String value) => _withoutEnding(value)
      .toLowerCase()
      .split(' ')
      .where((word) => word.isNotEmpty)
      .toList(growable: false);

  static bool _sameWordBag(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final left = List<String>.from(a)..sort();
    final right = List<String>.from(b)..sort();
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}
