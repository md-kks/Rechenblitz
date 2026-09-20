import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/teacher_assignment.dart';
import 'package:rechenblitz/models/teacher_assignment_result.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/parent_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

TrainingSessionResult _session({
  required int index,
  List<TrainingAttemptReview>? reviews,
}) => TrainingSessionResult(
  mode: TrainingMode.practice,
  startedAt: DateTime(2026, 9, 20, 9, index % 60),
  finishedAt: DateTime(2026, 9, 20, 9, (index + 5) % 60),
  total: 5,
  correctFirstTry: reviews?.isEmpty == true ? 5 : 4,
  incorrectAttempts: reviews?.isEmpty == true ? 0 : 1,
  plusCorrect: 4,
  plusTotal: 5,
  minusCorrect: 0,
  minusTotal: 0,
  averageResponseMs: 1800,
  numberRange: NumberRangeLevel.twenty,
  gradeLevel: GradeLevel.second,
  starsEarned: 2,
  attemptReviews: reviews,
);
const _review = TrainingAttemptReview(
  taskNumber: 3,
  taskKey: 'plus:8:7',
  prompt: '8 + 7 = ?',
  correctAnswer: '15',
  firstAnswer: '14',
  wrongAnswerAttempts: 2,
  usedHelp: true,
  checkpointQuestion: 'Wie viel fehlt bis 10?',
  checkpointFirstAnswer: '3',
  checkpointCorrectAnswer: '2',
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'Sitzungsverlauf speichert konkrete Rundenrückschau rückwärtskompatibel',
    () {
      final original = _session(index: 5, reviews: const [_review]);
      final raw =
          jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>;
      final restored = TrainingSessionResult.fromJson(raw);

      expect(restored.attemptReviews, hasLength(1));
      expect(restored.attemptReviews!.single.taskNumber, 3);
      expect(restored.attemptReviews!.single.firstAnswer, '14');
      expect(restored.attemptReviews!.single.correctAnswer, '15');
      expect(restored.attemptReviews!.single.wrongAnswerAttempts, 2);
      expect(restored.attemptReviews!.single.usedHelp, isTrue);
      expect(restored.attemptReviews!.single.checkpointFirstAnswer, '3');
      expect(restored.attemptReviews!.single.checkpointCorrectAnswer, '2');

      raw.remove('attemptReviews');
      expect(TrainingSessionResult.fromJson(raw).attemptReviews, isNull);
    },
  );
  test('beschädigter Review-Eintrag verwirft nicht den ganzen Verlauf', () {
    final raw = _session(index: 6, reviews: const [_review]).toJson();
    raw['attemptReviews'] = <dynamic>[
      _review.toJson(),
      <String, dynamic>{
        'taskNumber': 0,
        'taskKey': '',
        'prompt': '',
        'correctAnswer': '',
      },
    ];

    final restored = TrainingSessionResult.fromJson(raw);

    expect(restored.attemptReviews, hasLength(1));
    expect(restored.attemptReviews!.single.taskKey, 'plus:8:7');
  });

  test(
    'nur die 50 jüngsten Runden behalten Detailantworten im Speicher',
    () async {
      final storage = StorageService();
      await storage.initializeProfiles();
      final history = <TrainingSessionResult>[
        for (var index = 0; index < 52; index++)
          _session(index: index, reviews: const [_review]),
      ];

      await storage.saveHistory(history);
      final restored = await storage.loadHistory();

      expect(restored, hasLength(52));
      expect(
        restored.take(50).every((entry) => entry.attemptReviews != null),
        isTrue,
      );
      expect(restored[50].attemptReviews, isNull);
      expect(restored[51].attemptReviews, isNull);
    },
  );
  test('Lehrer-QR übernimmt keine konkrete lokale Aufgabenrückschau', () {
    const assignment = TeacherAssignment(
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.twenty,
      mode: TrainingMode.practice,
      tasks: 5,
      methods: MethodPreferences(),
    );
    final session = _session(index: 7, reviews: const [_review]);
    final result = TeacherAssignmentResult.fromSession(
      assignment: assignment,
      session: session,
      observations: const <MicroCompetencyObservation>[],
    );
    final raw = jsonEncode(result.toJson());

    expect(raw, isNot(contains('attemptReviews')));
    expect(raw, isNot(contains('8 + 7')));
    expect(raw, isNot(contains('14')));
    expect(result.correctFirstTry, session.correctFirstTry);
    expect(result.incorrectAttempts, session.incorrectAttempts);
  });

  testWidgets('Elternbereich zeigt erste und richtige Antwort später erneut', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.history = <TrainingSessionResult>[
      _session(index: 5, reviews: const [_review]),
    ];

    await tester.pumpWidget(
      MaterialApp(home: ParentScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    final section = find.text('Letzte Runden im Detail');
    await tester.scrollUntilVisible(
      section,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(section, findsOneWidget);

    final tile = find.byKey(
      ValueKey(
        'parent-round-review-'
        '${controller.history.single.startedAt.millisecondsSinceEpoch}',
      ),
    );
    await tester.scrollUntilVisible(
      tile,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(find.text('Aufgabe 3: 8 + 7 = ?'), findsOneWidget);
    expect(find.text('Erster Versuch: 14'), findsOneWidget);
    expect(
      find.text('2 Fehlversuche vor der richtigen Lösung'),
      findsOneWidget,
    );
    expect(find.text('Mit Hilfe gelöst'), findsOneWidget);
    expect(find.text('Richtig: 15'), findsOneWidget);
    expect(
      find.text('Zwischenschritt: Wie viel fehlt bis 10?'),
      findsOneWidget,
    );
    expect(find.text('Erster Versuch im Schritt: 3'), findsOneWidget);
    expect(find.text('Richtig im Schritt: 2'), findsOneWidget);
  });

  testWidgets('Eltern-Rundenreview bleibt bei 200 Prozent Schrift stabil', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final controller = AppController();
    await controller.load();
    controller.history = <TrainingSessionResult>[
      _session(index: 8, reviews: const [_review]),
    ];

    await tester.pumpWidget(
      MaterialApp(home: ParentScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    final section = find.text('Letzte Runden im Detail');
    await tester.scrollUntilVisible(
      section,
      700,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);

    final tile = find.byKey(
      ValueKey(
        'parent-round-review-'
        '${controller.history.single.startedAt.millisecondsSinceEpoch}',
      ),
    );
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Erster Versuch: 14'), findsOneWidget);
    expect(find.text('Richtig: 15'), findsOneWidget);
  });
}
