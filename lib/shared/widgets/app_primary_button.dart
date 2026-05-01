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
  final bool outlined;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? outlinedBorderColor;
  final Color? outlinedTextColor;
  final double? borderRadius;
  final double? outlinedBorderWidth;

  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.iconAsset,
    this.iconColor,
    this.outlined = false,
    this.backgroundColor,
    this.textColor,
    this.outlinedBorderColor,
    this.outlinedTextColor,
    this.borderRadius,
    this.outlinedBorderWidth,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveBackgroundColor =
        backgroundColor ?? (outlined ? AppColors.white : AppColors.primary);
    final Color effectiveOutlinedBorderColor =
        outlinedBorderColor ?? AppColors.primary;
    final Color effectiveTextColor =
        textColor ?? (outlined ? AppColors.primary : AppColors.white);
    final Color effectiveOutlinedTextColor =
        outlinedTextColor ?? effectiveTextColor;
    final double effectiveBorderRadius = borderRadius ?? AppRadius.button;
    final double effectiveOutlinedBorderWidth = outlinedBorderWidth ?? 1.5;

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 56.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBackgroundColor,
          disabledBackgroundColor: outlined
              ? effectiveBackgroundColor
              : effectiveBackgroundColor.withValues(alpha: 0.5),
          foregroundColor: outlined
              ? effectiveOutlinedTextColor
              : effectiveTextColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            side: outlined
                ? BorderSide(
                    color: effectiveOutlinedBorderColor,
                    width: effectiveOutlinedBorderWidth,
                  )
                : BorderSide.none,
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
                    Text(
                      label,
                      style: AppTextStyles.button.copyWith(
                        color: outlined
                            ? effectiveOutlinedTextColor
                            : effectiveTextColor,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (iconAsset != null)
                      Positioned(
                        right: 0,
                        child: iconAsset!.endsWith('.svg')
                            ? SvgPictureAsset(
                                iconAsset!,
                                width: 18.w,
                                height: 18.w,
                                color:
                                    iconColor ??
                                    (outlined
                                        ? effectiveOutlinedTextColor
                                        : effectiveTextColor),
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
