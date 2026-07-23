import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_cupertino_text_button.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/vehicle_type_image.dart';
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
                            child: AppCupertinoTextButton.skip(
                              label: AppStrings.skip.tr,
                              onPressed: controller.onSkipTap,
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
                                      backgroundColor:
                                          AppColors.bgAvatarLightPink,
                                      backgroundImage:
                                          controller.driverImage.isEmpty
                                          ? null
                                          : NetworkImage(controller.driverImage),
                                      child: controller.driverImage.isEmpty
                                          ? Text(
                                              controller.driverName.isEmpty
                                                  ? '?'
                                                  : controller
                                                        .driverName
                                                        .characters
                                                        .first
                                                        .toUpperCase(),
                                              style: AppTextStyles.homeTitle
                                                  .copyWith(
                                                    color:
                                                        AppColors.textHeading,
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
                                                      color:
                                                          AppColors.textHeading,
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
                                        VehicleTypeImage(
                                          assetPath: controller
                                              .vehicleImageAssetForType(
                                                controller.vehicleTypeForImage,
                                              ),
                                          height: 52.h,
                                          fit: BoxFit.contain,
                                          fallbackIcon: Icons.person,
                                          fallbackIconColor: AppColors.textBody,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 18.h),
                                    if (controller.hasRouteAddresses)
                                      _routeSummaryCard(),
                                    SizedBox(height: 14.h),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Obx(
                            () => AppPrimaryButton(
                              label: AppStrings.done.tr,
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
          if (controller.pickupAddress.isNotEmpty)
            _routeLine(
              label: AppStrings.pickup.tr,
              value: controller.pickupAddress,
            ),
          if (controller.pickupAddress.isNotEmpty &&
              controller.destinationAddress.isNotEmpty)
            SizedBox(height: 10.h),
          if (controller.destinationAddress.isNotEmpty)
            _routeLine(
              label: AppStrings.destination.tr,
              value: controller.destinationAddress,
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
