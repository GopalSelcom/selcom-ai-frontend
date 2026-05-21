import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// App-wide modal bottom sheet shell: drag handle, title, subtitle, and body.
///
/// Open via [AppDialogs.showStandardBottomSheet] so presentation matches other
/// overlays (blur barrier, slide animation, safe area).
class AppStandardBottomSheet extends StatelessWidget {
  const AppStandardBottomSheet({
    super.key,
    this.title,
    this.subtitle,
    required this.content,
    this.footer,
    this.showDragHandle = true,
    this.showHeaderDivider = true,
    this.contentPadding,
    this.maxHeightFactor = 0.75,
  });

  final String? title;
  final String? subtitle;
  final Widget content;
  final Widget? footer;

  /// Top pill handle (Figma-style sheets).
  final bool showDragHandle;

  /// Divider between header block and [content].
  final bool showHeaderDivider;

  final EdgeInsetsGeometry? contentPadding;

  /// Max height of the scrollable body as a fraction of screen height.
  final double maxHeightFactor;

  bool get _hasHeader =>
      (title != null && title!.trim().isNotEmpty) ||
      (subtitle != null && subtitle!.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final maxBodyHeight = MediaQuery.sizeOf(context).height * maxHeightFactor;
    final bodyPadding =
        contentPadding ?? EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showDragHandle) ...[
            SizedBox(height: 10.h),
            Center(
              child: Container(
                width: 48.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: AppColors.skeletonBase,
                  borderRadius: BorderRadius.circular(37.r),
                ),
              ),
            ),
            SizedBox(height: 13.h),
          ],
          if (_hasHeader) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (title != null && title!.trim().isNotEmpty)
                    Text(
                      title!.trim(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.homeTitle,
                    ),
                  if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Text(
                      subtitle!.trim(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.homeSubtitle
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 14.h),
            if (showHeaderDivider)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Divider(
                  color: AppColors.bgSoftCircle,
                  thickness: 1.h,
                  height: 1.h,
                ),
              ),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxBodyHeight),
            child: SingleChildScrollView(padding: bodyPadding, child: content),
          ),
          if (footer != null) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
              child: footer!,
            ),
          ] else
            SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
