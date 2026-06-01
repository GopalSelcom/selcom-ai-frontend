import 'dart:io';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/models/ride_management_models.dart';
import 'receipt_image_generator.dart';

/// Builds a PDF by embedding the same high-resolution receipt PNG used for gallery download.
class ReceiptPdfGenerator {
  static Future<File> generateReceiptPdf({
    required ReceiptModel receipt,
  }) async {
    final capture = await ReceiptImageGenerator.generateReceiptPngBytes(
      receipt: receipt,
    );

    final codec = await ui.instantiateImageCodec(capture.bytes);
    final frame = await codec.getNextFrame();
    final imageWidthPx = frame.image.width.toDouble();
    final imageHeightPx = frame.image.height.toDouble();
    frame.image.dispose();

    // Map physical pixels back to PDF points (72 dpi) using the capture pixel ratio.
    final pageWidth = imageWidthPx / capture.pixelRatio;
    final pageHeight = imageHeightPx / capture.pixelRatio;

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(pageWidth, pageHeight, marginAll: 0),
        build: (pw.Context context) {
          return pw.Image(
            pw.MemoryImage(capture.bytes),
            width: pageWidth,
            height: pageHeight,
            fit: pw.BoxFit.fill,
          );
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/receipt_${receipt.rideId}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
