import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:passport_mrz_capture/passport_mrz_capture.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../bindings/wallet_full_name_binding.dart';
import '../screens/wallet_full_name_screen.dart';
import '../wallet_link_flow_data.dart';

class WalletPassportScanController extends GetxController {
  WalletLinkFlowData get _flow => Get.find<WalletLinkFlowData>();

  void openNfcScan(BuildContext context) {
    Get.snackbar(
      AppStrings.walletLinkPassportScanTitle.tr,
      AppStrings.walletLinkNfcComingSoon.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> openCameraScan(BuildContext context) async {
    await PassportMrzCapture.capture(
      context: context,
      config: const PassportMrzCaptureConfig(
        screenTitle: '',
        includeFaceImage: true,
      ),
      onSuccess: (_) async {
        await _openFullName();
      },
      onFailure: (failure) {
        if (failure.code == PassportMrzCaptureErrorCode.cancelled) return;
        Get.snackbar(
          AppStrings.walletLinkPassportScanTitle.tr,
          failure.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.errorBackground,
          colorText: AppColors.textHeading,
        );
      },
    );
  }

  Future<void> _openFullName() async {
    await Get.to(
      () => const WalletFullNameScreen(),
      binding: WalletFullNameBinding(),
    );
    _flow.recordRoutePush();
  }
}
