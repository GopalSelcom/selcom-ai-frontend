import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_back_button.dart';

class AppProfileHeader extends StatelessWidget {
  final String? title;
  final VoidCallback? onBack;
  final Widget? child;
  final double? bottomPadding;

  const AppProfileHeader({
    super.key,
    this.title,
    this.onBack,
    this.child,
    this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.of(context).canPop();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16.h,
        bottom: bottomPadding ?? 32.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32.r),
          bottomRight: Radius.circular(32.r),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canGoBack)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: AppBackButton(
                color: Colors.white,
                size: 28.w,
                onPressed: onBack,
              ),
            ),

          if (title != null) ...[
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Text(
                title!,
                style: AppTextStyles.screenTitle.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],

          if (child != null) ...[
            if (title == null) SizedBox(height: 24.h),
            child!,
          ],
        ],
      ),
    );
  }
}
