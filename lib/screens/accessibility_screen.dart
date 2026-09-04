import 'package:flutter/material.dart';

import '../models/accessibility_preferences.dart';
import '../services/app_controller.dart';

class AccessibilityScreen extends StatefulWidget {
  const AccessibilityScreen({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {
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

  Future<void> _update(
    AccessibilityPreferences Function(AccessibilityPreferences current)
        update,
  ) =>
      widget.controller.setAccessibilityPreferences(
        update(widget.controller.accessibilityPreferences),
      );

  @override
  Widget build(BuildContext context) {
    final prefs = widget.controller.accessibilityPreferences;
    return Scaffold(
      appBar: AppBar(title: const Text('Lesen & Darstellung')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 34),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Diese Einstellungen gelten für das ganze Gerät. Sie verändern keine Lernbewertung.',
              ),
            ),
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            title: const Text('Größere Schrift'),
            subtitle: const Text('Texte werden deutlich größer dargestellt.'),
            value: prefs.largeText,
            onChanged: (value) =>
                _update((current) => current.copyWith(largeText: value)),
          ),
          SwitchListTile(
            title: const Text('Hoher Kontrast'),
            subtitle: const Text(
              'Stärkere Konturen und kontrastreichere Flächen.',
            ),
            value: prefs.highContrast,
            onChanged: (value) =>
                _update((current) => current.copyWith(highContrast: value)),
          ),
          SwitchListTile(
            title: const Text('Weniger Bewegung'),
            subtitle: const Text(
              'Reduziert Übergänge und Animationen, soweit Flutter dies unterstützt.',
            ),
            value: prefs.reducedMotion,
            onChanged: (value) =>
                _update((current) => current.copyWith(reducedMotion: value)),
          ),
          const Divider(height: 28),
          SwitchListTile(
            title: const Text('Aufgaben automatisch vorlesen'),
            subtitle: const Text(
              'Neue Aufgaben werden mit der deutschen Systemstimme vorgelesen.',
            ),
            value: prefs.readAloud,
            onChanged: (value) =>
                _update((current) => current.copyWith(readAloud: value)),
          ),
          const SizedBox(height: 8),
          Text(
            'Sprechgeschwindigkeit',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          Slider(
            min: 0.25,
            max: 0.65,
            divisions: 8,
            label: prefs.speechRate.toStringAsFixed(2),
            value: prefs.speechRate.clamp(0.25, 0.65),
            onChanged: (value) =>
                _update((current) => current.copyWith(speechRate: value)),
          ),
          FilledButton.tonalIcon(
            onPressed: () => widget.controller.speakOnDemand(
              'Rechenblitz liest diese Aufgabe jetzt vor.',
            ),
            icon: const Icon(Icons.volume_up_outlined),
            label: const Text('Vorlesen testen'),
          ),
          const SizedBox(height: 14),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Alle Aufgaben bleiben zusätzlich als Text sichtbar. Vorlesen ersetzt die visuelle Darstellung nicht.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
