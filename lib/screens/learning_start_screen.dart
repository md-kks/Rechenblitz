import 'package:flutter/material.dart';

import '../models/learner_profile.dart';
import '../models/learning_methods.dart';
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
  late SubtractionStrategy subtraction;
  late MultiplicationStrategy multiplication;
  late WrittenSubtractionStrategy writtenSubtraction;

  @override
  void initState() {
    super.initState();
    final profile = widget.controller.activeProfile;
    nameController.text =
        profile.name == 'Lernprofil' ? '' : profile.name;
    grade = profile.gradeLevel;
    state = profile.state;
    subtraction = widget.controller.methodPreferences.subtraction;
    multiplication = widget.controller.methodPreferences.multiplication;
    writtenSubtraction =
        widget.controller.methodPreferences.writtenSubtraction;
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  MethodPreferences get methods => MethodPreferences(
        subtraction: subtraction,
        multiplication: multiplication,
        writtenSubtraction: writtenSubtraction,
      );

  Future<void> _saveSetup() => widget.controller.saveLearningStartSetup(
        name: nameController.text,
        grade: grade,
        state: state,
        methods: methods,
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.flash_on_rounded, size: 30),
                  const SizedBox(width: 8),
                  Text(
                    'Rechenblitz Lernstart',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LinearProgressIndicator(
                value: (step + 1) / 3,
                minHeight: 8,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: switch (step) {
                  0 => _profileStep(),
                  1 => _methodsStep(),
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
            'Für wen ist Rechenblitz?',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Das Lernprofil bleibt ausschließlich auf diesem Gerät. Ein Konto ist nicht nötig.',
          ),
          const SizedBox(height: 24),
          TextField(
            key: const ValueKey('learning-start-name'),
            controller: nameController,
            maxLength: 24,
            decoration: const InputDecoration(
              labelText: 'Name oder Spitzname',
              hintText: 'z. B. Mia',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<GradeLevel>(
            key: const ValueKey('learning-start-grade'),
            initialValue: grade,
            decoration: const InputDecoration(
              labelText: 'Klassenstufe',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.school_outlined),
            ),
            items: GradeLevel.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => grade = value);
            },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<GermanState>(
            key: const ValueKey('learning-start-state'),
            initialValue: state,
            decoration: const InputDecoration(
              labelText: 'Bundesland',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            items: GermanState.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => state = value);
            },
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                state == GermanState.thuringia
                    ? 'Für Thüringen ist der Lehrplan bereits vollständig geprüft.'
                    : 'Das Bundesland wird lokal gespeichert. Thüringen ist derzeit vollständig lehrplangeprüft; für andere Bundesländer nutzt Rechenblitz zunächst den gemeinsamen Grundschul-Mathematikkern.',
              ),
            ),
          ),
          const SizedBox(height: 22),
          FilledButton(
            key: const ValueKey('learning-start-next'),
            onPressed: () => setState(() => step = 1),
            child: const Text('Weiter'),
          ),
        ],
      );

  Widget _methodsStep() => ListView(
        key: const ValueKey('learning-start-methods'),
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
        children: [
          Text(
            'So rechnen wir in der Schule',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Rechenblitz verwendet diese Wege später in Hilfen und Erklärungen. Die Auswahl kann jederzeit geändert werden.',
          ),
          const SizedBox(height: 22),
          DropdownButtonFormField<SubtractionStrategy>(
            initialValue: subtraction,
            decoration: const InputDecoration(
              labelText: 'Minus über den Zehner',
              border: OutlineInputBorder(),
            ),
            items: SubtractionStrategy.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => subtraction = value);
            },
          ),
          const SizedBox(height: 10),
          Text(subtraction.description),
          if (grade.index >= GradeLevel.second.index) ...[
            const SizedBox(height: 18),
            DropdownButtonFormField<MultiplicationStrategy>(
              initialValue: multiplication,
              decoration: const InputDecoration(
                labelText: 'Einmaleins verstehen',
                border: OutlineInputBorder(),
              ),
              items: MultiplicationStrategy.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => multiplication = value);
                }
              },
            ),
            const SizedBox(height: 10),
            Text(multiplication.description),
          ],
          if (grade.index >= GradeLevel.third.index) ...[
            const SizedBox(height: 18),
            DropdownButtonFormField<WrittenSubtractionStrategy>(
              initialValue: writtenSubtraction,
              decoration: const InputDecoration(
                labelText: 'Schriftliche Subtraktion',
                border: OutlineInputBorder(),
              ),
              items: WrittenSubtractionStrategy.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => writtenSubtraction = value);
                }
              },
            ),
            const SizedBox(height: 10),
            Text(writtenSubtraction.description),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => step = 0),
                  child: const Text('Zurück'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => setState(() => step = 2),
                  child: const Text('Weiter'),
                ),
              ),
            ],
          ),
        ],
      );

  Widget _assessmentStep() => ListView(
        key: const ValueKey('learning-start-assessment'),
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
        children: [
          Icon(
            Icons.route_rounded,
            size: 62,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 18),
          Text(
            'Wo stehst du gerade?',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          const Text(
            '12 kurze Aufgaben aus verschiedenen Bereichen helfen Rechenblitz, die erste Lernlandkarte sinnvoll zu starten.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CheckPoint(
                    icon: Icons.timer_off_outlined,
                    text: 'Keine Stoppuhr und kein Zeitdruck',
                  ),
                  _CheckPoint(
                    icon: Icons.grade_outlined,
                    text: 'Keine Note und keine verlorenen Sterne',
                  ),
                  _CheckPoint(
                    icon: Icons.help_outline_rounded,
                    text: '„Weiß ich noch nicht“ ist eine ganz normale Antwort',
                  ),
                  _CheckPoint(
                    icon: Icons.route_outlined,
                    text: 'Das Ergebnis bestimmt nur den ersten Lernschritt',
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
            child: const Text('Lerncheck später machen'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => step = 1),
            child: const Text('Zurück'),
          ),
        ],
      );
}

class _CheckPoint extends StatelessWidget {
  const _CheckPoint({
    required this.icon,
    required this.text,
  });

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
