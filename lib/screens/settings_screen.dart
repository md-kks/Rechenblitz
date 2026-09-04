import 'package:flutter/material.dart';

import '../models/learner_profile.dart';
import '../models/training.dart';
import '../services/app_controller.dart';
import 'assessment_screen.dart';
import 'accessibility_screen.dart';
import 'beta_feedback_screen.dart';
import 'curriculum_audit_screen.dart';
import 'teacher_mode_screen.dart';
import 'method_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: Text(
                    controller.activeProfileName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(controller.gradeLevel.label),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(controller: controller),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: const Text('So rechnen wir'),
                  subtitle: const Text(
                    'Rechenwege aus der Schule für Hilfen und Erklärungen',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MethodScreen(controller: controller),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              leading: const Icon(Icons.route_rounded),
              title: const Text('Lerncheck wiederholen'),
              subtitle: Text(
                controller.activeProfile.assessmentCompletedAt == null
                    ? 'Noch kein Einstufungscheck gespeichert'
                    : 'Lernlandkarte mit 12 kurzen Aufgaben neu einordnen',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AssessmentScreen(controller: controller),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.accessibility_new_rounded),
                  title: const Text('Lesen & Darstellung'),
                  subtitle: const Text(
                    'Große Schrift, Kontrast, weniger Bewegung und Vorlesen',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          AccessibilityScreen(controller: controller),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.qr_code_2_rounded),
                  title: const Text('Lehrerauftrag erstellen'),
                  subtitle: const Text(
                    'Lokaler QR-Auftrag ohne Schülerkonto',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          TeacherModeScreen(controller: controller),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.fact_check_outlined),
                  title: const Text('Lehrplan-Audit'),
                  subtitle: const Text(
                    'Lernziele und digitale Abdeckung prüfen',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          CurriculumAuditScreen(controller: controller),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.science_outlined),
                  title: const Text('Beta-Test'),
                  subtitle: const Text(
                    'Anonymes lokales Testfeedback erfassen',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          BetaFeedbackScreen(controller: controller),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Lernrahmen',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<GradeLevel>(
            initialValue: controller.gradeLevel,
            decoration: const InputDecoration(
              labelText: 'Klassenstufe',
              border: OutlineInputBorder(),
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
              if (value != null) controller.setGradeLevel(value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<GermanState>(
            initialValue: controller.activeProfile.state,
            decoration: const InputDecoration(
              labelText: 'Bundesland',
              border: OutlineInputBorder(),
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
              if (value != null) controller.setProfileState(value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<NumberRangeLevel>(
            key: ValueKey(
              'settings-range:${controller.gradeLevel.name}:${controller.numberRange.name}',
            ),
            initialValue: controller.numberRange,
            decoration: const InputDecoration(
              labelText: 'Zahlenraum',
              border: OutlineInputBorder(),
            ),
            items: controller.availableRanges
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) controller.setNumberRange(value);
            },
          ),
          const SizedBox(height: 18),
          SwitchListTile(
            title: const Text('Leiser Bestätigungston'),
            subtitle: const Text('Nur bei richtiger Antwort'),
            value: controller.soundEnabled,
            onChanged: controller.setSound,
          ),
          SwitchListTile(
            title: const Text('Haptisches Feedback'),
            subtitle: const Text('Kurze Rückmeldung bei richtiger Antwort'),
            value: controller.hapticEnabled,
            onChanged: controller.setHaptic,
          ),
          const SizedBox(height: 14),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Rechenblitz arbeitet local first: Lernprofile, Lernfortschritt und Rechenwege bleiben auf diesem Gerät. Es ist kein Konto erforderlich.',
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Die Lernlogik priorisiert Verstehen, korrektes Rechnen und Sicherheit. Tempo wird erst wichtiger, wenn die Grundlagen stabil sind.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
