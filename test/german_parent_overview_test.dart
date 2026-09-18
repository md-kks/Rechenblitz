import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_parent_overview.dart';
import 'package:rechenblitz/subjects/german/german_progress.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_storage_service.dart';
import 'package:rechenblitz/subjects/german/screens/german_parent_overview_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

GermanSessionResult _session({
  required GermanCompetencyId competency,
  required List<bool> correct,
  int minute = 0,
  GermanSessionKind kind = GermanSessionKind.practice,
  String taskPrefix = 'task',
}) => GermanSessionResult(
  gradeLevel: GradeLevel.second,
  startedAt: DateTime(2026, 9, 17, 10, minute),
  finishedAt: DateTime(2026, 9, 17, 10, minute + 1),
  kind: kind,
  taskResults: <GermanTaskResult>[
    for (var i = 0; i < correct.length; i++)
      GermanTaskResult(
        taskId: '$taskPrefix-${competency.name}-$i',
        competencyId: competency,
        correctFirstTry: correct[i],
        incorrectAttempts: correct[i] ? 0 : 1,
        responseMs: 1200,
      ),
  ],
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('parent overview separates strengths from practice needs', () {
    final overview = GermanParentOverview.analyze(
      gradeLevel: GradeLevel.second,
      history: <GermanSessionResult>[
        _session(
          competency: GermanCompetencyId.nounArticle,
          correct: const <bool>[true, true],
          taskPrefix: 'noun-a',
        ),
        _session(
          competency: GermanCompetencyId.nounArticle,
          correct: const <bool>[true],
          minute: 2,
          taskPrefix: 'noun-b',
        ),
        _session(
          competency: GermanCompetencyId.wordRecognition,
          correct: const <bool>[false, true],
          minute: 5,
        ),
      ],
    );

    expect(overview.sessionCount, 3);
    expect(overview.totalTasks, 5);
    expect(overview.secureCompetencies, 1);
    expect(
      overview.strengths.single.competencyId,
      GermanCompetencyId.nounArticle,
    );
    expect(
      overview.practiceNeeds.first.competencyId,
      GermanCompetencyId.wordRecognition,
    );
  });

  test('secure but stale skill moves from strengths to review due', () {
    final overview = GermanParentOverview.analyze(
      gradeLevel: GradeLevel.second,
      now: DateTime(2026, 10, 5),
      history: <GermanSessionResult>[
        _session(
          competency: GermanCompetencyId.nounArticle,
          correct: const <bool>[true, true],
          taskPrefix: 'noun-a',
        ),
        _session(
          competency: GermanCompetencyId.nounArticle,
          correct: const <bool>[true],
          minute: 2,
          taskPrefix: 'noun-b',
        ),
      ],
    );

    expect(overview.secureCompetencies, 1);
    expect(overview.strengths, isEmpty);
    expect(overview.reviewDue, hasLength(1));
    expect(
      overview.reviewDue.single.competencyId,
      GermanCompetencyId.nounArticle,
    );
    final language = overview.domains.firstWhere(
      (entry) => entry.domain.name == 'language',
    );
    expect(language.reviewDueCompetencies, 1);
  });

  test('recent setbacks outrank old strength in the parent overview', () {
    final history = <GermanSessionResult>[
      for (var index = 0; index < 10; index++)
        _session(
          competency: GermanCompetencyId.wordRecognition,
          correct: const <bool>[true],
          minute: index,
          taskPrefix: 'old-$index',
        ),
      _session(
        competency: GermanCompetencyId.wordRecognition,
        correct: const <bool>[false],
        minute: 10,
        taskPrefix: 'recent-a',
      ),
      _session(
        competency: GermanCompetencyId.wordRecognition,
        correct: const <bool>[false],
        minute: 12,
        taskPrefix: 'recent-b',
      ),
    ];

    final overview = GermanParentOverview.analyze(
      gradeLevel: GradeLevel.second,
      history: history,
    );
    final progress = overview.progress.firstWhere(
      (entry) => entry.competencyId == GermanCompetencyId.wordRecognition,
    );

    expect(progress.accuracy, closeTo(10 / 12, 0.0001));
    expect(progress.recentAccuracy, 0.6);
    expect(progress.state, GermanCompetencyState.learning);
    expect(
      overview.strengths.any(
        (entry) => entry.competencyId == GermanCompetencyId.wordRecognition,
      ),
      isFalse,
    );
    expect(
      overview.practiceNeeds.first.competencyId,
      GermanCompetencyId.wordRecognition,
    );
  });

  test('parent overview tracks the latest Lerncheck separately', () {
    final overview = GermanParentOverview.analyze(
      gradeLevel: GradeLevel.second,
      history: <GermanSessionResult>[
        _session(
          competency: GermanCompetencyId.wordRecognition,
          correct: const <bool>[true, false],
          kind: GermanSessionKind.assessment,
          minute: 10,
        ),
        _session(
          competency: GermanCompetencyId.nounArticle,
          correct: const <bool>[true],
        ),
      ],
    );

    expect(overview.assessmentCount, 1);
    expect(overview.latestAssessment, isNotNull);
    expect(overview.latestAssessment!.kind, GermanSessionKind.assessment);
  });

  testWidgets('German parent overview shows current and overall evidence', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    final storage = GermanStorageService(profileId: controller.activeProfileId);
    await storage.saveHistory(<GermanSessionResult>[
      for (var index = 0; index < 10; index++)
        _session(
          competency: GermanCompetencyId.wordRecognition,
          correct: const <bool>[true],
          minute: index,
          taskPrefix: 'old-$index',
        ),
      _session(
        competency: GermanCompetencyId.wordRecognition,
        correct: const <bool>[false],
        minute: 10,
        taskPrefix: 'recent-a',
      ),
      _session(
        competency: GermanCompetencyId.wordRecognition,
        correct: const <bool>[false],
        minute: 12,
        taskPrefix: 'recent-b',
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(home: GermanParentOverviewScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    final evidence = find.textContaining(
      'aktuell 60 % · insgesamt 83 % direkt richtig',
    );
    await tester.scrollUntilVisible(
      evidence,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(evidence, findsOneWidget);
  });

  testWidgets('German parent overview surfaces due spaced review', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    final storage = GermanStorageService(profileId: controller.activeProfileId);
    await storage.saveHistory(<GermanSessionResult>[
      _session(
        competency: GermanCompetencyId.nounArticle,
        correct: const <bool>[true, true],
        taskPrefix: 'noun-a',
      ),
      _session(
        competency: GermanCompetencyId.nounArticle,
        correct: const <bool>[true],
        minute: 2,
        taskPrefix: 'noun-b',
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: GermanParentOverviewScreen(
          controller: controller,
          now: () => DateTime(2026, 10, 5),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final review = find.text('Wiederholung fällig');
    await tester.scrollUntilVisible(
      review,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(review, findsWidgets);
    expect(find.textContaining('Nomen und Artikel erkennen'), findsOneWidget);
  });

  testWidgets('German parent overview reads only local profile progress', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    final storage = GermanStorageService(profileId: controller.activeProfileId);
    await storage.saveHistory(<GermanSessionResult>[
      _session(
        competency: GermanCompetencyId.nounArticle,
        correct: const <bool>[true, true],
        taskPrefix: 'noun-a',
      ),
      _session(
        competency: GermanCompetencyId.nounArticle,
        correct: const <bool>[true],
        minute: 2,
        taskPrefix: 'noun-b',
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(home: GermanParentOverviewScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Elternbereich · Deutsch'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    expect(find.text('3'), findsWidgets);
    expect(find.text('100 %'), findsWidgets);
    expect(find.textContaining('Nomen und Artikel erkennen'), findsOneWidget);
  });
}
