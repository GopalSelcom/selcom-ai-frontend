import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../data/models/ride_management_models.dart';
import 'receipt_format_utils.dart';

class ReceiptImageGenerator {
  /// Allow vector assets (logo + route pins) to finish rasterizing before capture.
  static const Duration _captureDelay = Duration(milliseconds: 500);

  static const Color _primary = AppColors.primary;
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textMid = Color(0xFF555566);
  static const Color _textLight = Color(0xFF999AAB);
  static const Color _divider = Color(0xFFEEEEF2);
  static const Color _bgLight = Color(0xFFF8F8FA);

  static Future<ReceiptPngCapture> generateReceiptPngBytes({
    required ReceiptModel receipt,
  }) async {
    final logoSvg = await loadReceiptSvgAsset(
      AppAssets.selcomGoLogoPrimaryColor,
    );
    final screenshotController = ScreenshotController();

    final captureContext = Get.context;
    final pixelRatio = captureContext != null
        ? MediaQuery.devicePixelRatioOf(
            captureContext,
          ).clamp(2.0, receiptExportPixelRatio)
        : receiptExportPixelRatio;

    final widget = RepaintBoundary(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          color: Colors.white,
          child: Container(
            width: receiptLogicalWidth,
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopBanner(receipt, logoSvg: logoSvg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 24,
                  ),
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
      ),
    );

    // Long-widget capture; delay + pixelRatio matter once multiple SVGs are in the tree.
    final Uint8List imageBytes = await screenshotController
        .captureFromLongWidget(
          widget,
          context: captureContext,
          delay: _captureDelay,
          pixelRatio: pixelRatio,
        );

    return ReceiptPngCapture(bytes: imageBytes, pixelRatio: pixelRatio);
  }

  static Future<File> generateReceiptImage({
    required ReceiptModel receipt,
  }) async {
    final capture = await generateReceiptPngBytes(receipt: receipt);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/receipt_${receipt.rideId}.png');
    await file.writeAsBytes(capture.bytes);
    return file;
  }

  // ── Sections ──────────────────────────────────────────────────────────────

