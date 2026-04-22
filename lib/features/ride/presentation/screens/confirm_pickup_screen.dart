import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' hide Marker;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/map_widgets.dart';
import '../controllers/confirm_pickup_controller.dart';

class ConfirmPickupScreen extends StatelessWidget {
  const ConfirmPickupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ConfirmPickupController>();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Obx(
              () => AppGoogleMap(
                mapWidgetKey: const ValueKey('confirm_pickup_map'),
                initialCameraPosition: CameraPosition(
                  target: c.selectedLatLng.value,
                  zoom: 16,
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
                              'Pickup point',
                              style: AppTextStyles.homeCaption.copyWith(
                                color: Colors.white,
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
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10.h,
            left: 16.w,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.shade1),
                onPressed: Get.back,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
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
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Check your pickup point',
                        style: AppTextStyles.homeTitle.copyWith(
                          fontSize: 28.sp / 2,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Select a nearby point for easier pickup',
                        style: AppTextStyles.homeCaption.copyWith(
                          color: AppColors.shade2,
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
                            color: const Color(0xFFF8F9FD),
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(color: const Color(0xFFE6E9EE)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.isEmpty ? 'Pickup point' : title,
                                style: AppTextStyles.homeSubtitle.copyWith(
                                  color: AppColors.shade1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                fullAddress,
                                style: AppTextStyles.homeCaption.copyWith(
                                  color: AppColors.shade2,
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
                                      'Updating address...',
                                      style: AppTextStyles.homeCaption.copyWith(
                                        color: AppColors.shade2,
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
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Confirm pickup',
                                    style: AppTextStyles.button.copyWith(
                                      color: Colors.white,
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
}
