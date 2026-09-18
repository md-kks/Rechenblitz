import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_history_scope.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_prerequisites.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_storage_service.dart';
import 'package:rechenblitz/subjects/german/screens/german_competency_map_screen.dart';
import 'package:rechenblitz/subjects/german/screens/german_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));
  test('history scope keeps current and earlier grades only', () {
    final history = <GermanSessionResult>[
      _session(GradeLevel.first, GermanCompetencyId.wordRecognition),
      _session(GradeLevel.second, GermanCompetencyId.nounArticle, minute: 2),
      _session(GradeLevel.third, GermanCompetencyId.compoundWords, minute: 4),
      _session(GradeLevel.fourth, GermanCompetencyId.textMainIdea, minute: 6),
    ];

    final scoped = GermanHistoryScope.throughGrade(history, GradeLevel.second);

    expect(scoped, hasLength(2));
    expect(
      scoped.map((session) => session.gradeLevel).toList(growable: false),
      <GradeLevel>[GradeLevel.first, GradeLevel.second],
    );
  });

  test('daily practice ignores future-grade evidence after downgrade', () {
    final baseline = GermanPracticePlanner.buildDailyRound(
      gradeLevel: GradeLevel.second,
      history: const <GermanSessionResult>[],
      now: DateTime(2026, 9, 18, 10),
    );
    final futureWeakness = _session(
      GradeLevel.fourth,
      GermanCompetencyId.wordRecognition,
      correct: false,
    );

    final downgraded = GermanPracticePlanner.buildDailyRound(
      gradeLevel: GradeLevel.second,
      history: <GermanSessionResult>[futureWeakness],
      now: DateTime(2026, 9, 18, 10),
    );

    expect(
      downgraded.map((task) => task.id).toList(growable: false),
      baseline.map((task) => task.id).toList(growable: false),
    );
  });

  test('future-grade mastery cannot satisfy a downgraded prerequisite', () {
    final futureMastery = <GermanSessionResult>[
      _session(
        GradeLevel.fourth,
        GermanCompetencyId.nounArticle,
        taskIds: const <String>['future-noun-a', 'future-noun-b'],
      ),
      _session(
        GradeLevel.fourth,
        GermanCompetencyId.nounArticle,
        taskIds: const <String>['future-noun-c'],
        minute: 3,
      ),
    ];

    final status = GermanPrerequisiteResolver.status(
      GermanCompetencyId.singularPlural,
      futureMastery,
      currentGrade: GradeLevel.second,
    );

    expect(status.isUnlocked, isFalse);
    expect(status.nextRequired?.id, GermanCompetencyId.nounArticle);
  });

  testWidgets('competency map ignores future-grade mastery after downgrade', (
    tester,
  ) async {
    final futureMastery = <GermanSessionResult>[
      _session(
        GradeLevel.fourth,
        GermanCompetencyId.nounArticle,
        taskIds: const <String>['future-noun-a', 'future-noun-b'],
      ),
      _session(
        GradeLevel.fourth,
        GermanCompetencyId.nounArticle,
        taskIds: const <String>['future-noun-c'],
        minute: 3,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: GermanCompetencyMapScreen(
          gradeLevel: GradeLevel.second,
          history: futureMastery,
          referenceNow: DateTime(2026, 9, 18, 10),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final card = find.byKey(
      const ValueKey('german-competency-card-nounArticle'),
    );
    await tester.scrollUntilVisible(
      card,
      180,
      scrollable: find.byType(Scrollable).first,
    );

    expect(
      find.descendant(of: card, matching: find.textContaining('Neu')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.textContaining('Sicher')),
      findsNothing,
    );
  });

  testWidgets('home ignores future-only history for focus and recent round', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    final storage = GermanStorageService(profileId: controller.activeProfileId);
    await storage.setIntroComplete(true);
    await storage.saveHistory(<GermanSessionResult>[
      _session(
        GradeLevel.fourth,
        GermanCompetencyId.wordRecognition,
        correct: false,
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: GermanHomeScreen(
          controller: controller,
          now: () => DateTime(2026, 9, 18, 10),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('12 kurze Aufgaben aus allen sechs Deutsch-Lernbereichen.'),
      findsOneWidget,
    );
    expect(find.text('Zuletzt'), findsNothing);
    expect(find.textContaining('mehr Übungszeit'), findsNothing);
  });
}

GermanSessionResult _session(
  GradeLevel grade,
  GermanCompetencyId competency, {
  bool correct = true,
  List<String>? taskIds,
  int minute = 0,
}) {
  final ids = taskIds ?? <String>['${grade.name}-${competency.name}-task'];
  return GermanSessionResult(
    gradeLevel: grade,
    startedAt: DateTime(2026, 9, 18, 9, minute),
    finishedAt: DateTime(2026, 9, 18, 9, minute + 1),
    taskResults: <GermanTaskResult>[
      for (final taskId in ids)
        GermanTaskResult(
          taskId: taskId,
          competencyId: competency,
          correctFirstTry: correct,
          incorrectAttempts: correct ? 0 : 1,
          responseMs: 1000,
        ),
    ],
  );
}
