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
    final child = switch (pattern) {
      ErrorPattern.tenBridge => _numberLineAid(),
      ErrorPattern.multiplicationFact => _multiplicationAid(),
      ErrorPattern.placeValue ||
      ErrorPattern.writtenRegrouping ||
      ErrorPattern.writtenProcedure => _placeValueAid(),
      ErrorPattern.unitConversion => const _UnitLadderAid(),
      ErrorPattern.fractionPart => _fractionAid(),
      ErrorPattern.timeDuration => const _TimelineAid(),
      ErrorPattern.perimeterArea => const _RectangleAid(),
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

  Widget _fractionAid() {
    final numbers = _numbers(taskKey);
    var denominator = 4;
    if (taskKey.contains('half') || taskKey.contains(':2:')) denominator = 2;
    if (taskKey.contains('quarter') || taskKey.contains(':4:')) denominator = 4;
    if (numbers.isNotEmpty && (numbers.first == 2 || numbers.first == 4)) {
      denominator = numbers.first;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AidLabel(
          title: 'Bruchbild',
          text: 'Das Ganze wird in $denominator gleich große Teile geteilt.',
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(
            denominator,
            (index) => Expanded(
              child: Container(
                height: 42,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: index == 0
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
  const _UnitLadderAid();

  @override
  Widget build(BuildContext context) {
    const units = ['km', 'm', 'dm', 'cm', 'mm'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AidLabel(
          title: 'Einheitenleiter',
          text: 'Markiere Start- und Zieleinheit und gehe Schritt für Schritt.',
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
                      color: Theme.of(context).colorScheme.outlineVariant,
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
  const _TimelineAid();

  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AidLabel(
            title: 'Zeitlinie',
            text: 'Gehe vom Start zuerst zur nächsten vollen Stunde und dann weiter.',
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

class _RectangleAid extends StatelessWidget {
  const _RectangleAid();

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AidLabel(
            title: 'Umfang oder Fläche?',
            text: 'Umfang ist der Rand. Fläche ist das Innere.',
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 180,
              height: 100,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 5,
                ),
              ),
              child: const Text(
                'Fläche',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(child: Text('Rand = Umfang')),
        ],
      );
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
