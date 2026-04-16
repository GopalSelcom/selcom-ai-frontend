import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:m7_livelyness_detection/index.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../widgets/selcom_pesa_connect_bottom_sheet.dart';
import '../widgets/selcom_pesa_phone_input_bottom_sheet.dart';
import '../widgets/selcom_pesa_otp_bottom_sheet.dart';
import '../widgets/selcom_pesa_selfie_bottom_sheet.dart';

class PaymentMethodsController extends GetxController {
  final RxString walletBalance = '43,829'.obs;
  final RxString walletNumber = '16010 00000 034'.obs;

  // Phone input controller
  final TextEditingController selcomPhoneController = TextEditingController();
  final RxString phoneError = ''.obs;

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
    phoneError.value = '';
    Get.bottomSheet(
      const SelcomPesaPhoneInputBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void onPhoneContinue() {
    final phone = selcomPhoneController.text.replaceAll(' ', '');
    if (phone.isEmpty) {
      phoneError.value = 'Please enter your phone number';
      return;
    }

    if (phone.length < 9) {
      phoneError.value = 'Please enter a valid phone number';
      return;
    }

    phoneError.value = '';
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
    openSelfieVerification();
  }

  void openSelfieVerification() {
    if (Get.isBottomSheetOpen ?? false) {
      Get.back();
    }
    Get.bottomSheet(
      const SelcomPesaSelfieBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> takeSelfie() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      AppDialogs.showPermissionDialog(
        title: 'Camera Permission',
        message:
            'We need camera access to capture your selfie for identity verification. Please enable it in your device settings.',
        onOpenSettings: () => openAppSettings(),
        icon: Icons.camera_alt_outlined,
        secondaryIcon: Icons.camera_alt,
      );
      return;
    }

    M7LivelynessDetection.instance.configure(
      thresholds: [
        M7BlinkDetectionThreshold(
          leftEyeProbability: 0.5,
          rightEyeProbability: 0.5,
        ),
      ],
      lineColor: Colors.blue.shade200,
      dotColor: Colors.blue.shade200,
      displayDots: true,
      displayLines: true,
    );

    try {
      final response = await M7LivelynessDetection.instance.detectLivelyness(
        Get.context!,
        config: M7DetectionConfig(
          maxSecToDetect: 120,
          allowAfterMaxSec: true,
          steps: [
            M7LivelynessStepItem(
              step: M7LivelynessStep.smile,
              title: 'Smile',
              isCompleted: false,
              detectionColor: Colors.blue.shade200,
            ),
            M7LivelynessStepItem(
              step: M7LivelynessStep.blink,
              title: 'Blink Your Eyes',
              isCompleted: false,
              detectionColor: Colors.blue.shade200,
            ),
          ],
          captureButtonColor: AppColors.primary,
          startWithInfoScreen: false,
        ),
      );

      if (response != null && response.imgPath.isNotEmpty) {
        // Just mock the success as per user request
        if (Get.isBottomSheetOpen ?? false) {
          Get.back(); // Close selfie sheet
        }
        Get.snackbar('Selcom Pesa', 'Selfie captured successfully!');

        Future.delayed(const Duration(seconds: 1), () {
          Get.snackbar('Selcom Pesa', 'Account linked successfully!');
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Selfie capture failed');
    }
  }

  void addCard() {
    // Placeholder for adding card
    Get.snackbar('Cards', 'Add card functionality coming soon.');
  }

  void openPaymentMethods() {
    // Placeholder for potential navigation
  }
}
