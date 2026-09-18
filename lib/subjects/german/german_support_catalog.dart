import 'german_competency.dart';
import 'german_task.dart';

class GermanSupportCatalog {
  const GermanSupportCatalog._();

  static String firstHint(GermanCompetencyId id) => switch (id) {
    GermanCompetencyId.letterSoundMatch =>
      'Sprich den Laut langsam. Welcher Buchstabe klingt genauso?',
    GermanCompetencyId.vowelConsonantRecognition =>
      'Selbstlaute kannst du lang sprechen: a, e, i, o, u.',
    GermanCompetencyId.alphabeticalOrder =>
      'Vergleiche zuerst den ersten Buchstaben der Wörter.',
    GermanCompetencyId.syllableSegmentation =>
      'Sprich das Wort langsam und klatsche bei jeder Sprechsilbe.',
    GermanCompetencyId.wordBuilding =>
      'Sprich die Teile nacheinander und ziehe sie dann zusammen.',
    GermanCompetencyId.wordFamilies =>
      'Suche den Wortstamm, der in beiden Wörtern wiederkommt.',
    GermanCompetencyId.nounArticle =>
      'Probiere der, die und das vor dem Nomen. Was klingt richtig?',
    GermanCompetencyId.singularPlural =>
      'Sag zuerst „ein …“ und dann „viele …“.',
    GermanCompetencyId.adjectiveRecognition =>
      'Frage: Wie ist etwas? Das beschreibende Wort ist das Adjektiv.',
    GermanCompetencyId.verbRecognition =>
      'Frage: Was tut jemand? Das Tätigkeitswort ist das Verb.',
    GermanCompetencyId.verbInflection =>
      'Schau zuerst, wer handelt. Passe die Verbform an diese Person an.',
    GermanCompetencyId.sentenceWordOrder =>
      'Beginne mit der Person oder Sache und frage dann: Was passiert?',
    GermanCompetencyId.sentencePunctuation =>
      'Überlege: Ist der Satz eine Aussage, eine Frage oder ein Ausruf?',
    GermanCompetencyId.sentenceTypes =>
      'Achte darauf, ob etwas gesagt, gefragt oder verlangt wird.',
    GermanCompetencyId.wordRecognition =>
      'Lies das Wort in kleinen Teilen oder Silben und füge sie zusammen.',
    GermanCompetencyId.sentenceComprehension =>
      'Suche zuerst: Wer kommt im Satz vor? Was tut diese Person oder Sache?',
    GermanCompetencyId.textInformation =>
      'Lies die Frage zuerst und suche dann genau die passende Textstelle.',
    GermanCompetencyId.listeningComprehension =>
      'Hör noch einmal und achte nur auf das gesuchte Schlüsselwort.',
    GermanCompetencyId.conversationRules =>
      'Überlege: Wer spricht gerade, und wie kannst du zeigen, dass du zuhörst?',
    GermanCompetencyId.oralRetelling =>
      'Suche zuerst Anfang, wichtiges Ereignis und Schluss der Geschichte.',
    GermanCompetencyId.sentenceWriting =>
      'Beginne groß, ordne die Wörter sinnvoll und denke an das Satzzeichen.',
    GermanCompetencyId.spellingStrategies =>
      'Prüfe das Wort: Kannst du es verlängern oder ein verwandtes Wort finden?',
    GermanCompetencyId.dictionarySkills =>
      'Suche nach der Grundform und vergleiche die Buchstaben von links nach rechts.',
    GermanCompetencyId.compoundWords =>
      'Zerlege das lange Wort in bekannte Wörter und prüfe ihre Bedeutung.',
    GermanCompetencyId.subjectPredicate =>
      'Frage zuerst „Wer oder was?“ und suche danach das Verb als Prädikat.',
    GermanCompetencyId.sentenceConstituents =>
      'Nutze eine W-Frage und verschiebe den ganzen Satzteil probeweise.',
    GermanCompetencyId.verbTenses =>
      'Achte auf Zeitwörter wie heute oder gestern und passe die Verbform an.',
    GermanCompetencyId.readingInference =>
      'Suche mehrere Hinweise im Text. Die Antwort muss zu allen Hinweisen passen.',
    GermanCompetencyId.textSequence =>
      'Achte auf Wörter wie zuerst, danach, anschließend und zum Schluss.',
    GermanCompetencyId.textMainIdea =>
      'Frage dich: Welche Aussage fasst den ganzen Text zusammen, nicht nur ein Detail?',
    GermanCompetencyId.sentenceConnections =>
      'Prüfe die Beziehung: Grund, Folge, Gegensatz oder zeitliche Reihenfolge?',
    GermanCompetencyId.textRevision =>
      'Lies den Text noch einmal und prüfe Reihenfolge, Wiederholungen und genaue Wörter.',
    GermanCompetencyId.listeningMainIdeas =>
      'Hör auf das Thema und die wichtigste Botschaft statt auf einzelne Nebendetails.',
    GermanCompetencyId.presentationStructure =>
      'Plane einen klaren Anfang, wenige wichtige Punkte und einen kurzen Abschluss.',
    GermanCompetencyId.discussionReasoning =>
      'Greife den Beitrag auf und nenne einen verständlichen Grund für deine Meinung.',
    GermanCompetencyId.directSpeechPunctuation =>
      'Trenne Begleitsatz und wörtliche Rede und prüfe Doppelpunkt, Anführungszeichen und Satzzeichen.',
  };

