import 'dart:async';

import 'package:flutter/material.dart';

import '../models/training.dart';
import '../services/app_controller.dart';
import 'competency_map_screen.dart';
import 'curriculum_training_screen.dart';
import 'my_round_screen.dart';
import 'parent_screen.dart';
import 'profile_screen.dart';
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
    if (mode.isUpperPrimary) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CurriculumTrainingScreen(
            controller: widget.controller,
            mode: mode,
          ),
        ),
      );
      return;
    }

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
    final recommendation = controller.recommendationText();

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
              controller.activeProfileName == 'Lernprofil'
                  ? 'Hallo!'
                  : 'Hallo, ${controller.activeProfileName}!',
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
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    controller.activeProfileName.isEmpty
                        ? '?'
                        : controller.activeProfileName.substring(0, 1).toUpperCase(),
                  ),
                ),
                title: Text(
                  controller.activeProfileName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  '${controller.gradeLevel.label} · ${controller.numberRange.label} · nur auf diesem Gerät',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(controller: controller),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Klassenstufe',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<GradeLevel>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: GradeLevel.first,
                            label: Text('1'),
                          ),
                          ButtonSegment(
                            value: GradeLevel.second,
                            label: Text('2'),
                          ),
                          ButtonSegment(
                            value: GradeLevel.third,
                            label: Text('3'),
                          ),
                          ButtonSegment(
                            value: GradeLevel.fourth,
                            label: Text('4'),
                          ),
                        ],
                        selected: {controller.gradeLevel},
                        onSelectionChanged: (values) =>
                            controller.setGradeLevel(values.first),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(controller.gradeLevel.description),
                    const SizedBox(height: 18),
                    Text(
                      'Zahlenraum',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<NumberRangeLevel>(
                      initialValue: controller.numberRange,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers_rounded),
                      ),
                      items: controller.availableRanges
                          .map(
                            (range) => DropdownMenuItem(
                              value: range,
                              child: Text(range.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) controller.setNumberRange(value);
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      controller.gradeLevel.index >= GradeLevel.third.index
                          ? 'Die Klassenstufe bestimmt die Lernmethoden. Der Zahlenraum kann für Wiederholung und Förderung kleiner gewählt werden.'
                          : 'Die Aufgaben passen sich innerhalb des gewählten Zahlenraums an den Lernstand an.',
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
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Meine Runde',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        const Chip(label: Text('ca. 5 Min')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(recommendation),
                    const SizedBox(height: 6),
                    const Text(
                      '10 Aufgaben: ruhig ankommen, aktuelles Lernziel üben und Wissen übertragen.',
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      key: const ValueKey('my-round-button'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MyRoundScreen(controller: controller),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Meine Runde starten'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              CompetencyMapScreen(controller: controller),
                        ),
                      ),
                      icon: const Icon(Icons.route_rounded),
                      label: const Text('Meine Lernlandkarte'),
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
            if (controller.gradeLevel.index >= GradeLevel.third.index) ...[
              const SizedBox(height: 28),
              _SectionTitle(
                title: '${controller.gradeLevel.label} · Zahlen & Rechnen',
              ),
              const SizedBox(height: 10),
              _LearningGrid(
                children: [
                  _LearningTile(
                    icon: Icons.format_list_numbered_rounded,
                    title: 'Große Zahlen',
                    subtitle: 'Stellenwert & Orientierung',
                    onTap: () => _openMode(TrainingMode.largeNumbers),
                  ),
                  _LearningTile(
                    icon: Icons.adjust_rounded,
                    title: 'Runden',
                    subtitle: 'sinnvoll annähern',
                    onTap: () => _openMode(TrainingMode.rounding),
                  ),
                  _LearningTile(
                    icon: Icons.psychology_alt_rounded,
                    title: 'Halbschriftlich',
                    subtitle: 'geschickt zerlegen',
                    onTap: () => _openMode(TrainingMode.mentalStrategies),
                  ),
                  _LearningTile(
                    icon: Icons.add_box_outlined,
                    title: 'Schriftlich + / −',
                    subtitle: 'mit Überträgen',
                    onTap: () => _openMode(TrainingMode.writtenAddSub),
                  ),
                  _LearningTile(
                    icon: Icons.close_rounded,
                    title: 'Schriftlich mal',
                    subtitle: 'Stelle für Stelle',
                    onTap: () => _openMode(TrainingMode.writtenMultiply),
                  ),
                  _LearningTile(
                    icon: Icons.horizontal_rule_rounded,
                    title: 'Schriftlich teilen',
                    subtitle: 'mit Probe',
                    onTap: () => _openMode(TrainingMode.writtenDivide),
                  ),
                  _LearningTile(
                    icon: Icons.calculate_outlined,
                    title: 'Überschlag',
                    subtitle: 'Ergebnisse prüfen',
                    onTap: () => _openMode(TrainingMode.estimation),
                  ),
                  _LearningTile(
                    icon: Icons.lightbulb_circle_outlined,
                    title: 'Rechenvorteile',
                    subtitle: 'Gesetze nutzen',
                    onTap: () => _openMode(TrainingMode.arithmeticLaws),
                  ),
                  _LearningTile(
                      icon: Icons.history_edu_rounded,
                      title: 'Römische Zahlen',
                      subtitle: 'lesen & schreiben',
                      onTap: () => _openMode(TrainingMode.romanNumerals),
                    ),
                  _LearningTile(
                      icon: Icons.pie_chart_outline_rounded,
                      title: 'Bruchteile',
                      subtitle: '1/2, 1/4 und Größen',
                      onTap: () => _openMode(TrainingMode.fractions),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Größen, Zeit & Sachrechnen'),
              const SizedBox(height: 10),
              _LearningGrid(
                children: [
                  _LearningTile(
                    icon: Icons.straighten_rounded,
                    title: 'Größen umwandeln',
                    subtitle: 'Länge, Masse, Volumen',
                    onTap: () => _openMode(TrainingMode.advancedMeasures),
                  ),
                  _LearningTile(
                    icon: Icons.timer_outlined,
                    title: 'Zeitspannen',
                    subtitle: 'Dauer berechnen',
                    onTap: () => _openMode(TrainingMode.timeDurations),
                  ),
                  _LearningTile(
                      icon: Icons.swap_vert_circle_outlined,
                      title: 'Zuordnungen',
                      subtitle: 'proportional denken',
                      onTap: () => _openMode(TrainingMode.proportionality),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Geometrie & Raum'),
              const SizedBox(height: 10),
              _LearningGrid(
                children: [
                  _LearningTile(
                    icon: Icons.crop_square_rounded,
                    title: 'Umfang & Fläche',
                    subtitle: 'Rechtecke untersuchen',
                    onTap: () => _openMode(TrainingMode.perimeterArea),
                  ),
                  _LearningTile(
                    icon: Icons.view_in_ar_rounded,
                    title: 'Körper & Netze',
                    subtitle: 'Ecken, Kanten, Flächen',
                    onTap: () => _openMode(TrainingMode.geometryBodies),
                  ),
                  _LearningTile(
                    icon: Icons.vertical_align_center_rounded,
                    title: 'Symmetrie',
                    subtitle: 'Achsen erkennen',
                    onTap: () => _openMode(TrainingMode.symmetry),
                  ),
                  _LearningTile(
                    icon: Icons.map_outlined,
                    title: 'Pläne & Wege',
                    subtitle: 'Orientierung & Maßstab',
                    onTap: () => _openMode(TrainingMode.plansAndOrientation),
                  ),
                  _LearningTile(
                      icon: Icons.grid_4x4_rounded,
                      title: 'Rauminhalt',
                      subtitle: 'mit Einheitswürfeln',
                      onTap: () => _openMode(TrainingMode.volumeCubes),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Daten, Muster & Zufall'),
              const SizedBox(height: 10),
              _LearningGrid(
                children: [
                  _LearningTile(
                    icon: Icons.bar_chart_rounded,
                    title: 'Daten & Diagramme',
                    subtitle: 'lesen & auswerten',
                    onTap: () => _openMode(TrainingMode.dataCharts),
                  ),
                  _LearningTile(
                    icon: Icons.casino_outlined,
                    title: 'Wahrscheinlichkeit',
                    subtitle: 'Chancen einschätzen',
                    onTap: () => _openMode(TrainingMode.probability),
                  ),
                  _LearningTile(
                    icon: Icons.account_tree_outlined,
                    title: 'Kombinatorik',
                    subtitle: 'Möglichkeiten finden',
                    onTap: () => _openMode(TrainingMode.combinatorics),
                  ),
                ],
              ),
            ],
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
