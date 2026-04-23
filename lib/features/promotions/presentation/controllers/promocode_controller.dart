import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../shared/utils/app_dialogs.dart';

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
      AppDialogs.showSuccessDialog(
        message: 'Promo code $code applied!',
      );
    } else {
      AppDialogs.showErrorDialog(
        message: 'Please enter a promo code',
      );
    }
  }

  void applyPromo(PromocodeModel promo) {
    AppDialogs.showSuccessDialog(
      message: 'Promo "${promo.title}" applied!',
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
