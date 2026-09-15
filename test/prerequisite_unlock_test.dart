import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/competency_map_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';

void _addSecure(
  AppController controller,
  MicroCompetencyId id, {
  GradeLevel grade = GradeLevel.third,
  NumberRangeLevel range = NumberRangeLevel.thousand,
  DateTime? start,
}) {
  final definition = MicroCompetencyCatalog.definition(id);
  final base = start ?? DateTime(2026, 9, 15, 10);
  controller.microObservations.addAll(
    List.generate(
      6,
      (index) => MicroCompetencyObservation(
        id: id,
        occurredAt: base.add(Duration(minutes: index)),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        helpLevel: 0,
        mode: definition.preferredMode,
        gradeLevel: grade,
        numberRange: range,
        taskKey: 'unlock-${id.name}:$index',
      ),
    ),
  );
}

void main() {
  test('direkte Voraussetzungen werden in Lernreihenfolge freigeschaltet', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;

    var status = controller.microCompetencyUnlockStatus(
      MicroCompetencyId.additionTenBridge,
    );
    expect(status.isUnlocked, isFalse);
    expect(status.unmetPrerequisites, hasLength(2));
    expect(status.nextRequired?.id, MicroCompetencyId.numberDecomposition);

    _addSecure(
      controller,
      MicroCompetencyId.numberDecomposition,
      grade: GradeLevel.second,
      range: NumberRangeLevel.hundred,
    );
    status = controller.microCompetencyUnlockStatus(
      MicroCompetencyId.additionTenBridge,
    );
    expect(status.nextRequired?.id, MicroCompetencyId.additionNoBridge);

    _addSecure(
      controller,
      MicroCompetencyId.additionNoBridge,
      grade: GradeLevel.second,
      range: NumberRangeLevel.hundred,
      start: DateTime(2026, 9, 15, 11),
    );
    status = controller.microCompetencyUnlockStatus(
      MicroCompetencyId.additionTenBridge,
    );
    expect(status.isUnlocked, isTrue);
    expect(status.nextRequired, isNull);
  });

  test('rekursive Voraussetzungskette führt zur tiefsten fehlenden Grundlage', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;

    var status = controller.microCompetencyUnlockStatus(
      MicroCompetencyId.largeNumberOrder,
    );
    expect(status.unmetPrerequisites.single.id, MicroCompetencyId.largeNumberCompare);
    expect(status.nextRequired?.id, MicroCompetencyId.placeValueDigits);

    _addSecure(controller, MicroCompetencyId.placeValueDigits);
    status = controller.microCompetencyUnlockStatus(
      MicroCompetencyId.largeNumberOrder,
    );
    expect(status.nextRequired?.id, MicroCompetencyId.largeNumberCompare);

    _addSecure(
      controller,
      MicroCompetencyId.largeNumberCompare,
      start: DateTime(2026, 9, 15, 11),
    );
    status = controller.microCompetencyUnlockStatus(
      MicroCompetencyId.largeNumberOrder,
    );
    expect(status.isUnlocked, isTrue);
  });

  test('instabil gewordene Grundlage sperrt abhängigen Schritt erneut', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;
    _addSecure(controller, MicroCompetencyId.placeValueDigits);

    expect(
      controller
          .microCompetencyUnlockStatus(MicroCompetencyId.placeValueDecompose)
          .isUnlocked,
      isTrue,
    );

    controller.microObservations.add(
      MicroCompetencyObservation(
        id: MicroCompetencyId.placeValueDigits,
        occurredAt: DateTime(2026, 9, 15, 12),
        correct: false,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        helpLevel: 0,
        mode: TrainingMode.placeValue,
        gradeLevel: GradeLevel.third,
        numberRange: NumberRangeLevel.thousand,
        taskKey: 'unlock-regression',
      ),
    );

    final status = controller.microCompetencyUnlockStatus(
      MicroCompetencyId.placeValueDecompose,
    );
    expect(status.isUnlocked, isFalse);
    expect(status.nextRequired?.id, MicroCompetencyId.placeValueDigits);
  });

  test('Voraussetzungsgraph ist azyklisch und zeigt nur rückwärts erreichbare Grundlagen', () {
    final definitions = {
      for (final definition in MicroCompetencyCatalog.definitions)
        definition.id: definition,
    };

    bool visit(
      MicroCompetencyId id,
      Set<MicroCompetencyId> visiting,
      Set<MicroCompetencyId> done,
    ) {
      if (done.contains(id)) return true;
      if (!visiting.add(id)) return false;
      final definition = definitions[id]!;
      for (final prerequisite in definition.prerequisites) {
        final base = definitions[prerequisite];
        expect(base, isNotNull, reason: '${id.name} -> ${prerequisite.name}');
        expect(
          base!.minGrade.index,
          lessThanOrEqualTo(definition.minGrade.index),
          reason: '${id.name} hängt von einer späteren Klassenstufe ab',
        );
        expect(
          base.minNumberRange.index,
          lessThanOrEqualTo(definition.minNumberRange.index),
          reason: '${id.name} hängt von einem späteren Zahlenraum ab',
        );
        if (!visit(prerequisite, visiting, done)) return false;
      }
      visiting.remove(id);
      done.add(id);
      return true;
    }

    final done = <MicroCompetencyId>{};
    for (final id in definitions.keys) {
      expect(visit(id, <MicroCompetencyId>{}, done), isTrue, reason: id.name);
    }
  });

  test('gesperrte Folgekompetenz lenkt Fokus auf tiefste fehlende Grundlage', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;
    controller.microObservations.addAll(
      List.generate(
        3,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.largeNumberOrder,
          occurredAt: DateTime(2026, 9, 15, 10, index),
          correct: false,
          evidenceWeight: 1,
          source: MicroEvidenceSource.practice,
          usedHelp: false,
          helpLevel: 0,
          mode: TrainingMode.largeNumbers,
          gradeLevel: GradeLevel.third,
          numberRange: NumberRangeLevel.thousand,
          taskKey: 'locked-order-focus:$index',
        ),
      ),
    );

    final focus = controller.currentMicroFocus();
    expect(focus, isNotNull);
    expect(focus!.definition.id, MicroCompetencyId.placeValueDigits);
    expect(controller.recommendedMode(), TrainingMode.placeValue);
    expect(controller.microFocusReason(), contains('kommt zuerst'));
    expect(controller.microFocusReason(), contains('Mehrere große Zahlen ordnen'));
    final plan = controller.buildMyRound();
    expect(plan[1].targetCompetency, MicroCompetencyId.placeValueDigits);
    expect(plan[1].reason, contains('kommt zuerst'));
  });

  test('stabile Alt-Evidenz bestätigt noch nicht separat protokollierte Grundlagen', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;
    _addSecure(controller, MicroCompetencyId.largeNumberOrder);

    final unlock = controller.microCompetencyUnlockStatus(
      MicroCompetencyId.largeNumberOrder,
    );
    expect(unlock.isUnlocked, isTrue);
    expect(unlock.nextRequired, isNull);
    expect(unlock.reason, contains('noch nicht separat protokollierte'));
    expect(
      controller.strongestMicroCompetency()?.definition.id,
      MicroCompetencyId.largeNumberOrder,
    );
  });

  test('ausdrücklich schwache Grundlage sperrt trotz starker Alt-Evidenz', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;
    _addSecure(
      controller,
      MicroCompetencyId.largeNumberOrder,
      start: DateTime(2026, 9, 1, 8),
    );
    controller.microObservations.addAll(
      List.generate(
        2,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.placeValueDigits,
          occurredAt: DateTime(2026, 9, 2, 8, index),
          correct: false,
          evidenceWeight: 1,
          source: MicroEvidenceSource.practice,
          usedHelp: false,
          helpLevel: 0,
          mode: TrainingMode.placeValue,
          gradeLevel: GradeLevel.third,
          numberRange: NumberRangeLevel.thousand,
          taskKey: 'explicit-weak-place:$index',
        ),
      ),
    );

    final unlock = controller.microCompetencyUnlockStatus(
      MicroCompetencyId.largeNumberOrder,
    );
    expect(unlock.isUnlocked, isFalse);
    expect(unlock.nextRequired?.id, MicroCompetencyId.placeValueDigits);
    expect(
      controller.strongestMicroCompetency()?.definition.id,
      isNot(MicroCompetencyId.largeNumberOrder),
    );
    expect(
      controller.dueReviewMicroCompetency(now: DateTime(2026, 9, 10))
          ?.definition
          .id,
      isNot(MicroCompetencyId.largeNumberOrder),
    );
    expect(
      controller.transferCandidateMicroCompetency()?.definition.id,
      isNot(MicroCompetencyId.largeNumberOrder),
    );
  });

  test('gesperrter Oberstufenbereich wird nicht als Empfehlung gewählt', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;

    expect(controller.recommendedMode(), isNot(TrainingMode.largeNumbers));
  });

  test('nach gesicherter Voraussetzungskette wird Folgekompetenz wieder planbar', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;
    _addSecure(controller, MicroCompetencyId.placeValueDigits);
    _addSecure(
      controller,
      MicroCompetencyId.largeNumberCompare,
      start: DateTime(2026, 9, 15, 11),
    );
    _addSecure(
      controller,
      MicroCompetencyId.largeNumberOrder,
      start: DateTime(2026, 9, 1, 8),
    );

    expect(
      controller
          .microCompetencyUnlockStatus(MicroCompetencyId.largeNumberOrder)
          .isUnlocked,
      isTrue,
    );
    final transfer = controller.transferCandidateMicroCompetency(
      excludingAny: const <MicroCompetencyId>[
        MicroCompetencyId.placeValueDigits,
        MicroCompetencyId.largeNumberCompare,
      ],
    );
    expect(transfer, isNotNull);
    expect(transfer!.definition.id, MicroCompetencyId.largeNumberOrder);
    final review = controller.dueReviewMicroCompetency(
      now: DateTime(2026, 9, 10),
      excluding: const <MicroCompetencyId>[
        MicroCompetencyId.placeValueDigits,
        MicroCompetencyId.largeNumberCompare,
      ],
    );
    expect(review, isNotNull);
    expect(review!.definition.id, MicroCompetencyId.largeNumberOrder);
  });

  testWidgets('Lernlandkarte zeigt Sperre und nächste Grundlage', (tester) async {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;

    await tester.pumpWidget(
      MaterialApp(home: CompetencyMapScreen(controller: controller)),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('learning-group:Zahlen & Operationen')),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('learning-mode:largeNumbers')),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    final modeTile = find.byKey(const ValueKey('learning-mode:largeNumbers'));
    await tester.ensureVisible(modeTile);
    await tester.pumpAndSettle();
    await tester.tap(modeTile);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('micro-step:largeNumberOrder')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Zuerst: Stellenwerte erkennen'), findsWidgets);
    expect(
      find.byKey(const ValueKey('micro-prerequisite:largeNumberOrder')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('micro-info:largeNumberOrder')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Noch nicht freigeschaltet'), findsOneWidget);
    expect(find.textContaining('Als Nächstes üben wir „Stellenwerte erkennen“'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('micro-unlock-practice:largeNumberOrder')),
      findsOneWidget,
    );
  });
}
