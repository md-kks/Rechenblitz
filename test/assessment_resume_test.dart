import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/assessment.dart';
import 'package:rechenblitz/models/learner_profile.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/assessment_screen.dart';
import 'package:rechenblitz/screens/learning_start_screen.dart';
import 'package:rechenblitz/screens/settings_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'Lerncheck-Entwurf roundtript vollständig und verfällt nach 24 Stunden',
    () {
      final now = DateTime(2026, 9, 17, 10);
      final tasks = _tasks();
      final progress = AssessmentProgress(
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        tasks: tasks,
        taskResults: <AssessmentTaskResult>[
          AssessmentTaskResult(
            mode: tasks.first.mode,
            taskKey: tasks.first.taskKey,
            correct: true,
            fact: tasks.first.fact,
            targetCompetency: tasks.first.targetCompetency,
          ),
        ],
        nextIndex: 1,
        startedAt: now.subtract(const Duration(minutes: 5)),
        updatedAt: now,
      );

      final restored = AssessmentProgress.fromJson(progress.toJson());
      expect(restored.tasks, hasLength(3));
      expect(restored.tasks.first.fact?.key, tasks.first.fact?.key);
      expect(restored.tasks[1].choices, tasks[1].choices);
      expect(restored.taskResults.single.correct, isTrue);
      expect(
        restored.isCompatible(
          grade: GradeLevel.second,
          range: NumberRangeLevel.hundred,
          currentState: GermanState.thuringia,
          now: now.add(const Duration(hours: 23)),
        ),
        isTrue,
      );
      expect(
        restored.isCompatible(
          grade: GradeLevel.second,
          range: NumberRangeLevel.hundred,
          currentState: GermanState.thuringia,
          now: now.add(const Duration(hours: 25)),
        ),
        isFalse,
      );
      expect(
        restored.isCompatible(
          grade: GradeLevel.third,
          range: NumberRangeLevel.hundred,
          currentState: GermanState.thuringia,
          now: now,
        ),
        isFalse,
      );
    },
  );

  test(
    'beschädigter Lerncheck-Entwurf blockiert den App-Start nicht',
    () async {
      final storage = StorageService();
      await storage.initializeProfiles();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'profile:default:assessment_progress_v1',
        '{defekt',
      );
      expect(await storage.loadAssessmentProgress(), isNull);
    },
  );

  test('Lerncheck-Entwürfe bleiben zwischen Profilen getrennt', () async {
    final storage = StorageService();
    final profiles = await storage.initializeProfiles();
    final now = DateTime.now();
    final progress = _progress(now: now);
    await storage.saveAssessmentProgress(progress);

    final second = LearnerProfile(
      id: 'assessment-second',
      name: 'Zweites Profil',
      gradeLevel: GradeLevel.second,
      createdAt: now,
    );
    await storage.saveProfiles(<LearnerProfile>[...profiles, second]);
    await storage.setActiveProfileId(second.id);
    expect(await storage.loadAssessmentProgress(), isNull);

    await storage.setActiveProfileId('default');
    expect((await storage.loadAssessmentProgress())?.nextIndex, 1);
  });

  test('inkompatibler oder alter Entwurf wird beim Laden entfernt', () async {
    final storage = StorageService();
    await storage.initializeProfiles();
    final old = _progress(
      now: DateTime.now().subtract(const Duration(days: 2)),
    );
    await storage.saveAssessmentProgress(old);

    final controller = AppController(storage: storage);
    await controller.load();
    expect(controller.assessmentProgress, isNull);
    expect(await storage.loadAssessmentProgress(), isNull);
  });

  testWidgets('Lerncheck setzt nach Neustart bei der nächsten Aufgabe fort', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    final generator = _FixedAssessmentGenerator(_tasks());

    await tester.pumpWidget(
      MaterialApp(
        home: AssessmentScreen(controller: controller, generator: generator),
      ),
    );
    expect(find.text('Aufgabe 1 von 3'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('assessment-dont-know')));
    await tester.pumpAndSettle();
    expect(controller.assessmentProgress?.nextIndex, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final reloaded = AppController();
    await reloaded.load();
    expect(reloaded.resumableAssessment()?.nextIndex, 1);

    await tester.pumpWidget(
      MaterialApp(
        home: AssessmentScreen(
          controller: reloaded,
          generator: _FixedAssessmentGenerator(_tasks().reversed.toList()),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Aufgabe 2 von 3'), findsOneWidget);
    expect(find.text(_tasks()[1].prompt), findsOneWidget);
    expect(find.byKey(const ValueKey('assessment-resumed')), findsOneWidget);
    expect(find.textContaining('1 Aufgaben schon beantwortet'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('assessment-dont-know')));
    await tester.pumpAndSettle();
    expect(reloaded.assessmentProgress?.nextIndex, 2);
    await tester.tap(find.byKey(const ValueKey('assessment-dont-know')));
    await tester.pumpAndSettle();

    expect(find.text('Lerncheck geschafft!'), findsOneWidget);
    expect(reloaded.assessmentProgress, isNull);
    final verifyStorage = StorageService();
    await verifyStorage.initializeProfiles();
    expect(await verifyStorage.loadAssessmentProgress(), isNull);
    final assessmentSessions = reloaded.history.where(
      (entry) => entry.isAssessment,
    );
    expect(
      assessmentSessions.fold<int>(0, (sum, entry) => sum + entry.total),
      3,
    );
  });

  test(
    'Klassen-, Zahlenraum-, Skip- und Resetwechsel verwerfen den Entwurf',
    () async {
      final controller = AppController();
      await controller.load();

      await controller.saveAssessmentProgress(_progress(now: DateTime.now()));
      await controller.setNumberRange(NumberRangeLevel.twenty);
      expect(controller.assessmentProgress, isNull);

      await controller.saveAssessmentProgress(
        _progress(
          now: DateTime.now(),
          range: controller.numberRange,
          grade: controller.gradeLevel,
        ),
      );
      await controller.setGradeLevel(GradeLevel.third);
      expect(controller.assessmentProgress, isNull);

      await controller.saveAssessmentProgress(
        _progress(
          now: DateTime.now(),
          range: controller.numberRange,
          grade: controller.gradeLevel,
        ),
      );
      await controller.completeOnboardingWithoutAssessment();
      expect(controller.assessmentProgress, isNull);

      await controller.saveAssessmentProgress(
        _progress(
          now: DateTime.now(),
          range: controller.numberRange,
          grade: controller.gradeLevel,
        ),
      );
      await controller.resetProgress();
      expect(controller.assessmentProgress, isNull);
    },
  );

  testWidgets('fortgesetzter Lerncheck kann bewusst neu gestartet werden', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    await controller.saveAssessmentProgress(
      _progress(
        now: DateTime.now(),
        range: controller.numberRange,
        grade: controller.gradeLevel,
      ),
    );
    final freshTasks = _tasks().reversed.toList(growable: false);

    await tester.pumpWidget(
      MaterialApp(
        home: AssessmentScreen(
          controller: controller,
          generator: _FixedAssessmentGenerator(freshTasks),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Aufgabe 2 von 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('assessment-restart')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('assessment-restart')));
    await tester.pumpAndSettle();
    expect(find.text('Lerncheck neu starten?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('assessment-restart-confirm')));
    await tester.pumpAndSettle();

    expect(controller.assessmentProgress, isNull);
    expect(find.text('Aufgabe 1 von 3'), findsOneWidget);
    expect(find.text(freshTasks.first.prompt), findsOneWidget);
    expect(find.byKey(const ValueKey('assessment-resumed')), findsNothing);
  });

  testWidgets(
    'Onboarding und Einstellungen zeigen einen fortsetzbaren Lerncheck',
    (tester) async {
      final controller = AppController();
      await controller.load();
      final progress = _progress(
        now: DateTime.now(),
        range: controller.numberRange,
        grade: controller.gradeLevel,
      );
      await controller.saveAssessmentProgress(progress);

      await tester.pumpWidget(
        MaterialApp(home: LearningStartScreen(controller: controller)),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('learning-start-assessment')),
        findsOneWidget,
      );
      expect(find.text('Lerncheck fortsetzen'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('learning-start-assessment-start')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Aufgabe 2 von 3'), findsOneWidget);
      expect(find.byKey(const ValueKey('assessment-resumed')), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpWidget(
        MaterialApp(home: SettingsScreen(controller: controller)),
      );
      await tester.pump();
      expect(find.text('Lerncheck fortsetzen'), findsOneWidget);
      expect(find.text('1 von 3 Aufgaben beantwortet'), findsOneWidget);
    },
  );
}

List<AssessmentTask> _tasks() => <AssessmentTask>[
  AssessmentTask(
    mode: TrainingMode.practice,
    taskKey: 'plus:7:5',
    prompt: '7 + 5 = ?',
    answer: 12,
    maxAnswerValue: 20,
    fact: MathFact(a: 7, b: 5, operation: MathOperation.plus),
  ),
  const AssessmentTask(
    mode: TrainingMode.clock,
    taskKey: 'clock:3:30',
    prompt: 'Welche Uhrzeit zeigt die Uhr?',
    answer: 1,
    maxAnswerValue: 3,
    choices: <String>['3:00', '3:30', '6:30'],
    clockHour: 3,
    clockMinute: 30,
  ),
  const AssessmentTask(
    mode: TrainingMode.numberFriends,
    taskKey: 'plus:6:4',
    prompt: '6 + ? = 10',
    answer: 4,
    maxAnswerValue: 10,
  ),
];

AssessmentProgress _progress({
  required DateTime now,
  GradeLevel grade = GradeLevel.second,
  NumberRangeLevel range = NumberRangeLevel.hundred,
}) {
  final tasks = _tasks();
  return AssessmentProgress(
    gradeLevel: grade,
    numberRange: range,
    tasks: tasks,
    taskResults: <AssessmentTaskResult>[
      AssessmentTaskResult(
        mode: tasks.first.mode,
        taskKey: tasks.first.taskKey,
        correct: false,
        fact: tasks.first.fact,
      ),
    ],
    nextIndex: 1,
    startedAt: now.subtract(const Duration(minutes: 2)),
    updatedAt: now,
  );
}

class _FixedAssessmentGenerator extends AssessmentGenerator {
  _FixedAssessmentGenerator(this.tasks);

  final List<AssessmentTask> tasks;

  @override
  List<AssessmentTask> generate({
    required GradeLevel grade,
    required NumberRangeLevel range,
    GermanState state = GermanState.thuringia,
  }) => List<AssessmentTask>.from(tasks);
}
