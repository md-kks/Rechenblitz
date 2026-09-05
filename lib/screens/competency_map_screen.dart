import 'package:flutter/material.dart';

import '../models/error_diagnosis.dart';
import '../models/learning_path.dart';
import '../models/micro_competency.dart';
import '../models/remediation_path.dart';
import '../models/training.dart';
import '../services/app_controller.dart';
import 'curriculum_training_screen.dart';
import 'structured_training_screen.dart';
import 'training_screen.dart';

class CompetencyMapScreen extends StatefulWidget {
  const CompetencyMapScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<CompetencyMapScreen> createState() => _CompetencyMapScreenState();
}

class _CompetencyMapScreenState extends State<CompetencyMapScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _open(
    TrainingMode mode, {
    MicroCompetencyId? targetCompetency,
  }) async {
    if (mode.isUpperPrimary) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CurriculumTrainingScreen(
            controller: widget.controller,
            mode: mode,
            targetCompetency: targetCompetency,
          ),
        ),
      );
    } else if (mode.isStructured) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StructuredTrainingScreen(
            controller: widget.controller,
            mode: mode,
            targetCompetency: targetCompetency,
          ),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TrainingScreen(
            controller: widget.controller,
            mode: mode,
            targetTasks: 10,
            targetCompetency: targetCompetency,
          ),
        ),
      );
    }
  }

  List<(String, List<TrainingMode>)> _groups() {
    final grade = widget.controller.gradeLevel;
    if (grade.index < GradeLevel.third.index) {
      final modes = widget.controller.learningModesForGrade(grade);
      final numbers = modes.where(
        (mode) => {
          TrainingMode.practice,
          TrainingMode.minus,
          TrainingMode.multiply,
          TrainingMode.divide,
          TrainingMode.numberFriends,
          TrainingMode.missingNumber,
          TrainingMode.neighbors,
          TrainingMode.placeValue,
          TrainingMode.doublesHalves,
          TrainingMode.sequences,
          TrainingMode.factFamilies,
          TrainingMode.numberWall,
        }.contains(mode),
      ).toList();
      final everyday = modes.where(
        (mode) => {
          TrainingMode.wordProblems,
          TrainingMode.money,
          TrainingMode.clock,
          TrainingMode.measures,
          TrainingMode.geometry,
        }.contains(mode),
      ).toList();
      return [
        ('Zahlen & Rechnen', numbers),
        if (everyday.isNotEmpty)
          ('Sachrechnen, Größen & Geometrie', everyday),
      ];
    }

    return [
      (
        'Zahlen & Operationen',
        [
          TrainingMode.multiply,
          TrainingMode.divide,
          TrainingMode.largeNumbers,
          TrainingMode.rounding,
          TrainingMode.mentalStrategies,
          TrainingMode.writtenAddSub,
          TrainingMode.writtenMultiply,
          TrainingMode.writtenDivide,
          TrainingMode.estimation,
          TrainingMode.arithmeticLaws,
          TrainingMode.romanNumerals,
          TrainingMode.fractions,
        ],
      ),
      (
        'Größen & Sachrechnen',
        [
          TrainingMode.wordProblems,
          TrainingMode.advancedMeasures,
          TrainingMode.timeDurations,
          TrainingMode.proportionality,
        ],
      ),
      (
        'Raum & Form',
        [
          TrainingMode.perimeterArea,
          TrainingMode.geometryBodies,
          TrainingMode.symmetry,
          TrainingMode.plansAndOrientation,
          TrainingMode.volumeCubes,
        ],
      ),
      (
        'Daten, Muster & Zufall',
        [
          TrainingMode.dataCharts,
          TrainingMode.probability,
          TrainingMode.combinatorics,
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups();
    final micro = widget.controller.microCompetenciesForGrade();
    final mastered = micro
        .where(
          (progress) =>
              progress.state == MicroCompetencyState.mastered,
        )
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Meine Lernlandkarte')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 34),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.controller.gradeLevel.label} · $mastered von ${micro.length} Teilschritten gemeistert',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Die großen Lernbereiche bleiben sichtbar. Darunter zeigt Rechenblitz jetzt die einzelnen mathematischen Teilschritte und ihre Evidenz.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          ...groups.expand(
            (group) => [
              Text(
                group.$1,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              ...group.$2.map((mode) {
                final progress = widget.controller.competencyProgress(mode);
                final diagnostic =
                    widget.controller.topDiagnosticForMode(mode);
                final remediationStatus = diagnostic == null
                    ? null
                    : widget.controller
                        .remediationStatusFor(diagnostic.pattern);
                final micro = widget.controller
                    .microCompetenciesForMode(mode);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: Column(
                      children: [
                        ListTile(
                          onTap: () => _open(mode),
                          leading: _StateIcon(state: progress.state),
                          title: Text(
                            mode.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                progress.tasks == 0
                                    ? 'Noch nicht bearbeitet'
                                    : '${progress.tasks} Aufgaben · ${(progress.accuracy * 100).round()} % direkt richtig',
                              ),
                              if (diagnostic != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  remediationStatus == null
                                      ? 'Auffällig: ${diagnostic.pattern.label} · ${diagnostic.confidenceLabel}'
                                      : 'Knacknuss: ${diagnostic.pattern.label} · ${remediationStatus.label}',
                                  style: TextStyle(
                                    color: remediationStatus ==
                                                RemediationStatus.improved ||
                                            remediationStatus ==
                                                RemediationStatus.stable
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .error,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing:
                              Chip(label: Text(progress.state.label)),
                        ),
                        if (micro.isNotEmpty) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              10,
                              16,
                              12,
                            ),
                            child: Column(
                              children: micro
                                  .map(
                                    (step) => _MicroStepTile(
                                      progress: step,
                                      onTap: () => _open(
                                        mode,
                                        targetCompetency:
                                            step.definition.id,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 14),
            ],
          ),
        ],
      ),
    );
  }
}

class _MicroStepTile extends StatelessWidget {
  const _MicroStepTile({
    required this.progress,
    required this.onTap,
  });

  final MicroCompetencyProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reviewDetail = progress.reviewObservations == 0
        ? 'Abstand: noch offen'
        : 'Abstand: ${(progress.reviewIndependentAccuracy * 100).round()} % selbstständig';
    final transferDetail = progress.transferObservations == 0
        ? 'Transfer: noch offen'
        : 'Transfer: ${(progress.transferIndependentAccuracy * 100).round()} % selbstständig';
    final helpDetail = progress.aidedObservations == 0
        ? 'Hilfe: bisher nicht benötigt'
        : 'Hilfe: ${progress.aidedObservations} Beobachtungen';
    final independentStepDetail =
        progress.independentStepObservations == 0
            ? null
            : 'Eigenständige Teilfragen: ${(progress.independentStepAccuracy * 100).round()} % · '
                '${progress.independentStepObservations} erste Versuche';
    final guidedDetail = progress.guidedStepObservations == 0
        ? null
        : 'Geführte Teilfragen: ${(progress.guidedStepAccuracy * 100).round()} % · '
            '${progress.guidedStepObservations} erste Versuche';
    final detail = progress.observations == 0
        ? progress.state.label
        : '${progress.state.label}\n'
            'Selbstständig: ${(progress.independentAccuracy * 100).round()} % · '
            '${progress.independentEvidence.toStringAsFixed(1)} Evidenz\n'
            '$helpDetail\n'
            '${independentStepDetail == null ? '' : '$independentStepDetail\n'}'
            '${guidedDetail == null ? '' : '$guidedDetail\n'}'
            '$reviewDetail · $transferDetail';
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(
        switch (progress.state) {
          MicroCompetencyState.newSkill =>
            Icons.radio_button_unchecked_rounded,
          MicroCompetencyState.discovering =>
            Icons.explore_outlined,
          MicroCompetencyState.practicing =>
            Icons.timelapse_rounded,
          MicroCompetencyState.secure =>
            Icons.check_circle_outline_rounded,
          MicroCompetencyState.mastered =>
            Icons.workspace_premium_rounded,
        },
        size: 20,
      ),
      title: Text(
        progress.definition.label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(detail),
      trailing: const Icon(Icons.play_arrow_rounded, size: 20),
    );
  }
}

class _StateIcon extends StatelessWidget {
  const _StateIcon({required this.state});

  final CompetencyState state;

  @override
  Widget build(BuildContext context) {
    final icon = switch (state) {
      CompetencyState.newSkill => Icons.radio_button_unchecked_rounded,
      CompetencyState.learning => Icons.timelapse_rounded,
      CompetencyState.secure => Icons.check_circle_outline_rounded,
      CompetencyState.mastered => Icons.workspace_premium_rounded,
    };
    return CircleAvatar(child: Icon(icon));
  }
}
