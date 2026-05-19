import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/widgets/app_back_button.dart';

/// Layout shell for PIN and biometric auth screens.
///
/// Two visual modes ([LoginPinHeaderStyle]):
/// - **branded:** back + centered logo, centered title/subtitle, spacer before footer.
/// - **compact:** back only, left-aligned title/subtitle (phone/OTP typography), no logo.
///
/// Also used by [BiometricUnlockScreen]. Parent owns loading overlay on [LoginPinScreen].
enum LoginPinHeaderStyle {
  /// Centered logo + titles (setup / login).
  branded,

  /// Left-aligned titles like phone / OTP screens (change PIN).
  compact,
}

/// Scrollable scaffold for PIN/biometric flows (`pageBackground`, safe area).
class LoginPinAuthShell extends StatelessWidget {
  const LoginPinAuthShell({
    super.key,
    required this.body,
    this.onBack,
    this.showBackButton = true,
    this.bottom,
    this.pinField,
    this.errorBanner,
    this.title,
    this.subtitle,
    this.titleWidget,
    this.subtitleWidget,
    this.headerStyle = LoginPinHeaderStyle.branded,
  });

  final Widget body;
  final VoidCallback? onBack;
  final bool showBackButton;
  final Widget? bottom;
  final Widget? pinField;
  final Widget? errorBanner;
  final String? title;
  final String? subtitle;
  final Widget? titleWidget;
  final Widget? subtitleWidget;
  final LoginPinHeaderStyle headerStyle;

  bool get _isCompact => headerStyle == LoginPinHeaderStyle.compact;

  static EdgeInsets screenPadding(BuildContext context, {bool compact = false}) {
    return EdgeInsets.symmetric(
      horizontal: compact ? 16.w : 20.w,
      vertical: compact ? 0 : 16.h,
    );
  }

  static double headerAfterLogoGapFor(LoginPinHeaderStyle style) =>
      style == LoginPinHeaderStyle.compact ? 16.h : 50.h;

  static double titleSubtitleGapFor(LoginPinHeaderStyle style) =>
      style == LoginPinHeaderStyle.compact ? 8.h : 5.h;

  static double beforePinGapFor(LoginPinHeaderStyle style) =>
      style == LoginPinHeaderStyle.compact ? 32.h : 50.h;

  static double get afterPinGap => 20.h;

  static TextStyle titleStyle(
    BuildContext context, {
    LoginPinHeaderStyle style = LoginPinHeaderStyle.branded,
  }) {
    if (style == LoginPinHeaderStyle.compact) {
      return AppTextStyles.onboardingTitle.copyWith(
        fontSize: 28.sp,
        height: 34 / 28,
        letterSpacing: -0.4,
        color: AppColors.textHeading,
      );
    }
    return AppTextStyles.onboardingTitle.copyWith(
      fontSize: 19.sp,
      height: 1.3,
      fontWeight: FontWeight.w600,
      color: AppColors.textHeading,
    );
  }

  static TextStyle subtitleStyle(
    BuildContext context, {
    LoginPinHeaderStyle style = LoginPinHeaderStyle.branded,
  }) {
    return AppTextStyles.homeSubtitle.copyWith(
      fontSize: 15.sp,
      fontWeight: FontWeight.w500,
      color: AppColors.textBody,
      height: style == LoginPinHeaderStyle.compact ? 20 / 15 : 1.3,
    );
  }

  @override
  Widget build(BuildContext context) {
    final align = _isCompact ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    final textAlign = _isCompact ? TextAlign.start : TextAlign.center;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: screenPadding(context, compact: _isCompact),
                    child: Column(
                      crossAxisAlignment: align,
                      children: [
                        if (_isCompact) ...[
                          SizedBox(height: 10.h),
                          if (showBackButton)
                            AppBackButton(
                              color: AppColors.textHeading,
                              showOnlyWhenCanPop: false,
                              onPressed: onBack ?? () => Get.back(),
                            ),
                          SizedBox(height: headerAfterLogoGapFor(headerStyle)),
                        ] else
                          _BrandedHeader(onBack: onBack, showBack: showBackButton),
                        if (!_isCompact)
                          SizedBox(height: headerAfterLogoGapFor(headerStyle)),
                        if (titleWidget != null)
                          Align(
                            alignment:
                                _isCompact ? Alignment.centerLeft : Alignment.center,
                            widthFactor: _isCompact ? 1 : null,
                            child: titleWidget!,
                          )
                        else if (title != null)
                          Text(
                            title!,
                            textAlign: textAlign,
                            style: titleStyle(context, style: headerStyle),
                          ),
                        if (subtitleWidget != null) ...[
                          SizedBox(height: titleSubtitleGapFor(headerStyle)),
                          Align(
                            alignment:
                                _isCompact ? Alignment.centerLeft : Alignment.center,
                            widthFactor: _isCompact ? 1 : null,
                            child: subtitleWidget!,
                          ),
                        ] else if (subtitle != null) ...[
                          SizedBox(height: titleSubtitleGapFor(headerStyle)),
                          Text(
                            subtitle!,
                            textAlign: textAlign,
                            style: subtitleStyle(context, style: headerStyle),
                          ),
                        ],
                        if (pinField != null) ...[
                          SizedBox(height: beforePinGapFor(headerStyle)),
                          pinField!,
                          SizedBox(height: afterPinGap),
                        ],
                        body,
                        if (errorBanner != null) ...[
                          SizedBox(height: 12.h),
                          errorBanner!,
                        ],
                        if (_isCompact)
                          SizedBox(height: 24.h)
                        else
                          const Spacer(),
                        if (bottom != null) bottom!,
                        if (_isCompact) SizedBox(height: 16.h),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrandedHeader extends StatelessWidget {
  const _BrandedHeader({this.onBack, required this.showBack});

  final VoidCallback? onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (showBack)
          Align(
            alignment: Alignment.centerLeft,
            child: AppBackButton(
              color: AppColors.textHeading,
              showOnlyWhenCanPop: false,
              onPressed: onBack,
            ),
          ),
        Center(
          child: SvgPictureAsset(
            AppAssets.selcomGoLogo,
            height: 40.h,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}
