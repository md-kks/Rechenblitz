import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_answer_feedback.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_learning_domain.dart';
import 'package:rechenblitz/subjects/german/german_mistake_kind.dart';
import 'package:rechenblitz/subjects/german/german_parent_overview.dart';
import 'package:rechenblitz/subjects/german/german_round_draft.dart';
import 'package:rechenblitz/subjects/german/german_round_feedback.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/german_teacher_assignment.dart';
import 'package:rechenblitz/subjects/german/german_teacher_assignment_result.dart';
import 'package:rechenblitz/subjects/german/screens/german_assignment_result_screen.dart';
import 'package:rechenblitz/subjects/german/screens/german_training_screen.dart';

GermanTask _writingTask() => const GermanTask(
  id: 'mistake-writing',
  competencyId: GermanCompetencyId.sentenceWriting,
  recommendedFromGrade: GradeLevel.third,
  instruction: 'Schreibe den Satz.',
  prompt: 'Der Hund läuft.',
  interaction: GermanTaskInteraction.typedText,
  acceptedAnswers: <String>['Der Hund läuft.'],
);

GermanTaskResult _result(
  String id,
  GermanMistakeKind? kind, {
  GermanCompetencyId competency = GermanCompetencyId.sentenceWriting,
}) => GermanTaskResult(
  taskId: id,
  competencyId: competency,
  correctFirstTry: kind == null,
  incorrectAttempts: kind == null ? 0 : 1,
  responseMs: 1200,
  firstMistakeKind: kind,
);

