import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/app_nav_spacing.dart';
import '../../../../shared/widgets/app_primary_button.dart';

/// Book-ride footer: primary CTA + wallet-only payment notice (no method picker).
class BookRideWalletFooter extends StatelessWidget {
  const BookRideWalletFooter({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final loading = isLoading;
    final nav = AppNavSpacing.instance;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16.w,
        4.h,
        16.w,
        nav.footerTrailingGap(context, fallback: 12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppPrimaryButton(
            label: AppStrings.bookRide.tr,
            onPressed: loading ? null : onPressed,
            width: double.infinity,
            height: 56.h,
          ),
          SizedBox(height: 10.h),
          Text(
            AppStrings.bookRideWalletDeductionNotice.tr,
            textAlign: TextAlign.center,
            style: AppTextStyles.homeCaption.copyWith(height: 20 / 12),
          ),
        ],
      ),
    );
  }
}
