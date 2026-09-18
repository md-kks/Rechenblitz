import 'package:flutter/material.dart';

import '../learning_app_theme.dart';
import '../learning_subject.dart';

class LearningSubjectSwitcher extends StatelessWidget {
  const LearningSubjectSwitcher({
    super.key,
    required this.current,
    required this.onMathematics,
    required this.onGerman,
  });

  final LearningSubject current;
  final VoidCallback onMathematics;
  final VoidCallback onGerman;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: _SubjectButton(
          subject: LearningSubject.mathematics,
          icon: Icons.calculate_rounded,
          selected: current == LearningSubject.mathematics,
          onTap: onMathematics,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _SubjectButton(
          subject: LearningSubject.german,
          icon: Icons.menu_book_rounded,
          selected: current == LearningSubject.german,
          onTap: onGerman,
        ),
      ),
    ],
  );
}

class _SubjectButton extends StatelessWidget {
  const _SubjectButton({
    required this.subject,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final LearningSubject subject;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final color = subject.visuals.seedColor;
    final highContrast = MediaQuery.highContrastOf(context);
    final foreground = selected
        ? Colors.white
        : (highContrast ? Theme.of(context).colorScheme.onSurface : color);
    final background = selected
        ? (highContrast ? Colors.black : color)
        : Theme.of(context).colorScheme.surface;
    final borderColor = highContrast
        ? Theme.of(context).colorScheme.onSurface
        : color.withValues(alpha: selected ? 1 : 0.45);

    return Semantics(
      button: true,
      selected: selected,
      label: '${subject.shortLabel}${selected ? ', ausgewählt' : ''}',
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: borderColor, width: selected ? 2 : 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('subject-switch-${subject.storageKey}'),
          onTap: selected ? null : onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 68),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon, color: foreground, size: 26),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      subject.shortLabel,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
