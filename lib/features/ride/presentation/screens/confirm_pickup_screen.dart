import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' hide Marker;
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/map_widgets.dart';
import '../controllers/confirm_pickup_controller.dart';

class ConfirmPickupScreen extends StatelessWidget {
  const ConfirmPickupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ConfirmPickupController>();
    final canGoBack = Navigator.of(context).canPop();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Obx(
              () => AppGoogleMap(
                key: const ValueKey('confirm_pickup_map'),
                initialCameraPosition: CameraPosition(
                  target: c.selectedLatLng.value,
                  zoom: 16,
                ),
                circles: _buildRouteCircles(
                  from: c.initialLatLng,
                  to: c.selectedLatLng.value,
                ),
                onMapCreated: c.onMapCreated,
                onCameraMove: c.onCameraMove,
                onCameraIdle: c.onCameraIdle,
                padding: EdgeInsets.only(bottom: 330.h),
              ),
            ),
          ),
          Positioned.fill(
            bottom: 330.h,
            child: IgnorePointer(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 10.w,
                      height: 10.h,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Positioned(
                      bottom: 4.h,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              AppStrings.pickupPoint.tr,
                              style: AppTextStyles.homeCaption.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            width: 2.w,
                            height: 12.h,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (canGoBack)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 10.h,
              left: 16.w,
              child: CircleAvatar(
                backgroundColor: AppColors.cardBackground,
                child: AppBackButton(
                  color: AppColors.textHeading,
                  alignment: Alignment.center,
                  size: 22.w,
                  hitSize: 40.w,
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 48.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: AppColors.skeletonBase,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        AppStrings.checkYourPickupPoint.tr,
                        style: AppTextStyles.homeTitle.copyWith(
                          fontSize: 28.sp / 2,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        AppStrings.selectANearbyPointForEasierPickup.tr,
                        style: AppTextStyles.homeCaption.copyWith(
                          color: AppColors.textBody,
                        ),
                      ),
                      SizedBox(height: 14.h),
                      Obx(() {
                        final fullAddress = c.address.value.trim().isEmpty
                            ? 'Selected pickup point'
                            : c.address.value.trim();
                        final title = fullAddress.split(',').first.trim();
                        return Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(color: AppColors.borderWalletCard),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.isEmpty ? 'Pickup point' : title,
                                style: AppTextStyles.homeSubtitle.copyWith(
                                  color: AppColors.textHeading,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                fullAddress,
                                style: AppTextStyles.homeCaption.copyWith(
                                  color: AppColors.textBody,
                                ),
                              ),
                              if (c.isResolvingAddress.value) ...[
                                SizedBox(height: 8.h),
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 12.w,
                                      height: 12.w,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      AppStrings.updatingAddress.tr,
                                      style: AppTextStyles.homeCaption.copyWith(
                                        color: AppColors.textBody,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                      SizedBox(height: 16.h),
                      Obx(
                        () => SizedBox(
                          width: double.infinity,
                          height: 54.h,
                          child: ElevatedButton(
                            onPressed: c.isSubmitting.value
                                ? null
                                : c.confirmPickup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              elevation: 0,
                            ),
                            child: c.isSubmitting.value
                                ? SizedBox(
                                    width: 20.w,
                                    height: 20.w,
                                    child: const CircularProgressIndicator(
                                      color: AppColors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    AppStrings.confirmPickup.tr,
                                    style: AppTextStyles.button.copyWith(
                                      color: AppColors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Set<Circle> _buildRouteCircles({required LatLng from, required LatLng to}) {
    final circles = <Circle>{
      Circle(
        circleId: const CircleId('initial_pickup_point'),
        center: from,
        radius: 7,
        fillColor: AppColors.primary.withValues(alpha: 0.22),
        strokeColor: AppColors.primary,
        strokeWidth: 2,
      ),
    };

    final latDiff = (to.latitude - from.latitude).abs();
    final lngDiff = (to.longitude - from.longitude).abs();
    final hasMoved = latDiff > 0.000001 || lngDiff > 0.000001;
    if (!hasMoved) return circles;

    final approxDistanceMeters = (latDiff + lngDiff) * 111000;
    final dotCount = (approxDistanceMeters / 16).clamp(10, 60).round();
    for (var i = 1; i < dotCount; i++) {
      final t = i / dotCount;
      circles.add(
        Circle(
          circleId: CircleId('pickup_route_dot_$i'),
          center: LatLng(
            from.latitude + (to.latitude - from.latitude) * t,
            from.longitude + (to.longitude - from.longitude) * t,
          ),
          radius: 3.2,
          fillColor: AppColors.primary.withValues(alpha: 0.65),
          strokeColor: AppColors.primary.withValues(alpha: 0.65),
          strokeWidth: 1,
        ),
      );
    }
    return circles;
  }
}
