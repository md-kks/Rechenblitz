import 'german_competency.dart';

class GermanFeedbackTipCatalog {
  const GermanFeedbackTipCatalog._();

  static String forCompetency(GermanCompetencyId id) => switch (id) {
    GermanCompetencyId.letterSoundMatch =>
      'Hör auf den ersten Laut und sprich das Wort langsam nach.',
    GermanCompetencyId.vowelConsonantRecognition =>
      'Sprich das Wort langsam und prüfe, ob der Laut ein Selbstlaut oder Mitlaut ist.',
    GermanCompetencyId.alphabeticalOrder =>
      'Vergleiche die Wörter Buchstabe für Buchstabe von links nach rechts.',
    GermanCompetencyId.syllableSegmentation =>
      'Sprich das Wort langsam und klatsche jeden hörbaren Sprechteil.',
    GermanCompetencyId.wordBuilding =>
      'Sprich das Wort langsam und setze die Bausteine in derselben Reihenfolge zusammen.',
    GermanCompetencyId.wordFamilies =>
      'Suche den gemeinsamen Wortstamm und denselben Bedeutungskern.',
    GermanCompetencyId.nounArticle =>
      'Prüfe, ob der, die oder das vor das Nomen passt.',
    GermanCompetencyId.singularPlural =>
      'Sprich Einzahl und Mehrzahl nacheinander und achte auf die Veränderung.',
    GermanCompetencyId.adjectiveRecognition =>
      'Frage dich: Wie ist jemand oder etwas?',
    GermanCompetencyId.verbRecognition =>
      'Frage dich: Was tut jemand oder was geschieht?',
    GermanCompetencyId.verbInflection =>
      'Passe die Verbform genau an die Person im Satz an.',
    GermanCompetencyId.sentenceWordOrder =>
      'Achte darauf, dass das Verb im Aussagesatz meist an zweiter Stelle steht.',
    GermanCompetencyId.sentencePunctuation =>
      'Lies den Satz mit passender Betonung und prüfe das Satzzeichen.',
    GermanCompetencyId.sentenceTypes =>
      'Entscheide zuerst: Aussage, Frage oder Aufforderung?',
    GermanCompetencyId.wordRecognition =>
      'Lies das Wort langsam von links nach rechts und beachte kleine Unterschiede.',
    GermanCompetencyId.sentenceComprehension =>
      'Suche die genaue Textstelle, die deine Antwort belegt.',
    GermanCompetencyId.textInformation =>
      'Suche nur die Information, nach der gefragt wird, und lass Nebendetails weg.',
    GermanCompetencyId.listeningComprehension =>
      'Hör den Text noch einmal mit der Frage im Kopf.',
    GermanCompetencyId.conversationRules =>
      'Lass andere ausreden, hör zu und antworte ruhig auf ihre Idee.',
    GermanCompetencyId.oralRetelling =>
      'Erzähle in der Reihenfolge zuerst, dann, danach und zum Schluss.',
    GermanCompetencyId.sentenceWriting =>
      'Prüfe: Wer tut was? Beginne groß und setze am Ende ein Satzzeichen.',
    GermanCompetencyId.spellingStrategies =>
      'Verlängere oder leite das Wort ab, wenn du einen Laut nicht sicher hörst.',
    GermanCompetencyId.dictionarySkills =>
      'Vergleiche die Wörter Buchstabe für Buchstabe bis zur ersten unterschiedlichen Stelle.',
    GermanCompetencyId.compoundWords =>
      'Finde zuerst das Grundwort am Ende und setze die genaueren Wortteile davor.',
    GermanCompetencyId.subjectPredicate =>
      'Frage zuerst Wer oder was? und markiere danach alle Teile des Prädikats.',
    GermanCompetencyId.sentenceConstituents =>
      'Nutze Frageprobe und Verschiebeprobe, damit ein Satzglied zusammenbleibt.',
    GermanCompetencyId.verbTenses =>
      'Prüfe Grundform, Zeitform und alle Teile des Verbs gemeinsam.',
    GermanCompetencyId.readingInference =>
      'Markiere alle Textstellen, die deine Schlussfolgerung wirklich belegen.',
    GermanCompetencyId.textSequence =>
      'Achte auf Signalwörter und ordne Anfang, nächste Schritte und Schluss.',
    GermanCompetencyId.textMainIdea =>
      'Frage dich, was im ganzen Text wichtig ist und was nur ein Detail ist.',
    GermanCompetencyId.sentenceConnections =>
      'Prüfe Verbindungswort, Satzstellung und Komma zusammen.',
    GermanCompetencyId.textRevision =>
      'Verbessere gezielt Wiederholungen, Wortwahl oder Reihenfolge.',
    GermanCompetencyId.listeningMainIdeas =>
      'Hör auf die wichtigsten Aussagen und lass einzelne Nebendetails weg.',
    GermanCompetencyId.presentationStructure =>
      'Ordne deinen Vortrag in Einstieg, Hauptteil und einen klaren Schluss.',
    GermanCompetencyId.discussionReasoning =>
      'Nenne deine Meinung und stütze sie mit passenden Gründen.',
    GermanCompetencyId.directSpeechPunctuation =>
      'Prüfe Begleitsatz, Anführungszeichen und Doppelpunkt oder Komma zusammen.',
  };
}
