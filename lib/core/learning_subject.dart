enum LearningSubject { mathematics, german }

extension LearningSubjectX on LearningSubject {
  String get storageKey => switch (this) {
    LearningSubject.mathematics => 'math',
    LearningSubject.german => 'german',
  };

  String get label => switch (this) {
    LearningSubject.mathematics => 'Mathematik',
    LearningSubject.german => 'Deutsch',
  };

  String get shortLabel => switch (this) {
    LearningSubject.mathematics => 'Mathe',
    LearningSubject.german => 'Deutsch',
  };
}
