import 'dart:async';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/currency_code.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/balance_visibility_policy.dart';
import '../../../../shared/utils/clipboard_utils.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../profile/domain/usecases/profile_usecase.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../payment/presentation/widgets/add_money_to_wallet_bottom_sheet.dart';
import '../../domain/entities/wallet_summary_entity.dart';
import '../../domain/entities/wallet_transaction_filter.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../data/datasources/wallet_remote_data_source.dart';
import '../../domain/usecases/email_wallet_statement_usecase.dart';
import '../../domain/utils/wallet_statement_utils.dart';
import '../models/wallet_transaction_item.dart';
import '../utils/wallet_format_utils.dart';
import '../utils/wallet_transaction_mapper.dart';

class WalletController extends GetxController {
  /// Manual singleton used by [WalletRouteMiddleware] and top-up flows outside
  /// GetX bindings. Must be cleared on logout — see [WalletSession.teardownOnLogout].
  static WalletController? _instance;

  factory WalletController() {
    _instance ??= WalletController._internal();
    return _instance!;
  }

  WalletController._internal();

  /// Clears in-memory wallet UI and drops [_instance] so the next session
  /// cannot reuse the previous user's balance or transaction preview.
  static void resetForLogout() {
    final controller = _instance;
    if (controller != null) {
      controller._cancelWalletBalanceHideTimer();
      controller.summary.value = null;
      controller.recentTransactions.clear();
      controller.isLoading.value = true;
      controller.isEmailingStatement.value = false;
      controller.isBalanceVisible.value = false;
      controller.isRefreshingWalletBalance.value = false;
      controller._loadInFlight = null;
    }
    _instance = null;
  }

  final EmailWalletStatementUseCase _emailWalletStatementUseCase =
      sl<EmailWalletStatementUseCase>();
  final ProfileUseCase _profileUseCase = sl<ProfileUseCase>();

  final RxBool isLoading = true.obs;
  final RxBool isEmailingStatement = false.obs;
  final RxBool isRefreshingWalletBalance = false.obs;
  final RxBool isBalanceVisible = false.obs;
  final Rxn<WalletSummaryEntity> summary = Rxn<WalletSummaryEntity>();
  final RxList<WalletTransactionItem> recentTransactions =
      <WalletTransactionItem>[].obs;

  RxBool isTestingMode = true.obs;

  RxBool isNidaRegistrationDialogVisible = false.obs;

  Timer? _walletBalanceHideTimer;
  Future<void>? _loadInFlight;

  @override
  void onInit() {
    super.onInit();
    resetWalletBalanceVisibilityOnScreenEntry();
    _restoreSummaryFromSharedCache();
  }

  /// Masks the wallet amount whenever the wallet screen is entered or a child
  /// route pops back to wallet.
  void resetWalletBalanceVisibilityOnScreenEntry() {
    _cancelWalletBalanceHideTimer();
    isBalanceVisible.value = false;
    ProfileWalletCache.isBalanceVisible = false;
  }

  void _navigateAndResetWalletBalanceOnReturn(Future<dynamic>? navigation) {
    // Re-mask balance when the user returns from any child route.
    navigation?.then((_) => resetWalletBalanceVisibilityOnScreenEntry());
  }

  /// Reuses [ProfileWalletCache] so wallet entry does not refetch card balance.
  void _restoreSummaryFromSharedCache() {
    summary.value = ProfileWalletCache.toSummaryEntity();
  }

  /// [fetchBalance] `false` when profile already loaded balance this session —
  /// only statement transactions are fetched (balance stays masked until eye tap).
  Future<void> loadWallet({
    bool showLoading = true,
    bool fetchBalance = true,
  }) async {
    if (_loadInFlight != null) {
      return _loadInFlight!;
    }

    final load = _loadWallet(showLoading: showLoading, fetchBalance: fetchBalance);
    _loadInFlight = load;
    try {
      await load;
    } finally {
      if (identical(_loadInFlight, load)) {
        _loadInFlight = null;
      }
    }
  }

