import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_competency_catalog.dart';
import 'package:rechenblitz/subjects/german/german_learning_domain.dart';
import 'package:rechenblitz/subjects/german/german_starter_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';
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

  test('fourth-grade German assignment round-trips new learning goals', () {
    const assignment = GermanTeacherAssignment(
      gradeLevel: GradeLevel.fourth,
      domain: GermanLearningDomain.reading,
      tasks: 10,
      targetCompetency: GermanCompetencyId.textMainIdea,
    );

    final restored = GermanTeacherAssignment.tryParse(assignment.toPayload());
    expect(restored, isNotNull);
    expect(restored!.targetCompetency, GermanCompetencyId.textMainIdea);
    expect(restored.gradeLevel, GradeLevel.fourth);
  });

  test('typed German answers keep sentence form but forgive extra spaces', () {
    final task = GermanStarterTaskCatalog.tasks.firstWhere(
      (task) => task.interaction == GermanTaskInteraction.typedText,
    );
    expect(task.accepts('  Heute   regnet es. '), isTrue);
    expect(task.accepts('Es regnet heute.'), isTrue);
    expect(task.accepts('heute regnet es.'), isFalse);
    expect(task.accepts('Heute regnet es'), isFalse);
  });

  test('typed German writing accepts curated grammatical alternatives', () {
    final gradeThree = GermanTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g3-write-afternoon-tower',
    );
    final gradeFour = GermanTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-connect-sick-write',
    );

    expect(
      gradeThree.accepts('Leo baut am Nachmittag einen hohen Turm.'),
      isTrue,
    );
    expect(
      gradeFour.accepts('Weil Ben krank ist, bleibt er heute zu Hause.'),
      isTrue,
    );
    expect(
      gradeFour.accepts('weil Ben krank ist, bleibt er heute zu Hause.'),
      isFalse,
    );
  });
  test('upper-primary writing includes real text production', () {
    final gradeThreeWriting =
        GermanTaskCatalog.forDomain(
          GermanLearningDomain.writing,
          GradeLevel.third,
        ).where(
          (task) =>
              task.recommendedFromGrade == GradeLevel.third &&
              task.interaction == GermanTaskInteraction.typedText,
        );
    expect(gradeThreeWriting.length, greaterThanOrEqualTo(4));

    for (final competency in <GermanCompetencyId>[
      GermanCompetencyId.sentenceConnections,
      GermanCompetencyId.textRevision,
    ]) {
      final productive = GermanTaskCatalog.forCompetency(competency).where(
        (task) =>
            task.recommendedFromGrade == GradeLevel.fourth &&
            task.interaction == GermanTaskInteraction.typedText,
      );
      expect(
        productive.length,
        greaterThanOrEqualTo(3),
        reason: competency.name,
      );
    }
  });

  test('upper-primary domains all have current-grade practice', () {
    for (final grade in <GradeLevel>[GradeLevel.third, GradeLevel.fourth]) {
      for (final domain in GermanLearningDomain.values) {
        final currentGradeTasks = GermanTaskCatalog.forDomain(domain, grade)
            .where((task) => task.recommendedFromGrade == grade)
            .toList(growable: false);
        expect(
          currentGradeTasks.length,
          greaterThanOrEqualTo(2),
          reason: '${grade.name} / ${domain.name}',
        );
      }
    }
  });

  test('combined German task catalog covers every competency', () {
    final ids = <String>{};
    for (final task in GermanTaskCatalog.tasks) {
      expect(ids.add(task.id), isTrue, reason: 'duplicate task id ${task.id}');
      expect(task.isWellFormed, isTrue, reason: task.id);
    }
    for (final competency in GermanCompetencyId.values) {
      expect(
        GermanTaskCatalog.forCompetency(competency),
        isNotEmpty,
        reason: 'missing tasks for ${competency.name}',
      );
    }
    for (final task in GermanTaskCatalog.tasks) {
      final definition = GermanCompetencyCatalog.definition(task.competencyId);
      expect(
        task.recommendedFromGrade.index,
        greaterThanOrEqualTo(definition.recommendedFromGrade.index),
        reason: 'task appears before competency: ${task.id}',
      );
    }
  });

  test('lower-primary German competencies have six curated tasks', () {
    final lowerPrimary = GermanCompetencyCatalog.definitions.where(
      (definition) =>
          definition.recommendedFromGrade.index <= GradeLevel.second.index,
    );
    for (final definition in lowerPrimary) {
      expect(
        GermanTaskCatalog.forCompetency(definition.id).length,
        greaterThanOrEqualTo(6),
        reason: definition.id.name,
      );
    }
  });

  test('every German competency has at least six curated tasks', () {
    for (final competency in GermanCompetencyId.values) {
      expect(
        GermanTaskCatalog.forCompetency(competency).length,
        greaterThanOrEqualTo(6),
        reason: competency.name,
      );
    }
  });

  test('word recognition uses a clue instead of copying the answer', () {
    final tasks = GermanTaskCatalog.forCompetency(
      GermanCompetencyId.wordRecognition,
    );

    expect(tasks, hasLength(greaterThanOrEqualTo(6)));
    for (final task in tasks) {
      expect(task.prompt, startsWith('Bild:'));
      expect(task.accessiblePrompt, isNotNull, reason: task.id);
      expect(task.accessiblePrompt, isNotEmpty, reason: task.id);
      for (final answer in task.acceptedAnswers) {
        final normalizedAnswer = answer.toLowerCase();
        expect(
          task.prompt.toLowerCase(),
          isNot(contains(normalizedAnswer)),
          reason: task.id,
        );
        expect(
          task.accessiblePrompt!.toLowerCase(),
          isNot(contains(normalizedAnswer)),
          reason: '${task.id} accessibility clue',
        );
      }
    }
  });

  test('German catalog contains no exact semantic task duplicates', () {
    String normalize(String value) =>
        value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

    final signatures = <String>{};
    for (final task in GermanTaskCatalog.tasks) {
      final accepted = task.acceptedAnswers.map(normalize).toList()..sort();
      final choices = task.choices.map(normalize).toList()..sort();
      final signature = <String>[
        task.competencyId.name,
        task.recommendedFromGrade.name,
        task.interaction.name,
        normalize(task.instruction),
        normalize(task.prompt),
        accepted.join('||'),
        choices.join('||'),
        normalize(task.spokenText ?? ''),
        normalize(task.accessiblePrompt ?? ''),
      ].join('|');
      expect(
        signatures.add(signature),
        isTrue,
        reason: 'duplicate semantic task content: ${task.id}',
      );
    }
  });

  test('combined catalog has varied practice instead of one fixed task', () {
    expect(GermanTaskCatalog.tasks.length, greaterThanOrEqualTo(215));
    expect(
      GermanTaskCatalog.forCompetency(GermanCompetencyId.wordRecognition),
      hasLength(greaterThanOrEqualTo(2)),
    );
  });

  test('upper-primary competencies unlock progressively by grade', () {
    final second = GermanCompetencyCatalog.recommendedFor(
      GradeLevel.second,
    ).map((definition) => definition.id).toSet();
    final third = GermanCompetencyCatalog.recommendedFor(
      GradeLevel.third,
    ).map((definition) => definition.id).toSet();
    final fourth = GermanCompetencyCatalog.recommendedFor(
      GradeLevel.fourth,
    ).map((definition) => definition.id).toSet();

    expect(second, isNot(contains(GermanCompetencyId.spellingStrategies)));
    expect(third, contains(GermanCompetencyId.spellingStrategies));
    expect(third, contains(GermanCompetencyId.readingInference));
    expect(third, isNot(contains(GermanCompetencyId.textMainIdea)));
    expect(fourth, contains(GermanCompetencyId.textMainIdea));
    expect(fourth, contains(GermanCompetencyId.textRevision));
    expect(fourth, contains(GermanCompetencyId.listeningMainIdeas));
  });

  test('grade filtering never leaks later German content downward', () {
    final secondTasks = GermanTaskCatalog.forGrade(GradeLevel.second);
    final thirdTasks = GermanTaskCatalog.forGrade(GradeLevel.third);

    expect(
      secondTasks.every(
        (task) => task.recommendedFromGrade.index <= GradeLevel.second.index,
      ),
      isTrue,
    );
    expect(
      thirdTasks.any(
        (task) => task.competencyId == GermanCompetencyId.subjectPredicate,
      ),
      isTrue,
    );
    expect(
      thirdTasks.any(
        (task) => task.competencyId == GermanCompetencyId.textRevision,
      ),
      isFalse,
    );
  });

  test(
    'all upper-primary listening tasks keep answer text out of the prompt',
    () {
      final listening = GermanTaskCatalog.forDomain(
        GermanLearningDomain.listening,
        GradeLevel.fourth,
      );
      expect(listening, isNotEmpty);
      expect(listening.every((task) => task.requiresSpeech), isTrue);
      for (final task in listening) {
        for (final answer in task.acceptedAnswers) {
          expect(
            task.prompt.toLowerCase(),
            isNot(contains(answer.toLowerCase())),
          );
        }
      }
    },
  );
}
