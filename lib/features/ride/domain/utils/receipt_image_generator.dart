import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../data/models/ride_management_models.dart';

class ReceiptImageGenerator {
  static const Color _primary = Color(0xFFF3004C);
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textMid = Color(0xFF555566);
  static const Color _textLight = Color(0xFF999AAB);
  static const Color _divider = Color(0xFFEEEEF2);
  static const Color _bgLight = Color(0xFFF8F8FA);

  static Future<File> generateReceiptImage({
    required ReceiptModel receipt,
  }) async {
    final String svgString =
        await rootBundle.loadString(AppAssets.selcomGoLogoRedSvg);

    final screenshotController = ScreenshotController();

    final widget = Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: Colors.white,
        child: Container(
          width: 595, // A4 width at 72dpi
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBanner(svgString, receipt),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRouteSection(receipt),
                    const SizedBox(height: 24),
                    _buildInfoRow(receipt),
                    const SizedBox(height: 24),
                    if (receipt.driverName != null) ...[
                      _buildDriverSection(receipt),
                      const SizedBox(height: 24),
                    ],
                    _buildFareSection(receipt),
                    const SizedBox(height: 32),
                    _buildFooter(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Use long-widget capture to avoid vertical overflow for tall receipts.
    final Uint8List imageBytes = await screenshotController.captureFromLongWidget(
      widget,
      context: null,
      delay: const Duration(milliseconds: 50), // slight delay to ensure rendering
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/receipt_${receipt.rideId}.png');
    await file.writeAsBytes(imageBytes);
    return file;
  }

  // ── Sections ──────────────────────────────────────────────────────────────

  static Widget _buildTopBanner(String svgString, ReceiptModel receipt) {
    final dateStr = receipt.completedAt != null
        ? DateFormat('MMMM dd, yyyy  •  hh:mm a')
            .format(DateTime.parse(receipt.completedAt!).toLocal())
        : DateFormat('MMMM dd, yyyy  •  hh:mm a').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.only(left: 36, right: 36, top: 48, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ride Receipt',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 10,
                  color: _textMid,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Ref: ${receipt.rideId}',
                style: const TextStyle(
                  fontSize: 9,
                  color: _textLight,
                ),
              ),
            ],
          ),
          SvgPicture.string(
            svgString,
            width: 120,
            colorFilter: const ColorFilter.mode(_primary, BlendMode.srcIn),
          ),
        ],
      ),
    );
  }

  static Widget _buildRouteSection(ReceiptModel receipt) {
    return Container(
      decoration: const BoxDecoration(
        color: _bgLight,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Route'),
          const SizedBox(height: 12),
          _routeStop(
            label: 'Pickup',
            address: receipt.pickupAddress,
            dot: Colors.green.shade700,
          ),
          Container(
            margin: const EdgeInsets.only(left: 5, top: 2, bottom: 2),
            width: 2,
            height: 16,
            color: _divider,
          ),
          _routeStop(
            label: 'Dropoff',
            address: receipt.destinationAddress,
            dot: _primary,
          ),
        ],
      ),
    );
  }

  static Widget _routeStop({
    required String label,
    required String address,
    required Color dot,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 3),
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(fontSize: 8, color: _textLight),
              ),
              Text(
                address.isEmpty ? '—' : address,
                style: const TextStyle(fontSize: 12, color: _textDark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildInfoRow(ReceiptModel receipt) {
    return Row(
      children: [
        _infoChip(
          icon: '📍',
          label: 'Distance',
          value: '${receipt.distanceKm.toStringAsFixed(2)} km',
        ),
        const SizedBox(width: 12),
        _infoChip(
          icon: '⏱',
          label: 'Duration',
          value: '${receipt.durationMinutes} min',
        ),
        const SizedBox(width: 12),
        _infoChip(
          icon: '💳',
          label: 'Payment',
          value: _formatPayment(receipt.paymentMethod),
        ),
      ],
    );
  }

  static Widget _infoChip({
    required String icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
          color: _bgLight,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(fontSize: 8, color: _textLight),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildDriverSection(ReceiptModel receipt) {
    return Container(
      decoration: const BoxDecoration(
        color: _bgLight,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Driver & Vehicle'),
          const SizedBox(height: 12),
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

  static Widget _buildFareSection(ReceiptModel receipt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Fare Breakdown'),
        const SizedBox(height: 12),
        Container(
          decoration: const BoxDecoration(
            color: _bgLight,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
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
                  valueColor: Colors.green.shade700,
                ),
              if (receipt.tax > 0)
                _fareRow('Tax', receipt.tax, receipt.currency),
              const SizedBox(height: 8),
              const Divider(color: _divider, height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(receipt.total),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
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

  static Widget _fareRow(
    String label,
    int amount,
    String currency, {
    Color valueColor = _textMid,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: _textMid),
          ),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(fontSize: 12, color: valueColor),
          ),
        ],
      ),
    );
  }

  static Widget _buildFooter() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _divider, width: 1)),
      ),
      padding: const EdgeInsets.only(top: 16),
      child: const Center(
        child: Text(
          'Thank you for riding with Selcom Go!',
          style: TextStyle(fontSize: 11, color: _textLight),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: _textLight,
        letterSpacing: 1.2,
      ),
    );
  }

  static Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: _textMid),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
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