  Future<void> _loadWallet({
    bool showLoading = true,
    bool fetchBalance = true,
  }) async {
    final useSharedBalance =
        !fetchBalance && ProfileWalletCache.isLoaded;

    if (showLoading && (summary.value == null || recentTransactions.isEmpty)) {
      isLoading.value = true;
    }
    try {
      if (useSharedBalance) {
        _restoreSummaryFromSharedCache();
        await _loadRecentTransactionsFromCache();
      } else {
        final pageData = await sl<WalletRepository>().getWalletPageData(
          filter: WalletTransactionFilter.all,
        );
        summary.value = pageData.summary;
        recentTransactions.assignAll(
          pageData.transactions
              .take(walletRecentTransactionPreviewLimit)
              .map(mapWalletTransactionToItem)
              .toList(growable: false),
        );
        _persistProfileWalletCache(pageData.summary);
      }
    } finally {
      isLoading.value = false;
      isRefreshingWalletBalance.value = false;
    }
  }

  Future<void> _loadRecentTransactionsFromCache() async {
    final currency = ProfileWalletCache.currency.trim().isNotEmpty
        ? ProfileWalletCache.currency.trim()
        : CommonValues.currencyCode;

    final transactions = await sl<WalletRepository>().getTransactions(
      filter: WalletTransactionFilter.all,
      currencyOverride: currency,
    );
    recentTransactions.assignAll(
      transactions
          .take(walletRecentTransactionPreviewLimit)
          .map(mapWalletTransactionToItem)
          .toList(growable: false),
    );
  }

  void _persistProfileWalletCache(WalletSummaryEntity walletSummary) {
    final account = walletSummary.walletNumber.trim();
    if (account.isEmpty) return;

    ProfileWalletCache.save(
      linked: true,
      balanceValue: NumberFormat('#,##0', 'en_US').format(walletSummary.balance),
      currencyValue: walletSummary.currency.trim(),
      walletNumberValue: formatWalletAccountNumber(account),
      walletNumberRawValue: account,
      reservedValue: walletSummary.reserved,
    );
    ProfileWalletCache.isBalanceVisible = isBalanceVisible.value;
  }

  String get formattedBalance {
    final value = summary.value?.balance;
    if (value == null) return '';
    return CurrencyFormatter.formatWithApiCurrency(
      value,
      summary.value?.currency,
    );
  }

  String get displayBalanceText {
    // Masked by default; eye tap (or refresh-in-flight) reveals the full amount.
    final showAmount =
        isBalanceVisible.value || isRefreshingWalletBalance.value;
    if (!showAmount) {
      // Keep currency visible while hiding digits (e.g. `TZS ••••••`).
      return formatHiddenWalletBalance(summary.value?.currency);
    }
    return formattedBalance;
  }

  /// Reserved line follows the same eye visibility as [displayBalanceText].
  String? get formattedReservedBalanceLabel {
    final reserved = summary.value?.reserved ?? 0;
    if (reserved <= 0) return null;

    final showAmount =
        isBalanceVisible.value || isRefreshingWalletBalance.value;
    final amountText = showAmount
        ? CurrencyFormatter.formatWithApiCurrency(
            reserved,
            summary.value?.currency,
          )
        : formatHiddenWalletBalance(summary.value?.currency);

    return AppStrings.walletReservedBalance.trParams({'amount': amountText});
  }

  String get formattedWalletNumber {
    final raw = summary.value?.walletNumber ?? '';
    return formatWalletAccountNumber(raw);
  }

  String get walletNumberForCopy =>
      summary.value?.walletNumber.replaceAll(RegExp(r'\s+'), '') ?? '';

  Future<void> refreshWallet() {
    // Pull-to-refresh must always re-fetch the statement. Balance is only
    // re-fetched when the amount is currently revealed (eye open).
    sl<WalletRepository>().invalidateStatementCache();
    return loadWallet(
      showLoading: false,
      fetchBalance: isBalanceVisible.value,
    );
  }

