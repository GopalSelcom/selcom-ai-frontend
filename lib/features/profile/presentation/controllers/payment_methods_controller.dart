import 'package:get/get.dart';

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
    // Placeholder for linking logic
    Get.snackbar('Selcom Pesa', 'Linking flow will be implemented next.');
  }

  void addCard() {
    // Placeholder for adding card
    Get.snackbar('Cards', 'Add card functionality coming soon.');
  }
}
