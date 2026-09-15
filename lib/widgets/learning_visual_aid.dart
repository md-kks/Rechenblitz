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

  static String _baseTaskKey(String key) {
    if (!key.startsWith('remediation:')) return key;
    final first = key.indexOf(':');
    final second = key.indexOf(':', first + 1);
    return second < 0 || second + 1 >= key.length ? key : key.substring(second + 1);
  }

  static bool canRender({
    required ErrorPattern pattern,
    required String taskKey,
    String? methodKey,
  }) {
    final baseTaskKey = _baseTaskKey(taskKey);
    if (baseTaskKey != taskKey) {
      return canRender(
        pattern: pattern,
        taskKey: baseTaskKey,
        methodKey: methodKey,
      );
    }
    if (methodKey == 'addition:toFullTen' ||
        methodKey == 'addition:direct' ||
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
        taskKey.startsWith('money:') ||
        taskKey.startsWith('clock:') ||
        taskKey.startsWith('geometry:') ||
        taskKey.startsWith('round:') ||
        taskKey.startsWith('estimate:') ||
        taskKey.startsWith('roman:') ||
        taskKey.startsWith('data:') ||
        taskKey.startsWith('prob:') ||
        taskKey.startsWith('combo:') ||
        taskKey.startsWith('wall:') ||
        taskKey.startsWith('divide:') ||
        taskKey.startsWith('mental:') ||
        taskKey.startsWith('law:') ||
        taskKey.startsWith('process:reasoning:') ||
        taskKey.startsWith('proportion:') ||
        taskKey.startsWith('symmetry:') ||
        taskKey.startsWith('plan:') ||
        taskKey.startsWith('volume:') ||
        taskKey.startsWith('geomrel:') ||
        taskKey.startsWith('large:') ||
        taskKey.startsWith('body:cube-net:') ||
        (taskKey.startsWith('body:') && !taskKey.startsWith('body:cube-net:')) ||
        taskKey.startsWith('process:strategy:') ||
        taskKey.startsWith('process:error:') ||
        taskKey.startsWith('process:plausibility:') ||
        taskKey.startsWith('process:representation:') ||
        taskKey.startsWith('story:calc:')) {
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
      ErrorPattern.representationTranslation ||
      ErrorPattern.moneyCalculation ||
      ErrorPattern.clockReading ||
      ErrorPattern.geometryProperty ||
      ErrorPattern.roundingPlace ||
      ErrorPattern.estimation ||
      ErrorPattern.romanNumeral ||
      ErrorPattern.dataReading ||
      ErrorPattern.probabilityReasoning ||
      ErrorPattern.combinatorics ||
      ErrorPattern.divisionFact ||
      ErrorPattern.numberRelations ||
      ErrorPattern.mentalStrategy ||
      ErrorPattern.arithmeticLaw ||
      ErrorPattern.proportionalReasoning ||
      ErrorPattern.symmetry ||
      ErrorPattern.planScale ||
      ErrorPattern.volume => true,
      _ => false,
    };
  }

  @override
  Widget build(BuildContext context) {
    final baseTaskKey = _baseTaskKey(taskKey);
    if (baseTaskKey != taskKey) {
      return LearningVisualAid(
        pattern: pattern,
        taskKey: baseTaskKey,
        expected: expected,
        methodKey: methodKey,
      );
    }
    final processChild = methodKey == 'numberFriends:decomposition'
        ? _numberFriendAid()
        : methodKey == 'addition:direct'
            ? _additionDirectAid()
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
                            : taskKey.startsWith('money:')
                                ? _moneyAid(context)
                                : taskKey.startsWith('clock:')
                                    ? _clockAid(context)
                                    : taskKey.startsWith('geometry:')
                                        ? _basicGeometryAid(context)
                                        : taskKey.startsWith('round:')
                                            ? _roundingAid(context)
                                            : taskKey.startsWith('estimate:')
                                                ? _estimationAid(context)
                                                : taskKey.startsWith('roman:')
                                                    ? _romanAid(context)
                                                    : taskKey.startsWith('data:')
                                                        ? _dataAid(context)
                                                        : taskKey.startsWith('prob:')
                                                            ? _probabilityAid(context)
                                                            : taskKey.startsWith('combo:')
                                                                ? _combinatoricsAid(context)
                                                                : taskKey.startsWith('body:') &&
                                                            !taskKey.startsWith('body:cube-net:')
                                                        ? _geometryBodyAid(context)
                                                        : taskKey.startsWith('story:calc:')
                                    ? _wordProblemCalculationAid(context)
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
    final extendedChild = taskKey.startsWith('large:')
        ? _largeNumberAid(context)
        : taskKey.startsWith('body:cube-net:')
            ? _cubeNetAid(context)
            : taskKey.startsWith('wall:')
        ? _numberWallAid(context)
        : taskKey.startsWith('divide:')
            ? _divisionFactAid(context)
            : taskKey.startsWith('mental:')
                ? _mentalStrategyAid(context)
                : taskKey.startsWith('law:') || taskKey.startsWith('process:reasoning:')
                    ? _arithmeticLawAid(context)
                    : taskKey.startsWith('proportion:')
                        ? _proportionAid(context)
                        : taskKey.startsWith('symmetry:')
                            ? _symmetryAid(context)
                            : taskKey.startsWith('plan:')
                                ? _planAid(context)
                                : taskKey.startsWith('volume:')
                                    ? _volumeAid(context)
                                    : taskKey.startsWith('geomrel:')
                                        ? _geometryRelationsAid(context)
                                        : null;
    final child = extendedChild ?? processChild ?? switch (pattern) {
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
      ErrorPattern.moneyCalculation => _moneyAid(context),
      ErrorPattern.clockReading => _clockAid(context),
      ErrorPattern.geometryProperty => _basicGeometryAid(context),
      ErrorPattern.roundingPlace => _roundingAid(context),
      ErrorPattern.estimation => _estimationAid(context),
      ErrorPattern.romanNumeral => _romanAid(context),
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

  Widget _moneyAid(BuildContext context) {
    final parts = taskKey.split(':');
    final family = parts.length >= 2 ? parts[1] : '';
    final numbers = RegExp(r'\d+')
        .allMatches(taskKey)
        .map((match) => int.parse(match.group(0)!))
        .toList(growable: false);

    if (family == 'convert') {
      return const Column(
        key: ValueKey('help-money-convert'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AidLabel(
            title: 'Euro und Cent verbinden',
            text: 'Nutze zuerst nur die Grundbeziehung. Den gefragten Betrag rechnest du danach selbst aus.',
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MoneyToken(label: '1 €'),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.sync_alt_rounded),
              ),
              _MoneyToken(label: '100 ct'),
            ],
          ),
        ],
      );
    }

    if (family == 'coins') {
      return const Column(
        key: ValueKey('help-money-coins'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AidLabel(
            title: 'Betrag mit Münzen bauen',
            text: 'Beginne mit einer großen passenden Münze und ergänze nur, was noch fehlt.',
          ),
          SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MoneyToken(label: '1 €'),
              _MoneyToken(label: '2 €'),
              _MoneyToken(label: '5 €'),
              _MoneyToken(label: '10 €'),
            ],
          ),
        ],
      );
    }

    final first = numbers.length >= 2 ? numbers[numbers.length - 2] : null;
    final second = numbers.isNotEmpty ? numbers.last : null;
    final title = family == 'add'
        ? 'Geldbeträge zusammenlegen'
        : family == 'missing'
            ? 'Fehlenden Geldbetrag finden'
            : 'Bezahlen und Rest bestimmen';
    final left = family == 'missing' ? 'Gesamt' : family == 'add' ? 'Betrag A' : 'bezahlt';
    final right = family == 'missing' ? 'bekannt' : family == 'add' ? 'Betrag B' : 'Preis';
    final relation = family == 'add'
        ? 'zusammen: ? €'
        : family == 'missing'
            ? 'fehlender Teil: ? €'
            : 'Rest: ? €';

    return Column(
      key: const ValueKey('help-money-model'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AidLabel(
          title: title,
          text: 'Stelle die gegebenen Beträge getrennt dar. Die gesuchte Geldmenge bleibt zunächst offen.',
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            _MoneyAmountCard(label: left, value: first),
            const Icon(Icons.arrow_forward_rounded),
            _MoneyAmountCard(label: right, value: second),
          ],
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            relation,
            key: const ValueKey('help-money-unknown'),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  Widget _clockAid(BuildContext context) => Column(
        key: const ValueKey('help-clock-reference'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AidLabel(
            title: 'Die Zeiger getrennt lesen',
            text: 'Das Beispiel zeigt nur die Rollen der Zeiger – nicht die Lösung deiner Aufgabe.',
          ),
          const SizedBox(height: 10),
          Center(
            child: CustomPaint(
              size: const Size.square(170),
              painter: _ClockReferencePainter(
                lineColor: Theme.of(context).colorScheme.onSurface,
                accentColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('langer Zeiger → Minuten')),
              Chip(label: Text('kurzer Zeiger → Stunden')),
            ],
          ),
        ],
      );

  Widget _basicGeometryAid(BuildContext context) {
    final parts = taskKey.split(':');
    final shape = parts.length >= 3 ? parts[2] : '';
    return Column(
      key: const ValueKey('help-geometry-properties'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AidLabel(
          title: 'Form am Rand untersuchen',
          text: 'Fahre gedanklich einmal am Rand entlang. Achte auf Treffpunkte und darauf, ob der Rand gerade oder gekrümmt ist.',
        ),
        const SizedBox(height: 10),
        Center(
          child: CustomPaint(
            key: const ValueKey('help-geometry-shape'),
            size: const Size(190, 125),
            painter: _GeometryPropertyPainter(
              shape: shape,
              lineColor: Theme.of(context).colorScheme.onSurface,
              accentColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text('Ecke = Treffpunkt')),
            Chip(label: Text('Seite = gerader Rand')),
          ],
        ),
      ],
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

  Widget _wordProblemCalculationAid(BuildContext context) {
    final parts = taskKey.split(':');
    if (parts.length < 5) {
      return const _AidLabel(
        title: 'Rechenplan ausführen',
        text: 'Die passende Rechnung steht fest. Rechne sie jetzt Schritt für Schritt aus.',
      );
    }
    final operation = parts[2];
    final a = int.tryParse(parts[3]);
    final b = int.tryParse(parts[4]);
    if (a == null || b == null) {
      return const _AidLabel(
        title: 'Rechenplan ausführen',
        text: 'Die passende Rechnung steht fest. Rechne sie jetzt Schritt für Schritt aus.',
      );
    }
    final symbol = switch (operation) {
      '+' => '+',
      '-' => '−',
      'x' => '×',
      'divide' => '÷',
      _ => '?',
    };
    final relation = switch (operation) {
      '+' => 'Zwei Mengen werden zusammengelegt.',
      '-' => 'Von der vorhandenen Menge wird etwas weggenommen.',
      'x' => 'Gleich große Gruppen werden zusammengezählt.',
      'divide' => 'Die Gesamtmenge wird gleichmäßig auf Gruppen verteilt.',
      _ => 'Führe die bereits gewählte Rechenart aus.',
    };
    return Column(
      key: const ValueKey('help-story-calculation'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AidLabel(title: 'Rechenplan ausführen', text: relation),
        const SizedBox(height: 12),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('$a')),
              Text(symbol, style: Theme.of(context).textTheme.headlineSmall),
              Chip(label: Text('$b')),
              Text('=', style: Theme.of(context).textTheme.headlineSmall),
              const Chip(label: Text('?')),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text('Das Ergebnis bleibt offen. Rechne es selbst aus.'),
      ],
    );
  }

  Widget _additionDirectAid() {
    final numbers = _numbers(taskKey);
    if (numbers.length < 2) {
      return const _AidLabel(
        title: 'Direkt addieren',
        text: 'Halte die Startzahl fest und gehe um den zweiten Summanden weiter.',
      );
    }
    final a = numbers[numbers.length - 2];
    final b = numbers.last;
    return Column(
      key: const ValueKey('help-addition-direct'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AidLabel(
          title: 'Direkt addieren',
          text:
              'Hier wird kein Zehner überschritten. Lies den Weg von links nach rechts und bestimme das Ziel selbst.',
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text('Start: $a')),
            const Icon(Icons.arrow_forward_rounded),
            Chip(label: Text('+$b')),
            const Icon(Icons.arrow_forward_rounded),
            const Chip(label: Text('Ziel: ?')),
          ],
        ),
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

  Widget _roundingAid(BuildContext context) {
    final parts = taskKey.split(':');
    final number = parts.length >= 3 ? int.tryParse(parts[1]) : null;
    final place = parts.length >= 3 ? int.tryParse(parts[2]) : null;
    if (number == null || place == null || place <= 0) {
      return const _AidLabel(
        title: 'Zwischen zwei Rundungsankern',
        text: 'Suche die beiden benachbarten glatten Zahlen und markiere die Mitte dazwischen.',
      );
    }
    return Column(
      key: const ValueKey('help-rounding-anchors'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AidLabel(
          title: 'Zwischen zwei Rundungsankern',
          text: 'Die Zahl liegt zwischen zwei glatten Nachbarn. Die Mitte entscheidet, zu welcher Seite gerundet wird.',
        ),
        const SizedBox(height: 12),
        _RoundingAnchorBar(value: number, place: place),
        const SizedBox(height: 8),
        const Text(
          'Entscheide selbst, auf welcher Seite der Mitte die Zahl liegt.',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _estimationAid(BuildContext context) {
    final numbers = _numbers(taskKey);
    if (numbers.length < 3) {
      return const _AidLabel(
        title: 'Überschlag vorbereiten',
        text: 'Runde beide Summanden getrennt auf dieselbe Stelle. Addiere erst danach.',
      );
    }
    final a = numbers[numbers.length - 3];
    final b = numbers[numbers.length - 2];
    final place = numbers.last;
    if (place <= 0) return const SizedBox.shrink();
    return Column(
      key: const ValueKey('help-estimation-anchors'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AidLabel(
          title: 'Beide Zahlen getrennt runden',
          text: 'Bestimme für jeden Summanden zuerst nur den passenden Rundungsanker. Der Überschlag selbst bleibt noch offen.',
        ),
        const SizedBox(height: 12),
        Text('1. Summand: $a', style: const TextStyle(fontWeight: FontWeight.w800)),
        _RoundingAnchorBar(value: a, place: place),
        const SizedBox(height: 12),
        Text('2. Summand: $b', style: const TextStyle(fontWeight: FontWeight.w800)),
        _RoundingAnchorBar(value: b, place: place),
        const SizedBox(height: 8),
        const Text(
          'Erst wenn beide Rundungswerte feststehen, werden sie zum Überschlag addiert.',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _romanAid(BuildContext context) {
    final writing = taskKey.startsWith('roman:write:');
    return Column(
      key: const ValueKey('help-roman-structure'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AidLabel(
          title: writing ? 'Römische Zahl zusammensetzen' : 'Römische Zahl in Blöcke teilen',
          text: writing
              ? 'Nutze zuerst die Grundwerte und prüfe dann, ob ein kleineres Zeichen vor einem größeren als Subtraktion gelesen wird.'
              : 'Lies nicht Zeichen für Zeichen blind weiter. Suche zuerst bekannte Einzelwerte und Subtraktionspaare.',
        ),
        const SizedBox(height: 12),
        Wrap(
          key: const ValueKey('help-roman-legend'),
          spacing: 8,
          runSpacing: 8,
          children: const [
            Chip(label: Text('I = 1')),
            Chip(label: Text('V = 5')),
            Chip(label: Text('X = 10')),
            Chip(label: Text('L = 50')),
            Chip(label: Text('C = 100')),
          ],
        ),
        const SizedBox(height: 10),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text('IV: 1 vor 5')),
            Chip(label: Text('IX: 1 vor 10')),
            Chip(label: Text('XL: 10 vor 50')),
            Chip(label: Text('XC: 10 vor 100')),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Das konkrete Ergebnis der Aufgabe musst du aus diesen Regeln selbst zusammensetzen.',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _dataAid(BuildContext context) {
    if (taskKey.startsWith('data:tally:')) {
      return const Column(
        key: ValueKey('help-data-tally'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AidLabel(
            title: 'Strichliste in Fünferblöcken lesen',
            text: 'Ein vollständiger Block steht für fünf. Zähle zuerst nur solche Blöcke und ergänze einzelne Reststriche erst danach.',
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('||||╱', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
              SizedBox(width: 10),
              Text('= ein Fünferblock', style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      );
    }
    if (taskKey.startsWith('data:representation:')) {
      return const Column(
        key: ValueKey('help-data-representation'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AidLabel(
            title: 'Darstellungen haben verschiedene Stärken',
            text: 'Achte zuerst darauf, was du mit den Daten tun willst. Die Situation selbst musst du danach noch passend zuordnen.',
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('Strichliste → laufend zählen')),
              Chip(label: Text('Tabelle → Werte nachschlagen')),
              Chip(label: Text('Balken → Größen vergleichen')),
            ],
          ),
        ],
      );
    }
    final parts = taskKey.split(':');
    final values = parts.length == 3
        ? parts[2].split('-').map(int.tryParse).whereType<int>().toList(growable: false)
        : const <int>[];
    if (values.length != 4) return const SizedBox.shrink();
    final operation = parts[1];
    return _DataChartAid(values: values, operation: operation);
  }

  Widget _probabilityAid(BuildContext context) {
    if (taskKey.startsWith('prob:sure:') ||
        taskKey.startsWith('prob:possible:') ||
        taskKey.startsWith('prob:impossible:')) {
      return Column(
        key: const ValueKey('help-probability-sample-space'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AidLabel(
            title: 'Ergebnisraum zuerst vollständig ansehen',
            text: 'Ein normaler Würfel kann genau diese sechs Ergebnisse zeigen. Vergleiche das Ereignis erst danach mit dieser Menge.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var face = 1; face <= 6; face++)
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Text('$face', style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Passt jedes Ergebnis, nur ein Teil oder keines?', style: TextStyle(fontWeight: FontWeight.w800)),
        ],
      );
    }
    final numbers = _numbers(taskKey);
    if (taskKey.startsWith('prob:bag:') && numbers.length >= 2) {
      return _ProbabilityBagAid(red: numbers[numbers.length - 2], blue: numbers.last);
    }
    if (taskKey.startsWith('prob:experiment:compare:') && numbers.length >= 3) {
      return _ObservedFrequencyAid(red: numbers[numbers.length - 2], blue: numbers.last);
    }
    if (taskKey.startsWith('prob:experiment:relative:') && numbers.length >= 2) {
      return _RelativeFrequencyAid(trials: numbers[numbers.length - 2], hits: numbers.last);
    }
    return const SizedBox.shrink();
  }

  Widget _combinatoricsAid(BuildContext context) {
    final parts = taskKey.split(':');
    if (parts.length != 5) return const SizedBox.shrink();
    final first = int.tryParse(parts[2]);
    final second = int.tryParse(parts[3]);
    final third = int.tryParse(parts[4]);
    if (first == null || second == null || third == null) return const SizedBox.shrink();
    final labels = switch (parts[1]) {
      'clothes' => ('T-Shirt', 'Hose', 'Mütze'),
      'icecream' => ('Eissorte', 'Soße', 'Streuselart'),
      'symbols' => ('Symbol', 'Farbe', 'Rahmen'),
      _ => ('erste Wahl', 'zweite Wahl', 'dritte Wahl'),
    };
    return Column(
      key: const ValueKey('help-combinatorics-branch'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AidLabel(
          title: 'Nur einen Ast zuerst vollständig machen',
          text: 'Halte genau einen ${labels.$1} fest. Verzweige von dort systematisch, bevor du die übrigen $first Möglichkeiten der ersten Kategorie betrachtest.',
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Chip(label: Text('1 ${labels.$1} fest')),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Icon(Icons.arrow_downward_rounded),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var b = 1; b <= second; b++)
              for (var c = 1; c <= third; c++)
                Chip(label: Text(third > 1 ? '${labels.$2} $b + ${labels.$3} $c' : '${labels.$2} $b')),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Erst danach dieselbe Verzweigung für jede weitere erste Wahl wiederholen.', style: TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }



  Widget _largeNumberAid(BuildContext context) {
    if (taskKey.startsWith('large:compare:')) {
      return _largeNumberCompareAid(context);
    }
    final parts = taskKey.split(':');
    if (parts.length < 2) return const SizedBox.shrink();
    final family = parts[1];
    if (family == 'word') {
      return const Column(
        key: ValueKey('help-large-word-structure'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AidLabel(
            title: 'Zahlwort in Stellenwertgruppen zerlegen',
            text: 'Suche zuerst Millionen/Tausender, danach Hunderter und zuletzt Zehner/Einer. Trage jede Gruppe erst an ihren Platz, bevor du die ganze Zahl liest.',
          ),
          SizedBox(height: 10),
          Wrap(spacing: 5, runSpacing: 5, children: [
            Chip(label: Text('M')), Chip(label: Text('HT')), Chip(label: Text('ZT')),
            Chip(label: Text('T')), Chip(label: Text('H')), Chip(label: Text('Z')), Chip(label: Text('E')),
          ]),
          SizedBox(height: 8),
          Text('Beim deutschen Zahlwort werden Einer vor Zehnern gesprochen: drei-und-vierzig → E vor Z.', style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      );
    }
    if (family == 'order' && parts.length >= 3) {
      final raw = parts[2].split('-').map(int.tryParse).whereType<int>().toList(growable: false);
      return Column(
        key: const ValueKey('help-large-order'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AidLabel(
            title: 'Große Zahlen spaltenweise vergleichen',
            text: 'Richte die Zahlen gedanklich rechtsbündig aus. Vergleiche ganz links und gehe nur weiter, wenn die Ziffern gleich sind.',
          ),
          const SizedBox(height: 10),
          for (final value in raw)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(_formatNumber(value), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ),
          const SizedBox(height: 6),
          const Text('Noch nicht sortieren – zuerst die erste unterschiedliche Stelle finden.', style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      );
    }
    final numbers = _numbers(taskKey);
    final number = numbers.isEmpty ? null : numbers.first;
    if (family == 'neighbor' && number != null) {
      return Column(
        key: const ValueKey('help-large-neighbor'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AidLabel(title: 'Genau einen Schritt auf der Zahlengeraden', text: 'Vorgänger bedeutet exakt 1 zurück, Nachfolger exakt 1 weiter – auch über Stellenwertwechsel hinweg.'),
          const SizedBox(height: 10),
          Center(child: Text('?   ←   ${_formatNumber(number)}   →   ?', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
        ],
      );
    }
    if ((family == 'place' || family == 'decompose') && number != null) {
      final raw = number.toString().padLeft(7, '0');
      const labels = ['M', 'HT', 'ZT', 'T', 'H', 'Z', 'E'];
      final requestedPlace = family == 'place' && numbers.length >= 2 ? numbers[1] : null;
      const places = [1000000, 100000, 10000, 1000, 100, 10, 1];
      return Column(
        key: const ValueKey('help-large-place-table'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AidLabel(title: 'Jede Ziffer hat einen festen Stellenwert', text: 'Lies von links nach rechts und behalte auch Nullstellen als echte Platzhalter in der Tabelle.'),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (var i=0;i<labels.length;i++)
                Container(
                  width: 52,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: requestedPlace == places[i] ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant,
                      width: requestedPlace == places[i] ? 3 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(children: [
                    Text(labels[i], style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(raw[i], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  ]),
                ),
            ]),
          ),
        ],
      );
    }
    return const _AidLabel(title: 'Große Zahl strukturieren', text: 'Gliedere die Zahl in Stellenwerte und bearbeite nur eine Stelle oder Gruppe nach der anderen.');
  }

  Widget _cubeNetAid(BuildContext context) {
    return Column(
      key: const ValueKey('help-cube-net-fold'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AidLabel(
          title: 'Würfelnetz gedanklich an Kanten falten',
          text: 'Nimm eine Fläche als Boden. Klappe nur direkt benachbarte Flächen an ihrer gemeinsamen Kante hoch. Prüfe danach, ob zwei Flächen denselben Platz besetzen würden.',
        ),
        const SizedBox(height: 12),
        Center(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (var i=0;i<3;i++)
                Container(width: 48, height: 48, alignment: Alignment.center,
                  decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2)),
                  child: i == 1 ? const Icon(Icons.keyboard_arrow_up_rounded) : null),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text('Das Beispiel zeigt nur das Faltprinzip – nicht die Lösung des konkreten Netzes.', style: TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _numberWallAid(BuildContext context) {
    final parts = taskKey.split(':');
    if (parts.length < 3 || parts[1] == 'fallback') {
      return const _AidLabel(
        title: 'Zahlenmauer: immer Nachbarsteine verbinden',
        text: 'Nach oben werden zwei benachbarte Steine addiert. Fehlt unten ein Stein, gehe von einem bekannten oberen Stein mit Minus zurück.',
      );
    }
    final values = parts[1].split('-').map(int.tryParse).toList(growable: false);
    final hidden = int.tryParse(parts[2]);
    if (values.length != 6 || values.any((v) => v == null) || hidden == null) {
      return const SizedBox.shrink();
    }
    final wall = values.cast<int>();
    Widget stone(int index) => Container(
          key: ValueKey('help-wall-stone-$index'),
          constraints: const BoxConstraints(minWidth: 54),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(index == hidden ? '?' : '${wall[index]}', textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900)),
        );
    return Column(
      key: const ValueKey('help-number-wall'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AidLabel(
          title: 'Die Mauer zeigt Rechenbeziehungen',
          text: 'Jeder obere Stein gehört genau zu den zwei Steinen direkt darunter. Nutze nur diese Nachbarschaft; das Fragezeichen bleibt offen.',
        ),
        const SizedBox(height: 12),
        Center(child: stone(5)),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [stone(3), const SizedBox(width: 8), stone(4)]),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [stone(0), const SizedBox(width: 8), stone(1), const SizedBox(width: 8), stone(2)]),
      ],
    );
  }

  Widget _divisionFactAid(BuildContext context) {
    final parts = taskKey.split(':');
    final dividend = parts.length >= 3 ? int.tryParse(parts[1]) : null;
    final divisor = parts.length >= 3 ? int.tryParse(parts[2]) : null;
    if (dividend == null || divisor == null || divisor <= 0) return const SizedBox.shrink();
    return Column(
      key: const ValueKey('help-division-inverse'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AidLabel(
          title: 'Geteilt rückwärts als Malaufgabe denken',
          text: 'Der Teiler wird zum bekannten Faktor. Gesucht ist der Faktor, der wieder genau zum Dividend führt.',
        ),
        const SizedBox(height: 12),
        Center(
          child: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(label: Text('$divisor')),
              const Text('×', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const Chip(label: Text('?')),
              const Text('=', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              Chip(label: Text('$dividend')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mentalStrategyAid(BuildContext context) {
    final parts = taskKey.split(':');
    final a = parts.length >= 4 ? int.tryParse(parts[2]) : null;
    final b = parts.length >= 4 ? int.tryParse(parts[3]) : null;
    final op = parts.length >= 2 ? parts[1] : '';
    if (a == null || b == null || (op != '+' && op != '-')) return const SizedBox.shrink();
    var place = 1;
    while (place * 10 <= b) {
      place *= 10;
    }
    final chunk = (b ~/ place) * place;
    final rest = b - chunk;
    return Column(
      key: const ValueKey('help-mental-chunks'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AidLabel(
          title: 'Zweiten Operanden nach Stellenwerten zerlegen',
          text: 'Rechne nicht alles auf einmal. Beginne mit dem größten Stellenwertblock und nimm den Rest erst danach.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(label: Text('$a')),
            Text(op, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            Chip(label: Text('$chunk')),
            const Icon(Icons.arrow_forward_rounded),
            const Chip(label: Text('?')),
            if (rest > 0) ...[
              Text(op, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              Chip(label: Text('$rest')),
              const Icon(Icons.arrow_forward_rounded),
              const Chip(label: Text('?')),
            ],
          ],
        ),
      ],
    );
  }

  Widget _arithmeticLawAid(BuildContext context) {
    final parts = taskKey.split(':');
    if (taskKey.startsWith('process:reasoning:')) {
      final family = parts.length >= 3 ? parts[2] : '';
      final text = switch (family) {
        'compensate' => 'Wenn ein Summand um denselben Betrag kleiner und der andere größer wird, gleichen sich beide Veränderungen aus.',
        'commute' => 'Beim Vertauschen bleiben dieselben Faktoren erhalten; nur ihre Reihenfolge ändert sich.',
        'distribute' => 'Wird ein Faktor auf eine Zerlegung verteilt, muss er zu jedem Teil gehören – auch zur Korrektur.',
        _ => 'Vergleiche zuerst, was an der Rechnung verändert wurde und was dabei gleich bleibt.',
      };
      return Column(
        key: const ValueKey('help-reasoning-structure'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AidLabel(title: 'Veränderung und Invariante trennen', text: text),
          const SizedBox(height: 10),
          const Wrap(spacing: 8, runSpacing: 8, children: [
            Chip(label: Text('Was verändert sich?')),
            Icon(Icons.arrow_forward_rounded),
            Chip(label: Text('Was bleibt gleich?')),
            Icon(Icons.arrow_forward_rounded),
            Chip(label: Text('Warum?')),
          ]),
        ],
      );
    }
    final family = parts.length >= 2 ? parts[1] : '';
    if (family == 'associate' && parts.length >= 5) {
      final a = int.tryParse(parts[2]);
      final b = int.tryParse(parts[3]);
      final c = int.tryParse(parts[4]);
      if (a == null || b == null || c == null) return const SizedBox.shrink();
      return Column(
        key: const ValueKey('help-law-associate'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AidLabel(title: 'Erst ein günstiges Paar suchen', text: 'Bei drei Summanden darfst du zuerst zwei zusammenfassen. Suche ein Paar, das eine glatte Zahl ergibt.'),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [Chip(label: Text('$a')), Chip(label: Text('$b')), Chip(label: Text('$c')), const Chip(label: Text('Ziel: glatte Summe'))]),
        ],
      );
    }
    if (family == 'commute') {
      return const Column(
        key: ValueKey('help-law-commute'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AidLabel(title: 'Zeilen und Spalten vertauschen', text: 'Bei einer Malaufgabe kannst du die beiden Faktoren vertauschen. Die Anordnung ändert sich, die Anzahl der Elemente nicht.'),
          SizedBox(height: 10),
          Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [Chip(label: Text('Zeilen × Spalten')), Icon(Icons.swap_horiz_rounded), Chip(label: Text('Spalten × Zeilen'))]),
        ],
      );
    }
    if (family == 'distribute' && parts.length >= 4) {
      final factor = int.tryParse(parts[2]);
      final value = int.tryParse(parts[3]);
      if (factor == null || value == null) return const SizedBox.shrink();
      final rounded = ((value + 9) ~/ 10) * 10;
      final gap = rounded - value;
      return Column(
        key: const ValueKey('help-law-distribute'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AidLabel(title: 'Über eine glatte Zahl zerlegen', text: 'Rechne zuerst mit der leichteren glatten Zahl. Die Korrektur muss anschließend ebenfalls mit dem Faktor berücksichtigt werden.'),
          const SizedBox(height: 10),
          Text('$factor × $value  →  $factor × $rounded  −  ($factor × $gap)', style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('Die Korrektur selbst bleibt zum Ausrechnen offen.', style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _proportionAid(BuildContext context) {
    final parts = taskKey.split(':');
    if (parts.length != 5) return const SizedBox.shrink();
    final unit = int.tryParse(parts[2]);
    final first = int.tryParse(parts[3]);
    final second = int.tryParse(parts[4]);
    if (unit == null || first == null || second == null) return const SizedBox.shrink();
    final knownTotal = unit * first;
    return Column(
      key: const ValueKey('help-proportion-unit'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AidLabel(title: 'Erst auf 1 Einheit zurückgehen', text: 'Teile den bekannten Gesamtwert gleichmäßig auf die bekannte Anzahl. Übertrage danach denselben Einzelwert auf die neue Anzahl.'),
        const SizedBox(height: 12),
        Text('$first Einheiten = $knownTotal €', style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Wrap(spacing: 5, runSpacing: 5, children: [for (var i=0;i<first;i++) const Chip(label: Text('? €'))]),
        const SizedBox(height: 10),
        Text('$second Einheiten = ? €', style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Wrap(spacing: 5, runSpacing: 5, children: [for (var i=0;i<second;i++) const Chip(label: Text('gleich viel'))]),
      ],
    );
  }

  Widget _symmetryAid(BuildContext context) {
    return Column(
      key: const ValueKey('help-symmetry-concept'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AidLabel(title: 'Eine Achse immer einzeln prüfen', text: 'Stell dir vor, du faltest genau auf einer Linie. Nur wenn beide Hälften deckungsgleich werden, ist diese Linie eine Symmetrieachse.'),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 54, height: 70, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2), borderRadius: const BorderRadius.horizontal(left: Radius.circular(14))), child: const Icon(Icons.circle, size: 14)),
          Container(key: const ValueKey('help-symmetry-axis'), width: 3, height: 86, color: Theme.of(context).colorScheme.outline),
          Container(width: 54, height: 70, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2), borderRadius: const BorderRadius.horizontal(right: Radius.circular(14))), child: const Icon(Icons.circle, size: 14)),
        ]),
        const SizedBox(height: 8),
        const Center(child: Text('spiegelgleich?', style: TextStyle(fontWeight: FontWeight.w800))),
      ],
    );
  }

  Widget _planAid(BuildContext context) {
    final parts = taskKey.split(':');
    if (parts.length < 2) return const SizedBox.shrink();
    if (parts[1] == 'scale' && parts.length >= 4) {
      final scale = int.tryParse(parts[2]);
      final cm = int.tryParse(parts[3]);
      if (scale == null || cm == null) return const SizedBox.shrink();
      return Column(
        key: const ValueKey('help-plan-scale'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AidLabel(title: 'Maßstab als gleiche Blöcke lesen', text: 'Jeder Zentimeter im Plan steht für denselben Real-Abstand. Baue die Planlänge aus gleich großen Zuordnungsblöcken; die Gesamtsumme bleibt offen.'),
          const SizedBox(height: 10),
          Text('1 cm im Plan = $scale m real', style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Wrap(spacing: 5, runSpacing: 5, children: [for (var i=0;i<cm;i++) Chip(label: Text('1 cm → $scale m'))]),
          const SizedBox(height: 8),
          const Text('Gesamt: ? m', style: TextStyle(fontWeight: FontWeight.w900)),
        ],
      );
    }
    if (parts[1] == 'path' && parts.length >= 4) {
      return Column(
        key: const ValueKey('help-plan-path'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _AidLabel(title: 'Weg in Abschnitte zerlegen', text: 'Lies jeden Wegabschnitt getrennt mit Richtung und Länge. Erst danach werden die gegangenen Felder zusammengezählt.'),
          SizedBox(height: 10),
          Wrap(spacing: 8, children: [Chip(label: Text('→ erster Abschnitt')), Icon(Icons.add_rounded), Chip(label: Text('↑ zweiter Abschnitt')), Icon(Icons.arrow_forward_rounded), Chip(label: Text('gesamt ?'))]),
        ],
      );
    }
    if (parts[1] == 'route') {
      return const Column(
        key: ValueKey('help-plan-route'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AidLabel(title: 'Pfeilplan in Reihenfolge lesen', text: 'Richtung und Länge gehören zusammen. Lies zuerst den ersten Block vollständig und erst danach den zweiten.'),
          SizedBox(height: 10),
          Wrap(spacing: 8, children: [Chip(label: Text('1. Richtung + Länge')), Icon(Icons.arrow_forward_rounded), Chip(label: Text('2. Richtung + Länge'))]),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _volumeAid(BuildContext context) {
    final parts = taskKey.split(':');
    if (parts.length != 4) return const SizedBox.shrink();
    final length = int.tryParse(parts[1]);
    final width = int.tryParse(parts[2]);
    final height = int.tryParse(parts[3]);
    if (length == null || width == null || height == null) return const SizedBox.shrink();
    return Column(
      key: const ValueKey('help-volume-layers'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AidLabel(title: 'Erst eine Schicht, dann alle Schichten', text: 'Bestimme zuerst, wie viele Einheitswürfel in genau einer waagerechten Schicht liegen. Wiederhole diese Schicht anschließend so oft wie die Höhe angibt.'),
        const SizedBox(height: 10),
        Text('eine Schicht: $length × $width Würfel', style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Wrap(spacing: 5, runSpacing: 5, children: [for (var i=0;i<height;i++) Chip(label: Text('Schicht ${i+1}'))]),
        const SizedBox(height: 8),
        const Text('alle Würfel zusammen: ?', style: TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _geometryRelationsAid(BuildContext context) {
    final parts = taskKey.split(':');
    final family = parts.length >= 2 ? parts[1] : '';
    if (family == 'circle') {
      return const Column(
        key: ValueKey('help-geomrel-circle'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AidLabel(title: 'Kreislinien vom Mittelpunkt aus unterscheiden', text: 'Ein Radius geht vom Mittelpunkt bis zum Rand. Ein Durchmesser geht durch den Mittelpunkt von Rand zu Rand.'),
          SizedBox(height: 8),
          Wrap(spacing: 8, children: [Chip(label: Text('Mittelpunkt → Rand = Radius')), Chip(label: Text('Rand → Mittelpunkt → Rand = Durchmesser'))]),
        ],
      );
    }
    if (family == 'angle') {
      return const Column(
        key: ValueKey('help-geomrel-angle'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AidLabel(title: 'Rechten Winkel an einer Referenzecke prüfen', text: 'Vergleiche den Winkel mit einer Papier- oder Quadratecke. Passt die Öffnung genau, ist der Winkel recht.'),
          SizedBox(height: 8),
          Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [Icon(Icons.crop_square_rounded, size: 42), Text('Referenz: 90°', style: TextStyle(fontWeight: FontWeight.w900))]),
        ],
      );
    }
    if (family == 'lines') {
      return const Column(
        key: ValueKey('help-geomrel-lines'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AidLabel(title: 'Geraden über ihre Beziehung erkennen', text: 'Parallel: der Abstand bleibt gleich. Senkrecht: beim Schneiden entsteht ein rechter Winkel. Vergleiche die Aufgabe mit beiden Referenzen.'),
          SizedBox(height: 8),
          Wrap(spacing: 8, children: [Chip(label: Text('∥ gleicher Abstand')), Chip(label: Text('⟂ rechter Winkel'))]),
        ],
      );
    }
    return const Column(
      key: ValueKey('help-geomrel-figure'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AidLabel(title: 'Figur über Merkmale einordnen', text: 'Prüfe Seitenlängen, Parallelität und rechte Winkel einzeln. Der Name der Figur folgt erst aus der Kombination dieser Merkmale.'),
        SizedBox(height: 8),
        Wrap(spacing: 8, children: [Chip(label: Text('Seiten')), Chip(label: Text('parallel?')), Chip(label: Text('rechte Winkel?'))]),
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

class _DataChartAid extends StatelessWidget {
  const _DataChartAid({required this.values, required this.operation});

  final List<int> values;
  final String operation;

  @override
  Widget build(BuildContext context) {
    final maximum = values.reduce(math.max).toDouble();
    const labels = ['Rot', 'Blau', 'Grün', 'Gelb'];
    final instruction = switch (operation) {
      'max' => 'Suche den höchsten Balken. Lies noch keine fertige Antwort aus einem Text ab.',
      'sum' => 'Lies jeden Balken einzeln an derselben Skala ab. Addiert wird erst danach.',
      _ => 'Für die Differenz vergleichst du Rot und Blau auf derselben Skala.',
    };
    return Column(
      key: const ValueKey('help-data-chart'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AidLabel(title: 'Balken an einer gemeinsamen Skala lesen', text: instruction),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < values.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: values[i] / maximum,
                              widthFactor: 0.65,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  border: Border.all(color: Theme.of(context).colorScheme.primary),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(labels[i], style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 2),
        const SizedBox(height: 6),
        const Text('Tipp: Eine gedachte waagerechte Linie vom Balkenkopf zur Skala hilft beim genauen Ablesen.', style: TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _ProbabilityBagAid extends StatelessWidget {
  const _ProbabilityBagAid({required this.red, required this.blue});
  final int red;
  final int blue;

  @override
  Widget build(BuildContext context) => Column(
        key: const ValueKey('help-probability-bag'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AidLabel(
            title: 'Chance über Anzahlen vergleichen',
            text: 'Jedes Teil ist gleichartig erreichbar. Vergleiche deshalb zuerst nur, von welcher Sorte mehr Teile im Beutel liegen.',
          ),
          const SizedBox(height: 12),
          _TokenGroup(label: 'Rot', count: red, symbol: 'R'),
          const SizedBox(height: 10),
          _TokenGroup(label: 'Blau', count: blue, symbol: 'B'),
          const SizedBox(height: 8),
          const Text('Erst nach dem Mengenvergleich formulierst du: Rot, Blau oder beide gleich wahrscheinlich.', style: TextStyle(fontWeight: FontWeight.w800)),
        ],
      );
}

class _ObservedFrequencyAid extends StatelessWidget {
  const _ObservedFrequencyAid({required this.red, required this.blue});
  final int red;
  final int blue;

  @override
  Widget build(BuildContext context) {
    final maximum = math.max(red, blue).toDouble();
    return Column(
      key: const ValueKey('help-probability-experiment'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AidLabel(
          title: 'Beobachtete Häufigkeiten vergleichen',
          text: 'Die Balken beschreiben nur diese Versuchsreihe. Vergleiche ihre Höhe, ohne daraus eine sichere Vorhersage zu machen.',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final entry in [('Rot', red), ('Blau', blue)])
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: entry.$2 / maximum,
                            widthFactor: 0.45,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondaryContainer,
                                border: Border.all(color: Theme.of(context).colorScheme.secondary),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(entry.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RelativeFrequencyAid extends StatelessWidget {
  const _RelativeFrequencyAid({required this.trials, required this.hits});
  final int trials;
  final int hits;

  @override
  Widget build(BuildContext context) => Column(
        key: const ValueKey('help-probability-relative'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AidLabel(
            title: 'Anteil auf 100 übertragen',
            text: 'Behalte zuerst den beobachteten Anteil bei. Gesucht ist dieselbe Relation mit 100 als Grundmenge.',
          ),
          const SizedBox(height: 12),
          Center(
            child: Text('$hits / $trials   =   ? / 100', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 12),
          Wrap(
            key: const ValueKey('help-relative-hundred-grid'),
            spacing: 2,
            runSpacing: 2,
            children: [
              for (var i = 0; i < 100; i++)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Fülle gedanklich genau so viele von 100 Feldern, dass der Anteil gleich bleibt.', style: TextStyle(fontWeight: FontWeight.w800)),
        ],
      );
}

class _TokenGroup extends StatelessWidget {
  const _TokenGroup({required this.label, required this.count, required this.symbol});
  final String label;
  final int count;
  final String symbol;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 48, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900))),
          Expanded(
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (var i = 0; i < count; i++)
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Text(symbol, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                  ),
              ],
            ),
          ),
        ],
      );
}

class _RoundingAnchorBar extends StatelessWidget {
  const _RoundingAnchorBar({
    required this.value,
    required this.place,
  });

  final int value;
  final int place;

  @override
  Widget build(BuildContext context) {
    final lower = (value ~/ place) * place;
    final upper = lower + place;
    final midpoint = lower + place ~/ 2;
    final fraction = ((value - lower) / place).clamp(0.0, 1.0);
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            disabledActiveTrackColor: Theme.of(context).colorScheme.primary,
            disabledInactiveTrackColor: Theme.of(context).colorScheme.outlineVariant,
            disabledThumbColor: Theme.of(context).colorScheme.primary,
            showValueIndicator: ShowValueIndicator.never,
          ),
          child: Slider(
            key: ValueKey('help-rounding-marker-$value-$place'),
            value: fraction,
            onChanged: null,
          ),
        ),
        Row(
          children: [
            Expanded(child: Text('$lower', textAlign: TextAlign.left)),
            Expanded(
              child: Text(
                'Mitte\n$midpoint',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(child: Text('$upper', textAlign: TextAlign.right)),
          ],
        ),
        const SizedBox(height: 4),
        Text('Zahl: $value', style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
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
class _MoneyToken extends StatelessWidget {
  const _MoneyToken({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        width: 58,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      );
}

class _MoneyAmountCard extends StatelessWidget {
  const _MoneyAmountCard({required this.label, required this.value});
  final String label;
  final int? value;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 105),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value == null ? '? €' : '$value €',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      );
}

class _ClockReferencePainter extends CustomPainter {
  const _ClockReferencePainter({required this.lineColor, required this.accentColor});
  final Color lineColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) * 0.43;
    final outline = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, outline);
    for (var i = 0; i < 12; i++) {
      final angle = -math.pi / 2 + i * math.pi / 6;
      final outer = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final inner = center + Offset(math.cos(angle), math.sin(angle)) * (radius - 8);
      canvas.drawLine(inner, outer, outline);
    }
    final minutePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    final hourPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, center + Offset(0, -radius * 0.72), minutePaint);
    canvas.drawLine(center, center + Offset(radius * 0.48, 0), hourPaint);
    canvas.drawCircle(center, 5, Paint()..color = lineColor);
    final textStyle = TextStyle(color: lineColor, fontSize: 11, fontWeight: FontWeight.w800);
    void label(String text, Offset at) {
      final tp = TextPainter(text: TextSpan(text: text, style: textStyle), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
    }
    label('00', center + Offset(0, -radius - 13));
    label('15', center + Offset(radius + 14, 0));
    label('30', center + Offset(0, radius + 13));
    label('45', center + Offset(-radius - 14, 0));
  }

  @override
  bool shouldRepaint(covariant _ClockReferencePainter oldDelegate) =>
      oldDelegate.lineColor != lineColor || oldDelegate.accentColor != accentColor;
}

class _GeometryPropertyPainter extends CustomPainter {
  const _GeometryPropertyPainter({required this.shape, required this.lineColor, required this.accentColor});
  final String shape;
  final Color lineColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final normal = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final accent = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final cx = size.width / 2;
    final cy = size.height / 2;
    if (shape == 'circle') {
      final radius = math.min(size.width, size.height) * 0.34;
      canvas.drawCircle(Offset(cx, cy), radius, normal);
      final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
      canvas.drawArc(rect, -math.pi / 2, math.pi / 3, false, accent);
      return;
    }
    final rect = shape == 'rectangle'
        ? Rect.fromCenter(center: Offset(cx, cy), width: size.width * 0.68, height: size.height * 0.48)
        : Rect.fromCenter(center: Offset(cx, cy), width: size.height * 0.58, height: size.height * 0.58);
    Path path;
    if (shape == 'triangle') {
      final top = Offset(cx, size.height * 0.16);
      final left = Offset(size.width * 0.23, size.height * 0.82);
      final right = Offset(size.width * 0.77, size.height * 0.82);
      path = Path()..moveTo(top.dx, top.dy)..lineTo(left.dx, left.dy)..lineTo(right.dx, right.dy)..close();
      canvas.drawPath(path, normal);
      canvas.drawLine(top, left, accent);
      canvas.drawCircle(top, 6, Paint()..color = accentColor);
      return;
    }
    path = Path()..addRect(rect);
    canvas.drawPath(path, normal);
    canvas.drawLine(rect.topLeft, rect.topRight, accent);
    canvas.drawCircle(rect.topLeft, 6, Paint()..color = accentColor);
  }

  @override
  bool shouldRepaint(covariant _GeometryPropertyPainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.lineColor != lineColor || oldDelegate.accentColor != accentColor;
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
