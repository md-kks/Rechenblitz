import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/remediation_path.dart';
import 'package:rechenblitz/models/training.dart';

void main() {
  test('jede gezielte Sammelförderung bleibt über alle Stufen semantisch intakt', () {
    final failures = <String>[];
    for (final entry in RemediationGenerator.focusableCompetencies.entries) {
      for (final competency in entry.value) {
        final definition = MicroCompetencyCatalog.definition(competency);
        final grade = definition.appliesTo(GradeLevel.fourth)
            ? GradeLevel.fourth : definition.minGrade;
        final range = _rangeFor(definition);
        final plan = RemediationGenerator(
          random: Random(91000 + competency.index),
        ).generate(
          pattern: entry.key,
          preferredMode: definition.preferredMode,
          grade: grade,
          range: range,
          methods: const MethodPreferences(),
          targetCompetency: competency,
        );
        final stages = {for (final task in plan.tasks) task.stage};
        for (final requiredStage in RemediationStage.values) {
          if (!stages.contains(requiredStage)) {
            failures.add('${entry.key.name}/${competency.name}: Stufe ${requiredStage.name} fehlt');
          }
        }
        for (final task in plan.tasks) {
          if (task.effectiveTargetCompetency != competency) {
            failures.add('${entry.key.name}/${competency.name}/${task.stage.name}: Ziel=${task.effectiveTargetCompetency?.name}');
          }
          final tags = MicroCompetencyCatalog.tagsForTask(
            mode: task.mode,
            taskKey: task.sourceTaskKey,
          );
          if (!tags.any((tag) => tag.id == competency)) {
            failures.add('${entry.key.name}/${competency.name}/${task.stage.name}: Aufgabe taggt Ziel nicht (${task.sourceTaskKey})');
          }
          final expectedSource = switch (task.stage) {
            RemediationStage.guided || RemediationStage.supported =>
              MicroEvidenceSource.remediation,
            RemediationStage.transfer => MicroEvidenceSource.transfer,
            RemediationStage.check => MicroEvidenceSource.review,
          };
          if (task.stage.evidenceSource != expectedSource) {
            failures.add('${entry.key.name}/${competency.name}/${task.stage.name}: Evidenz=${task.stage.evidenceSource.name}');
          }
        }
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}

NumberRangeLevel _rangeFor(MicroCompetencyDefinition definition) {
  const descending = [
    NumberRangeLevel.million,
    NumberRangeLevel.tenThousand,
    NumberRangeLevel.thousand,
    NumberRangeLevel.hundred,
    NumberRangeLevel.twenty,
    NumberRangeLevel.ten,
  ];
  return descending.firstWhere(definition.appliesToNumberRange);
}
