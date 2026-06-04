import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';

/// Profile wallet row when Go wallet is not linked yet.
class WalletLinkCard extends StatelessWidget {
  const WalletLinkCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(27.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            border: Border.all(
              color: AppColors.borderWalletCard,
              width: 0.8,
            ),
            borderRadius: BorderRadius.circular(27.r),
          ),
          child: Row(
            children: [
              Container(
                width: 51.w,
                height: 51.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(12.w),
                child: const SvgPictureAsset(
                  AppAssets.icWallet,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 13.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.wallet.tr,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textHeading,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        height: 20 / 15,
                      ),
                    ),
                    Text(
                      AppStrings.linkWalletSubtitle.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textBody,
                        fontSize: 12.sp,
                        height: 20 / 12,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                AppStrings.linkAccount.tr,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                  height: 20 / 14,
                ),
              ),
              SizedBox(width: 4.w),
              SvgPictureAsset(
                AppAssets.icArrowForward,
                width: 18.w,
                height: 18.w,
                color: AppColors.primary,
                placeholderBuilder: (_) => Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16.sp,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
