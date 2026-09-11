import 'package:flutter/material.dart';

import '../models/learning_path.dart';
import '../models/micro_competency.dart';
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
      final numbers = modes
          .where(
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
          )
          .toList();
      final everyday = modes
          .where(
            (mode) => {
              TrainingMode.wordProblems,
              TrainingMode.money,
              TrainingMode.clock,
              TrainingMode.measures,
              TrainingMode.geometry,
            }.contains(mode),
          )
          .toList();
      return [
        ('Zahlen & Rechnen', numbers),
        if (everyday.isNotEmpty) ('Sachrechnen, Größen & Geometrie', everyday),
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

  Future<void> _showMicroDetails(MicroCompetencyProgress progress) async {
    final independent = progress.hasIndependentBasisEvidence
        ? '${(progress.independentAccuracy * 100).round()} % richtig'
        : 'noch nicht allein probiert';
    final aided = progress.aidedObservations == 0
        ? 'noch keine Hilfe gebraucht'
        : '${progress.aidedObservations}× mit Hilfe';
    final review = progress.reviewObservations == 0
        ? 'noch nicht wiederholt'
        : !progress.hasIndependentReviewEvidence
        ? 'bisher mit Hilfe'
        : '${(progress.reviewIndependentAccuracy * 100).round()} % allein richtig';
    final transfer = progress.transferObservations == 0
        ? 'noch nicht in anderer Aufgabe probiert'
        : !progress.hasIndependentTransferEvidence
        ? 'bisher mit Hilfe'
        : '${(progress.transferIndependentAccuracy * 100).round()} % allein richtig';

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  progress.definition.label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  progress.state.label,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 18),
                _EvidenceLine(label: 'Allein', value: independent),
                _EvidenceLine(label: 'Mit Hilfe', value: aided),
                _EvidenceLine(label: 'Später noch einmal', value: review),
                _EvidenceLine(label: 'Bei anderer Aufgabe', value: transfer),
                const SizedBox(height: 10),
                Text(
                  'Hilfe ist völlig okay. Sie zählt hier nur nicht als allein geschafft.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups();
    final allMicro = widget.controller.microCompetenciesForGrade();
    final safe = allMicro
        .where(
          (progress) =>
              progress.state == MicroCompetencyState.secure ||
              progress.state == MicroCompetencyState.mastered,
        )
        .length;
    final progressText = allMicro.isEmpty
        ? 'Deine Lernkarte füllt sich beim Üben Schritt für Schritt.'
        : safe == allMicro.length
        ? 'Alle Schritte in deiner Lernkarte sind sicher.'
        : safe == 0
        ? 'Deine Lernkarte füllt sich beim Üben Schritt für Schritt.'
        : 'Erste Schritte sind schon sicher. Wir machen Schritt für Schritt weiter.';
    final focus =
        widget.controller.currentMicroFocus() ??
        widget.controller.nextNewMicroCompetency();

    return Scaffold(
      appBar: AppBar(title: const Text('Lernlandkarte')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
        children: [
          if (focus != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Als Nächstes',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      focus.definition.label,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      focus.state == MicroCompetencyState.newSkill
                          ? 'Diesen Schritt kannst du jetzt neu entdecken.'
                          : 'Diesen Schritt üben wir jetzt weiter.',
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      key: const ValueKey('learning-map-next-button'),
                      onPressed: () => _open(
                        focus.definition.preferredMode,
                        targetCompetency: focus.definition.id,
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Jetzt üben'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dein Fortschritt',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    progressText,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: allMicro.isEmpty ? 0 : safe / allMicro.length,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.controller.gradeLevel.label,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          ...groups.map((group) {
            final groupSteps = group.$2
                .expand(widget.controller.microCompetenciesForMode)
                .toList();
            final groupSafe = groupSteps
                .where(
                  (progress) =>
                      progress.state == MicroCompetencyState.secure ||
                      progress.state == MicroCompetencyState.mastered,
                )
                .length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ExpansionTile(
                  key: ValueKey('learning-group:${group.$1}'),
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(group.$1),
                  subtitle: Text(
                    groupSteps.isEmpty
                        ? 'Noch keine Schritte'
                        : '$groupSafe von ${groupSteps.length} sicher',
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  children: group.$2
                      .map(
                        (mode) => _ModeTile(
                          mode: mode,
                          progress: widget.controller.competencyProgress(mode),
                          micro: widget.controller.microCompetenciesForMode(
                            mode,
                          ),
                          onOpenMode: () => _open(mode),
                          onOpenMicro: (progress) => _open(
                            mode,
                            targetCompetency: progress.definition.id,
                          ),
                          onInfo: _showMicroDetails,
                        ),
                      )
                      .toList(),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.mode,
    required this.progress,
    required this.micro,
    required this.onOpenMode,
    required this.onOpenMicro,
    required this.onInfo,
  });

  final TrainingMode mode;
  final CompetencyProgress progress;
  final List<MicroCompetencyProgress> micro;
  final VoidCallback onOpenMode;
  final ValueChanged<MicroCompetencyProgress> onOpenMicro;
  final ValueChanged<MicroCompetencyProgress> onInfo;

  @override
  Widget build(BuildContext context) {
    final microSafe = micro
        .where(
          (entry) =>
              entry.state == MicroCompetencyState.secure ||
              entry.state == MicroCompetencyState.mastered,
        )
        .length;
    final summary = micro.isEmpty
        ? progress.state.label
        : '$microSafe von ${micro.length} Schritten sicher';

    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ExpansionTile(
        key: ValueKey('learning-mode:${mode.name}'),
        leading: _StateIcon(state: progress.state),
        title: Text(mode.title),
        subtitle: Text(summary),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onOpenMode,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Bereich üben'),
            ),
          ),
          if (micro.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 4, 4, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Hier gibt es noch keine einzelnen Schritte.'),
              ),
            )
          else
            ...micro.map(
              (entry) => _MicroStepTile(
                progress: entry,
                onTap: () => onOpenMicro(entry),
                onInfo: () => onInfo(entry),
              ),
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
    required this.onInfo,
  });

  final MicroCompetencyProgress progress;
  final VoidCallback onTap;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    onTap: onTap,
    leading: Icon(_microIcon(progress.state), size: 22),
    title: Text(progress.definition.label),
    subtitle: Text(progress.state.label),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: ValueKey('micro-info:${progress.definition.id.name}'),
          tooltip: 'Lernstand ansehen',
          onPressed: onInfo,
          icon: const Icon(Icons.info_outline_rounded),
        ),
        const Icon(Icons.play_arrow_rounded),
      ],
    ),
  );
}

IconData _microIcon(MicroCompetencyState state) => switch (state) {
  MicroCompetencyState.newSkill => Icons.radio_button_unchecked_rounded,
  MicroCompetencyState.discovering => Icons.explore_outlined,
  MicroCompetencyState.practicing => Icons.timelapse_rounded,
  MicroCompetencyState.secure => Icons.check_circle_outline_rounded,
  MicroCompetencyState.mastered => Icons.workspace_premium_rounded,
};

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
    return Icon(icon, size: 24);
  }
}

class _EvidenceLine extends StatelessWidget {
  const _EvidenceLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: Text(value, textAlign: TextAlign.end)),
      ],
    ),
  );
}
