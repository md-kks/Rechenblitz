import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/main.dart';
import 'package:rechenblitz/services/app_controller.dart';

void main() {
  testWidgets('startup failure replaces native splash with recoverable UI', (
    tester,
  ) async {
    await tester.pumpWidget(
      RechenblitzBootstrap(
        controller: AppController(),
        loadController: () async {
          throw StateError('simulated startup failure');
        },
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Rechenblitz konnte nicht starten.'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);
    expect(find.text('Rechenblitz startet …'), findsNothing);
  });
}
