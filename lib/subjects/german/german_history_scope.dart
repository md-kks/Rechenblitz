import '../../core/grade_level.dart';
import 'german_session.dart';

class GermanHistoryScope {
  const GermanHistoryScope._();

  static List<GermanSessionResult> unique(
    Iterable<GermanSessionResult> history,
  ) {
    final seen = <String>{};
    final values = <GermanSessionResult>[];
    for (final session in history) {
      if (seen.add(session.evidenceIdentity)) values.add(session);
    }
    return values;
  }

  static List<GermanSessionResult> throughGrade(
    Iterable<GermanSessionResult> history,
    GradeLevel gradeLevel,
  ) => unique(
    history.where((session) => session.gradeLevel.index <= gradeLevel.index),
  );
}
