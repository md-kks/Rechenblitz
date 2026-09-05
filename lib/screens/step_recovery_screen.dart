import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/guided_method.dart';
import '../models/remediation_path.dart';
import '../services/app_controller.dart';
import '../widgets/number_answer_pad.dart';

class StepRecoveryScreen extends StatefulWidget {
  const StepRecoveryScreen({
    super.key,
    required this.controller,
    required this.focus,
  });

  final AppController controller;
  final IndependentStepRecoveryFocus focus;

  @override
  State<StepRecoveryScreen> createState() => _StepRecoveryScreenState();
}

class _StepRecoveryScreenState extends State<StepRecoveryScreen> {
  late final StepRecoveryPlan plan;
  int index = 0;
  int wrongOnCurrent = 0;
  bool locked = false;
  bool finishing = false;
  bool showHint = false;
  String feedback = '';

  RemediationTask get current => plan.tasks[index];

  bool get _autoHint => current.stage == RemediationStage.supported;

  int get _helpLevel =>
      (_autoHint || showHint) ? HelpLevel.nudge.value : HelpLevel.none.value;

  @override
  void initState() {
    super.initState();
    plan = StepRecoveryGenerator().generate(
      focus: widget.focus,
      range: widget.controller.numberRange,
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(widget.controller.speak(current.prompt)),
    );
  }

  Future<void> _answer(int answer) async {
    if (locked || finishing) return;

    final correct = answer == current.answer;
    if (wrongOnCurrent == 0) {
      await widget.controller.recordIndependentStepAttempt(
        mode: current.mode,
        taskKey: current.taskKey,
        stepKey: widget.focus.stepKey,
        competencyId: widget.focus.competencyId,
        correct: correct,
        usedHelp: _helpLevel > 0,
        helpLevel: _helpLevel,
        evidenceWeight: 0.35,
      );
    }

    if (!correct) {
      wrongOnCurrent += 1;
      setState(() {
        showHint = true;
        feedback = wrongOnCurrent == 1
            ? 'Noch nicht. Prüfe genau diesen Rechenschritt.'
            : 'Nutze den Hinweis und probiere den Schritt noch einmal.';
      });
      return;
    }

    locked = true;
    if (widget.controller.hapticEnabled) HapticFeedback.lightImpact();
    if (widget.controller.soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }

    setState(() {
      feedback = wrongOnCurrent == 0
          ? 'Richtig. Dieser Rechenschritt stimmt.'
          : 'Geschafft. Jetzt ist der Rechenschritt klar.';
    });

    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted || finishing) return;

    if (index + 1 >= plan.tasks.length) {
      await _finish();
      return;
    }

    setState(() {
      index += 1;
      wrongOnCurrent = 0;
      locked = false;
      showHint = false;
      feedback = '';
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(widget.controller.speak(current.prompt)),
    );
  }

  Future<void> _finish() async {
    if (finishing) return;
    finishing = true;

    final nextFocus = widget.controller.independentStepRecoveryFocus();
    final recovered = nextFocus == null ||
        nextFocus.competencyId != widget.focus.competencyId ||
        nextFocus.stepKey != widget.focus.stepKey;

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          recovered
              ? 'Rechenschritt bestätigt'
              : 'Rechenschritt bleibt im Blick',
        ),
        content: Text(
          recovered
              ? 'Der zuvor unsichere Schritt wurde jetzt zweimal selbstständig richtig bestätigt. Rechenblitz kehrt wieder zum normalen Lernfluss zurück.'
              : 'Mindestens eine selbstständige Bestätigung war noch unsicher. Rechenblitz behält genau diesen Schritt als aktuellen Fokus, ohne eine Endlosschleife zu starten.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(true);
            },
            child: const Text('Fertig'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stage = current.stage;
    final progress = (index + 1) / plan.tasks.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Rechenschritt festigen')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${index + 1}/${plan.tasks.length}'),
              ],
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_stageIcon(stage)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stage.label,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stage == RemediationStage.supported
                                ? 'Ein kurzer Hinweis richtet den Blick nur auf den unsicheren Teilschritt.'
                                : stage == RemediationStage.transfer
                                    ? 'Jetzt löst du denselben Teilschritt an einer veränderten Aufgabe selbst.'
                                    : 'Zum Schluss wird derselbe Teilschritt noch einmal ohne Starthilfe geprüft.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.focus.label,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              current.prompt,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                height: 1.3,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            if (_autoHint || showHint)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded),
                      const SizedBox(width: 10),
                      Expanded(child: Text(current.hint)),
                    ],
                  ),
                ),
              ),
            if (!_autoHint &&
                !showHint &&
                stage != RemediationStage.check)
              TextButton.icon(
                onPressed: () => setState(() => showHint = true),
                icon: const Icon(Icons.lightbulb_outline_rounded),
                label: const Text('Hinweis anzeigen'),
              ),
            if (stage == RemediationStage.check && !showHint)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'Kontrolle: Starte ohne Hilfe. Nur der erste Versuch zählt als selbstständige Bestätigung.',
                  ),
                ),
              ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                feedback,
                key: ValueKey(feedback),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 18),
            if (current.usesChoices)
              ...List.generate(
                current.choices!.length,
                (choiceIndex) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FilledButton.tonal(
                    onPressed:
                        locked ? null : () => _answer(choiceIndex),
                    child: Text(current.choices![choiceIndex]),
                  ),
                ),
              )
            else
              NumberAnswerPad(
                key: ValueKey(
                  'step-recovery:$index:${current.taskKey}',
                ),
                maxValue: current.maxAnswerValue,
                onAnswer: _answer,
              ),
          ],
        ),
      ),
    );
  }

  IconData _stageIcon(RemediationStage stage) => switch (stage) {
        RemediationStage.guided => Icons.assistant_direction_rounded,
        RemediationStage.supported => Icons.lightbulb_outline_rounded,
        RemediationStage.transfer => Icons.psychology_alt_outlined,
        RemediationStage.check => Icons.fact_check_outlined,
      };
}
