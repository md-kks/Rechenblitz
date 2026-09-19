import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/assignments/subject_result_envelope.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/screens/assignment_result_scanner_screen.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_competency_catalog.dart';
import 'package:rechenblitz/subjects/german/german_learning_domain.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_teacher_assignment.dart';
import 'package:rechenblitz/subjects/german/german_teacher_assignment_result.dart';
import 'package:rechenblitz/subjects/german/screens/german_assignment_result_screen.dart';

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

  String mutateCompactPayload(
    GermanTeacherAssignmentResult result,
    void Function(Map<String, dynamic> data) mutate,
  ) {
    final envelope = SubjectResultEnvelope.tryParse(result.toPayload())!;
    final data = Map<String, dynamic>.from(envelope.data);
    mutate(data);
    return SubjectResultEnvelope(
      subject: envelope.subject,
      data: data,
    ).toPayload();
  }

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

  test('compact result round-trips target and multi-competency evidence', () {
    const targeted = GermanTeacherAssignmentResult(
      assignmentId: 'g4-reading-target',
      gradeLevel: GradeLevel.fourth,
      domain: GermanLearningDomain.reading,
      requestedTasks: 6,
      completedTasks: 6,
      correctFirstTry: 5,
      independentCorrectFirstTry: 4,
      readAloudAssistedTasks: 2,
      incorrectAttempts: 2,
      averageResponseMs: 1250,
      targetCompetency: GermanCompetencyId.textMainIdea,
      competencyBreakdown: <GermanAssignmentCompetencyResult>[
        GermanAssignmentCompetencyResult(
          competencyId: GermanCompetencyId.textMainIdea,
          completedTasks: 6,
          correctFirstTry: 5,
          independentCorrectFirstTry: 4,
          readAloudAssistedTasks: 2,
          incorrectAttempts: 2,
        ),
      ],
    );
    const domainWide = GermanTeacherAssignmentResult(
      assignmentId: 'g4-reading-domain',
      gradeLevel: GradeLevel.fourth,
      domain: GermanLearningDomain.reading,
      requestedTasks: 9,
      completedTasks: 9,
      correctFirstTry: 7,
      independentCorrectFirstTry: 5,
      readAloudAssistedTasks: 2,
      incorrectAttempts: 3,
      averageResponseMs: 1400,
      competencyBreakdown: <GermanAssignmentCompetencyResult>[
        GermanAssignmentCompetencyResult(
          competencyId: GermanCompetencyId.textInformation,
          completedTasks: 3,
          correctFirstTry: 3,
          independentCorrectFirstTry: 2,
          readAloudAssistedTasks: 1,
          incorrectAttempts: 0,
        ),
        GermanAssignmentCompetencyResult(
          competencyId: GermanCompetencyId.readingInference,
          completedTasks: 3,
          correctFirstTry: 2,
          independentCorrectFirstTry: 2,
          incorrectAttempts: 1,
        ),
        GermanAssignmentCompetencyResult(
          competencyId: GermanCompetencyId.textSequence,
          completedTasks: 3,
          correctFirstTry: 2,
          independentCorrectFirstTry: 1,
          readAloudAssistedTasks: 1,
          incorrectAttempts: 2,
        ),
      ],
    );

    final targetedParsed = GermanTeacherAssignmentResult.tryParse(
      targeted.toPayload(),
    );
    final domainParsed = GermanTeacherAssignmentResult.tryParse(
      domainWide.toPayload(),
    );

    expect(targetedParsed, isNotNull);
    expect(targetedParsed!.assignmentId, targeted.assignmentId);
    expect(targetedParsed.gradeLevel, targeted.gradeLevel);
    expect(targetedParsed.domain, targeted.domain);
    expect(targetedParsed.requestedTasks, targeted.requestedTasks);
    expect(targetedParsed.completedTasks, targeted.completedTasks);
    expect(targetedParsed.correctFirstTry, targeted.correctFirstTry);
    expect(
      targetedParsed.independentCorrectFirstTry,
      targeted.independentCorrectFirstTry,
    );
    expect(
      targetedParsed.readAloudAssistedTasks,
      targeted.readAloudAssistedTasks,
    );
    expect(targetedParsed.incorrectAttempts, targeted.incorrectAttempts);
    expect(targetedParsed.averageResponseMs, targeted.averageResponseMs);
    expect(targetedParsed.targetCompetency, targeted.targetCompetency);
    expect(
      targetedParsed.competencyBreakdown.single.competencyId,
      GermanCompetencyId.textMainIdea,
    );

    expect(domainParsed, isNotNull);
    expect(domainParsed!.competencyBreakdown, hasLength(3));
    expect(
      domainParsed.competencyBreakdown.map((entry) => entry.competencyId),
      <GermanCompetencyId>[
        GermanCompetencyId.textInformation,
        GermanCompetencyId.readingInference,
        GermanCompetencyId.textSequence,
      ],
    );
    expect(domainParsed.independentCorrectFirstTry, 5);
    expect(domainParsed.readAloudAssistedTasks, 2);
    expect(domainParsed.incorrectAttempts, 3);
  });

  test('compact result payload is substantially smaller at QR-scale loads', () {
    GermanTeacherAssignmentResult buildResult(List<int> counts) {
      const ids = <GermanCompetencyId>[
        GermanCompetencyId.textInformation,
        GermanCompetencyId.readingInference,
        GermanCompetencyId.textSequence,
        GermanCompetencyId.textMainIdea,
      ];
      final breakdown = <GermanAssignmentCompetencyResult>[
        for (var index = 0; index < counts.length; index++)
          GermanAssignmentCompetencyResult(
            competencyId: ids[index],
            completedTasks: counts[index],
            correctFirstTry: counts[index] - 1,
            independentCorrectFirstTry: counts[index] - 2,
            readAloudAssistedTasks: 1,
            incorrectAttempts: 1,
          ),
      ];
      final completed = counts.fold<int>(0, (sum, value) => sum + value);
      return GermanTeacherAssignmentResult(
        assignmentId: 'g4-reading-$completed',
        gradeLevel: GradeLevel.fourth,
        domain: GermanLearningDomain.reading,
        requestedTasks: completed,
        completedTasks: completed,
        correctFirstTry: completed - counts.length,
        independentCorrectFirstTry: completed - counts.length * 2,
        readAloudAssistedTasks: counts.length,
        incorrectAttempts: counts.length,
        averageResponseMs: 1450,
        competencyBreakdown: breakdown,
      );
    }

    final twenty = buildResult(<int>[5, 5, 5, 5]);
    final thirty = buildResult(<int>[8, 8, 7, 7]);

    for (final result in <GermanTeacherAssignmentResult>[twenty, thirty]) {
      final compact = result.toPayload();
      final verbose = result.toEnvelope().toPayload();
      expect(GermanTeacherAssignmentResult.tryParse(compact), isNotNull);
      expect(compact.length, lessThan(verbose.length * 0.7));
    }
  });

  test('reading assignment carries anonymous read-aloud evidence', () {
    final assistedSession = GermanSessionResult(
      gradeLevel: GradeLevel.fourth,
      startedAt: DateTime(2026, 9, 18, 9),
      finishedAt: DateTime(2026, 9, 18, 9, 3),
      kind: GermanSessionKind.teacherAssignment,
      taskResults: const <GermanTaskResult>[
        GermanTaskResult(
          taskId: 'read-independent',
          competencyId: GermanCompetencyId.textMainIdea,
          correctFirstTry: true,
          incorrectAttempts: 0,
          responseMs: 1000,
        ),
        GermanTaskResult(
          taskId: 'read-assisted-correct',
          competencyId: GermanCompetencyId.textMainIdea,
          correctFirstTry: true,
          incorrectAttempts: 0,
          responseMs: 1200,
          usedReadAloud: true,
        ),
        GermanTaskResult(
          taskId: 'read-assisted-retry',
          competencyId: GermanCompetencyId.textMainIdea,
          correctFirstTry: false,
          incorrectAttempts: 1,
          responseMs: 1400,
          usedReadAloud: true,
        ),
      ],
    );
    const assistedAssignment = GermanTeacherAssignment(
      gradeLevel: GradeLevel.fourth,
      domain: GermanLearningDomain.reading,
      tasks: 3,
      targetCompetency: GermanCompetencyId.textMainIdea,
    );

    final result = GermanTeacherAssignmentResult.fromSession(
      assignment: assistedAssignment,
      session: assistedSession,
    );
    final parsed = GermanTeacherAssignmentResult.tryParse(result.toPayload());

    expect(result.correctFirstTry, 2);
    expect(result.independentCorrectFirstTry, 1);
    expect(result.readAloudAssistedTasks, 2);
    expect(result.independentTasks, 1);
    expect(result.accuracy, 1);
    expect(parsed, isNotNull);
    expect(parsed!.independentCorrectFirstTry, 1);
    expect(parsed.readAloudAssistedTasks, 2);
    expect(parsed.competencyBreakdown.single.independentCorrectFirstTry, 1);
    expect(parsed.competencyBreakdown.single.readAloudAssistedTasks, 2);
  });

  test('German result rejects impossible independent success counts', () {
    final assistedSession = GermanSessionResult(
      gradeLevel: GradeLevel.fourth,
      startedAt: DateTime(2026, 9, 18, 9),
      finishedAt: DateTime(2026, 9, 18, 9, 2),
      kind: GermanSessionKind.teacherAssignment,
      taskResults: const <GermanTaskResult>[
        GermanTaskResult(
          taskId: 'independent',
          competencyId: GermanCompetencyId.textMainIdea,
          correctFirstTry: true,
          incorrectAttempts: 0,
          responseMs: 900,
        ),
        GermanTaskResult(
          taskId: 'assisted',
          competencyId: GermanCompetencyId.textMainIdea,
          correctFirstTry: true,
          incorrectAttempts: 0,
          responseMs: 900,
          usedReadAloud: true,
        ),
      ],
    );
    const assistedAssignment = GermanTeacherAssignment(
      gradeLevel: GradeLevel.fourth,
      domain: GermanLearningDomain.reading,
      tasks: 2,
      targetCompetency: GermanCompetencyId.textMainIdea,
    );
    final envelope = GermanTeacherAssignmentResult.fromSession(
      assignment: assistedAssignment,
      session: assistedSession,
    ).toEnvelope();
    final data = Map<String, dynamic>.from(envelope.data)
      ..['independentCorrectFirstTry'] = 2;
    final invalid = SubjectResultEnvelope(
      subject: envelope.subject,
      data: data,
    ).toPayload();

    expect(GermanTeacherAssignmentResult.tryParse(invalid), isNull);
  });

  testWidgets('all-assisted German result shows no fake zero-percent score', (
    tester,
  ) async {
    const assistedAssignment = GermanTeacherAssignment(
      gradeLevel: GradeLevel.fourth,
      domain: GermanLearningDomain.reading,
      tasks: 2,
      targetCompetency: GermanCompetencyId.textMainIdea,
    );
    final assistedSession = GermanSessionResult(
      gradeLevel: GradeLevel.fourth,
      startedAt: DateTime(2026, 9, 18, 9),
      finishedAt: DateTime(2026, 9, 18, 9, 2),
      kind: GermanSessionKind.teacherAssignment,
      taskResults: const <GermanTaskResult>[
        GermanTaskResult(
          taskId: 'assisted-a',
          competencyId: GermanCompetencyId.textMainIdea,
          correctFirstTry: true,
          incorrectAttempts: 0,
          responseMs: 900,
          usedReadAloud: true,
        ),
        GermanTaskResult(
          taskId: 'assisted-b',
          competencyId: GermanCompetencyId.textMainIdea,
          correctFirstTry: true,
          incorrectAttempts: 0,
          responseMs: 900,
          usedReadAloud: true,
        ),
      ],
    );
    final result = GermanTeacherAssignmentResult.fromSession(
      assignment: assistedAssignment,
      session: assistedSession,
    );

    expect(result.independentTasks, 0);
    expect(result.accuracy, 0);

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

    expect(find.text('0/0'), findsNothing);
    expect(find.text('–'), findsWidgets);
    expect(find.text('0 %'), findsNothing);
    expect(find.text('2'), findsWidgets);
    expect(find.text('mit Vorlesen'), findsOneWidget);
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

  test('compact result rejects malformed codes, breakdowns, and sums', () {
    final result = GermanTeacherAssignmentResult.fromSession(
      assignment: assignment,
      session: session(),
    );

    String withBreakdownValue(int index, Object? value) =>
        mutateCompactPayload(result, (data) {
          final rows = (data['b'] as List<dynamic>)
              .map((raw) => List<dynamic>.from(raw as List<dynamic>))
              .toList(growable: false);
          rows.single[index] = value;
          data['b'] = rows;
        });

    final invalidPayloads = <String>[
      mutateCompactPayload(result, (data) => data['g'] = -1),
      mutateCompactPayload(result, (data) => data['g'] = 4),
      mutateCompactPayload(result, (data) => data['g'] = 3.5),
      mutateCompactPayload(result, (data) => data['g'] = '3'),
      mutateCompactPayload(result, (data) => data['d'] = 99),
      mutateCompactPayload(result, (data) => data['t'] = 99),
      mutateCompactPayload(result, (data) => data['b'] = <String, dynamic>{}),
      mutateCompactPayload(
        result,
        (data) => data['b'] = <dynamic>[
          <dynamic>[29, 5, 4, 4, 0],
        ],
      ),
      withBreakdownValue(0, 99),
      withBreakdownValue(1, '5'),
      withBreakdownValue(1, 5.5),
      mutateCompactPayload(result, (data) => data['n'] = 4),
    ];

    for (final payload in invalidPayloads) {
      expect(GermanTeacherAssignmentResult.tryParse(payload), isNull);
    }
  });

  test('verbose German result with assisted evidence remains readable', () {
    const result = GermanTeacherAssignmentResult(
      assignmentId: 'legacy-current-fields',
      gradeLevel: GradeLevel.fourth,
      domain: GermanLearningDomain.reading,
      requestedTasks: 2,
      completedTasks: 2,
      correctFirstTry: 2,
      independentCorrectFirstTry: 1,
      readAloudAssistedTasks: 1,
      incorrectAttempts: 0,
      averageResponseMs: 950,
      targetCompetency: GermanCompetencyId.textMainIdea,
      competencyBreakdown: <GermanAssignmentCompetencyResult>[
        GermanAssignmentCompetencyResult(
          competencyId: GermanCompetencyId.textMainIdea,
          completedTasks: 2,
          correctFirstTry: 2,
          independentCorrectFirstTry: 1,
          readAloudAssistedTasks: 1,
          incorrectAttempts: 0,
        ),
      ],
    );

    final parsed = GermanTeacherAssignmentResult.tryParse(
      result.toEnvelope().toPayload(),
    );

    expect(parsed, isNotNull);
    expect(parsed!.independentCorrectFirstTry, 1);
    expect(parsed.readAloudAssistedTasks, 1);
    expect(parsed.competencyBreakdown.single.readAloudAssistedTasks, 1);
  });

  test('old German result without breakdown stays readable', () {
    final valid = GermanTeacherAssignmentResult.fromSession(
      assignment: assignment,
      session: session(),
    ).toEnvelope();
    final legacyData = Map<String, dynamic>.from(valid.data)
      ..remove('breakdown')
      ..remove('independentCorrectFirstTry')
      ..remove('readAloudAssistedTasks');
    final legacyPayload = SubjectResultEnvelope(
      subject: valid.subject,
      data: legacyData,
    ).toPayload();

    final parsed = GermanTeacherAssignmentResult.tryParse(legacyPayload);

    expect(parsed, isNotNull);
    expect(parsed!.competencyBreakdown, isEmpty);
    expect(parsed.independentCorrectFirstTry, parsed.correctFirstTry);
    expect(parsed.readAloudAssistedTasks, 0);
  });

  test('German result rejects impossible independent breakdown counts', () {
    final assistedSession = GermanSessionResult(
      gradeLevel: GradeLevel.fourth,
      startedAt: DateTime(2026, 9, 18, 9),
      finishedAt: DateTime(2026, 9, 18, 9, 2),
      kind: GermanSessionKind.teacherAssignment,
      taskResults: const <GermanTaskResult>[
        GermanTaskResult(
          taskId: 'independent',
          competencyId: GermanCompetencyId.textMainIdea,
          correctFirstTry: true,
          incorrectAttempts: 0,
          responseMs: 900,
        ),
        GermanTaskResult(
          taskId: 'assisted',
          competencyId: GermanCompetencyId.textMainIdea,
          correctFirstTry: true,
          incorrectAttempts: 0,
          responseMs: 900,
          usedReadAloud: true,
        ),
      ],
    );
    const assistedAssignment = GermanTeacherAssignment(
      gradeLevel: GradeLevel.fourth,
      domain: GermanLearningDomain.reading,
      tasks: 2,
      targetCompetency: GermanCompetencyId.textMainIdea,
    );
    final envelope = GermanTeacherAssignmentResult.fromSession(
      assignment: assistedAssignment,
      session: assistedSession,
    ).toEnvelope();
    final data = Map<String, dynamic>.from(envelope.data);
    final breakdown = (data['breakdown'] as List<dynamic>)
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList(growable: false);
    breakdown.single['s'] = 2;
    data['breakdown'] = breakdown;
    final invalid = SubjectResultEnvelope(
      subject: envelope.subject,
      data: data,
    ).toPayload();

    expect(GermanTeacherAssignmentResult.tryParse(invalid), isNull);
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

  testWidgets(
    'teacher result orders difficulty before unknown and strong evidence',
    (tester) async {
      const domainAssignment = GermanTeacherAssignment(
        gradeLevel: GradeLevel.fourth,
        domain: GermanLearningDomain.reading,
        tasks: 3,
      );
      final mixedSession = GermanSessionResult(
        gradeLevel: GradeLevel.fourth,
        startedAt: DateTime(2026, 9, 18, 11),
        finishedAt: DateTime(2026, 9, 18, 11, 3),
        kind: GermanSessionKind.teacherAssignment,
        taskResults: const <GermanTaskResult>[
          GermanTaskResult(
            taskId: 'difficulty',
            competencyId: GermanCompetencyId.textMainIdea,
            correctFirstTry: false,
            incorrectAttempts: 1,
            responseMs: 1200,
          ),
          GermanTaskResult(
            taskId: 'assisted-only',
            competencyId: GermanCompetencyId.readingInference,
            correctFirstTry: true,
            incorrectAttempts: 0,
            responseMs: 1000,
            usedReadAloud: true,
          ),
          GermanTaskResult(
            taskId: 'independent-strong',
            competencyId: GermanCompetencyId.textInformation,
            correctFirstTry: true,
            incorrectAttempts: 0,
            responseMs: 900,
          ),
        ],
      );
      final result = GermanTeacherAssignmentResult.fromSession(
        assignment: domainAssignment,
        session: mixedSession,
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

      final difficulty = find.text(
        GermanCompetencyCatalog.definition(
          GermanCompetencyId.textMainIdea,
        ).label,
      );
      final unknown = find.text(
        GermanCompetencyCatalog.definition(
          GermanCompetencyId.readingInference,
        ).label,
      );
      final strong = find.text(
        GermanCompetencyCatalog.definition(
          GermanCompetencyId.textInformation,
        ).label,
      );
      expect(difficulty, findsOneWidget);
      expect(unknown, findsOneWidget);
      expect(strong, findsOneWidget);
      expect(
        tester.getTopLeft(difficulty).dy,
        lessThan(tester.getTopLeft(unknown).dy),
      );
      expect(
        tester.getTopLeft(unknown).dy,
        lessThan(tester.getTopLeft(strong).dy),
      );
      expect(
        find.textContaining('noch keine selbstständige Beobachtung'),
        findsOneWidget,
      );
    },
  );

  testWidgets('child result explains fully assisted reading evidence', (
    tester,
  ) async {
    const assistedAssignment = GermanTeacherAssignment(
      gradeLevel: GradeLevel.fourth,
      domain: GermanLearningDomain.reading,
      tasks: 2,
      targetCompetency: GermanCompetencyId.textMainIdea,
    );
    final assistedSession = GermanSessionResult(
      gradeLevel: GradeLevel.fourth,
      startedAt: DateTime(2026, 9, 18, 9),
      finishedAt: DateTime(2026, 9, 18, 9, 2),
      kind: GermanSessionKind.teacherAssignment,
      taskResults: const <GermanTaskResult>[
        GermanTaskResult(
          taskId: 'assisted-a',
          competencyId: GermanCompetencyId.textMainIdea,
          correctFirstTry: true,
          incorrectAttempts: 0,
          responseMs: 900,
          usedReadAloud: true,
        ),
        GermanTaskResult(
          taskId: 'assisted-b',
          competencyId: GermanCompetencyId.textMainIdea,
          correctFirstTry: true,
          incorrectAttempts: 0,
          responseMs: 900,
          usedReadAloud: true,
        ),
      ],
    );
    final result = GermanTeacherAssignmentResult.fromSession(
      assignment: assistedAssignment,
      session: assistedSession,
    );

    await tester.pumpWidget(
      MaterialApp(home: GermanAssignmentResultScreen(result: result)),
    );
    await tester.pumpAndSettle();

    expect(find.text('0/0'), findsNothing);
    expect(find.text('–'), findsWidgets);
    expect(
      find.text('Mit Vorlesen geübt · noch keine selbstständige Beobachtung'),
      findsOneWidget,
    );
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

  testWidgets(
    'result scanner prioritizes independent difficulty over assisted difficulty',
    (tester) async {
      const domainAssignment = GermanTeacherAssignment(
        gradeLevel: GradeLevel.fourth,
        domain: GermanLearningDomain.reading,
        tasks: 4,
      );
      final mixedEvidenceSession = GermanSessionResult(
        gradeLevel: GradeLevel.fourth,
        startedAt: DateTime(2026, 9, 19, 10),
        finishedAt: DateTime(2026, 9, 19, 10, 3),
        kind: GermanSessionKind.teacherAssignment,
        taskResults: const <GermanTaskResult>[
          GermanTaskResult(
            taskId: 'assisted-infer-a',
            competencyId: GermanCompetencyId.readingInference,
            correctFirstTry: true,
            incorrectAttempts: 0,
            responseMs: 1000,
            usedReadAloud: true,
          ),
          GermanTaskResult(
            taskId: 'assisted-infer-b',
            competencyId: GermanCompetencyId.readingInference,
            correctFirstTry: false,
            incorrectAttempts: 1,
            responseMs: 1300,
            usedReadAloud: true,
          ),
          GermanTaskResult(
            taskId: 'independent-main-a',
            competencyId: GermanCompetencyId.textMainIdea,
            correctFirstTry: true,
            incorrectAttempts: 0,
            responseMs: 1000,
          ),
          GermanTaskResult(
            taskId: 'independent-main-b',
            competencyId: GermanCompetencyId.textMainIdea,
            correctFirstTry: false,
            incorrectAttempts: 1,
            responseMs: 1300,
          ),
        ],
      );
      final result = GermanTeacherAssignmentResult.fromSession(
        assignment: domainAssignment,
        session: mixedEvidenceSession,
      );

      expect(
        result.competencyBreakdown.first.competencyId,
        GermanCompetencyId.readingInference,
        reason: 'The encoded breakdown starts in catalog order.',
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

      final independentDifficulty = find.text(
        'Kernaussage eines Textes erfassen',
      );
      final assistedDifficulty = find.text('Zwischen den Zeilen lesen');
      expect(independentDifficulty, findsOneWidget);
      expect(assistedDifficulty, findsOneWidget);
      expect(
        tester.getTopLeft(independentDifficulty).dy,
        lessThan(tester.getTopLeft(assistedDifficulty).dy),
        reason:
            'Selbstständige Schwierigkeit soll vor Schwierigkeit mit Vorlesen stehen.',
      );
    },
  );

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
