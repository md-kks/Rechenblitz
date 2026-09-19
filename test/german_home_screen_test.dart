import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_learning_domain.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_storage_service.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';
import 'package:rechenblitz/subjects/german/screens/german_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('German home exposes daily round and all six domains', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    await GermanStorageService(
      profileId: controller.activeProfileId,
    ).setIntroComplete(true);

    await tester.pumpWidget(
      MaterialApp(home: GermanHomeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Meine Deutsch-Runde'), findsOneWidget);
    expect(find.text('Lerncheck'), findsOneWidget);
    for (final label in <String>[
      'Lesen',
      'Rechtschreibung',
      'Sprache untersuchen',
      'Wörter & Wortschatz',
      'Sprechen & Zuhören',
      'Schreiben',
    ]) {
      final item = find.text(label);
      await tester.scrollUntilVisible(
        item,
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(item, findsOneWidget);
    }
  });

  testWidgets(
    'reading domain revisits assisted evidence when read-aloud is off',
    (tester) async {
      final controller = AppController();
      await controller.load();
      await controller.setGradeLevel(GradeLevel.second);
      expect(controller.accessibilityPreferences.readAloud, isFalse);

      final storage = GermanStorageService(
        profileId: controller.activeProfileId,
      );
      await storage.setIntroComplete(true);
      final history = <GermanSessionResult>[
        _profileSession(
          taskId: 'assisted-reading',
          correct: true,
          usedReadAloud: true,
        ),
      ];
      await storage.saveHistory(history);

      final expectedFirst = GermanPracticePlanner.buildDomainRound(
        gradeLevel: GradeLevel.second,
        domain: GermanLearningDomain.reading,
        history: history,
        prioritizeIndependentReading: true,
      ).first;
      expect(expectedFirst.competencyId, GermanCompetencyId.wordRecognition);

      await tester.pumpWidget(
        MaterialApp(home: GermanHomeScreen(controller: controller)),
      );
      await tester.pumpAndSettle();

      final reading = find.byKey(const ValueKey('german-domain-reading'));
      await tester.scrollUntilVisible(
        reading,
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(reading);
      await tester.pumpAndSettle();

      expect(find.text('Deutsch üben'), findsOneWidget);
      expect(find.text('1 von 6'), findsOneWidget);
      expect(find.text(expectedFirst.prompt), findsOneWidget);
    },
  );

  testWidgets('German home does not invent focus for fresh secure skill', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    final storage = GermanStorageService(profileId: controller.activeProfileId);
    await storage.setIntroComplete(true);
    await storage.saveHistory(_secureWordHistory(DateTime(2026, 9, 17, 10)));

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
      find.text(
        '12 Aufgaben für heute – ausgewogen aus allen sechs Lernbereichen.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('mehr Übungszeit'), findsNothing);
  });

  testWidgets('German home names due review as refresh instead of weakness', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    final storage = GermanStorageService(profileId: controller.activeProfileId);
    await storage.setIntroComplete(true);
    await storage.saveHistory(_secureWordHistory(DateTime(2026, 8, 20, 10)));

    await tester.pumpWidget(
      MaterialApp(
        home: GermanHomeScreen(
          controller: controller,
          now: () => DateTime(2026, 9, 18, 10),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('zur Auffrischung wiederholt'), findsOneWidget);
    final reading = find.byKey(const ValueKey('german-domain-reading'));
    await tester.scrollUntilVisible(
      reading,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.descendant(
        of: reading,
        matching: find.textContaining('Wiederholung fällig'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('German home surfaces a pending grade bridge', (tester) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.third;
    final storage = GermanStorageService(profileId: controller.activeProfileId);
    await storage.setIntroComplete(true);
    await storage.saveHistory(_secureWordFamilyGradeTwoHistory());

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
      find.textContaining('wird mit Aufgaben aus Klasse 3 kurz bestätigt'),
      findsOneWidget,
    );
    final vocabulary = find.byKey(const ValueKey('german-domain-vocabulary'));
    await tester.scrollUntilVisible(
      vocabulary,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.descendant(
        of: vocabulary,
        matching: find.textContaining('1 Klassenstufen-Check'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('competency map starts a two-task grade bridge', (tester) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.third;
    final storage = GermanStorageService(profileId: controller.activeProfileId);
    await storage.setIntroComplete(true);
    await storage.saveHistory(_secureWordFamilyGradeTwoHistory());

    await tester.pumpWidget(
      MaterialApp(home: GermanHomeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('german-competency-map')));
    await tester.pumpAndSettle();

    final practiceButton = find.byKey(
      const ValueKey('german-competency-practice-wordFamilies'),
    );
    await tester.scrollUntilVisible(
      practiceButton,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.descendant(
        of: practiceButton,
        matching: find.text('Klasse 3 bestätigen'),
      ),
      findsOneWidget,
    );
    tester.widget<OutlinedButton>(practiceButton).onPressed!.call();
    await tester.pumpAndSettle();

    expect(find.text('Deutsch üben'), findsOneWidget);
    expect(find.text('1 von 2'), findsOneWidget);
  });

  testWidgets('locked upper-grade skill routes to its pending grade bridge', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.third;
    final storage = GermanStorageService(profileId: controller.activeProfileId);
    await storage.setIntroComplete(true);
    await storage.saveHistory(_secureWordFamilyGradeTwoHistory());

    await tester.pumpWidget(
      MaterialApp(home: GermanHomeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('german-competency-map')));
    await tester.pumpAndSettle();

    final compoundButton = find.byKey(
      const ValueKey('german-competency-practice-compoundWords'),
    );
    await tester.scrollUntilVisible(
      compoundButton,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.descendant(
        of: compoundButton,
        matching: find.text('Grundlage üben'),
      ),
      findsOneWidget,
    );
    final compoundCard = find.byKey(
      const ValueKey('german-competency-card-compoundWords'),
    );
    expect(
      find.descendant(
        of: compoundCard,
        matching: find.textContaining('Zuerst: Wortfamilien erkennen'),
      ),
      findsOneWidget,
    );

    tester.widget<OutlinedButton>(compoundButton).onPressed!.call();
    await tester.pumpAndSettle();

    expect(find.text('Deutsch üben'), findsOneWidget);
    expect(find.text('1 von 2'), findsOneWidget);
  });

  testWidgets('German home opens the competency map', (tester) async {
    final controller = AppController();
    await controller.load();
    await GermanStorageService(
      profileId: controller.activeProfileId,
    ).setIntroComplete(true);

    await tester.pumpWidget(
      MaterialApp(home: GermanHomeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('german-competency-map')));
    await tester.pumpAndSettle();

    expect(find.text('Deutsch-Lernlandkarte'), findsOneWidget);
    expect(find.textContaining('sicher'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Laute und Buchstaben verbinden'),
      180,
    );
    expect(find.text('Laute und Buchstaben verbinden'), findsOneWidget);
  });

  testWidgets('German home reloads immediately after profile switch', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    await controller.setGradeLevel(GradeLevel.second);
    final firstId = controller.activeProfileId;
    final firstStorage = GermanStorageService(profileId: firstId);
    await firstStorage.setIntroComplete(true);
    await firstStorage.saveHistory(<GermanSessionResult>[
      _profileSession(taskId: 'first-profile', correct: true),
    ]);

    await controller.createProfile(
      name: 'Zweites Kind',
      grade: GradeLevel.second,
    );
    final secondId = controller.activeProfileId;
    final secondStorage = GermanStorageService(profileId: secondId);
    await secondStorage.setIntroComplete(true);
    await secondStorage.saveHistory(<GermanSessionResult>[
      _profileSession(taskId: 'second-profile', correct: false),
    ]);
    await controller.switchProfile(firstId);

    await tester.pumpWidget(
      MaterialApp(home: GermanHomeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    final firstRecent = find.text('Zuletzt');
    await tester.scrollUntilVisible(
      firstRecent,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('1 von 1 direkt richtig'), findsOneWidget);
    expect(find.textContaining('0 von 1 direkt richtig'), findsNothing);

    await controller.switchProfile(secondId);
    await tester.pumpAndSettle();

    expect(controller.activeProfileName, 'Zweites Kind');
    final secondRecent = find.text('Zuletzt');
    await tester.scrollUntilVisible(
      secondRecent,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('0 von 1 direkt richtig'), findsOneWidget);
    expect(find.textContaining('1 von 1 direkt richtig'), findsNothing);
  });

  testWidgets('running German round stays bound to its start profile', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    await controller.setGradeLevel(GradeLevel.third);
    final firstId = controller.activeProfileId;
    final firstStorage = GermanStorageService(profileId: firstId);
    final bridgeHistory = _secureWordFamilyGradeTwoHistory();
    await firstStorage.setIntroComplete(true);
    await firstStorage.saveHistory(bridgeHistory);

    await controller.createProfile(
      name: 'Anderes Kind',
      grade: GradeLevel.third,
    );
    final secondId = controller.activeProfileId;
    final secondStorage = GermanStorageService(profileId: secondId);
    await secondStorage.setIntroComplete(true);
    await controller.switchProfile(firstId);

    final bridgeTasks = GermanPracticePlanner.buildGradeBridgeRound(
      gradeLevel: GradeLevel.third,
      competencyId: GermanCompetencyId.wordFamilies,
      history: bridgeHistory,
    );
    expect(bridgeTasks, hasLength(2));

    await tester.pumpWidget(
      MaterialApp(home: GermanHomeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('german-competency-map')));
    await tester.pumpAndSettle();
    final practiceButton = find.byKey(
      const ValueKey('german-competency-practice-wordFamilies'),
    );
    await tester.scrollUntilVisible(
      practiceButton,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    tester.widget<OutlinedButton>(practiceButton).onPressed!.call();
    await tester.pumpAndSettle();
    expect(find.text('1 von 2'), findsOneWidget);

    await controller.switchProfile(secondId);
    await tester.pumpAndSettle();

    for (var index = 0; index < bridgeTasks.length; index++) {
      final answer = bridgeTasks[index].acceptedAnswers.first;
      await tester.tap(find.widgetWithText(FilledButton, answer));
      await tester.pumpAndSettle();
    }
    expect(find.text('Runde geschafft'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('german-round-done')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1));

    final firstHistory = await firstStorage.loadHistory();
    final secondHistory = await secondStorage.loadHistory();
    expect(
      firstHistory.where(
        (session) =>
            session.gradeLevel == GradeLevel.third &&
            session.taskResults.length == 2 &&
            session.taskResults.every(
              (result) =>
                  result.competencyId == GermanCompetencyId.wordFamilies,
            ),
      ),
      hasLength(1),
    );
    expect(secondHistory, isEmpty);
    expect(find.text('Hallo Anderes Kind'), findsOneWidget);
  });

  testWidgets('daily German round opens a touch-first training session', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    await GermanStorageService(
      profileId: controller.activeProfileId,
    ).setIntroComplete(true);

    await tester.pumpWidget(
      MaterialApp(home: GermanHomeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('german-daily-round')));
    await tester.pumpAndSettle();

    expect(find.text('Deutsch üben'), findsOneWidget);
    expect(find.text('1 von 12'), findsOneWidget);
  });
  testWidgets('competency map starts targeted six-task practice', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    await GermanStorageService(
      profileId: controller.activeProfileId,
    ).setIntroComplete(true);

    await tester.pumpWidget(
      MaterialApp(home: GermanHomeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('german-competency-map')));
    await tester.pumpAndSettle();
    final practiceButton = find.byKey(
      const ValueKey('german-competency-practice-letterSoundMatch'),
    );
    await tester.scrollUntilVisible(
      practiceButton,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.descendant(of: practiceButton, matching: find.text('Gezielt üben')),
      findsOneWidget,
    );
    tester.widget<OutlinedButton>(practiceButton).onPressed!.call();
    await tester.pumpAndSettle();

    expect(find.text('Deutsch üben'), findsOneWidget);
    expect(find.text('1 von 6'), findsOneWidget);
  });
  testWidgets('German home announces independent reading follow-up', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    final storage = GermanStorageService(profileId: controller.activeProfileId);
    await storage.setIntroComplete(true);
    await storage.saveHistory(<GermanSessionResult>[
      GermanSessionResult(
        gradeLevel: GradeLevel.second,
        startedAt: DateTime(2026, 9, 18, 8),
        finishedAt: DateTime(2026, 9, 18, 8, 2),
        taskResults: const <GermanTaskResult>[
          GermanTaskResult(
            taskId: 'assisted-reading-practice',
            competencyId: GermanCompetencyId.wordRecognition,
            correctFirstTry: true,
            incorrectAttempts: 0,
            responseMs: 900,
            usedReadAloud: true,
          ),
        ],
      ),
    ]);
    expect(controller.accessibilityPreferences.readAloud, isFalse);

    await tester.pumpWidget(
      MaterialApp(
        home: GermanHomeScreen(
          controller: controller,
          now: () => DateTime(2026, 9, 19, 8),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('ohne Vorlesen kurz selbstständig ausprobiert'),
      findsOneWidget,
    );

    final recent = find.text('Zuletzt');
    await tester.scrollUntilVisible(
      recent,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.textContaining(
        '1 mit Vorlesen · selbstständig noch keine Beobachtung',
      ),
      findsOneWidget,
    );
  });

  testWidgets('German home plans independent reading after assisted practice', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    final storage = GermanStorageService(profileId: controller.activeProfileId);
    await storage.setIntroComplete(true);
    await storage.saveHistory(<GermanSessionResult>[
      GermanSessionResult(
        gradeLevel: GradeLevel.second,
        startedAt: DateTime(2026, 9, 18, 8),
        finishedAt: DateTime(2026, 9, 18, 8, 2),
        taskResults: const <GermanTaskResult>[
          GermanTaskResult(
            taskId: 'assisted-reading',
            competencyId: GermanCompetencyId.wordRecognition,
            correctFirstTry: true,
            incorrectAttempts: 0,
            responseMs: 900,
            usedReadAloud: true,
          ),
        ],
      ),
      GermanSessionResult(
        gradeLevel: GradeLevel.second,
        startedAt: DateTime(2026, 9, 18, 9),
        finishedAt: DateTime(2026, 9, 18, 9, 2),
        taskResults: const <GermanTaskResult>[
          GermanTaskResult(
            taskId: 'independent-reading',
            competencyId: GermanCompetencyId.wordRecognition,
            correctFirstTry: true,
            incorrectAttempts: 0,
            responseMs: 900,
          ),
        ],
      ),
    ]);

    expect(controller.accessibilityPreferences.readAloud, isFalse);
    await tester.pumpWidget(
      MaterialApp(
        home: GermanHomeScreen(
          controller: controller,
          now: () => DateTime(2026, 9, 19, 8),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Wörter sicher lesen'), findsOneWidget);
    expect(
      find.textContaining('ohne Vorlesen kurz selbstständig ausprobiert'),
      findsOneWidget,
    );
  });

  testWidgets('German home marks assisted Lerncheck as non-independent', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    final storage = GermanStorageService(profileId: controller.activeProfileId);
    await storage.setIntroComplete(true);
    await storage.saveHistory(<GermanSessionResult>[
      GermanSessionResult(
        gradeLevel: controller.gradeLevel,
        startedAt: DateTime(2026, 9, 18, 8),
        finishedAt: DateTime(2026, 9, 18, 8, 4),
        kind: GermanSessionKind.assessment,
        taskResults: const <GermanTaskResult>[
          GermanTaskResult(
            taskId: 'assisted-assessment',
            competencyId: GermanCompetencyId.wordRecognition,
            correctFirstTry: true,
            incorrectAttempts: 0,
            responseMs: 900,
            usedReadAloud: true,
          ),
        ],
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(home: GermanHomeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    final summary = find.textContaining('Letzter Lerncheck:');
    await tester.scrollUntilVisible(
      summary,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.textContaining(
        '1 mit Vorlesen · selbstständig noch keine Beobachtung',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('Letzter Lerncheck: 1 von 1 direkt richtig · 100 %'),
      findsNothing,
    );
  });

  testWidgets('old-grade Lerncheck is not shown as current snapshot', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.third;
    final storage = GermanStorageService(profileId: controller.activeProfileId);
    await storage.setIntroComplete(true);
    await storage.saveHistory(<GermanSessionResult>[
      GermanSessionResult(
        gradeLevel: GradeLevel.second,
        startedAt: DateTime(2026, 9, 17, 8),
        finishedAt: DateTime(2026, 9, 17, 8, 5),
        kind: GermanSessionKind.assessment,
        taskResults: const <GermanTaskResult>[
          GermanTaskResult(
            taskId: 'old-assessment',
            competencyId: GermanCompetencyId.wordRecognition,
            correctFirstTry: true,
            incorrectAttempts: 0,
            responseMs: 900,
          ),
        ],
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(home: GermanHomeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    final assessmentCard = find.textContaining(
      'Eine kurze Momentaufnahme über alle Deutsch-Lernbereiche',
    );
    await tester.scrollUntilVisible(
      assessmentCard,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(assessmentCard, findsOneWidget);
    expect(find.textContaining('Letzter Lerncheck:'), findsNothing);

    final recent = find.text('Zuletzt');
    await tester.scrollUntilVisible(
      recent,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.textContaining('Klasse 2 · 100 % beim ersten Versuch'),
      findsOneWidget,
    );
  });

  testWidgets('German home starts a support-free Lerncheck', (tester) async {
    final controller = AppController();
    await controller.load();
    await GermanStorageService(
      profileId: controller.activeProfileId,
    ).setIntroComplete(true);

    await tester.pumpWidget(
      MaterialApp(home: GermanHomeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    final button = find.byKey(const ValueKey('german-assessment-start'));
    await tester.scrollUntilVisible(
      button,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Deutsch-Lerncheck'), findsOneWidget);
    expect(find.text('1 von 12'), findsOneWidget);
  });

  testWidgets('first German visit offers Lerncheck or direct practice', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    final storage = GermanStorageService(profileId: controller.activeProfileId);
    await storage.setIntroComplete(false);

    await tester.pumpWidget(
      MaterialApp(home: GermanHomeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Willkommen bei Deutsch'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('german-intro-assessment')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('german-intro-skip')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('german-intro-skip')));
    await tester.pumpAndSettle();

    expect(find.text('Meine Deutsch-Runde'), findsOneWidget);
    expect(await storage.loadIntroComplete(), isTrue);
  });

  testWidgets('first German visit can start the adaptive Lerncheck directly', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    final storage = GermanStorageService(profileId: controller.activeProfileId);
    await storage.setIntroComplete(false);

    await tester.pumpWidget(
      MaterialApp(home: GermanHomeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('german-intro-assessment')));
    await tester.pumpAndSettle();

    expect(find.text('Deutsch-Lerncheck'), findsOneWidget);
    expect(find.text('1 von 12'), findsOneWidget);
    expect(await storage.loadIntroComplete(), isTrue);
  });
}

GermanSessionResult _profileSession({
  required String taskId,
  required bool correct,
  bool usedReadAloud = false,
}) => GermanSessionResult(
  gradeLevel: GradeLevel.second,
  startedAt: DateTime(2026, 9, 18, 10),
  finishedAt: DateTime(2026, 9, 18, 10, 1),
  taskResults: <GermanTaskResult>[
    GermanTaskResult(
      taskId: taskId,
      competencyId: GermanCompetencyId.wordRecognition,
      correctFirstTry: correct,
      incorrectAttempts: correct ? 0 : 1,
      responseMs: 900,
      usedReadAloud: usedReadAloud,
    ),
  ],
);

List<GermanSessionResult> _secureWordFamilyGradeTwoHistory() {
  final taskIds =
      GermanTaskCatalog.forCompetency(GermanCompetencyId.wordFamilies)
          .where((task) => task.recommendedFromGrade == GradeLevel.second)
          .map((task) => task.id)
          .take(3)
          .toList(growable: false);
  return <GermanSessionResult>[
    GermanSessionResult(
      gradeLevel: GradeLevel.second,
      startedAt: DateTime(2026, 9, 17, 9, 59),
      finishedAt: DateTime(2026, 9, 17, 10),
      taskResults: <GermanTaskResult>[
        for (final taskId in taskIds.take(2))
          GermanTaskResult(
            taskId: taskId,
            competencyId: GermanCompetencyId.wordFamilies,
            correctFirstTry: true,
            incorrectAttempts: 0,
            responseMs: 900,
          ),
      ],
    ),
    GermanSessionResult(
      gradeLevel: GradeLevel.second,
      startedAt: DateTime(2026, 9, 17, 10, 59),
      finishedAt: DateTime(2026, 9, 17, 11),
      taskResults: <GermanTaskResult>[
        GermanTaskResult(
          taskId: taskIds.last,
          competencyId: GermanCompetencyId.wordFamilies,
          correctFirstTry: true,
          incorrectAttempts: 0,
          responseMs: 900,
        ),
      ],
    ),
  ];
}

List<GermanSessionResult> _secureWordHistory(DateTime firstFinished) =>
    <GermanSessionResult>[
      GermanSessionResult(
        gradeLevel: GradeLevel.second,
        startedAt: firstFinished.subtract(const Duration(minutes: 1)),
        finishedAt: firstFinished,
        taskResults: const <GermanTaskResult>[
          GermanTaskResult(
            taskId: 'word-a',
            competencyId: GermanCompetencyId.wordRecognition,
            correctFirstTry: true,
            incorrectAttempts: 0,
            responseMs: 900,
          ),
          GermanTaskResult(
            taskId: 'word-b',
            competencyId: GermanCompetencyId.wordRecognition,
            correctFirstTry: true,
            incorrectAttempts: 0,
            responseMs: 900,
          ),
        ],
      ),
      GermanSessionResult(
        gradeLevel: GradeLevel.second,
        startedAt: firstFinished.add(const Duration(hours: 1)),
        finishedAt: firstFinished.add(const Duration(hours: 1, minutes: 1)),
        taskResults: const <GermanTaskResult>[
          GermanTaskResult(
            taskId: 'word-c',
            competencyId: GermanCompetencyId.wordRecognition,
            correctFirstTry: true,
            incorrectAttempts: 0,
            responseMs: 900,
          ),
        ],
      ),
    ];
