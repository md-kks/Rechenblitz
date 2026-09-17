import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_audit.dart';
import 'package:rechenblitz/models/evidence_coverage_audit.dart';
import 'package:rechenblitz/models/learner_profile.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/teacher_assignment.dart';
import 'package:rechenblitz/models/teacher_assignment_result.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/competency_map_screen.dart';
import 'package:rechenblitz/screens/teacher_mode_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/services/assignment_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('Lehrerauftrag transportiert das Bundesland ohne PII', () {
    const assignment = TeacherAssignment(
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      mode: TrainingMode.dataCharts,
      tasks: 8,
      methods: MethodPreferences(),
      state: GermanState.bavaria,
      targetCompetency: MicroCompetencyId.dataReading,
    );

    final payload = assignment.toPayload();
    final parsed = TeacherAssignment.tryParse(payload);

    expect(parsed, isNotNull);
    expect(parsed!.state, GermanState.bavaria);
    expect(parsed.summary, contains('Bayern'));
    expect(parsed.isCompatibleWithState(GermanState.bavaria), isTrue);
    expect(parsed.isCompatibleWithState(GermanState.hesse), isFalse);
    expect(payload, isNot(contains('profile')));
    expect(payload, isNot(contains('name')));
  });

  test('alter Auftrag ohne Land wird am aktiven Landespfad geprüft', () {
    const earlyData = TeacherAssignment(
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      mode: TrainingMode.dataCharts,
      tasks: 8,
      methods: MethodPreferences(),
      targetCompetency: MicroCompetencyId.dataReading,
    );
    const generic = TeacherAssignment(
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      mode: TrainingMode.minus,
      tasks: 8,
      methods: MethodPreferences(),
      targetCompetency: MicroCompetencyId.subtractionTenBridge,
    );

    expect(earlyData.isCompatibleWithState(GermanState.bavaria), isTrue);
    expect(earlyData.isCompatibleWithState(GermanState.hesse), isFalse);
    expect(generic.isCompatibleWithState(GermanState.hesse), isTrue);
    expect(earlyData.toJson().containsKey('state'), isFalse);
    expect(generic.toJson().containsKey('state'), isFalse);

    const legacyModeOnly = TeacherAssignment(
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      mode: TrainingMode.dataCharts,
      tasks: 5,
      methods: MethodPreferences(),
    );
    expect(legacyModeOnly.isCompatibleWithState(GermanState.bavaria), isTrue);
    expect(legacyModeOnly.isCompatibleWithState(GermanState.hesse), isFalse);
  });

  test('Ergebnis-QR behält den Lehrplan-Kontext des Auftrags', () {
    const assignment = TeacherAssignment(
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      mode: TrainingMode.probability,
      tasks: 5,
      methods: MethodPreferences(),
      state: GermanState.bavaria,
      targetCompetency: MicroCompetencyId.probabilityReasoning,
    );
    final now = DateTime(2026, 9, 17, 22);
    final session = TrainingSessionResult(
      mode: TrainingMode.probability,
      startedAt: now,
      finishedAt: now.add(const Duration(minutes: 2)),
      total: 5,
      correctFirstTry: 4,
      incorrectAttempts: 1,
      plusCorrect: 0,
      plusTotal: 0,
      minusCorrect: 0,
      minusTotal: 0,
      averageResponseMs: 1800,
      numberRange: NumberRangeLevel.hundred,
      gradeLevel: GradeLevel.second,
    );

    final result = TeacherAssignmentResult.fromSession(
      assignment: assignment,
      session: session,
      observations: const <MicroCompetencyObservation>[],
    );
    final parsed = TeacherAssignmentResult.tryParse(result.toPayload());

    expect(parsed, isNotNull);
    expect(parsed!.state, GermanState.bavaria);
    expect(parsed.summary, contains('Bayern'));
    expect(parsed.assignmentId, assignment.assignmentId);
  });

  testWidgets('fremdes Bundesland blockiert den Lehrerauftrag vor dem Start', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    await controller.setProfileState(GermanState.hesse);

    const assignment = TeacherAssignment(
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      mode: TrainingMode.dataCharts,
      tasks: 5,
      methods: MethodPreferences(),
      state: GermanState.bavaria,
      targetCompetency: MicroCompetencyId.dataReading,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () =>
                  launchTeacherAssignment(context, controller, assignment),
              child: const Text('Start'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Start'));
    await tester.pump();

    expect(
      find.textContaining('Dieser Auftrag ist für Bayern'),
      findsOneWidget,
    );
    expect(controller.hasTeacherAssignment, isFalse);
  });

  testWidgets('Lernlandkarte zeigt frühe Landesbereiche nur wo vorgesehen', (
    tester,
  ) async {
    final bavaria = AppController();
    await bavaria.load();
    bavaria.gradeLevel = GradeLevel.second;
    bavaria.numberRange = NumberRangeLevel.hundred;
    await bavaria.setProfileState(GermanState.bavaria);

    await tester.pumpWidget(
      MaterialApp(home: CompetencyMapScreen(controller: bavaria)),
    );
    await tester.pump();
    final dataGroup = find.byKey(
      const ValueKey('learning-group:Daten & Zufall'),
    );
    await tester.scrollUntilVisible(
      dataGroup,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(dataGroup, findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    final hesse = AppController();
    await hesse.load();
    hesse.gradeLevel = GradeLevel.second;
    hesse.numberRange = NumberRangeLevel.hundred;
    await hesse.setProfileState(GermanState.hesse);
    expect(
      hesse.learningModesForGrade(GradeLevel.second),
      isNot(contains(TrainingMode.dataCharts)),
    );
    expect(
      hesse.learningModesForGrade(GradeLevel.second),
      isNot(contains(TrainingMode.probability)),
    );
    expect(
      hesse.learningModesForGrade(GradeLevel.second),
      isNot(contains(TrainingMode.combinatorics)),
    );
  });

  testWidgets('Lehreransicht kennzeichnet den Landes-Kontext im Auftrag', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    await controller.setProfileState(GermanState.bavaria);

    await tester.pumpWidget(
      MaterialApp(home: TeacherModeScreen(controller: controller)),
    );
    await tester.pump();

    expect(find.textContaining('Bayern'), findsWidgets);
    expect(
      find.textContaining('Bundesland, Klassenstufe und Rechenweg'),
      findsOneWidget,
    );
  });

  test('Evidenz-Audit deckt jeden aktiven Landespfad ab', () {
    for (final state in GermanState.values) {
      for (final grade in GradeLevel.values) {
        final expected = CurriculumAuditCatalog.definitionsForGrade(
          state,
          grade,
        ).map((definition) => definition.id).toSet();
        final audit = EvidenceCoverageAuditCatalog.audit(grade, state: state);
        final actual = audit.items.map((item) => item.definition.id).toSet();
        expect(actual, expected, reason: '${state.name}/${grade.name}');
        expect(
          audit.coreEvidenceComplete,
          isTrue,
          reason: '${state.name}/${grade.name}',
        );
      }
    }
  });
}
