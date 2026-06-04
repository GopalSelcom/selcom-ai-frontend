import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';

/// Circular icon + label (Add money, E-Statement).
class WalletIconLabelButton extends StatelessWidget {
  const WalletIconLabelButton({
    super.key,
    required this.label,
    required this.iconAsset,
    required this.onTap,
    this.iconHeight,
  });

  final String label;
  final String iconAsset;
  final VoidCallback onTap;
  final double? iconHeight;

  @override
  Widget build(BuildContext context) {
    final size = iconHeight ?? 24.h;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 51.94.w,
                width: 51.94.w,
                alignment: Alignment.center,
                padding: EdgeInsets.all(15.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.borderWalletCard,
                    width: 0.8,
                  ),
                ),
                child: SvgPictureAsset(
                  iconAsset,
                  height: size,
                  width: size,
                  color: AppColors.primaryButton,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.walletCardText,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
