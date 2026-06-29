import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/phone_national_rules.dart';
import '../../../../shared/utils/grouped_phone_number_formatter.dart';
import '../../../../shared/utils/thousands_separator_input_formatter.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../../../wallet/presentation/utils/wallet_refresh.dart';
import '../../data/datasources/wallet_payment_remote_data_source.dart';
import '../../data/models/go_other_payment_methods_models.dart';
import '../../domain/wallet_payment_phone_country.dart';
import '../../domain/wallet_top_up_limits.dart';
import '../widgets/mobile_money_topup_status_dialog.dart';

class MobileMoneyTopupController extends GetxController {
  MobileMoneyTopupController({
    this.controllerTag,
    WalletRepository? walletRepository,
  }) : _walletRepository = walletRepository ?? sl<WalletRepository>();

  final String? controllerTag;

  final WalletRepository _walletRepository;

  static const int countdownDurationSeconds = 300;
  static const Duration pollInterval = Duration(seconds: 10);

  final phoneRaw = ''.obs;
  final amountRaw = ''.obs;
  final phoneError = RxnString();
  final amountError = RxnString();
  final apiError = RxnString();
  final isSubmitting = false.obs;
  final isCancelling = false.obs;

  late final TextEditingController phoneController;
  late final TextEditingController amountController;
  bool _textFieldsDisposed = false;

  bool get textFieldsDisposed => _textFieldsDisposed;

  final ValueNotifier<int> pendingCountdown = ValueNotifier<int>(
    countdownDurationSeconds,
  );

  Timer? _countdownTimer;
  Timer? _pollTimer;
  bool _paymentHandled = false;
  bool _pendingDialogVisible = false;
  TanQrPaymentSession? _session;
  String? _lastUssdPhone;
  int? _lastAmount;

  String get countryDialCode => WalletPaymentPhoneCountry.dialCodeDigits;

  String get countryDialCodeDisplay =>
      WalletPaymentPhoneCountry.dialCodeDisplay;

  String get countryIso => WalletPaymentPhoneCountry.iso;

  int? get parsedAmount {
    final digits = amountRaw.value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  bool get isAwaitingPaymentResult =>
      _pendingDialogVisible || (_session != null && !_paymentHandled);

  bool get canContinue {
    if (isSubmitting.value) return false;
    return _validatePhone(showEmptyError: false) == null &&
        _validateAmount(showEmptyError: false) == null;
  }

  @override
  void onInit() {
    super.onInit();
    phoneController = TextEditingController();
    amountController = TextEditingController();
  }

  void disposeTextFields() {
    if (_textFieldsDisposed) return;
    _textFieldsDisposed = true;
    phoneController.dispose();
    amountController.dispose();
  }

  @override
  void onClose() {
    _stopTimers();
    pendingCountdown.dispose();
    if (!_textFieldsDisposed) {
      disposeTextFields();
    }
    super.onClose();
  }

  void onPhoneChanged(String value) {
    phoneRaw.value = value.replaceAll(RegExp(r'\D'), '');
    apiError.value = null;
    if (phoneError.value != null) {
      _validatePhone(showEmptyError: false);
    }
  }

  void onAmountChanged(String value) {
    amountRaw.value = value.replaceAll(RegExp(r'\D'), '');
    apiError.value = null;
    if (amountError.value != null) {
      _validateAmount(showEmptyError: false);
    }
  }

  String? validatePhoneForDisplay({bool showEmptyError = true}) {
    return _validatePhone(showEmptyError: showEmptyError);
  }

  String? validateAmountForDisplay({bool showEmptyError = true}) {
    return _validateAmount(showEmptyError: showEmptyError);
  }

  String? _validatePhone({required bool showEmptyError}) {
    final digits = phoneRaw.value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return showEmptyError ? AppStrings.enterPhoneNumber.tr : null;
    }
    const iso = WalletPaymentPhoneCountry.iso;
    if (!PhoneNationalRules.isCompleteValidNational(iso, digits)) {
      return AppStrings.enterPhoneNumber.tr;
    }
    return null;
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

  String _buildUssdPhoneNumber(String nationalDigits) {
    var digits = nationalDigits.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return digits;
  }

  Future<void> submit() async {
    if (isSubmitting.value) return;

    final phoneValidation = _validatePhone(showEmptyError: true);
    final amountValidation = _validateAmount(showEmptyError: true);
    phoneError.value = phoneValidation;
    amountError.value = amountValidation;
    if (phoneValidation != null || amountValidation != null) return;

    final amount = parsedAmount;
    if (amount == null) return;

    final ussdPhone = _buildUssdPhoneNumber(phoneRaw.value);
    _lastUssdPhone = ussdPhone;
    _lastAmount = amount;

    await _initiatePayment(
      ussdPhone: ussdPhone,
      amount: amount,
      closeSheetFirst: true,
    );
  }

  Future<void> retryPayment() async {
    final ussdPhone = _lastUssdPhone;
    final amount = _lastAmount;
    if (ussdPhone == null || amount == null) return;

    await _initiatePayment(
      ussdPhone: ussdPhone,
      amount: amount,
      closeSheetFirst: false,
    );
  }

  Future<void> _initiatePayment({
    required String ussdPhone,
    required int amount,
    required bool closeSheetFirst,
  }) async {
    apiError.value = null;
    isSubmitting.value = true;
    Loader.instance.show();

    try {
      final result = await _walletRepository.initiateMobileMoneyTopUp(
        GoOtherPaymentMethodsRequest(
          totalPrice: amount,
          ussdPhoneNumber: ussdPhone,
          // paymentMode: GoOtherPaymentMethodsRequest.paymentModeMobileMoney,
        ),
      );

      _session = result;
      _paymentHandled = false;

      if (closeSheetFirst) {
        Get.back<void>();
      }

      await Future<void>.delayed(Duration.zero);
      _showPendingDialog();
      _startPollingTimers();
    } on WalletPaymentException catch (e) {
      if (closeSheetFirst) {
        apiError.value = e.message.tr;
      } else {
        AppDialogs.showErrorDialog(message: e.message.tr);
      }
    } catch (_) {
      final message = AppStrings.tanQrPaymentRequestFailed.tr;
      if (closeSheetFirst) {
        apiError.value = message;
      } else {
        AppDialogs.showErrorDialog(message: message);
      }
    } finally {
      isSubmitting.value = false;
      Loader.instance.hide();
    }
  }

  String _enteredPhoneDisplay() {
    var digits = phoneRaw.value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      digits = _lastUssdPhone ?? '';
    }
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    const iso = WalletPaymentPhoneCountry.iso;
    final country = PhoneNationalRules.findByIso(iso);
    final grouped = GroupedPhoneNumberFormatter.formatDigits(
      digits,
      country.format,
    );
    return '$countryDialCodeDisplay $grouped';
  }

