import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../utils/app_nav_spacing.dart';

/// App-wide modal bottom sheet shell: drag handle, title, subtitle, and body.
///
/// Use via [AppDialogs.showStandardBottomSheet]:
/// - pass this widget as `sheet:` when title/subtitle change inside the flow, or
/// - pass only the body as `content:` and set title/subtitle on [AppDialogs].
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
    this.headerTextAlign = TextAlign.start,
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

  /// Title and subtitle alignment ([TextAlign.start] or [TextAlign.center]).
  final TextAlign headerTextAlign;

  bool get _hasHeader =>
      (title != null && title!.trim().isNotEmpty) ||
      (subtitle != null && subtitle!.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final availableAboveKeyboard = mq.size.height - mq.viewInsets.bottom;
    final maxBodyHeight = mq.size.height * maxHeightFactor;
    final bodyPadding =
        contentPadding ?? EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h);
    final nav = AppNavSpacing.instance;
    final computedBottomPadding = nav.overlayTrailingGap(context);
    final useSafeAreaBottom = nav.overlayShouldUseSafeAreaBottom(context);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: availableAboveKeyboard),
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
                  crossAxisAlignment: _columnAlignFor(headerTextAlign),
                  children: [
                    if (title != null && title!.trim().isNotEmpty)
                      Text(
                        title!.trim(),
                        textAlign: headerTextAlign,
                        style: AppTextStyles.homeTitle,
                      ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        subtitle!.trim(),
                        textAlign: headerTextAlign,
                        style: AppTextStyles.homeSubtitle,
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
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxBodyHeight),
                child: SingleChildScrollView(
                  padding: bodyPadding,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: content,
                ),
              ),
            ),
            if (footer != null)
              SafeArea(
                top: false,
                bottom: useSafeAreaBottom,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20.w,
                    8.h,
                    20.w,
                    computedBottomPadding,
                  ),
                  child: footer!,
                ),
              )
            else
              SafeArea(
                top: false,
                bottom: useSafeAreaBottom,
                child: SizedBox(height: computedBottomPadding),
              ),
          ],
        ),
      ),
    );
  }

  static CrossAxisAlignment _columnAlignFor(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return CrossAxisAlignment.stretch;
      case TextAlign.end:
      case TextAlign.right:
        return CrossAxisAlignment.end;
      default:
        return CrossAxisAlignment.start;
    }
  }
}
