import 'dart:async';

import 'package:flutter/material.dart';

import '../models/training.dart';
import '../services/app_controller.dart';
import 'parent_screen.dart';
import 'settings_screen.dart';
import 'training_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _parentGateTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _parentGateTimer?.cancel();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _startParentGate() {
    _parentGateTimer?.cancel();
    _parentGateTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      _parentGateTimer = null;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ParentScreen(controller: widget.controller),
        ),
      );
    });
  }

  void _cancelParentGate() {
    _parentGateTimer?.cancel();
    _parentGateTimer = null;
  }

  Future<void> _openMode(TrainingMode mode) async {
    if (mode == TrainingMode.tempo) {
      final config = await showModalBottomSheet<TempoConfig>(
        context: context,
        showDragHandle: true,
        builder: (_) => const _TempoConfigurator(),
      );
      if (!mounted || config == null) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TrainingScreen(
            controller: widget.controller,
            mode: mode,
            targetTasks: config.tasks,
            timeLimit: config.duration,
          ),
        ),
      );
      return;
    }
    final target = mode == TrainingMode.blitz ? 5 : 10;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrainingScreen(
          controller: widget.controller,
          mode: mode,
          targetTasks: target,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final today = controller.todayHistory.toList();
    final todayModes = today.map((e) => e.mode).toSet();
    final todayCorrect = today.fold<int>(0, (sum, e) => sum + e.correctFirstTry);
    final todayMinusCorrect = today.fold<int>(0, (sum, e) => sum + e.minusCorrect);
    final blitzRounds = today.where((e) => e.mode == TrainingMode.blitz).length;
    final speedRounds = controller.history
        .where((e) => (e.mode == TrainingMode.speed || e.mode == TrainingMode.tempo) && e.averageResponseMs > 0)
        .toList();
    final bestMs = speedRounds.isEmpty
        ? 0.0
        : speedRounds.map((e) => e.averageResponseMs).reduce((a, b) => a < b ? a : b);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechenblitz'),
        actions: [
          IconButton(
            tooltip: 'Einstellungen',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SettingsScreen(controller: controller),
              ),
            ),
            icon: const Icon(Icons.tune_rounded),
          ),
          Listener(
            key: const ValueKey('parent-gate'),
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => _startParentGate(),
            onPointerUp: (_) => _cancelParentGate(),
            onPointerCancel: (_) => _cancelParentGate(),
            child: Semantics(
              button: true,
              label: 'Elternbereich – 2 Sekunden gedrückt halten',
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Icon(Icons.admin_panel_settings_rounded),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'Hallo!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Wir machen dich sicher bei Plus und Minus bis 10.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => _openMode(controller.recommendedMode()),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Kurze Runde starten'),
            ),
            const SizedBox(height: 14),
            _ModeCard(
              icon: Icons.school_rounded,
              title: 'Üben',
              subtitle: 'Ganz ohne Zeitdruck',
              onTap: () => _openMode(TrainingMode.practice),
            ),
            const SizedBox(height: 10),
            _ModeCard(
              icon: Icons.remove_circle_outline_rounded,
              title: 'Minus üben',
              subtitle: 'Mit Hilfe, wenn du sie brauchst',
              onTap: () => _openMode(TrainingMode.minus),
            ),
            const SizedBox(height: 10),
            _ModeCard(
              icon: Icons.bolt_rounded,
              title: 'Schnell rechnen',
              subtitle: '10 kurze Aufgaben',
              onTap: () => _openMode(TrainingMode.speed),
            ),
            const SizedBox(height: 10),
            _ModeCard(
              icon: Icons.timer_outlined,
              title: 'Tempotest',
              subtitle: 'Wie morgen in der Schule',
              onTap: () => _openMode(TrainingMode.tempo),
            ),
            const SizedBox(height: 10),
            _ModeCard(
              icon: Icons.flash_on_rounded,
              title: '5 Blitzaufgaben',
              subtitle: 'Unter einer Minute üben',
              onTap: () => _openMode(TrainingMode.blitz),
            ),
            const SizedBox(height: 10),
            _ModeCard(
              icon: Icons.extension_rounded,
              title: 'Zahlenfreunde',
              subtitle: 'Zahlen zerlegen und ergänzen',
              onTap: () => _openMode(TrainingMode.numberFriends),
            ),
            const SizedBox(height: 26),
            Text('Heute', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 18,
                  runSpacing: 14,
                  children: [
                    _Stat(label: 'Runden', value: '${today.length}'),
                    _Stat(label: 'Aufgaben', value: '${controller.todayTasks}'),
                    _Stat(label: 'direkt richtig', value: '$todayCorrect'),
                    _Stat(label: 'Minus richtig', value: '$todayMinusCorrect'),
                    _Stat(label: 'Bestzeit Ø', value: bestMs == 0 ? '–' : '${(bestMs / 1000).toStringAsFixed(1)} s'),
                    _Stat(label: 'Sterne', value: '${controller.stars} ★'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text('Heute üben', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            _PlanItem(done: todayModes.contains(TrainingMode.practice), text: '5 Minuten sicher rechnen'),
            _PlanItem(done: todayModes.contains(TrainingMode.blitz), text: '5 Blitzaufgaben'),
            _PlanItem(done: todayModes.contains(TrainingMode.minus), text: '5 Minuten Minus-Training'),
            _PlanItem(done: todayModes.contains(TrainingMode.tempo), text: '1 Tempotest'),
            _PlanItem(done: blitzRounds >= 2, text: 'Abends noch einmal 5 Blitzaufgaben'),
            const SizedBox(height: 10),
            Text(
              'Du musst nicht alles schaffen. Jede kurze Runde zählt.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(radius: 24, child: Icon(icon)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(subtitle),
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          Text(label),
        ],
      );
}

class _PlanItem extends StatelessWidget {
  const _PlanItem({required this.done, required this.text});
  final bool done;
  final String text;
  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded),
        title: Text(text),
      );
}

class TempoConfig {
  const TempoConfig(this.tasks, this.duration);
  final int tasks;
  final Duration? duration;
}

class _TempoConfigurator extends StatefulWidget {
  const _TempoConfigurator();
  @override
  State<_TempoConfigurator> createState() => _TempoConfiguratorState();
}

class _TempoConfiguratorState extends State<_TempoConfigurator> {
  int tasks = 20;
  int minutes = 2;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tempotest einstellen', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            const Text('Aufgaben'),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 10, label: Text('10')),
                ButtonSegment(value: 20, label: Text('20')),
                ButtonSegment(value: 30, label: Text('30')),
              ],
              selected: {tasks},
              onSelectionChanged: (v) => setState(() => tasks = v.first),
            ),
            const SizedBox(height: 18),
            const Text('Zeit'),
            DropdownButtonFormField<int>(
              initialValue: minutes,
              items: const [
                DropdownMenuItem(value: 1, child: Text('1 Minute')),
                DropdownMenuItem(value: 2, child: Text('2 Minuten')),
                DropdownMenuItem(value: 3, child: Text('3 Minuten')),
                DropdownMenuItem(value: 0, child: Text('Ohne festes Limit')),
              ],
              onChanged: (v) => setState(() => minutes = v ?? 2),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                TempoConfig(tasks, minutes == 0 ? null : Duration(minutes: minutes)),
              ),
              child: const Text('Test starten'),
            ),
          ],
        ),
      );
}
