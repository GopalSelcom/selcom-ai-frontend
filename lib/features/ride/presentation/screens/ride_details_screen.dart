import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/domain/entities/ride_entity.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../../../ride_rating/presentation/widgets/ride_rating_input_section.dart';
import '../controllers/ride_details_controller.dart';
import '../widgets/ride_common_widgets.dart';

class RideDetailsScreen extends StatelessWidget {
  final RideEntity ride;
  final bool openedFromCompletionFlow;

  const RideDetailsScreen({
    super.key,
    required this.ride,
    this.openedFromCompletionFlow = false,
  });

  @override
  Widget build(BuildContext context) {
    // Recreate controller when either ride id or entry source changes.
    // This prevents stale state when navigating between "My Rides" and
    // post-completion flow, where behavior differs.
    final hasRegisteredController = Get.isRegistered<RideDetailsController>();
    if (hasRegisteredController) {
      final existingController = Get.find<RideDetailsController>();
      final hasDifferentFlowMode =
          existingController.openedFromCompletionFlow !=
          openedFromCompletionFlow;
      final hasDifferentRide = existingController.ride.id != ride.id;
      if (hasDifferentFlowMode || hasDifferentRide) {
        Get.delete<RideDetailsController>();
      }
    }
    final controller = Get.isRegistered<RideDetailsController>()
        ? Get.find<RideDetailsController>()
        : Get.put(
            RideDetailsController(
              ride: ride,
              openedFromCompletionFlow: openedFromCompletionFlow,
            ),
          );

    Future<void> handleCompletionExit() async {
      // Post-completion flow should always exit to Home (clear stack).
      Get.offAllNamed(AppRoutes.home);
    }

    Future<void> handleSkipToHome() async {
      // Skip still calls backend first; then we enforce Home navigation.
      await controller.ratingController.onSkipTap();
      await handleCompletionExit();
    }

    final reviewSection = controller.hasExistingRating
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
                  style: AppTextStyles.homeSubtitle.copyWith(
                    color: AppColors.black,
                    height: 20 / 15,
                  ),
                ),
                SizedBox(height: 6.h),
                RideRatingStars(rating: (ride.riderRating?.toDouble() ?? 0)),
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
        : const SizedBox.shrink();

    return PopScope(
      // In completion flow, back should not return to stale ride stack.
      canPop: !controller.openedFromCompletionFlow,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && controller.openedFromCompletionFlow) {
          await handleCompletionExit();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: Column(
          children: [
            AppProfileHeader(
              title: controller.openedFromCompletionFlow
                  ? AppStrings.yourRideIsCompleted.tr
                  : AppStrings.yourRides.tr,
              onBack: controller.openedFromCompletionFlow
                  ? handleCompletionExit
                  : null,
              bottomPadding:
                  controller.openedFromCompletionFlow &&
                      controller.canShowReviewInput &&
                      !controller.hasExistingRating
                  ? 10.h
                  : null,
              child:
                  controller.openedFromCompletionFlow &&
                      controller.canShowReviewInput &&
                      !controller.hasExistingRating
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: handleSkipToHome,
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 0,
                          ),
                        ),
                        child: Text(
                          AppStrings.skip.tr,
                          style: AppTextStyles.homeSubtitle.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
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
                              style: AppTextStyles.homeTitle.copyWith(
                                fontWeight: FontWeight.w600,
                                height: 34 / 20,
                                letterSpacing: -0.4,
                              ),
                            ),
                            Text(
                              RideDateFormatter.formatDate(
                                controller.formattedDate,
                              ),
                              style: AppTextStyles.homeSubtitle.copyWith(
                                height: 20 / 15,
                              ),
                            ),
                          ],
                        ),
                        Image.asset(
                          controller.vehicleImageAsset,
                          height: 50.h,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.two_wheeler,
                            size: 50.w,
                            color: AppColors.textBody,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    if (controller.shouldPrioritizeReviewSection) ...[
                      // Completion entry: keep rating above route/fare cards.
                      reviewSection,
                      SizedBox(height: 16.h),
                    ],
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
                        stops: ride.stops,
                      ),
                    ),
                    SizedBox(height: 8.h),
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
                            style: AppTextStyles.homeSubtitle.copyWith(
                              color: AppColors.black,
                              height: 20 / 15,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          FareBreakdownRow(
                            title: AppStrings.rideCharge.tr,
                            amount: controller.rideChargeLabel,
                          ),
                          SizedBox(height: 6.h),
                          FareBreakdownRow(
                            title:
                                AppStrings.bookingFeesAndConvenienceCharges.tr,
                            amount: controller.bookingFeeLabel,
                          ),
                          SizedBox(height: 6.h),
                          FareBreakdownRow(
                            title: AppStrings.totalAmount.tr,
                            amount: controller.totalAmountLabel,
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    if (!controller.shouldPrioritizeReviewSection)
                      reviewSection,
                    SizedBox(height: 16.h),
                    NeedHelpRow(
                      showDownloadSlip: controller.isCompleted,
                      onDownloadTap: controller.downloadSlip,
                    ),
                    SizedBox(height: 8.h),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                child:
                    (controller.hasExistingRating ||
                        !controller.canShowReviewInput)
                    ? AppPrimaryButton(
                        label: AppStrings.done.tr,
                        onPressed: controller.openedFromCompletionFlow
                            ? handleCompletionExit
                            : () => Navigator.pop(context),
                      )
                    : Obx(
                        () => AppPrimaryButton(
                          label: AppStrings.done.tr,
                          isLoading:
                              controller.ratingController.isSubmitting.value,
                          onPressed: controller.ratingController.canSubmit
                              ? () => controller.ratingController.onSubmitTap(
                                  // Route success-dialog "Continue" by source:
                                  // completion flow -> Home, My Rides -> pop.
                                  onSuccessConfirmed:
                                      controller.openedFromCompletionFlow
                                      ? handleCompletionExit
                                      : () => Navigator.pop(context),
                                )
                              : null,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
