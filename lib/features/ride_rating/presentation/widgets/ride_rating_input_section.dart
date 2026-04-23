import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
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
    return Obx(
      () => Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FD),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFE6E9EE), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.howWasYourRide.tr,
              style: AppTextStyles.homeTitle.copyWith(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF132235),
              ),
            ),
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                final star = index + 1;
                return GestureDetector(
                  onTap: () => controller.onRatingSelected(star),
                  child: Icon(
                    Icons.star,
                    size: starSize.w,
                    color: star <= controller.selectedRating.value
                        ? const Color(0xFFFFCC00)
                        : const Color(0xFFD9DDE3),
                  ),
                );
              }),
            ),
            if (controller.hasSelectedRating) ...[
              SizedBox(height: 12.h),
              Text(
                AppStrings.whatStoodOut.tr,
                style: AppTextStyles.homeTitle.copyWith(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF132235),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                AppStrings.pickAnyTagsThatMatchThisTrip.tr,
                style: AppTextStyles.homeCaption.copyWith(
                  color: const Color(0xFF364B63),
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
                              : Colors.white,
                          borderRadius: BorderRadius.circular(999.r),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFFD9DDE3),
                          ),
                        ),
                        child: Text(
                          tag.label,
                          style: AppTextStyles.homeCaption.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFF364B63),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              if (controller.selectedRating.value <= 2) ...[
                SizedBox(height: 12.h),
                Text(
                  AppStrings.pleaseTellUsWhatWentWrongOrHowWeCanImprove.tr,
                  style: AppTextStyles.homeTitle.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF132235),
                  ),
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
