import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/app_controller.dart';

MicroCompetencyObservation _observation({
  required DateTime at,
  required MicroEvidenceSource source,
  required String taskKey,
  MicroCompetencyId id = MicroCompetencyId.additionTenBridge,
}) {
  return MicroCompetencyObservation(
    id: id,
    occurredAt: at,
    correct: true,
    evidenceWeight: 1,
    source: source,
    usedHelp: false,
    mode: source == MicroEvidenceSource.transfer
        ? TrainingMode.wordProblems
        : TrainingMode.practice,
    gradeLevel: GradeLevel.second,
    numberRange: NumberRangeLevel.hundred,
    taskKey: taskKey,
  );
}

void main() {
  test('anderer Sachkontext zaehlt nicht als neue Transfer-Mathematik', () {
    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.hundred;
    final base = DateTime(2026, 9, 10, 9);

    controller.microObservations = <MicroCompetencyObservation>[
      for (var index = 0; index < 6; index++)
        _observation(
          at: base.add(Duration(minutes: index)),
          source: MicroEvidenceSource.practice,
          taskKey: 'plus:${41 + index}:${9 - index}',
        ),
      _observation(
        at: base.add(const Duration(days: 3)),
        source: MicroEvidenceSource.review,
        taskKey: 'review:plus:47:8',
      ),
      _observation(
        at: base.add(const Duration(days: 3, minutes: 1)),
        source: MicroEvidenceSource.review,
        taskKey: 'review:plus:46:9',
      ),
      _observation(
        at: base.add(const Duration(days: 4)),
        source: MicroEvidenceSource.transfer,
        taskKey: 'story:transfer:skill:additionTenBridge:+:books:47:8',
      ),
      _observation(
        at: base.add(const Duration(days: 4, minutes: 1)),
        source: MicroEvidenceSource.transfer,
        taskKey: 'story:transfer:skill:additionTenBridge:+:stickers:47:8',
      ),
    ];

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.additionTenBridge,
    );

    expect(progress.transferIndependentEvidence, closeTo(2, 0.001));
    expect(progress.transferIndependentTaskVariety, 1);
    expect(progress.state, MicroCompetencyState.secure);
  });

  test('Sachkontext allein erhoeht Vielfalt bei keiner Grundrechenart', () {
    final cases = <(MicroCompetencyId, String, String)>[
      (
        MicroCompetencyId.additionTenBridge,
        'story:transfer:skill:additionTenBridge:+:books:47:8',
        'story:transfer:skill:additionTenBridge:+:stickers:47:8',
      ),
      (
        MicroCompetencyId.subtractionTenBridge,
        'story:transfer:skill:subtractionTenBridge:-:cards:15:7',
        'story:transfer:skill:subtractionTenBridge:-:blocks:15:7',
      ),
      (
        MicroCompetencyId.multiplicationFacts,
        'story:transfer:skill:multiplicationFacts:x:tables:6:4',
        'story:transfer:skill:multiplicationFacts:x:packs:6:4',
      ),
      (
        MicroCompetencyId.divisionFacts,
        'story:transfer:skill:divisionFacts:divide:teams:24:6',
        'story:transfer:skill:divisionFacts:divide:packs:24:6',
      ),
    ];

    for (final (id, first, second) in cases) {
      final controller = AppController()
        ..gradeLevel = GradeLevel.second
        ..numberRange = NumberRangeLevel.hundred
        ..microObservations = <MicroCompetencyObservation>[
          _observation(
            id: id,
            at: DateTime(2026, 9, 12, 10),
            source: MicroEvidenceSource.transfer,
            taskKey: first,
          ),
          _observation(
            id: id,
            at: DateTime(2026, 9, 12, 10, 1),
            source: MicroEvidenceSource.transfer,
            taskKey: second,
          ),
        ];

      final progress = controller.microCompetencyProgress(id);
      expect(progress.transferIndependentEvidence, closeTo(2, 0.001));
      expect(progress.transferIndependentTaskVariety, 1, reason: id.name);
    }
  });

  test('andere Rechnung im Transfer bleibt neue Vielfalt', () {
    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.hundred;
    final base = DateTime(2026, 9, 10, 9);

    controller.microObservations = <MicroCompetencyObservation>[
      for (var index = 0; index < 6; index++)
        _observation(
          at: base.add(Duration(minutes: index)),
          source: MicroEvidenceSource.practice,
          taskKey: 'plus:${41 + index}:${9 - index}',
        ),
      _observation(
        at: base.add(const Duration(days: 3)),
        source: MicroEvidenceSource.review,
        taskKey: 'review:plus:47:8',
      ),
      _observation(
        at: base.add(const Duration(days: 3, minutes: 1)),
        source: MicroEvidenceSource.review,
        taskKey: 'review:plus:46:9',
      ),
      _observation(
        at: base.add(const Duration(days: 4)),
        source: MicroEvidenceSource.transfer,
        taskKey: 'story:transfer:skill:additionTenBridge:+:books:47:8',
      ),
      _observation(
        at: base.add(const Duration(days: 4, minutes: 1)),
        source: MicroEvidenceSource.transfer,
        taskKey: 'story:transfer:skill:additionTenBridge:+:stickers:46:9',
      ),
    ];

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.additionTenBridge,
    );

    expect(progress.transferIndependentTaskVariety, 2);
    expect(progress.state, MicroCompetencyState.mastered);
  });
}
