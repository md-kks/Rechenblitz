import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/remediation_path.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  AppController controllerWithDueTarget() {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.fourth;
    controller.numberRange = NumberRangeLevel.million;
    controller.remediationProgress = [
      RemediationProgress(
        pattern: ErrorPattern.placeValue,
        gradeLevel: GradeLevel.fourth,
        numberRange: NumberRangeLevel.million,
        status: RemediationStatus.improved,
        startedAt: DateTime(2026, 9, 1),
        completedAt: DateTime(2026, 9, 1),
        nextReviewAt: DateTime(2026, 9, 2),
        targetCompetency: MicroCompetencyId.largeNumberCompare,
      ),
    ];
    return controller;
  }

  test('fremde Teilkompetenz bestätigt gezielte Verbesserung nicht', () async {
    final controller = controllerWithDueTarget();
    await controller.recordDiagnosticAttempt(
      mode: TrainingMode.largeNumbers,
      taskKey: 'large:decompose:482731',
      expected: 1,
      actual: 1,
      targetCompetency: MicroCompetencyId.placeValueDecompose,
      evidenceId: 'unrelated-place-value',
    );
    final progress = controller.remediationProgress.single;
    expect(progress.status, RemediationStatus.improved);
    expect(progress.stabilityCorrect, 0);
  });

  test('passende Teilkompetenz bestätigt gezielte Verbesserung', () async {
    final controller = controllerWithDueTarget();
    for (var i = 0; i < 3; i++) {
      await controller.recordDiagnosticAttempt(
        mode: TrainingMode.largeNumbers,
        taskKey: 'large:compare:${482731 + i}:${482700 + i}',
        expected: 1,
        actual: 1,
        targetCompetency: MicroCompetencyId.largeNumberCompare,
        evidenceId: 'compare-confirmation-$i',
      );
    }
    final progress = controller.remediationProgress.single;
    expect(progress.status, RemediationStatus.stable);
    expect(progress.stabilityCorrect, 3);
  });

  test('fremde Teilkompetenz widerlegt gezielte Verbesserung nicht', () async {
    final controller = controllerWithDueTarget();
    await controller.recordDiagnosticAttempt(
      mode: TrainingMode.largeNumbers,
      taskKey: 'large:order:4:8:2',
      expected: 1,
      actual: 0,
      targetCompetency: MicroCompetencyId.largeNumberOrder,
      evidenceId: 'unrelated-place-value-error',
    );
    expect(controller.remediationProgress.single.status, RemediationStatus.improved);
  });

  test('Förderziel überlebt Persistenz des Fortschritts', () {
    final original = controllerWithDueTarget().remediationProgress.single;
    final restored = RemediationProgress.fromJson(original.toJson());
    expect(restored.targetCompetency, MicroCompetencyId.largeNumberCompare);
  });
}
