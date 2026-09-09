import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/widgets/qr_camera_panel.dart';

void main() {
  testWidgets('QR-Scanner zeigt Fallback ohne Kamera', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 310,
            child: QrCameraPanel(
              onPayload: (_) {},
              cameraProbe: () async => const <CameraDescription>[],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('keine Kamera verfügbar'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);
  });

  testWidgets('QR-Scanner erklärt verweigerten Kamerazugriff', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 310,
            child: QrCameraPanel(
              onPayload: (_) {},
              cameraProbe: () async =>
                  throw CameraException('CameraAccessDenied', 'denied'),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.textContaining('Kamerazugriff wurde nicht erlaubt'),
      findsOneWidget,
    );
    expect(find.textContaining('Code unten manuell eingeben'), findsOneWidget);
  });
}
