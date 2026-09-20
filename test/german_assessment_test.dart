import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_assessment.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_competency_catalog.dart';
import 'package:rechenblitz/subjects/german/german_learning_domain.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_task_evidence_priority.dart';

void main() {
  test('Lerncheck covers every available German domain', () {
    for (final grade in GradeLevel.values) {
      final tasks = GermanAssessmentPlanner.buildRound(grade);
      expect(tasks, isNotEmpty);
      expect(tasks.length, lessThanOrEqualTo(12));
      final domains = tasks
          .map(
            (task) =>
                GermanCompetencyCatalog.definition(task.competencyId).domain,
          )
          .toSet();
      expect(domains, containsAll(GermanLearningDomain.values));
      expect(
        tasks.every((task) => task.recommendedFromGrade.index <= grade.index),
        isTrue,
      );
    }
  });
  test('Lerncheck prefers stronger evidence over avoidable single choice', () {
    final expectedSingleChoice = <GradeLevel, int>{
      GradeLevel.first: 1,
      GradeLevel.second: 0,
      GradeLevel.third: 0,
      GradeLevel.fourth: 0,
    };

    for (final grade in GradeLevel.values) {
      final tasks = GermanAssessmentPlanner.buildRound(grade);
      expect(
        tasks
            .where(
              (task) => task.interaction == GermanTaskInteraction.singleChoice,
            )
            .length,
        expectedSingleChoice[grade],
        reason: grade.name,
      );

      for (final task in tasks) {
        final sameSkill = GermanTaskCatalog.forCompetency(task.competencyId)
            .where(
              (candidate) =>
                  candidate.recommendedFromGrade == task.recommendedFromGrade,
            );
        final bestRank = sameSkill
            .map(GermanTaskEvidencePriority.rank)
            .fold<int>(999, (best, rank) => rank < best ? rank : best);
        expect(
          GermanTaskEvidencePriority.rank(task),
          bestRank,
          reason: '${grade.name}/${task.id}',
        );
      }
    }
  });

  test('Lerncheck measures letter-sound matching through listening', () {
    for (final grade in GradeLevel.values) {
      final phonics = GermanAssessmentPlanner.buildRound(grade).where(
        (task) => task.competencyId == GermanCompetencyId.letterSoundMatch,
      );
      for (final task in phonics) {
        expect(task.interaction, GermanTaskInteraction.listeningChoice);
        expect(task.requiresSpeech, isTrue);
      }
    }
  });

  test('upper-primary Lernchecks use current-grade tasks first', () {
    for (final grade in <GradeLevel>[GradeLevel.third, GradeLevel.fourth]) {
      final tasks = GermanAssessmentPlanner.buildRound(grade);

      expect(tasks, hasLength(12));
      expect(
        tasks.every((task) => task.recommendedFromGrade == grade),
        isTrue,
        reason: grade.name,
      );
    }

    final fourth = GermanAssessmentPlanner.buildRound(GradeLevel.fourth);
    expect(
      fourth.any(
        (task) => task.competencyId == GermanCompetencyId.textMainIdea,
      ),
      isTrue,
    );
    expect(
      fourth.any(
        (task) =>
            task.competencyId == GermanCompetencyId.directSpeechPunctuation,
      ),
      isTrue,
    );
  });

  test('assessment rotation ignores evidence from another grade', () {
    final baseline = GermanAssessmentPlanner.buildRound(GradeLevel.second);
    final foreignGradeSession = GermanSessionResult(
      gradeLevel: GradeLevel.first,
      startedAt: DateTime(2026, 9, 17, 9),
      finishedAt: DateTime(2026, 9, 17, 9, 5),
      kind: GermanSessionKind.assessment,
      taskResults: baseline
          .map(
            (task) => GermanTaskResult(
              taskId: task.id,
              competencyId: task.competencyId,
              correctFirstTry: true,
              incorrectAttempts: 0,
              responseMs: 1000,
            ),
          )
          .toList(growable: false),
    );

    final withForeignHistory = GermanAssessmentPlanner.buildRound(
      GradeLevel.second,
      history: <GermanSessionResult>[foreignGradeSession],
    );

    expect(
      withForeignHistory.map((task) => task.id).toList(growable: false),
      baseline.map((task) => task.id).toList(growable: false),
    );
  });

  test('duplicate Lerncheck session does not rotate twice', () {
    final first = GermanAssessmentPlanner.buildRound(GradeLevel.second);
    final firstSession = GermanSessionResult(
      gradeLevel: GradeLevel.second,
      startedAt: DateTime(2026, 9, 17, 10),
      finishedAt: DateTime(2026, 9, 17, 10, 5),
      kind: GermanSessionKind.assessment,
      taskResults: first
          .map(
            (task) => GermanTaskResult(
              taskId: task.id,
              competencyId: task.competencyId,
              correctFirstTry: true,
              incorrectAttempts: 0,
              responseMs: 1000,
            ),
          )
          .toList(growable: false),
    );

    final singleHistory = GermanAssessmentPlanner.buildRound(
      GradeLevel.second,
      history: <GermanSessionResult>[firstSession],
    );
    final duplicatedHistory = GermanAssessmentPlanner.buildRound(
      GradeLevel.second,
      history: <GermanSessionResult>[firstSession, firstSession],
    );

    expect(
      duplicatedHistory.map((task) => task.id).toList(growable: false),
      singleHistory.map((task) => task.id).toList(growable: false),
    );
  });

  test('Lerncheck can revisit previously read-aloud reading tasks', () {
    final first = GermanAssessmentPlanner.buildRound(GradeLevel.second);
    final firstSession = GermanSessionResult(
      gradeLevel: GradeLevel.second,
      startedAt: DateTime(2026, 9, 18, 10),
      finishedAt: DateTime(2026, 9, 18, 10, 5),
      kind: GermanSessionKind.assessment,
      taskResults: first
          .map(
            (task) => GermanTaskResult(
              taskId: task.id,
              competencyId: task.competencyId,
              correctFirstTry: true,
              incorrectAttempts: 0,
              responseMs: 1000,
              usedReadAloud:
                  GermanCompetencyCatalog.definition(
                    task.competencyId,
                  ).domain ==
                  GermanLearningDomain.reading,
            ),
          )
          .toList(growable: false),
    );

    final normalRotation = GermanAssessmentPlanner.buildRound(
      GradeLevel.second,
      history: <GermanSessionResult>[firstSession],
    );
    final independentReadingRotation = GermanAssessmentPlanner.buildRound(
      GradeLevel.second,
      history: <GermanSessionResult>[firstSession],
      prioritizeIndependentReading: true,
    );

    Set<String> readingIds(List<GermanTask> tasks) => tasks
        .where(
          (task) =>
              GermanCompetencyCatalog.definition(task.competencyId).domain ==
              GermanLearningDomain.reading,
        )
        .map((task) => task.id)
        .toSet();

    final firstReading = readingIds(first);
    final normalReading = readingIds(normalRotation);
    final independentReading = readingIds(independentReadingRotation);
    final normalOverlap = normalReading.intersection(firstReading).length;
    final independentOverlap = independentReading
        .intersection(firstReading)
        .length;

    expect(independentOverlap, greaterThan(normalOverlap));
    expect(independentReading, firstReading);
  });

  test('repeated Lernchecks rotate away from recently used tasks', () {
    final first = GermanAssessmentPlanner.buildRound(GradeLevel.second);
    final firstSession = GermanSessionResult(
      gradeLevel: GradeLevel.second,
      startedAt: DateTime(2026, 9, 17, 10),
      finishedAt: DateTime(2026, 9, 17, 10, 5),
      kind: GermanSessionKind.assessment,
      taskResults: first
          .map(
            (task) => GermanTaskResult(
              taskId: task.id,
              competencyId: task.competencyId,
              correctFirstTry: true,
              incorrectAttempts: 0,
              responseMs: 1000,
            ),
          )
          .toList(growable: false),
    );

    final second = GermanAssessmentPlanner.buildRound(
      GradeLevel.second,
      history: <GermanSessionResult>[firstSession],
    );
    final firstIds = first.map((task) => task.id).toSet();
    final overlap = second.where((task) => firstIds.contains(task.id)).length;

    expect(second, hasLength(first.length));
    expect(overlap, lessThan(first.length));
    final secondDomains = second
        .map(
          (task) =>
              GermanCompetencyCatalog.definition(task.competencyId).domain,
        )
        .toSet();
    expect(secondDomains, containsAll(GermanLearningDomain.values));
  });

  test('assessment summary groups first-try evidence by domain', () {
    final tasks = GermanAssessmentPlanner.buildRound(GradeLevel.second);
    final results = tasks
        .map(
          (task) => GermanTaskResult(
            taskId: task.id,
            competencyId: task.competencyId,
            correctFirstTry: task == tasks.first,
            incorrectAttempts: task == tasks.first ? 0 : 1,
            responseMs: 1000,
          ),
        )
        .toList(growable: false);
    final session = GermanSessionResult(
      gradeLevel: GradeLevel.second,
      startedAt: DateTime(2026, 9, 17, 10),
      finishedAt: DateTime(2026, 9, 17, 10, 5),
      taskResults: results,
      kind: GermanSessionKind.assessment,
    );
    final summary = GermanAssessmentSummary.fromSession(session);
    expect(summary.domains.where((value) => value.total > 0).length, 6);
    expect(summary.session.kind, GermanSessionKind.assessment);
    expect(summary.nextDomains, isNotEmpty);
  });
  test('assisted reading success is neutral in Lerncheck domain evidence', () {
    final session = GermanSessionResult(
      gradeLevel: GradeLevel.second,
      startedAt: DateTime(2026, 9, 18, 10),
      finishedAt: DateTime(2026, 9, 18, 10, 5),
      kind: GermanSessionKind.assessment,
      taskResults: const <GermanTaskResult>[
        GermanTaskResult(
          taskId: 'read-assisted',
          competencyId: GermanCompetencyId.wordRecognition,
          correctFirstTry: true,
          incorrectAttempts: 0,
          responseMs: 1000,
          usedReadAloud: true,
        ),
        GermanTaskResult(
          taskId: 'language-independent',
          competencyId: GermanCompetencyId.nounArticle,
          correctFirstTry: true,
          incorrectAttempts: 0,
          responseMs: 1000,
        ),
      ],
    );

    final summary = GermanAssessmentSummary.fromSession(session);
    final reading = summary.domains.firstWhere(
      (entry) => entry.domain == GermanLearningDomain.reading,
    );

    expect(reading.independentTasks, 0);
    expect(reading.readAloudAssistedTasks, 1);
    expect(reading.accuracy, 0);
    expect(
      summary.strongestDomains.map((entry) => entry.domain),
      isNot(contains(GermanLearningDomain.reading)),
    );
    expect(
      summary.nextDomains.map((entry) => entry.domain),
      isNot(contains(GermanLearningDomain.reading)),
    );
  });

  test('assisted reading retry still surfaces reading as next focus', () {
    final session = GermanSessionResult(
      gradeLevel: GradeLevel.second,
      startedAt: DateTime(2026, 9, 18, 10),
      finishedAt: DateTime(2026, 9, 18, 10, 5),
      kind: GermanSessionKind.assessment,
      taskResults: const <GermanTaskResult>[
        GermanTaskResult(
          taskId: 'read-assisted-retry',
          competencyId: GermanCompetencyId.wordRecognition,
          correctFirstTry: false,
          incorrectAttempts: 1,
          responseMs: 1300,
          usedReadAloud: true,
        ),
        GermanTaskResult(
          taskId: 'language-independent',
          competencyId: GermanCompetencyId.nounArticle,
          correctFirstTry: true,
          incorrectAttempts: 0,
          responseMs: 900,
        ),
      ],
    );

    final summary = GermanAssessmentSummary.fromSession(session);

    expect(
      summary.nextDomains.map((entry) => entry.domain),
      contains(GermanLearningDomain.reading),
    );
  });

  test('perfect Lerncheck does not invent a next practice domain', () {
    final session = GermanSessionResult(
      gradeLevel: GradeLevel.second,
      startedAt: DateTime(2026, 9, 18, 10),
      finishedAt: DateTime(2026, 9, 18, 10, 5),
      kind: GermanSessionKind.assessment,
      taskResults: const <GermanTaskResult>[
        GermanTaskResult(
          taskId: 'read-perfect',
          competencyId: GermanCompetencyId.wordRecognition,
          correctFirstTry: true,
          incorrectAttempts: 0,
          responseMs: 1000,
        ),
        GermanTaskResult(
          taskId: 'language-perfect',
          competencyId: GermanCompetencyId.nounArticle,
          correctFirstTry: true,
          incorrectAttempts: 0,
          responseMs: 1000,
        ),
      ],
    );

    final summary = GermanAssessmentSummary.fromSession(session);

    expect(summary.solvedAfterRetry, 0);
    expect(summary.nextDomains, isEmpty);
    expect(
      summary.domains
          .where((entry) => entry.total > 0)
          .every((entry) => entry.solvedAfterRetry == 0),
      isTrue,
    );
  });

  test('Lerncheck next focus only contains domains that needed retries', () {
    final session = GermanSessionResult(
      gradeLevel: GradeLevel.second,
      startedAt: DateTime(2026, 9, 18, 10),
      finishedAt: DateTime(2026, 9, 18, 10, 5),
      kind: GermanSessionKind.assessment,
      taskResults: const <GermanTaskResult>[
        GermanTaskResult(
          taskId: 'read-retry',
          competencyId: GermanCompetencyId.wordRecognition,
          correctFirstTry: false,
          incorrectAttempts: 2,
          responseMs: 1800,
        ),
        GermanTaskResult(
          taskId: 'language-direct',
          competencyId: GermanCompetencyId.nounArticle,
          correctFirstTry: true,
          incorrectAttempts: 0,
          responseMs: 900,
        ),
      ],
    );

    final summary = GermanAssessmentSummary.fromSession(session);
    final reading = summary.domains.firstWhere(
      (entry) => entry.domain == GermanLearningDomain.reading,
    );

    expect(summary.solvedAfterRetry, 1);
    expect(reading.solvedAfterRetry, 1);
    expect(summary.nextDomains, hasLength(1));
    expect(summary.nextDomains.single.domain, GermanLearningDomain.reading);
  });

  test('old German session JSON defaults to normal practice', () {
    final session = GermanSessionResult.fromJson(<String, dynamic>{
      'gradeLevel': 'first',
      'startedAt': '2026-09-17T10:00:00.000',
      'finishedAt': '2026-09-17T10:01:00.000',
      'taskResults': <dynamic>[],
    });
    expect(session.kind, GermanSessionKind.practice);
  });
}
