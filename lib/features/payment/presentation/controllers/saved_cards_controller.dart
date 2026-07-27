import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/widgets/web_view_screen.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../../../wallet/presentation/utils/wallet_refresh.dart';
import '../../../wallet/data/models/go_wallet_card_model.dart';
import '../../../wallet/data/models/model_status_msg.dart';
import '../../../profile/presentation/screens/add_card_screen.dart';

enum SavedCardsStep { cardList, amountEntry }

class SavedCardsController extends GetxController {
  final WalletRepository _walletRepository;

  SavedCardsController({
    WalletRepository? walletRepository,
  }) : _walletRepository = walletRepository ?? sl<WalletRepository>();

  final step = SavedCardsStep.cardList.obs;
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final cards = <Datum>[].obs;
  final selectedCard = Rxn<Datum>();
  final amountError = RxnString();
  final apiError = RxnString();

  TextEditingController amountController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    amountController = TextEditingController();
  }

  @override
  void onClose() {
    amountController.clear();
    super.onClose();
  }

  void resetState() {
    step.value = SavedCardsStep.cardList;
    selectedCard.value = null;
    amountController.clear();
    amountError.value = null;
    apiError.value = null;
    isLoading.value = false;
    isSubmitting.value = false;
  }

  Future<void> loadCards() async {
    isLoading.value = true;
    apiError.value = null;

    final result = await _walletRepository.fetchCards();

    result.fold(
      (failure) {
        apiError.value = failure.message;
        isLoading.value = false;
      },
      (list) {
        cards.assignAll(list);
        isLoading.value = false;
      },
    );
  }

  Future<Either<Failure, ModelStatusMsg>> deleteCard(int id) async {
    final result = await _walletRepository.deleteCard(id: id);
    if (result.isRight()) {
      await loadCards();
    }
    return result;
  } 

  void selectCard(Datum card) {
    selectedCard.value = card;
    step.value = SavedCardsStep.amountEntry;
    amountError.value = null;
    apiError.value = null;
  }

  void backToCardList() {
    step.value = SavedCardsStep.cardList;
    selectedCard.value = null;
    amountError.value = null;
    apiError.value = null;
  }

  Future<void> onAddCardPressed() async {
    final result = await Get.to<dynamic>(
      () => const AddCardScreen(),
    );
    if (result == true) {
      await loadCards();
    }
  }

  Future<void> submitTopUp() async {
    final amountText = amountController.text.replaceAll(RegExp(r'\D'), '');
    if (amountText.isEmpty) {
      amountError.value = AppStrings.amountIsRequired.tr;
      return;
    }
    final amount = int.tryParse(amountText);
    if (amount == null || amount < 100) {
      amountError.value = "Minimum top-up is TZS 100";
      return;
    }

    isSubmitting.value = true;
    amountError.value = null;
    apiError.value = null;

    if (selectedCard.value != null) {
      // Flow B: Saved Card Top-up
      final addResult = await _walletRepository.goAddCardNew(
        amount: amount,
        newCard: 1,
      );

      await addResult.fold(
        (failure) async {
          apiError.value = failure.message;
          isSubmitting.value = false;
        },
        (response) async {
          final payResult = await _walletRepository.goPayByExistingCard(
            transId: response.transId,
            cardToken: selectedCard.value!.cardToken ?? '',
          );

          payResult.fold(
            (failure) {
              apiError.value = failure.message;
              isSubmitting.value = false;
            },
            (_) async {
              isSubmitting.value = false;
              Get.back<void>(); // close sheet

              unawaited(WalletRefresh.afterBalanceChange());

              AppDialogs.showWalletTopupSuccessDialog(
                title: AppStrings.walletFundsReceivedTitle.tr,
                confirmLabel: AppStrings.ok,
                barrierDismissible: true,
              );
            },
          );
        },
      );
    } else {
      // Flow A: New Card (WebView)
      final addResult = await _walletRepository.goAddCardNew(
        amount: amount,
        newCard: 0,
      );

      await addResult.fold(
        (failure) async {
          apiError.value = failure.message;
          isSubmitting.value = false;
        },
        (response) async {
          isSubmitting.value = false;
          Get.back<void>(); // close sheet

          // Open Selcom Hosted Checkout page
          final success = await WebViewScreen.open<bool>(
            url: response.url,
            title: AppStrings.addMoneyToWallet.tr,
          );

          unawaited(WalletRefresh.afterBalanceChange());

          if (success == true) {
            AppDialogs.showWalletTopupSuccessDialog(
              title: AppStrings.walletFundsReceivedTitle.tr,
              confirmLabel: AppStrings.ok,
              barrierDismissible: true,
            );
          }
        },
      );
    }
  }
}
