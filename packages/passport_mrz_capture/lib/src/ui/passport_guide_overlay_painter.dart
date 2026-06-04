import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:passport_mrz_capture/src/layout/passport_guide_layout.dart';
class PassportGuideOverlayPainter extends CustomPainter {
  PassportGuideOverlayPainter({
    required this.hint,
    this.pulse = 0.0,
    this.mrzPulse = 0.0,
  });

  static const mrzBlue = Color(0xFF29B6F6);

  final PassportScanHint hint;
  final double pulse;
  /// 0..1 animated highlight on the MRZ band border.
  final double mrzPulse;

  @override
  void paint(Canvas canvas, Size size) {
    final guide = PassportGuideLayout.rectFor(size);
    final rrect = RRect.fromRectAndRadius(guide, const Radius.circular(12));

    final dim = Paint()..color = Colors.black.withValues(alpha: 0.62);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, dim);

    canvas.save();
    canvas.clipRRect(rrect);
    _drawPassportPlaceholder(canvas, guide);
    canvas.restore();

    final pulseWidth = hint == PassportScanHint.moveCloser ? 2.5 + pulse * 1.5 : 2.0;
    final border = Paint()
      ..color = hint.borderColor.withValues(
        alpha: hint == PassportScanHint.moveCloser ? 0.65 + pulse * 0.35 : 0.95,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = pulseWidth;
    canvas.drawRRect(rrect, border);

    if (hint == PassportScanHint.moveCloser ||
        hint == PassportScanHint.alignMrz ||
        hint == PassportScanHint.poorLighting ||
        hint == PassportScanHint.outOfFocus) {
      final corner = Paint()
        ..color = hint.borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      const len = 22.0;
      _drawCorner(canvas, guide.topLeft, len, corner, 1, 1);
      _drawCorner(canvas, guide.topRight, len, corner, -1, 1);
      _drawCorner(canvas, guide.bottomLeft, len, corner, 1, -1);
      _drawCorner(canvas, guide.bottomRight, len, corner, -1, -1);
    }

    _drawAnimatedMrzBand(canvas, guide);
  }

  void _drawAnimatedMrzBand(Canvas canvas, Rect guide) {
    final inner = guide.deflate(18);
    final mrzRect = PassportGuideLayout.mrzBandRectInInner(inner);
    final mrzRrect = RRect.fromRectAndRadius(mrzRect, const Radius.circular(4));

    final fillAlpha = 0.10 + mrzPulse * 0.14;
    canvas.drawRRect(
      mrzRrect,
      Paint()
        ..color = mrzBlue.withValues(alpha: fillAlpha)
        ..style = PaintingStyle.fill,
    );

    final borderAlpha = 0.55 + mrzPulse * 0.45;
    final borderWidth = 2.2 + mrzPulse * 2.3;
    canvas.drawRRect(
      mrzRrect,
      Paint()
        ..color = mrzBlue.withValues(alpha: borderAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );

    // Outer glow so the band reads clearly against the passport art.
    canvas.drawRRect(
      mrzRrect.inflate(3),
      Paint()
        ..color = mrzBlue.withValues(alpha: 0.18 + mrzPulse * 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _drawCorner(
    Canvas canvas,
    Offset origin,
    double len,
    Paint paint,
    int dx,
    int dy,
  ) {
    canvas.drawLine(origin, origin + Offset(len * dx, 0), paint);
    canvas.drawLine(origin, origin + Offset(0, len * dy), paint);
  }

  void _drawPassportPlaceholder(Canvas canvas, Rect guide) {
    final outline = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        guide.deflate(10),
        const Radius.circular(6),
      ),
      outline,
    );

    final inner = guide.deflate(18);
    final photoW = inner.width * 0.28;
    final photo = Rect.fromLTWH(
      inner.left,
      inner.top,
      photoW,
      inner.height * 0.42,
    );
    final photoFill = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    final photoStroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(photo, const Radius.circular(4)),
      photoFill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(photo, const Radius.circular(4)),
      photoStroke,
    );
    _drawPersonIcon(canvas, photo);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final textLeft = photo.right + 12;
    final textRight = inner.right;
    for (var i = 0; i < 4; i++) {
      final y = inner.top + 14 + i * (inner.height * 0.09);
      final w = textRight - textLeft - (i * 12);
      canvas.drawLine(Offset(textLeft, y), Offset(textLeft + w, y), linePaint);
    }

    final mrzRect = PassportGuideLayout.mrzBandRectInInner(inner);

    final mrzLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.4;
    final mrzY1 = mrzRect.top + mrzRect.height * 0.35;
    final mrzY2 = mrzRect.top + mrzRect.height * 0.72;
    canvas.drawLine(
      Offset(mrzRect.left + 8, mrzY1),
      Offset(mrzRect.right - 8, mrzY1),
      mrzLine,
    );
    canvas.drawLine(
      Offset(mrzRect.left + 8, mrzY2),
      Offset(mrzRect.right - 8, mrzY2),
      mrzLine,
    );
    _drawChevrons(canvas, mrzRect, mrzY1);
    _drawChevrons(canvas, mrzRect, mrzY2);
  }

  void _drawPersonIcon(Canvas canvas, Rect photo) {
    final cx = photo.center.dx;
    final cy = photo.center.dy;
    final icon = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(Offset(cx, cy - 8), photo.width * 0.14, icon);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, cy + 22),
        width: photo.width * 0.5,
        height: photo.height * 0.35,
      ),
      math.pi,
      math.pi,
      false,
      icon,
    );
  }

  void _drawChevrons(Canvas canvas, Rect mrz, double y) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var x = mrz.left + 12; x < mrz.right - 20; x += 10) {
      final path = Path()
        ..moveTo(x, y - 3)
        ..lineTo(x + 5, y)
        ..lineTo(x, y + 3);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant PassportGuideOverlayPainter oldDelegate) {
    return oldDelegate.hint != hint ||
        (oldDelegate.pulse - pulse).abs() > 0.02 ||
        (oldDelegate.mrzPulse - mrzPulse).abs() > 0.02;
  }
}
