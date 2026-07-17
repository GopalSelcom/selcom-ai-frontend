import 'dart:async';

import 'package:card_swiper/card_swiper.dart';
import 'package:get/get.dart';

import '../../../../core/constants/currency_code.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../domain/entities/wallet_transaction_filter.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../domain/usecases/get_wallet_transactions_usecase.dart';
import '../models/wallet_transaction_item.dart';
import '../utils/wallet_transaction_mapper.dart';
import '../widgets/wallet_segmented_tabs.dart';

class WalletHistoryController extends GetxController {
  WalletHistoryController({
    required GetWalletTransactionsUseCase getWalletTransactionsUseCase,
  }) : _getWalletTransactionsUseCase = getWalletTransactionsUseCase;

  final GetWalletTransactionsUseCase _getWalletTransactionsUseCase;

  final SwiperController swiperController = SwiperController();
  final RxBool isLoading = true.obs;
  final Rx<WalletTransactionFilter> selectedFilter =
      WalletTransactionFilter.all.obs;
  final RxMap<WalletTransactionFilter, List<WalletTransactionItem>>
  transactionsByFilter =
      <WalletTransactionFilter, List<WalletTransactionItem>>{}.obs;

  bool _suppressSwiperIndexCallback = false;

  @override
  void onInit() {
    super.onInit();
    unawaited(loadAllFilters());
  }

  @override
  void onClose() {
    swiperController.dispose();
    super.onClose();
  }

  Future<void> loadAllFilters() async {
    isLoading.value = true;
    try {
      // Match [refreshTransactions] — initial load must not reuse a prior
      // user's cached statement after account switch.
      sl<WalletRepository>().invalidateStatementCache();
      await _fetchTransactions();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshTransactions() async {
    sl<WalletRepository>().invalidateStatementCache();
    await _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    // Reuse session currency so history never needs go_card_balance.
    final currency = ProfileWalletCache.currency.trim().isNotEmpty
        ? ProfileWalletCache.currency.trim()
        : CommonValues.currencyCode;
    final transactions = await _getWalletTransactionsUseCase(
      filter: WalletTransactionFilter.all,
      currencyOverride: currency,
    );
    transactionsByFilter.assignAll(groupWalletTransactionsByFilter(transactions));
  }

  List<WalletTransactionItem> transactionsForFilter(
    WalletTransactionFilter filter,
  ) =>
      transactionsByFilter[filter] ?? const [];

  Future<void> onSwiperIndexChanged(int index) async {
    if (_suppressSwiperIndexCallback) return;
    final filter = WalletSegmentedTabs.filters[index];
    if (selectedFilter.value == filter) return;
    selectedFilter.value = filter;
  }

  Future<void> selectFilter(WalletTransactionFilter filter) async {
    final index = WalletSegmentedTabs.filters.indexOf(filter);
    if (index < 0 || selectedFilter.value == filter) return;

    selectedFilter.value = filter;
    _suppressSwiperIndexCallback = true;
    swiperController.move(index);
    _suppressSwiperIndexCallback = false;
  }

  String filterLabel(WalletTransactionFilter filter) {
    return switch (filter) {
      WalletTransactionFilter.all => AppStrings.filterAll.tr,
      WalletTransactionFilter.received => AppStrings.filterReceived.tr,
      WalletTransactionFilter.sent => AppStrings.filterSent.tr,
    };
  }
}
