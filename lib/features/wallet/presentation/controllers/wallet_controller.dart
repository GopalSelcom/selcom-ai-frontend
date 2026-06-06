import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../payment/data/models/go_other_payment_methods_models.dart';
import '../../../payment/presentation/widgets/add_money_to_wallet_bottom_sheet.dart';
import '../../domain/entities/wallet_summary_entity.dart';
import '../../domain/entities/wallet_transaction_filter.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../domain/usecases/get_wallet_summary_usecase.dart';
import '../../domain/usecases/get_wallet_transactions_usecase.dart';
import '../../domain/utils/wallet_statement_utils.dart';
import '../models/wallet_transaction_item.dart';
import '../utils/wallet_format_utils.dart';
import '../utils/wallet_refresh.dart';
import '../utils/wallet_transaction_mapper.dart';

class WalletController extends GetxController {
  static WalletController? _instance;

  factory WalletController() {
    _instance ??= WalletController._internal();
    return _instance!;
  }

  WalletController._internal();

  final GetWalletSummaryUseCase _getWalletSummaryUseCase =
      sl<GetWalletSummaryUseCase>();
  final GetWalletTransactionsUseCase _getWalletTransactionsUseCase =
      sl<GetWalletTransactionsUseCase>();

  final RxBool isLoading = true.obs;
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
    return CurrencyFormatter.format(value);
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
    // Placeholder until e-statement API / flow is available.
  }

  void copyWalletNumber() {
    final number = walletNumberForCopy;
    if (number.isEmpty) return;
    Clipboard.setData(ClipboardData(text: number));
  }

  ///wallet controller from v4
  RxString lang = "en".obs;
}
