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
    GermanCompetencyId.sentenceWriting =>
      'Beginne groß, ordne die Wörter sinnvoll und denke an das Satzzeichen.',
  };

  static String secondHint(GermanCompetencyId id) => switch (id) {
    GermanCompetencyId.letterSoundMatch ||
    GermanCompetencyId.vowelConsonantRecognition ||
    GermanCompetencyId.syllableSegmentation ||
    GermanCompetencyId.wordRecognition =>
      'Sprich oder lies noch einmal langsam. Du musst nicht raten.',
    GermanCompetencyId.sentenceComprehension ||
    GermanCompetencyId.textInformation ||
    GermanCompetencyId.listeningComprehension =>
      'Konzentriere dich nur auf die Information, nach der gefragt wird.',
    GermanCompetencyId.sentenceWordOrder ||
    GermanCompetencyId.sentencePunctuation ||
    GermanCompetencyId.sentenceTypes ||
    GermanCompetencyId.sentenceWriting =>
      'Baue zuerst einen verständlichen Satz und prüfe danach seine Form.',
    _ =>
      'Prüfe jedes Wort einzeln und schließe Antworten aus, die nicht passen.',
  };
}
