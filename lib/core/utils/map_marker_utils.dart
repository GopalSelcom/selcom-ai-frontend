import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_colors.dart';

class MapMarkerUtils {
  /// Resizes an image asset to be used as a Google Maps marker.
  static Future<BitmapDescriptor> getResizedMarker(
    String path,
    int width,
  ) async {
    final ByteData data = await rootBundle.load(path);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? bytes = await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  /// Creates a circular marker with a colored border and white center.
  /// Used for Pickup and Drop-off points.
  static Future<BitmapDescriptor> createCustomCircleMarker({
    required Color color,
    int size = 60,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);

    // Outer circle (Color)
    final outerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size * 0.4, outerPaint);

    // Inner circle (White)
    final innerPaint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size * 0.2, innerPaint);

    final image = await recorder.endRecording().toImage(size, size);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  /// Creates a circular marker with a letter or number inside.
  static Future<BitmapDescriptor> createTextMarker({
    required String text,
    required Color color,
    int size = 90,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);

    // Outer circle with subtle "shadow" (Darker version of color)
    final shadowPaint = Paint()
      ..color = AppColors.black.withOpacity(0.1)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(center + const Offset(1, 1), size * 0.45, shadowPaint);

    // Main Circle (Solid Color)
    final mainPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size * 0.42, mainPaint);

    // White Border
    final borderPaint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.05;
    canvas.drawCircle(center, size * 0.42, borderPaint);

    // Text (Letter/Number) - White
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: AppColors.white,
          fontSize: size * 0.45,
          fontWeight: FontWeight.w800, // Extra bold
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      center -
          Offset(
            textPainter.width / 2,
            (textPainter.height / 2) + (size * 0.02),
          ),
    );

    final image = await recorder.endRecording().toImage(size, size);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  /// Creates a text marker (e.g. P / D) with an edit badge.
  static Future<BitmapDescriptor> createEditableTextMarker({
    required String text,
    required Color color,
    // Increase this to make the whole marker wider/bigger.
    int markerWidth = 120,
    Color editBadgeColor = AppColors.primary,
    Color editIconColor = AppColors.primary,
  }) async {
    final size = markerWidth;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final markerHeight = (size * 0.72).roundToDouble();
    final markerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size * 0.10,
        size * 0.18,
        size * 0.80,
        markerHeight * 0.62,
      ),
      Radius.circular(size * 0.16),
    );

    // Main rounded marker body (not circle)
    final shadowPaint = Paint()
      ..color = AppColors.black.withOpacity(0.14)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawRRect(
      markerRect.shift(const Offset(1, 1)),
      shadowPaint,
    );

    final mainPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRRect(markerRect, mainPaint);

    final borderPaint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.04;
    canvas.drawRRect(markerRect, borderPaint);

    // Bottom pointer (pin tip)
    final pointerPath = Path()
      ..moveTo(size * 0.42, markerRect.bottom)
      ..lineTo(size * 0.50, markerHeight * 0.92)
      ..lineTo(size * 0.58, markerRect.bottom)
      ..close();
    canvas.drawPath(pointerPath, mainPaint);
    canvas.drawPath(pointerPath, borderPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: "$text ${String.fromCharCode(Icons.edit.codePoint)}",
        style: TextStyle(
          color: AppColors.white,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w800,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        markerRect.center.dx - (textPainter.width / 2),
        markerRect.center.dy - (textPainter.height / 2),
      ),
    );

    // Edit badge
    // final badgeCenter = Offset(markerRect.right, markerRect.top);
    // final badgeRadius = size * 0.13;
    // final badgePaint = Paint()
    //   ..color = editBadgeColor
    //   ..style = PaintingStyle.fill;
    // canvas.drawCircle(badgeCenter, badgeRadius, badgePaint);

    // final badgeBorderPaint = Paint()
    //   ..color = AppColors.white
    //   ..style = PaintingStyle.stroke
    //   ..strokeWidth = size * 0.03;
    // canvas.drawCircle(badgeCenter, badgeRadius, badgeBorderPaint);

    // final editIconPainter = TextPainter(
    //   text: TextSpan(
    //     text: String.fromCharCode(Icons.edit.codePoint),
    //     style: TextStyle(
    //       color: editIconColor,
    //       fontSize: size * 0.40,
    //       fontFamily: Icons.edit.fontFamily,
    //       package: Icons.edit.fontPackage,
    //       fontWeight: FontWeight.w700,
    //       height: 1.0,
    //     ),
    //   ),
    //   textDirection: TextDirection.ltr,
    // );
    // editIconPainter.layout();
    // editIconPainter.paint(
    //   canvas,
    //       Offset(editIconPainter.width / 2, editIconPainter.height / 2),
    // );

    final image = await recorder.endRecording().toImage(size, size);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }
}
