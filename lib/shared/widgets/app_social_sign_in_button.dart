import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/constants/app_assets.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/svg_picture_asset.dart';

enum SocialSignInProvider { google, facebook, apple }

/// Shared SSO CTA used for Google, Facebook, and Apple on the login screen.
class AppSocialSignInButton extends StatelessWidget {
  const AppSocialSignInButton({
    super.key,
    required this.provider,
    required this.onPressed,
  });

  final SocialSignInProvider provider;
  final VoidCallback? onPressed;

  static const double _iconSize = 20;

  @override
  Widget build(BuildContext context) {
    final theme = _themeFor(provider);
    final double effectiveBorderRadius = 8.r;
    final bool isDisabled = onPressed == null;
    final icon = _leadingIconFor(provider, theme.iconColor);

    final materialChild = InkWell(
      onTap: isDisabled ? null : onPressed,
      splashColor: theme.splashColor,
      highlightColor: theme.highlightColor,
      child: Opacity(
        opacity: isDisabled ? 0.6 : 1,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            children: [
              SizedBox(
                width: _iconSize.w,
                height: _iconSize.w,
                child: Center(child: icon),
              ),
              Expanded(
                child: Text(
                  _labelFor(provider),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.socialSignInButtonLabel.copyWith(
                    color: theme.labelColor,
                  ),
                ),
              ),
              SizedBox(width: _iconSize.w),
            ],
          ),
        ),
      ),
    );

    return SizedBox(
      width: double.infinity,
      child: theme.hasOutlinedShape
          ? Material(
              color: theme.backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(effectiveBorderRadius),
                side: BorderSide(color: theme.borderColor!, width: 1),
              ),
              clipBehavior: Clip.antiAlias,
              elevation: isDisabled ? 0 : 0.5,
              shadowColor: AppColors.shadowCard,
              child: materialChild,
            )
          : Material(
              color: theme.backgroundColor,
              borderRadius: BorderRadius.circular(effectiveBorderRadius),
              clipBehavior: Clip.antiAlias,
              child: materialChild,
            ),
    );
  }

  static String _labelFor(SocialSignInProvider provider) {
    return switch (provider) {
      SocialSignInProvider.google => AppStrings.continueWithGoogle.tr,
      SocialSignInProvider.facebook => AppStrings.continueWithFacebook.tr,
      SocialSignInProvider.apple => AppStrings.continueWithApple.tr,
    };
  }

  static Widget _leadingIconFor(
    SocialSignInProvider provider,
    Color? iconColor,
  ) {
    return switch (provider) {
      SocialSignInProvider.google => SvgPictureAsset(
        AppAssets.icGoogleLogo,
        width: _iconSize.w,
        height: _iconSize.w,
      ),
      SocialSignInProvider.facebook => SvgPictureAsset(
        AppAssets.icFacebookLogo,
        width: _iconSize.w,
        height: _iconSize.w,
      ),
      SocialSignInProvider.apple => Icon(
        Icons.apple,
        size: 22.w,
        color: iconColor ?? AppColors.socialSignInLabelOnDark,
      ),
    };
  }

  static _SocialSignInButtonTheme _themeFor(SocialSignInProvider provider) {
    return switch (provider) {
      SocialSignInProvider.google => _SocialSignInButtonTheme(
        backgroundColor: AppColors.socialSignInGoogleBackground,
        borderColor: AppColors.socialSignInGoogleBorder,
        labelColor: AppColors.socialSignInGoogleText,
        splashColor: AppColors.socialSignInGoogleText.withValues(alpha: 0.06),
        highlightColor: AppColors.socialSignInGoogleText.withValues(
          alpha: 0.04,
        ),
        hasOutlinedShape: true,
      ),
      SocialSignInProvider.facebook => _SocialSignInButtonTheme(
        backgroundColor: AppColors.socialSignInFacebookBackground,
        labelColor: AppColors.socialSignInLabelOnDark,
        splashColor: AppColors.socialSignInLabelOnDark.withValues(alpha: 0.12),
        highlightColor: AppColors.socialSignInLabelOnDark.withValues(
          alpha: 0.06,
        ),
      ),
      SocialSignInProvider.apple => _SocialSignInButtonTheme(
        backgroundColor: AppColors.socialSignInAppleBackground,
        labelColor: AppColors.socialSignInLabelOnDark,
        iconColor: AppColors.socialSignInLabelOnDark,
        splashColor: AppColors.socialSignInLabelOnDark.withValues(alpha: 0.08),
        highlightColor: AppColors.socialSignInLabelOnDark.withValues(
          alpha: 0.04,
        ),
      ),
    };
  }
}

class _SocialSignInButtonTheme {
  const _SocialSignInButtonTheme({
    required this.backgroundColor,
    required this.labelColor,
    required this.splashColor,
    required this.highlightColor,
    this.borderColor,
    this.iconColor,
    this.hasOutlinedShape = false,
  });

  final Color backgroundColor;
  final Color? borderColor;
  final Color labelColor;
  final Color splashColor;
  final Color highlightColor;
  final Color? iconColor;
  final bool hasOutlinedShape;
}
