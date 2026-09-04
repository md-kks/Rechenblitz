import 'package:flutter/material.dart';

import '../models/teacher_assignment.dart';
import '../models/training.dart';
import '../services/app_controller.dart';
import '../screens/curriculum_training_screen.dart';
import '../screens/structured_training_screen.dart';
import '../screens/training_screen.dart';

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

  controller.beginTeacherAssignment(assignment);
  try {
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
  } finally {
    controller.endTeacherAssignment();
  }
}
