import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/main.dart';
import 'package:rechenblitz/services/app_controller.dart';

void main() {
  testWidgets('Startseite zeigt zentrale Lernmodi', (tester) async {
    final controller = AppController();
    controller.facts = const [];
    controller.loaded = true;
    await tester.pumpWidget(RechenblitzApp(controller: controller));
    expect(find.text('Hallo!'), findsOneWidget);
    expect(find.text('Üben'), findsOneWidget);
    expect(find.text('Minus üben'), findsOneWidget);
    expect(find.text('Tempotest'), findsOneWidget);
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
