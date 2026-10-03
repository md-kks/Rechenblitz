import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/remediation_path.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  AppController controllerWith({
    required RemediationStatus status,
    required int stabilityCorrect,
  }) {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.remediationProgress = [
      RemediationProgress(
        pattern: ErrorPattern.tenBridge,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        status: status,
        startedAt: DateTime(2026, 9, 1),
        completedAt: DateTime(2026, 9, 1),
        nextReviewAt:
            status == RemediationStatus.stable ? null : DateTime(2026, 9, 2),
        stabilityCorrect: stabilityCorrect,
        targetCompetency: MicroCompetencyId.additionTenBridge,
      ),
    ];
    return controller;
  }

  test('zwei spätere Kontrolltreffer umgehen Drei-Belege-Regel nicht', () async {
    final controller = controllerWith(
      status: RemediationStatus.improved,
      stabilityCorrect: 2,
    );
    final result = await controller.completeRemediation(
      ErrorPattern.tenBridge,
      checkCorrect: 2,
      checkTotal: 2,
      reviewOnly: true,
      targetCompetency: MicroCompetencyId.additionTenBridge,
    );
    expect(result.status, RemediationStatus.improved);
    expect(result.stabilityCorrect, 2);
    expect(result.nextReviewAt, isNotNull);
  });

  test('bereits dritter später Beleg bleibt beim Kontrollabschluss stabil',
      () async {
    final controller = controllerWith(
      status: RemediationStatus.stable,
      stabilityCorrect: 3,
    );
    final result = await controller.completeRemediation(
      ErrorPattern.tenBridge,
      checkCorrect: 2,
      checkTotal: 2,
      reviewOnly: true,
      targetCompetency: MicroCompetencyId.additionTenBridge,
    );
    expect(result.status, RemediationStatus.stable);
    expect(result.stabilityCorrect, 3);
    expect(result.nextReviewAt, isNull);
  });
}
