import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/main.dart';
import 'package:rechenblitz/screens/structured_training_screen.dart';
import 'package:rechenblitz/screens/curriculum_training_screen.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/training_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void _compactLargeText(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 1.5;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

AppController _controller() {
  final controller = AppController();
  controller.facts = const [];
  controller.loaded = true;
  return controller;
}

Future<AppController> _controllerWithFacts() async {
  final controller = AppController();
  await controller.load();
  return controller;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'Startseite bleibt bei schmalem Display und großer Schrift stabil',
    (tester) async {
      _compactLargeText(tester);
      await tester.pumpWidget(RechenblitzApp(controller: _controller()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Mehr'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Schulauftrag'), findsOneWidget);
    },
  );

  testWidgets(
    'Meine Runde bleibt bei schmalem Display und großer Schrift stabil',
    (tester) async {
      _compactLargeText(tester);
      await tester.pumpWidget(RechenblitzApp(controller: _controller()));
      await tester.pumpAndSettle();

      final button = find.byKey(const ValueKey('my-round-button'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Etwa 5–8 Minuten Mathe.'), findsOneWidget);
    },
  );

  testWidgets(
    'Blitzaufgabe bleibt bei schmalem Display und großer Schrift stabil',
    (tester) async {
      _compactLargeText(tester);
      final controller = await _controllerWithFacts();
      await tester.pumpWidget(
        MaterialApp(
          home: TrainingScreen(
            controller: controller,
            mode: TrainingMode.blitz,
            targetTasks: 5,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TrainingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Sachaufgabe bleibt bei schmalem Display und großer Schrift stabil',
    (tester) async {
      _compactLargeText(tester);
      final controller = await _controllerWithFacts();
      controller.gradeLevel = GradeLevel.second;
      controller.numberRange = NumberRangeLevel.twenty;
      await tester.pumpWidget(
        MaterialApp(
          home: StructuredTrainingScreen(
            controller: controller,
            mode: TrainingMode.wordProblems,
            targetTasks: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StructuredTrainingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Klasse-3-Aufgabe bleibt bei schmalem Display und großer Schrift stabil',
    (tester) async {
      _compactLargeText(tester);
      final controller = await _controllerWithFacts();
      controller.gradeLevel = GradeLevel.third;
      controller.numberRange = NumberRangeLevel.thousand;
      await tester.pumpWidget(
        MaterialApp(
          home: CurriculumTrainingScreen(
            controller: controller,
            mode: TrainingMode.largeNumbers,
            targetTasks: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CurriculumTrainingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
