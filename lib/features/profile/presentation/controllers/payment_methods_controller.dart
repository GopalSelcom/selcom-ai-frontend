import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/balance_visibility_policy.dart';
import '../../../../shared/utils/phone_formatter.dart';
import '../../../../shared/utils/selcom_pesa_phone_utils.dart';
import '../../../payment/domain/wallet_payment_phone_country.dart';
import '../../../wallet/data/models/go_card_balance_response.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../../../wallet/presentation/utils/wallet_format_utils.dart';
import '../../data/datasources/selcom_pesa_link_remote_data_source.dart';
import '../../data/models/selcom_pesa_link_models.dart';
import '../../data/models/sp_link_response.dart';
import '../../domain/repositories/selcom_pesa_link_repository.dart';
import '../widgets/selcom_pesa_flow_bottom_sheet.dart';

/// Payment Methods + Selcom Pesa link orchestration.
///
/// Selcom Pesa link/top-up wallet UI lives on [SelcomPesaToWalletScreen]; this
/// controller owns linked-account state, link request, balance reveal, selection,
/// and unlink. Flow reference: `docs/flows/selcom-pesa-link-flow.md`.
class PaymentMethodsController extends GetxController {
  PaymentMethodsController({
    SelcomPesaLinkRepository? selcomPesaLinkRepository,
    WalletRepository? walletRepository,
  }) : _selcomPesaLinkRepository =
           selcomPesaLinkRepository ?? sl<SelcomPesaLinkRepository>(),
       _walletRepository = walletRepository ?? sl<WalletRepository>();

  final SelcomPesaLinkRepository _selcomPesaLinkRepository;
  final WalletRepository _walletRepository;

  // --- Wallet summary (Payment Methods screen) ---

  final RxString walletBalance = ''.obs;
  final RxString walletNumber = ''.obs;

  // --- Selcom Pesa linked accounts (link flow + wallet screen) ---

  /// True when at least one LINKED account exists (summary / Payment Methods).
  final RxBool isSelcomPesaLinked = false.obs;
  final RxBool isLoadingLinkedAccount = false.obs;
  final RxInt linkedAccountsCount = 0.obs;

  /// First linked account — used for Payment Methods subtitle only.
  final Rxn<Account> primaryLinkedAccount = Rxn<Account>();

  /// LINKED-only rows shown on Selcom Pesa to Go Wallet (max [maxLinkedAccounts]).
  final RxList<Account> linkedAccountsList = <Account>[].obs;

  /// Optional top-up target on wallet screen; none selected by default.
  final RxnString selectedLinkedAccountKey = RxnString();

  static const int maxLinkedAccounts = 5;

  // --- Link request phone sheet ([SelcomPesaFlowBottomSheet]) ---

  final TextEditingController selcomPhoneController = TextEditingController();
  final RxString phoneError = ''.obs;
  final RxBool canContinueSelcomPhone = false.obs;
  final RxBool isLinkRequestSubmitting = false.obs;
  final RxBool isUnlinkSubmitting = false.obs;
  final RxBool isSetDefaultSubmitting = false.obs;

  // --- Per-card balance reveal (POST main_balance, auto-hide after reveal) ---

  String _hiddenLinkedBalanceLabel() =>
      formatHiddenWalletBalance(AppStrings.defaultCurrencyTzs.tr);

  final RxMap<String, String> _linkedBalanceVisible = <String, String>{}.obs;
  final RxMap<String, bool> _linkedBalanceLoading = <String, bool>{}.obs;
  final Map<String, Timer> _linkedBalanceHideTimers = {};

  @override
  void onInit() {
    super.onInit();
    unawaited(_loadWalletSummary());
  }

  @override
  void onClose() {
    _cancelAllLinkedBalanceHideTimers();
    selcomPhoneController.dispose();
    super.onClose();
  }

  /// Payment Methods screen — loads wallet + linked Selcom Pesa summary.
  Future<void> refreshPaymentMethodsState() async {
    await Future.wait([_loadWalletSummary(), loadLinkedAccounts()]);
  }

  Future<void> _loadWalletSummary() async {
    try {
      final summary = await _walletRepository.getCardBalance();
      if (summary != null && summary.isSuccess) {
        walletBalance.value = NumberFormat(
          '#,##0',
          'en_US',
        ).format(summary.availableBalance);
        walletNumber.value = summary.pan;
      } else {
        clearWalletDisplayOnLogout();
      }
    } catch (_) {
      clearWalletDisplayOnLogout();
    }
  }

