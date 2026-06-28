import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_adaptive_bottom_inset_layout.dart';

/// App-wide modal bottom sheet shell: drag handle, title, subtitle, and body.
///
/// Use via [AppDialogs.showStandardBottomSheet]:
/// - pass this widget as `sheet:` when title/subtitle change inside the flow, or
/// - pass only the body as `content:` and set title/subtitle on [AppDialogs].
///
/// Spacing / keyboard recipes: `.cursor/rules/bottom-sheet-recipes.mdc`
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
    this.hasBottomWidget,
    this.liftBodyForKeyboard = true,
    this.bottomBodyWidget,
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

  /// When null, defaults to true so content-only sheets get 3-button / iOS
  /// clearance via [AppAdaptiveBottomInsetLayout]. Android gesture uses zero
  /// layout gap here; use [AppStandardBottomSheetBottomPad] with
  /// `gestureNavOnly: true` in content, or [AppStandardBottomSheetGesturePad].
  final bool? hasBottomWidget;

  final bool liftBodyForKeyboard;

  /// Optional widget pinned below the scrollable [content] (not scrolled away).
  /// Use [AppStandardBottomSheetBottomPad] with `hideWhenKeyboardOpen: true`
  /// when [hasBottomWidget] is false and the sheet handles keyboard sizing.
  final Widget? bottomBodyWidget;

  bool get _hasHeader =>
      (title != null && title!.trim().isNotEmpty) ||
      (subtitle != null && subtitle!.trim().isNotEmpty);

  bool get _applyBottomSpacing => hasBottomWidget ?? true;

  @override
  Widget build(BuildContext context) {
    final maxBodyHeight = MediaQuery.sizeOf(context).height * maxHeightFactor;
    final bodyPadding =
        contentPadding ?? EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0.h);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      child: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: AppAdaptiveBottomInsetLayout(
          mainAxisSize: MainAxisSize.min,
          hasBottomWidget: _applyBottomSpacing,
          liftBodyForKeyboard: liftBodyForKeyboard,
          pinnedHeader: _buildHeader(),
          body: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxBodyHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: bodyPadding,
                    child: content,
                  ),
                ),
                if (bottomBodyWidget != null) bottomBodyWidget!,
              ],
            ),
          ),
          footer: footer == null
              ? null
              : Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
                  child: footer,
                ),
        ),
      ),
    );
  }

  Widget? _buildHeader() {
    if (!showDragHandle && !_hasHeader) return null;

    return Column(
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
      ],
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
