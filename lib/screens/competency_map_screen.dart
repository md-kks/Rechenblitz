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
    final unlock = widget.controller.microCompetencyUnlockStatus(
      progress.definition.id,
    );
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
                if (unlock.hasPrerequisites) ...[
                  Card(
                    key: ValueKey(
                      'micro-unlock:${progress.definition.id.name}',
                    ),
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                unlock.isUnlocked
                                    ? Icons.lock_open_rounded
                                    : Icons.lock_outline_rounded,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  unlock.isUnlocked
                                      ? 'Freigeschaltet'
                                      : 'Noch nicht freigeschaltet',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(unlock.reason),
                          if (!unlock.isUnlocked &&
                              unlock.nextRequired != null) ...[
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              key: ValueKey(
                                'micro-unlock-practice:${progress.definition.id.name}',
                              ),
                              onPressed: () {
                                final next = unlock.nextRequired!;
                                Navigator.of(context).pop();
                                _open(
                                  next.preferredMode,
                                  targetCompetency: next.id,
                                );
                              },
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: Text('Zuerst „${unlock.nextRequired!.label}“ üben'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                _EvidenceLine(label: 'Allein', value: independent),
                _EvidenceLine(label: 'Mit Hilfe', value: aided),
                _EvidenceLine(label: 'Später noch einmal', value: review),
                _EvidenceLine(label: 'Bei anderer Aufgabe', value: transfer),
                const SizedBox(height: 10),
                Card(
                  key: ValueKey('micro-stability:${progress.definition.id.name}'),
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.event_repeat_rounded, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.controller.microStabilityScheduleText(
                              progress.definition.id,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
    final gradeBridge = widget.controller.gradeBridgeStatus();
    final rangeBridge = widget.controller.numberRangeBridgeStatus();
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
          if (gradeBridge.isActive) ...[
            Card(
              key: const ValueKey('learning-map-grade-bridge'),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.school_rounded),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Grundlagen aus ${gradeBridge.previousGrade!.label} bestätigen',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(gradeBridge.reason),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      key: const ValueKey('learning-map-grade-bridge-progress'),
                      value: gradeBridge.progress,
                      minHeight: 9,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Wichtig: Sicher in ${gradeBridge.previousGrade!.label} wird nicht automatisch als sicher in ${gradeBridge.currentGrade.label} gewertet. Rechenblitz bestätigt die Grundlage kurz mit Aufgaben der neuen Klassenstufe.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (rangeBridge.isActive) ...[
            Card(
              key: const ValueKey('learning-map-range-bridge'),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.compare_arrows_rounded),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Grundlagen in ${rangeBridge.currentRange.label} bestätigen',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(rangeBridge.reason),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: rangeBridge.progress,
                      minHeight: 9,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Wichtig: Sicher in ${rangeBridge.previousRange!.label} wird nicht automatisch als sicher in ${rangeBridge.currentRange.label} gewertet. Rechenblitz prüft die Grundlage erst kurz mit größeren Zahlen.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
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
                          unlockStatus: widget.controller.microCompetencyUnlockStatus,
                          onOpenMicro: (progress) => _open(
                            mode,
                            targetCompetency: progress.definition.id,
                          ),
                          onOpenPrerequisite: (id) {
                            final definition =
                                MicroCompetencyCatalog.definition(id);
                            _open(
                              definition.preferredMode,
                              targetCompetency: id,
                            );
                          },
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
    required this.unlockStatus,
    required this.onOpenMicro,
    required this.onOpenPrerequisite,
    required this.onInfo,
  });

  final TrainingMode mode;
  final CompetencyProgress progress;
  final List<MicroCompetencyProgress> micro;
  final VoidCallback onOpenMode;
  final MicroCompetencyUnlockStatus Function(MicroCompetencyId) unlockStatus;
  final ValueChanged<MicroCompetencyProgress> onOpenMicro;
  final ValueChanged<MicroCompetencyId> onOpenPrerequisite;
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
    final locked = micro
        .where((entry) => !unlockStatus(entry.definition.id).isUnlocked)
        .length;
    final summary = micro.isEmpty
        ? progress.state.label
        : '$microSafe von ${micro.length} Schritten sicher'
            '${locked == 0 ? '' : ' · $locked warten auf Grundlagen'}';

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
              (entry) {
                final unlock = unlockStatus(entry.definition.id);
                return _MicroStepTile(
                  progress: entry,
                  unlock: unlock,
                  onTap: () => onOpenMicro(entry),
                  onPrerequisite: unlock.nextRequired == null
                      ? null
                      : () => onOpenPrerequisite(unlock.nextRequired!.id),
                  onInfo: () => onInfo(entry),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _MicroStepTile extends StatelessWidget {
  const _MicroStepTile({
    required this.progress,
    required this.unlock,
    required this.onTap,
    required this.onPrerequisite,
    required this.onInfo,
  });

  final MicroCompetencyProgress progress;
  final MicroCompetencyUnlockStatus unlock;
  final VoidCallback onTap;
  final VoidCallback? onPrerequisite;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final locked = !unlock.isUnlocked;
    return ListTile(
      key: ValueKey('micro-step:${progress.definition.id.name}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      onTap: locked ? onPrerequisite : onTap,
      leading: Icon(
        locked ? Icons.lock_outline_rounded : _microIcon(progress.state),
        size: 22,
      ),
      title: Text(progress.definition.label),
      subtitle: Text(
        locked && unlock.nextRequired != null
            ? 'Zuerst: ${unlock.nextRequired!.label}'
            : progress.state.label,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: ValueKey('micro-info:${progress.definition.id.name}'),
            tooltip: 'Lernstand ansehen',
            onPressed: onInfo,
            icon: const Icon(Icons.info_outline_rounded),
          ),
          if (locked)
            IconButton(
              key: ValueKey(
                'micro-prerequisite:${progress.definition.id.name}',
              ),
              tooltip: 'Fehlende Grundlage üben',
              onPressed: onPrerequisite,
              icon: const Icon(Icons.arrow_back_rounded),
            )
          else
            const Icon(Icons.play_arrow_rounded),
        ],
      ),
    );
  }
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
