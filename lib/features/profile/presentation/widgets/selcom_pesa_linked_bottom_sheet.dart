import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../payment/domain/wallet_payment_phone_country.dart';
import '../controllers/payment_methods_controller.dart';

class SelcomPesaLinkedBottomSheet {
  SelcomPesaLinkedBottomSheet._();

  static Future<void> show() {
    return AppDialogs.showStandardBottomSheet<void>(
      title: AppStrings.yourLinkedAccount.tr,
      headerTextAlign: TextAlign.start,
      showHeaderDivider: true,
      barrierDismissible: true,
      content: const _SelcomPesaLinkedContent(),
      footer: const _SelcomPesaLinkedFooter(),
    );
  }
}

class _SelcomPesaLinkedContent extends GetView<PaymentMethodsController> {
  const _SelcomPesaLinkedContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildReadOnlyField(
          label: AppStrings.fullName.tr,
          value: 'Chirag panchal',
        ),
        SizedBox(height: 20.h),
        _buildReadOnlyField(
          label: AppStrings.phoneNumber.tr,
          value: '${WalletPaymentPhoneCountry.dialCodeDisplay} 711 410 410',
        ),
        SizedBox(height: 24.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPictureAsset(
              AppAssets.icAccountVerified,
              width: 24.w,
              height: 24.w,
            ),
            SizedBox(width: 12.w),
            Text(
              AppStrings.accountVerified.tr,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textVerified,
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: 48.h),
      ],
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textBody,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.borderWalletCard),
          ),
          child: Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textHeading,
            ),
          ),
        ),
      ],
    );
  }
}

class _SelcomPesaLinkedFooter extends GetView<PaymentMethodsController> {
  const _SelcomPesaLinkedFooter();

  @override
  Widget build(BuildContext context) {
    return AppPrimaryButton(
      label: AppStrings.removeAccount.tr,
      onPressed: controller.unlinkAccount,
      height: 56.h,
      borderRadius: 16.r,
      outlined: true,
      backgroundColor: AppColors.white,
      textColor: AppColors.primaryButton,
      outlinedTextColor: AppColors.primaryButton,
      outlinedBorderColor: AppColors.primaryButton,
      outlinedBorderWidth: 1,
    );
  }
}
