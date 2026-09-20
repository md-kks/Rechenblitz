import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_competency_catalog.dart';
import 'package:rechenblitz/subjects/german/german_learning_domain.dart';
import 'package:rechenblitz/subjects/german/german_round_draft.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';

void main() {
  test(
    'task catalog indexes preserve grade, domain and competency ordering',
    () {
      for (final grade in GradeLevel.values) {
        final expectedGrade = GermanTaskCatalog.tasks
            .where((task) => task.recommendedFromGrade.index <= grade.index)
            .map((task) => task.id)
            .toList(growable: false);
        final actualGrade = GermanTaskCatalog.forGrade(grade);
        expect(
          actualGrade.map((task) => task.id),
          expectedGrade,
          reason: grade.name,
        );
        expect(
          identical(actualGrade, GermanTaskCatalog.forGrade(grade)),
          isTrue,
        );

        for (final domain in GermanLearningDomain.values) {
          final expectedDomain = GermanTaskCatalog.tasks
              .where(
                (task) =>
                    task.recommendedFromGrade.index <= grade.index &&
                    GermanCompetencyCatalog.definition(
                          task.competencyId,
                        ).domain ==
                        domain,
              )
              .map((task) => task.id)
              .toList(growable: false);
          final actualDomain = GermanTaskCatalog.forDomain(domain, grade);
          expect(
            actualDomain.map((task) => task.id),
            expectedDomain,
            reason: '${grade.name}/${domain.name}',
          );
          expect(
            identical(actualDomain, GermanTaskCatalog.forDomain(domain, grade)),
            isTrue,
          );
        }
      }

      for (final competency in GermanCompetencyId.values) {
        final expected = GermanTaskCatalog.tasks
            .where((task) => task.competencyId == competency)
            .map((task) => task.id)
            .toList(growable: false);
        final actual = GermanTaskCatalog.forCompetency(competency);
        expect(
          actual.map((task) => task.id),
          expected,
          reason: competency.name,
        );
        expect(
          identical(actual, GermanTaskCatalog.forCompetency(competency)),
          isTrue,
        );
      }
    },
  );

  test('task id index resolves canonical task objects', () {
    for (final task in GermanTaskCatalog.tasks) {
      expect(
        identical(GermanTaskCatalog.byId(task.id), task),
        isTrue,
        reason: task.id,
      );
    }
    expect(GermanTaskCatalog.byId('missing-task-id'), isNull);
  });

  test('competency catalog indexes preserve existing results', () {
    for (final competency in GermanCompetencyId.values) {
      final expected = GermanCompetencyCatalog.definitions.firstWhere(
        (definition) => definition.id == competency,
      );
      expect(
        identical(GermanCompetencyCatalog.definition(competency), expected),
        isTrue,
        reason: competency.name,
      );
    }

    for (final grade in GradeLevel.values) {
      final expectedRecommended = GermanCompetencyCatalog.definitions
          .where((definition) => definition.isRecommendedFor(grade))
          .map((definition) => definition.id)
          .toList(growable: false);
      final actualRecommended = GermanCompetencyCatalog.recommendedFor(grade);
      expect(
        actualRecommended.map((definition) => definition.id),
        expectedRecommended,
        reason: grade.name,
      );
      expect(
        identical(
          actualRecommended,
          GermanCompetencyCatalog.recommendedFor(grade),
        ),
        isTrue,
      );

      for (final domain in GermanLearningDomain.values) {
        final expectedDomain = GermanCompetencyCatalog.definitions
            .where(
              (definition) =>
                  definition.domain == domain &&
                  definition.isRecommendedFor(grade),
            )
            .map((definition) => definition.id)
            .toList(growable: false);
        final actualDomain = GermanCompetencyCatalog.forDomain(domain, grade);
        expect(
          actualDomain.map((definition) => definition.id),
          expectedDomain,
          reason: '${grade.name}/${domain.name}',
        );
        expect(
          identical(
            actualDomain,
            GermanCompetencyCatalog.forDomain(domain, grade),
          ),
          isTrue,
        );
      }
    }
  });

  test('cached catalog lists are protected from accidental mutation', () {
    final task = GermanTaskCatalog.tasks.first;
    expect(
      () => GermanTaskCatalog.forGrade(GradeLevel.first).add(task),
      throwsUnsupportedError,
    );
    expect(
      () => GermanTaskCatalog.forCompetency(task.competencyId).clear(),
      throwsUnsupportedError,
    );
    expect(
      () => GermanCompetencyCatalog.recommendedFor(GradeLevel.first).clear(),
      throwsUnsupportedError,
    );
  });

  test('round draft resolves through the canonical task index', () {
    final tasks = GermanTaskCatalog.forGrade(GradeLevel.first).take(3).toList();
    final draft = GermanRoundDraft(
      gradeLevel: GradeLevel.first,
      taskIds: tasks.map((task) => task.id).toList(growable: false),
      currentIndex: 0,
      startedAt: DateTime(2026, 9, 20, 12),
      updatedAt: DateTime(2026, 9, 20, 12, 1),
      completedResults: const <GermanTaskResult>[],
    );

    final resolved = draft.resolveTasks();
    expect(resolved, isNotNull);
    expect(resolved, hasLength(tasks.length));
    for (var index = 0; index < tasks.length; index++) {
      expect(identical(resolved![index], tasks[index]), isTrue);
    }

    final invalid = GermanRoundDraft(
      gradeLevel: GradeLevel.first,
      taskIds: const <String>['missing-task-id'],
      currentIndex: 0,
      startedAt: DateTime(2026, 9, 20, 12),
      updatedAt: DateTime(2026, 9, 20, 12, 1),
      completedResults: const <GermanTaskResult>[],
    );
    expect(invalid.resolveTasks(), isNull);
  });
}
