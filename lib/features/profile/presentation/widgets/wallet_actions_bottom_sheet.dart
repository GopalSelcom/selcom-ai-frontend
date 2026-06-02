import 'dart:async';

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
import '../../../payment/presentation/widgets/add_money_to_wallet_bottom_sheet.dart';

class WalletActionsBottomSheet extends StatelessWidget {
  const WalletActionsBottomSheet({super.key});

  static Future<void> show() {
    return AppDialogs.showStandardBottomSheet<void>(
      title: AppStrings.wallet.tr,
      headerTextAlign: TextAlign.center,
      showHeaderDivider: true,
      barrierDismissible: true,
      content: const WalletActionsBottomSheet(),
      footer: AppPrimaryButton(
        label: AppStrings.back.tr,
        onPressed: () => Get.back<void>(),
        outlined: true,
        width: double.infinity,
        height: 56.h,
        borderRadius: 16.r,
        backgroundColor: AppColors.white,
        textColor: AppColors.iconHeartFilled,
        outlinedTextColor: AppColors.iconHeartFilled,
        outlinedBorderColor: AppColors.iconHeartFilled,
        outlinedBorderWidth: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WalletActionTile(
          title: AppStrings.addMoney.tr,
          onTap: _openAddMoneySheet,
        ),
        SizedBox(height: 194.h),
      ],
    );
  }

  void _openAddMoneySheet() {
    Get.back<void>();
    unawaited(
      Future<void>.delayed(
        const Duration(milliseconds: 120),
        AddMoneyToWalletBottomSheet.show,
      ),
    );
  }
}

class _WalletActionTile extends StatelessWidget {
  const _WalletActionTile({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceSubtle,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.borderWalletCard, width: 0.8),
          ),
          child: Row(
            children: [
              Container(
                width: 52.w,
                height: 52.w,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: SvgPictureAsset(
                  AppAssets.icCardReceive,
                  width: 24.w,
                  height: 24.w,
                  color: const Color(0XFF662AB2),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.homeTitle.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              SvgPictureAsset(
                AppAssets.icArrowForward,
                width: 20.w,
                height: 20.w,
                color: AppColors.iconHeartOutline,
                placeholderBuilder: (_) => Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18.sp,
                  color: AppColors.iconHeartOutline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
