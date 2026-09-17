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

  Map<String, dynamic> toJson() => <String, dynamic>{
    'taskId': taskId,
    'competencyId': competencyId.name,
    'correctFirstTry': correctFirstTry,
    'incorrectAttempts': incorrectAttempts,
    'responseMs': responseMs,
  };

  factory GermanTaskResult.fromJson(Map<String, dynamic> json) =>
      GermanTaskResult(
        taskId: json['taskId'] as String,
        competencyId: GermanCompetencyId.values.byName(
          json['competencyId'] as String,
        ),
        correctFirstTry: json['correctFirstTry'] as bool,
        incorrectAttempts: (json['incorrectAttempts'] as num).toInt(),
        responseMs: (json['responseMs'] as num).toInt(),
      );
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

  Map<String, dynamic> toJson() => <String, dynamic>{
    'gradeLevel': gradeLevel.name,
    'startedAt': startedAt.toIso8601String(),
    'finishedAt': finishedAt.toIso8601String(),
    'taskResults': taskResults.map((result) => result.toJson()).toList(),
  };

  factory GermanSessionResult.fromJson(Map<String, dynamic> json) {
    final rawResults = json['taskResults'];
    if (rawResults is! List<dynamic>) {
      throw const FormatException('taskResults missing');
    }
    return GermanSessionResult(
      gradeLevel: GradeLevel.values.byName(json['gradeLevel'] as String),
      startedAt: DateTime.parse(json['startedAt'] as String),
      finishedAt: DateTime.parse(json['finishedAt'] as String),
      taskResults: rawResults
          .map(
            (value) => GermanTaskResult.fromJson(value as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }
}
