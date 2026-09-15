import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/services/micro_evidence_retention.dart';
import 'package:rechenblitz/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Verdichtung bewahrt Mastery einer seltenen Kompetenz trotz Datenflut', () {
    final quiet = _masteryEvidence(MicroCompetencyId.additionTenBridge);
    final flood = List.generate(
      1300,
      (index) => _observation(
        id: MicroCompetencyId.multiplicationFacts,
        when: DateTime(2026, 3, 1).add(Duration(minutes: index)),
        source: MicroEvidenceSource.practice,
        taskKey: 'x:flood:$index',
      ),
    );

    final compacted = MicroEvidenceRetention.compact(<MicroCompetencyObservation>[
      ...flood,
      ...quiet,
    ]);

    expect(compacted, hasLength(MicroEvidenceRetention.maxStoredObservations));
    expect(
      compacted.where((entry) => entry.id == MicroCompetencyId.additionTenBridge),
      hasLength(10),
    );

    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.hundred
      ..microObservations = compacted;
    expect(
      controller.microCompetencyProgress(MicroCompetencyId.additionTenBridge).state,
      MicroCompetencyState.mastered,
    );
  });

  test('Verdichtung bewahrt die neueste unsichere Abstandskontrolle', () {
    final quiet = <MicroCompetencyObservation>[
      ..._masteryEvidence(MicroCompetencyId.subtractionTenBridge),
      _observation(
        id: MicroCompetencyId.subtractionTenBridge,
        when: DateTime(2026, 2, 20),
        source: MicroEvidenceSource.review,
        taskKey: 'review:minus:53:8',
        usedHelp: true,
      ),
    ];
    final flood = List.generate(
      1300,
      (index) => _observation(
        id: MicroCompetencyId.numberPatterns,
        when: DateTime(2026, 3, 1).add(Duration(minutes: index)),
        source: MicroEvidenceSource.practice,
        taskKey: 'sequence:flood:$index',
      ),
    );

    final compacted = MicroEvidenceRetention.compact(<MicroCompetencyObservation>[
      ...flood,
      ...quiet,
    ]);
    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.hundred
      ..microObservations = compacted;
    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.subtractionTenBridge,
    );

    expect(progress.state, MicroCompetencyState.secure);
    expect(progress.reviewNeedsReconfirmation, isTrue);
  });

  test('Verdichtung bewahrt aktuelle Teilfehler- und Guided-Step-Signale', () {
    final signals = <MicroCompetencyObservation>[
      _observation(
        id: MicroCompetencyId.placeValueDigits,
        when: DateTime(2026, 2, 18, 10),
        source: MicroEvidenceSource.independentStep,
        taskKey: 'independent:placeDigit:place:347',
        correct: false,
      ),
      _observation(
        id: MicroCompetencyId.placeValueDigits,
        when: DateTime(2026, 2, 18, 11),
        source: MicroEvidenceSource.guidedStep,
        taskKey: 'guided:placeValue:tensOnes:placeDigit:place:347',
        correct: false,
        usedHelp: true,
      ),
    ];
    final flood = List.generate(
      1300,
      (index) => _observation(
        id: MicroCompetencyId.dataReading,
        when: DateTime(2026, 3, 1).add(Duration(minutes: index)),
        source: MicroEvidenceSource.practice,
        taskKey: 'data:flood:$index',
      ),
    );

    final compacted = MicroEvidenceRetention.compact(<MicroCompetencyObservation>[
      ...flood,
      ...signals,
    ]);

    expect(
      compacted.where(
        (entry) =>
            entry.id == MicroCompetencyId.placeValueDigits &&
            entry.source == MicroEvidenceSource.independentStep,
      ),
      hasLength(1),
    );
    expect(
      compacted.where(
        (entry) =>
            entry.id == MicroCompetencyId.placeValueDigits &&
            entry.source == MicroEvidenceSource.guidedStep,
      ),
      hasLength(1),
    );
  });

  test('Storage speichert verdichtet und lädt chronologisch', () async {
    final storage = StorageService();
    final quiet = _masteryEvidence(MicroCompetencyId.additionTenBridge);
    final flood = List.generate(
      1300,
      (index) => _observation(
        id: MicroCompetencyId.multiplicationFacts,
        when: DateTime(2026, 3, 1).add(Duration(minutes: index)),
        source: MicroEvidenceSource.practice,
        taskKey: 'x:persist:$index',
      ),
    );

    await storage.saveMicroCompetencyObservations(<MicroCompetencyObservation>[
      ...flood.reversed,
      ...quiet.reversed,
    ]);
    final loaded = await storage.loadMicroCompetencyObservations();

    expect(loaded, hasLength(MicroEvidenceRetention.maxStoredObservations));
    expect(
      loaded.where((entry) => entry.id == MicroCompetencyId.additionTenBridge),
      hasLength(10),
    );
    for (var index = 1; index < loaded.length; index++) {
      expect(
        loaded[index - 1].occurredAt.isBefore(loaded[index].occurredAt),
        isFalse,
      );
    }
  });
}

List<MicroCompetencyObservation> _masteryEvidence(MicroCompetencyId id) => [
      ...List.generate(
        6,
        (index) => _observation(
          id: id,
          when: DateTime(2026, 2, 1, 8, index),
          source: MicroEvidenceSource.practice,
          taskKey: 'practice:${id.name}:$index',
        ),
      ),
      ...List.generate(
        2,
        (index) => _observation(
          id: id,
          when: DateTime(2026, 2, 3, 8, index),
          source: MicroEvidenceSource.review,
          taskKey: 'review:${id.name}:$index',
        ),
      ),
      ...List.generate(
        2,
        (index) => _observation(
          id: id,
          when: DateTime(2026, 2, 5, 8, index),
          source: MicroEvidenceSource.transfer,
          taskKey: 'transfer:${id.name}:$index',
        ),
      ),
    ];

MicroCompetencyObservation _observation({
  required MicroCompetencyId id,
  required DateTime when,
  required MicroEvidenceSource source,
  required String taskKey,
  bool correct = true,
  bool usedHelp = false,
}) =>
    MicroCompetencyObservation(
      id: id,
      occurredAt: when,
      correct: correct,
      evidenceWeight: 1,
      source: source,
      usedHelp: usedHelp,
      helpLevel: usedHelp ? 2 : 0,
      mode: TrainingMode.practice,
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      taskKey: taskKey,
    );
