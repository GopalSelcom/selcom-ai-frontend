import 'dart:async';
import 'package:get/get.dart';
import 'package:m7_livelyness_detection/index.dart' hide Rx;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:selcom_rides_frontend/core/constants/app_assets.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../domain/entities/payment_card.dart';
import '../screens/add_card_screen.dart';
import '../screens/card_details_screen.dart';
import '../widgets/payment_card_action_bottom_sheet.dart';
import '../widgets/selcom_pesa_linked_bottom_sheet.dart';
import '../widgets/selcom_pesa_flow_bottom_sheet.dart';

enum SelcomPesaStep { connect, phoneInput, otp, selfie }

class PaymentMethodsController extends GetxController {
  final Rx<SelcomPesaStep> selcomPesaStep = SelcomPesaStep.connect.obs;
  final RxString walletBalance = '43,829'.obs;
  final RxString walletNumber = '16010 00000 034'.obs;
  final RxBool isSelcomPesaLinked = false.obs;

  // Phone input controller
  final TextEditingController selcomPhoneController = TextEditingController();
  final RxString phoneError = ''.obs;
  final RxBool canContinueSelcomPhone = false.obs;

  // OTP controller
  final TextEditingController otpController = TextEditingController();
  final RxInt resendTimer = 60.obs;
  final RxString otpError = ''.obs;
  Timer? _timer;

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
    AppDialogs.showSuccessDialog(
      title: AppStrings.selcomPesa.tr,
      message: AppStrings.otpResentSuccessfully.tr,
    );
  }

  void handleBack() {
    Get.back();
  }

  void linkSelcomPesa() {
    selcomPhoneController.clear();
    selcomPesaStep.value = SelcomPesaStep.connect;
    SelcomPesaFlowBottomSheet.show();
  }

  void openPhoneInput() {
    phoneError.value = '';
    _updateCanContinueSelcomPhone();
    selcomPesaStep.value = SelcomPesaStep.phoneInput;
  }

  void openLinkedAccountSheet() {
    SelcomPesaLinkedBottomSheet.show();
  }

  void unlinkAccount() {
    AppDialogs.closeActiveDialog(); // Close bottom sheet
    isSelcomPesaLinked.value = false;
    // Optional: Clear selection or reset other states
    AppDialogs.showSuccessDialog(
      title: AppStrings.selcomPesa.tr,
      message: AppStrings.accountUnlinkedSuccessfully.tr,
    );
  }

  void onSelcomPhoneChanged(String _) {
    if (phoneError.value.isNotEmpty) {
      phoneError.value = '';
    }
    _updateCanContinueSelcomPhone();
  }

  void _updateCanContinueSelcomPhone() {
    final phone = selcomPhoneController.text.replaceAll(' ', '');
    // Same rules as [onPhoneContinue]: TZ local number after +255 (digits only, min 9).
    canContinueSelcomPhone.value = phone.isNotEmpty && phone.length >= 9;
  }

  void onPhoneContinue() {
    final phone = selcomPhoneController.text.replaceAll(' ', '');
    if (phone.isEmpty) {
      phoneError.value = AppStrings.pleaseEnterYourPhoneNumber.tr;
      return;
    }

    if (phone.length < 9) {
      phoneError.value = AppStrings.pleaseEnterAValidPhoneNumber.tr;
      return;
    }

    phoneError.value = '';
    _updateCanContinueSelcomPhone();
    openOtpInput();
  }

  void openOtpInput() {
    otpController.clear();
    otpError.value = '';
    _startTimer();
    selcomPesaStep.value = SelcomPesaStep.otp;
  }

  void onOtpComplete(String pin) {
    if (pin == '111111') {
      otpError.value = AppStrings.invalidOtpPleaseTryAgain.tr;
      return;
    }
    otpError.value = '';
    openSelfieVerification();
  }

  void openSelfieVerification() {
    selcomPesaStep.value = SelcomPesaStep.selfie;
  }

  Future<void> takeSelfie() async {
    // Simulator check to allow testing flow without camera
    bool isSimulator = false;
    final deviceInfo = DeviceInfoPlugin();
    if (GetPlatform.isIOS) {
      isSimulator = !(await deviceInfo.iosInfo).isPhysicalDevice;
    } else if (GetPlatform.isAndroid) {
      isSimulator = !(await deviceInfo.androidInfo).isPhysicalDevice;
    }

    if (isSimulator) {
      AppDialogs.closeActiveDialog(); // Close selfie sheet
      AppDialogs.showVerificationSuccessDialog();
      Future.delayed(const Duration(seconds: 3), () {
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
        isSelcomPesaLinked.value = true;
      });
      return;
    }

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      AppDialogs.showPermissionDialog(
        title: AppStrings.cameraPermission.tr,
        message: AppStrings.cameraAccessNeededForSelfieVerification.tr,
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
      lineColor: AppColors.inputBorderActive.withValues(alpha: 0.35),
      dotColor: AppColors.inputBorderActive.withValues(alpha: 0.35),
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
              title: AppStrings.smile.tr,
              isCompleted: false,
              detectionColor: AppColors.inputBorderActive.withValues(
                alpha: 0.35,
              ),
            ),
            M7LivelynessStepItem(
              step: M7LivelynessStep.blink,
              title: AppStrings.blinkYourEyes.tr,
              isCompleted: false,
              detectionColor: AppColors.inputBorderActive.withValues(
                alpha: 0.35,
              ),
            ),
          ],
          captureButtonColor: AppColors.primary,
          startWithInfoScreen: false,
        ),
      );

      if (response != null && response.imgPath.isNotEmpty) {
        // Just mock the success as per user request
        AppDialogs.closeActiveDialog(); // Close selfie sheet

        AppDialogs.showVerificationSuccessDialog();

        // Auto dismiss after 3 seconds and update state
        Future.delayed(const Duration(seconds: 3), () {
          if (Get.isDialogOpen ?? false) {
            Get.back();
          }
          isSelcomPesaLinked.value = true;
          // Refresh or navigate if needed, but since it's reactive, the UI will update
        });
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppDialogs.showErrorDialog(message: AppStrings.selfieCaptureFailed.tr);
    }
  }

  Future<void> addCard() async {
    final result = await Get.to<PaymentCard>(() => const AddCardScreen());

    if (result != null) {
      AppDialogs.showAnimatedBottomSheet(
        child: PaymentCardActionBottomSheet(
          title: AppStrings.yourCardHasBeenNaddedSuccessfully.tr,
          description: AppStrings.cardReadyToUseYouCanManageOrRemoveAnytime.tr,
          cardNumber: result.fullNumber,
          imageAssetPath: AppAssets.imgPaymentAddCardSuccess,
          primaryButtonLabel: AppStrings.ok.tr,
          onPrimaryPressed: AppDialogs.closeActiveDialog,
          iconAsset: AppAssets.locationIcArrowRight,
        ),
        barrierDismissible: true,
      );
    }
  }

  void openCardDetails(PaymentCard card) {
    Get.to(() => CardDetailsScreen(card: card));
  }

  void openPaymentMethods() {
    // Placeholder for potential navigation
  }
}
