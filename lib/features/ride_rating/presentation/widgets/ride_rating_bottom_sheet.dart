import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_cupertino_text_button.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_standard_bottom_sheet.dart';
import '../../../../shared/widgets/vehicle_type_image.dart';
import '../../domain/entities/ride_rating_ride_entity.dart';
import '../controllers/ride_rating_controller.dart';
import 'ride_rating_input_section.dart';

class RideRatingBottomSheet extends GetView<RideRatingController> {
  const RideRatingBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ride = controller.pendingReviewRide.value;
      if (ride == null) {
        return const SizedBox.shrink();
      }

      return AppStandardBottomSheet(
        showHeaderDivider: false,
        maxHeightFactor: 0.75,
        contentPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: AppCupertinoTextButton.skip(
                label: AppStrings.skip.tr,
                onPressed: controller.onSkipTap,
              ),
            ),
            CircleAvatar(
              radius: 40.r,
              backgroundColor: AppColors.bgAvatarLightPink,
              backgroundImage: ride.driverImage.trim().isEmpty
                  ? null
                  : NetworkImage(ride.driverImage),
              child: ride.driverImage.trim().isEmpty
                  ? Text(
                      ride.driverName.isEmpty
                          ? '?'
                          : ride.driverName.characters.first.toUpperCase(),
                      style: AppTextStyles.homeTitle.copyWith(
                        color: AppColors.textHeading,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            SizedBox(height: 14.h),
            Text(
              AppStrings.howDoYouRateTheDriver.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.homeTitle.copyWith(
                fontSize: 36.sp / 2,
                fontWeight: FontWeight.w700,
                color: AppColors.textHeading,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              AppStrings.helpSelcomGoDoBetterByRatingThisTrip.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.homeCaption.copyWith(
                color: AppColors.textBody,
                fontSize: 15.sp,
              ),
            ),
            SizedBox(height: 14.h),
            RideRatingInputSection(controller: controller),
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.rideTitle,
                        style: AppTextStyles.homeTitle.copyWith(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHeading,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        controller.rideDateLabel,
                        style: AppTextStyles.homeCaption.copyWith(
                          color: AppColors.textBody,
                          fontSize: 15.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                VehicleTypeImage(
                  assetPath: controller.vehicleImageAssetForType(
                    ride.vehicleType,
                  ),
                  height: 52.h,
                  fit: BoxFit.contain,
                  fallbackIcon: Icons.person,
                  fallbackIconColor: AppColors.textBody,
                ),
              ],
            ),
            SizedBox(height: 18.h),
            if (ride.pickupAddress.trim().isNotEmpty ||
                ride.destinationAddress.trim().isNotEmpty)
              _routeSummaryCard(ride),
            SizedBox(height: 14.h),
          ],
        ),
        footer: Obx(
          () => AppPrimaryButton(
            label: AppStrings.done.tr,
            isLoading: controller.isSubmitting.value,
            onPressed: controller.canSubmit ? controller.onSubmitTap : null,
          ),
        ),
      );
    });
  }

  Widget _routeSummaryCard(RideRatingRideEntity ride) {
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
            _routeLine(label: AppStrings.pickup.tr, value: ride.pickupAddress),
          if (ride.pickupAddress.trim().isNotEmpty &&
              ride.destinationAddress.trim().isNotEmpty)
            SizedBox(height: 10.h),
          if (ride.destinationAddress.trim().isNotEmpty)
            _routeLine(
              label: AppStrings.destination.tr,
              value: ride.destinationAddress,
            ),
          if (controller.rideFareLabel.isNotEmpty) ...[
            SizedBox(height: 10.h),
            _routeLine(
              label: AppStrings.fare.tr,
              value: controller.rideFareLabel,
            ),
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
