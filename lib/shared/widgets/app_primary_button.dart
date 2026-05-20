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
  final bool placeIconAfterLabel;
  /// When true (and an icon is shown), label stays centered and the icon is pinned to the **right**
  /// inside the horizontal padding — typical onboarding CTA. Ignored when [isLoading] or [outlined].
  final bool alignIconToTrailingEnd;
  /// Inner shadow along the **bottom** of the fill only (onboarding CTA).
  /// Ignored when [outlined] is true.
  final bool showBottomInnerShadow;
  /// When set (e.g. onboarding CTA), overrides default button typography.
  final TextStyle? labelStyle;

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
    this.placeIconAfterLabel = false,
    this.alignIconToTrailingEnd = false,
    this.showBottomInnerShadow = false,
    this.labelStyle,
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
    final Widget? iconWidget = iconAsset == null
        ? null
        : iconAsset!.endsWith('.svg')
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
              );

    TextStyle resolvedLabelStyle() {
      if (labelStyle != null) {
        return labelStyle!.copyWith(
          color: outlined ? effectiveOutlinedTextColor : effectiveTextColor,
        );
      }
      return AppTextStyles.button.copyWith(
        color: outlined ? effectiveOutlinedTextColor : effectiveTextColor,
        fontSize: 16.sp,
        fontWeight: FontWeight.w700,
      );
    }

    final buttonChild = isLoading
        ? SizedBox(
            width: 24.w,
            height: 24.w,
            child: CircularProgressIndicator(
              color: outlined ? effectiveOutlinedTextColor : effectiveTextColor,
              strokeWidth: 2,
            ),
          )
        : alignIconToTrailingEnd &&
                !outlined &&
                iconWidget != null
            ? Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: resolvedLabelStyle(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  iconWidget,
                ],
              )
        : placeIconAfterLabel
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: resolvedLabelStyle(),
                  ),
                  if (iconWidget != null) ...[
                    SizedBox(width: 4.w),
                    iconWidget,
                  ],
                ],
              )
            : SizedBox.expand(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      label,
                      style: resolvedLabelStyle(),
                    ),
                    if (iconWidget != null)
                      Positioned(right: 0, child: iconWidget),
                  ],
                ),
              );

    if (showBottomInnerShadow && !outlined) {
      return _buildPrimaryWithFace3d(
        buttonChild: buttonChild,
        effectiveBackgroundColor: effectiveBackgroundColor,
        effectiveBorderRadius: effectiveBorderRadius,
        effectiveTextColor: effectiveTextColor,
      );
    }

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
        child: buttonChild,
      ),
    );
  }

  /// Full-height pill with a bottom-only inner shadow (no top highlight).
  Widget _buildPrimaryWithFace3d({
    required Widget buttonChild,
    required Color effectiveBackgroundColor,
    required double effectiveBorderRadius,
    required Color effectiveTextColor,
  }) {
    final disabled = isLoading || onPressed == null;
    final fillColor = disabled
        ? effectiveBackgroundColor.withValues(alpha: 0.5)
        : effectiveBackgroundColor;
    final r = effectiveBorderRadius;

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 56.h,
      child: Material(
        color: fillColor,
        borderRadius: BorderRadius.circular(r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(r),
          onTap: disabled ? null : onPressed,
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: 0.38,
                    widthFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.1),
                            Colors.black.withValues(alpha: 0.3),
                          ],
                          stops: const [0.0, 0.75, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Center(
                  child: IconTheme.merge(
                    data: IconThemeData(color: effectiveTextColor),
                    child: DefaultTextStyle.merge(
                      style: TextStyle(color: effectiveTextColor),
                      child: buttonChild,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
