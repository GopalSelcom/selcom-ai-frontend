import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/data/models/user_model.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/app_region_service.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../core/services/selcom_pesa/selcom_pesa_app_launcher_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/phone_national_rules.dart';
import '../../../../shared/utils/thousands_separator_input_formatter.dart';
import '../../../wallet/domain/entities/wallet_details_entity.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../../../wallet/presentation/utils/wallet_refresh.dart';
import '../../data/datasources/wallet_payment_remote_data_source.dart';
import '../../data/models/selcom_pesa_topup_models.dart';
import '../../domain/wallet_top_up_limits.dart';
import '../widgets/mobile_money_topup_status_dialog.dart';

enum SelcomPesaTopupFlow { self, other }

class SelcomPesaTopupController extends GetxController
    with WidgetsBindingObserver {
  SelcomPesaTopupController({
    this.controllerTag,
    WalletRepository? walletRepository,
    AppRegionService? appRegionService,
    SelcomPesaAppLauncherService? selcomPesaLauncher,
  }) : _walletRepository = walletRepository ?? sl<WalletRepository>(),
       _appRegionService = appRegionService ?? sl<AppRegionService>(),
       _selcomPesaLauncher =
           selcomPesaLauncher ?? sl<SelcomPesaAppLauncherService>();

  final String? controllerTag;
  final WalletRepository _walletRepository;
  final AppRegionService _appRegionService;
  final SelcomPesaAppLauncherService _selcomPesaLauncher;

  static const int selfTimeoutSeconds = 120;
  static const int otherDialogAutoCloseSeconds = 2;

  final amountRaw = ''.obs;
  final phoneRaw = ''.obs;
  final amountError = RxnString();
  final phoneError = RxnString();
  final apiError = RxnString();
  final isSubmitting = false.obs;

  late final TextEditingController amountController;
  TextEditingController? phoneController;

  final ValueNotifier<int> pendingCountdown = ValueNotifier<int>(
    selfTimeoutSeconds,
  );

  Timer? _countdownTimer;
  Timer? _otherDialogTimer;
  bool _pendingDialogVisible = false;
  bool _awaitingSelcomPesaReturn = false;
  bool _selfFlowHandled = false;
  bool _retainForFollowUpSheet = false;
  SelcomPesaTopupFlow? _activeFlow;
  int? _lastSelfAmount;

  String get countryDialCode =>
      _appRegionService.selected.dialCode.replaceAll('+', '');

  String get countryDialCodeDisplay => _appRegionService.selected.dialCode;

  String get countryIso => _appRegionService.selected.code;

  bool get isAwaitingPaymentResult =>
      _pendingDialogVisible ||
      _awaitingSelcomPesaReturn ||
      (_activeFlow == SelcomPesaTopupFlow.self && !_selfFlowHandled);

  bool get shouldRetainAfterSheetClose =>
      isAwaitingPaymentResult ||
      _retainForFollowUpSheet ||
      isSubmitting.value;

  void retainForOtherNumberSheet() {
    _retainForFollowUpSheet = true;
  }

  void clearRetainForFollowUpSheet() {
    _retainForFollowUpSheet = false;
  }

  int? get parsedAmount {
    final digits = amountRaw.value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  bool get canSubmitSelf {
    if (isSubmitting.value) return false;
    return _validateAmount(showEmptyError: false) == null;
  }

  bool get canSubmitOther {
    if (isSubmitting.value) return false;
    return _validatePhone(showEmptyError: false) == null &&
        _validateAmount(showEmptyError: false) == null;
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    amountController = TextEditingController();
  }

  void bindPhoneController(TextEditingController controller) {
    phoneController = controller;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimers();
    pendingCountdown.dispose();
    amountController.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!_awaitingSelcomPesaReturn || _selfFlowHandled) return;
    unawaited(_onSelfFlowReturned());
  }

  void onAmountChanged(String value) {
    amountRaw.value = value.replaceAll(RegExp(r'\D'), '');
    apiError.value = null;
    if (amountError.value != null) {
      _validateAmount(showEmptyError: false);
    }
  }

  void onPhoneChanged(String value) {
    phoneRaw.value = value.replaceAll(RegExp(r'\D'), '');
    apiError.value = null;
    if (phoneError.value != null) {
      _validatePhone(showEmptyError: false);
    }
  }

  String? validateAmountForDisplay({bool showEmptyError = true}) {
    return _validateAmount(showEmptyError: showEmptyError);
  }

  String? validatePhoneForDisplay({bool showEmptyError = true}) {
    return _validatePhone(showEmptyError: showEmptyError);
  }

  Future<void> submitSelfTopUp({required bool closeSheetFirst}) async {
    if (isSubmitting.value) return;

    final amountValidation = _validateAmount(showEmptyError: true);
    amountError.value = amountValidation;
    if (amountValidation != null) return;

    final amount = parsedAmount;
    if (amount == null) return;

    final installed = await _selcomPesaLauncher.isSelcomPesaInstalled();
    if (!installed) {
      apiError.value = AppStrings.selcomPesaAppNotInstalled.tr;
      await _showInstallSelcomPesaDialog();
      return;
    }

    _lastSelfAmount = amount;
    _activeFlow = SelcomPesaTopupFlow.self;
    await _sendTopUpRequest(
      amount: amount,
      mobileNumber: '',
      requireShortCode: true,
      closeSheetFirst: closeSheetFirst,
      onSuccess: _startSelfFlow,
    );
  }

  Future<void> submitOtherTopUp({required bool closeSheetFirst}) async {
    if (isSubmitting.value) return;

    final phoneValidation = _validatePhone(showEmptyError: true);
    final amountValidation = _validateAmount(showEmptyError: true);
    phoneError.value = phoneValidation;
    amountError.value = amountValidation;
    if (phoneValidation != null || amountValidation != null) return;

    final amount = parsedAmount;
    if (amount == null) return;

    final ussdPhone = _buildUssdPhoneNumber(phoneRaw.value);
    _activeFlow = SelcomPesaTopupFlow.other;

    await _sendTopUpRequest(
      amount: amount,
      mobileNumber: ussdPhone,
      requireShortCode: false,
      closeSheetFirst: closeSheetFirst,
      onSuccess: _startOtherFlow,
    );
  }

  Future<void> retrySelfTopUp() async {
    final amount = _lastSelfAmount;
    if (amount == null) return;
    _activeFlow = SelcomPesaTopupFlow.self;
    await _sendTopUpRequest(
      amount: amount,
      mobileNumber: '',
      requireShortCode: true,
      closeSheetFirst: false,
      onSuccess: _startSelfFlow,
    );
  }

  Future<void> _sendTopUpRequest({
    required int amount,
    required String mobileNumber,
    required bool requireShortCode,
    required bool closeSheetFirst,
    required Future<void> Function(SelcomPesaTopupResult result) onSuccess,
  }) async {
    apiError.value = null;
    isSubmitting.value = true;
    Loader.instance.show();

    try {
      final walletContext = await _loadWalletContext();
      if (walletContext == null) {
        if (closeSheetFirst) {
          apiError.value = AppStrings.walletAccountUnavailable.tr;
        } else {
          AppDialogs.showErrorDialog(
            message: AppStrings.walletAccountUnavailable.tr,
          );
        }
        return;
      }

      final result = await _walletRepository.sendSelcomPesaTopUpRequest(
        SelcomPesaTopupRequest(
          cardNo: walletContext.accountNo,
          amount: amount,
          accountNo: walletContext.accountNo,
          mobileNumber: mobileNumber,
          name: walletContext.displayName,
        ),
        requireShortCode: requireShortCode,
      );

      if (closeSheetFirst) {
        Get.back<void>();
      }

      await Future<void>.delayed(Duration.zero);
      await onSuccess(result);
    } on WalletPaymentException catch (e) {
      final message = e.message.tr;
      if (closeSheetFirst) {
        apiError.value = message;
      } else {
        AppDialogs.showErrorDialog(message: message);
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

  Future<void> _startSelfFlow(SelcomPesaTopupResult result) async {
    _selfFlowHandled = false;
    _awaitingSelcomPesaReturn = false;
    _showSelfPendingDialog();
    _startSelfTimeout();

    final launched = await _selcomPesaLauncher.openPcodePayment(
      result.shortCode,
    );
    if (!launched) {
      _stopTimers();
      _dismissPendingDialog();
      AppDialogs.showErrorDialog(
        message: AppStrings.tanQrPaymentRequestFailed.tr,
      );
      return;
    }

    _awaitingSelcomPesaReturn = true;
  }

  Future<void> _startOtherFlow(SelcomPesaTopupResult result) async {
    final message = result.message.trim().isNotEmpty
        ? result.message
        : AppStrings.requestSentCompleteSelcomTopup.tr;

    _showOtherPendingDialog(message);
    _otherDialogTimer?.cancel();
    _otherDialogTimer = Timer(
      const Duration(seconds: otherDialogAutoCloseSeconds),
      () {
        _dismissPendingDialog();
        _finishFlow();
      },
    );
  }

  Future<void> _onSelfFlowReturned() async {
    if (_selfFlowHandled) return;
    _selfFlowHandled = true;
    _awaitingSelcomPesaReturn = false;
    _stopTimers();
    _dismissPendingDialog();

    await WalletRefresh.afterBalanceChange();

    if (Get.currentRoute != AppRoutes.wallet) {
      await Get.toNamed(AppRoutes.wallet);
    }

    AppDialogs.showSuccessDialog(
      title: AppStrings.walletFundsReceivedTitle.tr,
      message: AppStrings.walletFundsReceivedSubtitle.tr,
    );
    _finishFlow();
  }

  void _onSelfTimeoutExpired() {
    if (_selfFlowHandled) return;
    _awaitingSelcomPesaReturn = false;
    _stopTimers();
    _dismissPendingDialog();

    AppDialogs.showConfirmationDialog(
      title: AppStrings.tanQrTimerExpiredTitle.tr,
      message: AppStrings.tanQrTimerExpiredMessage.tr,
      confirmText: AppStrings.retry,
      cancelText: AppStrings.cancel,
      onConfirm: retrySelfTopUp,
      onCancel: _finishFlow,
    );
  }

  void _showSelfPendingDialog() {
    pendingCountdown.value = selfTimeoutSeconds;
    _pendingDialogVisible = true;

    AppDialogs.showAnimatedDialog<void>(
      barrierDismissible: false,
      child: PopScope(
        canPop: false,
        child: MobileMoneyTopupStatusDialog(
          type: MobileMoneyTopupDialogType.request,
          requestTitle: AppStrings
              .requestSentPleaseCompletePaymentOnSelcomPesaToBookYourRide
              .tr,
          secondsListenable: pendingCountdown,
        ),
      ),
    );
  }

  void _showOtherPendingDialog(String message) {
    _pendingDialogVisible = true;

    AppDialogs.showAnimatedDialog<void>(
      barrierDismissible: false,
      child: PopScope(
        canPop: false,
        child: MobileMoneyTopupStatusDialog(
          type: MobileMoneyTopupDialogType.request,
          requestTitle: message,
        ),
      ),
    );
  }

  void _dismissPendingDialog() {
    if (!_pendingDialogVisible) return;
    _pendingDialogVisible = false;
    if (Get.isDialogOpen == true) {
      Get.back<void>();
    }
  }

  void _startSelfTimeout() {
    _stopTimers();
    pendingCountdown.value = selfTimeoutSeconds;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = pendingCountdown.value - 1;
      if (next <= 0) {
        pendingCountdown.value = 0;
        _onSelfTimeoutExpired();
        return;
      }
      pendingCountdown.value = next;
    });
  }

  Future<void> _showInstallSelcomPesaDialog() async {
    AppDialogs.showConfirmationDialog(
      title: AppStrings.selcomPesaAppNotInstalled.tr,
      message: AppStrings.selcomPesaInstallPrompt.tr,
      confirmText: AppStrings.downloadApp.tr,
      cancelText: AppStrings.cancel,
      onConfirm: () => unawaited(_selcomPesaLauncher.openDownloadPage()),
    );
  }

  Future<_WalletTopupContext?> _loadWalletContext() async {
    final details = await _walletRepository.getWalletDetails();
    if (details == null || !details.hasWallet) {
      return null;
    }
    if (!details.isActive) {
      return null;
    }

    final displayName = await _resolveDisplayName(details);
    if (displayName.isEmpty) {
      return null;
    }

    return _WalletTopupContext(
      accountNo: details.accountNo.trim(),
      displayName: displayName,
    );
  }

  Future<String> _resolveDisplayName(WalletDetailsEntity details) async {
    final raw = await StorageService().read(StorageKeys.user);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final json = jsonDecode(raw);
        if (json is Map<String, dynamic>) {
          final user = UserModel.fromJson(json);
          final name = user.name?.trim() ?? '';
          if (name.isNotEmpty) return name;
        }
      } catch (_) {}
    }

    final parts = [
      details.firstName?.trim() ?? '',
      details.lastName?.trim() ?? '',
    ].where((part) => part.isNotEmpty).join(' ');
    return parts;
  }

  String? _validatePhone({required bool showEmptyError}) {
    final digits = phoneRaw.value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return showEmptyError ? AppStrings.enterPhoneNumber.tr : null;
    }
    if (!PhoneNationalRules.isCompleteValidNational(countryIso, digits)) {
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
    return '$countryDialCode$digits';
  }

  void handleSheetDismissed() {
    if (isAwaitingPaymentResult) return;
    _stopTimers();
  }

  void _finishFlow() {
    _selfFlowHandled = true;
    _awaitingSelcomPesaReturn = false;
    _activeFlow = null;
    _stopTimers();
    _dismissPendingDialog();
    _disposeRegisteredController();
  }

  void _disposeRegisteredController() {
    final tag = controllerTag;
    if (tag == null) return;
    if (Get.isRegistered<SelcomPesaTopupController>(tag: tag)) {
      Get.delete<SelcomPesaTopupController>(tag: tag);
    }
  }

  void _stopTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _otherDialogTimer?.cancel();
    _otherDialogTimer = null;
  }
}

class _WalletTopupContext {
  const _WalletTopupContext({
    required this.accountNo,
    required this.displayName,
  });

  final String accountNo;
  final String displayName;
}
