import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Shared shell for ride cancel flow modals: title, optional subtitle, body.
///
/// Show via [AppDialogs.showCancelFlowDialog] or embed in [AppDialogs.showAnimatedDialog].
class AppCancelFlowDialog extends StatelessWidget {
  const AppCancelFlowDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.content,
    this.canPop = true,
    this.padding,
    this.showDivider = true,
  });

  final String title;
  final String? subtitle;
  final Widget content;
  final bool canPop;
  final EdgeInsetsGeometry? padding;
  final bool showDivider;

  bool get _hasSubtitle => subtitle != null && subtitle!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final dialog = Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
      backgroundColor: AppColors.cardBackground,
      insetPadding: EdgeInsets.symmetric(horizontal: 13.w),
      child: Padding(
        padding:
            padding ?? EdgeInsets.symmetric(vertical: 28.h, horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.homeTitle,
            ),
            if (_hasSubtitle) ...[
              SizedBox(height: 4.h),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTextStyles.homeSubtitle,
              ),
            ],
            if (showDivider) ...[
              SizedBox(height: 6.5.h),
              Divider(height: 1.h, color: AppColors.bgSoftCircle),
              SizedBox(height: 15.5.h),
            ],
            content,
          ],
        ),
      ),
    );

    if (canPop) return dialog;
    return PopScope(canPop: false, child: dialog);
  }
}
