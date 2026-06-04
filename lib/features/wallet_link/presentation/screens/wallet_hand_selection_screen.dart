import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../controllers/wallet_hand_selection_controller.dart';

/// Hand selection — parity with selcom_auth [HandSelectionScreen].
class WalletHandSelectionScreen extends GetView<WalletHandSelectionController> {
  const WalletHandSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 0),
              child: Row(
                children: [
                  AppBackButton(
                    color: AppColors.textHeading,
                    size: 22.w,
                    onPressed: Get.back,
                  ),
                  Expanded(
                    child: Text(
                      AppStrings.walletLinkBiometricAuth.tr,
                      style: AppTextStyles.sectionTitle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 40.w),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _HandOption(
                    selected: controller.isLeftHandSelected,
                    imageAsset: AppAssets.walletLinkLeftHand,
                    label: AppStrings.walletLinkLeftHand.tr,
                    onTap: controller.selectLeftHand,
                    mirrorCheck: true,
                  ),
                  _HandOption(
                    selected: controller.isRightHandSelected,
                    imageAsset: AppAssets.walletLinkRightHand,
                    label: AppStrings.walletLinkRightHand.tr,
                    onTap: controller.selectRightHand,
                    mirrorCheck: false,
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
                    child: Column(
                      children: [
                        Obx(
                          () => AppPrimaryButton(
                            label: AppStrings.continueLabel.tr,
                            width: double.infinity,
                            height: 52.h,
                            onPressed: controller.hasHandSelected
                                ? controller.openFingerScanInstructions
                                : null,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Obx(
                          () => TextButton(
                            onPressed: controller.hasHandSelected
                                ? controller.openMissingFingers
                                : null,
                            child: Text(
                              AppStrings.walletLinkHaveMissingFingers.tr,
                              style: AppTextStyles.bodySecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HandOption extends StatelessWidget {
  const _HandOption({
    required this.selected,
    required this.imageAsset,
    required this.label,
    required this.onTap,
    required this.mirrorCheck,
  });

  final RxBool selected;
  final String imageAsset;
  final String label;
  final VoidCallback onTap;
  final bool mirrorCheck;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final isSelected = selected.value;
        return GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 20.h),
                child: CircleAvatar(
                  radius: 15.r,
                  backgroundColor: isSelected
                      ? AppColors.primaryButton
                      : AppColors.textMuted,
                  child: Icon(
                    Icons.check,
                    size: 18.sp,
                    color: isSelected ? AppColors.white : Colors.transparent,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Column(
                children: [
                  Container(
                    height: 0.22.sh,
                    width: 0.62.sw,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      color: AppColors.bgVerificationSurface,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryButton
                            : AppColors.borderDefault,
                        width: 2,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: mirrorCheck ? 10.w : 0,
                    ),
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.fitHeight,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    label,
                    style: AppTextStyles.cardTitle.copyWith(
                      color: isSelected
                          ? AppColors.primaryButton
                          : AppColors.textBody,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
