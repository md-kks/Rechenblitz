import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/error_diagnosis.dart';

class LearningVisualAid extends StatelessWidget {
  const LearningVisualAid({
    super.key,
    required this.pattern,
    required this.taskKey,
    required this.expected,
    this.methodKey,
  });

  final ErrorPattern pattern;
  final String taskKey;
  final int expected;
  final String? methodKey;

  static bool canRender({
    required ErrorPattern pattern,
    required String taskKey,
    String? methodKey,
  }) {
    if (methodKey == 'addition:toFullTen' ||
        methodKey == 'numberFriends:decomposition' ||
        taskKey.startsWith('gap:') ||
        taskKey.startsWith('neighbor:') ||
        taskKey.startsWith('minus:') ||
        taskKey.startsWith('double:') ||
        taskKey.startsWith('half:') ||
        taskKey.startsWith('family:') ||
        taskKey.startsWith('sequence:') ||
        taskKey.startsWith('measure:add:') ||
        taskKey.startsWith('measure:subtract:') ||
        (taskKey.startsWith('body:') && !taskKey.startsWith('body:cube-net:')) ||
        taskKey.startsWith('process:strategy:') ||
        taskKey.startsWith('process:error:') ||
        taskKey.startsWith('process:plausibility:') ||
        taskKey.startsWith('process:representation:')) {
      return true;
    }
    return switch (pattern) {
      ErrorPattern.tenBridge ||
      ErrorPattern.carryOmitted ||
      ErrorPattern.borrowAvoided ||
      ErrorPattern.partialOperand ||
      ErrorPattern.multiplicationFact ||
      ErrorPattern.multiplicationAsAddition ||
      ErrorPattern.placeValue ||
      ErrorPattern.writtenRegrouping ||
      ErrorPattern.writtenProcedure ||
      ErrorPattern.unitConversion ||
      ErrorPattern.fractionPart ||
      ErrorPattern.timeDuration ||
      ErrorPattern.perimeterArea ||
      ErrorPattern.operationChoice ||
      ErrorPattern.divisionAsSubtraction ||
      ErrorPattern.wordProblem ||
      ErrorPattern.wordProblemRelevantInformation ||
      ErrorPattern.wordProblemModel ||
      ErrorPattern.wordProblemInterpretation ||
      ErrorPattern.representationTranslation => true,
      _ => false,
    };
  }

