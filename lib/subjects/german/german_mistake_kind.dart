enum GermanMistakeKind {
  selectionMissing,
  selectionExtra,
  selectionSwap,
  selectionMixed,
  capitalization,
  endingPunctuation,
  punctuation,
  capitalizationAndPunctuation,
  wordOrder,
  spelling,
  missingWord,
  extraWord,
  wordRecognition,
  letterSound,
  listening,
  alphabeticalOrder,
  textSequence,
  wordBuilding,
  directSpeechPunctuation,
  sentenceConnection,
  textRevision,
}

extension GermanMistakeKindLabels on GermanMistakeKind {
  String get label => switch (this) {
    GermanMistakeKind.selectionMissing => 'passende Markierung fehlt',
    GermanMistakeKind.selectionExtra => 'Markierung zu viel',
    GermanMistakeKind.selectionSwap => 'eine Markierung verwechselt',
    GermanMistakeKind.selectionMixed => 'Markierungen noch nicht passend',
    GermanMistakeKind.capitalization => 'Groß- und Kleinschreibung',
    GermanMistakeKind.endingPunctuation => 'Satzzeichen am Ende',
    GermanMistakeKind.punctuation => 'Zeichensetzung',
    GermanMistakeKind.capitalizationAndPunctuation =>
      'Großschreibung und Zeichensetzung',
    GermanMistakeKind.wordOrder => 'Wort- oder Satzreihenfolge',
    GermanMistakeKind.spelling => 'Rechtschreibung eines Wortes',
    GermanMistakeKind.missingWord => 'ein Wort fehlt',
    GermanMistakeKind.extraWord => 'ein Wort zu viel',
    GermanMistakeKind.wordRecognition => 'ähnliche Wörter unterscheiden',
    GermanMistakeKind.letterSound => 'Anfangslaut und Buchstabe',
    GermanMistakeKind.listening => 'genaues Zuhören',
    GermanMistakeKind.alphabeticalOrder => 'alphabetische Reihenfolge',
    GermanMistakeKind.textSequence => 'Ablauf oder Textreihenfolge',
    GermanMistakeKind.wordBuilding => 'Wortbausteine',
    GermanMistakeKind.directSpeechPunctuation =>
      'Zeichensetzung der wörtlichen Rede',
    GermanMistakeKind.sentenceConnection => 'Sätze richtig verbinden',
    GermanMistakeKind.textRevision => 'Text gezielt überarbeiten',
  };

  String get tip => switch (this) {
    GermanMistakeKind.selectionMissing =>
      'Prüfe vor dem Abschicken, ob wirklich alle passenden Stellen markiert sind.',
    GermanMistakeKind.selectionExtra =>
      'Prüfe jede Markierung einzeln und entferne Stellen, die die Frage nicht beantworten.',
    GermanMistakeKind.selectionSwap =>
      'Vergleiche die beiden unsicheren Markierungen noch einmal direkt mit der Aufgabe.',
    GermanMistakeKind.selectionMixed =>
      'Gehe alle Markierungen einzeln durch: Was fehlt und was gehört nicht dazu?',
    GermanMistakeKind.capitalization =>
      'Lies den fertigen Satz noch einmal nur mit Blick auf Groß- und Kleinschreibung.',
    GermanMistakeKind.endingPunctuation =>
      'Prüfe am Satzende, ob Punkt, Fragezeichen oder Ausrufezeichen passt.',
    GermanMistakeKind.punctuation =>
      'Lies den Satz langsam und prüfe Kommas sowie Satzzeichen getrennt vom Wortlaut.',
    GermanMistakeKind.capitalizationAndPunctuation =>
      'Prüfe zuerst Großschreibung und danach in einem zweiten Durchgang die Satzzeichen.',
    GermanMistakeKind.wordOrder =>
      'Lies den Satz laut und prüfe besonders die Stellung des Verbs.',
    GermanMistakeKind.spelling =>
      'Sprich das unsichere Wort langsam und prüfe es Buchstabe für Buchstabe.',
    GermanMistakeKind.missingWord =>
      'Vergleiche den eigenen Satz Wort für Wort mit allen vorgegebenen Bausteinen.',
    GermanMistakeKind.extraWord =>
      'Prüfe, welches Wort im Satz keine Aufgabe erfüllt oder nicht vorgegeben war.',
    GermanMistakeKind.wordRecognition =>
      'Lies ähnliche Wörter vollständig von links nach rechts statt nur den Anfang anzusehen.',
    GermanMistakeKind.letterSound =>
      'Sprich das Wort langsam und halte den allerersten Laut kurz fest.',
    GermanMistakeKind.listening =>
      'Hör den Text noch einmal mit nur einer Frage im Kopf.',
    GermanMistakeKind.alphabeticalOrder =>
      'Vergleiche erst den ersten, dann den zweiten und erst danach weitere Buchstaben.',
    GermanMistakeKind.textSequence =>
      'Suche zuerst den möglichen Anfang und prüfe dann Schritt für Schritt, was folgen kann.',
    GermanMistakeKind.wordBuilding =>
      'Sprich das Zielwort langsam und setze die Bausteine in derselben Reihenfolge zusammen.',
    GermanMistakeKind.directSpeechPunctuation =>
      'Prüfe Begleitsatz, Anführungszeichen und Komma oder Doppelpunkt getrennt nacheinander.',
    GermanMistakeKind.sentenceConnection =>
      'Prüfe Verbindungswort, Satzstellung und Komma in drei getrennten Schritten.',
    GermanMistakeKind.textRevision =>
      'Ändere nur das verlangte Problem: Wiederholung, Wortwahl oder Reihenfolge.',
  };
}
