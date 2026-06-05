import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/app_animated_reveal.dart';
import '../../../../../shared/widgets/app_primary_button.dart';
import '../../../../../shared/widgets/app_profile_header.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../controllers/active_wallet_form_controller.dart';
import '../../widgets/custom_scrollbar_widget.dart';

class ActiveWalletFormScreen extends GetView<ActiveWalletFormController> {
  const ActiveWalletFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    final double computedBottomPadding = bottomPadding > 0
        ? (GetPlatform.isIOS ? 0 : 8.h)
        : 16.h;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppProfileHeader(
            title: AppStrings.enterNidaWalletActivation.tr,
            onBack: Get.back,
          ),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.walletActiveFormTitle.tr,
                  style: AppTextStyles.homeTitle,
                ),
                SizedBox(height: 6.h),
                Text(
                  AppStrings.activeWalletSubtitle.tr,
                  style: AppTextStyles.homeSubtitle,
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: CustomScrollBar(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildFormCard(),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            bottom: true,
            child: Obx(
              () => AppAnimatedReveal(
                show: controller.isSubmitEnabled.value,
                visibleKey: const ValueKey('active-wallet-submit-visible'),
                hiddenKey: const ValueKey('active-wallet-submit-hidden'),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16.w,
                    0,
                    16.w,
                    computedBottomPadding,
                  ),
                  child: AppPrimaryButton(
                    label: AppStrings.activateWallet.tr,
                    backgroundColor: AppColors.walletColor,
                    isLoading: controller.isSubmitting.value,
                    onPressed: controller.submit,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 20.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: AppColors.pageBackground,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.walletLinkFullNameSubtitle.tr,
            style: AppTextStyles.homeCaption.copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          AppTextField(
            maxLength: 120,
            textColor: AppColors.textHeading,
            label: AppStrings.fullName.tr,
            hintText: AppStrings.fullName.tr,
            controller: controller.nameController,
            textInputAction: TextInputAction.next,
            textFieldBackgroundColor: AppColors.white,
          ),
          SizedBox(height: 16.h),
          Text(
            AppStrings.walletLinkDateOfBirth.tr,
            style: AppTextStyles.cardTitle.copyWith(
              color: AppColors.textMutedStrong,
              fontWeight: FontWeight.w500,
              fontSize: 15.sp,
            ),
          ),
          SizedBox(height: 5.h),
          GestureDetector(
            onTap: controller.openDateOfBirthPicker,
            behavior: HitTestBehavior.opaque,
            child: AbsorbPointer(
              child: AppTextField(
                readOnly: true,
                fontSize: 12.sp,
                textColor: AppColors.textHeading,
                textFieldBackgroundColor: AppColors.white,
                controller: controller.dobController,
                hintText: AppStrings.walletLinkDatePlaceholder.tr,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          AppTextField(
            maxLength: 15,
            textColor: AppColors.textHeading,
            label: AppStrings.phoneNumber.tr,
            hintText: AppStrings.phoneNumber.tr,
            controller: controller.phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textFieldBackgroundColor: AppColors.white,
          ),
          SizedBox(height: 16.h),
          AppTextField(
            textColor: AppColors.textHeading,
            label: AppStrings.email.tr,
            hintText: AppStrings.enterYourEmailOptional.tr,
            controller: controller.emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            textFieldBackgroundColor: AppColors.white,
          ),
          SizedBox(height: 16.h),
          AppTextField(
            maxLength: 120,
            textColor: AppColors.textHeading,
            label: AppStrings.walletActiveAddress1.tr,
            hintText: AppStrings.walletActiveAddress1.tr,
            controller: controller.address1Controller,
            textInputAction: TextInputAction.next,
            textFieldBackgroundColor: AppColors.white,
          ),
          SizedBox(height: 16.h),
          AppTextField(
            maxLength: 120,
            textColor: AppColors.textHeading,
            label: AppStrings.walletActiveAddress2.tr,
            hintText: AppStrings.walletActiveAddress2.tr,
            controller: controller.address2Controller,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => controller.submit(),
            textFieldBackgroundColor: AppColors.white,
          ),
        ],
      ),
    );
  }
}
