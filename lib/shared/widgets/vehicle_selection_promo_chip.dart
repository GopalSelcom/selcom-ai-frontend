import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/constants/app_assets.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/svg_picture_asset.dart';
import '../../features/ride/presentation/controllers/vehicle_selection_controller.dart';

/// Promo entry on vehicle selection bottom sheet header (text button + icon).
class VehicleSelectionPromoChip extends StatelessWidget {
  const VehicleSelectionPromoChip({super.key, required this.controller});

  final VehicleSelectionController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final code = controller.appliedPromoCode.value.trim();
      final hasPromo = code.isNotEmpty;
      final fg = hasPromo ? AppColors.primary : AppColors.promotionBlue;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => unawaited(controller.openPromotions()),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: fg,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPictureAsset(
                  AppAssets.icPromoCode,
                  width: 20.w,
                  height: 20.w,
                  placeholderBuilder: (_) =>
                      Icon(Icons.percent, color: fg, size: 18.sp),
                ),
                SizedBox(width: 6.w),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 140.w),
                  child: Text(
                    hasPromo ? code : AppStrings.promotions.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.homeCaption.copyWith(
                      color: fg,
                      fontWeight: hasPromo ? FontWeight.w800 : FontWeight.w600,
                      fontSize: hasPromo ? 13.sp : 12.sp,
                      height: 16 / 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hasPromo)
            IconButton(
              style: IconButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              iconSize: 16.sp,
              onPressed: () => unawaited(controller.clearAppliedPromo()),
              icon: Icon(Icons.close, color: fg, size: 16.sp),
            ),
        ],
      );
    });
  }
}
