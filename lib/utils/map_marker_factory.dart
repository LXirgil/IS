import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Google Maps 用カスタムマーカー（ボウリングピン付き）
class MapMarkerFactory {
  MapMarkerFactory._();

  static BitmapDescriptor? _bowlingAlley;
  static BitmapDescriptor? _savedAlley;

  static Future<BitmapDescriptor> bowlingAlley() async {
    _bowlingAlley ??= BitmapDescriptor.bytes(
      await _renderMarker(
        pinColor: const Color(0xFF3949AB),
        accentColor: const Color(0xFFFF7043),
        showStar: false,
      ),
      width: 96,
    );
    return _bowlingAlley!;
  }

  static Future<BitmapDescriptor> savedAlley() async {
    _savedAlley ??= BitmapDescriptor.bytes(
      await _renderMarker(
        pinColor: const Color(0xFFF57C00),
        accentColor: const Color(0xFFFFD54F),
        showStar: true,
      ),
      width: 96,
    );
    return _savedAlley!;
  }

  static Future<Uint8List> _renderMarker({
    required Color pinColor,
    required Color accentColor,
    required bool showStar,
  }) async {
    const w = 96.0;
    const h = 120.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));

    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.22);
    canvas.drawOval(Rect.fromCenter(center: Offset(w / 2, h - 6), width: 36, height: 10), shadow);

    final pinPath = Path()
      ..moveTo(w / 2, h - 4)
      ..quadraticBezierTo(w * 0.12, h * 0.55, w * 0.18, h * 0.32)
      ..arcToPoint(Offset(w * 0.82, h * 0.32), radius: const Radius.circular(34), clockwise: true)
      ..quadraticBezierTo(w * 0.88, h * 0.55, w / 2, h - 4)
      ..close();

    canvas.drawPath(pinPath, Paint()..color = pinColor);
    canvas.drawPath(
      pinPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Colors.white.withValues(alpha: 0.9),
    );

    void drawPin(Offset c, double r) {
      canvas.drawCircle(c, r, Paint()..color = Colors.white);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = accentColor,
      );
    }

    const cx = w / 2;
    const cy = h * 0.38;
    drawPin(const Offset(cx, cy - 10), 7);
    drawPin(Offset(cx - 12, cy + 10), 7);
    drawPin(Offset(cx + 12, cy + 10), 7);

    if (showStar) {
      _drawStar(canvas, const Offset(cx, cy + 2), 11, Colors.amber.shade700);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(w.toInt(), h.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  static void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    const points = 5;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius * 0.45;
      final angle = (i * math.pi / points) - math.pi / 2;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }
}
