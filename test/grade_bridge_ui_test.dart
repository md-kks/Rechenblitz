import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/competency_map_screen.dart';
import 'package:rechenblitz/screens/my_round_screen.dart';
import 'package:rechenblitz/screens/parent_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppController> _controllerWithGradeBridge() async {
  final controller = AppController();
  await controller.load();
  controller.gradeLevel = GradeLevel.second;
  controller.numberRange = NumberRangeLevel.hundred;
  final start = DateTime(2026, 9, 15, 9);
  controller.microObservations = <MicroCompetencyObservation>[
    for (var index = 0; index < 6; index++)
      MicroCompetencyObservation(
        id: MicroCompetencyId.numberDecomposition,
        occurredAt: start.add(Duration(minutes: index)),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        helpLevel: 0,
        mode: TrainingMode.numberFriends,
        gradeLevel: GradeLevel.first,
        numberRange: NumberRangeLevel.twenty,
        taskKey: 'grade-ui-old:$index',
      ),
    for (var index = 0; index < 6; index++)
      MicroCompetencyObservation(
        id: MicroCompetencyId.numberDecomposition,
        occurredAt: start.add(Duration(hours: 1, minutes: index)),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        helpLevel: 0,
        mode: TrainingMode.numberFriends,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.twenty,
        taskKey: 'grade-ui-range:$index',
      ),
  ];
  return controller;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Elternbereich zeigt den Klassenstufen-Uebergang', (tester) async {
    final controller = await _controllerWithGradeBridge();
    await tester.pumpWidget(MaterialApp(home: ParentScreen(controller: controller)));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('grade-bridge-progress')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Übergang Klasse 1 → Klasse 2'), findsOneWidget);
    expect(find.byKey(const ValueKey('grade-bridge-progress')), findsOneWidget);
    expect(find.byKey(const ValueKey('grade-bridge-pending')), findsOneWidget);
  });


  testWidgets('Elternbereich zeigt die Aussagekraft des Lernstands', (tester) async {
    final controller = await _controllerWithGradeBridge();
    await tester.pumpWidget(MaterialApp(home: ParentScreen(controller: controller)));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Aussagekraft'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Aussagekraft'), findsOneWidget);
    expect(
      find.textContaining('Daten').evaluate().isNotEmpty ||
          find.textContaining('Aussage').evaluate().isNotEmpty ||
          find.textContaining('Bestätigung').evaluate().isNotEmpty,
      isTrue,
    );
  });

  testWidgets('Lernlandkarte erklaert die Klassenstufen-Bruecke', (tester) async {
    final controller = await _controllerWithGradeBridge();
    await tester.pumpWidget(
      MaterialApp(home: CompetencyMapScreen(controller: controller)),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('learning-map-grade-bridge')),
      findsOneWidget,
    );
    expect(find.text('Grundlagen aus Klasse 1 bestätigen'), findsOneWidget);
    expect(
      find.textContaining('nicht automatisch als sicher in Klasse 2'),
      findsOneWidget,
    );
  });

  testWidgets('Meine Runde kennzeichnet die Klassenstufen-Bruecke', (tester) async {
    final controller = await _controllerWithGradeBridge();
    expect(controller.gradeBridgeStatus().isActive, isTrue);
    expect(controller.numberRangeBridgeStatus().isActive, isTrue);

    await tester.pumpWidget(MaterialApp(home: MyRoundScreen(controller: controller)));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('round-grade-bridge-chip')),
      findsOneWidget,
    );
    expect(
      find.text('Brückenaufgaben in der neuen Klassenstufe'),
      findsOneWidget,
    );
    expect(find.text('Brückenaufgaben im neuen Zahlenraum'), findsNothing);
  });
}
