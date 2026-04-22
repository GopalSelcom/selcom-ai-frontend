import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Compact location row for map headers (pickup / drop labels + address).
class AppMapLocationSummaryCard extends StatelessWidget {
  const AppMapLocationSummaryCard({
    super.key,
    required this.label,
    required this.address,
    this.leading,
    this.labelStyle,
    this.addressStyle,
    this.maxAddressLines = 2,
  });

  final String label;
  final String address;
  final Widget? leading;
  final TextStyle? labelStyle;
  final TextStyle? addressStyle;
  final int maxAddressLines;

  static const Color _borderColor = Color(0xFFD3DDE7);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 61.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          leading ??
              Icon(Icons.location_on, color: AppColors.primary, size: 26.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style:
                      labelStyle ??
                      AppTextStyles.homeSubtitle.copyWith(
                        color: const Color(0xFF2A3143),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  address,
                  style:
                      addressStyle ??
                      AppTextStyles.homeCaption.copyWith(
                        color: const Color(0xFF586377),
                        fontSize: 13.sp,
                      ),
                  maxLines: maxAddressLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
