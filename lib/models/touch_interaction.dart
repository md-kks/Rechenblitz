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
  fractionMeasure,
  proportionalUnitBuilder,
  scaleDistanceBuilder,
  lengthRulerOperation,
  unitConversionMachine,
  durationTimeline,
  calendarStepper,
  geometryRelationChoice,
  cubeNetFoldChoice,
  bodyPropertySelector,
  largeNumberCompare,
  largeNumberOrder,
  largeNumberDecompose,
  largeNumberPlaceDigit,
  numberWordPlaceValueBuilder,
  storyRelevantFacts,
  storyOperationRelation,
  storyEquationBuilder,
  storyInterpretationBuilder,
  mentalChunkPath,
  strategyAnchorJump,
  arithmeticLawStructure,
  romanNumeralReader,
  romanNumeralBuilder,
  inverseFamilyMachine,
  numberBondComposer,
  writtenColumnProcedure,
  writtenMultiplicationProcedure,
  writtenDivisionProcedure,
  routeSequenceWalker,
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
  probabilityExperimentComparison,
  probabilityRelativeHundredGrid,
  combinatoricsGrid,
  roundingNumberLine,
  estimationRounding,
  volumeLayerBuilder,
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
    if (mode == TrainingMode.rounding && taskKey.startsWith('round:')) {
      final parts = taskKey.split(':');
      if (parts.length == 3) {
        final number = int.tryParse(parts[1]);
        final place = int.tryParse(parts[2]);
        if (number != null && place != null && place > 0) {
          final lower = (number ~/ place) * place;
          final upper = lower + place;
          return TouchInteractionPlan(
            taskKey: taskKey,
            kind: TouchInteractionKind.roundingNumberLine,
            instruction:
                'Finde die beiden Nachbarwerte und entscheide auf der Zahlengeraden, welcher näher liegt.',
            minValue: lower,
            maxValue: upper,
            startValue: number,
            dataValues: <int>[place],
            expectedAnswer: answer,
          );
        }
      }
    }

    if (mode == TrainingMode.estimation &&
        taskKey.startsWith('estimate:') &&
        choices != null &&
        choices.isNotEmpty) {
      final parts = taskKey.split(':');
      if (parts.length == 4) {
        final a = int.tryParse(parts[1]);
        final b = int.tryParse(parts[2]);
        final place = int.tryParse(parts[3]);
        if (a != null && b != null && place != null && place > 0) {
          int rounded(int value) => ((value + place ~/ 2) ~/ place) * place;
          return TouchInteractionPlan(
            taskKey: taskKey,
            kind: TouchInteractionKind.estimationRounding,
            instruction:
                'Runde beide Summanden passend. Wähle danach selbst den passenden Überschlag.',
            dataValues: <int>[a, b, place, rounded(a), rounded(b)],
            answerChoices: choices,
            expectedAnswer: answer,
          );
        }
      }
    }

    if (mode == TrainingMode.volumeCubes && taskKey.startsWith('volume:')) {
      final parts = taskKey.split(':');
      if (parts.length == 4) {
        final length = int.tryParse(parts[1]);
        final width = int.tryParse(parts[2]);
        final height = int.tryParse(parts[3]);
        if (length != null &&
            width != null &&
            height != null &&
            length > 0 &&
            width > 0 &&
            height > 0 &&
            length * width <= 48 &&
            height <= 6) {
          return TouchInteractionPlan(
            taskKey: taskKey,
            kind: TouchInteractionKind.volumeLayerBuilder,
            instruction:
                'Baue die richtige Zahl gleich großer Würfelschichten. Berechne danach selbst die Gesamtzahl der Würfel.',
            dataValues: <int>[length, width, height],
            expectedAnswer: answer,
            maxValue: max(300, answer),
          );
        }
      }
    }

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

    if (mode == TrainingMode.probability &&
        taskKey.startsWith('prob:experiment:compare:') &&
        choices != null &&
        choices.length == 3) {
      final parts = taskKey.split(':');
      if (parts.length == 6) {
        final trials = int.tryParse(parts[3]);
        final red = int.tryParse(parts[4]);
        final blue = int.tryParse(parts[5]);
        if (trials != null &&
            red != null &&
            blue != null &&
            trials > 0 &&
            red >= 0 &&
            blue >= 0 &&
            red + blue == trials &&
            trials <= 40) {
          return TouchInteractionPlan(
            taskKey: taskKey,
            kind: TouchInteractionKind.probabilityExperimentComparison,
            instruction:
                'Lies die beobachteten Häufigkeiten und ordne die Beobachtung zu. Es geht um diese Versuchsreihe, nicht um eine Vorhersage.',
            dataValues: <int>[trials, red, blue],
            answerChoices: choices,
            expectedAnswer: answer,
          );
        }
      }
    }

    if (mode == TrainingMode.probability &&
        taskKey.startsWith('prob:experiment:relative:') &&
        choices != null &&
        choices.isNotEmpty) {
      final parts = taskKey.split(':');
      if (parts.length == 5) {
        final trials = int.tryParse(parts[3]);
        final hits = int.tryParse(parts[4]);
        if (trials != null && hits != null && trials > 0 && hits >= 0 && hits <= trials) {
          final percent = (hits * 100 / trials).round();
          return TouchInteractionPlan(
            taskKey: taskKey,
            kind: TouchInteractionKind.probabilityRelativeHundredGrid,
            instruction:
                'Übertrage den beobachteten Anteil auf 100 Kästchen. Markiere ungefähr so viele Kästchen wie der Prozentanteil.',
            dataValues: <int>[trials, hits, percent],
            answerChoices: choices,
            expectedAnswer: answer,
          );
        }
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

    if (mode == TrainingMode.wordProblems &&
        taskKey.startsWith('story:info:') &&
        choices != null &&
        choices.isNotEmpty) {
      final parts = taskKey.split(':');
      if (parts.length == 6) {
        final first = int.tryParse(parts[3]);
        final second = int.tryParse(parts[4]);
        final irrelevant = int.tryParse(parts[5]);
        if (first != null && second != null && irrelevant != null) {
          final labels = switch (parts[2]) {
            'trip' => <String>[
                '$first Kinder',
                '$second Erwachsene',
                '$irrelevant Bälle',
              ],
            'pencils' => <String>[
                '$first rote Stifte',
                '$second blaue Stifte',
                '$irrelevant leere Schachteln',
              ],
            'groups' => <String>[
                '$first Kinder in Gruppe 1',
                '$second Kinder in Gruppe 2',
                '$irrelevant Buchseiten',
              ],
            _ => const <String>[],
          };
          if (labels.length == 3) {
            return TouchInteractionPlan(
              taskKey: taskKey,
              kind: TouchInteractionKind.storyRelevantFacts,
              instruction:
                  'Markiere nur die Angaben, die du für die Frage wirklich brauchst.',
              selectionLabels: labels,
              correctSelectionIndexes: const <int>[0, 1],
              answerChoices: choices,
              expectedAnswer: answer,
              dataOperation: 'relevant-info',
            );
          }
        }
      }
    }

    if (mode == TrainingMode.wordProblems &&
        taskKey.startsWith('story:operation:') &&
        choices != null &&
        choices.isNotEmpty) {
      final parts = taskKey.split(':');
      if (parts.length == 5) {
        final a = int.tryParse(parts[3]);
        final b = int.tryParse(parts[4]);
        final operation = parts[2];
        if (a != null && b != null) {
          const all = <String>['+', '-', 'x', 'divide'];
          bool present(String op) => switch (op) {
                '+' => choices.any((choice) => choice.contains('Plus')),
                '-' => choices.any((choice) => choice.contains('Minus')),
                'x' => choices.any((choice) => choice.contains('Mal')),
                'divide' => choices.any((choice) => choice.contains('Geteilt')),
                _ => false,
              };
          final operations = all.where(present).toList(growable: false);
          final correct = operations.indexOf(operation);
          if (correct >= 0) {
            return TouchInteractionPlan(
              taskKey: taskKey,
              kind: TouchInteractionKind.storyOperationRelation,
              instruction:
                  'Wähle die mathematische Beziehung, die zur Situation passt.',
              dataValues: <int>[a, b],
              dataLabels: operations,
              dataOperation: operation,
              correctSelectionIndexes: <int>[correct],
              answerChoices: choices,
              expectedAnswer: answer,
            );
          }
        }
      }
    }

    if (mode == TrainingMode.wordProblems &&
        taskKey.startsWith('story:equation:') &&
        choices != null &&
        choices.isNotEmpty) {
      final parts = taskKey.split(':');
      if (parts.length == 5) {
        final a = int.tryParse(parts[3]);
        final b = int.tryParse(parts[4]);
        final operation = parts[2];
        if (a != null && b != null) {
          const symbols = <String, String>{
            '+': '+',
            '-': '−',
            'x': '×',
            'divide': '÷',
          };
          final operations = symbols.entries
              .where((entry) => choices.any((choice) => choice.contains(' ${entry.value} ')))
              .map((entry) => entry.key)
              .toList(growable: false);
          if (operations.contains(operation)) {
            return TouchInteractionPlan(
              taskKey: taskKey,
              kind: TouchInteractionKind.storyEquationBuilder,
              instruction:
                  'Baue aus den beiden Angaben und dem passenden Rechenzeichen die Rechnung.',
              dataValues: <int>[a, b],
              dataLabels: operations,
              dataOperation: operation,
              answerChoices: choices,
              expectedAnswer: answer,
            );
          }
        }
      }
    }

    if (mode == TrainingMode.wordProblems &&
        taskKey.startsWith('story:interpret:') &&
        choices != null &&
        choices.isNotEmpty) {
      final parts = taskKey.split(':');
      if (parts.length == 6) {
        final operation = parts[2];
        final a = int.tryParse(parts[3]);
        final b = int.tryParse(parts[4]);
        final result = int.tryParse(parts[5]);
        if ((operation == '+' || operation == '-') &&
            a != null &&
            b != null &&
            result != null) {
          final correctMeaning = operation == '+'
              ? 'Endbestand – so viele sind jetzt da'
              : 'Restbestand – so viele bleiben übrig';
          final rawMeanings = operation == '+'
              ? <String>[
                  correctMeaning,
                  'Abgabe – so viele wurden weggegeben',
                  'Zuwachs – so viele kommen noch dazu',
                  'Anfangsbestand – so viele waren vorher da',
                ]
              : <String>[
                  correctMeaning,
                  'Abgabe – so viele wurden weggenommen',
                  'Anfangsbestand – so viele waren vorher da',
                  'Zuwachs – so viele kommen dazu',
                ];
          final meaningShift = result % rawMeanings.length;
          final meanings = <String>[
            ...rawMeanings.skip(meaningShift),
            ...rawMeanings.take(meaningShift),
          ];
          final correctUnit = operation == '+' ? 'Sticker' : 'Karten';
          final rawUnits = <String>[correctUnit, 'Kinder', operation == '+' ? 'Karten' : 'Sticker'];
          final unitShift = (a + b) % rawUnits.length;
          final units = <String>[
            ...rawUnits.skip(unitShift),
            ...rawUnits.take(unitShift),
          ];
          return TouchInteractionPlan(
            taskKey: taskKey,
            kind: TouchInteractionKind.storyInterpretationBuilder,
            instruction:
                'Deute das Ergebnis: Was bedeutet die Zahl in der Situation und wozu gehört sie?',
            dataValues: <int>[a, b, result],
            dataLabels: meanings,
            selectionLabels: units,
            correctSelectionIndexes: <int>[
              meanings.indexOf(correctMeaning),
              units.indexOf(correctUnit),
            ],
            dataOperation: operation,
            expectedAnswer: answer,
            answerChoices: choices,
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

    if (mode == TrainingMode.measures &&
        (taskKey.startsWith('measure:add:') ||
            taskKey.startsWith('measure:subtract:'))) {
      final parts = taskKey.split(':');
      if (parts.length == 5) {
        final first = int.tryParse(parts[3]);
        final second = int.tryParse(parts[4]);
        final subtraction = taskKey.startsWith('measure:subtract:');
        if (first != null && second != null && first >= 0 && second >= 0) {
          final rulerMax = subtraction ? first : first + second;
          if (rulerMax > 0 && rulerMax <= 30) {
            return TouchInteractionPlan(
              taskKey: taskKey,
              kind: TouchInteractionKind.lengthRulerOperation,
              instruction: subtraction
                  ? 'Stelle auf dem Zentimeter-Lineal ein, wo das Seil nach dem Abschneiden endet.'
                  : 'Lege die beiden Längen gedanklich aneinander und stelle den gemeinsamen Endpunkt auf dem Zentimeter-Lineal ein.',
              minValue: 0,
              maxValue: rulerMax,
              startValue: subtraction ? first : first,
              dataValues: <int>[first, second],
              dataOperation: subtraction ? 'subtract' : 'add',
              expectedAnswer: answer,
            );
          }
        }
      }
    }

    if (mode == TrainingMode.advancedMeasures || mode == TrainingMode.measures) {
      final parts = taskKey.split(':');
      final source = int.tryParse(parts.isEmpty ? '' : parts.last);
      String? startUnit;
      String? targetUnit;
      String? operation;
      int? factor;
      if (taskKey.startsWith('measure:convert:dm-cm:')) {
        startUnit = 'dm'; targetUnit = 'cm'; operation = 'multiply'; factor = 10;
      } else if (taskKey.startsWith('measure:convert:m-cm:')) {
        startUnit = 'm'; targetUnit = 'cm'; operation = 'multiply'; factor = 100;
      } else if (taskKey.startsWith('measure:convert:cm-mm:')) {
        startUnit = 'cm'; targetUnit = 'mm'; operation = 'multiply'; factor = 10;
      } else if (taskKey.startsWith('measure:convert:cm-m:')) {
        startUnit = 'cm'; targetUnit = 'm'; operation = 'divide'; factor = 100;
      } else if (taskKey.startsWith('length:m:')) {
        startUnit = 'm'; targetUnit = 'cm'; operation = 'multiply'; factor = 100;
      } else if (taskKey.startsWith('length:km:')) {
        startUnit = 'km'; targetUnit = 'm'; operation = 'multiply'; factor = 1000;
      } else if (taskKey.startsWith('length:cm-mm:')) {
        startUnit = 'cm'; targetUnit = 'mm'; operation = 'multiply'; factor = 10;
      } else if (taskKey.startsWith('mass:kg:')) {
        startUnit = 'kg'; targetUnit = 'g'; operation = 'multiply'; factor = 1000;
      } else if (taskKey.startsWith('mass:t-kg:')) {
        startUnit = 't'; targetUnit = 'kg'; operation = 'multiply'; factor = 1000;
      } else if (taskKey.startsWith('volume:l:')) {
        startUnit = 'l'; targetUnit = 'ml'; operation = 'multiply'; factor = 1000;
      } else if (taskKey.startsWith('money:euro:')) {
        startUnit = '€'; targetUnit = 'ct'; operation = 'multiply'; factor = 100;
      } else if (taskKey.startsWith('time:min:')) {
        startUnit = 'min'; targetUnit = 'h'; operation = 'divide'; factor = 60;
      } else if (taskKey.startsWith('time:seconds:min-to-sec:')) {
        startUnit = 'min'; targetUnit = 's'; operation = 'multiply'; factor = 60;
      } else if (taskKey.startsWith('time:seconds:sec-to-min:')) {
        startUnit = 's'; targetUnit = 'min'; operation = 'divide'; factor = 60;
      }
      if (source != null && startUnit != null && targetUnit != null && operation != null && factor != null) {
        final symbol = operation == 'multiply' ? '×' : '÷';
        final opposite = operation == 'multiply' ? '÷' : '×';
        final altFactor = factor == 1000 ? 100 : factor == 100 ? 10 : factor == 60 ? 10 : 100;
        final correctLabel = '$symbol $factor';
        final oppositeLabel = '$opposite $factor';
        final alternativeLabel = '$symbol $altFactor';
        final (relationOptions, correctIndex) = switch ((factor, operation)) {
          (10, _) => (<String>[correctLabel, oppositeLabel, alternativeLabel], 0),
          (100, _) => (<String>[oppositeLabel, alternativeLabel, correctLabel], 2),
          (1000, _) => (<String>[alternativeLabel, correctLabel, oppositeLabel], 1),
          (60, 'divide') => (<String>[correctLabel, alternativeLabel, oppositeLabel], 0),
          _ => (<String>[alternativeLabel, oppositeLabel, correctLabel], 2),
        };
        return TouchInteractionPlan(
          taskKey: taskKey,
          kind: TouchInteractionKind.unitConversionMachine,
          instruction: 'Wähle zuerst die richtige Umrechnung. Berechne danach den Zahlenwert in der Zieleinheit.',
          dataValues: <int>[source, factor],
          dataLabels: <String>[startUnit, targetUnit],
          dataOperation: operation,
          answerChoices: relationOptions,
          correctSelectionIndexes: <int>[correctIndex],
          expectedAnswer: answer,
          maxValue: maxValue,
        );
      }
    }

    if (mode == TrainingMode.timeDurations &&
        (taskKey.startsWith('duration:weeks:') || taskKey.startsWith('duration:days:'))) {
      final source = int.tryParse(taskKey.split(':').last);
      final weeks = taskKey.startsWith('duration:weeks:');
      if (source != null) {
        final factor = weeks ? 7 : 24;
        final correctLabel = '× $factor';
        final oppositeLabel = '÷ $factor';
        final alternativeLabel = '× ${weeks ? 24 : 7}';
        final relationOptions = weeks
            ? <String>[alternativeLabel, oppositeLabel, correctLabel]
            : <String>[correctLabel, oppositeLabel, alternativeLabel];
        return TouchInteractionPlan(
          taskKey: taskKey,
          kind: TouchInteractionKind.unitConversionMachine,
          instruction: 'Wähle die passende Zeitbeziehung und berechne anschließend den neuen Zahlenwert.',
          dataValues: <int>[source, factor],
          dataLabels: <String>[weeks ? 'Wochen' : 'Tage', weeks ? 'Tage' : 'h'],
          dataOperation: 'multiply',
          answerChoices: relationOptions,
          correctSelectionIndexes: <int>[weeks ? 2 : 0],
          expectedAnswer: answer,
          maxValue: maxValue,
        );
      }
    }

    if (mode == TrainingMode.timeDurations && taskKey.startsWith('calendar:add:') && choices != null) {
      final parts = taskKey.split(':');
      if (parts.length == 5) {
        final month = parts[2];
        final start = int.tryParse(parts[3]);
        final addDays = int.tryParse(parts[4]);
        final monthDays = switch (month) {
          'März' || 'Mai' || 'Oktober' => 31,
          'April' || 'Juni' || 'September' => 30,
          _ => 31,
        };
        if (start != null && addDays != null) {
          return TouchInteractionPlan(
            taskKey: taskKey,
            kind: TouchInteractionKind.calendarStepper,
            instruction: 'Gehe im Kalender wirklich um die geforderte Zahl Tage weiter. Nutze ganze Wochen, wenn sie passen.',
            dataValues: <int>[start, addDays, monthDays],
            dataLabels: <String>[month],
            answerChoices: choices,
            expectedAnswer: answer,
          );
        }
      }
    }

    if (mode == TrainingMode.timeDurations &&
        taskKey.startsWith('duration:') &&
        !taskKey.startsWith('duration:weeks:') &&
        !taskKey.startsWith('duration:days:')) {
      final parts = taskKey.split(':');
      if (parts.length == 3) {
        final start = int.tryParse(parts[1]);
        final duration = int.tryParse(parts[2]);
        if (start != null && duration != null) {
          return TouchInteractionPlan(
            taskKey: taskKey,
            kind: TouchInteractionKind.durationTimeline,
            instruction: 'Gehe auf der Zeitlinie in passenden Etappen vom Beginn bis zum Ende.',
            dataValues: <int>[start, start + duration],
            expectedAnswer: answer,
          );
        }
      }
    }

    if (mode == TrainingMode.geometryBodies &&
        taskKey.startsWith('body:') &&
        !taskKey.startsWith('body:cube-net:')) {
      final parts = taskKey.split(':');
      if (parts.length == 3) {
        final body = parts[1];
        final property = parts[2];
        const counts = <String, Map<String, int>>{
          'Würfel': <String, int>{'Ecken': 8, 'Kanten': 12, 'Flächen': 6},
          'Quader': <String, int>{'Ecken': 8, 'Kanten': 12, 'Flächen': 6},
          'Kugel': <String, int>{'Ecken': 0, 'Kanten': 0, 'Flächen': 1},
          'Zylinder': <String, int>{'Ecken': 0, 'Kanten': 2, 'Flächen': 3},
          'Kegel': <String, int>{'Ecken': 1, 'Kanten': 1, 'Flächen': 2},
          'Pyramide': <String, int>{'Ecken': 5, 'Kanten': 8, 'Flächen': 5},
        };
        final count = counts[body]?[property];
        if (count != null && count == answer) {
          return TouchInteractionPlan(
            taskKey: taskKey,
            kind: TouchInteractionKind.bodyPropertySelector,
            instruction: property == 'Flächen'
                ? 'Tippe im Flächenmodell jede Fläche genau einmal an.'
                : 'Tippe am Körper jede $property genau einmal an. Rückwärtige Kanten sind gestrichelt.',
            geometryShape: body,
            dataOperation: property,
            correctSelectionIndexes: List<int>.generate(count, (index) => index),
            expectedAnswer: answer,
          );
        }
      }
    }

    if (mode == TrainingMode.geometryBodies &&
        taskKey.startsWith('body:cube-net:fold:') &&
        choices != null &&
        choices.length == 2) {
      final parts = taskKey.split(':');
      if (parts.length >= 7) {
        final pattern = parts.sublist(6).join(':');
        return TouchInteractionPlan(
          taskKey: taskKey,
          kind: TouchInteractionKind.cubeNetFoldChoice,
          instruction:
              'Prüfe das Netz selbst: Würden beim Falten sechs verschiedene Würfelflächen entstehen?',
          dataLabels: pattern.split(';'),
          answerChoices: choices,
          expectedAnswer: answer,
        );
      }
    }


    if (mode == TrainingMode.fractions &&
        (taskKey == 'fraction:time' || taskKey == 'fraction:volume') &&
        choices != null &&
        choices.isNotEmpty) {
      final timeTask = taskKey == 'fraction:time';
      return TouchInteractionPlan(
        taskKey: taskKey,
        kind: TouchInteractionKind.fractionMeasure,
        instruction: timeTask
            ? 'Teile eine Stunde in vier gleiche Viertel. Markiere 3 Viertel und bestimme ihre Minuten.'
            : 'Teile einen Liter in vier gleiche Viertel. Markiere 1 Viertel und bestimme seine Milliliter.',
        answerChoices: choices,
        dataValues: timeTask
            ? const <int>[3, 4, 60, 15]
            : const <int>[1, 4, 1000, 250],
        dataOperation: timeTask ? 'time' : 'volume',
        expectedAnswer: answer,
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

    if (mode == TrainingMode.proportionality &&
        taskKey.startsWith('proportion:')) {
      final parts = taskKey.split(':');
      if (parts.length == 5) {
        final unit = int.tryParse(parts[2]);
        final first = int.tryParse(parts[3]);
        final second = int.tryParse(parts[4]);
        if (unit != null &&
            first != null &&
            second != null &&
            unit > 0 &&
            first > 0 &&
            second > 0 &&
            first <= 8 &&
            second <= 12) {
          return TouchInteractionPlan(
            taskKey: taskKey,
            kind: TouchInteractionKind.proportionalUnitBuilder,
            instruction:
                'Bestimme zuerst den Wert für genau 1 Einheit. Übertrage ihn danach auf die gesuchte Anzahl.',
            dataValues: <int>[unit, first, second, unit * first],
            dataLabels: <String>[parts[1]],
            expectedAnswer: answer,
            maxValue: max(maxValue, answer),
          );
        }
      }
    }

    if (mode == TrainingMode.plansAndOrientation &&
        taskKey.startsWith('plan:scale:')) {
      final parts = taskKey.split(':');
      final metersPerCentimeter =
          parts.length >= 4 ? int.tryParse(parts[2]) : null;
      final planCentimeters =
          parts.length >= 4 ? int.tryParse(parts[3]) : null;
      if (metersPerCentimeter != null &&
          planCentimeters != null &&
          metersPerCentimeter > 0 &&
          planCentimeters > 0 &&
          planCentimeters <= 12) {
        final operationAlreadyChecked =
            targetCompetency == MicroCompetencyId.scale;
        return TouchInteractionPlan(
          taskKey: taskKey,
          kind: TouchInteractionKind.scaleDistanceBuilder,
          instruction: operationAlreadyChecked
              ? 'Die passende Rechenart wurde schon geprüft. Baue jetzt für jeden Plan-Zentimeter genau einen gleich großen Realstrecken-Block und bestimme danach die Gesamtstrecke selbst.'
              : 'Übertrage die Maßstabszuordnung: Baue für jeden Plan-Zentimeter genau einen gleich großen Realstrecken-Block und bestimme danach die Gesamtstrecke selbst.',
          dataValues: <int>[metersPerCentimeter, planCentimeters],
          dataOperation: operationAlreadyChecked ? 'operation-checked' : 'full',
          expectedAnswer: answer,
          maxValue: max(maxValue, answer),
        );
      }
    }

    if (mode == TrainingMode.geometryRelations &&
        taskKey.startsWith('geomrel:') &&
        choices != null &&
        choices.isNotEmpty) {
      final operation = taskKey.startsWith('geomrel:lines:')
          ? 'lines'
          : taskKey.startsWith('geomrel:angle:')
              ? 'angle'
              : taskKey.startsWith('geomrel:figure:')
                  ? 'figure'
                  : taskKey.startsWith('geomrel:circle:')
                      ? 'circle'
                      : null;
      if (operation != null && answer >= 0 && answer < choices.length) {
        return TouchInteractionPlan(
          taskKey: taskKey,
          kind: TouchInteractionKind.geometryRelationChoice,
          instruction: switch (operation) {
            'lines' => 'Tippe das Geradenbild an, das zur beschriebenen Lage passt.',
            'angle' => 'Vergleiche die gezeichneten Winkel mit einer Rechteck-Ecke und tippe das passende Bild an.',
            'figure' => 'Prüfe Seitenlängen und rechte Winkel. Tippe die passende Figur an.',
            _ => 'Tippe die Kreiszeichnung an, die zur beschriebenen Strecke passt.',
          },
          answerChoices: choices,
          correctSelectionIndexes: <int>[answer],
          dataOperation: operation,
          expectedAnswer: answer,
        );
      }
    }

    if (mode == TrainingMode.plansAndOrientation &&
        taskKey.startsWith('plan:route:')) {
      final parts = taskKey.split(':');
      final firstDirection = parts.length >= 6 ? parts[2] : null;
      final firstLength = parts.length >= 6 ? int.tryParse(parts[3]) : null;
      final secondDirection = parts.length >= 6 ? parts[4] : null;
      final secondLength = parts.length >= 6 ? int.tryParse(parts[5]) : null;
      const directions = <String>{'right', 'up', 'left', 'down'};
      if (firstDirection != null &&
          secondDirection != null &&
          directions.contains(firstDirection) &&
          directions.contains(secondDirection) &&
          firstDirection != secondDirection &&
          firstLength != null &&
          secondLength != null &&
          firstLength > 0 &&
          secondLength > 0) {
        final firstAlreadyChecked =
            targetCompetency == MicroCompetencyId.planDirections;
        return TouchInteractionPlan(
          taskKey: taskKey,
          kind: TouchInteractionKind.routeSequenceWalker,
          instruction: firstAlreadyChecked
              ? 'Der erste Wegabschnitt wurde schon geprüft. Setze die Route jetzt Feld für Feld mit dem zweiten Abschnitt fort.'
              : 'Laufe den Pfeilplan Feld für Feld in der richtigen Reihenfolge ab.',
          dataLabels: <String>[firstDirection, secondDirection],
          dataValues: <int>[firstLength, secondLength],
          dataOperation: firstAlreadyChecked ? 'skip-first' : 'full',
          answerChoices: choices ?? const <String>[],
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
        taskKey.startsWith('geometry:name:') &&
        choices != null &&
        choices.length == 4 &&
        answer >= 0 &&
        answer < choices.length) {
      return TouchInteractionPlan(
        taskKey: taskKey,
        kind: TouchInteractionKind.geometryRelationChoice,
        instruction: 'Tippe die Form an, die du oben siehst.',
        answerChoices: choices,
        correctSelectionIndexes: <int>[answer],
        dataOperation: 'basic-shape',
        expectedAnswer: answer,
      );
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

    if (mode == TrainingMode.mentalStrategies &&
        taskKey.startsWith('process:strategy:')) {
      final parts = taskKey.split(':');
      final a = parts.length >= 6 ? int.tryParse(parts[3]) : null;
      final b = parts.length >= 6 ? int.tryParse(parts[4]) : null;
      final anchor = parts.length >= 6 ? int.tryParse(parts[5]) : null;
      if (a != null && b != null && anchor != null) {
        final gap = anchor - a;
        final rest = b - gap;
        if (gap > 0 && rest >= 0 && gap <= b) {
          return TouchInteractionPlan(
            taskKey: taskKey,
            kind: TouchInteractionKind.strategyAnchorJump,
            instruction:
                'Finde zuerst den passenden Sprung zur glatten Zielzahl. Erst danach bleibt der Rest des zweiten Summanden übrig.',
            dataValues: <int>[a, b, anchor, gap, rest],
            answerChoices: choices ?? const <String>[],
            expectedAnswer: answer,
            maxValue: max(maxValue, anchor + rest),
          );
        }
      }
    }

    if (mode == TrainingMode.mentalStrategies &&
        taskKey.startsWith('mental:')) {
      final parts = taskKey.split(':');
      final a = parts.length >= 4 ? int.tryParse(parts[2]) : null;
      final b = parts.length >= 4 ? int.tryParse(parts[3]) : null;
      final operation = parts.length >= 2 ? parts[1] : '';
      if (a != null &&
          b != null &&
          b >= 10 &&
          (operation == '+' || operation == '-')) {
        final chunks = <int>[];
        var place = 1;
        while (place * 10 <= b) {
          place *= 10;
        }
        var remaining = b;
        while (place >= 1) {
          final digit = remaining ~/ place;
          if (digit > 0) {
            final chunk = digit * place;
            chunks.add(chunk);
            remaining -= chunk;
          }
          place ~/= 10;
        }
        if (chunks.length >= 2) {
          return TouchInteractionPlan(
            taskKey: taskKey,
            kind: TouchInteractionKind.mentalChunkPath,
            instruction:
                'Zerlege den zweiten Operanden in Stellenwertblöcke. Rechne vom größten Block zum kleinsten und gib danach das Ergebnis selbst ein.',
            dataValues: <int>[a, b, ...chunks],
            dataOperation: targetCompetency == MicroCompetencyId.mentalStrategy
                ? '$operation:skip-first'
                : operation,
            expectedAnswer: answer,
            maxValue: max(maxValue, max(a, answer)),
          );
        }
      }
    }

    if (mode == TrainingMode.arithmeticLaws &&
        taskKey.startsWith('law:associate:')) {
      final parts = taskKey.split(':');
      final a = parts.length >= 5 ? int.tryParse(parts[2]) : null;
      final b = parts.length >= 5 ? int.tryParse(parts[3]) : null;
      final c = parts.length >= 5 ? int.tryParse(parts[4]) : null;
      if (a != null && b != null && c != null) {
        return TouchInteractionPlan(
          taskKey: taskKey,
          kind: TouchInteractionKind.arithmeticLawStructure,
          instruction:
              'Tippe genau die zwei Summanden an, die du für einen Rechenvorteil zuerst zusammenfassen würdest.',
          dataValues: <int>[a, b, c],
          dataOperation: 'associate',
          correctSelectionIndexes: const <int>[0, 2],
          expectedAnswer: answer,
        );
      }
    }

    if (mode == TrainingMode.arithmeticLaws &&
        taskKey.startsWith('law:commute:')) {
      final parts = taskKey.split(':');
      final a = parts.length >= 4 ? int.tryParse(parts[2]) : null;
      final b = parts.length >= 4 ? int.tryParse(parts[3]) : null;
      if (a != null && b != null && a != b) {
        return TouchInteractionPlan(
          taskKey: taskKey,
          kind: TouchInteractionKind.arithmeticLawStructure,
          instruction:
              'Baue die vertauschte Malaufgabe, indem du die beiden Faktoren in der neuen Reihenfolge antippst.',
          dataValues: <int>[a, b],
          dataOperation: 'commute',
          correctSelectionIndexes: const <int>[1, 0],
          expectedAnswer: answer,
        );
      }
    }

    if (mode == TrainingMode.arithmeticLaws &&
        taskKey.startsWith('law:distribute:')) {
      final parts = taskKey.split(':');
      final factor = parts.length >= 4 ? int.tryParse(parts[2]) : null;
      final value = parts.length >= 4 ? int.tryParse(parts[3]) : null;
      if (factor != null && value != null && factor > 0 && value > 0) {
        final rounded = ((value + 9) ~/ 10) * 10;
        final gap = rounded - value;
        if (gap > 0) {
          return TouchInteractionPlan(
            taskKey: taskKey,
            kind: TouchInteractionKind.arithmeticLawStructure,
            instruction:
                'Zerlege über die nächste glatte Zahl: Bestimme zuerst den Abstand und danach die nötige Produkt-Korrektur.',
            dataValues: <int>[factor, value, rounded, gap],
            dataOperation: 'distribute',
            expectedAnswer: answer,
            maxValue: max(maxValue, answer),
          );
        }
      }
    }

    if (mode == TrainingMode.romanNumerals && taskKey.startsWith('roman:')) {
      final parts = taskKey.split(':');
      final value = parts.length >= 3 ? int.tryParse(parts[2]) : null;
      if (value != null && value >= 1 && value <= 100) {
        final roman = _romanText(value);
        if (parts[1] == 'read') {
          final tokens = _romanTokens(value);
          return TouchInteractionPlan(
            taskKey: taskKey,
            kind: TouchInteractionKind.romanNumeralReader,
            instruction: targetCompetency == MicroCompetencyId.romanNumeral
                ? 'Der Zehnerblock wurde schon geprüft. Bestimme jetzt den Gesamtwert der römischen Zahl.'
                : 'Lies die römische Zahl blockweise. Bestimme erst die Werte der Blöcke und danach den Gesamtwert.',
            dataLabels: tokens.map((entry) => entry.$1).toList(growable: false),
            dataValues: tokens.map((entry) => entry.$2).toList(growable: false),
            dataOperation: targetCompetency == MicroCompetencyId.romanNumeral
                ? 'read-total'
                : 'read-groups',
            unitLabel: roman,
            expectedAnswer: answer,
            maxValue: max(maxValue, value),
          );
        }
        if (parts[1] == 'write' && choices != null && choices.isNotEmpty) {
          return TouchInteractionPlan(
            taskKey: taskKey,
            kind: TouchInteractionKind.romanNumeralBuilder,
            instruction:
                'Baue die römische Zahl selbst aus I, V, X, L und C. Achte besonders auf IV, IX, XL und XC.',
            dataValues: <int>[value],
            dataLabels: roman.split(''),
            answerChoices: choices,
            unitLabel: roman,
            expectedAnswer: answer,
            maxValue: maxValue,
          );
        }
      }
    }

    if (mode == TrainingMode.factFamilies && taskKey.startsWith('family:')) {
      final parts = taskKey.split(':');
      final operation = parts.length >= 4 ? parts[1] : '';
      final a = parts.length >= 4 ? int.tryParse(parts[2]) : null;
      final b = parts.length >= 4 ? int.tryParse(parts[3]) : null;
      if (a != null && b != null && a >= 0 && b > 0 &&
          (operation == '+' || operation == 'x')) {
        final multiply = operation == 'x';
        final result = multiply ? a * b : a + b;
        final skipOperation =
            targetCompetency == MicroCompetencyId.inverseRelationship;
        return TouchInteractionPlan(
          taskKey: taskKey,
          kind: TouchInteractionKind.inverseFamilyMachine,
          instruction: skipOperation
              ? 'Die Gegenoperation wurde schon geprüft. Nutze sie jetzt, um vom Ergebnis zur Ausgangszahl zurückzurechnen.'
              : 'Drehe die Rechenmaschine um: Wähle zuerst die passende Gegenoperation und rechne dann zur Ausgangszahl zurück.',
          dataValues: <int>[a, b, result],
          dataOperation:
              '${multiply ? 'multiply' : 'add'}${skipOperation ? ':skip-operation' : ''}',
          expectedAnswer: answer,
          maxValue: max(maxValue, result),
        );
      }
    }

    if (mode == TrainingMode.writtenMultiply &&
        taskKey.startsWith('written:x:')) {
      final parts = taskKey.split(':');
      final a = parts.length >= 4 ? int.tryParse(parts[2]) : null;
      final b = parts.length >= 4 ? int.tryParse(parts[3]) : null;
      if (a != null && b != null && a > 0 && b > 0 && b < 100) {
        return TouchInteractionPlan(
          taskKey: taskKey,
          kind: TouchInteractionKind.writtenMultiplicationProcedure,
          instruction: b < 10
              ? 'Multipliziere von rechts nach links. Setze Ergebnisziffer und Übertrag in jeder Spalte.'
              : 'Baue die Teilprodukte von rechts nach links und beachte die Stellenverschiebung der Zehnerzeile.',
          dataValues: <int>[a, b],
          dataOperation: b < 10 ? 'single' : 'partial',
          expectedAnswer: answer,
          maxValue: max(maxValue, answer),
        );
      }
    }

    if (mode == TrainingMode.writtenDivide &&
        (taskKey.startsWith('written:divide:') ||
            taskKey.startsWith('written:divide-rest:'))) {
      final parts = taskKey.split(':');
      final dividend = parts.length >= 4 ? int.tryParse(parts[parts.length - 2]) : null;
      final divisor = parts.length >= 4 ? int.tryParse(parts.last) : null;
      final withRest = taskKey.startsWith('written:divide-rest:');
      if (dividend != null &&
          divisor != null &&
          dividend > 0 &&
          divisor > 1 &&
          divisor <= 9 &&
          (!withRest || (choices != null && choices.isNotEmpty))) {
        return TouchInteractionPlan(
          taskKey: taskKey,
          kind: TouchInteractionKind.writtenDivisionProcedure,
          instruction:
              'Teile von links nach rechts: Quotientenziffer bestimmen, multiplizieren, abziehen und die nächste Ziffer herunterholen.',
          dataValues: <int>[dividend, divisor],
          dataOperation: withRest ? 'rest' : 'exact',
          answerChoices: choices ?? const <String>[],
          expectedAnswer: answer,
          maxValue: max(9, dividend ~/ divisor),
        );
      }
    }

    if (mode == TrainingMode.writtenAddSub &&
        (taskKey.startsWith('written:+:') ||
            taskKey.startsWith('written:-:'))) {
      final parts = taskKey.split(':');
      final a = parts.length >= 4 ? int.tryParse(parts[2]) : null;
      final b = parts.length >= 4 ? int.tryParse(parts[3]) : null;
      if (a != null && b != null && a >= 0 && b >= 0 && a >= (parts[1] == '-' ? b : 0)) {
        return TouchInteractionPlan(
          taskKey: taskKey,
          kind: TouchInteractionKind.writtenColumnProcedure,
          instruction: parts[1] == '+'
              ? 'Rechne Spalte für Spalte von rechts nach links. Setze Ergebnisziffer und Übertrag bewusst.'
              : 'Rechne Spalte für Spalte von rechts nach links. Entbündele nur, wenn die obere Ziffer nicht reicht.',
          dataValues: <int>[a, b],
          dataOperation: parts[1],
          expectedAnswer: answer,
          maxValue: max(maxValue, answer),
        );
      }
    }

    if (mode == TrainingMode.largeNumbers &&
        taskKey.startsWith('large:compare:') &&
        choices != null &&
        choices.isNotEmpty) {
      final parts = taskKey.split(':');
      final a = parts.length >= 4 ? int.tryParse(parts[2]) : null;
      final b = parts.length >= 4 ? int.tryParse(parts[3]) : null;
      if (a != null && b != null && a != b) {
        var place = 1;
        final largest = max(a.abs(), b.abs());
        while (place * 10 <= largest) {
          place *= 10;
        }
        while (place > 1 && (a ~/ place) % 10 == (b ~/ place) % 10) {
          place ~/= 10;
        }
        return TouchInteractionPlan(
          taskKey: taskKey,
          kind: TouchInteractionKind.largeNumberCompare,
          instruction:
              'Markiere zuerst die erste unterschiedliche Stelle von links. Wähle danach das passende Vergleichszeichen.',
          dataValues: <int>[a, b, place],
          answerChoices: choices,
          dataOperation: targetCompetency == MicroCompetencyId.largeNumberCompare
              ? 'relation-only'
              : 'mark-place',
          expectedAnswer: answer,
        );
      }
    }

    if (mode == TrainingMode.largeNumbers &&
        taskKey.startsWith('large:order:') &&
        choices != null &&
        choices.isNotEmpty) {
      final raw = taskKey.substring('large:order:'.length);
      final ordered = raw
          .split('-')
          .map(int.tryParse)
          .whereType<int>()
          .toList(growable: false);
      if (ordered.length == 3 && ordered.toSet().length == 3) {
        final display = (ordered.reduce((a, b) => a + b)).isEven
            ? <int>[ordered[1], ordered[2], ordered[0]]
            : <int>[ordered[2], ordered[0], ordered[1]];
        final correctOrder = ordered
            .map((value) => display.indexOf(value))
            .toList(growable: false);
        return TouchInteractionPlan(
          taskKey: taskKey,
          kind: TouchInteractionKind.largeNumberOrder,
          instruction:
              'Tippe die drei Zahlen nacheinander von klein nach groß an.',
          dataValues: display,
          correctSelectionIndexes: correctOrder,
          answerChoices: choices,
          expectedAnswer: answer,
        );
      }
    }

    if (mode == TrainingMode.largeNumbers &&
        taskKey.startsWith('large:decompose:')) {
      final parts = taskKey.split(':');
      final number = parts.length >= 3 ? int.tryParse(parts[2]) : null;
      if (number != null && number >= 0) {
        return TouchInteractionPlan(
          taskKey: taskKey,
          kind: TouchInteractionKind.largeNumberDecompose,
          instruction:
              'Baue die Zahl in der Stellenwerttafel aus den angegebenen Stellenwerten zusammen.',
          dataValues: <int>[number],
          expectedAnswer: answer,
        );
      }
    }

    if (mode == TrainingMode.largeNumbers &&
        taskKey.startsWith('large:place:')) {
      final parts = taskKey.split(':');
      final number = parts.length >= 4 ? int.tryParse(parts[2]) : null;
      final place = parts.length >= 4 ? int.tryParse(parts[3]) : null;
      if (number != null && place != null && place > 0) {
        return TouchInteractionPlan(
          taskKey: taskKey,
          kind: TouchInteractionKind.largeNumberPlaceDigit,
          instruction:
              'Tippe in der Stellenwerttafel genau die gefragte Stelle an.',
          dataValues: <int>[number, place],
          expectedAnswer: answer,
        );
      }
    }

    if (mode == TrainingMode.largeNumbers &&
        taskKey.startsWith('large:word:read:') &&
        choices != null &&
        choices.isNotEmpty) {
      final parts = taskKey.split(':');
      final number = parts.length >= 4 ? int.tryParse(parts[3]) : null;
      if (number != null && number >= 0 && answer >= 0 && answer < choices.length) {
        return TouchInteractionPlan(
          taskKey: taskKey,
          kind: TouchInteractionKind.numberWordPlaceValueBuilder,
          instruction:
              'Entschlüssle das Zahlwort Stelle für Stelle. Tippe eine Stelle an und setze dort die passende Ziffer.',
          dataValues: <int>[number],
          dataOperation: targetCompetency == MicroCompetencyId.numberWordReading
              ? 'read:skip-tens-ones'
              : 'read',
          answerChoices: choices,
          expectedAnswer: answer,
          maxValue: maxValue,
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

    if (mode == TrainingMode.numberFriends && taskKey.startsWith('plus:')) {
      final parts = taskKey.split(':');
      if (parts.length == 3) {
        final known = int.tryParse(parts[1]);
        final missing = int.tryParse(parts[2]);
        if (known != null && missing != null) {
          final target = known + missing;
          if (target > 0 && target <= 20 && answer == missing) {
            return TouchInteractionPlan(
              taskKey: taskKey,
              kind: TouchInteractionKind.numberBondComposer,
              instruction:
                  'Baue den fehlenden Teil so, dass beide Teile zusammen genau $target ergeben.',
              dataValues: <int>[target, known],
              expectedAnswer: answer,
              maxValue: target,
            );
          }
        }
      }
    }

    if (mode == TrainingMode.doublesHalves &&
        (taskKey.startsWith('double:') || taskKey.startsWith('half:'))) {
      final parts = taskKey.split(':');
      final value = parts.length == 2 ? int.tryParse(parts[1]) : null;
      if (value != null && value > 0) {
        if (taskKey.startsWith('double:')) {
          final total = value * 2;
          if (total <= 24) {
            return TouchInteractionPlan(
              taskKey: taskKey,
              kind: TouchInteractionKind.equalGroupsBuilder,
              instruction: targetCompetency == MicroCompetencyId.doublesHalves
                  ? 'Die Bedeutung von „doppelt“ wurde schon geprüft. Baue jetzt zwei gleich große Gruppen mit je $value Punkten.'
                  : 'Baue zwei gleich große Gruppen mit je $value Punkten. Zusammen zeigen sie das Doppelte.',
              groupCount: 2,
              itemsPerGroup: value,
              totalItems: total,
              expectedAnswer: answer,
            );
          }
        } else if (value <= 24 && value.isEven) {
          return TouchInteractionPlan(
            taskKey: taskKey,
            kind: TouchInteractionKind.divisionGroupsBuilder,
            instruction: targetCompetency == MicroCompetencyId.doublesHalves
                ? 'Die Bedeutung von „Hälfte“ wurde schon geprüft. Verteile jetzt alle $value Punkte fair auf zwei gleich große Gruppen.'
                : 'Verteile alle $value Punkte fair auf zwei gleich große Gruppen. Eine Gruppe ist die Hälfte.',
            totalItems: value,
            groupCount: 2,
            itemsPerGroup: value ~/ 2,
            divisionGrouping: false,
            expectedAnswer: answer,
          );
        }
      }
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

  static String _romanText(int value) {
    var rest = value;
    final out = StringBuffer();
    const values = <int>[100, 90, 50, 40, 10, 9, 5, 4, 1];
    const symbols = <String>['C', 'XC', 'L', 'XL', 'X', 'IX', 'V', 'IV', 'I'];
    for (var i = 0; i < values.length; i++) {
      while (rest >= values[i]) {
        out.write(symbols[i]);
        rest -= values[i];
      }
    }
    return out.toString();
  }

  static List<(String, int)> _romanTokens(int value) {
    var rest = value;
    final out = <(String, int)>[];
    const values = <int>[100, 90, 50, 40, 10, 9, 5, 4, 1];
    const symbols = <String>['C', 'XC', 'L', 'XL', 'X', 'IX', 'V', 'IV', 'I'];
    for (var i = 0; i < values.length; i++) {
      while (rest >= values[i]) {
        out.add((symbols[i], values[i]));
        rest -= values[i];
      }
    }
    return out;
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
