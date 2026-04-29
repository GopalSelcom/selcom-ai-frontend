import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/svg_picture_asset.dart';

class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double? height;
  final String? iconAsset;
  final Color? iconColor;

  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.iconAsset,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 56.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 24.w),
        ),
        child: isLoading
            ? SizedBox(
                width: 24.w,
                height: 24.w,
                child: const CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              )
            : SizedBox.expand(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(label, style: AppTextStyles.button),
                    if (iconAsset != null)
                      Positioned(
                        right: 0,
                        child: iconAsset!.endsWith('.svg')
                            ? SvgPictureAsset(
                                iconAsset!,
                                width: 18.w,
                                height: 18.w,
                                color: iconColor ?? AppColors.white,
                              )
                            : Image.asset(
                                iconAsset!,
                                width: 18.w,
                                height: 18.w,
                                color: iconColor,
                              ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

