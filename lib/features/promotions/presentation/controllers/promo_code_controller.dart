import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../../../core/data/models/responses/rides/promo_available_response.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/errors/failures.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../promo_code_route_args.dart';

class PromoCodeController extends GetxController {
  PromoCodeController({required this.homeRepository});

  final HomeRepository homeRepository;

  final RxList<PromoCodeModel> promoCodes = <PromoCodeModel>[].obs;
  final TextEditingController promoCodeTextController = TextEditingController();
  final isLoading = true.obs;
  final isApplying = false.obs;
  final showApplySuccess = false.obs;
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

  PromoCodeModel _mapToDisplayModel(AvailablePromoItem item) {
    final title = item.description.isNotEmpty ? item.description : item.code;
    final applicable = _isPromoApplicable(item);
    return PromoCodeModel(
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

  static const Duration _successDisplayDuration = Duration(seconds: 2);
  static const Duration _successDismissSettleDuration = Duration(
    milliseconds: 320,
  );

  /// Shows success on promo screen, waits for dismiss, then pops with [applyResult].
  Future<void> _showSuccessThenReturn(PromoCodeApplyResult applyResult) async {
    showApplySuccess.value = true;
    await Future<void>.delayed(_successDisplayDuration);
    showApplySuccess.value = false;
    await Future<void>.delayed(_successDismissSettleDuration);
    await SchedulerBinding.instance.endOfFrame;
    final navigator = Get.key.currentState;
    if (navigator != null && navigator.canPop()) {
      Get.back(result: applyResult.toMap());
    }
  }

  Future<void> applyPromo(PromoCodeModel promo) async {
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

    PromoCodeApplyResult? applyResult;
    try {
      await Loader.withFlag(isApplying, () async {
        final result = await homeRepository.validatePromo(
          code: code,
          vehicleTypeId: args.vehicleTypeId,
          fareEstimate: args.fareEstimate,
        );

        await result.fold<Future<void>>(
          (f) async {
            final err = f is PromoValidationFailure ? f.errorCode : null;
            applyInlineError.value = _messageForPromoError(err, f.message);
            unawaited(
              di.sl<AnalyticsService>().logEvent(
                'promo_validated',
                parameters: {
                  'success': 'false',
                  'error_code': err ?? 'unknown',
                },
              ),
            );
          },
          (data) async {
            applyResult = PromoCodeApplyResult(
              code: data.code,
              vehicleTypeId: args.vehicleTypeId,
              discountedFare: data.discountedFare,
              discountAmount: data.discountAmount,
            );
            unawaited(
              di.sl<AnalyticsService>().logEvent(
                'promo_validated',
                parameters: {'success': 'true', 'code': data.code},
              ),
            );
          },
        );
      });
    } catch (_) {
      applyInlineError.value = AppStrings.promoErrorNetwork.tr;
    }

    if (applyResult != null) {
      await _showSuccessThenReturn(applyResult!);
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

class PromoCodeModel {
  final String code;
  final String title;
  final String subtitle;
  final String footer;
  final bool isApplicable;
  final String? inapplicableHint;

  PromoCodeModel({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.footer,
    this.isApplicable = true,
    this.inapplicableHint,
  });
}
