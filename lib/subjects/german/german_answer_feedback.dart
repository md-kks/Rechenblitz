import 'german_competency.dart';
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
        if (task.competencyId == GermanCompetencyId.wordFamilies) {
          return 'Noch nicht. Prüfe bei jedem markierten Wort den Wortstamm. '
              'Es muss wirklich zur selben Wortfamilie gehören, nicht nur '
              'ähnlich klingen oder ähnlich aussehen.';
        }
        if (task.competencyId == GermanCompetencyId.sentenceConstituents) {
          return 'Noch nicht. Nutze die Frageprobe für jede Markierung: '
              'Passt der ganze Satzteil zur gesuchten Frage? Prüfe auch, ob '
              'noch ein zweites Satzglied fehlt.';
        }
        if (task.competencyId == GermanCompetencyId.sentencePunctuation ||
            task.competencyId == GermanCompetencyId.sentenceTypes) {
          return 'Noch nicht. Prüfe beides zusammen: Welche Satzart ist es '
              'und welches Satzzeichen passt genau dazu?';
        }
        if (task.competencyId == GermanCompetencyId.sentenceComprehension ||
            task.competencyId == GermanCompetencyId.textInformation ||
            task.competencyId == GermanCompetencyId.readingInference ||
            task.competencyId == GermanCompetencyId.textMainIdea) {
          return 'Noch nicht. Prüfe jede markierte Textstelle: Belegt sie die '
              'gesuchte Information wirklich? Vielleicht fehlt ein Hinweis '
              'oder eine Markierung ist zu viel.';
        }
        return 'Noch nicht. Prüfe jedes markierte Wort und überlege, ob noch '
            'etwas dazugehört oder eine Markierung zu viel ist.';
      case GermanTaskInteraction.wordOrder:
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
