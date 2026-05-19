import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/data/models/responses/rides/promo_available_response.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/promo_apply_success_dialog.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../promo_code_route_args.dart';

class PromoCodeController extends GetxController {
  PromoCodeController({required this.homeRepository});

  final HomeRepository homeRepository;

  final RxList<PromocodeModel> promoCodes = <PromocodeModel>[].obs;
  final TextEditingController promoCodeTextController = TextEditingController();
  final isLoading = true.obs;
  final isApplying = false.obs;
  final loadError = RxnString();
  final applyInlineError = RxnString();

  PromoCodeRouteArgs? _rideArgs;

  bool get isRideBookingFlow => _rideArgs != null;

  @override
  void onInit() {
    super.onInit();
    _rideArgs = PromoCodeRouteArgs.tryFrom(Get.arguments);
    final applied = _rideArgs?.appliedCode.trim() ?? '';
    if (applied.isNotEmpty) {
      promoCodeTextController.text = applied;
    }
    loadAvailablePromos();
  }

  @override
  void onClose() {
    promoCodeTextController.dispose();
    super.onClose();
  }

  Future<void> loadAvailablePromos() async {
    isLoading.value = true;
    loadError.value = null;
    // Load full list; applicability for current ride is resolved client-side.
    final result = await homeRepository.getAvailablePromos();
    isLoading.value = false;
    result.fold(
      (f) {
        loadError.value = f.message;
        promoCodes.clear();
      },
      (items) {
        promoCodes.assignAll(items.map(_mapToDisplayModel));
      },
    );
  }

  bool _isPromoApplicable(AvailablePromoItem item) {
    final args = _rideArgs;
    if (args == null) return true;

    if (item.minRideAmount > 0 && args.fareEstimate < item.minRideAmount) {
      return false;
    }
    if (item.applicableVehicleTypes.isNotEmpty &&
        !item.applicableVehicleTypes.contains(args.vehicleTypeId)) {
      return false;
    }
    return true;
  }

  String? _inapplicableHint(AvailablePromoItem item) {
    if (_isPromoApplicable(item)) return null;
    final args = _rideArgs;
    if (args == null) return null;

    if (item.minRideAmount > 0 && args.fareEstimate < item.minRideAmount) {
      return AppStrings.promoMinRideAmount.trParams({
        'amount': CurrencyFormatter.format(item.minRideAmount),
      });
    }
    if (item.applicableVehicleTypes.isNotEmpty &&
        !item.applicableVehicleTypes.contains(args.vehicleTypeId)) {
      return AppStrings.promoCodeNotValidForVehicle.tr;
    }
    return AppStrings.promoErrorNotApplicable.tr;
  }

  PromocodeModel _mapToDisplayModel(AvailablePromoItem item) {
    final title = item.description.isNotEmpty ? item.description : item.code;
    final applicable = _isPromoApplicable(item);
    return PromocodeModel(
      code: item.code,
      title: title,
      subtitle: _subtitleFor(item),
      footer: _footerFor(item.validUntil),
      isApplicable: applicable,
      inapplicableHint: _inapplicableHint(item),
    );
  }

  String _subtitleFor(AvailablePromoItem item) {
    final parts = <String>[item.code];
    if (item.minRideAmount > 0) {
      parts.add(
        AppStrings.promoMinRideAmount.trParams({
          'amount': CurrencyFormatter.format(item.minRideAmount),
        }),
      );
    }
    return parts.join(' · ');
  }

  String _footerFor(DateTime? validUntil) {
    if (validUntil == null) return '';
    final now = DateTime.now();
    final endLocal = validUntil.toLocal();
    final endDay = DateTime(endLocal.year, endLocal.month, endLocal.day);
    final today = DateTime(now.year, now.month, now.day);
    final days = endDay.difference(today).inDays;
    if (days <= 0) {
      return AppStrings.promoExpiresToday.tr;
    }
    if (days == 1) {
      return AppStrings.daysLeftCount.trParams({'count': '1'});
    }
    return AppStrings.daysLeftCount.trParams({'count': '$days'});
  }

  Future<void> applyPromoCode() async {
    final code = promoCodeTextController.text.trim().toUpperCase();
    if (code.isEmpty) {
      applyInlineError.value = AppStrings.pleaseEnterAPromoCode.tr;
      return;
    }
    await _applyCode(code);
  }

  Future<void> applyPromo(PromocodeModel promo) async {
    if (!promo.isApplicable) return;
    final code = promo.code.trim().toUpperCase();
    if (code.isEmpty) return;
    promoCodeTextController.text = code;
    await _applyCode(code);
  }

  Future<void> _applyCode(String code) async {
    applyInlineError.value = null;
    if (!isRideBookingFlow) return;
    if (isApplying.value) return;

    final args = _rideArgs!;
    isApplying.value = true;
    AppDialogs.showLoadingDialog();
    try {
      final result = await homeRepository.validatePromo(
        code: code,
        vehicleTypeId: args.vehicleTypeId,
        fareEstimate: args.fareEstimate,
      );
      _dismissLoadingDialogIfOpen();

      await result.fold<Future<void>>(
        (f) async {
          final err = f is PromoValidationFailure ? f.errorCode : null;
          applyInlineError.value = _messageForPromoError(err, f.message);
          unawaited(
            di.sl<AnalyticsService>().logEvent(
              'promo_validated',
              parameters: {'success': 'false', 'error_code': err ?? 'unknown'},
            ),
          );
        },
        (data) async {
          unawaited(
            di.sl<AnalyticsService>().logEvent(
              'promo_validated',
              parameters: {'success': 'true', 'code': data.code},
            ),
          );
          await Get.dialog<void>(
            const PromoApplySuccessDialog(),
            barrierDismissible: false,
            barrierColor: Colors.black38,
          );
          Get.back(result: PromocodeApplyResult(code: data.code).toMap());
        },
      );
    } finally {
      isApplying.value = false;
    }
  }

  void _dismissLoadingDialogIfOpen() {
    if (Get.isDialogOpen ?? false) {
      Get.back<void>();
    }
  }

  String _messageForPromoError(String? code, String fallback) {
    switch (code?.trim()) {
      case 'VALID_PROMO_INVALID':
        return AppStrings.promoErrorInvalid.tr;
      case 'VALID_PROMO_EXPIRED':
        return AppStrings.promoErrorExpired.tr;
      case 'VALID_PROMO_NOT_APPLICABLE':
        return AppStrings.promoErrorNotApplicable.tr;
      default:
        final msg = fallback.trim();
        return msg.isEmpty ? AppStrings.promoErrorNetwork.tr : msg;
    }
  }
}

class PromocodeModel {
  final String code;
  final String title;
  final String subtitle;
  final String footer;
  final bool isApplicable;
  final String? inapplicableHint;

  PromocodeModel({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.footer,
    this.isApplicable = true,
    this.inapplicableHint,
  });
}
