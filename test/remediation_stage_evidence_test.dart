import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/remediation_path.dart';

void main() {
  test('Förderstufen besitzen semantisch getrennte Evidenzquellen', () {
    expect(
      RemediationStage.guided.evidenceSource,
      MicroEvidenceSource.remediation,
    );
    expect(
      RemediationStage.supported.evidenceSource,
      MicroEvidenceSource.remediation,
    );
    expect(
      RemediationStage.transfer.evidenceSource,
      MicroEvidenceSource.transfer,
    );
    expect(
      RemediationStage.check.evidenceSource,
      MicroEvidenceSource.review,
    );
  });
}
