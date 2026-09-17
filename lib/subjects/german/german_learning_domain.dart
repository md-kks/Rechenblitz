enum GermanLearningDomain {
  reading,
  spelling,
  language,
  vocabulary,
  listening,
  writing,
}

extension GermanLearningDomainX on GermanLearningDomain {
  String get label => switch (this) {
    GermanLearningDomain.reading => 'Lesen',
    GermanLearningDomain.spelling => 'Rechtschreibung',
    GermanLearningDomain.language => 'Sprache untersuchen',
    GermanLearningDomain.vocabulary => 'Wörter & Wortschatz',
    GermanLearningDomain.listening => 'Sprechen & Zuhören',
    GermanLearningDomain.writing => 'Schreiben',
  };
}
