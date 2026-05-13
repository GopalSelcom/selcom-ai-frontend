import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' hide Marker;
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_primary_button.dart';
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
          Obx(() {
            if (!c.hasMovedFromInitial || c.mapController == null) {
              return const SizedBox.shrink();
            }
            final initial = c.initialLatLng;
            final trigger = c.selectedLatLng.value;
            return FutureBuilder<Offset?>(
              future: _projectInitialPickupOffset(
                context: context,
                controller: c,
                initialLatLng: initial,
                triggerLatLng: trigger,
              ),
              builder: (context, snap) {
                final offset = snap.data;
                if (offset == null) return const SizedBox.shrink();
                return Positioned(
                  left: offset.dx - 24.w,
                  top: offset.dy - 24.h,
                  child: _PreviousPickupBlueSymbol(size: 48.w),
                );
              },
            );
          }),
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
                              borderRadius: BorderRadius.circular(24.r),
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
                            height: 28.h,
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
              child: const AppBackButton(
                color: AppColors.textHeading,
                alignment: Alignment.center,
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
                  padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
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
                      SizedBox(height: 14.h),
                      Row(
                        children: [
                          SvgPictureAsset(
                            AppAssets.locationIcDestinationPin,
                            width: 36.w,
                            height: 36.w,
                            color: AppColors.mapDropMarkerGreen,
                            placeholderBuilder: (_) => Icon(
                              Icons.push_pin,
                              color: AppColors.mapDropMarkerGreen,
                              size: 18.sp,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.checkYourPickupPoint.tr,
                                style: AppTextStyles.homeTitle.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.black,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                AppStrings.selectANearbyPointForEasierPickup.tr,
                                style: AppTextStyles.homeCaption.copyWith(
                                  color: AppColors.textBody,
                                  fontSize: 15.sp,
                                  height: 20 / 15,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Obx(() {
                        final fullAddress = c.address.value.trim().isEmpty
                            ? 'Selected pickup point'
                            : c.address.value.trim();
                        final title = fullAddress.split(',').first.trim();
                        return Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 14.h),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: AppColors.borderWalletCard,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.isEmpty ? 'Pickup point' : title,
                                style: AppTextStyles.homeSubtitle.copyWith(
                                  color: AppColors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15.sp,
                                  height: 20 / 15,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                fullAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.homeCaption.copyWith(
                                  color: AppColors.textBody,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w400,
                                  height: 20 / 12,
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
                      SizedBox(height: 26.h),
                      Obx(
                        () => SizedBox(
                          width: double.infinity,
                          height: 54.h,
                          child: AppPrimaryButton(
                            label: AppStrings.confirmPickup.tr,
                            onPressed: c.isSubmitting.value
                                ? null
                                : c.confirmPickup,
                            isLoading: c.isSubmitting.value,
                            iconAsset: AppAssets.locationIcArrowRight,
                            iconColor: AppColors.white,
                            height: 54.h,
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

  Future<Offset?> _projectInitialPickupOffset({
    required BuildContext context,
    required ConfirmPickupController controller,
    required LatLng initialLatLng,
    required LatLng triggerLatLng,
  }) async {
    if (controller.mapController == null) return null;
    final raw = await AppMapService.screenOffsetFor(
      controller.mapController!,
      initialLatLng,
    );
    if (raw == null) return null;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    return Offset(raw.dx / dpr, raw.dy / dpr);
  }

  Set<Circle> _buildRouteCircles({required LatLng from, required LatLng to}) {
    final circles = <Circle>{};

    final latDiff = (to.latitude - from.latitude).abs();
    final lngDiff = (to.longitude - from.longitude).abs();
    final hasMoved = latDiff > 0.000001 || lngDiff > 0.000001;
    if (!hasMoved) return circles;

    final approxDistanceMeters = (latDiff + lngDiff) * 111000;
    final dotCount = (approxDistanceMeters / 24).clamp(6, 28).round();
    for (var i = 1; i < dotCount; i++) {
      final t = i / dotCount;
      circles.add(
        Circle(
          circleId: CircleId('pickup_route_dot_$i'),
          center: LatLng(
            from.latitude + (to.latitude - from.latitude) * t,
            from.longitude + (to.longitude - from.longitude) * t,
          ),
          radius: 5,
          fillColor: AppColors.primary.withValues(alpha: 0.95),
          strokeColor: AppColors.primary.withValues(alpha: 0.95),
          strokeWidth: 1,
        ),
      );
    }
    return circles;
  }
}

class _PreviousPickupBlueSymbol extends StatelessWidget {
  const _PreviousPickupBlueSymbol({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: size * 0.16,
                    spreadRadius: size * 0.02,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: size * 0.40,
            top: size * 0.22,
            child: Container(
              width: size * 0.46,
              height: size * 0.46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                border: Border.all(color: AppColors.white, width: 1.3),
              ),
            ),
          ),
          Positioned(
            left: size * 0.14,
            top: size * 0.31,
            child: Transform.rotate(
              angle: -0.65,
              child: CustomPaint(
                size: Size(size * 0.18, size * 0.18),
                painter: const _BlueTrianglePainter(
                  AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlueTrianglePainter extends CustomPainter {
  const _BlueTrianglePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.78, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BlueTrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}
