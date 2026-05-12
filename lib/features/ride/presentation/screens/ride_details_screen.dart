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
import 'package:iconsax/iconsax.dart';
import '../../../../shared/utils/phone_formatter.dart';

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
            padding: EdgeInsets.all(14.w),
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
                starSize: 37.w,
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
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
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
                          width: 76.w,
                          height: 50.67.h,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.two_wheeler,
                            size: 50.w,
                            color: AppColors.textBody,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
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
                    if (ride.isBookedForOther) ...[
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
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: const BoxDecoration(
                                color: AppColors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Iconsax.user,
                                size: 20.sp,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.bookingForName.trParams({
                                      'name':
                                          (ride.passengerName ?? '')
                                              .trim()
                                              .isEmpty
                                          ? AppStrings.someone.tr
                                          : ride.passengerName!,
                                    }),
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.metropolisFont,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textHeading,
                                      fontSize: 15.sp,
                                    ),
                                  ),
                                  if (ride.passengerPhone != null)
                                    Text(
                                      AppStrings.phoneWithNumber.trParams({
                                        'phone':
                                            TanzaniaPhoneFormatter.formatInternational(
                                              ride.passengerPhone ?? '',
                                            ),
                                      }),
                                      style: TextStyle(
                                        fontFamily:
                                            AppTextStyles.metropolisFont,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textBody,
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.fromLTRB(14.w, 14.h, 11.w, 14.h),
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
                          SizedBox(height: 4.h),
                          FareBreakdownRow(
                            title:
                                AppStrings.bookingFeesAndConvenienceCharges.tr,
                            amount: controller.bookingFeeLabel,
                          ),
                          SizedBox(height: 4.h),
                          FareBreakdownRow(
                            title: AppStrings.totalAmount.tr,
                            amount: controller.totalAmountLabel,
                          ),
                        ],
                      ),
                    ),
                    if (!controller.shouldPrioritizeReviewSection)
                      reviewSection,
                    SizedBox(height: 13.h),
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
              child: Obx(() {
                final rc = controller.ratingController;
                final bool isSimpleDoneFlow =
                    controller.hasExistingRating ||
                        !controller.canShowReviewInput;
                final bool needsReviewForm =
                    controller.canShowReviewInput &&
                        !controller.hasExistingRating;
                final bool isSubmitting = rc.isSubmitting.value;
                final bool canSubmit = rc.canSubmit;
                final bool formComplete = rc.isRatingFormComplete;
                final bool shouldShowButton = isSimpleDoneFlow ||
                    (needsReviewForm &&
                        formComplete &&
                        (isSubmitting || canSubmit));

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    16.w,
                    0,
                    16.w,
                    shouldShowButton ? 16.h : 0,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        sizeFactor: animation,
                        axis: Axis.vertical,
                        child: child,
                      ),
                    ),
                    child: shouldShowButton
                        ? AppPrimaryButton(
                            key: const ValueKey('ride-details-done-visible'),
                            label: AppStrings.done.tr,
                            isLoading:
                                !isSimpleDoneFlow && isSubmitting,
                            onPressed: isSimpleDoneFlow
                                ? (controller.openedFromCompletionFlow
                                      ? handleCompletionExit
                                      : () => Navigator.pop(context))
                                : () => rc.onSubmitTap(
                                      onSuccessConfirmed:
                                          controller.openedFromCompletionFlow
                                          ? handleCompletionExit
                                          : () => Navigator.pop(context),
                                    ),
                          )
                        : const SizedBox.shrink(
                            key: ValueKey('ride-details-done-hidden'),
                          ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
