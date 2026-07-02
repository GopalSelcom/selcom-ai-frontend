import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/phone_formatter.dart';
import '../../../../shared/utils/selcom_pesa_phone_utils.dart';
import '../../../payment/domain/wallet_payment_phone_country.dart';
import '../../../wallet/domain/usecases/get_wallet_summary_usecase.dart';
import '../../data/datasources/selcom_pesa_link_remote_data_source.dart';
import '../../domain/entities/payment_card.dart';
import '../../domain/entities/selcom_pesa_linked_account_entity.dart';
import '../../domain/repositories/selcom_pesa_link_repository.dart';
import '../screens/add_card_screen.dart';
import '../screens/card_details_screen.dart';
import '../widgets/payment_card_action_bottom_sheet.dart';
import '../widgets/selcom_pesa_flow_bottom_sheet.dart';

/// Payment Methods + Selcom Pesa link orchestration.
///
/// Selcom Pesa link/top-up wallet UI lives on [SelcomPesaToWalletScreen]; this
/// controller owns linked-account state, link request, balance reveal, selection,
/// and unlink. Flow reference: `docs/flows/selcom-pesa-link-flow.md`.
class PaymentMethodsController extends GetxController {
  PaymentMethodsController({
    SelcomPesaLinkRepository? selcomPesaLinkRepository,
    GetWalletSummaryUseCase? getWalletSummaryUseCase,
  }) : _selcomPesaLinkRepository =
           selcomPesaLinkRepository ?? sl<SelcomPesaLinkRepository>(),
       _getWalletSummaryUseCase =
           getWalletSummaryUseCase ?? sl<GetWalletSummaryUseCase>();

  final SelcomPesaLinkRepository _selcomPesaLinkRepository;
  final GetWalletSummaryUseCase _getWalletSummaryUseCase;

  // --- Wallet summary (Payment Methods screen) ---

  final RxString walletBalance = ''.obs;
  final RxString walletNumber = ''.obs;

  // --- Selcom Pesa linked accounts (link flow + wallet screen) ---

  /// True when at least one LINKED account exists (summary / Payment Methods).
  final RxBool isSelcomPesaLinked = false.obs;
  final RxBool isLoadingLinkedAccount = false.obs;
  final RxInt linkedAccountsCount = 0.obs;
  /// First linked account — used for Payment Methods subtitle only.
  final Rxn<SelcomPesaLinkedAccountEntity> primaryLinkedAccount =
      Rxn<SelcomPesaLinkedAccountEntity>();
  /// LINKED-only rows shown on Selcom Pesa to Go Wallet (max [maxLinkedAccounts]).
  final RxList<SelcomPesaLinkedAccountEntity> linkedAccountsList =
      <SelcomPesaLinkedAccountEntity>[].obs;
  /// Optional top-up target on wallet screen; none selected by default.
  final RxnString selectedLinkedAccountKey = RxnString();

  static const int maxLinkedAccounts = 5;

  // --- Link request phone sheet ([SelcomPesaFlowBottomSheet]) ---

  final TextEditingController selcomPhoneController = TextEditingController();
  final RxString phoneError = ''.obs;
  final RxBool canContinueSelcomPhone = false.obs;
  final RxBool isLinkRequestSubmitting = false.obs;

  // --- Per-card balance reveal (POST main_balance, auto-hide after 30s) ---

