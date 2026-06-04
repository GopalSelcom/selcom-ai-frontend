import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/wallet_full_name_controller.dart';

/// Full name capture — parity with selcom_auth [AskUserFullNameScreen].
class WalletFullNameScreen extends GetView<WalletFullNameController> {
  const WalletFullNameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: Obx(
        () => AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.fromLTRB(
            20.w,
            8.h,
            20.w,
            bottomInset > 0 ? bottomInset + 12.h : 16.h,
          ),
          child: SafeArea(
            top: false,
            child: AppPrimaryButton(
              label: AppStrings.continueLabel.tr,
              width: double.infinity,
              height: 52.h,
              onPressed: controller.isButtonEnabled.value
                  ? controller.submitNames
                  : null,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              SizedBox(height: 16.h),
              SvgPictureAsset(
                AppAssets.selcomGoLogo,
                width: 154.w,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 24.h),
              Text(
                AppStrings.walletLinkEnterYourName.tr,
                style: AppTextStyles.onboardingTitle.copyWith(
                  fontSize: 28.sp,
                  height: 34 / 28,
                  letterSpacing: -0.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                AppStrings.walletLinkFullNameSubtitle.tr,
                style: AppTextStyles.bodySecondary.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              AppTextField(
                label: AppStrings.walletLinkFirstName.tr,
                hintText: AppStrings.walletLinkFirstName.tr,
                controller: controller.firstNameController,
                textInputAction: TextInputAction.next,
                onChanged: (_) => controller.validateFields(),
                textFieldBackgroundColor: AppColors.cardBackground,
              ),
              SizedBox(height: 16.h),
              AppTextField(
                label: AppStrings.walletLinkMiddleName.tr,
                hintText: AppStrings.walletLinkMiddleName.tr,
                controller: controller.middleNameController,
                textInputAction: TextInputAction.next,
                onChanged: (_) => controller.validateFields(),
                textFieldBackgroundColor: AppColors.cardBackground,
              ),
              SizedBox(height: 16.h),
              AppTextField(
                label: AppStrings.walletLinkLastName.tr,
                hintText: AppStrings.walletLinkLastName.tr,
                controller: controller.lastNameController,
                textInputAction: TextInputAction.done,
                onChanged: (_) => controller.validateFields(),
                textFieldBackgroundColor: AppColors.cardBackground,
              ),
              SizedBox(height: 100.h),
            ],
          ),
        ),
      ),
    );
  }
}