  /// Clears wallet summary shown on Payment Methods after session teardown.
  void clearWalletDisplayOnLogout() {
    walletBalance.value = '';
    walletNumber.value = '';
  }

  /// Pull-to-refresh on Selcom Pesa to Go Wallet — re-fetches `GET linked_accounts`.
  Future<void> refreshLinkedAccounts() => loadLinkedAccounts();

  /// Loads linked accounts from API; UI shows only `LINKED` status, deduped by mobile.
  Future<void> loadLinkedAccounts() async {
    isLoadingLinkedAccount.value = true;
    try {
      final accounts = await _selcomPesaLinkRepository.getLinkedAccounts();

      linkedAccountsList.assignAll(accounts.data?.accounts ?? []);
      _clearLinkedBalanceState();
      // _pruneSelectedLinkedAccount();
      linkedAccountsCount.value = accounts.data?.count ?? 0;
      if (linkedAccountsList.isEmpty) {
        primaryLinkedAccount.value = null;
        isSelcomPesaLinked.value = false;
        return;
      }

      primaryLinkedAccount.value = linkedAccountsList.firstWhereOrNull(
        (e) => (e.isDefault ?? false),
      );
      isSelcomPesaLinked.value = true;
    } on SelcomPesaLinkException catch (e, stackTrace) {
      _clearLinkedSummary();
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      _clearLinkedSummary();
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
    } finally {
      isLoadingLinkedAccount.value = false;
    }
  }

  void _clearLinkedSummary() {
    primaryLinkedAccount.value = null;
    isSelcomPesaLinked.value = false;
    linkedAccountsCount.value = 0;
    linkedAccountsList.clear();
    selectedLinkedAccountKey.value = null;
    _clearLinkedBalanceState();
  }

  bool get canLinkAnother => linkedAccountsCount.value < maxLinkedAccounts;

  /// Selected linked card on wallet screen, or null when Done runs self top-up.
  Account? get selectedLinkedAccount {
    final key = selectedLinkedAccountKey.value;
    if (key == null || key.isEmpty) return null;
    for (final account in linkedAccountsList) {
      if (linkedAccountKey(account) == key) return account;
    }
    return null;
  }

  bool isLinkedAccountSelected(Account account) {
    return selectedLinkedAccountKey.value == linkedAccountKey(account);
  }

  /// Toggles single-select on wallet screen (tap again to deselect).
  void toggleLinkedAccountSelection(Account account) {
    final key = linkedAccountKey(account);
    if (selectedLinkedAccountKey.value == key) {
      selectedLinkedAccountKey.value = null;
      return;
    }
    selectedLinkedAccountKey.value = key;
  }

  /// `POST request_unlink` with SP mobile, then refreshes linked list.
  Future<void> unlinkLinkedAccount(Account account) async {
    if (isUnlinkSubmitting.value) return;

    final key = linkedAccountKey(account);
    isUnlinkSubmitting.value = true;
    Loader.instance.show();

    try {
      await _selcomPesaLinkRepository.requestUnlink(
        mobileNumber: account.spMobileNumber ?? "",
      );

      _hideLinkedAccountBalance(key);
      _linkedBalanceLoading.remove(key);
      _linkedBalanceLoading.refresh();

      if (selectedLinkedAccountKey.value == key) {
        selectedLinkedAccountKey.value = null;
      }

      await loadLinkedAccounts();

      await Loader.instance.hideAsync();
      await WidgetsBinding.instance.endOfFrame;

      AppDialogs.showSuccessDialog(
        title: AppStrings.selcomPesa.tr,
        message: AppStrings.accountUnlinkedSuccessfully.tr,
      );
    } on SelcomPesaLinkException catch (e) {
      await Loader.instance.hideAsync();
      AppDialogs.showErrorDialog(message: e.message.tr);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      await Loader.instance.hideAsync();
      AppDialogs.showErrorDialog(
        message: AppStrings.somethingWentWrongPleaseTryAgain.tr,
      );
    } finally {
      isUnlinkSubmitting.value = false;
      Loader.instance.hide();
    }
  }

