import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/selcom_pesa_connect_bottom_sheet.dart';
import '../widgets/selcom_pesa_phone_input_bottom_sheet.dart';

class PaymentMethodsController extends GetxController {
  final RxString walletBalance = '43,829'.obs;
  final RxString walletNumber = '16010 00000 034'.obs;

  // Phone input controller
  final TextEditingController selcomPhoneController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // In a real app, we would fetch data here
  }

  @override
  void onClose() {
    selcomPhoneController.dispose();
    super.onClose();
  }

  void handleBack() {
    Get.back();
  }

  void linkSelcomPesa() {
    selcomPhoneController.clear();
    Get.bottomSheet(
      const SelcomPesaConnectBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void openPhoneInput() {
    if (Get.isBottomSheetOpen ?? false) {
      Get.back(); // Close previous bottom sheet
    }
    Get.bottomSheet(
      const SelcomPesaPhoneInputBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void onPhoneContinue() {
    if (selcomPhoneController.text.trim().isEmpty) {
      Get.snackbar('Validation', 'Please enter your phone number');
      return;
    }
    // Placeholder for next step
    Get.snackbar(
      'Selcom Pesa',
      'Phone number submitted: ${selcomPhoneController.text}',
    );
  }

  void addCard() {
    // Placeholder for adding card
    Get.snackbar('Cards', 'Add card functionality coming soon.');
  }
}
