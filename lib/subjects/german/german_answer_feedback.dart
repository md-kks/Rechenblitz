import 'german_task.dart';

class GermanAnswerFeedback {
  const GermanAnswerFeedback._();

  static const retry = 'Noch nicht. Versuch es noch einmal.';

  static String forIncorrect(GermanTask task, String answer) {
    if (task.interaction != GermanTaskInteraction.typedText ||
        task.acceptedAnswers.isEmpty) {
      return retry;
    }

    final given = _spaces(answer);
    final expected = _spaces(task.acceptedAnswers.first);

    if (given.toLowerCase() == expected.toLowerCase()) {
      return 'Fast richtig. Prüfe die Groß- und Kleinschreibung.';
    }

    if (_withoutEnding(given).toLowerCase() ==
        _withoutEnding(expected).toLowerCase()) {
      return 'Fast richtig. Prüfe das Satzzeichen am Ende.';
    }

    final givenWords = _words(given);
    final expectedWords = _words(expected);
    if (_sameWordBag(givenWords, expectedWords)) {
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