  /// Hides the amount, or reveals cached amount and refreshes balance from API.
  void toggleBalanceVisibility() {
    if (isRefreshingWalletBalance.value) return;

    if (isBalanceVisible.value) {
      _hideWalletBalance();
      return;
    }

    isBalanceVisible.value = true;
    ProfileWalletCache.isBalanceVisible = true;
    _scheduleWalletBalanceHide();
    unawaited(_refreshWalletBalance());
  }

  Future<void> _refreshWalletBalance() async {
    isRefreshingWalletBalance.value = true;
    try {
      final walletSummary = await sl<WalletRepository>().getWalletSummary();
      summary.value = walletSummary;
      _persistProfileWalletCache(walletSummary);

      if (Get.isRegistered<ProfileController>()) {
        final profileController = Get.find<ProfileController>();
        profileController.walletBalance.value =
            NumberFormat('#,##0', 'en_US').format(walletSummary.balance);
        profileController.walletCurrency.value = walletSummary.currency.trim();
        profileController.walletNumber.value =
            formatWalletAccountNumber(walletSummary.walletNumber.trim());
        profileController.isWalletLinked.value = true;
      }
    } finally {
      isRefreshingWalletBalance.value = false;
    }
  }

  void _hideWalletBalance() {
    resetWalletBalanceVisibilityOnScreenEntry();
  }

  void _scheduleWalletBalanceHide() {
    _cancelWalletBalanceHideTimer();
    _walletBalanceHideTimer = Timer(BalanceVisibilityPolicy.autoHideAfterReveal, () {
      _hideWalletBalance();
    });
  }

  void _cancelWalletBalanceHideTimer() {
    _walletBalanceHideTimer?.cancel();
    _walletBalanceHideTimer = null;
  }

  void goBack() => Get.back<void>();

  void openTransactionHistory() {
    _navigateAndResetWalletBalanceOnReturn(
      Get.toNamed(AppRoutes.walletTransactions),
    );
  }

  void openAddMoney() {
    unawaited(_openAddMoney());
  }

  Future<void> _openAddMoney() async {
    await AddMoneyToWalletBottomSheet.show();
  }

  void openEStatement() {
    unawaited(_emailEStatement());
  }

  Future<void> _emailEStatement() async {
    if (isEmailingStatement.value) return;

    await Loader.withFlag(isEmailingStatement, () async {
      final profileResult = await _profileUseCase.getProfile();
      var email = '';
      profileResult.fold((_) => null, (user) {
        email = user.emailId?.trim() ?? '';
      });

      if (email.isEmpty) {
        AppDialogs.showErrorDialog(message: AppStrings.emailIsRequired.tr);
        return;
      }

      final currency =
          summary.value?.currency.trim().isNotEmpty == true
              ? summary.value!.currency.trim()
              : CommonValues.currencyCode;
      final (startDate, endDate) = defaultWalletStatementDateRange();

      try {
        final result = await _emailWalletStatementUseCase(
          email: email,
          startDate: startDate,
          endDate: endDate,
          currency: currency,
        );

        final apiMessage = result.message.trim();
        final message = apiMessage.isNotEmpty
            ? apiMessage
            : AppStrings.walletStatementEmailedSuccess.tr;
        final successMessage = result.rangeCapped
            ? '$message\n\n${AppStrings.walletStatementRangeCappedHint.tr}'
            : message;

        AppDialogs.showSuccessDialog(message: successMessage);
      } on WalletStatementEmailException catch (e) {
        AppDialogs.showErrorDialog(message: e.message.tr);
      } catch (_) {
        AppDialogs.showErrorDialog(
          message: AppStrings.walletStatementEmailFailed.tr,
        );
      }
    });
  }

  /// Copies wallet number; iOS shows snackbar via [copyToClipboardWithFeedback].
  void copyWalletNumber() {
    final number = walletNumberForCopy;
    if (number.isEmpty) return;
    unawaited(
      copyToClipboardWithFeedback(
        text: number,
        message: AppStrings.walletNumberCopied.tr,
      ),
    );
  }

  ///wallet controller from v4
  RxString lang = "en".obs;
}
