import '../../core/grade_level.dart';
import 'german_session.dart';
import 'german_task.dart';
import 'german_task_catalog.dart';

class GermanRoundDraft {
  const GermanRoundDraft({
    required this.gradeLevel,
    required this.taskIds,
    required this.currentIndex,
    required this.startedAt,
    required this.updatedAt,
    required this.completedResults,
    this.incorrectAttempts = 0,
    this.assignmentPayload,
    this.sessionKind = GermanSessionKind.practice,
  });

  static const maxAge = Duration(days: 7);

  final GradeLevel gradeLevel;
  final List<String> taskIds;
  final int currentIndex;
  final DateTime startedAt;
  final DateTime updatedAt;
  final List<GermanTaskResult> completedResults;
  final int incorrectAttempts;
  final String? assignmentPayload;
  final GermanSessionKind sessionKind;

  int get totalTasks => taskIds.length;
  int get nextTaskNumber => currentIndex + 1;

  bool isResumableFor(GradeLevel grade, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    if (gradeLevel != grade || taskIds.isEmpty) return false;
    if (currentIndex < 0 || currentIndex >= taskIds.length) return false;
    if (completedResults.length != currentIndex) return false;
    if (incorrectAttempts < 0) return false;
    if (reference.difference(updatedAt) > maxAge) return false;
    return resolveTasks() != null;
  }

  List<GermanTask>? resolveTasks() {
    final byId = <String, GermanTask>{
      for (final task in GermanTaskCatalog.tasks) task.id: task,
    };
    final resolved = <GermanTask>[];
    for (final id in taskIds) {
      final task = byId[id];
      if (task == null || task.recommendedFromGrade.index > gradeLevel.index) {
        return null;
      }
      resolved.add(task);
    }
    return resolved;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'v': 1,
    'gradeLevel': gradeLevel.name,
    'taskIds': taskIds,
    'currentIndex': currentIndex,
    'startedAt': startedAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'completedResults': completedResults
        .map((value) => value.toJson())
        .toList(),
    'incorrectAttempts': incorrectAttempts,
    'assignmentPayload': assignmentPayload,
    'sessionKind': sessionKind.name,
  };

  factory GermanRoundDraft.fromJson(Map<String, dynamic> json) {
    if (json['v'] != 1) throw const FormatException('unsupported draft');
    final rawIds = json['taskIds'];
    final rawResults = json['completedResults'];
    if (rawIds is! List<dynamic> || rawResults is! List<dynamic>) {
      throw const FormatException('draft content missing');
    }
    return GermanRoundDraft(
      gradeLevel: GradeLevel.values.byName(json['gradeLevel'] as String),
      taskIds: rawIds.cast<String>().toList(growable: false),
      currentIndex: (json['currentIndex'] as num).toInt(),
      startedAt: DateTime.parse(json['startedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      completedResults: rawResults
          .map(
            (value) => GermanTaskResult.fromJson(value as Map<String, dynamic>),
          )
          .toList(growable: false),
      incorrectAttempts: (json['incorrectAttempts'] as num?)?.toInt() ?? 0,
      assignmentPayload: json['assignmentPayload'] as String?,
      sessionKind: _parseSessionKind(json['sessionKind']),
    );
  }

  static GermanSessionKind _parseSessionKind(Object? raw) {
    if (raw is String) {
      for (final value in GermanSessionKind.values) {
        if (value.name == raw) return value;
      }
    }
    return GermanSessionKind.practice;
  }
}
