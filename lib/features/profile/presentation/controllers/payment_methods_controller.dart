import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/selcom_pesa_connect_bottom_sheet.dart';
import '../widgets/selcom_pesa_phone_input_bottom_sheet.dart';
import '../widgets/selcom_pesa_otp_bottom_sheet.dart';

class PaymentMethodsController extends GetxController {
  final RxString walletBalance = '43,829'.obs;
  final RxString walletNumber = '16010 00000 034'.obs;

  // Phone input controller
  final TextEditingController selcomPhoneController = TextEditingController();

  // OTP controller
  final TextEditingController otpController = TextEditingController();
  final RxInt resendTimer = 60.obs;
  final RxString otpError = ''.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    // In a real app, we would fetch data here
  }

  @override
  void onClose() {
    selcomPhoneController.dispose();
    otpController.dispose();
    _stopTimer();
    super.onClose();
  }

  void _startTimer() {
    _stopTimer();
    resendTimer.value = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendTimer.value > 0) {
        resendTimer.value--;
      } else {
        _stopTimer();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void resendOtp() {
    _startTimer();
    Get.snackbar('Selcom Pesa', 'OTP resent successfully');
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
      Get.back();
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
    openOtpInput();
  }

  void openOtpInput() {
    if (Get.isBottomSheetOpen ?? false) {
      Get.back();
    }
    otpController.clear();
    otpError.value = '';
    _startTimer();
    Get.bottomSheet(
      const SelcomPesaOtpBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void onOtpComplete(String pin) {
    if (pin == '111111') {
      otpError.value = 'Invalid OTP. Please try again.';
      return;
    }
    otpError.value = '';
    // Placeholder for completion logic
    Get.back(); // Close OTP sheet
    Get.snackbar('Selcom Pesa', 'Account linked successfully!');
  }

  void addCard() {
    // Placeholder for adding card
    Get.snackbar('Cards', 'Add card functionality coming soon.');
  }

  void openPaymentMethods() {
    // Placeholder for potential navigation
  }
}