  static const String hiddenBalancePlaceholder = '••••••';
  static const Duration linkedBalanceVisibleDuration = Duration(seconds: 30);

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
    await Future.wait([
      _loadWalletSummary(),
      loadLinkedAccounts(),
    ]);
  }

  Future<void> _loadWalletSummary() async {
    try {
      final summary = await _getWalletSummaryUseCase();
      walletBalance.value = NumberFormat(
        '#,##0',
        'en_US',
      ).format(summary.balance);
      walletNumber.value = summary.walletNumber.trim();
    } catch (_) {
      walletBalance.value = '';
      walletNumber.value = '';
    }
  }

  /// Pull-to-refresh on Selcom Pesa to Go Wallet — re-fetches `GET linked_accounts`.
  Future<void> refreshLinkedAccounts() => loadLinkedAccounts();

  /// Loads linked accounts from API; UI shows only `LINKED` status, deduped by mobile.
  Future<void> loadLinkedAccounts() async {
    isLoadingLinkedAccount.value = true;
    try {
      final accounts = await _selcomPesaLinkRepository.getLinkedAccounts();
      final linked = _dedupeLinked(
        accounts
            .where((a) => a.status == SelcomPesaLinkStatus.linked)
            .toList(),
      );

      linkedAccountsList.assignAll(linked);
      _clearLinkedBalanceState();
      _pruneSelectedLinkedAccount();
      linkedAccountsCount.value = linked.length;
      if (linked.isEmpty) {
        primaryLinkedAccount.value = null;
        isSelcomPesaLinked.value = false;
        return;
      }

      primaryLinkedAccount.value = linked.first;
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

  /// Merges duplicate rows from API using normalized 9-digit mobile key.
  List<SelcomPesaLinkedAccountEntity> _dedupeLinked(
    List<SelcomPesaLinkedAccountEntity> accounts,
  ) {
    final seen = <String>{};
    final result = <SelcomPesaLinkedAccountEntity>[];
    for (final account in accounts) {
      final key = account.normalizedMobileDigits;
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      result.add(account);
    }
    return result;
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
  SelcomPesaLinkedAccountEntity? get selectedLinkedAccount {
    final key = selectedLinkedAccountKey.value;
    if (key == null || key.isEmpty) return null;
    for (final account in linkedAccountsList) {
      if (linkedAccountKey(account) == key) return account;
    }
    return null;
  }

  bool isLinkedAccountSelected(SelcomPesaLinkedAccountEntity account) {
    return selectedLinkedAccountKey.value == linkedAccountKey(account);
  }

  /// Toggles single-select on wallet screen (tap again to deselect).
  void toggleLinkedAccountSelection(SelcomPesaLinkedAccountEntity account) {
    final key = linkedAccountKey(account);
    if (selectedLinkedAccountKey.value == key) {
      selectedLinkedAccountKey.value = null;
      return;
    }
    selectedLinkedAccountKey.value = key;
  }

  /// Removes account from local list and shows success dialog.
  ///
  /// TODO: Call unlink API when backend endpoint is available; until then pull-to-
  /// refresh may restore the account from `GET linked_accounts`.
  Future<void> unlinkLinkedAccount(SelcomPesaLinkedAccountEntity account) async {
    final key = linkedAccountKey(account);
    _hideLinkedAccountBalance(key);
    _linkedBalanceLoading.remove(key);
    _linkedBalanceLoading.refresh();

    if (selectedLinkedAccountKey.value == key) {
      selectedLinkedAccountKey.value = null;
    }

    linkedAccountsList.removeWhere((a) => linkedAccountKey(a) == key);
    linkedAccountsCount.value = linkedAccountsList.length;

    if (linkedAccountsList.isEmpty) {
      primaryLinkedAccount.value = null;
      isSelcomPesaLinked.value = false;
    } else {
      primaryLinkedAccount.value = linkedAccountsList.first;
      isSelcomPesaLinked.value = true;
    }

    AppDialogs.showSuccessDialog(
      title: AppStrings.selcomPesa.tr,
      message: AppStrings.accountUnlinkedSuccessfully.tr,
    );
  }

  void _pruneSelectedLinkedAccount() {
    final key = selectedLinkedAccountKey.value;
    if (key == null || key.isEmpty) return;
    final stillExists = linkedAccountsList.any(
      (account) => linkedAccountKey(account) == key,
    );
    if (!stillExists) {
      selectedLinkedAccountKey.value = null;
    }
  }

  /// Stable key for selection/balance maps — prefers server `id`, else mobile digits.
  String linkedAccountKey(SelcomPesaLinkedAccountEntity account) {
    final id = account.id.trim();
    if (id.isNotEmpty) return id;
    return account.normalizedMobileDigits;
  }

  String linkedAccountBalanceDisplay(SelcomPesaLinkedAccountEntity account) {
    final key = linkedAccountKey(account);
    return _linkedBalanceVisible[key] ?? hiddenBalancePlaceholder;
  }

  bool isLinkedAccountBalanceLoading(SelcomPesaLinkedAccountEntity account) {
    return _linkedBalanceLoading[linkedAccountKey(account)] ?? false;
  }

  /// Fetches SP balance for one card; visible for [linkedBalanceVisibleDuration].
  Future<void> revealLinkedAccountBalance(
    SelcomPesaLinkedAccountEntity account,
  ) async {
    if (!account.isLinked) return;

    final key = linkedAccountKey(account);
    if (_linkedBalanceLoading[key] == true) return;

    _linkedBalanceLoading[key] = true;
    _linkedBalanceLoading.refresh();

    try {
      final countryCode = account.countryCode.trim().isNotEmpty
          ? account.countryCode.trim()
          : WalletPaymentPhoneCountry.dialCodeDigits;
      final result = await _selcomPesaLinkRepository.getMainBalance(
        mobileNumber: account.mobileNumber,
        countryCode: countryCode,
      );
      final currency = result.currency.trim().isNotEmpty
          ? result.currency.trim()
          : AppStrings.defaultCurrencyTzs.tr;
      _linkedBalanceVisible[key] =
          '$currency ${NumberFormat('#,##0', 'en_US').format(result.balance)}';
      _linkedBalanceVisible.refresh();
      _scheduleLinkedBalanceHide(key);
    } on SelcomPesaLinkException catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
    } finally {
      _linkedBalanceLoading.remove(key);
      _linkedBalanceLoading.refresh();
    }
  }

  void _scheduleLinkedBalanceHide(String key) {
    _linkedBalanceHideTimers[key]?.cancel();
    _linkedBalanceHideTimers[key] = Timer(linkedBalanceVisibleDuration, () {
      _hideLinkedAccountBalance(key);
    });
  }

  void _hideLinkedAccountBalance(String key) {
    _linkedBalanceHideTimers.remove(key)?.cancel();
    if (!_linkedBalanceVisible.containsKey(key)) return;
    _linkedBalanceVisible.remove(key);
    _linkedBalanceVisible.refresh();
  }

  void _clearLinkedBalanceState() {
    _cancelAllLinkedBalanceHideTimers();
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

  String phoneDisplayFor(SelcomPesaLinkedAccountEntity account) {
    final digits = account.normalizedMobileDigits;
    if (digits.isEmpty) return account.mobileNumber;
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

  Future<void> openSelcomPesaToWallet() async {
    await Get.toNamed(AppRoutes.selcomPesaToWallet);
    await loadLinkedAccounts();
  }

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
    isLinkRequestSubmitting.value = true;
    Loader.instance.show();

    try {
      final normalized = normalizeTzMobileForSelcomPesa(selcomPhoneController.text);
      final result = await _selcomPesaLinkRepository.sendLinkRequest(
        countryCode: WalletPaymentPhoneCountry.dialCodeDigits,
        mobileNumber: normalized,
      );
      final phoneDisplay = TanzaniaPhoneFormatter.formatInternational(normalized);
      AppDialogs.closeActiveDialog();
      await _handleSendLinkRequestResult(result, phoneDisplay);
      await loadLinkedAccounts();
    } on SelcomPesaLinkException catch (e) {
      AppDialogs.showErrorDialog(message: e.message.tr);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
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
    SelcomPesaLinkedAccountEntity account,
    String phoneDisplay,
  ) async {
    final params = {'phoneNumber': phoneDisplay};

    if (account.isLinked) {
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

  Future<void> addCard() async {
    final result = await Get.to<PaymentCard>(() => const AddCardScreen());

    if (result != null) {
      AppDialogs.showAnimatedBottomSheet(
        child: PaymentCardActionBottomSheet(
          title: AppStrings.yourCardHasBeenNaddedSuccessfully.tr,
          description: AppStrings.cardReadyToUseYouCanManageOrRemoveAnytime.tr,
          cardNumber: result.fullNumber,
          imageAssetPath: AppAssets.imgPaymentAddCardSuccess,
          primaryButtonLabel: AppStrings.ok.tr,
          onPrimaryPressed: AppDialogs.closeActiveDialog,
          iconAsset: AppAssets.locationIcArrowRight,
        ),
        barrierDismissible: true,
      );
    }
  }

  void openCardDetails(PaymentCard card) {
    Get.to(() => CardDetailsScreen(card: card));
  }
}
