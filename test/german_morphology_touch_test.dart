import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_morphology_touch_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_support_catalog.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';

void main() {
  test('morphology touch catalog is valid and spans grades one to four', () {
    expect(GermanMorphologyTouchTaskCatalog.tasks, hasLength(24));
    expect(
      GermanMorphologyTouchTaskCatalog.tasks
          .map((task) => task.recommendedFromGrade)
          .toSet(),
      <GradeLevel>{
        GradeLevel.first,
        GradeLevel.second,
        GradeLevel.third,
        GradeLevel.fourth,
      },
    );
    for (final task in GermanMorphologyTouchTaskCatalog.tasks) {
      expect(task.interaction, GermanTaskInteraction.wordBuilder);
      expect(task.isWellFormed, isTrue, reason: task.id);
    }
  });

  test('targeted practice surfaces productive morphology builders', () {
    final cases = <(GradeLevel, GermanCompetencyId)>[
      (GradeLevel.first, GermanCompetencyId.syllableSegmentation),
      (GradeLevel.second, GermanCompetencyId.verbInflection),
      (GradeLevel.third, GermanCompetencyId.verbTenses),
      (GradeLevel.fourth, GermanCompetencyId.verbTenses),
    ];

    for (final entry in cases) {
      final round = GermanPracticePlanner.buildCompetencyRound(
        gradeLevel: entry.$1,
        competencyId: entry.$2,
        history: const <GermanSessionResult>[],
      );
      expect(
        round.any(
          (task) => task.interaction == GermanTaskInteraction.wordBuilder,
        ),
        isTrue,
        reason: '${entry.$1.name}/${entry.$2.name}',
      );
    }
  });

  test('morphology builders reject wrong endings and chunks', () {
    final inflection = GermanMorphologyTouchTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g2-inflect-go-you-build',
    );
    final perfect = GermanMorphologyTouchTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-tense-play-perfect-build',
    );

    expect(inflection.accepts('gehst'), isTrue);
    expect(inflection.accepts('geht'), isFalse);
    expect(perfect.accepts('gespielt'), isTrue);
    expect(perfect.accepts('gespielte'), isFalse);
  });

  test('word-builder hints are specific to the learning goal', () {
    final syllable = GermanMorphologyTouchTaskCatalog.tasks.first;
    final inflection = GermanMorphologyTouchTaskCatalog.tasks.firstWhere(
      (task) => task.competencyId == GermanCompetencyId.verbInflection,
    );
    final tense = GermanMorphologyTouchTaskCatalog.tasks.firstWhere(
      (task) => task.competencyId == GermanCompetencyId.verbTenses,
    );

    expect(
      GermanSupportCatalog.firstHintForTask(syllable),
      contains('klatsche'),
    );
    expect(
      GermanSupportCatalog.firstHintForTask(inflection),
      contains('Person'),
    );
    expect(GermanSupportCatalog.secondHintForTask(tense), contains('Perfekt'));
  });
}
