import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/teacher_assignment_result.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/assignment_result_scanner_screen.dart';
import 'package:rechenblitz/screens/assignment_result_screen.dart';

const _partialResult = TeacherAssignmentResult(
  assignmentId: 'AB12CD34',
  gradeLevel: GradeLevel.second,
  numberRange: NumberRangeLevel.twenty,
  mode: TrainingMode.practice,
  requestedTasks: 8,
  completedTasks: 5,
  correctFirstTry: 3,
  incorrectAttempts: 3,
  averageResponseMs: 1750,
  aidedObservations: 2,
  maxHelpLevel: 2,
  methodsUsed: <String>[
    'process:strategyChoice',
    'addition:bridgeToTen',
    'future:unknownMethod',
  ],
  targetCompetency: MicroCompetencyId.additionTenBridge,
);

void main() {
  test('Ergebnis trennt Erstversuch, Korrektur und Auftragsfortschritt', () {
    expect(_partialResult.isComplete, isFalse);
    expect(_partialResult.correctedAfterRetry, 2);
    expect(_partialResult.summary, contains('3/5 beim ersten Versuch richtig'));
    expect(_partialResult.summary, contains('5/8 bearbeitet'));
    expect(_partialResult.summary, isNot(contains('direkt richtig')));

    final parsed = TeacherAssignmentResult.tryParse(_partialResult.toPayload());
    expect(parsed, isNotNull);
    expect(parsed!.correctedAfterRetry, 2);
    expect(parsed.isComplete, isFalse);
    expect(parsed.summary, contains('5/8 bearbeitet'));
  });

  test(
    'interne Methodenschlüssel werden nur als bekannte Lernwege gezeigt',
    () {
      expect(_partialResult.methodLabels, <String>[
        'Erst zum Zehner',
        'Günstigen Rechenweg wählen',
      ]);
      expect(
        _partialResult.methodLabels.join(' '),
        isNot(contains('process:')),
      );
      expect(_partialResult.methodLabels.join(' '), isNot(contains('future:')));
    },
  );

  testWidgets('Kinder-Ergebnis erklärt Erstversuch und Korrektur eindeutig', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AssignmentResultScreen(result: _partialResult)),
    );
    await tester.pump();

    expect(find.text('beim ersten Versuch'), findsOneWidget);
    expect(find.text('Erstversuchquote'), findsOneWidget);
    expect(find.text('bearbeitet'), findsOneWidget);
    expect(find.text('nach Korrektur gelöst'), findsOneWidget);
    expect(find.text('direkt richtig'), findsNothing);
    expect(find.text('Trefferquote'), findsNothing);
    expect(find.text('5/8'), findsOneWidget);
    expect(find.text('60 %'), findsOneWidget);
  });

  testWidgets('Lehrer-Scanner zeigt Lernwege statt interner Kennungen', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AssignmentResultScannerScreen()),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), _partialResult.toPayload());

    final submit = find.text('Ergebniscode prüfen');
    await tester.scrollUntilVisible(
      submit,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('beim ersten Versuch'), findsOneWidget);
    expect(find.text('Erstversuchquote'), findsOneWidget);
    expect(find.text('bearbeitet'), findsOneWidget);
    expect(find.text('nach Korrektur gelöst'), findsOneWidget);
    expect(find.text('5/8'), findsOneWidget);

    final methods = find.text('Verwendete Rechenwege');
    await tester.scrollUntilVisible(
      methods,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('• Erst zum Zehner'), findsOneWidget);
    expect(find.text('• Günstigen Rechenweg wählen'), findsOneWidget);
    expect(find.textContaining('process:strategyChoice'), findsNothing);
    expect(find.textContaining('future:unknownMethod'), findsNothing);
  });

  testWidgets('Lehrer-Ergebnis bleibt bei 200 Prozent Schrift scrollbar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      const MaterialApp(home: AssignmentResultScannerScreen()),
    );
    await tester.pump();
    final manualEntry = find.text('Alternativ Ergebniscode einfügen');
    await tester.scrollUntilVisible(
      manualEntry,
      700,
      scrollable: find.byType(Scrollable).first,
    );
    expect(manualEntry, findsOneWidget);
    await tester.enterText(find.byType(TextField), _partialResult.toPayload());
    final submit = find.text('Ergebniscode prüfen');
    await tester.scrollUntilVisible(
      submit,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final methods = find.text('Verwendete Rechenwege');
    await tester.scrollUntilVisible(
      methods,
      700,
      scrollable: find.byType(Scrollable).first,
    );
    expect(methods, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
