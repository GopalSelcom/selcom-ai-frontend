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

  bool _isPromoApplicable(AvailablePromo item) {
    final args = _rideArgs;
    if (args == null) return true;

    final minRide = item.minRideAmount ?? 0;
    if (minRide > 0 && args.fareEstimate < minRide) {
      return false;
    }
    if (args.bookAny) {
      return false;
    }
    final vehicles = item.applicableVehicleTypes ?? const <String>[];
    if (vehicles.isNotEmpty && !vehicles.contains(args.vehicleTypeId)) {
      return false;
    }
    return true;
  }

  String? _inapplicableHint(AvailablePromo item) {
    if (_isPromoApplicable(item)) return null;
    final args = _rideArgs;
    if (args == null) return null;

    final minRide = item.minRideAmount ?? 0;
    if (minRide > 0 && args.fareEstimate < minRide) {
      return AppStrings.promoMinRideAmount.trParams({
        'amount': CurrencyFormatter.format(minRide),
      });
    }
    if (args.bookAny) {
      return AppStrings.promoCodeNotValidForVehicle.tr;
    }
    final vehicles = item.applicableVehicleTypes ?? const <String>[];
    if (vehicles.isNotEmpty && !vehicles.contains(args.vehicleTypeId)) {
      return AppStrings.promoCodeNotValidForVehicle.tr;
    }
    return AppStrings.promoErrorNotApplicable.tr;
  }

  PromoCodeModel _mapToDisplayModel(AvailablePromo item) {
    final description = (item.description ?? '').trim();
    final code = (item.code ?? '').trim().toUpperCase();
    final title = description.isNotEmpty ? description : code;
    final applicable = _isPromoApplicable(item);
    return PromoCodeModel(
      code: code,
      title: title,
      subtitle: _subtitleFor(item),
      footer: _footerFor(item.validUntil),
      isApplicable: applicable,
      inapplicableHint: _inapplicableHint(item),
      isAutoApply: item.isAutoApply == true,
      isCashback: item.isCashback == true,
    );
  }

  String _subtitleFor(AvailablePromo item) {
    final code = (item.code ?? '').trim().toUpperCase();
    final parts = <String>[if (code.isNotEmpty) code];
    final minRide = item.minRideAmount ?? 0;
    if (minRide > 0) {
      parts.add(
        AppStrings.promoMinRideAmount.trParams({
          'amount': CurrencyFormatter.format(minRide),
        }),
      );
    }
    return parts.join(' · ');
  }

  String _footerFor(String? validUntilRaw) {
    if (validUntilRaw == null || validUntilRaw.trim().isEmpty) return '';
    final validUntil = DateTime.tryParse(validUntilRaw);
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
    PromoCodeModel? match;
    for (final promo in promoCodes) {
      if (promo.code == code) {
        match = promo;
        break;
      }
    }
    await _applyCode(
      code,
      isAutoApply: match?.isAutoApply ?? false,
      isCashback: match?.isCashback ?? false,
    );
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
    await _applyCode(
      code,
      isAutoApply: promo.isAutoApply,
      isCashback: promo.isCashback,
    );
  }

  Future<void> _applyCode(
    String code, {
    bool isAutoApply = false,
    bool isCashback = false,
  }) async {
    applyInlineError.value = null;
    if (!isRideBookingFlow) return;
    if (isApplying.value) return;

    final args = _rideArgs!;
    if (args.bookAny) {
      applyInlineError.value = AppStrings.promoCodeNotValidForVehicle.tr;
      return;
    }

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
              code: (data.code ?? code).trim().toUpperCase(),
              vehicleTypeId: args.vehicleTypeId,
              discountedFare: data.discountedFare ?? 0,
              discountAmount: data.discountAmount ?? 0,
              isAutoApply: isAutoApply,
              isCashback: isCashback,
            );
            unawaited(
              di.sl<AnalyticsService>().logEvent(
                'promo_validated',
                parameters: {
                  'success': 'true',
                  'code': (data.code ?? code).trim().toUpperCase(),
                },
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
  final bool isAutoApply;
  final bool isCashback;

  PromoCodeModel({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.footer,
    this.isApplicable = true,
    this.inapplicableHint,
    this.isAutoApply = false,
    this.isCashback = false,
  });
}
