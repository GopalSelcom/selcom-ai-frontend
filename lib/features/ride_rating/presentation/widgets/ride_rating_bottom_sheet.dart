import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/ride_rating_controller.dart';

class RideRatingBottomSheet extends GetView<RideRatingController> {
  const RideRatingBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = MediaQuery.of(context).size.height * 0.75;

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(36.r)),
            ),
            child: Obx(() {
              final ride = controller.pendingReviewRide.value;
              if (ride == null) {
                return const SizedBox.shrink();
              }
              return SafeArea(
                top: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Padding(
                      padding: EdgeInsets.only(
                        left: 16.w,
                        right: 16.w,
                        top: 10.h,
                        bottom: 16.h,
                      ),
                      child: Column(
                        children: [
                          Center(
                            child: Container(
                              width: 64.w,
                              height: 5.h,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1D5DB),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: controller.onSkipTap,
                              child: Text(
                                'Skip',
                                style: AppTextStyles.homeCaption.copyWith(
                                  color: const Color(0xFF364B63),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              child: AnimatedPadding(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOut,
                                padding: EdgeInsets.only(bottom: bottomInset),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 40.r,
                                      backgroundColor: const Color(0xFFFFD2DE),
                                      backgroundImage: ride.driverImage.trim().isEmpty
                                          ? null
                                          : NetworkImage(ride.driverImage),
                                      child: ride.driverImage.trim().isEmpty
                                          ? Text(
                                              ride.driverName.isEmpty
                                                  ? '?'
                                                  : ride.driverName.characters.first
                                                        .toUpperCase(),
                                              style: AppTextStyles.homeTitle.copyWith(
                                                color: AppColors.shade1,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            )
                                          : null,
                                    ),
                                    SizedBox(height: 14.h),
                                    Text(
                                      'How do you rate the driver?',
                                      style: AppTextStyles.homeTitle.copyWith(
                                        fontSize: 36.sp / 2,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF132235),
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      'Help Selcom Go do better by rating this trip',
                                      style: AppTextStyles.homeCaption.copyWith(
                                        color: const Color(0xFF364B63),
                                        fontSize: 15.sp,
                                      ),
                                    ),
                                    SizedBox(height: 14.h),
                                    _ratingCard(),
                                    Obx(
                                      () => AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 250),
                                        child: controller.hasSelectedRating
                                            ? Column(
                                                key: const ValueKey('details'),
                                                children: [
                                                  SizedBox(height: 12.h),
                                                  _tagCard(),
                                                  if (controller.selectedRating.value <= 2) ...[
                                                    SizedBox(height: 12.h),
                                                    _commentCard(),
                                                  ],
                                                ],
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ),
                                    SizedBox(height: 14.h),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                controller.rideTitle,
                                                style: AppTextStyles.homeTitle.copyWith(
                                                  fontSize: 20.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFF132235),
                                                ),
                                              ),
                                              SizedBox(height: 2.h),
                                              Text(
                                                controller.rideDateLabel,
                                                style: AppTextStyles.homeCaption
                                                    .copyWith(
                                                      color: const Color(0xFF364B63),
                                                      fontSize: 15.sp,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Image.asset(
                                          controller.vehicleImageAssetForType(
                                            ride.vehicleType,
                                          ),
                                          height: 52.h,
                                          fit: BoxFit.contain,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 18.h),
                                    if (ride.pickupAddress.trim().isNotEmpty ||
                                        ride.destinationAddress.trim().isNotEmpty)
                                      _routeSummaryCard(),
                                    SizedBox(height: 14.h),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Obx(
                            () => AppPrimaryButton(
                              label: 'Done',
                              isLoading: controller.isSubmitting.value,
                              onPressed: controller.canSubmit
                                  ? controller.onSubmitTap
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _ratingCard() {
    return Container(
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
            'How was your ride?',
            style: AppTextStyles.homeTitle.copyWith(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF132235),
            ),
          ),
          SizedBox(height: 10.h),
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                final star = index + 1;
                return GestureDetector(
                  onTap: () => controller.onRatingSelected(star),
                  child: Icon(
                    Icons.star,
                    size: 42.w,
                    color: star <= controller.selectedRating.value
                        ? const Color(0xFFFFCC00)
                        : const Color(0xFFD9DDE3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagCard() {
    return Container(
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
            'What stood out?',
            style: AppTextStyles.homeTitle.copyWith(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF132235),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Pick any tags that match this trip.',
            style: AppTextStyles.homeCaption.copyWith(
              color: const Color(0xFF364B63),
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 10.h),
          Obx(() {
            if (controller.isLoadingTags.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.availableTags.isEmpty) {
              return const SizedBox.shrink();
            }
            return Wrap(
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
                      color: isSelected ? AppColors.primaryLight : Colors.white,
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
            );
          }),
        ],
      ),
    );
  }

  Widget _commentCard() {
    return Container(
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
            'Please tell us what went wrong or how we can improve.',
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
            hintText: 'Type here',
            maxLines: 2,
            maxLength: 120,
            showCounter: true,
          ),
        ],
      ),
    );
  }

  Widget _routeSummaryCard() {
    final ride = controller.pendingReviewRide.value;
    if (ride == null) return const SizedBox.shrink();
    return Container(
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
          if (ride.pickupAddress.trim().isNotEmpty)
            _routeLine(label: 'Pickup', value: ride.pickupAddress),
          if (ride.pickupAddress.trim().isNotEmpty &&
              ride.destinationAddress.trim().isNotEmpty)
            SizedBox(height: 10.h),
          if (ride.destinationAddress.trim().isNotEmpty)
            _routeLine(label: 'Destination', value: ride.destinationAddress),
          if (controller.rideFareLabel.isNotEmpty) ...[
            SizedBox(height: 10.h),
            _routeLine(label: 'Fare', value: controller.rideFareLabel),
          ],
        ],
      ),
    );
  }

  Widget _routeLine({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.homeCaption.copyWith(
            color: const Color(0xFF6B7280),
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: AppTextStyles.homeCaption.copyWith(
            color: const Color(0xFF132235),
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
