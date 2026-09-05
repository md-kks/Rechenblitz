import 'dart:math' as math;

import 'package:flutter/material.dart';

class GeometryRelationVisual extends StatelessWidget {
  const GeometryRelationVisual({
    super.key,
    required this.taskKey,
  });

  final String taskKey;

  @override
  Widget build(BuildContext context) {
    final kind = taskKey.startsWith('geomrel:lines:')
        ? _GeometryKind.lines
        : taskKey.startsWith('geomrel:angle:')
            ? _GeometryKind.angle
            : taskKey.startsWith('geomrel:figure:')
                ? _GeometryKind.figure
                : _GeometryKind.circle;

    return Semantics(
      label: _semanticLabel(kind),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: _GeometryRelationPainter(
                taskKey: taskKey,
                kind: kind,
                lineColor: Theme.of(context).colorScheme.onSurface,
                accentColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _semanticLabel(_GeometryKind kind) => switch (kind) {
        _GeometryKind.lines => taskKey.contains(':parallel:')
            ? 'Zwei parallele Geraden'
            : 'Zwei senkrechte Geraden mit rechtem Winkel',
        _GeometryKind.angle => 'Darstellung eines rechten Winkels',
        _GeometryKind.figure => 'Geometrische Figur zur Aufgabenbeschreibung',
        _GeometryKind.circle => taskKey.contains(':diameter:')
            ? 'Kreis mit eingezeichnetem Durchmesser'
            : 'Kreis mit eingezeichnetem Radius',
      };
}

enum _GeometryKind { lines, angle, figure, circle }

class _GeometryRelationPainter extends CustomPainter {
  const _GeometryRelationPainter({
    required this.taskKey,
    required this.kind,
    required this.lineColor,
    required this.accentColor,
  });

  final String taskKey;
  final _GeometryKind kind;
  final Color lineColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final accent = Paint()
      ..color = accentColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    switch (kind) {
      case _GeometryKind.lines:
        _paintLines(canvas, size, line, accent);
      case _GeometryKind.angle:
        _paintRightAngle(canvas, size, line, accent);
      case _GeometryKind.figure:
        _paintFigure(canvas, size, line, accent);
      case _GeometryKind.circle:
        _paintCircle(canvas, size, line, accent);
    }
  }

  void _paintLines(
    Canvas canvas,
    Size size,
    Paint line,
    Paint accent,
  ) {
    if (taskKey.contains(':parallel:')) {
      final y1 = size.height * 0.36;
      final y2 = size.height * 0.66;
      canvas.drawLine(
        Offset(size.width * 0.12, y1),
        Offset(size.width * 0.88, y1),
        line,
      );
      canvas.drawLine(
        Offset(size.width * 0.12, y2),
        Offset(size.width * 0.88, y2),
        line,
      );
      _label(canvas, 'g', Offset(size.width * 0.10, y1 - 28));
      _label(canvas, 'h', Offset(size.width * 0.10, y2 + 8));
      _label(
        canvas,
        'gleicher Abstand',
        Offset(size.width * 0.58, size.height * 0.48),
        accentColor,
      );
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawLine(
      Offset(size.width * 0.12, center.dy),
      Offset(size.width * 0.88, center.dy),
      line,
    );
    canvas.drawLine(
      Offset(center.dx, size.height * 0.12),
      Offset(center.dx, size.height * 0.88),
      line,
    );
    _rightAngleMarker(canvas, center, accent);
  }

  void _paintRightAngle(
    Canvas canvas,
    Size size,
    Paint line,
    Paint accent,
  ) {
    final corner = Offset(size.width * 0.38, size.height * 0.68);
    canvas.drawLine(
      corner,
      Offset(size.width * 0.38, size.height * 0.18),
      line,
    );
    canvas.drawLine(
      corner,
      Offset(size.width * 0.82, size.height * 0.68),
      line,
    );
    _rightAngleMarker(canvas, corner, accent);
    _label(
      canvas,
      '90°',
      Offset(corner.dx + 38, corner.dy - 45),
      accentColor,
    );
  }

  void _paintFigure(
    Canvas canvas,
    Size size,
    Paint line,
    Paint accent,
  ) {
    final parts = taskKey.split(':');
    final variant = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
    final center = Offset(size.width / 2, size.height / 2);

    if (variant == 0) {
      final rect = Rect.fromCenter(
        center: center,
        width: 115,
        height: 115,
      );
      canvas.drawRect(rect, line);
      _rightAngleMarker(canvas, rect.bottomLeft, accent);
      return;
    }

    if (variant == 1) {
      final rect = Rect.fromCenter(
        center: center,
        width: 170,
        height: 100,
      );
      canvas.drawRect(rect, line);
      _rightAngleMarker(canvas, rect.bottomLeft, accent);
      return;
    }

    final top = Offset(center.dx, size.height * 0.18);
    final left = Offset(
      variant == 2 ? center.dx - 75 : center.dx - 95,
      size.height * 0.78,
    );
    final right = Offset(
      variant == 2 ? center.dx + 75 : center.dx + 60,
      size.height * 0.78,
    );
    final path = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(path, line);

    if (variant == 2) {
      _tick(canvas, _mid(top, left), accent);
      _tick(canvas, _mid(top, right), accent);
      _tick(canvas, _mid(left, right), accent);
    } else {
      _tick(canvas, _mid(top, left), accent);
      _tick(canvas, _mid(top, right), accent);
    }
  }

  void _paintCircle(
    Canvas canvas,
    Size size,
    Paint line,
    Paint accent,
  ) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.34;
    canvas.drawCircle(center, radius, line);
    canvas.drawCircle(
      center,
      5,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.fill,
    );

    if (taskKey.contains(':diameter:')) {
      canvas.drawLine(
        Offset(center.dx - radius, center.dy),
        Offset(center.dx + radius, center.dy),
        accent,
      );
      _label(
        canvas,
        'durch den Mittelpunkt',
        Offset(center.dx - 78, center.dy + 16),
        accentColor,
      );
    } else {
      canvas.drawLine(
        center,
        Offset(center.dx + radius, center.dy),
        accent,
      );
      _label(
        canvas,
        'vom Mittelpunkt zum Rand',
        Offset(center.dx - 45, center.dy + 16),
        accentColor,
      );
    }
  }

  void _rightAngleMarker(
    Canvas canvas,
    Offset corner,
    Paint paint,
  ) {
    const side = 22.0;
    final path = Path()
      ..moveTo(corner.dx, corner.dy - side)
      ..lineTo(corner.dx + side, corner.dy - side)
      ..lineTo(corner.dx + side, corner.dy);
    canvas.drawPath(path, paint);
  }

  void _tick(Canvas canvas, Offset point, Paint paint) {
    canvas.drawLine(
      Offset(point.dx - 6, point.dy - 7),
      Offset(point.dx + 6, point.dy + 7),
      paint,
    );
  }

  Offset _mid(Offset a, Offset b) =>
      Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);

  void _label(
    Canvas canvas,
    String text,
    Offset offset, [
    Color? color,
  ]) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color ?? lineColor,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 180);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _GeometryRelationPainter oldDelegate) =>
      oldDelegate.taskKey != taskKey ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.accentColor != accentColor;
}
