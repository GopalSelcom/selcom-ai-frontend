import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/utils/currency_formatter.dart';

class WalletSummaryCard extends StatelessWidget {
  final String balance;
  final String walletNumber;
  final VoidCallback? onTap;

  const WalletSummaryCard({
    super.key,
    required this.balance,
    required this.walletNumber,
    this.onTap,
  });

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
        ), // Divider/Primary
        borderRadius: BorderRadius.circular(27.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Side: Icon + Texts
          Row(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.wallet.tr,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textHeading, // fill_IETHWP
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      height: 20 / 15,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        walletNumber,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textBody,
                          fontSize: 12.sp,
                          height: 20 / 12,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: walletNumber));
                        },
                        behavior: HitTestBehavior.opaque,
                        child: SvgPictureAsset(
                          AppAssets.icCopy,
                          width: 14.w,
                          height: 14.w,
                          placeholderBuilder: (_) => Icon(
                            Iconsax.copy,
                            size: 14.w,
                            color: AppColors.textHeading.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Right Side: Amount + Arrow
          Row(
            children: [
              Text(
                '${CurrencyFormatter.displaySymbol} $balance',
                style: AppTextStyles.price.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 19.03.sp,
                  height: 23.11 / 19.03,
                  letterSpacing: -0.27,
                ),
              ),
              SizedBox(width: 8.w),
              SvgPictureAsset(
                AppAssets.icArrowForward,
                width: 20.w,
                height: 20.w,
                color: AppColors.textHeading.withValues(alpha: 0.5),
                placeholderBuilder: (_) => Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 24.w,
                  color: AppColors.textHeading.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }
}