  @override
  Widget build(BuildContext context) {
    final processChild = methodKey == 'numberFriends:decomposition'
        ? _numberFriendAid()
        : methodKey == 'addition:toFullTen'
            ? _additionToFullTenAid()
            : taskKey.startsWith('double:') || taskKey.startsWith('half:')
                ? _doubleHalfAid(context)
                : taskKey.startsWith('family:')
                    ? _inverseFamilyAid()
                    : taskKey.startsWith('sequence:')
                        ? _sequenceAid()
                        : taskKey.startsWith('measure:add:') ||
                                taskKey.startsWith('measure:subtract:')
                            ? _measurementLengthAid(context)
                            : taskKey.startsWith('body:') &&
                                    !taskKey.startsWith('body:cube-net:')
                                ? _geometryBodyAid(context)
                                : taskKey.startsWith('gap:')
            ? _missingNumberAid()
            : taskKey.startsWith('neighbor:')
                ? _neighborAid()
                : taskKey.startsWith('minus:')
                    ? _subtractionProcessAid()
                    : taskKey.startsWith('large:compare:')
                ? _largeNumberCompareAid(context)
                : taskKey.startsWith('process:strategy:')
                    ? _strategyProcessAid()
                    : taskKey.startsWith('process:error:')
                        ? _writtenColumnAid()
                        : taskKey.startsWith('process:plausibility:')
                            ? _plausibilityAid()
                            : taskKey.startsWith('process:representation:')
                                ? _representationAid(context)
                                : null;
    final child = processChild ?? switch (pattern) {
      ErrorPattern.tenBridge ||
      ErrorPattern.carryOmitted ||
      ErrorPattern.borrowAvoided ||
      ErrorPattern.partialOperand => _numberLineAid(context),
      ErrorPattern.multiplicationFact ||
      ErrorPattern.multiplicationAsAddition => _multiplicationAid(),
      ErrorPattern.placeValue => _placeValueAid(context),
      ErrorPattern.writtenRegrouping ||
      ErrorPattern.writtenProcedure => _writtenColumnAid(),
      ErrorPattern.unitConversion => _UnitLadderAid(taskKey: taskKey),
      ErrorPattern.fractionPart => _fractionAid(context),
      ErrorPattern.timeDuration => _TimelineAid(taskKey: taskKey),
      ErrorPattern.perimeterArea => _RectangleAid(taskKey: taskKey),
      ErrorPattern.operationChoice ||
      ErrorPattern.divisionAsSubtraction ||
      ErrorPattern.wordProblem ||
      ErrorPattern.wordProblemRelevantInformation ||
      ErrorPattern.wordProblemModel ||
      ErrorPattern.wordProblemInterpretation => const _OperationAid(),
      ErrorPattern.representationTranslation => _representationAid(context),
      _ => null,
    };

    if (child == null) return const SizedBox.shrink();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _geometryBodyAid(BuildContext context) {
    final parts = taskKey.split(':');
    final body = parts.length >= 3 ? parts[1] : '';
    final property = parts.length >= 3 ? parts[2] : '';
    const supportedBodies = <String>{
      'Würfel',
      'Quader',
      'Kugel',
      'Zylinder',
      'Kegel',
      'Pyramide',
    };
    const supportedProperties = <String>{'Ecken', 'Kanten', 'Flächen'};
    if (!supportedBodies.contains(body) ||
        !supportedProperties.contains(property)) {
      return const _AidLabel(
        title: 'Körper untersuchen',
        text: 'Betrachte den Körper aus mehreren Richtungen und prüfe nur die gesuchte Eigenschaft.',
      );
    }
    return _BodyPropertyAid(body: body, property: property);
  }

  Widget _numberFriendAid() {
    final parts = taskKey.split(':');
    final a = parts.length >= 3 ? int.tryParse(parts[1]) : null;
    final b = parts.length >= 3 ? int.tryParse(parts[2]) : null;
    if (a == null || b == null) {
      return const _AidLabel(
        title: 'Zahlzerlegung',
        text: 'Das Ganze besteht aus zwei Teilen. Ein Teil ist bekannt, der andere fehlt.',
      );
    }
    final whole = a + b;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _AidLabel(
          title: 'Zahlzerlegung',
          text: 'Das Ganze steht oben. Unten liegen die beiden Teile.',
        ),
        const SizedBox(height: 12),
        Center(
          child: Chip(
            key: const ValueKey('help-number-friend-whole'),
            avatar: const Icon(Icons.account_tree_outlined),
            label: Text('Ganzes: $whole'),
          ),
        ),
        const SizedBox(height: 8),
        const Icon(Icons.keyboard_double_arrow_down_rounded),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Chip(label: Text('bekannter Teil: $a')),
            const Chip(
              key: ValueKey('help-number-friend-missing'),
              label: Text('fehlender Teil: ?'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '$a + ? = $whole',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _doubleHalfAid(BuildContext context) {
    final numbers = _numbers(taskKey);
    final value = numbers.isEmpty ? null : numbers.last;
    if (value == null) {
      return const _AidLabel(
        title: 'Gleich große Mengen',
        text: 'Doppelt bedeutet zwei gleiche Mengen. Halbieren bedeutet in zwei gleiche Teile teilen.',
      );
    }
    final isDouble = taskKey.startsWith('double:');
    Widget group(String label) => Container(
          width: 116,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              if (isDouble && value <= 12)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 3,
                  runSpacing: 3,
                  children: List.generate(
                    value,
                    (_) => const Icon(Icons.circle, size: 10),
                  ),
                )
              else
                Text(
                  isDouble ? '$value' : 'gleich groß',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AidLabel(
          title: isDouble ? 'Doppelt = zweimal gleich viel' : 'Hälfte = zwei gleich große Teile',
          text: isDouble
              ? 'Lege dieselbe Menge zweimal nebeneinander.'
              : 'Teile die ganze Menge so, dass beide Teile gleich groß sind.',
        ),
        const SizedBox(height: 12),
        if (!isDouble)
          Text(
            'Ganzes: $value',
            key: const ValueKey('help-half-whole'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        if (!isDouble) const SizedBox(height: 8),
        Wrap(
          key: const ValueKey('help-double-half-groups'),
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [group('Teil 1'), group('Teil 2')],
        ),
      ],
    );
  }

  Widget _inverseFamilyAid() {
    final parts = taskKey.split(':');
    if (parts.length < 4) {
      return const _AidLabel(
        title: 'Vorwärts und rückwärts',
        text: 'Eine Umkehraufgabe macht den Rechenschritt wieder rückgängig.',
      );
    }
    final operation = parts[1];
    final a = int.tryParse(parts[2]);
    final b = int.tryParse(parts[3]);
    if (a == null || b == null) {
      return const _AidLabel(
        title: 'Vorwärts und rückwärts',
        text: 'Eine Umkehraufgabe macht den Rechenschritt wieder rückgängig.',
      );
    }
    final multiply = operation == 'x';
    final result = multiply ? a * b : a + b;
    final forward = multiply ? '×$b' : '+$b';
    final backward = multiply ? '÷$b' : '−$b';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _AidLabel(
          title: 'Umkehraufgabe',
          text: 'Lies zuerst vorwärts. Danach gehst du mit der Gegenrechenart zurück.',
        ),
        const SizedBox(height: 12),
        _ProcessAid(
          title: 'Vorwärts',
          text: 'Der bekannte Rechenschritt führt zum Ergebnis.',
          nodes: [a, result],
          nodeLabels: const ['Start', 'Ergebnis'],
          operations: [forward],
          footer: 'Rückweg: $result → $backward → ?',
        ),
      ],
    );
  }

  Widget _sequenceAid() {
    final parts = taskKey.split(':');
    if (parts.length < 4) {
      return const _AidLabel(
        title: 'Muster sichtbar machen',
        text: 'Zwischen benachbarten Zahlen muss immer derselbe Schritt liegen.',
      );
    }
    final start = int.tryParse(parts[2]);
    final step = int.tryParse(parts[3]);
    if (start == null || step == null) {
      return const _AidLabel(
        title: 'Muster sichtbar machen',
        text: 'Zwischen benachbarten Zahlen muss immer derselbe Schritt liegen.',
      );
    }
    final backwards = parts[1] == '-';
    final second = backwards ? start - step : start + step;
    final third = backwards ? start - 2 * step : start + 2 * step;
    final op = backwards ? '−$step' : '+$step';
    return _ProcessAid(
      title: 'Gleicher Schritt',
      text: 'Markiere dieselbe Veränderung zwischen allen sichtbaren Zahlen.',
      nodes: [start, second, third],
      nodeLabels: const ['1.', '2.', '3.'],
      operations: [op, op],
      footer: '$third → $op → ?',
    );
  }

  Widget _measurementLengthAid(BuildContext context) {
    final parts = taskKey.split(':');
    if (parts.length < 5) {
      return const _AidLabel(
        title: 'Längen darstellen',
        text: 'Lege Längen aneinander oder markiere den abgeschnittenen Teil.',
      );
    }
    final first = int.tryParse(parts[3]);
    final second = int.tryParse(parts[4]);
    if (first == null || second == null) {
      return const _AidLabel(
        title: 'Längen darstellen',
        text: 'Lege Längen aneinander oder markiere den abgeschnittenen Teil.',
      );
    }
    final subtraction = taskKey.startsWith('measure:subtract:');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AidLabel(
          title: subtraction ? 'Abschneiden sichtbar machen' : 'Längen aneinanderlegen',
          text: subtraction
              ? 'Die ganze Länge bleibt sichtbar. Der abgeschnittene Abschnitt gehört nicht mehr zum Rest.'
              : 'Beide Stücke haben dieselbe Einheit und werden ohne Lücke aneinandergelegt.',
        ),
        const SizedBox(height: 12),
        if (subtraction) ...[
          Container(
            key: const ValueKey('help-measure-whole'),
            height: 26,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text('ganz: $first cm'),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              const Chip(label: Text('Rest: ? cm')),
              Chip(label: Text('abgeschnitten: $second cm')),
            ],
          ),
        ] else ...[
          Wrap(
            key: const ValueKey('help-measure-parts'),
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 8,
            children: [
              Chip(label: Text('$first cm')),
              const Text('+', style: TextStyle(fontWeight: FontWeight.w800)),
              Chip(label: Text('$second cm')),
              const Text('→'),
              const Chip(label: Text('zusammen: ? cm')),
            ],
          ),
        ],
      ],
    );
  }

