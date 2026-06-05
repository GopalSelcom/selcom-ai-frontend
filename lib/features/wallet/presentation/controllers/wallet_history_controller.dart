import 'dart:async';

import 'package:card_swiper/card_swiper.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../domain/entities/wallet_transaction_filter.dart';
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
      final transactions = await _getWalletTransactionsUseCase(
        filter: WalletTransactionFilter.all,
      );
      transactionsByFilter.assignAll(groupWalletTransactionsByFilter(transactions));
    } finally {
      isLoading.value = false;
    }
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
