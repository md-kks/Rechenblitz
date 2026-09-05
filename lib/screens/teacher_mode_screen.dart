import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/micro_competency.dart';
import '../models/teacher_assignment.dart';
import '../models/training.dart';
import '../services/app_controller.dart';
import '../services/assignment_launcher.dart';
import 'assignment_result_scanner_screen.dart';

class TeacherModeScreen extends StatefulWidget {
  const TeacherModeScreen({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  State<TeacherModeScreen> createState() => _TeacherModeScreenState();
}

class _TeacherModeScreenState extends State<TeacherModeScreen> {
  late GradeLevel grade;
  late NumberRangeLevel range;
  MicroCompetencyId? target;
  int tasks = 10;
  bool transferEmphasis = false;

  @override
  void initState() {
    super.initState();
    grade = widget.controller.gradeLevel;
    range = widget.controller.numberRange;
    final focus = widget.controller.currentMicroFocus();
    target = focus?.definition.id ??
        MicroCompetencyCatalog.forGrade(grade).firstOrNull?.id;
  }

  List<NumberRangeLevel> _rangesFor(GradeLevel value) => switch (value) {
        GradeLevel.first => const [
            NumberRangeLevel.ten,
            NumberRangeLevel.twenty,
          ],
        GradeLevel.second => const [
            NumberRangeLevel.ten,
            NumberRangeLevel.twenty,
            NumberRangeLevel.hundred,
          ],
        GradeLevel.third => const [
            NumberRangeLevel.ten,
            NumberRangeLevel.twenty,
            NumberRangeLevel.hundred,
            NumberRangeLevel.thousand,
            NumberRangeLevel.tenThousand,
          ],
        GradeLevel.fourth => NumberRangeLevel.values,
      };

  List<MicroCompetencyDefinition> get _targets =>
      MicroCompetencyCatalog.forGrade(grade);

  TeacherAssignment get _assignment {
    final definition = target == null
        ? null
        : MicroCompetencyCatalog.definition(target!);
    final mode = transferEmphasis && target != null
        ? widget.controller.transferModeFor(target!)
        : definition?.preferredMode ?? TrainingMode.practice;
    return TeacherAssignment(
      gradeLevel: grade,
      numberRange: range,
      mode: mode,
      tasks: tasks,
      targetCompetency: target,
      transferEmphasis: transferEmphasis,
      methods: widget.controller.methodPreferences,
    );
  }

  void _setGrade(GradeLevel value) {
    final ranges = _rangesFor(value);
    setState(() {
      grade = value;
      if (!ranges.contains(range)) range = value.recommendedRange;
      final targets = MicroCompetencyCatalog.forGrade(value);
      if (target == null || !targets.any((item) => item.id == target)) {
        target = targets.isEmpty ? null : targets.first.id;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final assignment = _assignment;
    final payload = assignment.toPayload();
    return Scaffold(
      appBar: AppBar(title: const Text('Lehrerauftrag')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 36),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Der QR-Code enthält nur den Lernauftrag. Kein Name, keine Profil-ID und kein Lernverlauf werden übertragen.',
              ),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<GradeLevel>(
            initialValue: grade,
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
              if (value != null) _setGrade(value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<NumberRangeLevel>(
            key: ValueKey('teacher-range:${grade.name}:${range.name}'),
            initialValue: range,
            decoration: const InputDecoration(
              labelText: 'Zahlenraum',
              border: OutlineInputBorder(),
            ),
            items: _rangesFor(grade)
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => range = value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<MicroCompetencyId>(
            initialValue: target,
            decoration: const InputDecoration(
              labelText: 'Lernziel',
              border: OutlineInputBorder(),
            ),
            items: _targets
                .map(
                  (definition) => DropdownMenuItem(
                    value: definition.id,
                    child: Text(definition.label),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => target = value),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: tasks,
            decoration: const InputDecoration(
              labelText: 'Aufgabenanzahl',
              border: OutlineInputBorder(),
            ),
            items: const [5, 8, 10, 12, 15, 20]
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text('$value Aufgaben'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => tasks = value);
            },
          ),
          const SizedBox(height: 6),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Transfer besonders betonen'),
            subtitle: const Text(
              'Bereits gelerntes Wissen wird in einer veränderten Aufgabenform oder einem Anwendungskontext geprüft.',
            ),
            value: transferEmphasis,
            onChanged: (value) =>
                setState(() => transferEmphasis = value),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Text(
                    assignment.summary,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Auftrags-ID: ${assignment.assignmentId}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    label: 'QR-Code für den Rechenblitz-Lehrerauftrag',
                    child: QrImageView(
                      data: payload,
                      version: QrVersions.auto,
                      size: 260,
                      gapless: false,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Rechenweg im Auftrag: ${assignment.methods.selectionLabel}',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: payload));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Auftragscode kopiert.'),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Auftragscode kopieren'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AssignmentResultScannerScreen(),
              ),
            ),
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Ergebnis-QR scannen'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: grade != widget.controller.gradeLevel
                ? null
                : () => launchTeacherAssignment(
                      context,
                      widget.controller,
                      assignment,
                    ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
              grade == widget.controller.gradeLevel
                  ? 'Auftrag auf diesem Profil testen'
                  : 'Zum Testen ein Profil derselben Klasse wählen',
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
