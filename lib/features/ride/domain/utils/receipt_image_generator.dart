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
import '../../../../shared/widgets/app_route_location_pin_icon.dart';
import '../../data/models/ride_management_models.dart';
import 'receipt_format_utils.dart';

class ReceiptImageGenerator {
  /// Allow vector assets (logo + route pins) to finish rasterizing before capture.
  static const Duration _captureDelay = Duration(milliseconds: 500);

  /// Receipt route pins — fixed px (no ScreenUtil) for PNG/PDF capture.
  static const double _routePinSize = 13;
  static const double _routePinSlotHeight = 16;
  static const double _routeIconColumnWidth = 16;

  static Future<ReceiptPngCapture> generateReceiptPngBytes({
    required ReceiptModel receipt,
  }) async {
    final logoSvg = await loadReceiptSvgAsset(AppAssets.selcomGoLogo);
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
          color: AppColors.white,
          child: Container(
            width: receiptLogicalWidth,
            color: AppColors.white,
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
    const dateStyle = TextStyle(fontSize: 10, color: AppColors.receiptTextMid);

    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.only(left: 36, right: 36, top: 36, bottom: 24),
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
                  color: AppColors.receiptTextDark,
                ),
              ),
              const SizedBox(height: 6),
              receiptDateTimeRow(dateTime: completedAt, style: dateStyle),
              const SizedBox(height: 2),
              Text(
                AppStrings.refWithId.trParams({'id': receipt.rideId}).tr,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.receiptTextMuted,
                ),
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
    final filteredStops = receipt.stops.where((s) {
      final stopAddr = s.address.trim().toLowerCase();
      final endAddr = receipt.destinationAddress.trim().toLowerCase();
      return stopAddr != endAddr;
    }).toList();

    final rows = <Widget>[
      _routeTimelineRow(
        label: AppStrings.pickup.tr,
        address: receipt.pickupAddress,
        icon: AppRouteLocationPinIcon.pickup(size: _routePinSize),
        showConnectorBelow: true,
        iconTopInset: 0,
      ),
    ];

    for (int i = 0; i < filteredStops.length; i++) {
      rows.add(
        _routeTimelineRow(
          label: '${AppStrings.stop.tr} ${i + 1}',
          address: filteredStops[i].address,
          icon: AppRouteLocationPinIcon.stop(i, size: _routePinSize),
          showConnectorBelow: true,
          iconTopInset: 2,
        ),
      );
    }

    rows.add(
      _routeTimelineRow(
        label: AppStrings.dropoff.tr,
        address: receipt.destinationAddress,
        icon: AppRouteLocationPinIcon.destination(size: _routePinSize),
        showConnectorBelow: false,
        iconTopInset: 2,
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.receiptBgLight,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(AppStrings.route.tr),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  static Widget _routeTimelineRow({
    required String label,
    required String address,
    required Widget icon,
    required bool showConnectorBelow,
    double iconTopInset = 0,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _routeIconColumnWidth,
            child: Column(
              children: [
                if (iconTopInset > 0) SizedBox(height: iconTopInset),
                SizedBox(
                  height: _routePinSlotHeight,
                  width: _routeIconColumnWidth,
                  child: Center(
                    child: FittedBox(fit: BoxFit.contain, child: icon),
                  ),
                ),
                if (showConnectorBelow)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 1.5),
                        color: AppColors.receiptDivider,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: iconTopInset,
                bottom: showConnectorBelow ? 9 : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 8,
                      color: AppColors.receiptTextMuted,
                    ),
                  ),
                  Text(
                    address.isEmpty ? AppStrings.emDash.tr : address,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.receiptTextDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildInfoRow(ReceiptModel receipt) {
    return Row(
      children: [
        _infoChip(
          icon: '📍',
          label: AppStrings.distance.tr,
          value: AppStrings.distanceKmFormat.trParams({
            'value': receipt.distanceKm.toStringAsFixed(2),
          }),
        ),
        const SizedBox(width: 12),
        _infoChip(
          icon: '⏱',
          label: AppStrings.duration.tr,
          value: AppStrings.minutesShortCount.trParams({
            'count': '${receipt.durationMinutes}',
          }),
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
          color: AppColors.receiptBgLight,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 8,
                color: AppColors.receiptTextMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.receiptTextDark,
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
        color: AppColors.receiptBgLight,
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
            color: AppColors.receiptBgLight,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _fareRow(
                AppStrings.rideCharge.tr,
                receipt.totalFare,
                receipt.currency,
              ),
              _fareRow(
                AppStrings.bookingFeesAndConvenienceCharges.tr,
                receipt.bookingFee,
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
                  valueColor: AppColors.iconSuccess,
                ),
              if (receipt.discount > 0)
                _fareRow(
                  AppStrings.discount.tr,
                  -receipt.discount,
                  receipt.currency,
                  valueColor: AppColors.iconSuccess,
                ),
              if (receipt.tax > 0)
                _fareRow(AppStrings.tax.tr, receipt.tax, receipt.currency),
              const SizedBox(height: 8),
              const Divider(color: AppColors.receiptDivider, height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.totalAmount.tr,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.receiptTextDark,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatPayableOrFree(
                      receipt.totalAmount,
                      receipt.currency,
                      freeLabel: AppStrings.rideFreeLabel.tr,
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
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
    Color valueColor = AppColors.receiptTextMid,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.receiptTextMid,
            ),
          ),
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
        border: Border(
          top: BorderSide(color: AppColors.receiptDivider, width: 1),
        ),
      ),
      padding: const EdgeInsets.only(top: 16),
      child: Center(
        child: Text(
          AppStrings.thankYouForRidingWithSelcomGo.tr,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.receiptTextMuted,
          ),
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
        color: AppColors.receiptTextMuted,
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
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.receiptTextMid,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.receiptTextDark,
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
