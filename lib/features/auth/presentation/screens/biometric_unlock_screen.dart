import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../controllers/biometric_unlock_controller.dart';
import '../widgets/login_pin_auth_shell.dart';

/// Cold-start unlock via Face ID / fingerprint when server `biometric_enabled`.
///
/// Shown from [LoginPinGateService.resolveColdStartRoute] if hardware is available.
/// Fallback: [AppRoutes.pinLogin].
class BiometricUnlockScreen extends GetView<BiometricUnlockController> {
  const BiometricUnlockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LoginPinAuthShell(
      showBackButton: false,
      title: AppStrings.unlockWithBiometric.tr,
      subtitle: AppStrings.biometricUnlockHint.tr,
      body: Column(
        children: [
          SizedBox(height: 24.h),
          Icon(
            Iconsax.finger_scan,
            size: Get.height * 0.14,
            color: AppColors.primary,
          ),
        ],
      ),
      errorBanner: Obx(() => _errorBanner()),
      bottom: Column(
        children: [
          Obx(
            () => AppPrimaryButton(
              label: AppStrings.unlockWithBiometric.tr,
              isLoading: controller.isLoading.value,
              onPressed: controller.authenticate,
            ),
          ),
          SizedBox(height: 12.h),
          TextButton(
            onPressed: controller.cancelToPin,
            child: Text(
              AppStrings.usePinInstead.tr,
              style: LoginPinAuthShell.subtitleStyle(context).copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  Widget _errorBanner() {
    final msg = controller.errorMessage.value;
    if (msg.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.otpErrorBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.otpErrorBorder),
      ),
      child: Row(
        children: [
          SvgPictureAsset(
            AppAssets.icError,
            width: 22.w,
            height: 22.h,
            color: AppColors.otpErrorBorder,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              msg,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textHeading,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
