import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../profile/presentation/controllers/payment_methods_controller.dart';
import '../../../wallet/presentation/utils/wallet_refresh.dart';
import '../../../../core/data/models/user_profile_models.dart';

enum SavedCardsStep { cardList, amountEntry }

class SavedCardsController extends GetxController {
  final ProfileRepository _profileRepository;
  final String controllerTag;

  SavedCardsController({
    ProfileRepository? profileRepository,
    required this.controllerTag,
  }) : _profileRepository = profileRepository ?? sl<ProfileRepository>();

  final step = SavedCardsStep.cardList.obs;
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final cards = <PaymentMethodModel>[].obs;
  final selectedCard = Rxn<PaymentMethodModel>();
  final amountError = RxnString();
  final apiError = RxnString();

  final TextEditingController amountController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadCards();
  }

  @override
  void onClose() {
    amountController.dispose();
    super.onClose();
  }

  Future<void> loadCards() async {
    isLoading.value = true;
    apiError.value = null;

    final result = await _profileRepository.getPaymentMethods();

    result.fold(
      (failure) {
        apiError.value = failure.message;
        isLoading.value = false;
      },
      (methods) {
        cards.assignAll(methods.where((m) => m.type == 'card').toList());
        isLoading.value = false;
      },
    );
  }

  void selectCard(PaymentMethodModel card) {
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

  void onAddCardPressed() {
    Get.back<void>(); // close sheet first
    final paymentController = Get.isRegistered<PaymentMethodsController>()
        ? Get.find<PaymentMethodsController>()
        : Get.put(PaymentMethodsController());
    unawaited(paymentController.addCard());
  }

  Future<void> submitTopUp() async {
    final amountText = amountController.text.replaceAll(RegExp(r'\D'), '');
    if (amountText.isEmpty) {
      amountError.value = AppStrings.amountIsRequired.tr;
      return;
    }
    final amount = int.tryParse(amountText);
    if (amount == null || amount <= 0) {
      amountError.value = AppStrings.enterValidAmount.tr;
      return;
    }

    isSubmitting.value = true;
    amountError.value = null;
    apiError.value = null;

    // Simulate API call for card top up
    await Future.delayed(const Duration(seconds: 2));

    isSubmitting.value = false;

    Get.back<void>(); // Close bottom sheet

    // Refresh wallet balance
    unawaited(WalletRefresh.afterBalanceChange());

    // Show success dialog (dismissable with an OK button/message)
    AppDialogs.showSuccessDialog(
      message: AppStrings.walletFundsReceivedTitle.tr,
      confirmLabel: AppStrings.ok,
      barrierDismissible: true,
    );
  }
}
