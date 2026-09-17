import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_competency_catalog.dart';
import 'package:rechenblitz/subjects/german/german_learning_domain.dart';
import 'package:rechenblitz/subjects/german/german_starter_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/german_teacher_assignment.dart';

void main() {
  test('every German competency id has exactly one definition', () {
    final ids = GermanCompetencyCatalog.definitions
        .map((definition) => definition.id)
        .toList();
    expect(ids.toSet().length, ids.length);
    expect(ids.toSet(), GermanCompetencyId.values.toSet());
  });

  test('prerequisites always point to earlier or same-grade competencies', () {
    for (final definition in GermanCompetencyCatalog.definitions) {
      for (final prerequisite in definition.prerequisites) {
        final prerequisiteDefinition = GermanCompetencyCatalog.definition(
          prerequisite,
        );
        expect(
          prerequisiteDefinition.recommendedFromGrade.index,
          lessThanOrEqualTo(definition.recommendedFromGrade.index),
        );
      }
    }
  });

  test('starter tasks are unique, well formed and grade-compatible', () {
    final ids = <String>{};
    for (final task in GermanStarterTaskCatalog.tasks) {
      expect(ids.add(task.id), isTrue, reason: 'duplicate task id ${task.id}');
      expect(task.isWellFormed, isTrue, reason: task.id);
      final definition = GermanCompetencyCatalog.definition(task.competencyId);
      expect(
        task.recommendedFromGrade.index,
        greaterThanOrEqualTo(definition.recommendedFromGrade.index),
        reason: task.id,
      );
    }
  });

  test('first-grade starter set stays free of second-grade content', () {
    final firstGrade = GermanStarterTaskCatalog.forGrade(GradeLevel.first);
    expect(firstGrade, isNotEmpty);
    expect(
      firstGrade.every((task) => task.recommendedFromGrade == GradeLevel.first),
      isTrue,
    );
  });

  test('listening tasks contain local TTS content', () {
    final listening = GermanStarterTaskCatalog.forDomain(
      GermanLearningDomain.listening,
      GradeLevel.second,
    );
    expect(listening, isNotEmpty);
    expect(listening.every((task) => task.requiresSpeech), isTrue);
    expect(listening.every((task) => task.spokenText!.isNotEmpty), isTrue);
  });

  test('German teacher assignment round-trips through offline QR payload', () {
    const assignment = GermanTeacherAssignment(
      gradeLevel: GradeLevel.second,
      domain: GermanLearningDomain.reading,
      tasks: 12,
      targetCompetency: GermanCompetencyId.textInformation,
    );

    final restored = GermanTeacherAssignment.tryParse(assignment.toPayload());
    expect(restored, isNotNull);
    expect(restored!.gradeLevel, assignment.gradeLevel);
    expect(restored.domain, assignment.domain);
    expect(restored.tasks, assignment.tasks);
    expect(restored.targetCompetency, assignment.targetCompetency);
    expect(restored.assignmentId, assignment.assignmentId);
  });

  test('German assignment rejects competency from another domain', () {
    const assignment = GermanTeacherAssignment(
      gradeLevel: GradeLevel.second,
      domain: GermanLearningDomain.reading,
      tasks: 8,
      targetCompetency: GermanCompetencyId.nounArticle,
    );

    expect(GermanTeacherAssignment.tryParse(assignment.toPayload()), isNull);
  });

  test('typed German answers ignore casing and repeated spaces', () {
    final task = GermanStarterTaskCatalog.tasks.firstWhere(
      (task) => task.interaction == GermanTaskInteraction.typedText,
    );
    expect(task.accepts('  heute   REGNET es. '), isTrue);
  });
}