  void _showPendingDialog() {
    _pendingDialogVisible = true;

    AppDialogs.showAnimatedDialog<void>(
      barrierDismissible: false,
      child: PopScope(
        canPop: false,
        child: MobileMoneyTopupStatusDialog(
          type: MobileMoneyTopupDialogType.request,
          requestTitle: AppStrings.mobileMoneyRequestSentTitle.tr,
          requestSubtitle: AppStrings.mobileMoneyRequestSentMessage.trParams({
            'number': _enteredPhoneDisplay(),
          }),
          onAcknowledge: _dismissPendingDialog,
        ),
      ),
    );
  }

  void _dismissPendingDialog() {
    if (!_pendingDialogVisible) return;
    _pendingDialogVisible = false;
    AppDialogs.dismissTopOverlay();
  }

  void _startPollingTimers() {
    _stopTimers();
    pendingCountdown.value = countdownDurationSeconds;
    _paymentHandled = false;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = pendingCountdown.value - 1;
      if (next <= 0) {
        pendingCountdown.value = 0;
        _onTimerExpired();
        return;
      }
      pendingCountdown.value = next;
    });

    _pollTimer = Timer.periodic(pollInterval, (_) {
      unawaited(_pollPaymentStatus());
    });
    unawaited(_pollPaymentStatus());
  }

  Future<void> _pollPaymentStatus() async {
    if (_paymentHandled) return;

    final transid = _session?.transid.trim() ?? '';
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
    if (_paymentHandled) return;
    _stopTimers();
    _dismissPendingDialog();

    AppDialogs.showConfirmationDialog(
      title: AppStrings.tanQrTimerExpiredTitle.tr,
      message: AppStrings.tanQrTimerExpiredMessage.tr,
      confirmText: AppStrings.retry,
      cancelText: AppStrings.cancel,
      onConfirm: retryPayment,
      onCancel: cancelPayment,
    );
  }

  Future<void> _onPaymentSucceeded(String message) async {
    if (_paymentHandled) return;
    _paymentHandled = true;
    _stopTimers();
    _dismissPendingDialog();

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
    _finishPaymentFlow();
  }

  void cancelPayment() {
    _paymentHandled = true;
    _stopTimers();
    _dismissPendingDialog();
    _disposeRegisteredController();
  }

  Future<void> cancelPaymentRequest() async {
    if (isCancelling.value || _paymentHandled) return;

    final transid = _session?.transid.trim() ?? '';
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
      await Loader.instance.hideAsync();
      _dismissPendingDialog();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _disposeRegisteredController();
      });
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
    if (_pendingDialogVisible || isAwaitingPaymentResult) return;
    _stopTimers();
  }

  void _disposeRegisteredController() {
    final tag = controllerTag;
    if (tag == null) return;
    if (Get.isRegistered<MobileMoneyTopupController>(tag: tag)) {
      Get.delete<MobileMoneyTopupController>(tag: tag);
    }
  }

  void _finishPaymentFlow() {
    _disposeRegisteredController();
  }

  void _stopTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _pollTimer?.cancel();
    _pollTimer = null;
  }
}
