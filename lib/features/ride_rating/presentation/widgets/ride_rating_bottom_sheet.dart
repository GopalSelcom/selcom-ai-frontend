import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

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
        final maxHeight =
            MediaQuery.of(context).size.height - bottomInset - 10.h;

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(36.r)),
            ),
            child: Obx(() {
              final ride = controller.lastCompletedRide.value;
              if (ride == null) {
                return const SizedBox.shrink();
              }
              return SafeArea(
                top: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 16.w,
                          right: 16.w,
                          top: 10.h,
                          bottom: bottomInset + 16.h,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
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
                            SizedBox(height: 14.h),
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
                            CircleAvatar(
                              radius: 40.r,
                              backgroundColor: const Color(0xFFFFD2DE),
                              backgroundImage: NetworkImage(ride.driverImage),
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
                                child: controller.shouldShowComment
                                    ? Column(
                                        key: const ValueKey('comment'),
                                        children: [
                                          SizedBox(height: 12.h),
                                          _commentCard(),
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
                                        ride.vehicleType,
                                        style: AppTextStyles.homeTitle.copyWith(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF132235),
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        ride.dateTime,
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
                            AppPrimaryButton(
                              label: 'Done',
                              isLoading: controller.isSubmitting.value,
                              onPressed: controller.onSubmitTap,
                            ),
                          ],
                        ),
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
            hintText: 'Type here',
            maxLines: 2,
            maxLength: 120,
            showCounter: true,
          ),
        ],
      ),
    );
  }
}
