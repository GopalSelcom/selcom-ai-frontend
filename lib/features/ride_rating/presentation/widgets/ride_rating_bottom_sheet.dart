import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../controllers/ride_rating_controller.dart';
import 'ride_rating_input_section.dart';

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
              color: AppColors.white,
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
                                color: AppColors.dividerHandle,
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
                                AppStrings.skip.tr,
                                style: AppTextStyles.homeCaption.copyWith(
                                  color: AppColors.textBody,
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
                                      backgroundColor: AppColors.bgAvatarLightPink,
                                      backgroundImage:
                                          ride.driverImage.trim().isEmpty
                                          ? null
                                          : NetworkImage(ride.driverImage),
                                      child: ride.driverImage.trim().isEmpty
                                          ? Text(
                                              ride.driverName.isEmpty
                                                  ? '?'
                                                  : ride
                                                        .driverName
                                                        .characters
                                                        .first
                                                        .toUpperCase(),
                                              style: AppTextStyles.homeTitle
                                                  .copyWith(
                                                    color: AppColors.textHeading,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            )
                                          : null,
                                    ),
                                    SizedBox(height: 14.h),
                                    Text(
                                      AppStrings.howDoYouRateTheDriver.tr,
                                      style: AppTextStyles.homeTitle.copyWith(
                                        fontSize: 36.sp / 2,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textHeading,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      AppStrings
                                          .helpSelcomGoDoBetterByRatingThisTrip
                                          .tr,
                                      style: AppTextStyles.homeCaption.copyWith(
                                        color: AppColors.textBody,
                                        fontSize: 15.sp,
                                      ),
                                    ),
                                    SizedBox(height: 14.h),
                                    RideRatingInputSection(
                                      controller: controller,
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
                                                style: AppTextStyles.homeTitle
                                                    .copyWith(
                                                      fontSize: 20.sp,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: AppColors.textHeading,
                                                    ),
                                              ),
                                              SizedBox(height: 2.h),
                                              Text(
                                                controller.rideDateLabel,
                                                style: AppTextStyles.homeCaption
                                                    .copyWith(
                                                      color: AppColors.textBody,
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
                                        ride.destinationAddress
                                            .trim()
                                            .isNotEmpty)
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

  Widget _routeSummaryCard() {
    final ride = controller.pendingReviewRide.value;
    if (ride == null) return const SizedBox.shrink();
    return Container(
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
            color: AppColors.textTertiary,
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: AppTextStyles.homeCaption.copyWith(
            color: AppColors.textHeading,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