  static Widget _buildTopBanner(
    ReceiptModel receipt, {
    required String logoSvg,
  }) {
    final completedAt = receipt.completedAt != null
        ? DateTime.parse(receipt.completedAt!).toLocal()
        : DateTime.now();
    const dateStyle = TextStyle(fontSize: 10, color: _textMid);

    return Container(
      padding: const EdgeInsets.only(left: 36, right: 36, top: 48, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.rideReceipt.tr,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 6),
              receiptDateTimeRow(dateTime: completedAt, style: dateStyle),
              const SizedBox(height: 2),
              Text(
                AppStrings.refWithId.trParams({'id': receipt.rideId}).tr,
                style: const TextStyle(fontSize: 9, color: _textLight),
              ),
            ],
          ),
          SizedBox(
            width: 120,
            height: 48,
            child: SvgPicture.string(
              logoSvg,
              width: 120,
              height: 48,
              fit: BoxFit.contain,
              allowDrawingOutsideViewBox: true,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildRouteSection(ReceiptModel receipt) {
    // Filter stops to avoid duplicating final destination
    final filteredStops = receipt.stops.where((s) {
      final stopAddr = s.address.trim().toLowerCase();
      final endAddr = receipt.destinationAddress.trim().toLowerCase();
      return stopAddr != endAddr;
    }).toList();

    final bool isMulti = filteredStops.isNotEmpty;
    const letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];

    final children = <Widget>[
      _sectionLabel(AppStrings.route.tr),
      const SizedBox(height: 12),
      _routeStop(
        label: AppStrings.pickup.tr,
        address: receipt.pickupAddress,
        icon: _buildLetterIcon(
          isMulti ? 'A' : 'P',
          color: AppColors.mapPickupMarkerBlue,
        ),
      ),
    ];

    for (int i = 0; i < filteredStops.length; i++) {
      children.add(
        Container(
          margin: const EdgeInsets.only(left: 11, top: 2, bottom: 2),
          width: 2,
          height: 16,
          color: _divider,
        ),
      );
      children.add(
        _routeStop(
          label: '${AppStrings.stop.tr} ${i + 1}',
          address: filteredStops[i].address,
          icon: _buildLetterIcon(
            letters[i + 1],
            color: AppColors.mapStopMarkerRed,
          ),
        ),
      );
    }

    children.add(
      Container(
        margin: const EdgeInsets.only(left: 11, top: 2, bottom: 2),
        width: 2,
        height: 16,
        color: _divider,
      ),
    );

    children.add(
      _routeStop(
        label: AppStrings.dropoff.tr,
        address: receipt.destinationAddress,
        icon: _buildLetterIcon(
          isMulti ? letters[filteredStops.length + 1] : 'D',
          color: AppColors.mapDropMarkerGreen,
        ),
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        color: _bgLight,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  static Widget _buildLetterIcon(String label, {required Color color}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  static Widget _routeStop({
    required String label,
    required String address,
    required Widget icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        icon,
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
                address.isEmpty ? AppStrings.emDash.tr : address,
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
          label: AppStrings.distance.tr,
          value: '${receipt.distanceKm.toStringAsFixed(2)} km',
        ),
        const SizedBox(width: 12),
        _infoChip(
          icon: '⏱',
          label: AppStrings.duration.tr,
          value: '${receipt.durationMinutes} min',
        ),
        const SizedBox(width: 12),
        _infoChip(
          icon: '💳',
          label: AppStrings.payment.tr,
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
          _sectionLabel(AppStrings.driverAndVehicle.tr),
          const SizedBox(height: 12),
          _detailRow(
            AppStrings.driver.tr,
            receipt.driverName ?? AppStrings.emDash.tr,
          ),
          if (receipt.vehicleType != null)
            _detailRow(AppStrings.vehicleType.tr, receipt.vehicleType!),
          if (receipt.vehicleModel != null)
            _detailRow(AppStrings.model.tr, receipt.vehicleModel!),
          if (receipt.vehicleColor != null)
            _detailRow(AppStrings.colour.tr, receipt.vehicleColor!),
          if (receipt.vehicleRegistration != null)
            _detailRow(AppStrings.plate.tr, receipt.vehicleRegistration!),
        ],
      ),
    );
  }

  static Widget _buildFareSection(ReceiptModel receipt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(AppStrings.fareBreakdown.tr),
        const SizedBox(height: 12),
        Container(
          decoration: const BoxDecoration(
            color: _bgLight,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _fareRow(
                AppStrings.baseFare.tr,
                receipt.baseFare,
                receipt.currency,
              ),
              _fareRow(
                AppStrings.distanceCharge.tr,
                receipt.distanceCharge,
                receipt.currency,
              ),
              _fareRow(
                AppStrings.timeCharge.tr,
                receipt.timeCharge,
                receipt.currency,
              ),
              if (receipt.promoDiscountAmount > 0 &&
                  (receipt.promoCode?.trim().isNotEmpty ?? false))
                _fareRow(
                  AppStrings.receiptPromoLine.trParams({
                    'code': receipt.promoCode!.trim(),
                  }).tr,
                  -receipt.promoDiscountAmount,
                  receipt.currency,
                  valueColor: Colors.green.shade700,
                ),
              if (receipt.discount > 0)
                _fareRow(
                  AppStrings.discount.tr,
                  -receipt.discount,
                  receipt.currency,
                  valueColor: Colors.green.shade700,
                ),
              if (receipt.tax > 0)
                _fareRow(AppStrings.tax.tr, receipt.tax, receipt.currency),
              const SizedBox(height: 8),
              const Divider(color: _divider, height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.total.tr,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatPayableOrFree(
                      receipt.total,
                      receipt.currency,
                      freeLabel: AppStrings.rideFreeLabel.tr,
                    ),
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
          Text(label, style: const TextStyle(fontSize: 12, color: _textMid)),
          Text(
            CurrencyFormatter.formatWithApiCurrency(amount, currency),
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
      child: Center(
        child: Text(
          AppStrings.thankYouForRidingWithSelcomGo.tr,
          style: const TextStyle(fontSize: 11, color: _textLight),
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
          Text(label, style: const TextStyle(fontSize: 12, color: _textMid)),
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
        return AppStrings.wallet.tr;
      case 'selcompesa':
      case 'selcom_pesa':
        return AppStrings.selcomPesa.tr;
      case 'mobile_money':
      case 'mobilemoney':
        return AppStrings.mobileMoney.tr;
      case 'card':
        return AppStrings.card.tr;
      default:
        return raw.isEmpty ? AppStrings.emDash.tr : raw;
    }
  }
}
