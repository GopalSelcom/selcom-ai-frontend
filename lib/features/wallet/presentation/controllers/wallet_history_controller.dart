import 'dart:async';

import 'package:card_swiper/card_swiper.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_strings.dart';
import '../../domain/entities/wallet_transaction_entity.dart';
import '../../domain/entities/wallet_transaction_filter.dart';
import '../../domain/usecases/get_wallet_transactions_usecase.dart';
import '../models/wallet_transaction_item.dart';
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
      final entries = await Future.wait(
        WalletSegmentedTabs.filters.map((filter) async {
          final result = await _getWalletTransactionsUseCase(filter: filter);
          return MapEntry(
            filter,
            result.map(_mapTransactionToItem).toList(growable: false),
          );
        }),
      );
      transactionsByFilter.assignAll(Map.fromEntries(entries));
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

  WalletTransactionItem _mapTransactionToItem(WalletTransactionEntity entity) {
    return WalletTransactionItem(
      merchantName: entity.merchantName,
      categoryLabel: entity.categoryLabel,
      amount: entity.amount,
      isCredit: entity.isCredit,
      createdAtLabel: DateFormat(
        'd MMM yyyy, h:mm a',
      ).format(entity.createdAt.toLocal()),
    );
  }
}
