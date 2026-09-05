import 'package:flutter/material.dart';

import '../models/teacher_assignment.dart';
import '../models/teacher_assignment_result.dart';
import '../models/training.dart';
import '../screens/assignment_result_screen.dart';
import '../screens/curriculum_training_screen.dart';
import '../screens/structured_training_screen.dart';
import '../screens/training_screen.dart';
import 'app_controller.dart';

Future<void> launchTeacherAssignment(
  BuildContext context,
  AppController controller,
  TeacherAssignment assignment,
) async {
  if (assignment.gradeLevel != controller.gradeLevel) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Dieser Auftrag ist für ${assignment.gradeLevel.label}. '
            'Das aktive Profil ist ${controller.gradeLevel.label}.',
          ),
        ),
      );
    }
    return;
  }

  final startedAt = DateTime.now();
  controller.beginTeacherAssignment(assignment);

  try {
    await _openAssignmentTraining(
      context,
      controller,
      assignment,
    );
  } finally {
    controller.endTeacherAssignment();
  }

  if (!context.mounted) return;

  TrainingSessionResult? session;
  for (final entry in controller.history) {
    if (!entry.isAssessment &&
        entry.mode == assignment.mode &&
        !entry.startedAt.isBefore(
          startedAt.subtract(const Duration(seconds: 1)),
        )) {
      session = entry;
      break;
    }
  }

  if (session == null || session.total == 0) return;

  final observations = controller.microObservations.where(
    (entry) =>
        entry.mode == assignment.mode &&
        entry.gradeLevel == assignment.gradeLevel &&
        entry.numberRange == assignment.numberRange &&
        !entry.occurredAt.isBefore(
          startedAt.subtract(const Duration(seconds: 1)),
        ),
  );

  final result = TeacherAssignmentResult.fromSession(
    assignment: assignment,
    session: session,
    observations: observations,
  );

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AssignmentResultScreen(result: result),
    ),
  );
}

Future<void> _openAssignmentTraining(
  BuildContext context,
  AppController controller,
  TeacherAssignment assignment,
) async {
  if (assignment.mode.isUpperPrimary) {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CurriculumTrainingScreen(
          controller: controller,
          mode: assignment.mode,
          targetTasks: assignment.tasks,
          targetCompetency: assignment.targetCompetency,
        ),
      ),
    );
    return;
  }

  if (assignment.mode.isStructured) {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StructuredTrainingScreen(
          controller: controller,
          mode: assignment.mode,
          targetTasks: assignment.tasks,
          targetCompetency: assignment.targetCompetency,
          transferEmphasis: assignment.transferEmphasis,
        ),
      ),
    );
    return;
  }

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => TrainingScreen(
        controller: controller,
        mode: assignment.mode,
        targetTasks: assignment.tasks,
        targetCompetency: assignment.targetCompetency,
      ),
    ),
  );
}
