import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../payment/presentation/widgets/add_money_to_wallet_bottom_sheet.dart';
import '../../domain/entities/wallet_summary_entity.dart';
import '../../domain/entities/wallet_transaction_entity.dart';
import '../../domain/usecases/get_wallet_summary_usecase.dart';
import '../../domain/usecases/get_wallet_transactions_usecase.dart';
import '../models/wallet_transaction_item.dart';
import '../utils/wallet_format_utils.dart';
import '../widgets/wallet_vcn_overlay.dart';

class WalletController extends GetxController {
  WalletController({
    required GetWalletSummaryUseCase getWalletSummaryUseCase,
    required GetWalletTransactionsUseCase getWalletTransactionsUseCase,
  }) : _getWalletSummaryUseCase = getWalletSummaryUseCase,
       _getWalletTransactionsUseCase = getWalletTransactionsUseCase;

  final GetWalletSummaryUseCase _getWalletSummaryUseCase;
  final GetWalletTransactionsUseCase _getWalletTransactionsUseCase;

  final RxBool isLoading = true.obs;
  final Rxn<WalletSummaryEntity> summary = Rxn<WalletSummaryEntity>();
  final RxList<WalletTransactionItem> recentTransactions =
      <WalletTransactionItem>[].obs;

  static const int recentPreviewCount = 3;

  // Dummy VCN until API is available.
  static const String _vcnCardNumberRaw = '1234123412321653';
  static const String _vcnExpiry = '09/27';
  static const String _vcnCvv = '786';

  String get vcnExpiry => _vcnExpiry;

  String get vcnCvv => _vcnCvv;

  @override
  void onInit() {
    super.onInit();
    unawaited(loadWallet());
  }

  Future<void> loadWallet() async {
    isLoading.value = true;
    try {
      final walletSummary = await _getWalletSummaryUseCase();
      final transactions = await _getWalletTransactionsUseCase();
      summary.value = walletSummary;
      recentTransactions.assignAll(
        transactions
            .take(recentPreviewCount)
            .map(_mapTransactionToItem)
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

  void goBack() => Get.back<void>();

  void openTransactionHistory() {
    Get.toNamed(AppRoutes.walletTransactions);
  }

  void openAddMoney() {
    unawaited(AddMoneyToWalletBottomSheet.show());
  }

  void openEStatement() {
    // Placeholder until e-statement API / flow is available.
  }

  String get formattedVcnCardNumber => formatCardNumber(_vcnCardNumberRaw);

  String get vcnCardNumberForCopy => _vcnCardNumberRaw;

  void openShowVcn() {
    unawaited(WalletVcnOverlay.show());
  }

  void closeShowVcn() => Get.back<void>();

  void copyVcnCardNumber() {
    Clipboard.setData(ClipboardData(text: vcnCardNumberForCopy));
  }

  void copyVcnCvv() {
    Clipboard.setData(const ClipboardData(text: _vcnCvv));
  }

  void copyWalletNumber() {
    final number = walletNumberForCopy;
    if (number.isEmpty) return;
    Clipboard.setData(ClipboardData(text: number));
    _showCopiedSnack();
  }

  void _showCopiedSnack() {
    Get.snackbar(
      AppStrings.wallet.tr,
      AppStrings.walletNumberCopied.tr,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  WalletTransactionItem _mapTransactionToItem(WalletTransactionEntity entity) {
    return WalletTransactionItem(
      merchantName: entity.merchantName,
      categoryLabel: entity.categoryLabel,
      amount: entity.amount,
      isCredit: entity.isCredit,
      createdAtLabel: _formatCreatedAt(entity.createdAt),
    );
  }

  String _formatCreatedAt(DateTime date) {
    return DateFormat('d MMM yyyy, h:mm a').format(date.toLocal());
  }
}