  Future<void> setDefaultAccount(Account account) async {
    if (isSetDefaultSubmitting.value) return;

    isSetDefaultSubmitting.value = true;
    Loader.instance.show();

    try {
      await _selcomPesaLinkRepository.setDefaultAccount(
        mobileNumber:
            (account.spCountryCode ?? "") + (account.spMobileNumber ?? ""),
      );

      await loadLinkedAccounts();

      await Loader.instance.hideAsync();
      await WidgetsBinding.instance.endOfFrame;

      AppDialogs.showSuccessDialog(
        title: AppStrings.selcomPesa.tr,
        message: AppStrings.defaultAccountSetSuccessfully.tr,
      );
    } on SelcomPesaLinkException catch (e) {
      await Loader.instance.hideAsync();
      AppDialogs.showErrorDialog(message: e.message.tr);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      await Loader.instance.hideAsync();
      AppDialogs.showErrorDialog(
        message: AppStrings.somethingWentWrongPleaseTryAgain.tr,
      );
    } finally {
      isSetDefaultSubmitting.value = false;
      Loader.instance.hide();
    }
  }

  /// Stable key for selection/balance maps — prefers server `id`, else mobile digits.
  String linkedAccountKey(Account account) {
    final id = (account.id ?? "").trim();
    return id;
  }

  String linkedAccountBalanceDisplay(Account account) {
    final key = linkedAccountKey(account);
    return _linkedBalanceVisible[key] ?? _hiddenLinkedBalanceLabel();
  }

  bool isLinkedAccountBalanceLoading(Account account) {
    return _linkedBalanceLoading[linkedAccountKey(account)] ?? false;
  }

  /// Fetches SP balance for one card; visible for [BalanceVisibilityPolicy.autoHideAfterReveal].
  RxBool isAmountVisible = false.obs;

  Future<void> revealLinkedAccountBalance(Account account) async {
    final key = linkedAccountKey(account);
    isAmountVisible.value = !isAmountVisible.value;

    if (!isAmountVisible.value) {
      _hideLinkedAccountBalance(key);
      return;
    }

    if (_linkedBalanceLoading[key] == true) return;

    _linkedBalanceLoading[key] = true;
    _linkedBalanceLoading.refresh();

    try {
      final result = await _selcomPesaLinkRepository.getMainBalance(
        mobileNumber: account.spMobileNumber ?? "",
        countryCode: account.spCountryCode ?? "",
      );
      final currency = AppStrings.defaultCurrencyTzs.tr;
      _linkedBalanceVisible[key] =
          '$currency ${NumberFormat('#,##0', 'en_US').format(result.data?.balance)}';
      _linkedBalanceVisible.refresh();
      _scheduleLinkedBalanceHide(key);
    } on SelcomPesaLinkException catch (e, stackTrace) {
      isAmountVisible.value = false;
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      isAmountVisible.value = false;
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
    } finally {
      _linkedBalanceLoading.remove(key);
      _linkedBalanceLoading.refresh();
    }
  }

  void _scheduleLinkedBalanceHide(String key) {
    _linkedBalanceHideTimers[key]?.cancel();
    _linkedBalanceHideTimers[key] = Timer(BalanceVisibilityPolicy.autoHideAfterReveal, () {
      _hideLinkedAccountBalance(key);
    });
  }

  void _hideLinkedAccountBalance(String key) {
    _linkedBalanceHideTimers.remove(key)?.cancel();
    isAmountVisible.value = false;
    if (!_linkedBalanceVisible.containsKey(key)) return;
    _linkedBalanceVisible.remove(key);
    _linkedBalanceVisible.refresh();
  }

  void _clearLinkedBalanceState() {
    _cancelAllLinkedBalanceHideTimers();
    isAmountVisible.value = false;
    _linkedBalanceVisible.clear();
    _linkedBalanceLoading.clear();
    _linkedBalanceVisible.refresh();
    _linkedBalanceLoading.refresh();
  }

  void _cancelAllLinkedBalanceHideTimers() {
    for (final timer in _linkedBalanceHideTimers.values) {
      timer.cancel();
    }
    _linkedBalanceHideTimers.clear();
  }

  String phoneDisplayFor(Account account) {
    final digits = account.spMobileNumber ?? "";
    if (digits.isEmpty) return account.spMobileNumber ?? "";
    return TanzaniaPhoneFormatter.formatInternational(digits);
  }

  String get linkedPhoneDisplay {
    final account = primaryLinkedAccount.value;
    if (account == null) return '';
    return phoneDisplayFor(account);
  }

