import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_audit.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/teacher_assignment.dart';
import 'package:rechenblitz/models/teacher_assignment_result.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/widgets/learning_visual_aid.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Auftrags-ID ist stabil und ändert sich mit dem Auftrag', () {
    const first = TeacherAssignment(
      gradeLevel: GradeLevel.third,
      numberRange: NumberRangeLevel.thousand,
      mode: TrainingMode.mentalStrategies,
      tasks: 10,
      methods: MethodPreferences(),
      targetCompetency: MicroCompetencyId.strategyChoice,
    );
    const same = TeacherAssignment(
      gradeLevel: GradeLevel.third,
      numberRange: NumberRangeLevel.thousand,
      mode: TrainingMode.mentalStrategies,
      tasks: 10,
      methods: MethodPreferences(),
      targetCompetency: MicroCompetencyId.strategyChoice,
    );
    const different = TeacherAssignment(
      gradeLevel: GradeLevel.third,
      numberRange: NumberRangeLevel.thousand,
      mode: TrainingMode.mentalStrategies,
      tasks: 12,
      methods: MethodPreferences(),
      targetCompetency: MicroCompetencyId.strategyChoice,
    );

    expect(first.assignmentId, same.assignmentId);
    expect(first.assignmentId, isNot(different.assignmentId));
    expect(first.assignmentId.length, 8);
  });

  test('Ergebnis-QR enthält nur die aktuelle Schulrunde', () {
    const assignment = TeacherAssignment(
      gradeLevel: GradeLevel.third,
      numberRange: NumberRangeLevel.thousand,
      mode: TrainingMode.mentalStrategies,
      tasks: 8,
      methods: MethodPreferences(),
      targetCompetency: MicroCompetencyId.strategyChoice,
    );
    final session = TrainingSessionResult(
      mode: TrainingMode.mentalStrategies,
      startedAt: DateTime(2026, 9, 5, 9),
      finishedAt: DateTime(2026, 9, 5, 9, 5),
      total: 8,
      correctFirstTry: 6,
      incorrectAttempts: 2,
      plusCorrect: 0,
      plusTotal: 0,
      minusCorrect: 0,
      minusTotal: 0,
      averageResponseMs: 1600,
      numberRange: NumberRangeLevel.thousand,
      gradeLevel: GradeLevel.third,
    );
    final observations = [
      MicroCompetencyObservation(
        id: MicroCompetencyId.strategyChoice,
        occurredAt: DateTime(2026, 9, 5, 9, 1),
        correct: true,
        evidenceWeight: 0.65,
        source: MicroEvidenceSource.practice,
        usedHelp: true,
        helpLevel: 2,
        methodKey: 'process:strategyChoice',
        mode: TrainingMode.mentalStrategies,
        gradeLevel: GradeLevel.third,
        numberRange: NumberRangeLevel.thousand,
        taskKey: 'process:strategy:Hunderter:397:28:400',
      ),
    ];

    final result = TeacherAssignmentResult.fromSession(
      assignment: assignment,
      session: session,
      observations: observations,
    );
    final parsed = TeacherAssignmentResult.tryParse(result.toPayload());
    final rawJson = jsonEncode(result.toJson());

    expect(parsed, isNotNull);
    expect(parsed!.assignmentId, assignment.assignmentId);
    expect(parsed.correctFirstTry, 6);
    expect(parsed.maxHelpLevel, 2);
    expect(parsed.aidedObservations, 1);
    expect(parsed.methodsUsed, contains('process:strategyChoice'));

    expect(rawJson, isNot(contains('"name"')));
    expect(rawJson, isNot(contains('profile')));
    expect(rawJson, isNot(contains('history')));
    expect(rawJson, isNot(contains('facts')));
  });

  test('Prozesskompetenzen werden gezielt generiert und getaggt', () {
    final generator = CurriculumExerciseGenerator(random: Random(20260905));
    final cases = [
      (
        mode: TrainingMode.mentalStrategies,
        id: MicroCompetencyId.strategyChoice,
        prefix: 'process:strategy:',
      ),
      (
        mode: TrainingMode.writtenAddSub,
        id: MicroCompetencyId.errorChecking,
        prefix: 'process:error:',
      ),
      (
        mode: TrainingMode.estimation,
        id: MicroCompetencyId.plausibilityCheck,
        prefix: 'process:plausibility:',
      ),
      (
        mode: TrainingMode.arithmeticLaws,
        id: MicroCompetencyId.reasoningJustification,
        prefix: 'process:reasoning:',
      ),
    ];

    for (final item in cases) {
      final exercise = generator.generate(
        mode: item.mode,
        gradeLevel: GradeLevel.third,
        maxValue: 100,
        targetCompetency: item.id,
      );
      final tags = MicroCompetencyCatalog.tagsForTask(
        mode: item.mode,
        taskKey: exercise.key,
      );

      expect(exercise.key, startsWith(item.prefix));
      expect(tags.map((tag) => tag.id), contains(item.id));
      expect(exercise.choices, isNotNull);
      expect(exercise.answer, inInclusiveRange(0, exercise.choices!.length - 1));

      if (item.id == MicroCompetencyId.reasoningJustification) {
        expect(tags.first.id, MicroCompetencyId.reasoningJustification);
        final lawSupport = tags.firstWhere(
          (tag) => tag.id == MicroCompetencyId.arithmeticLaw,
        );
        expect(lawSupport.weight, closeTo(0.45, 0.001));
      }
    }
  });

  test('Prozessaufgaben respektieren Förder-Zahlenraum 100', () {
    final generator = CurriculumExerciseGenerator(random: Random(8080));

    for (var i = 0; i < 80; i++) {
      final strategy = generator.generate(
        mode: TrainingMode.mentalStrategies,
        gradeLevel: GradeLevel.third,
        maxValue: 100,
        targetCompetency: MicroCompetencyId.strategyChoice,
      );
      final strategyNumbers = _numbers(strategy.key);
      final a = strategyNumbers[strategyNumbers.length - 3];
      final b = strategyNumbers[strategyNumbers.length - 2];
      expect(a + b, lessThanOrEqualTo(100));

      final error = generator.generate(
        mode: TrainingMode.writtenAddSub,
        gradeLevel: GradeLevel.third,
        maxValue: 100,
        targetCompetency: MicroCompetencyId.errorChecking,
      );
      final errorNumbers = _numbers(error.key);
      final left = errorNumbers[errorNumbers.length - 3];
      final right = errorNumbers[errorNumbers.length - 2];
      final shown = errorNumbers.last;
      expect(left + right, lessThanOrEqualTo(100));
      expect(shown, inInclusiveRange(0, 100));

      final plausibility = generator.generate(
        mode: TrainingMode.estimation,
        gradeLevel: GradeLevel.third,
        maxValue: 100,
        targetCompetency: MicroCompetencyId.plausibilityCheck,
      );
      final plausibilityNumbers = _numbers(plausibility.key);
      final pa = plausibilityNumbers[plausibilityNumbers.length - 4];
      final pb = plausibilityNumbers[plausibilityNumbers.length - 3];
      final candidate = plausibilityNumbers[plausibilityNumbers.length - 2];
      expect(pa + pb, lessThanOrEqualTo(100));
      expect(candidate, inInclusiveRange(0, 100));

      final reasoning = generator.generate(
        mode: TrainingMode.arithmeticLaws,
        gradeLevel: GradeLevel.third,
        maxValue: 100,
        targetCompetency: MicroCompetencyId.reasoningJustification,
      );
      final reasoningNumbers = _numbers(reasoning.key);
      if (reasoning.key.contains(':compensate:')) {
        expect(reasoningNumbers[0] + reasoningNumbers[1], lessThanOrEqualTo(100));
      } else if (reasoning.key.contains(':commute:')) {
        expect(reasoningNumbers[0] * reasoningNumbers[1], lessThanOrEqualTo(100));
      } else {
        expect(reasoning.key, contains(':distribute:'));
        expect(reasoningNumbers[0] * reasoningNumbers[2], lessThanOrEqualTo(100));
      }
    }
  });

  test('Hilfe nach erstem Fehler wird als Unterstützungs-Evidenz erfasst',
      () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.hundred;

    const key = 'process:strategy:Zehner:37:8:40';
    await controller.recordDiagnosticAttempt(
      mode: TrainingMode.mentalStrategies,
      taskKey: key,
      expected: 0,
      actual: 1,
    );
    await controller.recordMicroSupportResolution(
      mode: TrainingMode.mentalStrategies,
      taskKey: key,
      helpLevel: 3,
      methodKey: 'process:strategyChoice',
    );

    final observations = controller.microObservations
        .where(
          (entry) =>
              entry.id == MicroCompetencyId.strategyChoice &&
              entry.taskKey == key,
        )
        .toList();

    expect(observations.length, 2);
    expect(observations.any((entry) => !entry.correct), isTrue);
    final supported =
        observations.firstWhere((entry) => entry.correct);
    expect(supported.helpLevel, 3);
    expect(supported.usedHelp, isTrue);
    expect(supported.evidenceWeight, closeTo(0.50, 0.001));
  });

  test('Klasse 3 enthält die neuen Prozess-Mikrokompetenzen', () {
    final ids = MicroCompetencyCatalog.forGrade(GradeLevel.third)
        .map((definition) => definition.id)
        .toSet();

    expect(ids, contains(MicroCompetencyId.strategyChoice));
    expect(ids, contains(MicroCompetencyId.errorChecking));
    expect(ids, contains(MicroCompetencyId.plausibilityCheck));
    expect(ids, contains(MicroCompetencyId.reasoningJustification));
  });

  test('Lehrplan-Audit kennzeichnet Prozesskompetenzen explizit', () {
    final processIds = CurriculumAuditCatalog.forGrade(GradeLevel.third)
        .where((objective) => objective.processRelated)
        .map((objective) => objective.competency)
        .toSet();

    expect(processIds, contains(MicroCompetencyId.strategyChoice));
    expect(processIds, contains(MicroCompetencyId.errorChecking));
    expect(processIds, contains(MicroCompetencyId.plausibilityCheck));
    expect(processIds, contains(MicroCompetencyId.reasoningJustification));

    final reasoning = CurriculumAuditCatalog.forGrade(GradeLevel.third)
        .firstWhere(
          (objective) =>
              objective.competency ==
              MicroCompetencyId.reasoningJustification,
        );
    expect(reasoning.coverage, CurriculumCoverage.digitalSupport);
    expect(reasoning.note, contains('eigene Begründungen'));
  });

  testWidgets('Prozessaufgaben besitzen konkrete visuelle Hilfen',
      (tester) async {
    Future<void> pumpAid(String key) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LearningVisualAid(
              pattern: ErrorPattern.unknown,
              taskKey: key,
              expected: 0,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    await pumpAid('process:strategy:Zehner:37:8:40');
    expect(find.text('Rechenvorteil sichtbar machen'), findsOneWidget);

    await pumpAid('process:error:add:47:32:89');
    expect(find.text('Vorgegebene Rechnung prüfen'), findsOneWidget);

    await pumpAid('process:plausibility:34:28:92:10');
    expect(find.text('Überschlag'), findsOneWidget);
  });
}

List<int> _numbers(String value) => RegExp(r'\d+')
    .allMatches(value)
    .map((match) => int.parse(match.group(0)!))
    .toList();
