import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Text-style tap control using [CupertinoButton] (same family as OTP edit-phone).
///
/// Use for legacy [TextButton] / [InkWell] + [Text] links. Presets keep existing
/// typography and padding per screen.
class AppCupertinoTextButton extends StatelessWidget {
  const AppCupertinoTextButton({
    super.key,
    this.label,
    this.child,
    required this.onPressed,
    this.textStyle,
    this.alignment = Alignment.center,
    this.padding,
    this.minimumSize = Size.zero,
  }) : assert(label != null || child != null);

  final String? label;
  final Widget? child;
  final VoidCallback? onPressed;
  final TextStyle? textStyle;
  final AlignmentGeometry alignment;
  final EdgeInsetsGeometry? padding;
  final Size minimumSize;

  /// Home recent locations — "View more" (underlined 14sp).
  factory AppCupertinoTextButton.viewMore({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return AppCupertinoTextButton(
      key: key,
      label: label,
      onPressed: onPressed,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      textStyle: AppTextStyles.homeSubtitle.copyWith(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryButton,
        decoration: TextDecoration.underline,
        decorationColor: AppColors.primaryButton,
        decorationThickness: 1,
        height: 18 / 14,
      ),
    );
  }

  /// OTP / auth — underlined primary link (e.g. edit phone).
  factory AppCupertinoTextButton.primaryUnderlinedLink({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    AlignmentGeometry alignment = Alignment.centerLeft,
  }) {
    return AppCupertinoTextButton(
      key: key,
      label: label,
      onPressed: onPressed,
      alignment: alignment,
      textStyle: AppTextStyles.onboardingSubtitle.copyWith(
        fontSize: 16.sp,
        color: AppColors.primaryButton,
        decoration: TextDecoration.underline,
        decorationColor: AppColors.primaryButton,
        decorationThickness: 1,
        decorationStyle: TextDecorationStyle.solid,
        height: 22 / 16,
      ),
    );
  }

  /// OTP — resend code (no underline).
  factory AppCupertinoTextButton.resendOtp({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return AppCupertinoTextButton(
      key: key,
      label: label,
      onPressed: onPressed,
      textStyle: AppTextStyles.onboardingButton.copyWith(
        color: AppColors.primaryButton,
        fontSize: 15.sp,
      ),
    );
  }

  /// Ride rating sheet — skip.
  factory AppCupertinoTextButton.skip({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    AlignmentGeometry alignment = Alignment.centerRight,
  }) {
    return AppCupertinoTextButton(
      key: key,
      label: label,
      onPressed: onPressed,
      alignment: alignment,
      textStyle: AppTextStyles.homeCaption.copyWith(
        color: AppColors.textBody,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Promo / error retry.
  factory AppCupertinoTextButton.retry({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return AppCupertinoTextButton(
      key: key,
      label: label,
      onPressed: onPressed,
      textStyle: AppTextStyles.button.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Promo field inline apply.
  factory AppCupertinoTextButton.promoFieldApply({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    required bool enabled,
  }) {
    return AppCupertinoTextButton(
      key: key,
      label: label,
      onPressed: onPressed,
      textStyle: AppTextStyles.button.copyWith(
        color: enabled ? AppColors.primary : AppColors.textMutedStrong,
        fontSize: 14.sp,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  /// Promo list row apply.
  factory AppCupertinoTextButton.promoListApply({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    required bool enabled,
  }) {
    return AppCupertinoTextButton(
      key: key,
      label: label,
      onPressed: onPressed,
      textStyle: AppTextStyles.button.copyWith(
        color: enabled ? AppColors.primary : AppColors.textMutedStrong,
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
    );
  }

  /// Vehicle selection promo chip opener (icon + label row).
  factory AppCupertinoTextButton.promoChipOpener({
    Key? key,
    required Widget child,
    required VoidCallback? onPressed,
  }) {
    return AppCupertinoTextButton(
      key: key,
      onPressed: onPressed,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: child,
    );
  }

  /// Stop / route update modal — cancel update.
  factory AppCupertinoTextButton.cancelRouteUpdate({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return AppCupertinoTextButton(
      key: key,
      label: label,
      onPressed: onPressed,
      textStyle: AppTextStyles.onboardingSubtitle.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Ride details — change drop-off link.
  factory AppCupertinoTextButton.changeDropLocation({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return AppCupertinoTextButton(
      key: key,
      label: label,
      onPressed: onPressed,
      textStyle: TextStyle(
        fontFamily: AppTextStyles.metropolisFont,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryButton,
        fontSize: 12.sp,
        height: 20 / 12,
      ),
    );
  }

  /// Insufficient wallet dialog — full-width dismiss (e.g. "NO").
  factory AppCupertinoTextButton.insufficientBalanceDismiss({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
  }) {
    final textStyle = TextStyle(
      fontFamily: AppTextStyles.metropolisFont,
      fontWeight: FontWeight.w500,
      fontSize: 14.sp,
      height: 18 / 14,
      letterSpacing: 14.sp * 0.02,
      color: const Color(0xFF7F7F7F),
    );
    return AppCupertinoTextButton(
      key: key,
      label: label,
      onPressed: onPressed,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      minimumSize: Size(double.infinity, 44.h),
      textStyle: textStyle,
    );
  }

  /// Ride details footer — need help.
  factory AppCupertinoTextButton.inlineHelpLink({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return AppCupertinoTextButton(
      key: key,
      label: label,
      onPressed: onPressed,
      textStyle: AppTextStyles.homeSubtitle.copyWith(height: 20 / 15),
    );
  }

  /// Inline body link beside plain text (e.g. social login contact support).
  factory AppCupertinoTextButton.inlineBodyLink({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
    TextStyle? baseTextStyle,
  }) {
    final style = (baseTextStyle ?? AppTextStyles.bodySecondary).copyWith(
      fontWeight: FontWeight.w500,
      color: color,
      height: 20 / 14,
    );
    return AppCupertinoTextButton(
      key: key,
      label: label,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      alignment: Alignment.centerLeft,
      textStyle: style,
    );
  }

  @override
  Widget build(BuildContext context) {
    final button = CupertinoButton(
      padding: padding ?? EdgeInsets.zero,
      minimumSize: minimumSize,
      alignment: alignment,
      onPressed: onPressed,
      child: child ?? Text(label!, style: textStyle, textAlign: TextAlign.center),
    );
    if (minimumSize.width >= double.infinity) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
