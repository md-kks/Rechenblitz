enum GradeLevel { first, second, third, fourth }

extension GradeLevelX on GradeLevel {
  int get number => index + 1;

  String get label => 'Klasse $number';

  String get shortLabel => '$number';
}
