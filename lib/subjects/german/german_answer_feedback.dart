import 'german_competency.dart';
import 'german_mistake_kind.dart';
import 'german_task.dart';

class GermanAnswerFeedback {
  const GermanAnswerFeedback._();

  static const retry = 'Noch nicht. Versuch es noch einmal.';

  static String forIncorrect(GermanTask task, String answer) {
    if (task.acceptedAnswers.isEmpty) return retry;

    switch (task.interaction) {
      case GermanTaskInteraction.singleChoice:
        if (task.competencyId == GermanCompetencyId.wordRecognition) {
          return 'Noch nicht. Lies die Wörter langsam von links nach rechts. '
              'Achte besonders auf die Stelle, an der sie sich unterscheiden.';
        }
        return 'Noch nicht. Vergleiche deine Auswahl noch einmal genau mit '
            'der Aufgabe.';
      case GermanTaskInteraction.listeningChoice:
        if (task.competencyId == GermanCompetencyId.letterSoundMatch) {
          return 'Noch nicht. Hör das Wort noch einmal und sprich es langsam '
              'nach. Welchen Laut hörst du ganz am Anfang?';
        }
        return 'Noch nicht. Hör die Aufgabe noch einmal an und achte nur auf '
            'die gesuchte Information.';
      case GermanTaskInteraction.tokenSelection:
        final diagnostic = _tokenSelectionDiagnostic(task, answer);
        final guidance = _tokenSelectionGuidance(task);
        return diagnostic == null ? guidance : '$diagnostic $guidance';
      case GermanTaskInteraction.wordOrder:
        if (task.requiresSpeech) {
          return 'Noch nicht. Hör den Ablauf noch einmal und achte auf '
              'Signalwörter wie zuerst, danach und zuletzt.';
        }
        if (task.competencyId == GermanCompetencyId.alphabeticalOrder ||
            task.competencyId == GermanCompetencyId.dictionarySkills) {
          return 'Noch nicht alphabetisch. Vergleiche die Wörter noch einmal '
              'Buchstabe für Buchstabe.';
        }
        if (task.competencyId == GermanCompetencyId.textSequence) {
          return 'Noch nicht. Prüfe, welcher Schritt zuerst möglich ist und '
              'was jeweils danach folgen muss.';
        }
        return 'Alle Satzbausteine sind da. Prüfe noch einmal ihre '
            'Reihenfolge.';
      case GermanTaskInteraction.wordBuilder:
        if (task.competencyId == GermanCompetencyId.directSpeechPunctuation) {
          return 'Noch nicht. Prüfe Begleitsatz, Doppelpunkt oder Komma sowie '
              'Anführungszeichen und Satzzeichen der wörtlichen Rede.';
        }
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

    final punctuationMatch = expected.where(
      (value) =>
          _withoutPunctuation(given).toLowerCase() ==
          _withoutPunctuation(value).toLowerCase(),
    );
    if (punctuationMatch.isNotEmpty) {
      final sameCase = punctuationMatch.any(
        (value) => _withoutPunctuation(given) == _withoutPunctuation(value),
      );
      return sameCase
          ? 'Fast richtig. Prüfe die Zeichensetzung, besonders Kommas und Satzzeichen.'
          : 'Fast richtig. Prüfe die Groß- und Kleinschreibung sowie die Zeichensetzung.';
    }

    final givenWords = _words(given);
    if (expected.any((value) => _sameWordBag(givenWords, _words(value)))) {
      return 'Die passenden Wörter sind da. Prüfe ihre Reihenfolge.';
    }

    if (task.competencyId == GermanCompetencyId.sentenceWriting) {
      final diagnostic = _sentenceWritingDiagnostic(given, expected);
      if (diagnostic != null) return diagnostic;
    }

    if (task.competencyId == GermanCompetencyId.sentenceConnections) {
      return 'Noch nicht. Prüfe das verlangte Verbindungswort, die Satzstellung '
          'und das Komma. Beide Aussagen müssen vollständig erhalten bleiben.';
    }
    if (task.competencyId == GermanCompetencyId.textRevision) {
      return 'Noch nicht. Prüfe genau die verlangte Überarbeitung: '
          'Wiederholung, Wortwahl oder Reihenfolge soll gezielt verbessert werden.';
    }
    return 'Noch nicht. Prüfe, ob du alle vorgegebenen Wörter '
        'vollständig und richtig verwendet hast.';
  }

  static GermanMistakeKind? kindForIncorrect(GermanTask task, String answer) {
    if (task.acceptedAnswers.isEmpty) return null;
    switch (task.interaction) {
      case GermanTaskInteraction.singleChoice:
        return task.competencyId == GermanCompetencyId.wordRecognition
            ? GermanMistakeKind.wordRecognition
            : null;
      case GermanTaskInteraction.listeningChoice:
        return task.competencyId == GermanCompetencyId.letterSoundMatch
            ? GermanMistakeKind.letterSound
            : GermanMistakeKind.listening;
      case GermanTaskInteraction.tokenSelection:
        final selected = answer
            .split('·')
            .map(_spaces)
            .where((value) => value.isNotEmpty)
            .map((value) => value.toLowerCase())
            .toSet();
        final expected = task.acceptedAnswers
            .map(_spaces)
            .map((value) => value.toLowerCase())
            .toSet();
        if (selected.isEmpty || selected == expected) return null;
        final missing = expected.difference(selected).length;
        final extra = selected.difference(expected).length;
        if (missing > 0 && extra == 0) {
          return GermanMistakeKind.selectionMissing;
        }
        if (missing == 0 && extra > 0) {
          return GermanMistakeKind.selectionExtra;
        }
        if (missing == 1 && extra == 1) {
          return GermanMistakeKind.selectionSwap;
        }
        return GermanMistakeKind.selectionMixed;
      case GermanTaskInteraction.wordOrder:
        if (task.requiresSpeech) return GermanMistakeKind.textSequence;
        if (task.competencyId == GermanCompetencyId.alphabeticalOrder ||
            task.competencyId == GermanCompetencyId.dictionarySkills) {
          return GermanMistakeKind.alphabeticalOrder;
        }
        if (task.competencyId == GermanCompetencyId.textSequence) {
          return GermanMistakeKind.textSequence;
        }
        return GermanMistakeKind.wordOrder;
      case GermanTaskInteraction.wordBuilder:
        return task.competencyId == GermanCompetencyId.directSpeechPunctuation
            ? GermanMistakeKind.directSpeechPunctuation
            : GermanMistakeKind.wordBuilding;
      case GermanTaskInteraction.typedText:
        break;
    }

    final given = _spaces(answer);
    final expected = task.acceptedAnswers.map(_spaces).toList(growable: false);
    if (expected.any((value) => given.toLowerCase() == value.toLowerCase())) {
      return GermanMistakeKind.capitalization;
    }
    if (expected.any(
      (value) =>
          _withoutEnding(given).toLowerCase() ==
          _withoutEnding(value).toLowerCase(),
    )) {
      return GermanMistakeKind.endingPunctuation;
    }
    final punctuationMatch = expected.where(
      (value) =>
          _withoutPunctuation(given).toLowerCase() ==
          _withoutPunctuation(value).toLowerCase(),
    );
    if (punctuationMatch.isNotEmpty) {
      final sameCase = punctuationMatch.any(
        (value) => _withoutPunctuation(given) == _withoutPunctuation(value),
      );
      return sameCase
          ? GermanMistakeKind.punctuation
          : GermanMistakeKind.capitalizationAndPunctuation;
    }

    final givenWords = _words(given);
    if (expected.any((value) => _sameWordBag(givenWords, _words(value)))) {
      return GermanMistakeKind.wordOrder;
    }
    if (task.competencyId == GermanCompetencyId.sentenceWriting) {
      final kind = _sentenceWritingMistakeKind(given, expected);
      if (kind != null) return kind;
    }
    if (task.competencyId == GermanCompetencyId.sentenceConnections) {
      return GermanMistakeKind.sentenceConnection;
    }
    if (task.competencyId == GermanCompetencyId.textRevision) {
      return GermanMistakeKind.textRevision;
    }
    return null;
  }

  static String? _tokenSelectionDiagnostic(GermanTask task, String answer) {
    final selected = answer
        .split('·')
        .map(_spaces)
        .where((value) => value.isNotEmpty)
        .map((value) => value.toLowerCase())
        .toSet();
    if (selected.isEmpty) return null;

    final expected = task.acceptedAnswers
        .map(_spaces)
        .map((value) => value.toLowerCase())
        .toSet();
    final missing = expected.difference(selected).length;
    final extra = selected.difference(expected).length;
    if (missing == 0 && extra == 0) return null;

    if (extra == 0) {
      return missing == 1
          ? 'Fast richtig. Eine passende Markierung fehlt noch.'
          : 'Fast richtig. $missing passende Markierungen fehlen noch.';
    }
    if (missing == 0) {
      return extra == 1
          ? 'Fast richtig. Eine Markierung ist zu viel.'
          : 'Fast richtig. $extra Markierungen sind zu viel.';
    }
    if (missing == 1 && extra == 1) {
      return 'Fast richtig. Eine Markierung passt noch nicht; tausche genau eine aus.';
    }
    return 'Noch nicht. $missing passende Markierungen fehlen und $extra sind zu viel.';
  }

  static String _tokenSelectionGuidance(GermanTask task) {
    if (task.requiresSpeech) {
      return 'Hör den Text noch einmal und prüfe jede Markierung: Wurde diese '
          'Information wirklich gesagt und fehlt noch eine wichtige Aussage?';
    }
    if (task.competencyId == GermanCompetencyId.wordFamilies) {
      return 'Prüfe bei jedem markierten Wort den Wortstamm. Es muss wirklich '
          'zur selben Wortfamilie gehören, nicht nur ähnlich klingen oder '
          'ähnlich aussehen.';
    }
    if (task.competencyId == GermanCompetencyId.subjectPredicate) {
      return 'Finde zuerst mit „Wer oder was?“ das Subjekt. Prüfe danach alle '
          'Verbteile des Prädikats – sie können im Satz getrennt stehen.';
    }
    if (task.competencyId == GermanCompetencyId.sentenceConstituents) {
      return 'Nutze die Frageprobe für jede Markierung: Passt der ganze Satzteil '
          'zur gesuchten Frage? Prüfe auch, ob noch ein zweites Satzglied fehlt.';
    }
    if (task.competencyId == GermanCompetencyId.sentencePunctuation ||
        task.competencyId == GermanCompetencyId.sentenceTypes) {
      return 'Prüfe beides zusammen: Welche Satzart ist es und welches '
          'Satzzeichen passt genau dazu?';
    }
    if (task.competencyId == GermanCompetencyId.sentenceComprehension ||
        task.competencyId == GermanCompetencyId.textInformation ||
        task.competencyId == GermanCompetencyId.readingInference ||
        task.competencyId == GermanCompetencyId.textMainIdea) {
      return 'Prüfe jede markierte Textstelle: Belegt sie die gesuchte '
          'Information wirklich?';
    }
    return 'Prüfe jedes markierte Wort und überlege, ob noch etwas dazugehört '
        'oder eine Markierung zu viel ist.';
  }

  static GermanMistakeKind? _sentenceWritingMistakeKind(
    String given,
    List<String> expected,
  ) {
    final givenWords = _plainWords(given);
    for (final value in expected) {
      final expectedWords = _plainWords(value);
      if (givenWords.length == expectedWords.length) {
        final differences = <int>[];
        for (var index = 0; index < givenWords.length; index++) {
          if (givenWords[index] != expectedWords[index]) differences.add(index);
        }
        if (differences.length == 1) {
          final index = differences.single;
          if (_editDistance(givenWords[index], expectedWords[index]) <= 2) {
            return GermanMistakeKind.spelling;
          }
        }
      }
      if (expectedWords.length == givenWords.length + 1 &&
          _isSubsequence(givenWords, expectedWords)) {
        return GermanMistakeKind.missingWord;
      }
      if (givenWords.length == expectedWords.length + 1 &&
          _isSubsequence(expectedWords, givenWords)) {
        return GermanMistakeKind.extraWord;
      }
    }
    return null;
  }

  static String? _sentenceWritingDiagnostic(
    String given,
    List<String> expected,
  ) {
    final givenWords = _plainWords(given);
    for (final value in expected) {
      final expectedWords = _plainWords(value);
      if (givenWords.length == expectedWords.length) {
        final differences = <int>[];
        for (var index = 0; index < givenWords.length; index++) {
          if (givenWords[index] != expectedWords[index]) differences.add(index);
        }
        if (differences.length == 1) {
          final index = differences.single;
          if (_editDistance(givenWords[index], expectedWords[index]) <= 2) {
            return 'Fast richtig. Ein Wort ist noch nicht richtig geschrieben.';
          }
        }
      }
      if (expectedWords.length == givenWords.length + 1 &&
          _isSubsequence(givenWords, expectedWords)) {
        return 'Fast richtig. Ein Wort fehlt noch.';
      }
      if (givenWords.length == expectedWords.length + 1 &&
          _isSubsequence(expectedWords, givenWords)) {
        return 'Fast richtig. Ein Wort ist zu viel.';
      }
    }
    return null;
  }

  static String _spaces(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');

  static String _withoutPunctuation(String value) =>
      _spaces(value.replaceAll(RegExp(r'[.,!?;:„“"‚‘’]'), ' '));

  static List<String> _plainWords(String value) => _withoutPunctuation(value)
      .toLowerCase()
      .split(' ')
      .where((word) => word.isNotEmpty)
      .toList(growable: false);

  static bool _isSubsequence(List<String> shorter, List<String> longer) {
    if (shorter.length > longer.length) return false;
    var index = 0;
    for (final word in longer) {
      if (index < shorter.length && shorter[index] == word) index += 1;
    }
    return index == shorter.length;
  }

  static int _editDistance(String a, String b) {
    var previous = List<int>.generate(b.length + 1, (index) => index);
    for (var row = 1; row <= a.length; row++) {
      final current = List<int>.filled(b.length + 1, 0)..[0] = row;
      for (var column = 1; column <= b.length; column++) {
        final substitution =
            previous[column - 1] +
            (a.codeUnitAt(row - 1) == b.codeUnitAt(column - 1) ? 0 : 1);
        final insertion = current[column - 1] + 1;
        final deletion = previous[column] + 1;
        current[column] = substitution < insertion
            ? (substitution < deletion ? substitution : deletion)
            : (insertion < deletion ? insertion : deletion);
      }
      previous = current;
    }
    return previous[b.length];
  }

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
