import 'dart:math';

import 'training.dart';

enum TouchInteractionKind {
  numberLine,
  dragNumberToTarget,
  placeValueBuilder,
  moneyComposer,
  clockSetter,
  fractionBuilder,
  pathWalker,
  symmetryAxes,
  shapeCorners,
  rectanglePerimeterEdges,
}

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
    this.answerChoices = const <String>[],
    this.clockHour,
    this.clockMinute,
    this.denominations = const <int>[],
    this.unitLabel,
    this.fractionNumerator,
    this.fractionDenominator,
    this.fractionWhole,
    this.pathRight,
    this.pathUp,
    this.symmetryShape,
    this.geometryShape,
    this.rectangleWidth,
    this.rectangleHeight,
    this.selectionLabels = const <String>[],
    this.correctSelectionIndexes = const <int>[],
    this.expectedAnswer,
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
  final List<String> answerChoices;
  final int? clockHour;
  final int? clockMinute;
  final List<int> denominations;
  final String? unitLabel;
  final int? fractionNumerator;
  final int? fractionDenominator;
  final int? fractionWhole;
  final int? pathRight;
  final int? pathUp;
  final String? symmetryShape;
  final String? geometryShape;
  final int? rectangleWidth;
  final int? rectangleHeight;
  final List<String> selectionLabels;
  final List<int> correctSelectionIndexes;
  final int? expectedAnswer;

  bool get hasInteractiveWall => wallValues != null && hiddenWallIndex != null;

  static TouchInteractionPlan? forTask({
    required TrainingMode mode,
    required String taskKey,
    required int answer,
    required int maxValue,
    List<int>? wallValues,
    int? hiddenWallIndex,
    List<String>? choices,
    int? clockHour,
    int? clockMinute,
    String? answerSuffix,
  }) {
    if (mode == TrainingMode.placeValue &&
        taskKey.startsWith('place:') &&
        answer <= 100) {
      return TouchInteractionPlan(
        taskKey: taskKey,
        kind: TouchInteractionKind.placeValueBuilder,
        instruction: 'Baue die Zahl aus Zehnern und Einern zusammen.',
        minValue: 0,
        maxValue: min(100, max(1, maxValue)),
      );
    }

    if (mode == TrainingMode.money && taskKey.startsWith('money:')) {
      final centTask =
          answerSuffix == 'ct' || taskKey.startsWith('money:convert:');
      if ((!centTask && answer > 100) || (centTask && answer > 1000)) {
        return null;
      }
      final upper = centTask
          ? max(100, min(1000, answer + 100))
          : max(20, min(100, answer + 20));
      final oneEuroCoins = taskKey.startsWith('money:coins:one:');
      final denominations = centTask
          ? <int>[100]
          : oneEuroCoins
          ? <int>[1]
          : <int>[
              1,
              2,
              5,
              10,
              20,
              50,
            ].where((value) => value <= upper).toList();
      return TouchInteractionPlan(
        taskKey: taskKey,
        kind: TouchInteractionKind.moneyComposer,
        instruction: centTask
            ? 'Lege 100-Cent-Blöcke, bis der passende Cent-Betrag entsteht.'
            : 'Stelle den gesuchten Geldbetrag mit Münzen und Scheinen zusammen.',
        minValue: 0,
        maxValue: upper,
        denominations: denominations.isEmpty ? <int>[1] : denominations,
        unitLabel: centTask ? 'ct' : '€',
      );
    }

    if (mode == TrainingMode.clock &&
        taskKey.startsWith('clock:') &&
        clockHour != null &&
        clockMinute != null &&
        choices != null &&
        choices.isNotEmpty) {
      return TouchInteractionPlan(
        taskKey: taskKey,
        kind: TouchInteractionKind.clockSetter,
        instruction:
            'Stelle die Zeiger genauso ein wie bei der Uhr oben.',
        answerChoices: choices,
        clockHour: clockHour,
        clockMinute: clockMinute,
      );
    }

    if (mode == TrainingMode.fractions && taskKey.startsWith('fraction:')) {
      final parts = taskKey.split(':');
      int? numerator;
      int? denominator;
      int? whole;
      if (parts.length == 3 && parts[1] == 'half') {
        numerator = 1;
        denominator = 2;
        whole = int.tryParse(parts[2]);
      } else if (parts.length == 3 && parts[1] == 'quarter') {
        numerator = 1;
        denominator = 4;
        whole = int.tryParse(parts[2]);
      } else if (parts.length == 5 && parts[1] == 'parts') {
        numerator = int.tryParse(parts[2]);
        denominator = int.tryParse(parts[3]);
        whole = int.tryParse(parts[4]);
      }
      if (numerator != null &&
          denominator != null &&
          whole != null &&
          numerator > 0 &&
          denominator > 0 &&
          whole > 0 &&
          whole <= 200) {
        return TouchInteractionPlan(
          taskKey: taskKey,
          kind: TouchInteractionKind.fractionBuilder,
          instruction:
              'Baue gleich große Teile. Erst wenn alle Teile zusammen das Ganze ergeben, passt der Bruchteil.',
          fractionNumerator: numerator,
          fractionDenominator: denominator,
          fractionWhole: whole,
          expectedAnswer: answer,
        );
      }
    }

    if (mode == TrainingMode.plansAndOrientation &&
        taskKey.startsWith('plan:path:')) {
      final parts = taskKey.split(':');
      final right = parts.length >= 4 ? int.tryParse(parts[2]) : null;
      final up = parts.length >= 4 ? int.tryParse(parts[3]) : null;
      if (right != null && up != null) {
        return TouchInteractionPlan(
          taskKey: taskKey,
          kind: TouchInteractionKind.pathWalker,
          instruction: 'Gehe den beschriebenen Weg Feld für Feld ab.',
          pathRight: right,
          pathUp: up,
          expectedAnswer: answer,
        );
      }
    }

    if (mode == TrainingMode.symmetry && taskKey.startsWith('symmetry:')) {
      final symmetry = _symmetrySpec(taskKey);
      if (symmetry != null) {
        return TouchInteractionPlan(
          taskKey: taskKey,
          kind: TouchInteractionKind.symmetryAxes,
          instruction:
              'Tippe alle Linien an, an denen die Figur gespiegelt werden kann.',
          symmetryShape: symmetry.$1,
          selectionLabels: symmetry.$2,
          correctSelectionIndexes: symmetry.$3,
          expectedAnswer: answer,
        );
      }
    }

    if (mode == TrainingMode.geometry &&
        taskKey.startsWith('geometry:corners:')) {
      final shape = taskKey.split(':').last;
      final correct = switch (shape) {
        'triangle' => const <int>[0, 2, 4],
        'square' || 'rectangle' => const <int>[0, 2, 4, 6],
        'circle' => const <int>[],
        _ => null,
      };
      if (correct != null) {
        return TouchInteractionPlan(
          taskKey: taskKey,
          kind: TouchInteractionKind.shapeCorners,
          instruction: 'Tippe genau die Ecken der Figur an.',
          geometryShape: shape,
          correctSelectionIndexes: correct,
          expectedAnswer: answer,
        );
      }
    }

    if (mode == TrainingMode.perimeterArea &&
        taskKey.startsWith('rect:perimeter:')) {
      final parts = taskKey.split(':');
      final width = parts.length >= 5 ? int.tryParse(parts[3]) : null;
      final height = parts.length >= 5 ? int.tryParse(parts[4]) : null;
      if (width != null && height != null && width > 0 && height > 0) {
        return TouchInteractionPlan(
          taskKey: taskKey,
          kind: TouchInteractionKind.rectanglePerimeterEdges,
          instruction: 'Tippe alle Kanten an, die zum Umfang gehören.',
          rectangleWidth: width,
          rectangleHeight: height,
          correctSelectionIndexes: const <int>[0, 1, 2, 3],
          expectedAnswer: answer,
        );
      }
    }

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

  static (String, List<String>, List<int>)? _symmetrySpec(String taskKey) {
    const names = <String>[
      'Quadrat',
      'Rechteck',
      'gleichseitiges Dreieck',
      'gleichschenkliges Dreieck',
    ];
    String? shape;
    final parts = taskKey.split(':');
    if (parts.length >= 3 && parts[1] == 'target') {
      final index = int.tryParse(parts[2]);
      if (index != null && index >= 0 && index < names.length) {
        shape = names[index];
      }
    } else if (parts.length >= 2) {
      shape = parts.sublist(1).join(':');
    }
    if (shape == null) return null;
    return switch (shape) {
      'Quadrat' => (
          shape,
          const <String>['Senkrecht', 'Waagerecht', 'Diagonal ↘', 'Diagonal ↙'],
          const <int>[0, 1, 2, 3],
        ),
      'Rechteck' => (
          shape,
          const <String>['Senkrecht', 'Waagerecht', 'Diagonal ↘', 'Diagonal ↙'],
          const <int>[0, 1],
        ),
      'gleichseitiges Dreieck' => (
          shape,
          const <String>[
            'Spitze → unten',
            'Links unten → Mitte',
            'Rechts unten → Mitte',
            'Waagerecht',
          ],
          const <int>[0, 1, 2],
        ),
      'gleichschenkliges Dreieck' => (
          shape,
          const <String>[
            'Spitze → unten',
            'Links unten → Mitte',
            'Rechts unten → Mitte',
            'Waagerecht',
          ],
          const <int>[0],
        ),
      _ => null,
    };
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
