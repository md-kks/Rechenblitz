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
}
