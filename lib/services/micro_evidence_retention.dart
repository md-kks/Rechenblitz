import '../models/micro_competency.dart';

/// Keeps micro-competency evidence bounded without letting high-volume areas
/// erase quieter competencies from a learner's history.
class MicroEvidenceRetention {
  static const int maxStoredObservations = 1200;

  static List<MicroCompetencyObservation> compact(
    Iterable<MicroCompetencyObservation> input, {
    int maxObservations = maxStoredObservations,
  }) {
    if (maxObservations <= 0) return <MicroCompetencyObservation>[];
    final sorted = input.toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    if (sorted.length <= maxObservations) return sorted;

    final buckets = <String, _RetentionBucket>{};
    for (final observation in sorted) {
      final key = '${observation.id.name}|${observation.gradeLevel.name}|${observation.numberRange.name}';
      final bucket = buckets.putIfAbsent(key, _RetentionBucket.new);
      switch (observation.source) {
        case MicroEvidenceSource.practice:
        case MicroEvidenceSource.remediation:
          bucket.basis.add(observation);
          break;
        case MicroEvidenceSource.review:
          bucket.review.add(observation);
          break;
        case MicroEvidenceSource.transfer:
          bucket.transfer.add(observation);
          break;
        case MicroEvidenceSource.independentStep:
          bucket.independentStep.add(observation);
          break;
        case MicroEvidenceSource.guidedStep:
          bucket.guidedStep.add(observation);
          break;
      }
    }

    final selected = <MicroCompetencyObservation>{};
    final groups = buckets.values.toList(growable: false);

    void keepRound(
      List<MicroCompetencyObservation> Function(_RetentionBucket) channel,
      int index,
    ) {
      if (selected.length >= maxObservations) return;
      for (final group in groups) {
        final values = channel(group);
        if (index < values.length) selected.add(values[index]);
        if (selected.length >= maxObservations) return;
      }
    }

    // First preserve the latest state of every evidence channel fairly.
    for (final channel in <List<MicroCompetencyObservation> Function(_RetentionBucket)>[
      (g) => g.basis,
      (g) => g.review,
      (g) => g.transfer,
      (g) => g.independentStep,
      (g) => g.guidedStep,
    ]) {
      keepRound(channel, 0);
    }

    // Preserve enough core evidence for secure/mastered thresholds.
    for (var index = 1; index < 2; index++) {
      keepRound((g) => g.basis, index);
      keepRound((g) => g.review, index);
      keepRound((g) => g.transfer, index);
    }
    for (var index = 2; index < 6; index++) {
      keepRound((g) => g.basis, index);
    }

    // Keep additional recent context for accuracy, recovery and guided-step fading.
    for (var index = 6; index < 8; index++) {
      keepRound((g) => g.basis, index);
    }
    keepRound((g) => g.review, 2);
    keepRound((g) => g.transfer, 2);
    for (var index = 1; index < 6; index++) {
      keepRound((g) => g.independentStep, index);
    }
    for (var index = 1; index < 8; index++) {
      keepRound((g) => g.guidedStep, index);
    }

    // Spend remaining capacity on the globally newest evidence.
    for (final observation in sorted) {
      if (selected.length >= maxObservations) break;
      selected.add(observation);
    }

    return sorted
        .where(selected.contains)
        .take(maxObservations)
        .toList(growable: false);
  }
}

class _RetentionBucket {
  final List<MicroCompetencyObservation> basis = <MicroCompetencyObservation>[];
  final List<MicroCompetencyObservation> review = <MicroCompetencyObservation>[];
  final List<MicroCompetencyObservation> transfer = <MicroCompetencyObservation>[];
  final List<MicroCompetencyObservation> independentStep = <MicroCompetencyObservation>[];
  final List<MicroCompetencyObservation> guidedStep = <MicroCompetencyObservation>[];
}
