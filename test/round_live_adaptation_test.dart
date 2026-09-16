import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/learning_path.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/training.dart';
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

  testWidgets(
    'Meine Runde zeigt die letzte Live-Anpassung nach Wiederaufnahme',
    (tester) async {
      final controller = await _controllerWithAdaptation();
      await tester.pumpWidget(
        MaterialApp(home: MyRoundScreen(controller: controller)),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('round-adaptation-card')),
        findsOneWidget,
      );
      expect(find.text('Runde entlastet'), findsOneWidget);
      expect(
        find.text(
          'Die Runde wurde nach den letzten Antworten bewusst verkürzt.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('Elternbereich erklärt die letzte Live-Anpassung', (
    tester,
  ) async {
    final controller = await _controllerWithAdaptation();
    await tester.pumpWidget(
      MaterialApp(home: ParentScreen(controller: controller)),
    );
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

  testWidgets('Meine Runde zählt adaptiv gekürzte Aufgaben tatsächlich', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    final now = DateTime.now();
    const warmUp = GuidedRoundSegment(
      role: GuidedRoundRole.warmUp,
      mode: TrainingMode.practice,
      tasks: 5,
      reason: 'Ankommen',
    );
    const focus = GuidedRoundSegment(
      role: GuidedRoundRole.focus,
      mode: TrainingMode.minus,
      tasks: 5,
      reason: 'Fokus',
    );
    controller.guidedRoundProgress = GuidedRoundProgress(
      plan: const <GuidedRoundSegment>[warmUp, focus],
      completedRoles: const <GuidedRoundRole>{GuidedRoundRole.warmUp},
      completedTaskCounts: const <GuidedRoundRole, int>{
        GuidedRoundRole.warmUp: 3,
      },
      gradeLevel: controller.gradeLevel,
      numberRange: controller.numberRange,
      startedAt: now.subtract(const Duration(minutes: 2)),
      updatedAt: now,
      recoveryRequired: false,
    );

    await tester.pumpWidget(
      MaterialApp(home: MyRoundScreen(controller: controller)),
    );
    await tester.pump();

    expect(find.text('3 von 8 Aufgaben'), findsOneWidget);
  });

  testWidgets('abgeschlossene Meine Runde zeigt Lernbilanz und nächsten Fokus', (
    tester,
  ) async {
    final controller = _FreshDecisionController(
      const GuidedRoundDecisionTrace(
        items: <GuidedRoundDecisionItem>[
          GuidedRoundDecisionItem(
            kind: GuidedRoundDecisionKind.dueReview,
            detail: 'nach Abstand wieder prüfen',
            priority: 90,
            selected: true,
            competencyId: MicroCompetencyId.additionNoBridge,
          ),
        ],
      ),
    );
    await controller.load();
    final now = DateTime.now();
    const warmUp = GuidedRoundSegment(
      role: GuidedRoundRole.warmUp,
      mode: TrainingMode.practice,
      tasks: 2,
      reason: 'Sicher starten',
      targetCompetency: MicroCompetencyId.additionNoBridge,
    );
    const focus = GuidedRoundSegment(
      role: GuidedRoundRole.focus,
      mode: TrainingMode.minus,
      tasks: 3,
      reason: 'Fokus festigen',
      targetCompetency: MicroCompetencyId.subtractionTenBridge,
    );
    controller.guidedRoundProgress = GuidedRoundProgress(
      plan: const <GuidedRoundSegment>[warmUp, focus],
      completedRoles: const <GuidedRoundRole>{
        GuidedRoundRole.warmUp,
        GuidedRoundRole.focus,
      },
      completedTaskCounts: const <GuidedRoundRole, int>{
        GuidedRoundRole.warmUp: 2,
        GuidedRoundRole.focus: 3,
      },
      gradeLevel: controller.gradeLevel,
      numberRange: controller.numberRange,
      startedAt: now.subtract(const Duration(minutes: 8)),
      updatedAt: now,
      recoveryRequired: false,
      decisionTrace: const GuidedRoundDecisionTrace(
        items: <GuidedRoundDecisionItem>[
          GuidedRoundDecisionItem(
            kind: GuidedRoundDecisionKind.dueReview,
            detail: 'nach Abstand wieder prüfen',
            priority: 90,
            selected: true,
            competencyId: MicroCompetencyId.additionNoBridge,
          ),
        ],
      ),
    );

    await tester.pumpWidget(MaterialApp(home: MyRoundScreen(controller: controller)));
    await tester.pump();

    expect(find.byKey(const ValueKey('round-learning-summary')), findsOneWidget);
    expect(find.text('Das hast du heute gestärkt'), findsOneWidget);
    expect(find.text('5 Aufgaben sind genug für heute. Rechenblitz hat Verstehen, Wiederholung, Anwendung und Automatisierung getrennt ausgewertet.'), findsOneWidget);
    expect(
      find.text(MicroCompetencyCatalog.definition(MicroCompetencyId.additionNoBridge).label),
      findsWidgets,
    );
    expect(
      find.text(MicroCompetencyCatalog.definition(MicroCompetencyId.subtractionTenBridge).label),
      findsWidgets,
    );
    expect(find.byKey(const ValueKey('round-next-learning-step')), findsOneWidget);
    expect(find.textContaining('Abstandskontrolle fällig'), findsOneWidget);
  });

  testWidgets('Lernbilanz der Runde bleibt bei 200 Prozent stabil', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    final controller = AppController();
    await controller.load();
    final now = DateTime.now();
    const segment = GuidedRoundSegment(
      role: GuidedRoundRole.focus,
      mode: TrainingMode.minus,
      tasks: 3,
      reason: 'Fokus',
      targetCompetency: MicroCompetencyId.subtractionTenBridge,
    );
    controller.guidedRoundProgress = GuidedRoundProgress(
      plan: const <GuidedRoundSegment>[segment],
      completedRoles: const <GuidedRoundRole>{GuidedRoundRole.focus},
      completedTaskCounts: const <GuidedRoundRole, int>{GuidedRoundRole.focus: 3},
      gradeLevel: controller.gradeLevel,
      numberRange: controller.numberRange,
      startedAt: now.subtract(const Duration(minutes: 4)),
      updatedAt: now,
      recoveryRequired: false,
    );

    await tester.pumpWidget(MaterialApp(home: MyRoundScreen(controller: controller)));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('round-learning-summary')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('round-learning-summary')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });


  testWidgets('abgeschlossene Runde plant den nächsten Fokus frisch statt vom Rundenstart', (
    tester,
  ) async {
    const oldTrace = GuidedRoundDecisionTrace(
      items: <GuidedRoundDecisionItem>[
        GuidedRoundDecisionItem(
          kind: GuidedRoundDecisionKind.focus,
          detail: 'alter Fokus',
          priority: 100,
          selected: true,
          competencyId: MicroCompetencyId.additionNoBridge,
        ),
      ],
    );
    const freshTrace = GuidedRoundDecisionTrace(
      items: <GuidedRoundDecisionItem>[
        GuidedRoundDecisionItem(
          kind: GuidedRoundDecisionKind.dueTransfer,
          detail: 'neuer Transfer',
          priority: 100,
          selected: true,
          competencyId: MicroCompetencyId.subtractionTenBridge,
        ),
      ],
    );
    final controller = _FreshDecisionController(freshTrace);
    await controller.load();
    final now = DateTime.now();
    controller.guidedRoundProgress = GuidedRoundProgress(
      plan: const <GuidedRoundSegment>[
        GuidedRoundSegment(
          role: GuidedRoundRole.focus,
          mode: TrainingMode.practice,
          tasks: 2,
          reason: 'alter Rundenteil',
          targetCompetency: MicroCompetencyId.additionNoBridge,
        ),
      ],
      completedRoles: const <GuidedRoundRole>{GuidedRoundRole.focus},
      completedTaskCounts: const <GuidedRoundRole, int>{GuidedRoundRole.focus: 2},
      gradeLevel: controller.gradeLevel,
      numberRange: controller.numberRange,
      startedAt: now.subtract(const Duration(minutes: 3)),
      updatedAt: now,
      recoveryRequired: false,
      decisionTrace: oldTrace,
    );

    await tester.pumpWidget(MaterialApp(home: MyRoundScreen(controller: controller)));
    await tester.pump();

    final freshLabel = MicroCompetencyCatalog.definition(
      MicroCompetencyId.subtractionTenBridge,
    ).label;
    final oldLabel = MicroCompetencyCatalog.definition(
      MicroCompetencyId.additionNoBridge,
    ).label;
    final nextText = tester.widget<Text>(
      find.byKey(const ValueKey('round-next-learning-step')),
    ).data!;
    expect(nextText, contains(freshLabel));
    expect(nextText, contains('Transfer fällig'));
    expect(nextText, isNot(contains('„$oldLabel“ dran')));
  });

}


class _FreshDecisionController extends AppController {
  _FreshDecisionController(this.freshTrace);

  final GuidedRoundDecisionTrace freshTrace;

  @override
  GuidedRoundDecisionTrace guidedRoundDecisionTrace({DateTime? now}) => freshTrace;
}
