import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddCardController extends GetxController {
  final cardHolderController = TextEditingController();
  final cardNumberController = TextEditingController();
  final expiryController = TextEditingController();
  final cvvController = TextEditingController();

  final fullNameFocus = FocusNode();
  final cardNumberFocus = FocusNode();
  final expiryFocus = FocusNode();
  final cvvFocus = FocusNode();

  final isCvvHidden = true.obs;
  final isSubmitting = false.obs;

  final fullNameError = RxnString();
  final cardNumberError = RxnString();
  final expiryError = RxnString();
  final cvvError = RxnString();

  @override
  void onClose() {
    cardHolderController.dispose();
    cardNumberController.dispose();
    expiryController.dispose();
    cvvController.dispose();
    fullNameFocus.dispose();
    cardNumberFocus.dispose();
    expiryFocus.dispose();
    cvvFocus.dispose();
    super.onClose();
  }

  void toggleCvvVisibility() {
    isCvvHidden.value = !isCvvHidden.value;
  }

  void onFieldChanged() {
    // Keep UX responsive by clearing stale field errors while typing.
    fullNameError.value = null;
    cardNumberError.value = null;
    expiryError.value = null;
    cvvError.value = null;
  }

  void focusCardNumber() => cardNumberFocus.requestFocus();

  void focusExpiry() => expiryFocus.requestFocus();

  void focusCvv() => cvvFocus.requestFocus();

  Future<void> submitCard() async {
    if (isSubmitting.value) {
      return;
    }

    if (!_validateForm()) {
      return;
    }

    isSubmitting.value = true;
    try {
      // TODO(api): Replace this with AddCard use case + repository call.
      // For now we return success and let caller show success bottom sheet.
      await Future.delayed(const Duration(seconds: 3));
      Get.back(result: true);
    } finally {
      isSubmitting.value = false;
    }
  }

  bool _validateForm() {
    final fullName = cardHolderController.text.trim();
    final cardNumber = cardNumberController.text.replaceAll(' ', '');
    final expiry = expiryController.text.trim();
    final cvv = cvvController.text.trim();

    fullNameError.value = null;
    cardNumberError.value = null;
    expiryError.value = null;
    cvvError.value = null;

    if (fullName.isEmpty) {
      fullNameError.value = 'Full Name is required';
    }

    if (cardNumber.isEmpty) {
      cardNumberError.value = 'Card Number is required';
    } else if (cardNumber.length != 16) {
      cardNumberError.value = 'Card Number must be 16 digits';
    }

    if (expiry.isEmpty) {
      expiryError.value = 'Expiry is required';
    } else if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(expiry)) {
      expiryError.value = 'Use MM/YY format';
    } else {
      final month = int.tryParse(expiry.substring(0, 2)) ?? 0;
      if (month < 1 || month > 12) {
        expiryError.value = 'Invalid month';
      }
    }

    if (cvv.isEmpty) {
      cvvError.value = 'CVV is required';
    } else if (cvv.length != 3) {
      cvvError.value = 'CVV must be 3 digits';
    }

    return fullNameError.value == null &&
        cardNumberError.value == null &&
        expiryError.value == null &&
        cvvError.value == null;
  }
}
