import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/data/models/responses/rides/ride_details_response.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/phone_national_rules.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../../../../shared/widgets/vehicle_type_image.dart';
import '../../../ride_rating/presentation/widgets/ride_rating_input_section.dart';
import '../controllers/ride_details_controller.dart';
import '../widgets/ride_common_widgets.dart';
import '../widgets/ride_details_screen_layout.dart';
import '../widgets/ride_details_screen_shimmer.dart';

class RideDetailsScreen extends StatelessWidget {
  final RideDetailsRide ride;
  final bool openedFromCompletionFlow;
  /// Passed to [RideDetailsController]; false when caller pre-fetched ride details.
  final bool refreshOnInit;

  const RideDetailsScreen({
    super.key,
    required this.ride,
    this.openedFromCompletionFlow = false,
    this.refreshOnInit = true,
  });

  @override
  Widget build(BuildContext context) {
    final controller = RideDetailsController.ensureBound(
      ride: ride,
      openedFromCompletionFlow: openedFromCompletionFlow,
      refreshOnInit: refreshOnInit,
    );

    final reviewSection = controller.hasExistingRating
        ? Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColors.pageBackground,
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
                RideRatingStars(
                  rating: (controller.ride.riderRating?.toDouble() ?? 0),
                ),
              ],
            ),
          )
        : controller.canShowReviewInput
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
          controller.exitToHome();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Column(
          children: [
            AppProfileHeader(
              title: controller.openedFromCompletionFlow
                  ? AppStrings.thanksForUsingGo.tr
                  : AppStrings.yourRides.tr,
              onBack: controller.openedFromCompletionFlow
                  ? controller.exitToHome
                  : null,
            ),
            Expanded(
              child: Obx(() {
                final scrollPadding = EdgeInsets.symmetric(
                  horizontal: RideDetailsScreenLayout.scrollHorizontalPadding,
                  vertical: RideDetailsScreenLayout.scrollVerticalPadding,
                );
                if (controller.isLoadingRideDetails.value) {
                  final showReviewAtTop =
                      controller.shouldPrioritizeReviewSection;
                  final showReviewAtBottom =
                      !showReviewAtTop &&
                      (controller.hasExistingRating ||
                          controller.canShowReviewInput);
                  final ride = controller.ride;
                  return SingleChildScrollView(
                    padding: scrollPadding,
                    child: RideDetailsScreenShimmer.content(
                      showReviewAtTop: showReviewAtTop,
                      showReviewAtBottom: showReviewAtBottom,
                      showBookedForOther: ride.isBookedForOther ?? false,
                      showPassengerPhone: ride.passengerPhone != null,
                      fareLineRowCount: controller.fareLineRows.length,
                      showDownloadSlip: controller.isCompleted,
                      locationRowCount:
                          RideDetailsScreenShimmer.locationRowCountFor(ride),
                    ),
                  );
                }
                final ride = controller.ride;
                return SingleChildScrollView(
                  padding: scrollPadding,
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
                          VehicleTypeImage(
                            assetPath: controller.vehicleImageAsset,
                            width:
                                RideDetailsScreenLayout.headerVehicleImageWidth,
                            height: RideDetailsScreenLayout
                                .headerVehicleImageHeight,
                            fit: BoxFit.contain,
                            fallbackIcon: Icons.two_wheeler,
                            fallbackIconColor: AppColors.textBody,
                          ),
                        ],
                      ),
                      SizedBox(height: RideDetailsScreenLayout.sectionGap),
                      if (controller.shouldPrioritizeReviewSection) ...[
                        reviewSection,
                        SizedBox(height: RideDetailsScreenLayout.sectionGap),
                      ],
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppColors.pageBackground,
                          border: Border.all(
                            color: AppColors.borderWalletCard,
                            width: 0.78,
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: RideLocationsTimeline(
                          startLocation: controller.pickupTitle,
                          startAddress: ride.pickup?.address ?? '',
                          endLocation: controller.destinationTitle,
                          endAddress: ride.destination?.address ?? '',
                          stops: controller.timelineStops,
                        ),
                      ),
                      if (ride.isBookedForOther ?? false) ...[
                        SizedBox(height: RideDetailsScreenLayout.sectionGap),
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: AppColors.pageBackground,
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
                                            (ride.passengerName?.toString().trim() ??
                                                    '')
                                                .isEmpty
                                            ? AppStrings.someone.tr
                                            : ride.passengerName.toString(),
                                      }),
                                      style: TextStyle(
                                        fontFamily:
                                            AppTextStyles.metropolisFont,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textHeading,
                                        fontSize: 15.sp,
                                      ),
                                    ),
                                    if (ride.passengerPhone != null)
                                      Text(
                                        AppStrings.phoneWithNumber.trParams({
                                          'phone':
                                              PhoneNationalRules.formatE164DigitsForDisplay(
                                                ride.passengerPhone
                                                        ?.toString() ??
                                                    '',
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
                      SizedBox(height: RideDetailsScreenLayout.sectionGap),
                      Container(
                        padding: EdgeInsets.fromLTRB(14.w, 14.h, 11.w, 14.h),
                        decoration: BoxDecoration(
                          color: AppColors.pageBackground,
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
                              controller.fareCardTitle,
                              style: AppTextStyles.homeSubtitle.copyWith(
                                color: AppColors.black,
                                height: 20 / 15,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            if (controller.hasCancellationContext) ...[
                              Text(
                                AppStrings.cancellationReason.tr,
                                style: AppTextStyles.homeCaption.copyWith(
                                  fontWeight: FontWeight.w400,
                                  height: 20 / 12,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                controller.cancellationContextText,
                                style: AppTextStyles.homeCaption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 20 / 12,
                                  color: AppColors.textHeading,
                                ),
                              ),
                              if (controller.midRideCancelMessage != null) ...[
                                SizedBox(height: 8.h),
                                Text(
                                  controller.midRideCancelMessage!,
                                  style: AppTextStyles.homeCaption.copyWith(
                                    fontWeight: FontWeight.w500,
                                    height: 20 / 12,
                                    color: AppColors.textSlate,
                                  ),
                                ),
                              ],
                              SizedBox(height: 8.h),
                            ],
                            if (controller.hasFareLineItems)
                              FareBreakdownRowsList(
                                rows: controller.fareLineRows,
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: RideDetailsScreenLayout.sectionGap),
                      if (!controller.shouldPrioritizeReviewSection)
                        reviewSection,
                      SizedBox(height: RideDetailsScreenLayout.needHelpTopGap),
                      NeedHelpRow(
                        showDownloadSlip: controller.isCompleted,
                        onDownloadTap: controller.downloadSlip,
                      ),
                      SizedBox(height: RideDetailsScreenLayout.scrollBottomGap),
                    ],
                  ),
                );
              }),
            ),
            SafeArea(
              top: false,
              child: Obx(() {
                if (controller.isLoadingRideDetails.value) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      RideDetailsScreenLayout.primaryButtonHorizontalPadding,
                      0,
                      RideDetailsScreenLayout.primaryButtonHorizontalPadding,
                      RideDetailsScreenLayout.primaryButtonBottomPadding,
                    ),
                    child: RideDetailsScreenShimmer.primaryButton(),
                  );
                }
                final rc = controller.ratingController;
                final bool isSimpleDoneFlow =
                    controller.hasExistingRating ||
                    !controller.canShowReviewInput;
                final bool isSubmitting = rc.isSubmitting.value;

                final String buttonLabel = isSimpleDoneFlow
                    ? AppStrings.done.tr
                    : (rc.hasSelectedRating
                          ? AppStrings.done.tr
                          : AppStrings.skip.tr);

                final onPressed = isSimpleDoneFlow
                    ? controller.onPrimaryDonePressed
                    : (rc.hasSelectedRating
                          ? controller.onSubmitRatingPressed
                          : controller.onSkipRating);

                return Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  child: AppPrimaryButton(
                    label: buttonLabel,
                    isLoading: !isSimpleDoneFlow && isSubmitting,
                    onPressed: onPressed,
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
