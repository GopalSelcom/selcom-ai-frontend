import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:selcom_rides_frontend/core/constants/app_assets.dart';
import 'package:selcom_rides_frontend/core/theme/app_colors.dart';
import 'package:selcom_rides_frontend/core/theme/app_text_styles.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';
import 'package:get/get.dart';

class WalletSummaryCard extends StatelessWidget {
  final String balance;
  final String walletNumber;

  const WalletSummaryCard({
    super.key,
    required this.balance,
    required this.walletNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
              Image.asset(
                AppAssets.walletPattern,
                width: 51.w,
                height: 51.h,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    SizedBox(width: 51.w, height: 51.h),
              ),
              SizedBox(width: 12.w),
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
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Text(
                        walletNumber,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textBody,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: walletNumber));
                        },
                        child: Icon(
                          Iconsax.copy,
                          size: 14.w,
                          color: AppColors.textHeading.withValues(alpha: 0.5),
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
                'TZS $balance',
                style: AppTextStyles.price.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 18.sp,
                ),
              ),
              SizedBox(width: 4.w),
              Icon(
                Iconsax.arrow_right_3,
                size: 24.w,
                color: AppColors.textHeading.withValues(alpha: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
