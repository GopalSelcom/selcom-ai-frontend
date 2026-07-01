import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/data/models/user_model.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/payment_countdown_timer.dart';
import '../../../../shared/utils/thousands_separator_input_formatter.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../../../wallet/domain/usecases/get_wallet_summary_usecase.dart';
import '../../../wallet/presentation/controllers/wallet_controller.dart';
import '../../../wallet/presentation/utils/wallet_format_utils.dart';
import '../../../wallet/presentation/utils/wallet_refresh.dart';
import '../../data/datasources/wallet_payment_remote_data_source.dart';
import '../../data/models/go_other_payment_methods_models.dart';
import '../../domain/wallet_top_up_limits.dart';
import '../../../settings/data/models/settings_models.dart';

enum TanQrTopupStep { options, amountEntry, qrDisplay }

class TanQrWalletTopupController extends GetxController {
  TanQrWalletTopupController({
    WalletRepository? walletRepository,
    AppSettingsService? appSettingsService,
  }) : _walletRepository = walletRepository ?? sl<WalletRepository>(),
       _appSettingsService = appSettingsService ?? sl<AppSettingsService>();

  final WalletRepository _walletRepository;
  final AppSettingsService _appSettingsService;

  static const Duration pollInterval = Duration(seconds: 10);

  final step = TanQrTopupStep.options.obs;
  final amountRaw = ''.obs;
  final amountError = RxnString();
  final apiError = RxnString();
  final session = Rxn<TanQrPaymentSession>();
  final countdownSeconds = AppSettingsModel.defaultPaymentTimerSeconds.obs;
  final isSubmitting = false.obs;
  final isCancelling = false.obs;
  final displayName = ''.obs;
  final displayWalletNumber = ''.obs;

  late final TextEditingController amountController;
  bool _textFieldsDisposed = false;

  bool get textFieldsDisposed => _textFieldsDisposed;

  late final PaymentCountdownTimer _paymentCountdown;
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
    _paymentCountdown = PaymentCountdownTimer(
      onTick: (remaining) => countdownSeconds.value = remaining,
      onExpired: _onTimerExpired,
      onResumed: () => unawaited(_pollPaymentStatus()),
    );
    unawaited(_loadRegisteredPhone());
    unawaited(_loadDisplayAccountDetails());
  }

  void disposeTextFields() {
    if (_textFieldsDisposed) return;
    _textFieldsDisposed = true;
    amountController.dispose();
  }

  @override
  void onClose() {
    _stopTimers();
    if (!_textFieldsDisposed) {
      disposeTextFields();
    }
    super.onClose();
  }

  Future<void> _loadRegisteredPhone() async {
    _registeredPhone = await _readRegisteredPhoneFromStorage();
    if (_registeredPhone == null || _registeredPhone!.isEmpty) {
      apiError.value = AppStrings.tanQrMissingRegisteredPhone.tr;
    }
  }

  Future<void> _loadDisplayAccountDetails() async {
    final raw = await StorageService().read(StorageKeys.user);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final json = jsonDecode(raw);
        if (json is Map<String, dynamic>) {
          final user = UserModel.fromJson(json);
          displayName.value = user.name?.trim() ?? '';
        }
      } catch (_) {
        displayName.value = '';
      }
    }

    try {
      final summary = await sl<GetWalletSummaryUseCase>()();
      final walletNumber = summary.walletNumber.trim();
      if (walletNumber.isNotEmpty) {
        displayWalletNumber.value = formatWalletAccountNumber(walletNumber);
        return;
      }
    } catch (_) {}

    if (Get.isRegistered<WalletController>()) {
      final formatted = WalletController().formattedWalletNumber.trim();
      if (formatted.isNotEmpty) {
        displayWalletNumber.value = formatted;
      }
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
    countdownSeconds.value = _appSettingsService.paymentWaitSeconds.value;
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
      await _loadDisplayAccountDetails();
      step.value = TanQrTopupStep.qrDisplay;
      await _startQrTimers();
    } on WalletPaymentException catch (e) {
      apiError.value = e.message.tr;
    } catch (_) {
      apiError.value = AppStrings.tanQrPaymentRequestFailed.tr;
    } finally {
      isSubmitting.value = false;
      Loader.instance.hide();
    }
  }

  Future<void> _startQrTimers() async {
    _stopTimers();
    final durationSeconds =
        await _appSettingsService.resolvePaymentTimerSeconds();
    countdownSeconds.value = durationSeconds;
    _paymentHandled = false;

    _paymentCountdown.start(durationSeconds);

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

    await WalletRefresh.afterBalanceChange();

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
    countdownSeconds.value = _appSettingsService.paymentWaitSeconds.value;
    apiError.value = null;
    amountError.value = null;
    step.value = TanQrTopupStep.amountEntry;
  }

  void closeWithCancel() {
    _stopTimers();
    Get.back(result: TanQrTopupResult.cancelled);
  }

  Future<void> cancelPaymentRequest() async {
    if (isCancelling.value) return;

    final transid = session.value?.transid.trim() ?? '';
    if (transid.isEmpty) return;

    isCancelling.value = true;
    Loader.instance.show();

    var dismissed = false;
    try {
      await _walletRepository.cancelUssdOrder(
        transid: transid,
        paymentMethod:
            GoOtherPaymentMethodsRequest.cancelUssdPaymentMethodMobileMoney,
      );
      _paymentHandled = true;
      _stopTimers();
      dismissed = true;
      Get.back(result: TanQrTopupResult.cancelled);
    } on WalletPaymentException catch (e) {
      AppDialogs.showErrorDialog(message: e.message.tr);
    } catch (_) {
      AppDialogs.showErrorDialog(
        message: AppStrings.couldNotCancelTryAgain.tr,
      );
    } finally {
      Loader.instance.hide();
      if (!dismissed) {
        isCancelling.value = false;
      }
    }
  }

  void handleSheetDismissed() {
    _stopTimers();
  }

  void _stopTimers() {
    _paymentCountdown.stop();
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  String formatCountdown(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
