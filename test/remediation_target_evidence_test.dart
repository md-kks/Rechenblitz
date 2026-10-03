import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('gezielte Förderung verbucht Evidenz auf der expliziten Zielkompetenz',
      () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.fourth;
    controller.numberRange = NumberRangeLevel.million;

    await controller.recordDiagnosticAttempt(
      mode: TrainingMode.largeNumbers,
      taskKey: 'remediation:placeValue:large-compare:483210:483201',
      expected: 1,
      actual: 1,
      targetCompetency: MicroCompetencyId.largeNumberCompare,
      source: MicroEvidenceSource.remediation,
      evidenceId: 'targeted-large-number-compare',
    );

    final evidence = controller.microObservations
        .where((entry) => entry.evidenceId == 'targeted-large-number-compare')
        .toList();

    expect(evidence, hasLength(1));
    expect(evidence.single.id, MicroCompetencyId.largeNumberCompare);
    expect(evidence.single.source, MicroEvidenceSource.remediation);
    expect(
      evidence.where((entry) => entry.id == MicroCompetencyId.placeValueDigits),
      isEmpty,
    );
  });

  test('explizites Förderziel bleibt erhalten wenn generischer Schlüssel es nicht taggt',
      () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.fourth;
    controller.numberRange = NumberRangeLevel.million;

    await controller.recordDiagnosticAttempt(
      mode: TrainingMode.largeNumbers,
      taskKey: 'remediation:placeValue:custom-target-task',
      expected: 42,
      actual: 41,
      targetCompetency: MicroCompetencyId.largeNumberOrder,
      source: MicroEvidenceSource.remediation,
      evidenceId: 'targeted-large-number-order',
    );

    final evidence = controller.microObservations
        .where((entry) => entry.evidenceId == 'targeted-large-number-order')
        .toList();

    expect(evidence, hasLength(1));
    expect(evidence.single.id, MicroCompetencyId.largeNumberOrder);
    expect(evidence.single.correct, isFalse);
  });
}
