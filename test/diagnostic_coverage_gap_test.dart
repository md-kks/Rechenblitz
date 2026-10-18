import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/training.dart';

void main() {
  group('semantisch verschiedene Prozessaufgaben behalten ihr Diagnoseziel', () {
    ErrorPattern? classify(TrainingMode mode, String key, int expected, int actual) =>
        ErrorClassifier.classify(mode: mode, taskKey: key, expected: expected, actual: actual);

    test('Überschlag und Plausibilitätskontrolle werden getrennt', () {
      expect(classify(TrainingMode.estimation, 'estimate:462:337:100', 0, 1), ErrorPattern.estimation);
      expect(classify(TrainingMode.estimation, 'process:plausibility:462:337:1200:100', 1, 0), ErrorPattern.plausibilityCheck);
    });

    test('Rechengesetz und Begründung werden getrennt', () {
      expect(classify(TrainingMode.arithmeticLaws, 'law:commute:6:8', 6, 5), ErrorPattern.arithmeticLaw);
      expect(classify(TrainingMode.arithmeticLaws, 'process:reasoning:commute:6:8', 0, 1), ErrorPattern.reasoningJustification);
    });

    test('Maßstab und Weglesen werden getrennt', () {
      expect(classify(TrainingMode.plansAndOrientation, 'plan:scale:100:6', 600, 500), ErrorPattern.planScale);
      expect(classify(TrainingMode.plansAndOrientation, 'plan:route:right:3:up:2', 0, 1), ErrorPattern.planDirections);
      expect(classify(TrainingMode.plansAndOrientation, 'plan:path:6:4', 10, 9), ErrorPattern.planDirections);
    });
  });
}
