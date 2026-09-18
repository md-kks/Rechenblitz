import '../../core/grade_level.dart';
import 'german_session.dart';

class GermanHistoryScope {
  const GermanHistoryScope._();

  static List<GermanSessionResult> throughGrade(
    Iterable<GermanSessionResult> history,
    GradeLevel gradeLevel,
  ) => history
      .where((session) => session.gradeLevel.index <= gradeLevel.index)
      .toList(growable: false);
}
