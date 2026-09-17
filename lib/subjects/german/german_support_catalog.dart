import 'german_competency.dart';

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

  static String secondHint(GermanCompetencyId id) => switch (id) {
    GermanCompetencyId.letterSoundMatch ||
    GermanCompetencyId.vowelConsonantRecognition ||
    GermanCompetencyId.syllableSegmentation ||
    GermanCompetencyId.wordRecognition =>
      'Sprich oder lies noch einmal langsam. Du musst nicht raten.',
    GermanCompetencyId.sentenceComprehension ||
    GermanCompetencyId.textInformation ||
    GermanCompetencyId.listeningComprehension ||
    GermanCompetencyId.conversationRules ||
    GermanCompetencyId.oralRetelling ||
    GermanCompetencyId.presentationStructure ||
    GermanCompetencyId.discussionReasoning =>
      'Hör den Beitrag noch einmal. Achte auf Reihenfolge, Gesprächsziel und einen passenden nächsten Satz.',
    GermanCompetencyId.sentenceWordOrder ||
    GermanCompetencyId.sentencePunctuation ||
    GermanCompetencyId.sentenceTypes ||
    GermanCompetencyId.sentenceWriting =>
      'Baue zuerst einen verständlichen Satz und prüfe danach seine Form.',
    _ =>
      'Prüfe jedes Wort einzeln und schließe Antworten aus, die nicht passen.',
  };
}
