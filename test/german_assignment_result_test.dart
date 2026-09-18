import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/assignments/subject_result_envelope.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/screens/assignment_result_scanner_screen.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_learning_domain.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_teacher_assignment.dart';
import 'package:rechenblitz/subjects/german/german_teacher_assignment_result.dart';

void main() {
  const assignment = GermanTeacherAssignment(
    gradeLevel: GradeLevel.fourth,
    domain: GermanLearningDomain.reading,
    tasks: 5,
    targetCompetency: GermanCompetencyId.textMainIdea,
  );

  GermanSessionResult session() => GermanSessionResult(
    gradeLevel: GradeLevel.fourth,
    startedAt: DateTime(2026, 9, 17, 10),
    finishedAt: DateTime(2026, 9, 17, 10, 3),
    taskResults: <GermanTaskResult>[
      for (var i = 0; i < 5; i++)
        GermanTaskResult(
          taskId: 'g4-result-$i',
          competencyId: GermanCompetencyId.textMainIdea,
          correctFirstTry: i < 4,
          incorrectAttempts: i == 4 ? 1 : 0,
          responseMs: 1000 + i * 100,
        ),
    ],
  );

  test('German assignment result round-trips anonymously', () {
    final result = GermanTeacherAssignmentResult.fromSession(
      assignment: assignment,
      session: session(),
    );
    final payload = result.toPayload();
    final parsed = GermanTeacherAssignmentResult.tryParse(payload);
    final envelope = SubjectResultEnvelope.tryParse(payload);

    expect(payload, startsWith(SubjectResultEnvelope.prefix));
    expect(parsed, isNotNull);
    expect(parsed!.assignmentId, assignment.assignmentId);
    expect(parsed.completedTasks, 5);
    expect(parsed.correctFirstTry, 4);
    expect(parsed.incorrectAttempts, 1);
    expect(parsed.targetCompetency, GermanCompetencyId.textMainIdea);
    expect(envelope, isNotNull);
    expect(envelope!.data.containsKey('name'), isFalse);
    expect(envelope.data.containsKey('profileId'), isFalse);
  });

  test('domain-wide result carries anonymous competency breakdown', () {
    const domainAssignment = GermanTeacherAssignment(
      gradeLevel: GradeLevel.fourth,
      domain: GermanLearningDomain.reading,
      tasks: 5,
    );
    final domainSession = GermanSessionResult(
      gradeLevel: GradeLevel.fourth,
      startedAt: DateTime(2026, 9, 18, 10),
      finishedAt: DateTime(2026, 9, 18, 10, 4),
      kind: GermanSessionKind.teacherAssignment,
      taskResults: const <GermanTaskResult>[
        GermanTaskResult(
          taskId: 'main-1',
          competencyId: GermanCompetencyId.textMainIdea,
          correctFirstTry: true,
          incorrectAttempts: 0,
          responseMs: 1000,
        ),
        GermanTaskResult(
          taskId: 'main-2',
          competencyId: GermanCompetencyId.textMainIdea,
          correctFirstTry: false,
          incorrectAttempts: 1,
          responseMs: 1400,
        ),
        GermanTaskResult(
          taskId: 'infer-1',
          competencyId: GermanCompetencyId.readingInference,
          correctFirstTry: true,
          incorrectAttempts: 0,
          responseMs: 1100,
        ),
        GermanTaskResult(
          taskId: 'infer-2',
          competencyId: GermanCompetencyId.readingInference,
          correctFirstTry: true,
          incorrectAttempts: 0,
          responseMs: 1200,
        ),
        GermanTaskResult(
          taskId: 'infer-3',
          competencyId: GermanCompetencyId.readingInference,
          correctFirstTry: false,
          incorrectAttempts: 2,
          responseMs: 1600,
        ),
      ],
    );

    final result = GermanTeacherAssignmentResult.fromSession(
      assignment: domainAssignment,
      session: domainSession,
    );
    final parsed = GermanTeacherAssignmentResult.tryParse(result.toPayload());

    expect(result.competencyBreakdown, hasLength(2));
    expect(parsed, isNotNull);
    expect(parsed!.competencyBreakdown, hasLength(2));
    final mainIdea = parsed.competencyBreakdown.firstWhere(
      (entry) => entry.competencyId == GermanCompetencyId.textMainIdea,
    );
    final inference = parsed.competencyBreakdown.firstWhere(
      (entry) => entry.competencyId == GermanCompetencyId.readingInference,
    );
    expect(mainIdea.completedTasks, 2);
    expect(mainIdea.correctFirstTry, 1);
    expect(mainIdea.incorrectAttempts, 1);
    expect(inference.completedTasks, 3);
    expect(inference.correctFirstTry, 2);
    expect(inference.incorrectAttempts, 2);
  });

  test('old German result without breakdown stays readable', () {
    final valid = GermanTeacherAssignmentResult.fromSession(
      assignment: assignment,
      session: session(),
    ).toEnvelope();
    final legacyData = Map<String, dynamic>.from(valid.data)
      ..remove('breakdown');
    final legacyPayload = SubjectResultEnvelope(
      subject: valid.subject,
      data: legacyData,
    ).toPayload();

    final parsed = GermanTeacherAssignmentResult.tryParse(legacyPayload);

    expect(parsed, isNotNull);
    expect(parsed!.competencyBreakdown, isEmpty);
  });

  test('German assignment result rejects inconsistent breakdown', () {
    final valid = GermanTeacherAssignmentResult.fromSession(
      assignment: assignment,
      session: session(),
    ).toEnvelope();
    final data = Map<String, dynamic>.from(valid.data);
    final raw = (data['breakdown'] as List<dynamic>)
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList(growable: false);
    raw.first['n'] = 4;
    data['breakdown'] = raw;
    final invalid = SubjectResultEnvelope(
      subject: valid.subject,
      data: data,
    ).toPayload();

    expect(GermanTeacherAssignmentResult.tryParse(invalid), isNull);
  });

  test('German assignment result rejects impossible counts', () {
    final valid = GermanTeacherAssignmentResult.fromSession(
      assignment: assignment,
      session: session(),
    ).toEnvelope();
    final data = Map<String, dynamic>.from(valid.data)..['completedTasks'] = 6;
    final invalid = SubjectResultEnvelope(
      subject: valid.subject,
      data: data,
    ).toPayload();

    expect(GermanTeacherAssignmentResult.tryParse(invalid), isNull);
  });

  testWidgets('result scanner shows domain competency breakdown', (
    tester,
  ) async {
    const domainAssignment = GermanTeacherAssignment(
      gradeLevel: GradeLevel.fourth,
      domain: GermanLearningDomain.reading,
      tasks: 4,
    );
    final domainSession = GermanSessionResult(
      gradeLevel: GradeLevel.fourth,
      startedAt: DateTime(2026, 9, 18, 11),
      finishedAt: DateTime(2026, 9, 18, 11, 3),
      kind: GermanSessionKind.teacherAssignment,
      taskResults: const <GermanTaskResult>[
        GermanTaskResult(
          taskId: 'main-a',
          competencyId: GermanCompetencyId.textMainIdea,
          correctFirstTry: true,
          incorrectAttempts: 0,
          responseMs: 1000,
        ),
        GermanTaskResult(
          taskId: 'main-b',
          competencyId: GermanCompetencyId.textMainIdea,
          correctFirstTry: false,
          incorrectAttempts: 1,
          responseMs: 1300,
        ),
        GermanTaskResult(
          taskId: 'infer-a',
          competencyId: GermanCompetencyId.readingInference,
          correctFirstTry: true,
          incorrectAttempts: 0,
          responseMs: 1100,
        ),
        GermanTaskResult(
          taskId: 'infer-b',
          competencyId: GermanCompetencyId.readingInference,
          correctFirstTry: true,
          incorrectAttempts: 0,
          responseMs: 1200,
        ),
      ],
    );
    final result = GermanTeacherAssignmentResult.fromSession(
      assignment: domainAssignment,
      session: domainSession,
    );

    await tester.pumpWidget(
      const MaterialApp(home: AssignmentResultScannerScreen()),
    );
    await tester.pumpAndSettle();

    final input = find.byKey(const ValueKey('assignment-result-code-input'));
    await tester.ensureVisible(input);
    await tester.enterText(input, result.toPayload());
    await tester.tap(
      find.byKey(const ValueKey('assignment-result-code-submit')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lernziele in dieser Runde'), findsOneWidget);
    final mainIdeaLabel = find.text('Kernaussage eines Textes erfassen');
    final inferenceLabel = find.text('Zwischen den Zeilen lesen');
    expect(mainIdeaLabel, findsOneWidget);
    expect(inferenceLabel, findsOneWidget);
    expect(find.textContaining('1/2 direkt richtig'), findsOneWidget);
    expect(find.textContaining('2/2 direkt richtig'), findsOneWidget);
    expect(
      tester.getTopLeft(mainIdeaLabel).dy,
      lessThan(tester.getTopLeft(inferenceLabel).dy),
      reason: 'Das schwächere Lernziel soll für Lehrkräfte zuerst erscheinen.',
    );
  });

  testWidgets('result scanner accepts German LBR1 result code', (tester) async {
    final result = GermanTeacherAssignmentResult.fromSession(
      assignment: assignment,
      session: session(),
    );
    await tester.pumpWidget(
      const MaterialApp(home: AssignmentResultScannerScreen()),
    );
    await tester.pumpAndSettle();

    final input = find.byKey(const ValueKey('assignment-result-code-input'));
    await tester.ensureVisible(input);
    await tester.enterText(input, result.toPayload());
    await tester.tap(
      find.byKey(const ValueKey('assignment-result-code-submit')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Deutsch-Auftrag ${assignment.assignmentId}'),
      findsOneWidget,
    );
    expect(find.text('Kernaussage eines Textes erfassen'), findsOneWidget);
    expect(find.text('4/5'), findsOneWidget);
    expect(find.text('80 %'), findsOneWidget);
  });
}
