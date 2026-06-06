import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/data/models/user_model.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/thousands_separator_input_formatter.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../../../wallet/presentation/controllers/wallet_controller.dart';
import '../../data/datasources/wallet_payment_remote_data_source.dart';
import '../../data/models/go_other_payment_methods_models.dart';
import '../../domain/wallet_top_up_limits.dart';

enum TanQrTopupStep { options, amountEntry, qrDisplay }

class TanQrWalletTopupController extends GetxController {
  TanQrWalletTopupController({WalletRepository? walletRepository})
    : _walletRepository = walletRepository ?? sl<WalletRepository>();

  final WalletRepository _walletRepository;

  static const int countdownDurationSeconds = 300;
  static const Duration pollInterval = Duration(seconds: 10);

  final step = TanQrTopupStep.options.obs;
  final amountRaw = ''.obs;
  final amountError = RxnString();
  final apiError = RxnString();
  final session = Rxn<TanQrPaymentSession>();
  final countdownSeconds = countdownDurationSeconds.obs;
  final isSubmitting = false.obs;

  late final TextEditingController amountController;

  Timer? _countdownTimer;
  Timer? _pollTimer;
  bool _paymentHandled = false;
  String? _registeredPhone;

  int? get parsedAmount {
    final digits = amountRaw.value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  bool get canContinue {
    if (isSubmitting.value) return false;
    if (_registeredPhone == null || _registeredPhone!.isEmpty) return false;
    return _validateAmount(showEmptyError: false) == null;
  }

  @override
  void onInit() {
    super.onInit();
    amountController = TextEditingController();
    unawaited(_loadRegisteredPhone());
  }

  @override
  void onClose() {
    _stopTimers();
    amountController.dispose();
    super.onClose();
  }

  Future<void> _loadRegisteredPhone() async {
    _registeredPhone = await _readRegisteredPhoneFromStorage();
    if (_registeredPhone == null || _registeredPhone!.isEmpty) {
      apiError.value = AppStrings.tanQrMissingRegisteredPhone.tr;
    }
  }

  Future<String?> _readRegisteredPhoneFromStorage() async {
    final raw = await StorageService().read(StorageKeys.user);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      final user = UserModel.fromJson(json);
      final mobile = user.mobileNumber?.toString() ?? '';
      final digits = mobile.replaceAll(RegExp(r'\D'), '');
      return digits.isEmpty ? null : digits;
    } catch (_) {
      return null;
    }
  }

  void openTanQrAmountEntry() {
    apiError.value = null;
    amountError.value = null;
    step.value = TanQrTopupStep.amountEntry;
  }

  void backToOptions() {
    _stopTimers();
    session.value = null;
    countdownSeconds.value = countdownDurationSeconds;
    apiError.value = null;
    amountError.value = null;
    step.value = TanQrTopupStep.options;
  }

  void onAmountChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    amountRaw.value = digits;
    apiError.value = null;
    if (amountError.value != null) {
      _validateAmount(showEmptyError: false);
    }
  }

  String? validateAmountForDisplay({bool showEmptyError = true}) {
    return _validateAmount(showEmptyError: showEmptyError);
  }

  String? _validateAmount({required bool showEmptyError}) {
    final digits = amountRaw.value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return showEmptyError ? AppStrings.tanQrAmountRequired.tr : null;
    }

    final amount = int.tryParse(digits);
    if (amount == null || amount <= 0) {
      return AppStrings.tanQrAmountMustBeGreaterThanZero.tr;
    }

    if (amount > WalletTopUpLimits.maxTopUpAmount) {
      return AppStrings.tanQrAmountExceedsMax.trParams({
        'max': ThousandsSeparatorInputFormatter.formatDigits(
          WalletTopUpLimits.maxTopUpAmount.toString(),
        ),
      });
    }

    return null;
  }

  Future<void> submitAmount() async {
    if (isSubmitting.value) return;

    final validation = _validateAmount(showEmptyError: true);
    amountError.value = validation;
    if (validation != null) return;

    final phone = _registeredPhone ?? await _readRegisteredPhoneFromStorage();
    if (phone == null || phone.isEmpty) {
      apiError.value = AppStrings.tanQrMissingRegisteredPhone.tr;
      return;
    }
    _registeredPhone = phone;

    final amount = parsedAmount;
    if (amount == null) return;

    apiError.value = null;
    isSubmitting.value = true;
    Loader.instance.show();

    try {
      final result = await _walletRepository.initiateTanQrTopUp(
        GoOtherPaymentMethodsRequest(
          totalPrice: amount,
          ussdPhoneNumber: "",
        ),
      );
      session.value = result;
      step.value = TanQrTopupStep.qrDisplay;
      _startQrTimers();
    } on WalletPaymentException catch (e) {
      apiError.value = e.message.tr;
    } catch (_) {
      apiError.value = AppStrings.tanQrPaymentRequestFailed.tr;
    } finally {
      isSubmitting.value = false;
      Loader.instance.hide();
    }
  }

  void _startQrTimers() {
    _stopTimers();
    countdownSeconds.value = countdownDurationSeconds;
    _paymentHandled = false;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = countdownSeconds.value - 1;
      if (next <= 0) {
        countdownSeconds.value = 0;
        _onTimerExpired();
        return;
      }
      countdownSeconds.value = next;
    });

    _pollTimer = Timer.periodic(pollInterval, (_) {
      unawaited(_pollPaymentStatus());
    });
    unawaited(_pollPaymentStatus());
  }

  Future<void> _pollPaymentStatus() async {
    if (_paymentHandled) return;

    final current = session.value;
    if (current == null || step.value != TanQrTopupStep.qrDisplay) return;

    final transid = current.transid.trim();
    if (transid.isEmpty) return;

    try {
      final status = await _walletRepository.checkPaymentStatus(
        transid: transid,
      );
      if (status.isPaid) {
        await _onPaymentSucceeded(status.message);
      }
    } catch (_) {
      // Keep polling until timer expires or payment succeeds.
    }
  }

  void _onTimerExpired() {
    _stopTimers();
    AppDialogs.showConfirmationDialog(
      title: AppStrings.tanQrTimerExpiredTitle.tr,
      message: AppStrings.tanQrTimerExpiredMessage.tr,
      confirmText: AppStrings.retry,
      cancelText: AppStrings.cancel,
      onConfirm: resetToAmountEntry,
      onCancel: closeWithCancel,
    );
  }

  Future<void> _onPaymentSucceeded(String message) async {
    if (_paymentHandled) return;
    _paymentHandled = true;
    _stopTimers();

    Get.back(result: TanQrTopupResult.success);

    await WalletController().loadWallet();

    if (Get.currentRoute != AppRoutes.wallet) {
      await Get.toNamed(AppRoutes.wallet);
    }

    AppDialogs.showSuccessDialog(
      title: AppStrings.walletFundsReceivedTitle.tr,
      message: message.trim().isNotEmpty
          ? message
          : AppStrings.walletFundsReceivedSubtitle.tr,
    );
  }

  void resetToAmountEntry() {
    _stopTimers();
    session.value = null;
    countdownSeconds.value = countdownDurationSeconds;
    apiError.value = null;
    amountError.value = null;
    step.value = TanQrTopupStep.amountEntry;
  }

  void closeWithCancel() {
    _stopTimers();
    Get.back(result: TanQrTopupResult.cancelled);
  }

  void handleSheetDismissed() {
    _stopTimers();
  }

  void _stopTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  String formatCountdown(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