void main() {
  test('answer diagnostics classify concrete first-mistake patterns', () {
    final writing = _writingTask();
    expect(
      GermanAnswerFeedback.kindForIncorrect(writing, 'der Hund läuft.'),
      GermanMistakeKind.capitalization,
    );
    expect(
      GermanAnswerFeedback.kindForIncorrect(writing, 'Der Hund läuft'),
      GermanMistakeKind.endingPunctuation,
    );
    expect(
      GermanAnswerFeedback.kindForIncorrect(writing, 'Der Hund lauft.'),
      GermanMistakeKind.spelling,
    );

    const selection = GermanTask(
      id: 'mistake-selection',
      competencyId: GermanCompetencyId.readingInference,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere.',
      prompt: 'Text',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['A', 'B'],
      choices: <String>['A', 'B', 'C'],
    );
    expect(
      GermanAnswerFeedback.kindForIncorrect(selection, 'A'),
      GermanMistakeKind.selectionMissing,
    );
    expect(
      GermanAnswerFeedback.kindForIncorrect(selection, 'A · B · C'),
      GermanMistakeKind.selectionExtra,
    );
    expect(
      GermanAnswerFeedback.kindForIncorrect(selection, 'A · C'),
      GermanMistakeKind.selectionSwap,
    );
  });

  test('task result persists mistake kind and reads legacy data safely', () {
    final result = _result('a', GermanMistakeKind.punctuation);
    final json = result.toJson();
    expect(json['firstMistakeKind'], 'punctuation');
    expect(
      GermanTaskResult.fromJson(json).firstMistakeKind,
      GermanMistakeKind.punctuation,
    );

    final legacy = <String, dynamic>{
      'taskId': 'legacy',
      'competencyId': GermanCompetencyId.sentenceWriting.name,
      'correctFirstTry': false,
      'incorrectAttempts': 1,
      'responseMs': 900,
      'usedReadAloud': false,
    };
    expect(GermanTaskResult.fromJson(legacy).firstMistakeKind, isNull);
    legacy['firstMistakeKind'] = 'futureUnknownKind';
    expect(GermanTaskResult.fromJson(legacy).firstMistakeKind, isNull);
  });

  test('round draft preserves current first mistake across resume', () {
    final draft = GermanRoundDraft(
      gradeLevel: GradeLevel.third,
      taskIds: const <String>['mistake-writing'],
      currentIndex: 0,
      startedAt: DateTime(2026, 10, 2, 10),
      updatedAt: DateTime(2026, 10, 2, 10, 1),
      completedResults: const <GermanTaskResult>[],
      incorrectAttempts: 1,
      currentFirstMistakeKind: GermanMistakeKind.capitalization,
      currentAnswer: 'der Hund läuft.',
    );

    final restored = GermanRoundDraft.fromJson(draft.toJson());
    expect(restored.currentFirstMistakeKind, GermanMistakeKind.capitalization);
    expect(restored.incorrectAttempts, 1);
    expect(restored.currentAnswer, 'der Hund läuft.');
  });

  test('round feedback uses the concrete mistake tip when available', () {
    final session = GermanSessionResult(
      gradeLevel: GradeLevel.third,
      startedAt: DateTime(2026, 10, 2, 10),
      finishedAt: DateTime(2026, 10, 2, 10, 5),
      taskResults: <GermanTaskResult>[
        _result('a', GermanMistakeKind.punctuation),
        _result('b', GermanMistakeKind.punctuation),
        _result('c', null),
      ],
    );

    final feedback = GermanRoundFeedback.forSession(session);
    expect(feedback.detail, contains('Kommas sowie Satzzeichen'));
    expect(feedback.spokenText, contains('Kommas sowie Satzzeichen'));
  });

  test('parent overview ranks current-grade mistake patterns', () {
    final history = <GermanSessionResult>[
      GermanSessionResult(
        gradeLevel: GradeLevel.third,
        startedAt: DateTime(2026, 10, 1, 10),
        finishedAt: DateTime(2026, 10, 1, 10, 5),
        taskResults: <GermanTaskResult>[
          _result('a', GermanMistakeKind.punctuation),
          _result('b', GermanMistakeKind.spelling),
          _result('c', GermanMistakeKind.punctuation),
        ],
      ),
    ];

    final overview = GermanParentOverview.analyze(
      gradeLevel: GradeLevel.third,
      history: history,
      now: DateTime(2026, 10, 2),
    );
    expect(overview.mistakePatterns, hasLength(2));
    expect(overview.mistakePatterns.first.kind, GermanMistakeKind.punctuation);
    expect(overview.mistakePatterns.first.count, 2);
    expect(overview.mistakePatterns.first.tip, contains('Kommas'));
  });

  test('teacher result carries one compact common-mistake code', () {
    const assignment = GermanTeacherAssignment(
      gradeLevel: GradeLevel.third,
      domain: GermanLearningDomain.writing,
      tasks: 3,
      targetCompetency: GermanCompetencyId.sentenceWriting,
    );
    final session = GermanSessionResult(
      gradeLevel: GradeLevel.third,
      startedAt: DateTime(2026, 10, 2, 10),
      finishedAt: DateTime(2026, 10, 2, 10, 5),
      kind: GermanSessionKind.teacherAssignment,
      taskResults: <GermanTaskResult>[
        _result('a', GermanMistakeKind.punctuation),
        _result('b', GermanMistakeKind.punctuation),
        _result('c', GermanMistakeKind.spelling),
      ],
    );

    final result = GermanTeacherAssignmentResult.fromSession(
      assignment: assignment,
      session: session,
    );
    expect(result.commonMistakeKind, GermanMistakeKind.punctuation);
    final payload = result.toPayload();
    final parsed = GermanTeacherAssignmentResult.tryParse(payload);
    expect(parsed, isNotNull);
    expect(parsed!.commonMistakeKind, GermanMistakeKind.punctuation);
    expect(parsed.commonMistakeLabel, 'Zeichensetzung');

    final verbose = GermanTeacherAssignmentResult.tryParse(
      result.toEnvelope().toPayload(),
    );
    expect(verbose?.commonMistakeKind, GermanMistakeKind.punctuation);
  });

  testWidgets('training stores first diagnosed mistake after correction', (
    tester,
  ) async {
    GermanSessionResult? completed;
    await tester.pumpWidget(
      MaterialApp(
        home: GermanTrainingScreen(
          gradeLevel: GradeLevel.third,
          tasks: <GermanTask>[_writingTask()],
          speak: (_) async {},
          onComplete: (result) => completed = result,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'der Hund läuft.');
    await tester.tap(find.widgetWithText(FilledButton, 'Prüfen'));
    await tester.pump();
    expect(completed, isNull);

    await tester.enterText(find.byType(TextField), 'Der Hund läuft.');
    await tester.tap(find.widgetWithText(FilledButton, 'Prüfen'));
    await tester.pump();

    expect(completed, isNotNull);
    expect(completed!.taskResults.single.incorrectAttempts, 1);
    expect(
      completed!.taskResults.single.firstMistakeKind,
      GermanMistakeKind.capitalization,
    );
  });

  testWidgets('teacher result screen shows the common mistake and tip', (
    tester,
  ) async {
    const result = GermanTeacherAssignmentResult(
      assignmentId: 'TEST1234',
      gradeLevel: GradeLevel.third,
      domain: GermanLearningDomain.writing,
      requestedTasks: 3,
      completedTasks: 3,
      correctFirstTry: 1,
      independentCorrectFirstTry: 1,
      incorrectAttempts: 2,
      averageResponseMs: 1300,
      targetCompetency: GermanCompetencyId.sentenceWriting,
      commonMistakeKind: GermanMistakeKind.punctuation,
    );

    await tester.pumpWidget(
      const MaterialApp(home: GermanAssignmentResultScreen(result: result)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Häufigste Stolperstelle'), findsOneWidget);
    expect(find.textContaining('Zeichensetzung'), findsOneWidget);
    expect(find.textContaining('Kommas'), findsOneWidget);
  });
}
