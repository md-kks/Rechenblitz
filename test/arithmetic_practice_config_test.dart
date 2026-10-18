import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/curriculum_training_screen.dart';
import 'package:rechenblitz/screens/home_screen.dart';
import 'package:rechenblitz/screens/training_screen.dart';
import 'package:rechenblitz/services/adaptive_engine.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  AppController controller() {
    final value = AppController();
    value.loaded = true;
    value.gradeLevel = GradeLevel.second;
    value.numberRange = NumberRangeLevel.hundred;
    value.facts = AdaptiveEngine.buildFactPool(maxValue: 100);
    return value;
  }

  AppController largeController() {
    final value = AppController();
    value.loaded = true;
    value.gradeLevel = GradeLevel.third;
    value.numberRange = NumberRangeLevel.thousand;
    value.facts = AdaptiveEngine.buildFactPool(maxValue: 100);
    return value;
  }

  Future<void> openPracticeCatalog(
    WidgetTester tester,
    AppController controller,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(controller: controller)),
    );
    await tester.tap(find.text('Mehr üben'));
    await tester.pumpAndSettle();
  }

  testWidgets('Grundrechenarten lassen den Zahlenraum vor dem Start wählen', (
    tester,
  ) async {
    final value = controller();
    await openPracticeCatalog(tester, value);

    await tester.ensureVisible(find.text('Plus & Minus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plus & Minus'));
    await tester.pumpAndSettle();

    expect(find.text('Plus & Minus einstellen'), findsOneWidget);
    expect(find.text('Zahlenraum'), findsOneWidget);
    expect(find.text('Automatisch (bis 100)'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('arithmetic-range-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('bis 20').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('arithmetic-start-button')));
    await tester.pumpAndSettle();

    final screen = tester.widget<TrainingScreen>(find.byType(TrainingScreen));
    expect(screen.mode, TrainingMode.practice);
    expect(screen.numberRangeOverride, NumberRangeLevel.twenty);
    expect(find.text('Zahlenraum: bis 20'), findsOneWidget);
  });

  testWidgets('Rechnen auf Zeit startet mit sichtbarem Countdown', (
    tester,
  ) async {
    final value = controller();
    await openPracticeCatalog(tester, value);

    await tester.ensureVisible(find.text('Rechnen auf Zeit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rechnen auf Zeit'));
    await tester.pumpAndSettle();

    expect(find.text('Rechnen auf Zeit einstellen'), findsOneWidget);
    expect(find.text('Countdown'), findsOneWidget);
    expect(
      find.textContaining('Der Countdown bleibt während der Runde sichtbar'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('arithmetic-start-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final screen = tester.widget<TrainingScreen>(find.byType(TrainingScreen));
    expect(screen.mode, TrainingMode.speed);
    expect(screen.timeLimit, const Duration(minutes: 1));
    expect(find.byKey(const ValueKey('training-countdown')), findsOneWidget);
    expect(find.text('1:00'), findsOneWidget);
  });

  test(
    'manueller Zahlenraum wird in Diagnose und Mikro-Evidenz gespeichert',
    () async {
      final value = controller();
      final fact = MathFact(a: 8, b: 5, operation: MathOperation.plus);

      await value.recordDiagnosticAttempt(
        mode: TrainingMode.practice,
        taskKey: fact.key,
        expected: fact.result,
        actual: fact.result,
        fact: fact,
        numberRangeOverride: NumberRangeLevel.twenty,
      );

      expect(value.diagnostics.first.numberRange, NumberRangeLevel.twenty);
      expect(value.microObservations, isNotEmpty);
      expect(
        value.microObservations.every(
          (entry) => entry.numberRange == NumberRangeLevel.twenty,
        ),
        isTrue,
      );
    },
  );

  testWidgets('Klasse 3 startet Plus und Minus bis 1000 ohne riesigen Faktenpool', (
    tester,
  ) async {
    final value = largeController();
    await openPracticeCatalog(tester, value);

    await tester.ensureVisible(find.text('Plus & Minus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plus & Minus'));
    await tester.pumpAndSettle();

    expect(find.text('Automatisch (bis 1.000)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('arithmetic-range-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('bis 1.000').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('arithmetic-start-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final screen = tester.widget<CurriculumTrainingScreen>(
      find.byType(CurriculumTrainingScreen),
    );
    expect(screen.mode, TrainingMode.practice);
    expect(screen.arithmeticMode, TrainingMode.practice);
    expect(screen.numberRangeOverride, NumberRangeLevel.thousand);
    expect(find.text('Zahlenraum: bis 1.000'), findsOneWidget);
  });

  testWidgets('Zeitmodus kombiniert Rechenart und großen Zahlenraum', (
    tester,
  ) async {
    final value = largeController();
    await openPracticeCatalog(tester, value);

    await tester.ensureVisible(find.text('Rechnen auf Zeit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rechnen auf Zeit'));
    await tester.pumpAndSettle();

    expect(find.text('Rechenart'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('arithmetic-operation-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Malnehmen').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('arithmetic-range-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('bis 1.000').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('arithmetic-start-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final screen = tester.widget<CurriculumTrainingScreen>(
      find.byType(CurriculumTrainingScreen),
    );
    expect(screen.mode, TrainingMode.speed);
    expect(screen.arithmeticMode, TrainingMode.multiply);
    expect(screen.timeLimit, const Duration(minutes: 1));
    expect(screen.numberRangeOverride, NumberRangeLevel.thousand);
    expect(
      find.byKey(const ValueKey('curriculum-training-countdown')),
      findsOneWidget,
    );
  });

}
