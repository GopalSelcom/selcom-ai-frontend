import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Receipt layout width in logical pixels (A4 width @ 72 dpi).
const double receiptLogicalWidth = 595;

/// PNG capture scale for gallery + PDF embedding (must match PDF point conversion).
const double receiptExportPixelRatio = 3.0;

/// High-resolution receipt PNG from screenshot capture.
class ReceiptPngCapture {
  const ReceiptPngCapture({
    required this.bytes,
    required this.pixelRatio,
  });

  final Uint8List bytes;
  final double pixelRatio;
}

/// Date and time parts for receipt header (bullet drawn separately for PDF safety).
class ReceiptDateTimeParts {
  const ReceiptDateTimeParts({required this.date, required this.time});

  final String date;
  final String time;
}

ReceiptDateTimeParts receiptDateTimeParts(DateTime dateTime) {
  return ReceiptDateTimeParts(
    date: DateFormat('MMMM dd, yyyy').format(dateTime),
    time: DateFormat('hh:mm a').format(dateTime),
  );
}

/// Loads SVG as-is from assets; applies runtime-only color fixes (does not edit files).
Future<String> loadReceiptSvgAsset(String assetPath) async {
  final raw = await rootBundle.loadString(assetPath);
  return raw.replaceAll('fill="#white"', 'fill="#FFFFFF"');
}

Widget receiptDateTimeRow({
  required DateTime dateTime,
  required TextStyle style,
}) {
  final parts = receiptDateTimeParts(dateTime);
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(parts.date, style: style),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text('\u2022', style: style),
      ),
      Text(parts.time, style: style),
    ],
  );
}

pw.Widget receiptDateTimeRowPdf({
  required DateTime dateTime,
  required PdfColor color,
  double fontSize = 10,
}) {
  final parts = receiptDateTimeParts(dateTime);
  return pw.Row(
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      pw.Text(
        parts.date,
        style: pw.TextStyle(fontSize: fontSize, color: color),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6),
        child: pw.Text(
          '\u2022',
          style: pw.TextStyle(fontSize: fontSize, color: color),
        ),
      ),
      pw.Text(
        parts.time,
        style: pw.TextStyle(fontSize: fontSize, color: color),
      ),
    ],
  );
}
