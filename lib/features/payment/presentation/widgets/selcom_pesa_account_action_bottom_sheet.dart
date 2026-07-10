import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../profile/data/models/selcom_pesa_link_models.dart';
import '../../../profile/presentation/controllers/payment_methods_controller.dart';

class SelcomPesaAccountActionBottomSheet extends StatelessWidget {
  const SelcomPesaAccountActionBottomSheet({
    super.key,
    required this.account,
    required this.paymentMethodsController,
  });

  final Account account;
  final PaymentMethodsController paymentMethodsController;

  static Future<void> show({
    required Account account,
    required PaymentMethodsController paymentMethodsController,
  }) {
    return AppDialogs.showStandardBottomSheet<void>(
      title: AppStrings.selcomPesa.tr,
      subtitle: paymentMethodsController.phoneDisplayFor(account),
      headerTextAlign: TextAlign.center,
      content: SelcomPesaAccountActionBottomSheet(
        account: account,
        paymentMethodsController: paymentMethodsController,
      ),
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDefault = account.isDefault ?? false;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isDefault) ...[
          _ActionOptionTile(
            icon: Icons.star_rounded,
            title: AppStrings.setAsDefault.tr,
            subtitle: AppStrings.setAsDefaultConfirm.tr,
            iconColor: AppColors.primary,
            iconBackgroundColor: AppColors.primary.withAlpha(26), // 10% opacity
            onTap: () {
              Get.back();
              unawaited(paymentMethodsController.setDefaultAccount(account));
            },
          ),
          SizedBox(height: 16.h),
        ],
        _ActionOptionTile(
          icon: Icons.delete_rounded,
          title: AppStrings.removeAccountTitle.tr,
          subtitle: AppStrings.removeAccountMessage.tr,
          iconColor: AppColors.error,
          iconBackgroundColor: AppColors.error.withAlpha(26), // 10% opacity
          onTap: () {
            Get.back();
            AppDialogs.showConfirmationDialog(
              title: AppStrings.removeAccountTitle.tr,
              message: AppStrings.removeAccountMessage.tr,
              confirmText: AppStrings.removeLabel.tr,
              confirmColor: AppColors.brandRed,
              onConfirm: () => unawaited(
                paymentMethodsController.unlinkLinkedAccount(account),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ActionOptionTile extends StatelessWidget {
  const _ActionOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color iconBackgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 16.sp),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textMuted,
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }
}
