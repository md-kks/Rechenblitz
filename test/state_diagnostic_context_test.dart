import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/learner_profile.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'landesspezifische Diagnosen verschwinden außerhalb des Lehrplanpfads',
    () async {
      final controller = AppController();
      await controller.load();
      controller.gradeLevel = GradeLevel.second;
      controller.numberRange = NumberRangeLevel.hundred;
      await controller.setProfileState(GermanState.bavaria);

      await _recordTwice(
        controller,
        mode: TrainingMode.dataCharts,
        taskKey: 'data:bar:state-context',
      );

      expect(
        controller
            .diagnosticSummaries(recurringOnly: true)
            .map((entry) => entry.pattern),
        contains(ErrorPattern.dataReading),
      );
      expect(
        controller.topDiagnosticForMode(TrainingMode.dataCharts)?.pattern,
        ErrorPattern.dataReading,
      );
      expect(
        controller.remediationCandidate()?.pattern,
        ErrorPattern.dataReading,
      );

      await controller.setProfileState(GermanState.thuringia);

      expect(
        controller
            .diagnosticSummaries(recurringOnly: true)
            .map((entry) => entry.pattern),
        isNot(contains(ErrorPattern.dataReading)),
      );
      expect(controller.topDiagnosticForMode(TrainingMode.dataCharts), isNull);
      expect(controller.remediationCandidate(), isNull);

      await controller.setProfileState(GermanState.bavaria);

      expect(
        controller
            .diagnosticSummaries(recurringOnly: true)
            .map((entry) => entry.pattern),
        contains(ErrorPattern.dataReading),
      );
    },
  );

  test(
    'gemeinsame Grundkompetenz bleibt über Bundeslandwechsel sichtbar',
    () async {
      final controller = AppController();
      await controller.load();
      controller.gradeLevel = GradeLevel.second;
      controller.numberRange = NumberRangeLevel.hundred;
      await controller.setProfileState(GermanState.bavaria);
      final fact = MathFact(a: 6, b: 4, operation: MathOperation.plus);

      await _recordTwice(
        controller,
        mode: TrainingMode.numberFriends,
        taskKey: fact.key,
        expected: fact.result,
        actual: fact.result - 1,
        fact: fact,
      );

      expect(
        controller
            .diagnosticSummaries(recurringOnly: true)
            .map((entry) => entry.pattern),
        contains(ErrorPattern.numberBond),
      );

      await controller.setProfileState(GermanState.hesse);

      expect(
        controller
            .diagnosticSummaries(recurringOnly: true)
            .map((entry) => entry.pattern),
        contains(ErrorPattern.numberBond),
      );
      expect(
        controller.topDiagnosticForMode(TrainingMode.numberFriends)?.pattern,
        ErrorPattern.numberBond,
      );
    },
  );

  test(
    'Diagnosen bleiben gespeichert statt beim Landeswechsel gelöscht zu werden',
    () async {
      final controller = AppController();
      await controller.load();
      controller.gradeLevel = GradeLevel.second;
      controller.numberRange = NumberRangeLevel.hundred;
      await controller.setProfileState(GermanState.bavaria);

      await _recordTwice(
        controller,
        mode: TrainingMode.dataCharts,
        taskKey: 'data:bar:persisted-state-context',
      );
      expect(controller.diagnostics, hasLength(2));

      await controller.setProfileState(GermanState.thuringia);
      expect(controller.diagnostics, hasLength(2));

      final reloaded = AppController();
      await reloaded.load();

      expect(reloaded.activeProfile.state, GermanState.thuringia);
      expect(reloaded.diagnostics, hasLength(2));
      expect(
        reloaded
            .diagnosticSummaries(recurringOnly: true)
            .map((entry) => entry.pattern),
        isNot(contains(ErrorPattern.dataReading)),
      );

      await reloaded.setProfileState(GermanState.bavaria);
      expect(
        reloaded
            .diagnosticSummaries(recurringOnly: true)
            .map((entry) => entry.pattern),
        contains(ErrorPattern.dataReading),
      );
    },
  );

  test(
    'nicht curricular gebundene Diagnosemodi bleiben rückwärtskompatibel',
    () async {
      final controller = AppController();
      await controller.load();
      controller.gradeLevel = GradeLevel.second;
      controller.numberRange = NumberRangeLevel.hundred;
      await controller.setProfileState(GermanState.hesse);

      await _recordTwice(
        controller,
        mode: TrainingMode.speed,
        taskKey: 'legacy-speed-check',
      );

      expect(
        controller
            .diagnosticSummaries(recurringOnly: true)
            .map((entry) => entry.pattern),
        contains(ErrorPattern.unknown),
      );
    },
  );
}

Future<void> _recordTwice(
  AppController controller, {
  required TrainingMode mode,
  required String taskKey,
  int expected = 5,
  int actual = 4,
  MathFact? fact,
}) async {
  for (var index = 0; index < 2; index++) {
    await controller.recordDiagnosticAttempt(
      mode: mode,
      taskKey: taskKey,
      expected: expected,
      actual: actual,
      fact: fact,
    );
  }
}
