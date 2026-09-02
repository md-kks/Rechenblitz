import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/main.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Startseite zeigt erweiterte Lernwelten', (tester) async {
    final controller = AppController();
    controller.facts = const [];
    controller.loaded = true;
    await tester.pumpWidget(RechenblitzApp(controller: controller));

    expect(find.text('Hallo!'), findsOneWidget);
    expect(find.text('Plus & Minus'), findsOneWidget);
    expect(find.text('Malnehmen'), findsOneWidget);
    expect(find.text('Zahlenmauern'), findsOneWidget);
    expect(find.text('Rechencheck'), findsOneWidget);
  });

  testWidgets('Zahlenraum kann auf 100 umgeschaltet werden', (tester) async {
    final controller = AppController();
    controller.facts = const [];
    controller.loaded = true;
    await tester.pumpWidget(RechenblitzApp(controller: controller));

    await tester.tap(find.text('bis 100').first);
    await tester.pumpAndSettle();
    expect(controller.numberRange, NumberRangeLevel.hundred);
  });

  testWidgets('Elternbereich öffnet nach zwei Sekunden Halten', (tester) async {
    final controller = AppController();
    controller.facts = const [];
    controller.loaded = true;
    await tester.pumpWidget(RechenblitzApp(controller: controller));

    final gate = find.byIcon(Icons.admin_panel_settings_rounded);
    expect(gate, findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(gate));
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pumpAndSettle();

    expect(find.text('Elternbereich'), findsOneWidget);
    await gesture.up();
  });
}
