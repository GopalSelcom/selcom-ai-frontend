import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/svg_picture_asset.dart';
import '../../core/constants/app_assets.dart';
import '../../features/ride/presentation/controllers/vehicle_selection_controller.dart';

/// Top-right promo entry + applied state (vehicle selection map overlay).
class VehicleSelectionPromoChip extends StatelessWidget {
  const VehicleSelectionPromoChip({super.key, required this.controller});

  final VehicleSelectionController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final code = controller.appliedPromoCode.value.trim();
      final hasPromo = code.isNotEmpty;
      final bg = hasPromo ? AppColors.primary : AppColors.promotionBlue;
      const fg = AppColors.white;

      return Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 220.w),
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [
                BoxShadow(
                  color: bg.withValues(alpha: 0.28),
                  blurRadius: 14.r,
                  offset: Offset(0, 6.h),
                ),
              ],
            ),
            child: InkWell(
              onTap: () => unawaited(controller.openPromotions()),
              borderRadius: BorderRadius.circular(18.r),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  10.w,
                  8.h,
                  hasPromo ? 2.w : 10.w,
                  8.h,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 22.w,
                      height: 22.w,
                      child: SvgPictureAsset(
                        AppAssets.icPromotions,
                        width: 20.w,
                        height: 20.w,
                        placeholderBuilder: (_) =>
                            Icon(Icons.percent, color: fg, size: 16.sp),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: hasPromo
                          ? Text(
                              code,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.homeCaption.copyWith(
                                color: fg,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.sp,
                              ),
                            )
                          : Text(
                              AppStrings.promotions.tr,
                              style: AppTextStyles.homeCaption.copyWith(
                                color: fg,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.sp,
                                height: 16 / 12,
                              ),
                            ),
                    ),
                    if (hasPromo)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: IconButton(
                          style: IconButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          iconSize: 16.sp,
                          onPressed: () {
                            unawaited(controller.clearAppliedPromo());
                          },
                          icon: const Icon(Icons.close, color: fg),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
