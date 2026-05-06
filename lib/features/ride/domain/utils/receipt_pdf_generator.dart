import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/constants/app_assets.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../data/models/ride_management_models.dart';

// Brand colours (matching Selcom Go)
const _primary = PdfColor.fromInt(0xFFF3004C); // Red
const _textDark = PdfColor.fromInt(0xFF1A1A2E);
const _textMid = PdfColor.fromInt(0xFF555566);
const _textLight = PdfColor.fromInt(0xFF999AAB);
const _divider = PdfColor.fromInt(0xFFEEEEF2);
const _bgLight = PdfColor.fromInt(0xFFF8F8FA);

class ReceiptPdfGenerator {
  static Future<File> generateReceiptPdf({
    required ReceiptModel receipt,
  }) async {
    final ByteData logoData = await rootBundle.load(AppAssets.selcomGoLogoPng);
    final pw.MemoryImage logoImage = pw.MemoryImage(
      logoData.buffer.asUint8List(),
    );

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildTopBanner(logoImage, receipt),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 24,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildRouteSection(receipt),
                    pw.SizedBox(height: 24),
                    _buildInfoRow(receipt),
                    pw.SizedBox(height: 24),
                    if (receipt.driverName != null) ...[
                      _buildDriverSection(receipt),
                      pw.SizedBox(height: 24),
                    ],
                    _buildFareSection(receipt),
                    pw.SizedBox(height: 32),
                    _buildFooter(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/receipt_${receipt.rideId}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ── Sections ──────────────────────────────────────────────────────────────

  static pw.Widget _buildTopBanner(pw.MemoryImage logo, ReceiptModel receipt) {
    final dateStr = receipt.completedAt != null
        ? DateFormat(
            'MMMM dd, yyyy  •  hh:mm a',
          ).format(DateTime.parse(receipt.completedAt!).toLocal())
        : DateFormat('MMMM dd, yyyy  •  hh:mm a').format(DateTime.now());

    return pw.Container(
      padding: const pw.EdgeInsets.only(left: 36, right: 36, top: 48, bottom: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Ride Receipt',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: _textDark,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                dateStr,
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: _textMid,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Ref: ${receipt.rideId}',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: _textLight,
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: const pw.BoxDecoration(
              color: _primary,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Image(logo, width: 80, fit: pw.BoxFit.contain),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildRouteSection(ReceiptModel receipt) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        color: _bgLight,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionLabel('Route'),
          pw.SizedBox(height: 12),
          _routeStop(
            label: 'Pickup',
            address: receipt.pickupAddress,
            dot: PdfColors.green700,
          ),
          pw.SizedBox(height: 2),
          pw.Container(
            margin: const pw.EdgeInsets.only(left: 5),
            width: 2,
            height: 16,
            color: _divider,
          ),
          pw.SizedBox(height: 2),
          _routeStop(
            label: 'Dropoff',
            address: receipt.destinationAddress,
            dot: _primary,
          ),
        ],
      ),
    );
  }

  static pw.Widget _routeStop({
    required String label,
    required String address,
    required PdfColor dot,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 3),
          width: 10,
          height: 10,
          decoration: pw.BoxDecoration(color: dot, shape: pw.BoxShape.circle),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                label.toUpperCase(),
                style: const pw.TextStyle(fontSize: 8, color: _textLight),
              ),
              pw.Text(
                address.isEmpty ? '—' : address,
                style: const pw.TextStyle(fontSize: 12, color: _textDark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInfoRow(ReceiptModel receipt) {
    return pw.Row(
      children: [
        _infoChip(
          icon: '📍',
          label: 'Distance',
          value: '${receipt.distanceKm.toStringAsFixed(2)} km',
        ),
        pw.SizedBox(width: 12),
        _infoChip(
          icon: '⏱',
          label: 'Duration',
          value: '${receipt.durationMinutes} min',
        ),
        pw.SizedBox(width: 12),
        _infoChip(
          icon: '💳',
          label: 'Payment',
          value: _formatPayment(receipt.paymentMethod),
        ),
      ],
    );
  }

  static pw.Widget _infoChip({
    required String icon,
    required String label,
    required String value,
  }) {
    return pw.Expanded(
      child: pw.Container(
        decoration: const pw.BoxDecoration(
          color: _bgLight,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label.toUpperCase(),
              style: const pw.TextStyle(fontSize: 8, color: _textLight),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: _textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildDriverSection(ReceiptModel receipt) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        color: _bgLight,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionLabel('Driver & Vehicle'),
          pw.SizedBox(height: 12),
          _detailRow('Driver', receipt.driverName ?? '—'),
          if (receipt.vehicleType != null)
            _detailRow('Vehicle Type', receipt.vehicleType!),
          if (receipt.vehicleModel != null)
            _detailRow('Model', receipt.vehicleModel!),
          if (receipt.vehicleColor != null)
            _detailRow('Colour', receipt.vehicleColor!),
          if (receipt.vehicleRegistration != null)
            _detailRow('Plate', receipt.vehicleRegistration!),
        ],
      ),
    );
  }

  static pw.Widget _buildFareSection(ReceiptModel receipt) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionLabel('Fare Breakdown'),
        pw.SizedBox(height: 12),
        pw.Container(
          decoration: const pw.BoxDecoration(
            color: _bgLight,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
          ),
          padding: const pw.EdgeInsets.all(16),
          child: pw.Column(
            children: [
              _fareRow('Base Fare', receipt.baseFare, receipt.currency),
              _fareRow(
                'Distance Charge',
                receipt.distanceCharge,
                receipt.currency,
              ),
              _fareRow('Time Charge', receipt.timeCharge, receipt.currency),
              if (receipt.discount > 0)
                _fareRow(
                  'Discount',
                  -receipt.discount,
                  receipt.currency,
                  valueColor: PdfColors.green700,
                ),
              if (receipt.tax > 0)
                _fareRow('Tax', receipt.tax, receipt.currency),
              pw.SizedBox(height: 8),
              pw.Divider(color: _divider),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total',
                    style: pw.TextStyle(
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                  pw.Text(
                    CurrencyFormatter.format(receipt.total),
                    style: pw.TextStyle(
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                      color: _primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _fareRow(
    String label,
    int amount,
    String currency, {
    PdfColor valueColor = _textMid,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 12, color: _textMid),
          ),
          pw.Text(
            CurrencyFormatter.format(amount),
            style: pw.TextStyle(fontSize: 12, color: valueColor),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _divider, width: 1)),
      ),
      padding: const pw.EdgeInsets.only(top: 16),
      child: pw.Center(
        child: pw.Text(
          'Thank you for riding with Selcom Go!',
          style: const pw.TextStyle(fontSize: 11, color: _textLight),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static pw.Widget _sectionLabel(String text) {
    return pw.Text(
      text.toUpperCase(),
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: _textLight,
        letterSpacing: 1.2,
      ),
    );
  }

  static pw.Widget _detailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 12, color: _textMid),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatPayment(String raw) {
    switch (raw.toLowerCase()) {
      case 'wallet':
        return 'Wallet';
      case 'selcompesa':
      case 'selcom_pesa':
        return 'Selcom Pesa';
      case 'mobile_money':
      case 'mobilemoney':
        return 'Mobile Money';
      case 'card':
        return 'Card';
      default:
        return raw.isEmpty ? '—' : raw;
    }
  }
}
