import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/domain/entities/ride_entity.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../../../ride_rating/presentation/widgets/ride_rating_input_section.dart';
import '../controllers/ride_details_controller.dart';
import '../widgets/ride_common_widgets.dart';

class RideDetailsScreen extends StatelessWidget {
  final RideEntity ride;

  const RideDetailsScreen({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<RideDetailsController>()
        ? Get.find<RideDetailsController>()
        : Get.put(RideDetailsController(ride: ride));

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Column(
        children: [
          AppProfileHeader(title: AppStrings.yourRides.tr),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.vehicleDisplayName,
                            style: TextStyle(
                              fontFamily: AppTextStyles.metropolisFont,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textHeading,
                              fontSize: 20.sp,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            RideDateFormatter.formatDate(controller.formattedDate),
                            style: TextStyle(
                              fontFamily: AppTextStyles.metropolisFont,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textBody,
                              fontSize: 15.sp,
                            ),
                          ),
                        ],
                      ),
                      Image.asset(
                        controller.vehicleImageAsset,
                        height: 60.h,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.two_wheeler,
                          size: 50.w,
                          color: AppColors.textBody,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      border: Border.all(
                        color: AppColors.borderWalletCard,
                        width: 0.78,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: RideLocationsTimeline(
                      startLocation: controller.pickupTitle,
                      startAddress: ride.pickup.address,
                      endLocation: controller.destinationTitle,
                      endAddress: ride.destination.address,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      border: Border.all(
                        color: AppColors.borderWalletCard,
                        width: 0.78,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.totalFare.tr,
                          style: TextStyle(
                            fontFamily: AppTextStyles.metropolisFont,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textHeading,
                            fontSize: 15.sp,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        FareBreakdownRow(
                          title: AppStrings.rideCharge.tr,
                          amount: controller.rideChargeLabel,
                        ),
                        SizedBox(height: 12.h),
                        FareBreakdownRow(
                          title: AppStrings.bookingFeesAndConvenienceCharges.tr,
                          amount: controller.bookingFeeLabel,
                        ),
                        SizedBox(height: 12.h),
                        FareBreakdownRow(
                          title: AppStrings.totalAmount.tr,
                          amount: controller.totalAmountLabel,
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  controller.hasExistingRating
                      ? Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            border: Border.all(
                              color: AppColors.borderWalletCard,
                              width: 0.78,
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.howWasYourRide.tr,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.metropolisFont,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textHeading,
                                  fontSize: 15.sp,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              RideRatingStars(rating: (ride.riderRating?.toDouble() ?? 0)),
                              SizedBox(height: 8.h),
                              Text(
                                '${ride.riderRating}/5 ${AppStrings.ratingGiven.tr}',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.metropolisFont,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textBody,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                        )
                      : controller.canShowReviewInput
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: 12.h),
                            RideRatingInputSection(
                              controller: controller.ratingController,
                              starSize: 40,
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                  SizedBox(height: 24.h),
                  const NeedHelpRow(),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: (controller.hasExistingRating || !controller.canShowReviewInput)
                  ? AppPrimaryButton(
                      label: AppStrings.done.tr,
                      onPressed: () => Navigator.pop(context),
                    )
                  : Obx(
                      () => AppPrimaryButton(
                        label: AppStrings.done.tr,
                        isLoading: controller.ratingController.isSubmitting.value,
                        onPressed: controller.ratingController.canSubmit
                            ? controller.ratingController.onSubmitTap
                            : null,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
