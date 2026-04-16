import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/selcom_pesa_connect_bottom_sheet.dart';

class PaymentMethodsController extends GetxController {
  final RxString walletBalance = '43,829'.obs;
  final RxString walletNumber = '16010 00000 034'.obs;

  @override
  void onInit() {
    super.onInit();
    // In a real app, we would fetch data here
  }

  void handleBack() {
    Get.back();
  }

  void linkSelcomPesa() {
    Get.bottomSheet(
      const SelcomPesaConnectBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void addCard() {
    // Placeholder for adding card
    Get.snackbar('Cards', 'Add card functionality coming soon.');
  }
}
