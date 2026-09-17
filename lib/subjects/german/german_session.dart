import '../../core/grade_level.dart';
import 'german_competency.dart';

class GermanTaskResult {
  const GermanTaskResult({
    required this.taskId,
    required this.competencyId,
    required this.correctFirstTry,
    required this.incorrectAttempts,
    required this.responseMs,
  });

  final String taskId;
  final GermanCompetencyId competencyId;
  final bool correctFirstTry;
  final int incorrectAttempts;
  final int responseMs;
}

class GermanSessionResult {
  const GermanSessionResult({
    required this.gradeLevel,
    required this.startedAt,
    required this.finishedAt,
    required this.taskResults,
  });

  final GradeLevel gradeLevel;
  final DateTime startedAt;
  final DateTime finishedAt;
  final List<GermanTaskResult> taskResults;

  int get total => taskResults.length;

  int get correctFirstTry =>
      taskResults.where((result) => result.correctFirstTry).length;

  int get incorrectAttempts =>
      taskResults.fold<int>(0, (sum, result) => sum + result.incorrectAttempts);

  double get accuracy => total == 0 ? 0 : correctFirstTry / total;

  double get averageResponseMs => total == 0
      ? 0
      : taskResults.fold<int>(0, (sum, result) => sum + result.responseMs) /
            total;
}
