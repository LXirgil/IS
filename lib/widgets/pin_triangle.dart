import 'package:flutter/material.dart';

/// USBC標準的な三角形配置でピンを描画（残っているピンを強調）
class PinTriangle extends StatelessWidget {
  const PinTriangle({
    super.key,
    required this.standingPins,
    this.size = 120,
    this.highlightColor,
  });

  /// まだ立っているピン番号（1..10）。空ならストライク相当（全消し）
  final Set<int> standingPins;
  final double size;
  final Color? highlightColor;

  static const Map<int, Offset> _norm = {
    1: Offset(0.50, 0.08),
    2: Offset(0.38, 0.28),
    3: Offset(0.62, 0.28),
    4: Offset(0.28, 0.48),
    5: Offset(0.50, 0.48),
    6: Offset(0.72, 0.48),
    7: Offset(0.18, 0.72),
    8: Offset(0.40, 0.72),
    9: Offset(0.60, 0.72),
    10: Offset(0.82, 0.72),
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final on = highlightColor ?? scheme.primary;
    final off = scheme.surfaceContainerHighest;
    final border = scheme.outlineVariant;

    return SizedBox(
      width: size,
      height: size * 0.95,
      child: CustomPaint(
        painter: _PinPainter(
          standing: standingPins,
          onColor: on,
          offColor: off,
          borderColor: border,
        ),
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  _PinPainter({
    required this.standing,
    required this.onColor,
    required this.offColor,
    required this.borderColor,
  });

  final Set<int> standing;
  final Color onColor;
  final Color offColor;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide * 0.055;
    for (final e in PinTriangle._norm.entries) {
      final pin = e.key;
      final o = e.value;
      final c = Offset(o.dx * size.width, o.dy * size.height);
      final up = standing.contains(pin);
      final fill = Paint()..color = up ? onColor : offColor;
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = borderColor;
      canvas.drawCircle(c, r, fill);
      canvas.drawCircle(c, r, stroke);

      final tp = TextPainter(
        text: TextSpan(
          text: '$pin',
          style: TextStyle(
            fontSize: r * 1.35,
            color: up ? Colors.white : Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _PinPainter oldDelegate) {
    return oldDelegate.standing != standing ||
        oldDelegate.onColor != onColor ||
        oldDelegate.offColor != offColor;
  }
}