  Widget _additionToFullTenAid() {
    final numbers = _numbers(taskKey);
    if (numbers.length < 2) {
      return const _AidLabel(
        title: 'Rechenweg',
        text: 'Die Aufgabe endet genau auf einem vollen Zehner.',
      );
    }
    final a = numbers[numbers.length - 2];
    final b = numbers.last;
    return _ProcessAid(
      title: 'Rechenweg',
      text: 'Lies von links nach rechts: Startzahl und voller Zehner.',
      nodes: [a, expected],
      nodeLabels: const ['Start', 'voller Zehner'],
      operations: ['+$b'],
      footer: '$a + $b = $expected',
    );
  }

  Widget _subtractionProcessAid() {
    final numbers = _numbers(taskKey);
    if (numbers.length < 2) {
      return const _AidLabel(
        title: 'Rechenweg',
        text: 'Lies den Minus-Rechenweg von links nach rechts.',
      );
    }
    final a = numbers[numbers.length - 2];
    final b = numbers.last;
    final result = expected;

    if (methodKey?.endsWith('complement') ?? false) {
      final nextTen = ((b ~/ 10) + 1) * 10;
      if (nextTen > b && nextTen < a) {
        return _ProcessAid(
          title: 'Ergänzweg',
          text:
              'Beim Ergänzen startest du bei der kleineren Zahl und gehst in Rechenschritten bis zur größeren Zahl.',
          nodes: [b, nextTen, a],
          nodeLabels: const ['Start', 'voller Zehner', 'Ziel'],
          operations: ['+${nextTen - b}', '+${a - nextTen}'],
          footer: 'Die Sprünge zusammen ergeben den Unterschied $result.',
        );
      }
      return _ProcessAid(
        title: 'Ergänzweg',
        text:
            'Beim Ergänzen startest du bei der kleineren Zahl und gehst bis zur größeren Zahl.',
        nodes: [b, a],
        nodeLabels: const ['Start', 'Ziel'],
        operations: ['+$result'],
        footer: 'Die Ergänzung ist der Unterschied $result.',
      );
    }

    if (methodKey?.endsWith('takeAway') ?? false) {
      final first = math.min(b, math.max(1, b ~/ 2));
      final second = b - first;
      final middle = a - first;
      if (second > 0) {
        return _ProcessAid(
          title: 'Rechenweg',
          text:
              'Lies die Rechenschritte von links nach rechts: Start, Zwischenergebnis, Ergebnis.',
          nodes: [a, middle, result],
          nodeLabels: const ['Start', 'Zwischenschritt', 'Ergebnis'],
          operations: ['−$first', '−$second'],
          footer: '$a − $b = $result',
        );
      }
    }

    final toTen = a % 10;
    final crossesTen = toTen > 0 && b > toTen;
    if (crossesTen) {
      final bridge = a - toTen;
      final rest = b - toTen;
      return _ProcessAid(
        title: 'Rechenweg',
        text:
            'Lies von links nach rechts: Startzahl, voller Zehner, Ergebnis.',
        nodes: [a, bridge, result],
        nodeLabels: const ['Start', 'voller Zehner', 'Ergebnis'],
        operations: ['−$toTen', '−$rest'],
        footer: '$a − $b: zuerst bis $bridge, dann weiter bis $result.',
      );
    }

    return _ProcessAid(
      title: 'Rechenweg',
      text: a % 10 == 0
          ? '$a ist schon ein voller Zehner. Ein zusätzlicher Zwischenstopp ist nicht nötig.'
          : 'Diese Aufgabe braucht keinen Zehner-Zwischenstopp.',
      nodes: [a, result],
      nodeLabels: const ['Start', 'Ergebnis'],
      operations: ['−$b'],
      footer: '$a − $b = $result',
    );
  }

  Widget _missingNumberAid() {
    final parts = taskKey.split(':');
    if (parts.length < 5) {
      return const _AidLabel(
        title: 'Lückenweg',
        text: 'Gehe von einer bekannten Zahl zur anderen und bestimme den fehlenden Abstand.',
      );
    }
    final operation = parts[1];
    final a = int.tryParse(parts[2]);
    final b = int.tryParse(parts[3]);
    final hidden = parts[4];
    if (a == null || b == null) {
      return const _AidLabel(
        title: 'Lückenweg',
        text: 'Nutze die Umkehraufgabe, um die fehlende Zahl zu finden.',
      );
    }

    int start;
    int end;
    String footer;
    if (operation == '+') {
      final total = a + b;
      start = hidden == 'b' ? a : b;
      end = total;
      footer = '$end − $start = $expected';
    } else if (hidden == 'b') {
      start = a - b;
      end = a;
      footer = '$a − $expected = $start';
    } else {
      start = a - b;
      end = expected;
      footer = '$start + $b = $expected';
    }

    final jump = end - start;
    final nextTen = ((start ~/ 10) + 1) * 10;
    if (nextTen > start && nextTen < end) {
      return _ProcessAid(
        title: 'Lückenweg',
        text: 'Ergänze von links nach rechts. Ein voller Zehner kann als Zwischenstopp helfen.',
        nodes: [start, nextTen, end],
        nodeLabels: const ['Start', 'voller Zehner', 'Ziel'],
        operations: ['+${nextTen - start}', '+${end - nextTen}'],
        footer: '$footer. Die beiden Sprünge zusammen sind $jump.',
      );
    }

    return _ProcessAid(
      title: 'Lückenweg',
      text: 'Ergänze von der bekannten Zahl bis zum Ziel.',
      nodes: [start, end],
      nodeLabels: const ['Start', 'Ziel'],
      operations: ['+${end - start}'],
      footer: footer,
    );
  }

  Widget _neighborAid() {
    final parts = taskKey.split(':');
    final number = parts.length >= 2 ? int.tryParse(parts[1]) : null;
    final before = parts.length >= 3 && parts[2] == 'before';
    if (number == null) {
      return const _AidLabel(
        title: 'Ein Schritt auf dem Zahlenstrahl',
        text: 'Vorgänger: einen Schritt nach links. Nachfolger: einen Schritt nach rechts.',
      );
    }
    return _ProcessAid(
      title: 'Ein Schritt auf dem Zahlenstrahl',
      text: before
          ? 'Für den Vorgänger gehst du genau einen Schritt zurück.'
          : 'Für den Nachfolger gehst du genau einen Schritt weiter.',
      nodes: [number, expected],
      nodeLabels: const ['Ausgangszahl', 'Nachbarzahl'],
      operations: [before ? '−1' : '+1'],
      footer: before
          ? '$number − 1 = $expected'
          : '$number + 1 = $expected',
    );
  }

