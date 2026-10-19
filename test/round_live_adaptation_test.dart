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

  testWidgets(
    'bewusst verschobene Prozess-Recovery bleibt nach Resume verschoben',
    (tester) async {
      final controller = AppController();
      await controller.load();
      controller.gradeLevel = GradeLevel.third;
      controller.numberRange = NumberRangeLevel.thousand;
      final now = DateTime.now();
      final savedPlan = controller.buildMyRound(now: now);
      controller.microObservations = <MicroCompetencyObservation>[
        MicroCompetencyObservation(
          id: MicroCompetencyId.largeMultiplicationPartialProducts,
          occurredAt: now.subtract(const Duration(minutes: 5)),
          correct: false,
          evidenceWeight: 0.22,
          source: MicroEvidenceSource.independentStep,
          usedHelp: false,
          mode: TrainingMode.multiply,
          gradeLevel: GradeLevel.third,
          numberRange: NumberRangeLevel.thousand,
          taskKey:
              'independent:combinePlaceValueProducts:multiply:247:6:process:combine',
        ),
      ];
      controller.guidedRoundProgress = GuidedRoundProgress(
        plan: savedPlan,
        completedRoles: const <GuidedRoundRole>{GuidedRoundRole.warmUp},
        completedTaskCounts: <GuidedRoundRole, int>{
          GuidedRoundRole.warmUp: savedPlan
              .firstWhere((segment) => segment.role == GuidedRoundRole.warmUp)
              .tasks,
        },
        gradeLevel: GradeLevel.third,
        numberRange: NumberRangeLevel.thousand,
        startedAt: now.subtract(const Duration(minutes: 12)),
        updatedAt: now,
        recoveryRequired: false,
        deferEmergingRecovery: true,
        lastAdaptationKind: GuidedRoundAdaptationKind.support,
        lastAdaptationMessage:
            'Die neu entdeckte Recovery wird bewusst in die nächste Runde verschoben.',
      );

      await tester.pumpWidget(
        MaterialApp(home: MyRoundScreen(controller: controller)),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('step-recovery-button')), findsNothing);
      expect(controller.guidedRoundProgress?.deferEmergingRecovery, isTrue);
      expect(controller.guidedRoundProgress?.recoveryRequired, isFalse);
    },
  );

  testWidgets(
    'Meine Runde zeigt fällige Prozess-Abstandskontrolle getrennt vom Lernfokus',
    (tester) async {
      final controller = AppController();
      await controller.load();
      controller.gradeLevel = GradeLevel.third;
      controller.numberRange = NumberRangeLevel.thousand;
      final now = DateTime.now();
      final failure = now.subtract(const Duration(days: 4));
      final firstConfirmation = now.subtract(const Duration(days: 3));
      final secondConfirmation = firstConfirmation.add(
        const Duration(minutes: 1),
      );
      controller.microObservations = <MicroCompetencyObservation>[
        MicroCompetencyObservation(
          id: MicroCompetencyId.largeMultiplicationPartialProducts,
          occurredAt: secondConfirmation,
          correct: true,
          evidenceWeight: 0.35,
          source: MicroEvidenceSource.independentStep,
          usedHelp: false,
          mode: TrainingMode.multiply,
          gradeLevel: GradeLevel.third,
          numberRange: NumberRangeLevel.thousand,
          taskKey:
              'independent:combinePlaceValueProducts:repair:check:multiply:247:6',
        ),
        MicroCompetencyObservation(
          id: MicroCompetencyId.largeMultiplicationPartialProducts,
          occurredAt: firstConfirmation,
          correct: true,
          evidenceWeight: 0.35,
          source: MicroEvidenceSource.independentStep,
          usedHelp: false,
          mode: TrainingMode.multiply,
          gradeLevel: GradeLevel.third,
          numberRange: NumberRangeLevel.thousand,
          taskKey:
              'independent:combinePlaceValueProducts:repair:transfer:multiply:372:4',
        ),
        MicroCompetencyObservation(
          id: MicroCompetencyId.largeMultiplicationPartialProducts,
          occurredAt: failure,
          correct: false,
          evidenceWeight: 0.22,
          source: MicroEvidenceSource.independentStep,
          usedHelp: false,
          mode: TrainingMode.multiply,
          gradeLevel: GradeLevel.third,
          numberRange: NumberRangeLevel.thousand,
          taskKey:
              'independent:combinePlaceValueProducts:multiply:247:6:process:combine',
        ),
      ];

      final due = controller.independentStepRecoveryFocus(now: now);
      expect(due?.isSpacingReview, isTrue);

      await tester.pumpWidget(
        MaterialApp(home: MyRoundScreen(controller: controller)),
      );
      await tester.pump();

      expect(find.text('Nach Abstand prüfen'), findsOneWidget);
      expect(
        find.textContaining('Teilprodukte vollständig zusammenfügen'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('step-recovery-button')),
        findsOneWidget,
      );
    },
  );

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
      startedAt: now,
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

    await tester.pumpWidget(
      MaterialApp(home: MyRoundScreen(controller: controller)),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('round-learning-summary')),
      findsOneWidget,
    );
    expect(find.text('Das hast du heute gestärkt'), findsOneWidget);
    expect(
      find.text(
        '5 Aufgaben sind genug für heute. Rechenblitz hat Verstehen, Wiederholung, Anwendung und Automatisierung getrennt ausgewertet.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        MicroCompetencyCatalog.definition(
          MicroCompetencyId.additionNoBridge,
        ).label,
      ),
      findsWidgets,
    );
    expect(
      find.text(
        MicroCompetencyCatalog.definition(
          MicroCompetencyId.subtractionTenBridge,
        ).label,
      ),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey('round-next-learning-step')),
      findsOneWidget,
    );
    expect(find.textContaining('Abstandskontrolle fällig'), findsOneWidget);
  });

  testWidgets('Lernbilanz der Runde bleibt bei 200 Prozent stabil', (
    tester,
  ) async {
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
      completedTaskCounts: const <GuidedRoundRole, int>{
        GuidedRoundRole.focus: 3,
      },
      gradeLevel: controller.gradeLevel,
      numberRange: controller.numberRange,
      startedAt: now,
      updatedAt: now,
      recoveryRequired: false,
    );

    await tester.pumpWidget(
      MaterialApp(home: MyRoundScreen(controller: controller)),
    );
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('round-learning-summary')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('round-learning-summary')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'abgeschlossene Runde plant den nächsten Fokus frisch statt vom Rundenstart',
    (tester) async {
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
        completedTaskCounts: const <GuidedRoundRole, int>{
          GuidedRoundRole.focus: 2,
        },
        gradeLevel: controller.gradeLevel,
        numberRange: controller.numberRange,
        startedAt: now,
        updatedAt: now,
        recoveryRequired: false,
        decisionTrace: oldTrace,
      );

      await tester.pumpWidget(
        MaterialApp(home: MyRoundScreen(controller: controller)),
      );
      await tester.pump();

      final freshLabel = MicroCompetencyCatalog.definition(
        MicroCompetencyId.subtractionTenBridge,
      ).label;
      final oldLabel = MicroCompetencyCatalog.definition(
        MicroCompetencyId.additionNoBridge,
      ).label;
      final nextText = tester
          .widget<Text>(find.byKey(const ValueKey('round-next-learning-step')))
          .data!;
      expect(nextText, contains(freshLabel));
      expect(nextText, contains('Transfer fällig'));
      expect(nextText, isNot(contains('„$oldLabel“ dran')));
    },
  );
}

class _FreshDecisionController extends AppController {
  _FreshDecisionController(this.freshTrace);

  final GuidedRoundDecisionTrace freshTrace;

  @override
  GuidedRoundDecisionTrace guidedRoundDecisionTrace({DateTime? now}) =>
      freshTrace;
}
