import 'package:flutter/material.dart';

import '../models/learner_profile.dart';
import '../models/training.dart';
import '../services/app_controller.dart';
import 'assessment_screen.dart';

class LearningStartScreen extends StatefulWidget {
  const LearningStartScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<LearningStartScreen> createState() => _LearningStartScreenState();
}

class _LearningStartScreenState extends State<LearningStartScreen> {
  final nameController = TextEditingController();
  int step = 0;
  late GradeLevel grade;
  late GermanState state;

  @override
  void initState() {
    super.initState();
    final profile = widget.controller.activeProfile;
    nameController.text = profile.name == 'Lernprofil' ? '' : profile.name;
    grade = profile.gradeLevel;
    state = profile.state;
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _saveSetup() => widget.controller.saveLearningStartSetup(
    name: nameController.text,
    grade: grade,
    state: state,
  );

  Future<void> _startAssessment() async {
    await _saveSetup();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AssessmentScreen(
          controller: widget.controller,
          fromOnboarding: true,
        ),
      ),
    );
  }

  Future<void> _skipAssessment() async {
    await _saveSetup();
    await widget.controller.completeOnboardingWithoutAssessment();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.flash_on_rounded,
                    size: 28,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rechenblitz',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    'Start ${step + 1} von 2',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LinearProgressIndicator(
                value: (step + 1) / 2,
                minHeight: 6,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: switch (step) {
                  0 => _profileStep(),
                  _ => _assessmentStep(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileStep() => ListView(
    key: const ValueKey('learning-start-profile'),
    padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
    children: [
      Text(
        'Kurz einrichten',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 8),
      const Text(
        'Damit die Aufgaben zur Klasse passen. Alles bleibt auf diesem Gerät.',
      ),
      const SizedBox(height: 24),
      TextField(
        key: const ValueKey('learning-start-name'),
        controller: nameController,
        maxLength: 24,
        decoration: const InputDecoration(
          labelText: 'Name oder Spitzname (optional)',
          hintText: 'z. B. Mia',
          prefixIcon: Icon(Icons.person_outline_rounded),
        ),
      ),
      const SizedBox(height: 8),
      Text('Klasse', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: GradeLevel.values
            .map(
              (value) => ChoiceChip(
                key: ValueKey('learning-start-grade-${value.name}'),
                label: Text(value.label),
                selected: grade == value,
                onSelected: (_) => setState(() => grade = value),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 22),
      DropdownButtonFormField<GermanState>(
        key: const ValueKey('learning-start-state'),
        initialValue: state,
        decoration: const InputDecoration(
          labelText: 'Bundesland',
          prefixIcon: Icon(Icons.location_on_outlined),
        ),
        items: GermanState.values
            .map(
              (value) =>
                  DropdownMenuItem(value: value, child: Text(value.label)),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) setState(() => state = value);
        },
      ),
      const SizedBox(height: 10),
      Text(
        state == GermanState.thuringia
            ? 'Thüringen: Lehrplan vollständig geprüft.'
            : 'Das Bundesland hilft bei der Lehrplan-Zuordnung.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 28),
      FilledButton(
        key: const ValueKey('learning-start-next'),
        onPressed: () => setState(() => step = 1),
        child: const Text('Weiter zum Lerncheck'),
      ),
    ],
  );

  Widget _assessmentStep() => ListView(
    key: const ValueKey('learning-start-assessment'),
    padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
    children: [
      Icon(
        Icons.route_rounded,
        size: 56,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(height: 18),
      Text(
        'Ein kurzer Lerncheck',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 10),
      const Text(
        '12 Aufgaben ohne Zeitdruck. So findet Rechenblitz einen guten Startpunkt.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 22),
      const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _CheckPoint(
                icon: Icons.timer_off_outlined,
                text: 'Kein Zeitdruck',
              ),
              _CheckPoint(icon: Icons.grade_outlined, text: 'Keine Note'),
              _CheckPoint(
                icon: Icons.help_outline_rounded,
                text: '„Weiß ich noch nicht“ ist völlig in Ordnung',
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 22),
      FilledButton.icon(
        key: const ValueKey('learning-start-assessment-start'),
        onPressed: _startAssessment,
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Lerncheck starten'),
      ),
      const SizedBox(height: 8),
      TextButton(
        key: const ValueKey('learning-start-assessment-later'),
        onPressed: _skipAssessment,
        child: const Text('Ohne Lerncheck starten'),
      ),
      const SizedBox(height: 4),
      Text(
        'Der Lerncheck kann später in den Einstellungen nachgeholt werden.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 10),
      TextButton(
        onPressed: () => setState(() => step = 0),
        child: const Text('Zurück'),
      ),
    ],
  );
}

class _CheckPoint extends StatelessWidget {
  const _CheckPoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Icon(icon),
        const SizedBox(width: 11),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
