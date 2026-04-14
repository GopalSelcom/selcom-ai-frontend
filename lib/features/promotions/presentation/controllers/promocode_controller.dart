import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PromocodeController extends GetxController {
  final RxList<PromocodeModel> promocodes = <PromocodeModel>[].obs;
  final TextEditingController promoCodeTextController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _loadStaticPromocodes();
  }

  @override
  void onClose() {
    promoCodeTextController.dispose();
    super.onClose();
  }

  void _loadStaticPromocodes() {
    promocodes.assignAll([
      PromocodeModel(
        title: '20% Off on your first ride Booking',
        subtitle: 'Maximum Promo TZS 1500',
        footer: '21 days left',
      ),
      PromocodeModel(
        title: '20% Off on your first ride Booking',
        subtitle: 'Maximum Promo TZS 1500',
        footer: '21 days left',
      ),
    ]);
  }

  void applyPromoCode() {
    final code = promoCodeTextController.text;
    if (code.isNotEmpty) {
      Get.snackbar(
        'Success',
        'Promo code $code applied!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Error',
        'Please enter a promo code',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void applyPromo(PromocodeModel promo) {
    Get.snackbar(
      'Success',
      'Promo "${promo.title}" applied!',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

class PromocodeModel {
  final String title;
  final String subtitle;
  final String footer;

  PromocodeModel({
    required this.title,
    required this.subtitle,
    required this.footer,
  });
}
