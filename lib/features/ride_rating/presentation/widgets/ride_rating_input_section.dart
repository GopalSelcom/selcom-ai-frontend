import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/ride_rating_controller.dart';

class RideRatingInputSection extends StatelessWidget {
  const RideRatingInputSection({
    super.key,
    required this.controller,
    this.starSize = 42,
  });

  final RideRatingController controller;
  final double starSize;

  @override
  Widget build(BuildContext context) {
    TextStyle titleStyle = AppTextStyles.homeSubtitle.copyWith(
      color: AppColors.black,
      height: 20 / 15,
    );
    return Obx(
      () => Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.borderWalletCard, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.howWasYourRide.tr, style: titleStyle),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                final star = index + 1;
                final starColor = star <= controller.selectedRating.value
                    ? AppColors.ratingStarActive
                    : AppColors.ratingStarInactive;
                return GestureDetector(
                  onTap: () => controller.onRatingSelected(star),
                  child: SvgPictureAsset(
                    AppAssets.icRatingStar,
                    width: starSize.w,
                    height: starSize.w,
                    color: starColor,
                    placeholderBuilder: (_) =>
                        Icon(Icons.star, size: starSize.w, color: starColor),
                  ),
                );
              }),
            ),
            if (controller.hasSelectedRating) ...[
              SizedBox(height: 18.h),
              Text(AppStrings.whatStoodOut.tr, style: titleStyle),
              SizedBox(height: 6.h),
              Text(
                AppStrings.pickAnyTagsThatMatchThisTrip.tr,
                style: AppTextStyles.homeCaption.copyWith(
                  color: AppColors.textBody,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 10.h),
              if (controller.isLoadingTags.value)
                const Center(child: CircularProgressIndicator())
              else if (controller.availableTags.isNotEmpty)
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: controller.availableTags.map((tag) {
                    final isSelected = controller.isTagSelected(tag.key);
                    return GestureDetector(
                      onTap: () => controller.onTagToggled(tag.key),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryLight
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(999.r),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.borderDefault,
                          ),
                        ),
                        child: Text(
                          tag.label,
                          style: AppTextStyles.homeCaption.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textBody,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              if (controller.selectedRating.value <= 2) ...[
                SizedBox(height: 18.h),
                Text(
                  AppStrings.pleaseTellUsWhatWentWrongOrHowWeCanImprove.tr,
                  style: titleStyle,
                ),
                SizedBox(height: 10.h),
                AppTextField(
                  controller: controller.commentController,
                  onChanged: controller.onCommentChanged,
                  hintText: AppStrings.tellUsMoreAboutYourExperience.tr,
                  maxLines: 2,
                  maxLength: 120,
                  showCounter: true,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
