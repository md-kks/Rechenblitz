import 'dart:math';

import 'micro_competency.dart';
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
  shapeSides,
  rectanglePerimeterEdges,
  rectangleAreaBuilder,
  equalGroupsBuilder,
  divisionGroupsBuilder,
  dataChartSelection,
  tallySelection,
  representationSorter,
  probabilityOutcomes,
  probabilityBagComparison,
  combinatoricsGrid,
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
    this.groupCount,
    this.itemsPerGroup,
    this.totalItems,
    this.divisionGrouping = false,
    this.dataValues = const <int>[],
    this.dataLabels = const <String>[],
    this.dataOperation,
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
  final int? groupCount;
  final int? itemsPerGroup;
  final int? totalItems;
  final bool divisionGrouping;
  final List<int> dataValues;
  final List<String> dataLabels;
  final String? dataOperation;

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
    MicroCompetencyId? targetCompetency,
  }) {
    if (mode == TrainingMode.dataCharts &&
        taskKey.startsWith('data:representation:') &&
        choices != null &&
        choices.length == 3) {
      final kind = int.tryParse(taskKey.split(':').last);
      if (kind != null && kind >= 0 && kind < choices.length) {
        return TouchInteractionPlan(
          taskKey: taskKey,
          kind: TouchInteractionKind.representationSorter,
          instruction:
              'Ziehe die Situation zu der Darstellung, die dafür am besten passt.',
          answerChoices: choices,
          expectedAnswer: answer,
        );
      }
    }

    if (mode == TrainingMode.probability &&
        (taskKey.startsWith('prob:sure:') ||
            taskKey.startsWith('prob:possible:') ||
            taskKey.startsWith('prob:impossible:'))) {
      final parts = taskKey.split(':');
      if (parts.length == 4) {
        final matching = <int>[];
        if (parts[1] == 'sure' && parts[2] == 'below') {
          final boundary = int.tryParse(parts[3]);
          if (boundary != null) {
            for (var face = 1; face <= 6; face++) {
              if (face < boundary) matching.add(face - 1);
            }
          }
        } else if ((parts[1] == 'possible' || parts[1] == 'impossible') &&
            parts[2] == 'face') {
          final face = int.tryParse(parts[3]);
          if (face != null && face >= 1 && face <= 6) {
            matching.add(face - 1);
          }
        }
        return TouchInteractionPlan(
          taskKey: taskKey,
          kind: TouchInteractionKind.probabilityOutcomes,
          instruction:
              'Markiere alle Würfelergebnisse von 1 bis 6, bei denen die Aussage stimmt.',
          selectionLabels: const <String>['1', '2', '3', '4', '5', '6'],
          correctSelectionIndexes: matching,
          expectedAnswer: answer,
        );
      }
    }

    if (mode == TrainingMode.probability && taskKey.startsWith('prob:bag:')) {
      final parts = taskKey.split(':');
      if (parts.length == 5) {
        final red = int.tryParse(parts[3]);
        final blue = int.tryParse(parts[4]);
        if (red != null && blue != null && red > 0 && blue > 0 &&
            red <= 12 && blue <= 12) {
          return TouchInteractionPlan(
            taskKey: taskKey,
            kind: TouchInteractionKind.probabilityBagComparison,
            instruction:
                'Vergleiche die beiden Mengen und ziehe den Chance-Marker zur größeren Menge oder in die Mitte bei Gleichstand.',
            dataValues: <int>[red, blue],
            dataLabels: const <String>['Rot', 'Blau'],
            expectedAnswer: answer,
          );
        }
      }
    }

    if (mode == TrainingMode.combinatorics && taskKey.startsWith('combo:')) {
      final parts = taskKey.split(':');
      if (parts.length == 5) {
        final first = int.tryParse(parts[2]);
        final second = int.tryParse(parts[3]);
        final third = int.tryParse(parts[4]);
        if (first != null && second != null && third != null &&
            first > 0 && second > 0 && third > 0) {
          final total = first * second * third;
          if (total <= 24) {
            return TouchInteractionPlan(
              taskKey: taskKey,
              kind: TouchInteractionKind.combinatoricsGrid,
              instruction:
                  'Markiere jede mögliche Kombination genau einmal. Arbeite systematisch Zeile für Zeile.',
              dataValues: <int>[first, second, third],
              dataLabels: <String>[parts[1]],
              expectedAnswer: answer,
            );
          }
        }
      }
    }

    if (mode == TrainingMode.dataCharts && taskKey.startsWith('data:tally:')) {
      final count = int.tryParse(taskKey.split(':').last);
      if (count != null && count > 0 && count <= 50) {
        final groups = count ~/ 5;
        final rest = count % 5;
        final units = <int>[
          ...List<int>.filled(groups, 5),
          ...List<int>.filled(rest, 1),
        ];
        return TouchInteractionPlan(
          taskKey: taskKey,
          kind: TouchInteractionKind.tallySelection,
          instruction: 'Tippe jeden sichtbaren Fünferblock und jeden Reststrich genau einmal an.',
          dataValues: units,
          dataOperation: 'tally',
          expectedAnswer: answer,
        );
      }
    }

    if (mode == TrainingMode.dataCharts &&
        (taskKey.startsWith('data:max:') ||
            taskKey.startsWith('data:sum:') ||
            taskKey.startsWith('data:diff:'))) {
      final parts = taskKey.split(':');
      if (parts.length == 3) {
        final values = parts[2]
            .split('-')
            .map(int.tryParse)
            .whereType<int>()
            .toList(growable: false);
        if (values.length == 4 && values.every((value) => value > 0 && value <= 12)) {
          return TouchInteractionPlan(
            taskKey: taskKey,
            kind: TouchInteractionKind.dataChartSelection,
            instruction: switch (parts[1]) {
              'max' => 'Markiere den höchsten Balken.',
              'sum' => 'Markiere alle Balken, deren Werte du für die Summe brauchst.',
              _ => 'Markiere Rot und Blau für den Vergleich.',
            },
            dataValues: values,
            dataLabels: const <String>['Rot', 'Blau', 'Grün', 'Gelb'],
            dataOperation: parts[1],
            expectedAnswer: answer,
            maxValue: maxValue,
          );
        }
      }
    }

    if (targetCompetency == MicroCompetencyId.multiplicationGroups) {
      final multiplication = _multiplicationGroupsSpec(mode, taskKey);
      if (multiplication != null) {
        final groups = multiplication.$1;
        final each = multiplication.$2;
        final total = groups * each;
        if (groups > 0 && each > 0 && groups <= 6 && total <= 48) {
          return TouchInteractionPlan(
            taskKey: taskKey,
            kind: TouchInteractionKind.equalGroupsBuilder,
            instruction:
                'Baue $groups gleich große Gruppen mit jeweils $each Punkten.',
            groupCount: groups,
            itemsPerGroup: each,
            totalItems: total,
            expectedAnswer: answer,
          );
        }
      }
    }

    if (mode == TrainingMode.wordProblems &&
        targetCompetency == MicroCompetencyId.divisionSharing) {
      final division = _divisionGroupsSpec(taskKey, answer);
      if (division != null && division.$1 <= 48) {
        return TouchInteractionPlan(
          taskKey: taskKey,
          kind: TouchInteractionKind.divisionGroupsBuilder,
          instruction: division.$4
              ? 'Bilde gleich große Gruppen mit jeweils ${division.$3} Dingen.'
              : 'Verteile alle ${division.$1} Dinge gleichmäßig auf ${division.$2} Gruppen.',
          totalItems: division.$1,
          groupCount: division.$2,
          itemsPerGroup: division.$3,
          divisionGrouping: division.$4,
          expectedAnswer: answer,
        );
      }
    }

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
        instruction: 'Stelle die Zeiger genauso ein wie bei der Uhr oben.',
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

    if (mode == TrainingMode.geometry &&
        taskKey.startsWith('geometry:sides:')) {
      final shape = taskKey.split(':').last;
      final correct = switch (shape) {
        'triangle' => const <int>[0, 1, 2],
        'square' || 'rectangle' => const <int>[0, 1, 2, 3],
        'circle' => const <int>[],
        _ => null,
      };
      if (correct != null) {
        return TouchInteractionPlan(
          taskKey: taskKey,
          kind: TouchInteractionKind.shapeSides,
          instruction: shape == 'circle'
              ? 'Prüfe, ob der Kreis gerade Seiten hat.'
              : 'Tippe jede gerade Seite der Figur genau einmal an.',
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

    if (mode == TrainingMode.perimeterArea &&
        taskKey.startsWith('rect:area:')) {
      final parts = taskKey.split(':');
      final width = parts.length >= 5 ? int.tryParse(parts[3]) : null;
      final height = parts.length >= 5 ? int.tryParse(parts[4]) : null;
      if (width != null &&
          height != null &&
          width > 0 &&
          height > 0 &&
          width <= 50 &&
          height <= 50) {
        return TouchInteractionPlan(
          taskKey: taskKey,
          kind: TouchInteractionKind.rectangleAreaBuilder,
          instruction:
              'Baue das Rechteck aus Länge und Breite. Die Fläche entsteht aus Reihen und Spalten.',
          rectangleWidth: width,
          rectangleHeight: height,
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

  static (int, int)? _multiplicationGroupsSpec(
    TrainingMode mode,
    String taskKey,
  ) {
    if (mode == TrainingMode.multiply && taskKey.startsWith('multiply:')) {
      final parts = taskKey.split(':');
      if (parts.length != 3) return null;
      final a = int.tryParse(parts[1]);
      final b = int.tryParse(parts[2]);
      if (a == null || b == null) return null;
      return (a, b);
    }
    if (mode == TrainingMode.wordProblems &&
        taskKey.startsWith('story:transfer:skill:multiplicationGroups:x:')) {
      final parts = taskKey.split(':');
      if (parts.length < 8) return null;
      final groups = int.tryParse(parts[parts.length - 2]);
      final each = int.tryParse(parts.last);
      if (groups == null || each == null) return null;
      return (groups, each);
    }
    return null;
  }

  static (int, int?, int?, bool)? _divisionGroupsSpec(
    String taskKey,
    int answer,
  ) {
    final parts = taskKey.split(':');
    if (parts.isEmpty || parts.first != 'story') return null;

    if (parts.length == 5) {
      final total = int.tryParse(parts[3]);
      final known = int.tryParse(parts[4]);
      if (total == null || known == null || total <= 0 || known <= 0) {
        return null;
      }
      if (parts[1] == 'sharing') {
        return (total, known, answer, false);
      }
      if (parts[1] == 'grouping') {
        return (total, answer, known, true);
      }
      return null;
    }

    if (parts.length == 8 &&
        parts[1] == 'transfer' &&
        parts[2] == 'skill' &&
        parts[3] == MicroCompetencyId.divisionSharing.name &&
        parts[4] == 'divide') {
      final context = parts[5];
      final total = int.tryParse(parts[6]);
      final known = int.tryParse(parts[7]);
      if (total == null || known == null || total <= 0 || known <= 0) {
        return null;
      }
      const groupingContexts = <String>{'groups', 'packs', 'rows'};
      const sharingContexts = <String>{'teams', 'bags', 'plates'};
      if (groupingContexts.contains(context)) {
        return (total, answer, known, true);
      }
      if (sharingContexts.contains(context)) {
        return (total, known, answer, false);
      }
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
