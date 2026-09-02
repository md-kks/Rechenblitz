import 'dart:async';

import 'package:flutter/material.dart';

import '../models/training.dart';
import '../services/app_controller.dart';
import 'parent_screen.dart';
import 'reward_screen.dart';
import 'settings_screen.dart';
import 'structured_training_screen.dart';
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
    if (mode.isStructured) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StructuredTrainingScreen(
            controller: widget.controller,
            mode: mode,
          ),
        ),
      );
      return;
    }

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
    final todayCorrect =
        today.fold<int>(0, (sum, e) => sum + e.correctFirstTry);
    final todayTotal = today.fold<int>(0, (sum, e) => sum + e.total);
    final todayAccuracy = todayTotal == 0 ? 0.0 : todayCorrect / todayTotal;
    final recommendation = controller.engine.recommendation(
      controller.facts,
      maxValue: controller.maxValue,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechenblitz'),
        actions: [
          IconButton(
            tooltip: 'Meine Erfolge',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RewardScreen(controller: controller),
              ),
            ),
            icon: const Icon(Icons.emoji_events_rounded),
          ),
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
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 36),
          children: [
            Text(
              'Hallo!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rechnen üben, verstehen und Schritt für Schritt sicherer werden.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zahlenraum',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<NumberRangeLevel>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: NumberRangeLevel.ten,
                            label: Text('bis 10'),
                          ),
                          ButtonSegment(
                            value: NumberRangeLevel.twenty,
                            label: Text('bis 20'),
                          ),
                          ButtonSegment(
                            value: NumberRangeLevel.hundred,
                            label: Text('bis 100'),
                          ),
                        ],
                        selected: {controller.numberRange},
                        onSelectionChanged: (values) =>
                            controller.setNumberRange(values.first),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      controller.numberRange == NumberRangeLevel.hundred
                          ? 'Aufgaben bauen weiterhin auf den Grundlagen bis 10 und 20 auf.'
                          : 'Die Aufgaben passen sich innerhalb dieses Zahlenraums an den Lernstand an.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RewardScreen(controller: controller),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 30),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${controller.stars} Sterne',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text('${controller.badges.length} Abzeichen'),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded),
                        const SizedBox(width: 8),
                        Text(
                          'Empfohlene Runde',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(recommendation),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _openMode(controller.recommendedMode()),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Passende Runde starten'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Schnell starten'),
            const SizedBox(height: 10),
            _LearningGrid(
              children: [
                _LearningTile(
                  icon: Icons.school_rounded,
                  title: 'Plus & Minus',
                  subtitle: 'adaptiv üben',
                  onTap: () => _openMode(TrainingMode.practice),
                ),
                _LearningTile(
                  icon: Icons.flash_on_rounded,
                  title: '5 Blitzaufgaben',
                  subtitle: 'kurze Runde',
                  onTap: () => _openMode(TrainingMode.blitz),
                ),
                _LearningTile(
                  icon: Icons.speed_rounded,
                  title: 'Schnell rechnen',
                  subtitle: 'Tempo trainieren',
                  onTap: () => _openMode(TrainingMode.speed),
                ),
                _LearningTile(
                  icon: Icons.fact_check_outlined,
                  title: 'Rechencheck',
                  subtitle: 'mit optionaler Zeit',
                  onTap: () => _openMode(TrainingMode.tempo),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Grundrechenarten'),
            const SizedBox(height: 10),
            _LearningGrid(
              children: [
                _LearningTile(
                  icon: Icons.remove_circle_outline_rounded,
                  title: 'Minus üben',
                  subtitle: 'mit Hilfen',
                  onTap: () => _openMode(TrainingMode.minus),
                ),
                _LearningTile(
                  icon: Icons.close_rounded,
                  title: 'Malnehmen',
                  subtitle: 'Einmaleins aufbauen',
                  onTap: () => _openMode(TrainingMode.multiply),
                ),
                _LearningTile(
                  icon: Icons.horizontal_rule_rounded,
                  title: 'Teilen',
                  subtitle: 'Umkehraufgaben nutzen',
                  onTap: () => _openMode(TrainingMode.divide),
                ),
                _LearningTile(
                  icon: Icons.shuffle_rounded,
                  title: 'Gemischt',
                  subtitle: 'alle Grundrechenarten',
                  onTap: () => _openMode(TrainingMode.mixed),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Zahlen verstehen'),
            const SizedBox(height: 10),
            _LearningGrid(
              children: [
                _LearningTile(
                  icon: Icons.extension_rounded,
                  title: 'Zahlenfreunde',
                  subtitle: 'Zerlegen & ergänzen',
                  onTap: () => _openMode(TrainingMode.numberFriends),
                ),
                _LearningTile(
                  icon: Icons.swap_horiz_rounded,
                  title: 'Nachbarzahlen',
                  subtitle: 'vorher & nachher',
                  onTap: () => _openMode(TrainingMode.neighbors),
                ),
                _LearningTile(
                  icon: Icons.view_column_rounded,
                  title: 'Zehner & Einer',
                  subtitle: 'Stellenwert verstehen',
                  onTap: () => _openMode(TrainingMode.placeValue),
                ),
                _LearningTile(
                  icon: Icons.balance_rounded,
                  title: 'Doppelt & Hälfte',
                  subtitle: 'Zahlbeziehungen',
                  onTap: () => _openMode(TrainingMode.doublesHalves),
                ),
                _LearningTile(
                  icon: Icons.trending_up_rounded,
                  title: 'Zahlenfolgen',
                  subtitle: 'Muster erkennen',
                  onTap: () => _openMode(TrainingMode.sequences),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Rechenwege'),
            const SizedBox(height: 10),
            _LearningGrid(
              children: [
                _LearningTile(
                  icon: Icons.account_balance_rounded,
                  title: 'Zahlenmauern',
                  subtitle: 'Steine ergänzen',
                  onTap: () => _openMode(TrainingMode.numberWall),
                ),
                _LearningTile(
                  icon: Icons.question_mark_rounded,
                  title: 'Lückenaufgaben',
                  subtitle: 'fehlende Zahl finden',
                  onTap: () => _openMode(TrainingMode.missingNumber),
                ),
                _LearningTile(
                  icon: Icons.family_restroom_rounded,
                  title: 'Rechenfamilien',
                  subtitle: 'Umkehraufgaben',
                  onTap: () => _openMode(TrainingMode.factFamilies),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Sachrechnen & Alltag'),
            const SizedBox(height: 10),
            _LearningGrid(
              children: [
                _LearningTile(
                  icon: Icons.menu_book_rounded,
                  title: 'Sachaufgaben',
                  subtitle: 'Rechnen aus Geschichten',
                  onTap: () => _openMode(TrainingMode.wordProblems),
                ),
                _LearningTile(
                  icon: Icons.euro_rounded,
                  title: 'Geld',
                  subtitle: 'Euro, Cent & Rückgeld',
                  onTap: () => _openMode(TrainingMode.money),
                ),
                _LearningTile(
                  icon: Icons.schedule_rounded,
                  title: 'Uhrzeit',
                  subtitle: 'Uhren lesen',
                  onTap: () => _openMode(TrainingMode.clock),
                ),
                _LearningTile(
                  icon: Icons.straighten_rounded,
                  title: 'Längen & Größen',
                  subtitle: 'cm, dm & m',
                  onTap: () => _openMode(TrainingMode.measures),
                ),
                _LearningTile(
                  icon: Icons.category_rounded,
                  title: 'Geometrie',
                  subtitle: 'Formen, Seiten & Ecken',
                  onTap: () => _openMode(TrainingMode.geometry),
                ),
              ],
            ),
            const SizedBox(height: 26),
            const _SectionTitle(title: 'Heute'),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 22,
                  runSpacing: 16,
                  children: [
                    _Stat(label: 'Runden', value: '${today.length}'),
                    _Stat(label: 'Aufgaben', value: '$todayTotal'),
                    _Stat(
                      label: 'direkt richtig',
                      value: todayTotal == 0
                          ? '–'
                          : '${(todayAccuracy * 100).round()} %',
                    ),
                    _Stat(label: 'Sterne', value: '${controller.stars} ★'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Kurze Runden reichen aus. Sicherheit kommt vor Geschwindigkeit.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.w800),
      );
}

class _LearningGrid extends StatelessWidget {
  const _LearningGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final count = constraints.maxWidth >= 700 ? 3 : 2;
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: count,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: constraints.maxWidth < 390 ? 1.08 : 1.25,
            children: children,
          );
        },
      );
}

class _LearningTile extends StatelessWidget {
  const _LearningTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 28),
                const Spacer(),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
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
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(label),
        ],
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
            Text(
              'Rechencheck einstellen',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            const Text('Aufgaben'),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 10, label: Text('10')),
                ButtonSegment(value: 20, label: Text('20')),
                ButtonSegment(value: 30, label: Text('30')),
              ],
              selected: {tasks},
              onSelectionChanged: (values) =>
                  setState(() => tasks = values.first),
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
              onChanged: (value) => setState(() => minutes = value ?? 2),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                TempoConfig(
                  tasks,
                  minutes == 0 ? null : Duration(minutes: minutes),
                ),
              ),
              child: const Text('Rechencheck starten'),
            ),
          ],
        ),
      );
}
