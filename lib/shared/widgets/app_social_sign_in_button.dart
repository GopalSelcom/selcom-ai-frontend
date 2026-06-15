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

  static const double _iconSize = 21;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null;
    final icon = _leadingIconFor(provider);

    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: Material(
        color: AppColors.socialSignInNeutralBackground,
        borderRadius: BorderRadius.circular(12.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          splashColor: AppColors.socialSignInGoogleText.withValues(alpha: 0.08),
          highlightColor: AppColors.socialSignInGoogleText.withValues(
            alpha: 0.04,
          ),
          child: Opacity(
            opacity: isDisabled ? 0.6 : 1,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: _iconSize.w,
                    height: _iconSize.w,
                    child: Center(child: icon),
                  ),
                  SizedBox(width: 16.w),
                  Text(
                    _labelFor(provider),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.socialSignInButtonLabel.copyWith(
                      color: AppColors.socialSignInGoogleText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: _iconSize.w),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _labelFor(SocialSignInProvider provider) {
    return switch (provider) {
      SocialSignInProvider.google => AppStrings.signInWithGoogle.tr,
      SocialSignInProvider.facebook => AppStrings.signInWithFacebook.tr,
      SocialSignInProvider.apple => AppStrings.signInWithApple.tr,
    };
  }

  static Widget _leadingIconFor(SocialSignInProvider provider) {
    return switch (provider) {
      SocialSignInProvider.google => SvgPictureAsset(
        AppAssets.icGoogle,
        width: _iconSize.w,
        height: _iconSize.w,
      ),
      SocialSignInProvider.facebook => SvgPictureAsset(
        AppAssets.icFacebook,
        width: _iconSize.w,
        height: _iconSize.w,
      ),
      SocialSignInProvider.apple => Icon(
        Icons.apple,
        size: 22.w,
        color: AppColors.black,
      ),
    };
  }
}
