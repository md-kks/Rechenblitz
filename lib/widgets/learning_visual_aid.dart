import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/error_diagnosis.dart';

class LearningVisualAid extends StatelessWidget {
  const LearningVisualAid({
    super.key,
    required this.pattern,
    required this.taskKey,
    required this.expected,
  });

  final ErrorPattern pattern;
  final String taskKey;
  final int expected;

  @override
  Widget build(BuildContext context) {
    final processChild = taskKey.startsWith('process:strategy:')
        ? _strategyProcessAid()
        : taskKey.startsWith('process:error:')
            ? _writtenColumnAid()
            : taskKey.startsWith('process:plausibility:')
                ? _plausibilityAid()
                : null;
    final child = processChild ?? switch (pattern) {
      ErrorPattern.tenBridge => _numberLineAid(),
      ErrorPattern.multiplicationFact => _multiplicationAid(),
      ErrorPattern.placeValue => _placeValueAid(),
      ErrorPattern.writtenRegrouping ||
      ErrorPattern.writtenProcedure => _writtenColumnAid(),
      ErrorPattern.unitConversion => _UnitLadderAid(taskKey: taskKey),
      ErrorPattern.fractionPart => _fractionAid(context),
      ErrorPattern.timeDuration => _TimelineAid(taskKey: taskKey),
      ErrorPattern.perimeterArea => _RectangleAid(taskKey: taskKey),
      ErrorPattern.operationChoice ||
      ErrorPattern.wordProblem => const _OperationAid(),
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

  Widget _numberLineAid() {
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
    final bridge = minus ? (a ~/ 10) * 10 : ((a ~/ 10) + 1) * 10;
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

  Widget _placeValueAid() {
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
                        color: Colors.black12,
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
    final units = taskKey.startsWith('mass:')
        ? const ['t', 'kg', 'g']
        : taskKey.startsWith('volume:')
            ? const ['l', 'ml']
            : taskKey.startsWith('time:')
                ? const ['h', 'min']
                : taskKey.startsWith('money:')
                    ? const ['€', 'ct']
                    : const ['km', 'm', 'dm', 'cm', 'mm'];

    String? startUnit;
    String? targetUnit;
    for (final raw in tokens) {
      final normalized = raw == 'euro' ? '€' : raw;
      if (units.contains(normalized)) {
        startUnit ??= normalized;
        if (normalized != startUnit) targetUnit ??= normalized;
      }
    }
    if (taskKey.startsWith('money:euro')) targetUnit ??= 'ct';
    if (taskKey.startsWith('time:min')) targetUnit ??= 'h';
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
          title: 'Einheitenleiter',
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
    final numbers = RegExp(r'\\d+')
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
  });

  final int start;
  final int bridge;
  final int end;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final accent = Paint()
      ..color = Colors.black87
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
          style: const TextStyle(
            color: Colors.black87,
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
      end != oldDelegate.end;
}
