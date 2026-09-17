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
