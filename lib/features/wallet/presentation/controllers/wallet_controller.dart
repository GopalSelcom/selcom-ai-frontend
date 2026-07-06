import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/constants/currency_code.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../profile/domain/usecases/profile_usecase.dart';
import '../../../payment/data/models/go_other_payment_methods_models.dart';
import '../../../payment/presentation/widgets/add_money_to_wallet_bottom_sheet.dart';
import '../../domain/entities/wallet_summary_entity.dart';
import '../../domain/entities/wallet_transaction_filter.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../data/datasources/wallet_remote_data_source.dart';
import '../../domain/usecases/email_wallet_statement_usecase.dart';
import '../../domain/usecases/get_wallet_summary_usecase.dart';
import '../../domain/usecases/get_wallet_transactions_usecase.dart';
import '../../domain/utils/wallet_statement_utils.dart';
import '../models/wallet_transaction_item.dart';
import '../utils/wallet_format_utils.dart';
import '../utils/wallet_refresh.dart';
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
      controller.summary.value = null;
      controller.recentTransactions.clear();
      controller.isLoading.value = true;
      controller.isEmailingStatement.value = false;
    }
    _instance = null;
  }

  final GetWalletSummaryUseCase _getWalletSummaryUseCase =
      sl<GetWalletSummaryUseCase>();
  final GetWalletTransactionsUseCase _getWalletTransactionsUseCase =
      sl<GetWalletTransactionsUseCase>();
  final EmailWalletStatementUseCase _emailWalletStatementUseCase =
      sl<EmailWalletStatementUseCase>();
  final ProfileUseCase _profileUseCase = sl<ProfileUseCase>();

  final RxBool isLoading = true.obs;
  final RxBool isEmailingStatement = false.obs;
  final Rxn<WalletSummaryEntity> summary = Rxn<WalletSummaryEntity>();
  final RxList<WalletTransactionItem> recentTransactions =
      <WalletTransactionItem>[].obs;

  RxBool isTestingMode = true.obs;

  RxBool isNidaRegistrationDialogVisible = false.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(loadWallet());
  }

  Future<void> loadWallet({bool showLoading = true}) async {
    if (showLoading || summary.value == null) {
      isLoading.value = true;
    }
    try {
      sl<WalletRepository>().invalidateStatementCache();
      final walletSummary = await _getWalletSummaryUseCase();
      final transactions = await _getWalletTransactionsUseCase(
        filter: WalletTransactionFilter.all,
      );
      summary.value = walletSummary;
      recentTransactions.assignAll(
        transactions
            .take(walletRecentTransactionPreviewLimit)
            .map(mapWalletTransactionToItem)
            .toList(growable: false),
      );
    } finally {
      isLoading.value = false;
    }
  }

  String get formattedBalance {
    final value = summary.value?.balance;
    if (value == null) return '';
    return CurrencyFormatter.formatWithApiCurrency(
      value,
      summary.value?.currency,
    );
  }

  String? get formattedReservedBalanceLabel {
    final reserved = summary.value?.reserved ?? 0;
    if (reserved <= 0) return null;
    final formatted = CurrencyFormatter.formatWithApiCurrency(
      reserved,
      summary.value?.currency,
    );
    return AppStrings.walletReservedBalance.trParams({'amount': formatted});
  }

  String get formattedWalletNumber {
    final raw = summary.value?.walletNumber ?? '';
    return formatWalletAccountNumber(raw);
  }

  String get walletNumberForCopy =>
      summary.value?.walletNumber.replaceAll(RegExp(r'\s+'), '') ?? '';

  Future<void> refreshWallet() => loadWallet(showLoading: false);

  void goBack() => Get.back<void>();

  void openTransactionHistory() {
    Get.toNamed(AppRoutes.walletTransactions);
  }

  void openAddMoney() {
    unawaited(_openAddMoney());
  }

  Future<void> _openAddMoney() async {
    final result = await AddMoneyToWalletBottomSheet.show();
    if (result == TanQrTopupResult.success) {
      await WalletRefresh.afterBalanceChange();
    }
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

  void copyWalletNumber() {
    final number = walletNumberForCopy;
    if (number.isEmpty) return;
    Clipboard.setData(ClipboardData(text: number));
  }

  ///wallet controller from v4
  RxString lang = "en".obs;
}
