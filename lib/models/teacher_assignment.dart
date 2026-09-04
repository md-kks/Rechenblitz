import 'dart:convert';

import 'learning_methods.dart';
import 'micro_competency.dart';
import 'training.dart';

class TeacherAssignment {
  const TeacherAssignment({
    required this.gradeLevel,
    required this.numberRange,
    required this.mode,
    required this.tasks,
    required this.methods,
    this.targetCompetency,
    this.transferEmphasis = false,
  });

  static const prefix = 'RB1:';

  final GradeLevel gradeLevel;
  final NumberRangeLevel numberRange;
  final TrainingMode mode;
  final int tasks;
  final MicroCompetencyId? targetCompetency;
  final bool transferEmphasis;
  final MethodPreferences methods;

  Map<String, dynamic> toJson() => {
        'v': 1,
        'grade': gradeLevel.name,
        'range': numberRange.name,
        'mode': mode.name,
        'tasks': tasks,
        'target': targetCompetency?.name,
        'transfer': transferEmphasis,
        'methods': methods.toJson(),
      };

  String toPayload() {
    final raw = utf8.encode(jsonEncode(toJson()));
    return '$prefix${base64Url.encode(raw).replaceAll('=', '')}';
  }

  static TeacherAssignment? tryParse(String payload) {
    final clean = payload.trim();
    if (!clean.startsWith(prefix)) return null;
    try {
      var body = clean.substring(prefix.length);
      while (body.length % 4 != 0) {
        body += '=';
      }
      final decoded = jsonDecode(
        utf8.decode(base64Url.decode(body)),
      ) as Map<String, dynamic>;
      if (decoded['v'] != 1) return null;

      final grade = GradeLevel.values.byName(decoded['grade'] as String);
      final range =
          NumberRangeLevel.values.byName(decoded['range'] as String);
      final mode = TrainingMode.values.byName(decoded['mode'] as String);
      final tasks = (decoded['tasks'] as num).toInt();
      if (tasks < 1 || tasks > 30) return null;

      final rawTarget = decoded['target'] as String?;
      MicroCompetencyId? target;
      if (rawTarget != null) {
        target = MicroCompetencyId.values.byName(rawTarget);
      }

      return TeacherAssignment(
        gradeLevel: grade,
        numberRange: range,
        mode: mode,
        tasks: tasks,
        targetCompetency: target,
        transferEmphasis: decoded['transfer'] as bool? ?? false,
        methods: decoded['methods'] is Map<String, dynamic>
            ? MethodPreferences.fromJson(
                decoded['methods'] as Map<String, dynamic>,
              )
            : const MethodPreferences(),
      );
    } catch (_) {
      return null;
    }
  }

  String get summary {
    final target = targetCompetency == null
        ? mode.title
        : MicroCompetencyCatalog.definition(targetCompetency!).label;
    return '${gradeLevel.label} · ${numberRange.label} · $target · $tasks Aufgaben';
  }
}