  Widget _largeNumberCompareAid(BuildContext context) {
    final numbers = _numbers(taskKey);
    if (numbers.length < 2) return _placeValueAid(context);
    final a = numbers[numbers.length - 2];
    final b = numbers.last;
    final place = _firstDifferentPlace(a, b);
    final aDigit = (a ~/ place) % 10;
    final bDigit = (b ~/ place) % 10;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AidLabel(
          title: 'Stellenwerte vergleichen',
          text:
              'Vergleiche beide Zahlen von links nach rechts. Die erste unterschiedliche Stelle entscheidet.',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _NumberCompareCard(
                value: _formatNumber(a),
                digit: aDigit,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('↔', style: TextStyle(fontSize: 22)),
            ),
            Expanded(
              child: _NumberCompareCard(
                value: _formatNumber(b),
                digit: bDigit,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '${_largePlaceLabel(place)}: $aDigit und $bDigit',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  int _firstDifferentPlace(int a, int b) {
    var place = 1;
    var largest = math.max(a, b);
    while (largest >= 10) {
      place *= 10;
      largest ~/= 10;
    }
    while (place > 1 && (a ~/ place) % 10 == (b ~/ place) % 10) {
      place ~/= 10;
    }
    return place;
  }

  String _largePlaceLabel(int place) => switch (place) {
        1000000 => 'Millionenstelle',
        100000 => 'Hunderttausenderstelle',
        10000 => 'Zehntausenderstelle',
        1000 => 'Tausenderstelle',
        100 => 'Hunderterstelle',
        10 => 'Zehnerstelle',
        _ => 'Einerstelle',
      };

  String _formatNumber(int value) {
    final raw = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buffer.write('.');
      buffer.write(raw[i]);
    }
    return buffer.toString();
  }
  Widget _numberLineAid(BuildContext context) {
    final numbers = _numbers(taskKey);
    if (numbers.length < 2) {
      return const _AidLabel(
        title: 'Zahlenstrahl',
        text: 'Gehe in passenden Schritten über einen glatten Zehner.',
      );
    }
    final a = numbers[numbers.length - 2];
    final b = numbers.last;
    final minus = taskKey.contains(':-:') || taskKey.startsWith('minus:');
    if (minus) {
      final toTen = a % 10;
      final crossesTen = toTen > 0 && b > toTen;
      if (crossesTen) {
        final bridge = a - toTen;
        final rest = b - toTen;
        return _ProcessAid(
          title: 'Rechenweg',
          text:
              'Lies von links nach rechts: Startzahl, voller Zehner, Ergebnis.',
          nodes: [a, bridge, expected],
          nodeLabels: const ['Start', 'voller Zehner', 'Ergebnis'],
          operations: ['−$toTen', '−$rest'],
          footer: '$a − $b = $expected',
        );
      }
      return _ProcessAid(
        title: 'Rechenweg',
        text: 'Lies den Minus-Rechenweg von links nach rechts.',
        nodes: [a, expected],
        nodeLabels: const ['Start', 'Ergebnis'],
        operations: ['−$b'],
        footer: '$a − $b = $expected',
      );
    }
    final bridge = ((a ~/ 10) + 1) * 10;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AidLabel(
          title: 'Zahlenstrahl',
          text: 'Der glatte Zehner ist der Zwischenstopp.',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          width: double.infinity,
          child: CustomPaint(
            painter: _NumberLinePainter(
              start: a,
              bridge: bridge,
              end: expected,
              lineColor: Theme.of(context).colorScheme.outline,
              accentColor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        Text(
          minus
              ? '$a − $b: zuerst bis $bridge, dann weiter bis $expected.'
              : '$a + $b: zuerst bis $bridge, dann weiter bis $expected.',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _representationAid(BuildContext context) {
    if (taskKey.contains(':groups:') ||
        taskKey.contains(':equation:')) {
      return _multiplicationAid();
    }
    return _placeValueAid(context);
  }

  Widget _multiplicationAid() {
    final numbers = _numbers(taskKey);
    if (numbers.length < 2) {
      return const _AidLabel(
        title: 'Punktefeld',
        text: 'Malaufgaben sind gleich große Gruppen.',
      );
    }
    final rows = numbers[numbers.length - 2].clamp(1, 10).toInt();
    final columns = numbers.last.clamp(1, 10).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AidLabel(
          title: 'Punktefeld',
          text: '$rows Reihen mit je $columns Punkten.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: List.generate(
            rows * columns,
            (_) => const Icon(Icons.circle, size: 13),
          ),
        ),
      ],
    );
  }

  Widget _placeValueAid(BuildContext context) {
    final numbers = _numbers(taskKey);
    final value = numbers.isEmpty
        ? expected
        : numbers.reduce((a, b) => a > b ? a : b);
    final places = <(String, int)>[
      ('M', (value ~/ 1000000) % 10),
      ('HT', (value ~/ 100000) % 10),
      ('ZT', (value ~/ 10000) % 10),
      ('T', (value ~/ 1000) % 10),
      ('H', (value ~/ 100) % 10),
      ('Z', (value ~/ 10) % 10),
      ('E', value % 10),
    ];
    final visible = places.skipWhile((entry) => entry.$2 == 0).toList();
    final cells = visible.isEmpty ? [places.last] : visible;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AidLabel(
          title: 'Stellenwerttafel',
          text: 'Jede Ziffer hat ihren festen Platz.',
        ),
        const SizedBox(height: 12),
        Row(
          children: cells
              .map(
                (entry) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          entry.$1,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${entry.$2}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _fractionAid(BuildContext context) {
    final numbers = _numbers(taskKey);
    var denominator = 4;
    var numerator = 1;
    if (taskKey.contains('half')) {
      denominator = 2;
      numerator = 1;
    } else if (taskKey.contains('quarter')) {
      denominator = 4;
      numerator = 1;
    } else if (taskKey == 'fraction:time') {
      denominator = 4;
      numerator = 3;
    } else if (taskKey == 'fraction:volume') {
      denominator = 4;
      numerator = 1;
    } else if (numbers.length >= 2 &&
        numbers.first > 0 &&
        numbers[1] > numbers.first) {
      numerator = numbers.first;
      denominator = numbers[1];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AidLabel(
          title: 'Bruchbild',
          text: '$numerator von $denominator gleich großen Teilen sind markiert.',
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(
            denominator,
            (index) => Expanded(
              child: Container(
                height: 46,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: index < numerator
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _writtenColumnAid() {
    final numbers = _numbers(taskKey);
    if (numbers.length < 2) {
      return const _AidLabel(
        title: 'Stellenweise rechnen',
        text: 'Einer unter Einer, Zehner unter Zehner und Hunderter unter Hunderter.',
      );
    }

    final processError = taskKey.startsWith('process:error:add:') &&
        numbers.length >= 3;
    final a = processError
        ? numbers[numbers.length - 3]
        : numbers[numbers.length - 2];
    final b = processError
        ? numbers[numbers.length - 2]
        : numbers.last;
    final shownResult = processError ? numbers.last : expected;
    final minus = taskKey.contains('written:-:');
    final symbol = minus ? '−' : '+';
    final width = math.max(
      math.max(a.toString().length, b.toString().length),
      shownResult.toString().length,
    );
    String padded(int value) => value.toString().padLeft(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AidLabel(
          title: processError
              ? 'Vorgegebene Rechnung prüfen'
              : 'Schriftlich untereinander',
          text: processError
              ? 'Prüfe die Stellen nacheinander. Du musst nicht sofort alles neu rechnen.'
              : 'Die gleichen Stellenwerte stehen genau untereinander.',
        ),
        const SizedBox(height: 12),
        Center(
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '  ${padded(a)}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '$symbol ${padded(b)}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Divider(thickness: 2),
                Text(
                  '  ${padded(shownResult)}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _strategyProcessAid() {
    final numbers = _numbers(taskKey);
    if (numbers.length < 3) return const SizedBox.shrink();
    final a = numbers[numbers.length - 3];
    final b = numbers[numbers.length - 2];
    final anchor = numbers.last;
    final first = anchor - a;
    final rest = b - first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AidLabel(
          title: 'Rechenvorteil sichtbar machen',
          text: 'Zuerst zur runden Zielzahl, danach nur noch den Rest.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(label: Text('$a')),
            const Icon(Icons.add_rounded, size: 18),
            Chip(label: Text('$first')),
            const Icon(Icons.arrow_forward_rounded, size: 18),
            Chip(label: Text('$anchor')),
            if (rest > 0) ...[
              const Icon(Icons.add_rounded, size: 18),
              Chip(label: Text('$rest')),
            ],
          ],
        ),
      ],
    );
  }

  Widget _plausibilityAid() {
    final numbers = _numbers(taskKey);
    if (numbers.length < 4) return const SizedBox.shrink();
    final a = numbers[numbers.length - 4];
    final b = numbers[numbers.length - 3];
    final candidate = numbers[numbers.length - 2];
    final place = numbers.last;
    final roundedA = ((a + place ~/ 2) ~/ place) * place;
    final roundedB = ((b + place ~/ 2) ~/ place) * place;
    final estimate = roundedA + roundedB;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AidLabel(
          title: 'Überschlag',
          text: 'Vergleiche nur die Größenordnung – nicht jeden einzelnen Rechenschritt.',
        ),
        const SizedBox(height: 12),
        Text(
          '$a ≈ $roundedA   und   $b ≈ $roundedB',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Überschlag: $roundedA + $roundedB ≈ $estimate',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Vorgeschlagenes Ergebnis: $candidate',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  List<int> _numbers(String value) => RegExp(r'\d+')
      .allMatches(value)
      .map((match) => int.parse(match.group(0)!))
      .toList();
}

class _ProcessAid extends StatelessWidget {
  const _ProcessAid({
    required this.title,
    required this.text,
    required this.nodes,
    required this.nodeLabels,
    required this.operations,
    required this.footer,
  });

  final String title;
  final String text;
  final List<int> nodes;
  final List<String> nodeLabels;
  final List<String> operations;
  final String footer;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AidLabel(title: title, text: text),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < nodes.length; i++) ...[
                  _ProcessNode(
                    value: nodes[i],
                    label: nodeLabels[i],
                  ),
                  if (i < operations.length)
                    SizedBox(
                      width: 92,
                      child: Column(
                        children: [
                          Text(
                            operations[i],
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            footer,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      );
}

class _ProcessNode extends StatelessWidget {
  const _ProcessNode({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 78),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
}

class _NumberCompareCard extends StatelessWidget {
  const _NumberCompareCard({required this.value, required this.digit});

  final String value;
  final int digit;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'entscheidende Ziffer: $digit',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
}
class _AidLabel extends StatelessWidget {
  const _AidLabel({
    required this.title,
    required this.text,
  });

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(text),
        ],
      );
}

class _UnitLadderAid extends StatelessWidget {
  const _UnitLadderAid({required this.taskKey});

  final String taskKey;

  @override
  Widget build(BuildContext context) {
    final tokens = taskKey.split(RegExp(r'[:\\-]'));
    final secondsTask = taskKey.startsWith('time:seconds:');
    final units = taskKey.startsWith('mass:')
        ? const ['t', 'kg', 'g']
        : taskKey.startsWith('volume:')
            ? const ['l', 'ml']
            : secondsTask
                ? (taskKey.contains(':sec-to-min:')
                    ? const ['s', 'min']
                    : const ['min', 's'])
                : taskKey.startsWith('time:')
                    ? const ['h', 'min']
                    : taskKey.startsWith('money:')
                        ? const ['€', 'ct']
                        : const ['km', 'm', 'dm', 'cm', 'mm'];

    String? startUnit;
    String? targetUnit;
    for (final raw in tokens) {
      final normalized = raw == 'euro'
          ? '€'
          : raw == 'sec'
              ? 's'
              : raw;
      if (units.contains(normalized)) {
        startUnit ??= normalized;
        if (normalized != startUnit) targetUnit ??= normalized;
      }
    }
    if (secondsTask && taskKey.contains(':min-to-sec:')) {
      startUnit = 'min';
      targetUnit = 's';
    } else if (secondsTask && taskKey.contains(':sec-to-min:')) {
      startUnit = 's';
      targetUnit = 'min';
    }
    if (taskKey.startsWith('money:euro')) targetUnit ??= 'ct';
    if (!secondsTask && taskKey.startsWith('time:min')) targetUnit ??= 'h';
    if (taskKey.startsWith('volume:l')) targetUnit ??= 'ml';
    if (taskKey.startsWith('mass:kg')) targetUnit ??= 'g';
    if (taskKey.startsWith('mass:t-kg')) targetUnit ??= 'kg';
    if (taskKey.startsWith('length:m:')) targetUnit ??= 'cm';
    if (taskKey.startsWith('length:km:')) targetUnit ??= 'm';
    if (taskKey.startsWith('length:cm-mm:')) targetUnit ??= 'mm';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AidLabel(
          title: secondsTask ? 'Minuten und Sekunden' : 'Einheitenleiter',
          text: startUnit == null || targetUnit == null
              ? 'Markiere Start- und Zieleinheit und gehe Schritt für Schritt.'
              : 'Gehe von $startUnit zu $targetUnit. Jeder Schritt verändert den Zahlenwert passend zur Einheit.',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < units.length; i++) ...[
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: units[i] == startUnit || units[i] == targetUnit
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      width: units[i] == startUnit || units[i] == targetUnit
                          ? 2
                          : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    units[i],
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              if (i < units.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3),
                  child: Icon(Icons.arrow_forward_rounded, size: 17),
                ),
            ],
          ],
        ),
        if (secondsTask) ...[
          const SizedBox(height: 10),
          const Text(
            '1 min = 60 s',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ],
    );
  }
}

class _TimelineAid extends StatelessWidget {
  const _TimelineAid({required this.taskKey});

  final String taskKey;

  String _clock(int minutes) {
    final normalized = minutes % (24 * 60);
    final hour = normalized ~/ 60;
    final minute = normalized % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final numbers = RegExp(r'\d+')
        .allMatches(taskKey)
        .map((match) => int.parse(match.group(0)!))
        .toList();

    if (!taskKey.startsWith('duration:') ||
        taskKey.startsWith('duration:weeks:') ||
        taskKey.startsWith('duration:days:') ||
        numbers.length < 2) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AidLabel(
            title: 'Zeitlinie',
            text: 'Gehe in gut erreichbaren Etappen und addiere die Zeitstücke.',
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.schedule_rounded),
              Expanded(child: Divider(thickness: 3)),
              CircleAvatar(radius: 6),
              Expanded(child: Divider(thickness: 3)),
              Icon(Icons.flag_outlined),
            ],
          ),
        ],
      );
    }

    final start = numbers[0];
    final duration = numbers[1];
    final end = start + duration;
    final nextFullHour = ((start ~/ 60) + 1) * 60;
    final bridge = nextFullHour < end ? nextFullHour : end;
    final firstPart = bridge - start;
    final secondPart = end - bridge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AidLabel(
          title: 'Zeitlinie',
          text: 'Teile die Zeitspanne an einer gut erreichbaren Uhrzeit.',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TimePoint(
                label: 'Start',
                value: _clock(start),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  const Divider(thickness: 3),
                  Text('+$firstPart min'),
                ],
              ),
            ),
            Expanded(
              child: _TimePoint(
                label: bridge == end ? 'Ende' : 'volle Stunde',
                value: _clock(bridge),
              ),
            ),
            if (secondPart > 0) ...[
              Expanded(
                child: Column(
                  children: [
                    const Divider(thickness: 3),
                    Text('+$secondPart min'),
                  ],
                ),
              ),
              Expanded(
                child: _TimePoint(
                  label: 'Ende',
                  value: _clock(end),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _TimePoint extends StatelessWidget {
  const _TimePoint({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const Icon(Icons.circle, size: 14),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
}

class _RectangleAid extends StatelessWidget {
  const _RectangleAid({required this.taskKey});

  final String taskKey;

  @override
  Widget build(BuildContext context) {
    final parts = taskKey.split(':');
    final area = parts.length > 1 && parts[1] == 'area';
    final width =
        parts.length > 4 ? int.tryParse(parts[parts.length - 2]) : null;
    final height =
        parts.length > 4 ? int.tryParse(parts[parts.length - 1]) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AidLabel(
          title: area ? 'Fläche = Inneres' : 'Umfang = Rand',
          text: area
              ? 'Die Fläche zählt, wie groß das Innere des Rechtecks ist.'
              : 'Der Umfang zählt die Länge aller vier Randseiten.',
        ),
        const SizedBox(height: 12),
        Center(
          child: Column(
            children: [
              if (width != null) Text('$width cm'),
              Container(
                width: 180,
                height: 100,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: area
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: area ? 2 : 5,
                  ),
                ),
                child: Text(
                  area ? 'Länge × Breite' : 'alle Seiten zusammen',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (height != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Breite: $height cm'),
                ),
            ],
          ),
        ),
        if (width != null && height != null) ...[
          const SizedBox(height: 10),
          Text(
            area
                ? '$width × $height = ${width * height} cm²'
                : '2 × ($width + $height) = ${2 * (width + height)} cm',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ],
    );
  }
}

class _OperationAid extends StatelessWidget {
  const _OperationAid();

  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AidLabel(
            title: 'Was passiert in der Geschichte?',
            text: 'Entscheide zuerst über die Handlung – erst danach über das Rechenzeichen.',
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('dazu / mehr → +')),
              Chip(label: Text('weg / weniger → −')),
              Chip(label: Text('gleich große Gruppen → ×')),
              Chip(label: Text('gleichmäßig verteilen → ÷')),
            ],
          ),
        ],
      );
}

class _NumberLinePainter extends CustomPainter {
  const _NumberLinePainter({
    required this.start,
    required this.bridge,
    required this.end,
    required this.lineColor,
    required this.accentColor,
  });

  final int start;
  final int bridge;
  final int end;
  final Color lineColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final accent = Paint()
      ..color = accentColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final y = size.height * 0.60;
    final left = 24.0;
    final right = size.width - 24.0;
    canvas.drawLine(Offset(left, y), Offset(right, y), paint);

    final values = [start, bridge, end];
    final minValue = values.reduce((a, b) => math.min(a, b));
    final maxValue = values.reduce((a, b) => math.max(a, b));
    final span = math.max(1, maxValue - minValue);

    double xFor(int value) =>
        left + (value - minValue) / span * (right - left);

    for (final value in values.toSet()) {
      final x = xFor(value);
      canvas.drawLine(Offset(x, y - 8), Offset(x, y + 8), paint);
      final label = TextPainter(
        text: TextSpan(
          text: '$value',
          style: TextStyle(
            color: accentColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(x - label.width / 2, y + 12));
    }

    final startX = xFor(start);
    final bridgeX = xFor(bridge);
    final endX = xFor(end);
    final firstPath = Path()
      ..moveTo(startX, y - 8)
      ..quadraticBezierTo(
        (startX + bridgeX) / 2,
        y - 48,
        bridgeX,
        y - 8,
      );
    final secondPath = Path()
      ..moveTo(bridgeX, y - 8)
      ..quadraticBezierTo(
        (bridgeX + endX) / 2,
        y - 40,
        endX,
        y - 8,
      );
    canvas.drawPath(firstPath, accent);
    canvas.drawPath(secondPath, accent);
  }

  @override
  bool shouldRepaint(covariant _NumberLinePainter oldDelegate) =>
      start != oldDelegate.start ||
      bridge != oldDelegate.bridge ||
      end != oldDelegate.end ||
      lineColor != oldDelegate.lineColor ||
      accentColor != oldDelegate.accentColor;
}

class _BodyPropertyAid extends StatelessWidget {
  const _BodyPropertyAid({required this.body, required this.property});

  final String body;
  final String property;

  @override
  Widget build(BuildContext context) {
    final explanation = switch (property) {
      'Ecken' =>
        'Suche nur echte Treffpunkte von Kanten. Drehe den Körper gedanklich, damit keine hintere Ecke verloren geht.',
      'Kanten' =>
        'Verfolge jede Kante genau einmal. Dünnere Linien gehören zur Rückseite des Körpers.',
      _ =>
        'Lege die Flächen gedanklich auseinander. Auch gekrümmte Oberflächen zählen als Flächen.',
    };
    final secondLabel = property == 'Flächen'
        ? 'Flächen auseinandergelegt'
        : 'Zweite Ansicht';
    return Column(
      key: ValueKey('body-aid:$body:$property'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AidLabel(
          title: '$body · $property untersuchen',
          text: explanation,
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            _BodyDiagramCard(
              label: 'Körperansicht',
              body: body,
              property: property,
            ),
            _BodyDiagramCard(
              label: secondLabel,
              body: body,
              property: property,
              alternate: true,
              surfaces: property == 'Flächen',
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          property == 'Flächen'
              ? 'Zähle jetzt jede getrennte Fläche genau einmal.'
              : 'Vergleiche beide Ansichten und zähle jedes Merkmal nur einmal.',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _BodyDiagramCard extends StatelessWidget {
  const _BodyDiagramCard({
    required this.label,
    required this.body,
    required this.property,
    this.alternate = false,
    this.surfaces = false,
  });

  final String label;
  final String body;
  final String property;
  final bool alternate;
  final bool surfaces;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$label für $body, gesucht: $property',
        child: Container(
          width: 170,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 148,
                height: 124,
                child: CustomPaint(
                  painter: surfaces
                      ? _BodySurfacePainter(
                          body: body,
                          lineColor: Theme.of(context).colorScheme.onSurface,
                          accentColor: Theme.of(context).colorScheme.primary,
                        )
                      : _BodyDiagramPainter(
                          body: body,
                          property: property,
                          alternate: alternate,
                          lineColor: Theme.of(context).colorScheme.onSurface,
                          accentColor: Theme.of(context).colorScheme.primary,
                        ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _BodyDiagramPainter extends CustomPainter {
  const _BodyDiagramPainter({
    required this.body,
    required this.property,
    required this.alternate,
    required this.lineColor,
    required this.accentColor,
  });

  final String body;
  final String property;
  final bool alternate;
  final Color lineColor;
  final Color accentColor;

  Paint get _line => Paint()
    ..color = lineColor
    ..strokeWidth = 2.6
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  Paint get _rear => Paint()
    ..color = lineColor.withValues(alpha: 0.38)
    ..strokeWidth = 1.8
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  Paint get _accent => Paint()
    ..color = accentColor
    ..strokeWidth = 4
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  Paint get _fill => Paint()
    ..color = accentColor.withValues(alpha: 0.16)
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    switch (body) {
      case 'Würfel':
        _box(canvas, size, square: true);
      case 'Quader':
        _box(canvas, size, square: false);
      case 'Pyramide':
        _pyramid(canvas, size);
      case 'Zylinder':
        _cylinder(canvas, size);
      case 'Kegel':
        _cone(canvas, size);
      case 'Kugel':
        _sphere(canvas, size);
    }
  }

  void _box(Canvas canvas, Size size, {required bool square}) {
    final w = square ? size.width * .48 : size.width * .56;
    final h = square ? size.height * .52 : size.height * .42;
    final dx = (alternate ? -.13 : .14) * size.width;
    final dy = -.16 * size.height;
    final front = Rect.fromCenter(
      center: Offset(size.width * .50, size.height * .58),
      width: w,
      height: h,
    );
    final back = front.shift(Offset(dx, dy));
    final f = <Offset>[front.topLeft, front.topRight, front.bottomRight, front.bottomLeft];
    final b = <Offset>[back.topLeft, back.topRight, back.bottomRight, back.bottomLeft];
    if (property == 'Flächen') {
      canvas.drawRect(front, _fill);
      final top = Path()
        ..moveTo(f[0].dx, f[0].dy)
        ..lineTo(f[1].dx, f[1].dy)
        ..lineTo(b[1].dx, b[1].dy)
        ..lineTo(b[0].dx, b[0].dy)
        ..close();
      canvas.drawPath(top, _fill);
    }
    canvas.drawRect(back, _rear);
    canvas.drawRect(front, property == 'Kanten' ? _accent : _line);
    for (var i = 0; i < 4; i++) {
      canvas.drawLine(f[i], b[i], property == 'Kanten' ? _accent : _line);
    }
    if (property == 'Kanten') {
      for (var i = 0; i < 4; i++) {
        canvas.drawLine(b[i], b[(i + 1) % 4], _accent);
      }
    }
    if (property == 'Ecken') {
      for (final point in [...f, ...b]) {
        canvas.drawCircle(point, 4.5, Paint()..color = accentColor);
      }
    }
  }

  void _pyramid(Canvas canvas, Size size) {
    final apex = Offset(size.width * (alternate ? .62 : .48), size.height * .12);
    final base = <Offset>[
      Offset(size.width * .18, size.height * .68),
      Offset(size.width * .72, size.height * .68),
      Offset(size.width * .86, size.height * .86),
      Offset(size.width * .32, size.height * .86),
    ];
    final edgePaint = property == 'Kanten' ? _accent : _line;
    for (var i = 0; i < 4; i++) {
      canvas.drawLine(base[i], base[(i + 1) % 4], i == 2 ? _rear : edgePaint);
      canvas.drawLine(apex, base[i], i == 2 ? _rear : edgePaint);
    }
    if (property == 'Ecken') {
      for (final point in [apex, ...base]) {
        canvas.drawCircle(point, 4.5, Paint()..color = accentColor);
      }
    }
  }

  void _cylinder(Canvas canvas, Size size) {
    final top = Rect.fromLTWH(size.width * .20, size.height * .14, size.width * .60, size.height * .25);
    final bottom = top.shift(Offset(0, size.height * .48));
    if (property == 'Flächen') {
      canvas.drawRect(
        Rect.fromLTRB(top.left, top.center.dy, top.right, bottom.center.dy),
        _fill,
      );
    }
    canvas.drawOval(top, property == 'Kanten' ? _accent : _line);
    canvas.drawOval(bottom, property == 'Kanten' ? _accent : _line);
    canvas.drawLine(Offset(top.left, top.center.dy), Offset(bottom.left, bottom.center.dy), _line);
    canvas.drawLine(Offset(top.right, top.center.dy), Offset(bottom.right, bottom.center.dy), _line);
  }

  void _cone(Canvas canvas, Size size) {
    final apex = Offset(size.width * (alternate ? .58 : .50), size.height * .12);
    final base = Rect.fromLTWH(size.width * .18, size.height * .66, size.width * .64, size.height * .24);
    canvas.drawLine(apex, Offset(base.left, base.center.dy), _line);
    canvas.drawLine(apex, Offset(base.right, base.center.dy), _line);
    canvas.drawOval(base, property == 'Kanten' ? _accent : _line);
    if (property == 'Ecken') {
      canvas.drawCircle(apex, 5, Paint()..color = accentColor);
    }
  }

  void _sphere(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * .37;
    if (property == 'Flächen') canvas.drawCircle(center, radius, _fill);
    canvas.drawCircle(center, radius, _line);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radius * 2, height: radius * .62),
      _rear,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radius * .62, height: radius * 2),
      _rear,
    );
  }

  @override
  bool shouldRepaint(covariant _BodyDiagramPainter oldDelegate) =>
      body != oldDelegate.body ||
      property != oldDelegate.property ||
      alternate != oldDelegate.alternate ||
      lineColor != oldDelegate.lineColor ||
      accentColor != oldDelegate.accentColor;
}

class _BodySurfacePainter extends CustomPainter {
  const _BodySurfacePainter({
    required this.body,
    required this.lineColor,
    required this.accentColor,
  });

  final String body;
  final Color lineColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..color = accentColor.withValues(alpha: .14)
      ..style = PaintingStyle.fill;
    switch (body) {
      case 'Würfel':
      case 'Quader':
        _boxNet(canvas, size, line, fill, body == 'Quader');
      case 'Pyramide':
        _pyramidNet(canvas, size, line, fill);
      case 'Zylinder':
        _cylinderNet(canvas, size, line, fill);
      case 'Kegel':
        _coneNet(canvas, size, line, fill);
      case 'Kugel':
        _sphereSurface(canvas, size, line, fill);
    }
  }

  void _boxNet(Canvas canvas, Size size, Paint line, Paint fill, bool rectangle) {
    final cellW = rectangle ? 29.0 : 27.0;
    final cellH = rectangle ? 22.0 : 27.0;
    final origin = Offset(size.width / 2 - cellW * 1.5, size.height / 2 - cellH / 2);
    final cells = <Offset>[
      origin,
      origin.translate(cellW, 0),
      origin.translate(cellW * 2, 0),
      origin.translate(cellW * 3, 0),
      origin.translate(cellW, -cellH),
      origin.translate(cellW, cellH),
    ];
    for (final o in cells) {
      final r = Rect.fromLTWH(o.dx, o.dy, cellW, cellH);
      canvas.drawRect(r, fill);
      canvas.drawRect(r, line);
    }
  }

  void _pyramidNet(Canvas canvas, Size size, Paint line, Paint fill) {
    final c = Offset(size.width / 2, size.height / 2);
    final half = 24.0;
    final square = Rect.fromCenter(center: c, width: half * 2, height: half * 2);
    canvas.drawRect(square, fill);
    canvas.drawRect(square, line);
    final triangles = <Path>[
      Path()..moveTo(square.left, square.top)..lineTo(square.right, square.top)..lineTo(c.dx, square.top - 34)..close(),
      Path()..moveTo(square.right, square.top)..lineTo(square.right, square.bottom)..lineTo(square.right + 34, c.dy)..close(),
      Path()..moveTo(square.left, square.bottom)..lineTo(square.right, square.bottom)..lineTo(c.dx, square.bottom + 34)..close(),
      Path()..moveTo(square.left, square.top)..lineTo(square.left, square.bottom)..lineTo(square.left - 34, c.dy)..close(),
    ];
    for (final path in triangles) {
      canvas.drawPath(path, fill);
      canvas.drawPath(path, line);
    }
  }

  void _cylinderNet(Canvas canvas, Size size, Paint line, Paint fill) {
    final rect = Rect.fromLTWH(size.width * .25, size.height * .30, size.width * .50, size.height * .42);
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, line);
    final r = size.width * .12;
    for (final x in [size.width * .12, size.width * .88]) {
      canvas.drawCircle(Offset(x, size.height * .51), r, fill);
      canvas.drawCircle(Offset(x, size.height * .51), r, line);
    }
  }

  void _coneNet(Canvas canvas, Size size, Paint line, Paint fill) {
    final center = Offset(size.width * .50, size.height * .56);
    final sector = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(size.width * .16, size.height * .24)
      ..quadraticBezierTo(size.width * .78, size.height * .06, size.width * .86, size.height * .56)
      ..close();
    canvas.drawPath(sector, fill);
    canvas.drawPath(sector, line);
    canvas.drawCircle(Offset(size.width * .30, size.height * .88), 17, fill);
    canvas.drawCircle(Offset(size.width * .30, size.height * .88), 17, line);
  }

  void _sphereSurface(Canvas canvas, Size size, Paint line, Paint fill) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * .37;
    canvas.drawCircle(center, r, fill);
    canvas.drawCircle(center, r, line);
    canvas.drawArc(
      Rect.fromCenter(center: center, width: r * 2, height: r * .66),
      0,
      math.pi * 2,
      false,
      line,
    );
  }

  @override
  bool shouldRepaint(covariant _BodySurfacePainter oldDelegate) =>
      body != oldDelegate.body ||
      lineColor != oldDelegate.lineColor ||
      accentColor != oldDelegate.accentColor;
}
