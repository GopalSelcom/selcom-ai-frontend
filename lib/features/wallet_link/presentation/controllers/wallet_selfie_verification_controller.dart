import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:m7_livelyness_detection/m7_livelyness_detection.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../wallet_link_flow_data.dart';

/// Selfie / liveness step — parity with selcom_auth [LivelinessScreen].
class WalletSelfieVerificationController extends GetxController {
  final isCapturing = false.obs;

  WalletLinkFlowData get _flow => Get.find<WalletLinkFlowData>();

  Future<void> takeSelfie() async {
    if (isCapturing.value) return;
    isCapturing.value = true;

    try {
      final isSimulator = await _isSimulator();
      if (isSimulator) {
        _onSelfieSuccess();
        return;
      }

      final status = await Permission.camera.request();
      if (!status.isGranted) {
        AppDialogs.showPermissionDialog(
          title: AppStrings.cameraPermission.tr,
          message: AppStrings.cameraAccessNeededForSelfieVerification.tr,
          onOpenSettings: openAppSettings,
          icon: Icons.camera_alt_outlined,
          secondaryIcon: Icons.camera_alt,
        );
        return;
      }

      final context = Get.context;
      if (context == null) return;

      M7LivelynessDetection.instance.configure(
        thresholds: [
          M7BlinkDetectionThreshold(
            leftEyeProbability: 0.5,
            rightEyeProbability: 0.5,
          ),
        ],
        lineColor: AppColors.primaryButton.withValues(alpha: 0.35),
        dotColor: AppColors.primaryButton.withValues(alpha: 0.35),
        displayDots: true,
        displayLines: true,
      );

      final response = await M7LivelynessDetection.instance.detectLivelyness(
        context,
        config: M7DetectionConfig(
          maxSecToDetect: 120,
          allowAfterMaxSec: true,
          steps: [
            M7LivelynessStepItem(
              step: M7LivelynessStep.smile,
              title: AppStrings.smile.tr,
              isCompleted: false,
              detectionColor: AppColors.primaryButton.withValues(alpha: 0.35),
            ),
            M7LivelynessStepItem(
              step: M7LivelynessStep.blink,
              title: AppStrings.blinkYourEyes.tr,
              isCompleted: false,
              detectionColor: AppColors.primaryButton.withValues(alpha: 0.35),
            ),
          ],
          captureButtonColor: AppColors.primaryButton,
          startWithInfoScreen: false,
        ),
      );

      if (response != null && response.imgPath.isNotEmpty) {
        _flow.selfieImagePath = response.imgPath;
        _onSelfieSuccess();
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppDialogs.showErrorDialog(message: AppStrings.selfieCaptureFailed.tr);
    } finally {
      isCapturing.value = false;
    }
  }

  void _onSelfieSuccess() {
    // TODO(wallet-link): LiveliessRepository.verifySelfieAPINew when API is ready.
    AppDialogs.showVerificationSuccessDialog(
      onConfirm: _flow.completeAndReturnToProfile,
    );
  }

  Future<bool> _isSimulator() async {
    final deviceInfo = DeviceInfoPlugin();
    if (GetPlatform.isIOS) {
      return !(await deviceInfo.iosInfo).isPhysicalDevice;
    }
    if (GetPlatform.isAndroid) {
      return !(await deviceInfo.androidInfo).isPhysicalDevice;
    }
    return false;
  }
}
