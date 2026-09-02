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

  testWidgets('Startseite zeigt Lernwelten bis Klasse zwei', (tester) async {
    final controller = AppController();
    controller.facts = const [];
    controller.loaded = true;
    await tester.pumpWidget(RechenblitzApp(controller: controller));

    expect(find.text('Hallo!'), findsOneWidget);
    expect(find.text('bis 10'), findsOneWidget);
    expect(find.text('bis 20'), findsOneWidget);
    expect(find.text('bis 100'), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);

    final scrollable = find.byType(Scrollable).first;
    for (final label in [
      'Plus & Minus',
      'Malnehmen',
      'Zahlenmauern',
      'Sachaufgaben',
      'Geld',
      'Uhrzeit',
      'Längen & Größen',
      'Geometrie',
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        250,
        scrollable: scrollable,
      );
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('Erfolgsseite ist für das Kind direkt erreichbar', (tester) async {
    final controller = AppController();
    controller.facts = const [];
    controller.loaded = true;
    await tester.pumpWidget(RechenblitzApp(controller: controller));

    await tester.tap(find.byIcon(Icons.emoji_events_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Meine Erfolge'), findsOneWidget);
    expect(find.text('So entstehen Erfolge'), findsOneWidget);
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
