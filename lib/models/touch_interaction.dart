import 'dart:math';

import 'training.dart';

enum TouchInteractionKind { numberLine, dragNumberToTarget }

class TouchInteractionPlan {
  const TouchInteractionPlan({
    required this.taskKey,
    required this.kind,
    required this.instruction,
    this.minValue = 0,
    this.maxValue = 0,
    this.startValue = 0,
    this.targetLabel = 'Hier ablegen',
    this.wallValues,
    this.hiddenWallIndex,
  });

  final String taskKey;
  final TouchInteractionKind kind;
  final String instruction;
  final int minValue;
  final int maxValue;
  final int startValue;
  final String targetLabel;
  final List<int>? wallValues;
  final int? hiddenWallIndex;

  bool get hasInteractiveWall => wallValues != null && hiddenWallIndex != null;

  static TouchInteractionPlan? forTask({
    required TrainingMode mode,
    required String taskKey,
    required int answer,
    required int maxValue,
    List<int>? wallValues,
    int? hiddenWallIndex,
  }) {
    if (mode == TrainingMode.largeNumbers &&
        taskKey.startsWith('large:neighbor:')) {
      final parts = taskKey.split(':');
      final number = parts.length >= 3 ? int.tryParse(parts[2]) : null;
      if (number == null) return null;
      final next = parts.length >= 4 && parts[3] == 'true';
      return TouchInteractionPlan(
        taskKey: taskKey,
        kind: TouchInteractionKind.numberLine,
        instruction: next
            ? 'Zieh den Punkt genau einen Schritt weiter.'
            : 'Zieh den Punkt genau einen Schritt zurück.',
        minValue: max(0, number - 3),
        maxValue: number + 3,
        startValue: number,
      );
    }

    if (maxValue > 100) return null;

    if (mode == TrainingMode.numberWall &&
        taskKey.startsWith('wall:') &&
        wallValues != null &&
        hiddenWallIndex != null) {
      return TouchInteractionPlan(
        taskKey: taskKey,
        kind: TouchInteractionKind.dragNumberToTarget,
        instruction: 'Wähle eine Zahl und zieh sie in den freien Stein.',
        minValue: 0,
        maxValue: max(1, maxValue),
        startValue: 0,
        targetLabel: 'Fehlender Stein',
        wallValues: wallValues,
        hiddenWallIndex: hiddenWallIndex,
      );
    }

    if (mode == TrainingMode.missingNumber && taskKey.startsWith('gap:')) {
      final parts = taskKey.split(':');
      final start = parts.length >= 4 ? _missingNumberStart(parts, answer) : 0;
      return TouchInteractionPlan(
        taskKey: taskKey,
        kind: TouchInteractionKind.numberLine,
        instruction: 'Zieh den Punkt auf die Zahl, die in die Lücke gehört.',
        minValue: 0,
        maxValue: max(1, maxValue),
        startValue: start.clamp(0, max(1, maxValue)),
      );
    }

    if (mode == TrainingMode.neighbors && taskKey.startsWith('neighbor:')) {
      final parts = taskKey.split(':');
      final number = parts.length >= 2 ? int.tryParse(parts[1]) : null;
      if (number == null) return null;
      final before = parts.length >= 3 && parts[2] == 'before';
      return TouchInteractionPlan(
        taskKey: taskKey,
        kind: TouchInteractionKind.numberLine,
        instruction: before
            ? 'Zieh den Punkt genau einen Schritt zurück.'
            : 'Zieh den Punkt genau einen Schritt weiter.',
        minValue: max(0, number - 3),
        maxValue: min(maxValue, number + 3),
        startValue: number,
      );
    }

    if (mode == TrainingMode.sequences && taskKey.startsWith('sequence:')) {
      final parts = taskKey.split(':');
      if (parts.length < 4) return null;
      final start = int.tryParse(parts[2]);
      final step = int.tryParse(parts[3]);
      if (start == null || step == null) return null;
      final backwards = parts[1] == '-';
      final lastShown = backwards ? start - 2 * step : start + 2 * step;
      return TouchInteractionPlan(
        taskKey: taskKey,
        kind: TouchInteractionKind.numberLine,
        instruction: backwards
            ? 'Setze die Folge auf dem Zahlenstrahl rückwärts fort.'
            : 'Setze die Folge auf dem Zahlenstrahl weiter fort.',
        minValue: 0,
        maxValue: max(1, maxValue),
        startValue: lastShown.clamp(0, max(1, maxValue)),
      );
    }

    return null;
  }

  static int _missingNumberStart(List<String> parts, int answer) {
    final operation = parts[1];
    final a = int.tryParse(parts[2]);
    final b = int.tryParse(parts[3]);
    final hidden = parts.length >= 5 ? parts[4] : '';
    if (a == null || b == null) return 0;
    if (operation == '+') return hidden == 'b' ? a : b;
    if (hidden == 'b') return a - b;
    return max(0, answer - b);
  }
}
