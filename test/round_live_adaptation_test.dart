import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/learning_path.dart';
import 'package:rechenblitz/screens/my_round_screen.dart';
import 'package:rechenblitz/screens/parent_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppController> _controllerWithAdaptation() async {
  final controller = AppController();
  await controller.load();
  final now = DateTime.now();
  controller.guidedRoundProgress = GuidedRoundProgress(
    plan: controller.buildMyRound(now: now),
    completedRoles: const <GuidedRoundRole>{GuidedRoundRole.warmUp},
    gradeLevel: controller.gradeLevel,
    numberRange: controller.numberRange,
    startedAt: now.subtract(const Duration(minutes: 4)),
    updatedAt: now,
    recoveryRequired: false,
    decisionTrace: controller.guidedRoundDecisionTrace(now: now),
    lastAdaptationKind: GuidedRoundAdaptationKind.support,
    lastAdaptationMessage:
        'Die Runde wurde nach den letzten Antworten bewusst verkürzt.',
  );
  return controller;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Meine Runde zeigt die letzte Live-Anpassung nach Wiederaufnahme',
      (tester) async {
    final controller = await _controllerWithAdaptation();
    await tester.pumpWidget(MaterialApp(home: MyRoundScreen(controller: controller)));
    await tester.pump();

    expect(find.byKey(const ValueKey('round-adaptation-card')), findsOneWidget);
    expect(find.text('Runde entlastet'), findsOneWidget);
    expect(
      find.text('Die Runde wurde nach den letzten Antworten bewusst verkürzt.'),
      findsOneWidget,
    );
  });

  testWidgets('Elternbereich erklärt die letzte Live-Anpassung', (tester) async {
    final controller = await _controllerWithAdaptation();
    await tester.pumpWidget(MaterialApp(home: ParentScreen(controller: controller)));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Die Runde wurde nach den letzten Antworten bewusst verkürzt.'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Runde entlastet'), findsOneWidget);
    expect(
      find.text('Die Runde wurde nach den letzten Antworten bewusst verkürzt.'),
      findsOneWidget,
    );
  });
}
