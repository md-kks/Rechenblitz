import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/cube_net.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/structured_exercise.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/models/training_session_progress.dart';
import 'package:rechenblitz/screens/curriculum_training_screen.dart';
import 'package:rechenblitz/screens/structured_training_screen.dart';
import 'package:rechenblitz/screens/training_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Struktur- und Curriculumaufgaben bleiben exakt serialisierbar', () {
    const structured = StructuredExercise(
      mode: TrainingMode.wordProblems,
      prompt: 'Welche Rechnung passt?',
      answer: 1,
      hint: 'Achte auf die Beziehung.',
      key: 'story:operation:test',
      choices: ['12 + 4', '12 - 4'],
      answerSuffix: ' Aufgaben',
      maxAnswerValue: 1,
      representation: ExerciseRepresentation.equalGroups,
      representationA: 3,
      representationB: 4,
      checkpoints: [
        ExerciseCheckpoint(
          key: 'storyOperation',
          question: 'Welche Rechenart brauchst du?',
          choices: ['Plus', 'Minus'],
          correctChoice: 1,
          competencyId: MicroCompetencyId.wordProblemOperation,
        ),
      ],
    );
    final restoredStructured = decodeStructuredExercise(
      encodeStructuredExercise(structured),
    );
    expect(restoredStructured.key, structured.key);
    expect(restoredStructured.choices, structured.choices);
    expect(restoredStructured.representationA, 3);
    expect(restoredStructured.checkpoints.single.key, 'storyOperation');
    expect(
      restoredStructured.checkpoints.single.competencyId,
      MicroCompetencyId.wordProblemOperation,
    );

    const a = GridCell(0, 0);
    const b = GridCell(1, 0);
    final curriculum = CurriculumExercise(
      mode: TrainingMode.dataCharts,
      prompt: 'Lies das Diagramm.',
      answer: 7,
      hint: 'Lies die Höhe ab.',
      key: 'chart:test',
      choices: ['5', '7', '9'],
      bars: [CurriculumBar('A', 5), CurriculumBar('B', 7)],
      cubeNetCells: [a, b],
      cubeNetLabels: {a: 'A', b: 'B'},
    );
    final restoredCurriculum = decodeCurriculumExercise(
      encodeCurriculumExercise(curriculum),
    );
    expect(restoredCurriculum.key, curriculum.key);
    expect(restoredCurriculum.bars!.last.value, 7);
    expect(restoredCurriculum.cubeNetCells, [a, b]);
    expect(restoredCurriculum.cubeNetLabels![b], 'B');
  });

  test('Kern-Trainingsentwurf round-tript profilbezogen', () async {
    final storage = StorageService();
    await storage.initializeProfiles();
    final now = DateTime(2026, 9, 17, 10);
    final draft = CoreTrainingSessionProgress(
      kind: CoreTrainingKind.fact,
      mode: TrainingMode.practice,
      targetTasks: 5,
      targetCompetency: MicroCompetencyId.additionNoBridge,
      reviewEmphasis: true,
      adaptiveLength: true,
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      startedAt: now,
      updatedAt: now,
      currentTask: const {'key': 'plus:2:3'},
      completed: 2,
      incorrectAttempts: 1,
      correctFirstTry: 1,
      wrongOnCurrent: 1,
      assistanceVisible: true,
      usedHelp: true,
      useTouchInput: false,
      helpLevel: 1,
      taskFirstAttemptRecorded: true,
      responseTimes: const [1200, 1600],
    );

    await storage.saveCoreTrainingSession(draft);
    final restored = await storage.loadCoreTrainingSession();
    expect(restored, isNotNull);
    expect(restored!.currentTask['key'], 'plus:2:3');
    expect(restored.useTouchInput, isFalse);
    expect(restored.completed, 2);
    expect(restored.taskFirstAttemptRecorded, isTrue);
    expect(restored.responseTimes, [1200, 1600]);

    await storage.setActiveProfileId('zweites-profil');
    expect(await storage.loadCoreTrainingSession(), isNull);
    await storage.setActiveProfileId('default');
    expect(
      (await storage.loadCoreTrainingSession())?.currentTask['key'],
      'plus:2:3',
    );
  });

  test('Kern-Trainingsentwurf verfällt und bindet sich an den Lernkontext', () {
    final now = DateTime(2026, 9, 17, 10);
    final draft = CoreTrainingSessionProgress(
      kind: CoreTrainingKind.fact,
      mode: TrainingMode.practice,
      targetTasks: 4,
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      startedAt: now.subtract(const Duration(hours: 2)),
      updatedAt: now.subtract(const Duration(hours: 2)),
      currentTask: const {'key': 'plus:2:3'},
    );

    bool compatible({
      DateTime? at,
      NumberRangeLevel range = NumberRangeLevel.hundred,
    }) => draft.isCompatible(
      kind: CoreTrainingKind.fact,
      mode: TrainingMode.practice,
      targetTasks: 4,
      targetCompetency: null,
      reviewEmphasis: false,
      transferEmphasis: false,
      fluencyEmphasis: false,
      scaffoldFading: false,
      adaptiveLength: false,
      gradeLevel: GradeLevel.second,
      numberRange: range,
      teacherAssignmentActive: false,
      timeLimit: null,
      now: at ?? now,
    );

    expect(compatible(), isTrue);
    expect(compatible(range: NumberRangeLevel.twenty), isFalse);
    expect(compatible(at: now.add(const Duration(days: 2))), isFalse);
  });

  testWidgets('Grundrechnen setzt exakt die gespeicherte Aufgabe fort', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    final fact = MathFact(a: 2, b: 3, operation: MathOperation.plus);
    controller.facts = [fact];
    final now = DateTime.now();
    controller.coreTrainingSessionProgress = CoreTrainingSessionProgress(
      kind: CoreTrainingKind.fact,
      mode: TrainingMode.practice,
      targetTasks: 4,
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      startedAt: now.subtract(const Duration(minutes: 2)),
      updatedAt: now,
      currentTask: {'key': fact.key},
      completed: 1,
      incorrectAttempts: 1,
      wrongOnCurrent: 1,
      taskFirstAttemptRecorded: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TrainingScreen(
          controller: controller,
          mode: TrainingMode.practice,
          targetTasks: 4,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Aufgabe 2 von 4 · fortgesetzt'), findsOneWidget);
    expect(find.text('2 + 3 = ?'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Strukturtraining setzt Aufgabe und Hilfe exakt fort', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    const exercise = StructuredExercise(
      mode: TrainingMode.money,
      prompt: 'Du hast 8 Euro und gibst 3 Euro aus. Wie viel bleibt?',
      answer: 5,
      hint: 'Es wird weniger.',
      key: 'money:test:8:3',
      maxAnswerValue: 10,
    );
    final now = DateTime.now();
    controller.coreTrainingSessionProgress = CoreTrainingSessionProgress(
      kind: CoreTrainingKind.structured,
      mode: TrainingMode.money,
      targetTasks: 3,
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      startedAt: now,
      updatedAt: now,
      currentTask: encodeStructuredExercise(exercise),
      completed: 1,
      wrongOnCurrent: 2,
      assistanceVisible: true,
      helpLevel: 1,
      taskFirstAttemptRecorded: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StructuredTrainingScreen(
          controller: controller,
          mode: TrainingMode.money,
          targetTasks: 3,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Aufgabe 2 von 3 · fortgesetzt'), findsOneWidget);
    expect(find.text(exercise.prompt), findsOneWidget);
    expect(find.byKey(ValueKey('guide:${exercise.key}:1')), findsOneWidget);
  });

  testWidgets('Curriculumtraining setzt dieselbe Aufgabe fort', (tester) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.fourth;
    controller.numberRange = NumberRangeLevel.million;
    const exercise = CurriculumExercise(
      mode: TrainingMode.rounding,
      prompt: 'Runde 4387 auf Hunderter.',
      answer: 4400,
      hint: 'Schau auf die Zehnerstelle.',
      key: 'round:test:4387:100',
      maxAnswerValue: 10000,
    );
    final now = DateTime.now();
    controller.coreTrainingSessionProgress = CoreTrainingSessionProgress(
      kind: CoreTrainingKind.curriculum,
      mode: TrainingMode.rounding,
      targetTasks: 4,
      gradeLevel: GradeLevel.fourth,
      numberRange: NumberRangeLevel.million,
      startedAt: now,
      updatedAt: now,
      currentTask: encodeCurriculumExercise(exercise),
      completed: 2,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.rounding,
          targetTasks: 4,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Aufgabe 3 von 4 · fortgesetzt'), findsOneWidget);
    expect(find.text(exercise.prompt), findsOneWidget);
  });

  testWidgets(
    'Beantwortete letzte Aufgabe wird nach Neustart nur abgeschlossen',
    (tester) async {
      final controller = AppController();
      await controller.load();
      controller.gradeLevel = GradeLevel.second;
      controller.numberRange = NumberRangeLevel.hundred;
      final fact = MathFact(a: 4, b: 2, operation: MathOperation.plus);
      controller.facts = [fact];
      final started = DateTime.now().subtract(const Duration(minutes: 1));
      controller.coreTrainingSessionProgress = CoreTrainingSessionProgress(
        kind: CoreTrainingKind.fact,
        mode: TrainingMode.practice,
        targetTasks: 1,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        startedAt: started,
        updatedAt: DateTime.now(),
        currentTask: {'key': fact.key},
        completed: 1,
        correctFirstTry: 1,
        responseTimes: const [900],
        taskResolved: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TrainingScreen(
            controller: controller,
            mode: TrainingMode.practice,
            targetTasks: 1,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(controller.history, hasLength(1));
      expect(controller.history.single.startedAt, started);
      expect(controller.coreTrainingSessionProgress, isNull);
      expect(find.text('Runde geschafft!'), findsOneWidget);
    },
  );
  testWidgets('Tempotest übernimmt nur die aktive Zeit vor der Unterbrechung', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    final fact = MathFact(a: 2, b: 3, operation: MathOperation.plus);
    controller.facts = [fact];
    final now = DateTime.now();
    controller.coreTrainingSessionProgress = CoreTrainingSessionProgress(
      kind: CoreTrainingKind.fact,
      mode: TrainingMode.tempo,
      targetTasks: 5,
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      timeLimitMs: const Duration(seconds: 10).inMilliseconds,
      startedAt: now.subtract(const Duration(minutes: 20)),
      updatedAt: now,
      currentTask: {'key': fact.key},
      elapsedActiveMs: const Duration(seconds: 3).inMilliseconds,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TrainingScreen(
          controller: controller,
          mode: TrainingMode.tempo,
          targetTasks: 5,
          timeLimit: const Duration(seconds: 10),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('0:07'), findsOneWidget);
    expect(find.textContaining('fortgesetzt'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
