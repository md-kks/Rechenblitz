import 'package:flutter/material.dart';

import '../models/learning_methods.dart';
import '../services/app_controller.dart';

class MethodScreen extends StatefulWidget {
  const MethodScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<MethodScreen> createState() => _MethodScreenState();
}

class _MethodScreenState extends State<MethodScreen> {
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
    final methods = widget.controller.methodPreferences;
    return Scaffold(
      appBar: AppBar(title: const Text('So rechnen wir')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 34),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'Wähle die Rechenwege, die in der Schule verwendet werden. Rechenblitz nutzt diese Auswahl in Hilfen und Erklärungen für ${widget.controller.activeProfileName}.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          _MethodCard(
            title: 'Subtraktion über den Zehner',
            icon: Icons.remove_circle_outline_rounded,
            description: methods.subtraction.description,
            child: DropdownButtonFormField<SubtractionStrategy>(
              initialValue: methods.subtraction,
              decoration: const InputDecoration(
                labelText: 'Methode',
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
                if (value != null) {
                  widget.controller.setSubtractionStrategy(value);
                }
              },
            ),
          ),
          const SizedBox(height: 14),
          _MethodCard(
            title: 'Einmaleins verstehen',
            icon: Icons.close_rounded,
            description: methods.multiplication.description,
            child: DropdownButtonFormField<MultiplicationStrategy>(
              initialValue: methods.multiplication,
              decoration: const InputDecoration(
                labelText: 'Methode',
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
                  widget.controller.setMultiplicationStrategy(value);
                }
              },
            ),
          ),
          const SizedBox(height: 14),
          _MethodCard(
            title: 'Schriftliche Subtraktion',
            icon: Icons.edit_note_rounded,
            description: methods.writtenSubtraction.description,
            child: DropdownButtonFormField<WrittenSubtractionStrategy>(
              initialValue: methods.writtenSubtraction,
              decoration: const InputDecoration(
                labelText: 'Methode',
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
                  widget.controller.setWrittenSubtractionStrategy(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.title,
    required this.icon,
    required this.description,
    required this.child,
  });

  final String title;
  final IconData icon;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(description),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      );
}
