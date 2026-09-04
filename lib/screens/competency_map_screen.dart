import 'package:flutter/material.dart';

import '../models/error_diagnosis.dart';
import '../models/learning_path.dart';
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

  Future<void> _open(TrainingMode mode) async {
    if (mode.isUpperPrimary) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CurriculumTrainingScreen(
            controller: widget.controller,
            mode: mode,
          ),
        ),
      );
    } else if (mode.isStructured) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StructuredTrainingScreen(
            controller: widget.controller,
            mode: mode,
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
    final all = groups.expand((group) => group.$2).toList();
    final mastered = all
        .where(
          (mode) =>
              widget.controller.competencyProgress(mode).state ==
              CompetencyState.mastered,
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
                    '${widget.controller.gradeLevel.label} · $mastered von ${all.length} Bereichen gemeistert',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Die Klassenstufe legt den Lehrplanrahmen fest. Der tatsächliche Lernstand entscheidet, was als Nächstes geübt wird.',
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
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      onTap: () => _open(mode),
                      leading: _StateIcon(state: progress.state),
                      title: Text(
                        mode.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
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
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: Chip(label: Text(progress.state.label)),
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