  static String firstHintForTask(GermanTask task) {
    if (task.interaction == GermanTaskInteraction.wordOrder &&
        task.instruction.toLowerCase().contains('beginnt')) {
      return 'Nutze zuerst den vorgegebenen Satzanfang. Im Aussagesatz steht '
          'das gebeugte Verb meist an zweiter Stelle.';
    }
    return firstHint(task.competencyId);
  }

  static String secondHintForTask(GermanTask task) {
    if (task.interaction == GermanTaskInteraction.wordOrder) {
      if (task.instruction.toLowerCase().contains('beginnt')) {
        return 'Lass den vorgegebenen Anfang stehen. Setze danach das Verb '
            'an die zweite Stelle. Bei trennbaren Verben kann ein Teil wie '
            '„auf“ oder „vor“ am Satzende stehen.';
      }
      return 'Suche zuerst Wer oder was handelt. Danach kommt im einfachen '
          'Aussagesatz meist das Verb. Ergänze dann die übrigen Wörter.';
    }
    return secondHint(task.competencyId);
  }

  static String secondHint(GermanCompetencyId id) => switch (id) {
    GermanCompetencyId.letterSoundMatch ||
    GermanCompetencyId.vowelConsonantRecognition ||
    GermanCompetencyId.syllableSegmentation ||
    GermanCompetencyId.wordRecognition =>
      'Sprich oder lies noch einmal langsam. Du musst nicht raten.',
    GermanCompetencyId.alphabeticalOrder ||
    GermanCompetencyId.dictionarySkills =>
      'Vergleiche die Wörter Buchstabe für Buchstabe von links nach rechts.',
    GermanCompetencyId.wordBuilding ||
    GermanCompetencyId.wordFamilies ||
    GermanCompetencyId.compoundWords =>
      'Markiere den Wortstamm oder die einzelnen Wortteile. Prüfe dann, '
          'welche Teile wirklich zusammengehören.',
    GermanCompetencyId.nounArticle ||
    GermanCompetencyId.singularPlural ||
    GermanCompetencyId.adjectiveRecognition ||
    GermanCompetencyId.verbRecognition ||
    GermanCompetencyId.verbInflection =>
      'Bestimme zuerst die Aufgabe des Wortes im Satz und prüfe danach seine '
          'passende Form.',
    GermanCompetencyId.sentenceWordOrder ||
    GermanCompetencyId.sentencePunctuation ||
    GermanCompetencyId.sentenceTypes ||
    GermanCompetencyId.sentenceWriting =>
      'Baue zuerst einen verständlichen Satz und prüfe danach Reihenfolge, '
          'Großschreibung und Satzzeichen.',
    GermanCompetencyId.sentenceComprehension ||
    GermanCompetencyId.textInformation =>
      'Lies die Frage noch einmal und markiere im Satz oder Text genau die '
          'Stelle, die deine Antwort belegt.',
    GermanCompetencyId.readingInference =>
      'Suche mindestens zwei Hinweise im Text. Deine Antwort muss zu beiden '
          'passen, auch wenn sie nicht wörtlich dasteht.',
    GermanCompetencyId.textSequence =>
      'Ordne zuerst Anfang und Schluss. Setze danach die Zwischenschritte '
          'mithilfe von Zeit- und Reihenfolgewörtern ein.',
    GermanCompetencyId.textMainIdea =>
      'Streiche Antworten, die nur ein Detail nennen. Gesucht ist die '
          'Aussage, die möglichst viel vom ganzen Text erklärt.',
    GermanCompetencyId.listeningComprehension ||
    GermanCompetencyId.listeningMainIdeas =>
      'Hör noch einmal. Konzentriere dich diesmal nur auf die Frage und die '
          'wichtigste Aussage, nicht auf jedes Detail.',
    GermanCompetencyId.conversationRules ||
    GermanCompetencyId.discussionReasoning =>
      'Hör auf den letzten Beitrag. Deine Antwort soll dazu passen und einen '
          'verständlichen Grund oder Anschluss enthalten.',
    GermanCompetencyId.oralRetelling =>
      'Hör noch einmal und merke dir nur drei Punkte: Anfang, wichtigstes '
          'Ereignis und Ende.',
    GermanCompetencyId.presentationStructure =>
      'Prüfe die Reihenfolge: kurze Einleitung, wichtige Punkte in sinnvoller '
          'Ordnung und ein klarer Abschluss.',
    GermanCompetencyId.spellingStrategies =>
      'Probiere gezielt eine Strategie: verlängern, ableiten oder ein '
          'verwandtes Wort suchen.',
    GermanCompetencyId.subjectPredicate =>
      'Finde zuerst mit „Wer oder was?“ das Subjekt. Suche dann alle Teile '
          'des Prädikats, auch einen abgetrennten Verbteil.',
    GermanCompetencyId.sentenceConstituents =>
      'Stelle die passende W-Frage und verschiebe den vermuteten Satzteil '
          'als ganzen Block.',
    GermanCompetencyId.verbTenses =>
      'Suche das Zeitwort und prüfe Hilfsverb und Verbform gemeinsam.',
    GermanCompetencyId.sentenceConnections =>
      'Entscheide zuerst: Grund, Folge oder Gegensatz? Wähle danach ein '
          'Verbindungswort, das genau diese Beziehung ausdrückt.',
    GermanCompetencyId.textRevision =>
      'Überarbeite nur eine Sache nach der anderen: zuerst Reihenfolge, dann '
          'Wiederholungen, danach genaue Wörter.',
    GermanCompetencyId.directSpeechPunctuation =>
      'Finde zuerst Begleitsatz und wörtliche Rede. Setze dann Doppelpunkt, '
          'Anführungszeichen und das Satzzeichen der Rede.',
  };
}