  String get selcomPesaSummarySubtitle {
    if (!isSelcomPesaLinked.value) {
      return AppStrings.connectSelcomPesaRideChargesSubtitle.tr;
    }
    if (linkedAccountsCount.value > 1) {
      return AppStrings.selcomPesaMultipleLinked.trParams({
        'count': '${linkedAccountsCount.value}',
      });
    }
    return AppStrings.selcomPesaLinkedNumber.trParams({
      'number': linkedPhoneDisplay,
    });
  }

  void handleBack() => Get.back<void>();

  /// Opens phone sheet when user taps Link account / Link another (max 5 guard).
  void linkSelcomPesa() {
    if (!canLinkAnother) {
      AppDialogs.showErrorDialog(
        message: AppStrings.selcomPesaMaxLinkedAccounts.trParams({
          'max': '$maxLinkedAccounts',
        }),
      );
      return;
    }
    selcomPhoneController.clear();
    phoneError.value = '';
    _updateCanContinueSelcomPhone();
    SelcomPesaFlowBottomSheet.show();
  }

  void stopLinkFlow() {
    phoneError.value = '';
    selcomPhoneController.clear();
    _updateCanContinueSelcomPhone();
  }

  void onSelcomPhoneChanged(String _) {
    if (phoneError.value.isNotEmpty) phoneError.value = '';
    _updateCanContinueSelcomPhone();
  }

  void _updateCanContinueSelcomPhone() {
    final phone = selcomPhoneController.text.replaceAll(' ', '');
    canContinueSelcomPhone.value = phone.isNotEmpty && phone.length >= 9;
  }

  /// Link sheet Continue — `POST send_link_request`, then dialog + list refresh.
  Future<void> onPhoneContinue() async {
    final phone = selcomPhoneController.text.replaceAll(' ', '');
    if (phone.isEmpty) {
      phoneError.value = AppStrings.pleaseEnterYourPhoneNumber.tr;
      return;
    }
    if (phone.length < 9) {
      phoneError.value = AppStrings.pleaseEnterAValidPhoneNumber.tr;
      return;
    }

    if (isLinkRequestSubmitting.value) return;

    final normalized = normalizeTzMobileForSelcomPesa(
      selcomPhoneController.text,
    );
    final phoneDisplay = TanzaniaPhoneFormatter.formatInternational(normalized);

    // Dismiss keyboard and close the sheet once before the loader so it does not
    // flash back when the loader is removed after the API call.
    FocusManager.instance.primaryFocus?.unfocus();
    await AppDialogs.ensureKeyboardClosed();
    AppDialogs.closeActiveDialog();
    await WidgetsBinding.instance.endOfFrame;

    isLinkRequestSubmitting.value = true;
    Loader.instance.show();

    try {
      final result = await _selcomPesaLinkRepository.sendLinkRequest(
        countryCode: WalletPaymentPhoneCountry.dialCodeDigits,
        mobileNumber: normalized,
      );

      await Loader.instance.hideAsync();
      await WidgetsBinding.instance.endOfFrame;

      // await loadLinkedAccounts();
      await _handleSendLinkRequestResult(result.data, phoneDisplay);
    } on SelcomPesaLinkException catch (e) {
      await Loader.instance.hideAsync();
      AppDialogs.showErrorDialog(message: e.message.tr);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      await Loader.instance.hideAsync();
      AppDialogs.showErrorDialog(
        message: AppStrings.somethingWentWrongPleaseTryAgain.tr,
      );
    } finally {
      isLinkRequestSubmitting.value = false;
      Loader.instance.hide();
    }
  }

  /// LINKED → already-linked message; PENDING/other → request-sent message (no SP app open).
  Future<void> _handleSendLinkRequestResult(
    LinkData? account,
    String phoneDisplay,
  ) async {
    final params = {'phoneNumber': phoneDisplay};

    if (!(account?.isNewRequest ?? false)) {
      AppDialogs.showSuccessDialog(
        title: AppStrings.selcomPesa.tr,
        message: AppStrings.selcomPesaAlreadyLinkedMessage.trParams(params),
      );
      return;
    }

    AppDialogs.showSuccessDialog(
      title: AppStrings.selcomPesa.tr,
      message: AppStrings.selcomPesaLinkRequestSentMessage.trParams(params),
    );
  }
}
