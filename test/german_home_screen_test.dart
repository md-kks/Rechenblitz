import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
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
