import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/constants/app_assets.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/svg_picture_asset.dart';

/// Branded Facebook Login button aligned with Meta's blue CTA style.
class AppFacebookSignInButton extends StatelessWidget {
  const AppFacebookSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.height,
    this.borderRadius,
  });

  static const Color _facebookBlue = Color(0xFF1877F2);

  final VoidCallback? onPressed;
  final bool isLoading;
  final double? height;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final double effectiveHeight = height ?? 50.h;
    final double effectiveBorderRadius = borderRadius ?? 8.r;
    final bool isDisabled = isLoading || onPressed == null;

    return SizedBox(
      width: double.infinity,
      height: effectiveHeight,
      child: Material(
        color: _facebookBlue,
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          child: Opacity(
            opacity: isDisabled ? 0.6 : 1,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 22.w,
                    height: 22.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  Text(
                    AppStrings.continueWithFacebook.tr,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.homeSubtitle.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.2,
                      letterSpacing: -0.16,
                    ),
                  ),
                if (!isLoading)
                  Positioned(
                    left: 16.w,
                    child: SvgPictureAsset(
                      AppAssets.icFacebookLogo,
                      width: 20.w,
                      height: 20.w,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
