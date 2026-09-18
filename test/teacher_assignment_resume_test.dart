import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/teacher_assignment.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/models/training_session_progress.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const assignment = TeacherAssignment(
    gradeLevel: GradeLevel.second,
    numberRange: NumberRangeLevel.twenty,
    mode: TrainingMode.practice,
    tasks: 8,
    targetCompetency: MicroCompetencyId.additionTenBridge,
    methods: MethodPreferences(addition: AdditionStrategy.compensate),
  );

  test(
    'Lehrerauftrag und Schulmethode überleben einen Prozessneustart',
    () async {
      final first = AppController();
      await first.load();
      final now = DateTime.now();
      final startedAt = now.subtract(const Duration(minutes: 7));
      final fact = MathFact(a: 8, b: 7, operation: MathOperation.plus);

      await first.beginTeacherAssignment(assignment, startedAt: startedAt);
      await first.saveCoreTrainingSession(
        CoreTrainingSessionProgress(
          kind: CoreTrainingKind.fact,
          mode: TrainingMode.practice,
          targetTasks: 8,
          targetCompetency: MicroCompetencyId.additionTenBridge,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.twenty,
          teacherAssignmentActive: true,
          teacherAssignmentId: assignment.assignmentId,
          startedAt: startedAt,
          updatedAt: now,
          currentTask: {'key': fact.key},
          completed: 3,
        ),
      );

      final restarted = AppController();
      await restarted.load();

      expect(restarted.hasTeacherAssignment, isFalse);
      expect(restarted.hasResumableTeacherAssignment, isTrue);
      expect(
        restarted.resumableTeacherAssignment?.assignmentId,
        assignment.assignmentId,
      );
      expect(restarted.resumableTeacherAssignmentStartedAt, startedAt);
      expect(restarted.effectiveNumberRange, restarted.numberRange);
      expect(
        restarted.resumableTeacherAssignment?.methods.addition,
        AdditionStrategy.compensate,
      );
      expect(restarted.coreTrainingSessionProgress, isNotNull);
      expect(
        restarted.resumableTeacherAssignmentSession(
          now: now.add(const Duration(seconds: 1)),
        ),
        isNotNull,
      );

      await restarted.activateResumableTeacherAssignment();
      expect(restarted.hasTeacherAssignment, isTrue);
      expect(restarted.hasResumableTeacherAssignment, isFalse);
      expect(restarted.activeTeacherAssignmentStartedAt, startedAt);
      expect(restarted.effectiveNumberRange, NumberRangeLevel.twenty);
      expect(
        restarted.effectiveMethodPreferences.addition,
        AdditionStrategy.compensate,
      );
      expect(
        restarted.resumableCoreTrainingSession(
          kind: CoreTrainingKind.fact,
          mode: TrainingMode.practice,
          targetTasks: 8,
          targetCompetency: MicroCompetencyId.additionTenBridge,
          reviewEmphasis: false,
          transferEmphasis: false,
          fluencyEmphasis: false,
          scaffoldFading: false,
          adaptiveLength: false,
          timeLimit: null,
          now: now.add(const Duration(seconds: 1)),
        ),
        isNotNull,
      );
    },
  );

  test(
    'persistierter Auftrag ohne Lehrerentwurf lässt normalen Entwurf unangetastet',
    () async {
      final first = AppController();
      await first.load();
      final now = DateTime.now();
      final fact = MathFact(a: 6, b: 4, operation: MathOperation.plus);
      final profileRange = first.numberRange;

      await first.saveCoreTrainingSession(
        CoreTrainingSessionProgress(
          kind: CoreTrainingKind.fact,
          mode: TrainingMode.practice,
          targetTasks: 10,
          gradeLevel: GradeLevel.second,
          numberRange: profileRange,
          startedAt: now.subtract(const Duration(minutes: 4)),
          updatedAt: now,
          currentTask: {'key': fact.key},
          completed: 2,
        ),
      );
      await first.beginTeacherAssignment(
        assignment,
        startedAt: now.subtract(const Duration(seconds: 1)),
      );

      final restarted = AppController();
      await restarted.load();

      expect(restarted.hasTeacherAssignment, isFalse);
      expect(restarted.hasResumableTeacherAssignment, isFalse);
      expect(restarted.activeTeacherAssignmentStartedAt, isNull);
      expect(restarted.resumableTeacherAssignmentStartedAt, isNull);
      expect(restarted.coreTrainingSessionProgress, isNotNull);
      expect(
        restarted.coreTrainingSessionProgress?.teacherAssignmentActive,
        isFalse,
      );
      expect(restarted.coreTrainingSessionProgress?.completed, 2);
    },
  );

  test(
    'veralteter Lehrerauftrag und sein Entwurf werden sicher verworfen',
    () async {
      final first = AppController();
      await first.load();
      final now = DateTime.now();
      final oldStart = now.subtract(
        CoreTrainingSessionProgress.maxAge + const Duration(minutes: 1),
      );
      final fact = MathFact(a: 9, b: 6, operation: MathOperation.plus);

      await first.beginTeacherAssignment(assignment, startedAt: oldStart);
      await first.saveCoreTrainingSession(
        CoreTrainingSessionProgress(
          kind: CoreTrainingKind.fact,
          mode: TrainingMode.practice,
          targetTasks: 8,
          targetCompetency: MicroCompetencyId.additionTenBridge,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.twenty,
          teacherAssignmentActive: true,
          teacherAssignmentId: assignment.assignmentId,
          startedAt: oldStart,
          updatedAt: now,
          currentTask: {'key': fact.key},
          completed: 4,
        ),
      );

      final restarted = AppController();
      await restarted.load();

      expect(restarted.hasTeacherAssignment, isFalse);
      expect(restarted.hasResumableTeacherAssignment, isFalse);
      expect(restarted.activeTeacherAssignmentStartedAt, isNull);
      expect(restarted.resumableTeacherAssignmentStartedAt, isNull);
      expect(restarted.coreTrainingSessionProgress, isNull);
    },
  );

  test('fremde Auftrags-ID kann keinen Lehrerentwurf übernehmen', () async {
    final first = AppController();
    await first.load();
    final now = DateTime.now();
    final fact = MathFact(a: 8, b: 5, operation: MathOperation.plus);

    await first.beginTeacherAssignment(assignment, startedAt: now);
    await first.storage.saveCoreTrainingSession(
      CoreTrainingSessionProgress(
        kind: CoreTrainingKind.fact,
        mode: TrainingMode.practice,
        targetTasks: 8,
        targetCompetency: MicroCompetencyId.additionTenBridge,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.twenty,
        teacherAssignmentActive: true,
        teacherAssignmentId: 'DEADBEEF',
        startedAt: now,
        updatedAt: now,
        currentTask: {'key': fact.key},
        completed: 1,
      ),
    );

    final restarted = AppController();
    await restarted.load();

    expect(restarted.hasTeacherAssignment, isFalse);
    expect(restarted.hasResumableTeacherAssignment, isFalse);
    expect(restarted.coreTrainingSessionProgress, isNull);
  });

  test(
    'verspäteter Lehrer-Speicherwrite nach Verlassen wird ignoriert',
    () async {
      final controller = AppController();
      await controller.load();
      final now = DateTime.now();
      final fact = MathFact(a: 7, b: 6, operation: MathOperation.plus);

      await controller.beginTeacherAssignment(assignment, startedAt: now);
      await controller.endTeacherAssignment();
      await controller.saveCoreTrainingSession(
        CoreTrainingSessionProgress(
          kind: CoreTrainingKind.fact,
          mode: TrainingMode.practice,
          targetTasks: 8,
          targetCompetency: MicroCompetencyId.additionTenBridge,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.twenty,
          teacherAssignmentActive: true,
          teacherAssignmentId: assignment.assignmentId,
          startedAt: now,
          updatedAt: now,
          currentTask: {'key': fact.key},
        ),
      );

      expect(controller.coreTrainingSessionProgress, isNull);
      expect(await controller.storage.loadCoreTrainingSession(), isNull);
    },
  );

  test('normale Übung verwirft einen wartenden Lehrerauftrag', () async {
    final first = AppController();
    await first.load();
    final now = DateTime.now();
    final teacherFact = MathFact(a: 8, b: 7, operation: MathOperation.plus);
    await first.beginTeacherAssignment(assignment, startedAt: now);
    await first.saveCoreTrainingSession(
      CoreTrainingSessionProgress(
        kind: CoreTrainingKind.fact,
        mode: TrainingMode.practice,
        targetTasks: 8,
        targetCompetency: MicroCompetencyId.additionTenBridge,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.twenty,
        teacherAssignmentActive: true,
        teacherAssignmentId: assignment.assignmentId,
        startedAt: now,
        updatedAt: now,
        currentTask: {'key': teacherFact.key},
        completed: 2,
      ),
    );

    final restarted = AppController();
    await restarted.load();
    expect(restarted.hasResumableTeacherAssignment, isTrue);

    final normalFact = MathFact(a: 4, b: 3, operation: MathOperation.plus);
    final normalStartedAt = DateTime.now();
    await restarted.saveCoreTrainingSession(
      CoreTrainingSessionProgress(
        kind: CoreTrainingKind.fact,
        mode: TrainingMode.practice,
        targetTasks: 10,
        gradeLevel: GradeLevel.second,
        numberRange: restarted.numberRange,
        startedAt: normalStartedAt,
        updatedAt: normalStartedAt,
        currentTask: {'key': normalFact.key},
      ),
    );

    expect(restarted.hasResumableTeacherAssignment, isFalse);
    expect(
      restarted.coreTrainingSessionProgress?.teacherAssignmentActive,
      isFalse,
    );
    expect(
      restarted.coreTrainingSessionProgress?.currentTask['key'],
      normalFact.key,
    );

    final secondRestart = AppController();
    await secondRestart.load();
    expect(secondRestart.hasResumableTeacherAssignment, isFalse);
    expect(secondRestart.coreTrainingSessionProgress, isNotNull);
    expect(
      secondRestart.coreTrainingSessionProgress?.currentTask['key'],
      normalFact.key,
    );
  });

  test('Kontextwechsel löscht einen persistierten Lehrerauftrag', () async {
    final first = AppController();
    await first.load();
    final now = DateTime.now();

    await first.beginTeacherAssignment(assignment, startedAt: now);
    await first.setNumberRange(NumberRangeLevel.twenty);

    expect(first.hasTeacherAssignment, isFalse);
    expect(first.hasResumableTeacherAssignment, isFalse);

    final restarted = AppController();
    await restarted.load();
    expect(restarted.hasTeacherAssignment, isFalse);
    expect(restarted.hasResumableTeacherAssignment, isFalse);
  });
}
