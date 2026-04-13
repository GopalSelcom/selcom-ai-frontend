import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/widgets/app_map_gps_button.dart';
import '../../../../shared/widgets/app_map_location_summary_card.dart';
import '../../../../shared/widgets/app_map_profile_chip.dart';
import '../controllers/finding_driver_controller.dart';

/// SCR-10 — Finding driver (Figma `207:24889`). Map + nearby drivers socket (same as vehicle selection),
/// ride room for status, 10-minute search window, progress UI tied to countdown.
class FindingDriverScreen extends StatelessWidget {
  const FindingDriverScreen({super.key});

  /// Search radius on map (meters); static — no pulse animation.
  static const double _searchCircleRadiusM = 220;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<FindingDriverController>();
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildMap(c),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120.h,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.92),
                    Colors.white.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: topPad + 8.h,
            left: 16.w,
            right: 16.w,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppMapLocationSummaryCard(
                    label: 'Pickup',
                    address: c.pickupAddress.isEmpty ? 'Selected location' : c.pickupAddress,
                  ),
                ),
                SizedBox(width: 12.w),
                const AppMapProfileChip(),
              ],
            ),
          ),
          Positioned(
            bottom: 0.48.sh + 8.h,
            right: 20.w,
            child: AppMapGpsButton(onPressed: c.recenterMap),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 0.52.sh,
            child: _bottomSheet(c),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(FindingDriverController c) {
    return Obx(() {
      final pickup = c.pickupLatLng;
      final drivers = c.driverMarkerPoints.toList();
      final assigned = c.assignedDriverLocation.value;

      final markers = <Marker>{};
      for (var i = 0; i < drivers.length; i++) {
        final base = drivers[i];
        markers.add(
          Marker(
            markerId: MarkerId('near_$i'),
            position: base,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              i == 0 ? BitmapDescriptor.hueRose : BitmapDescriptor.hueAzure,
            ),
            anchor: const Offset(0.5, 0.5),
          ),
        );
      }
      if (assigned != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('assigned_driver'),
            position: assigned,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            anchor: const Offset(0.5, 0.5),
          ),
        );
      }
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );

      return GoogleMap(
        key: const ValueKey('finding_driver_map'),
        initialCameraPosition: CameraPosition(target: pickup, zoom: 15),
        onMapCreated: c.onMapCreated,
        markers: markers,
        circles: {
          Circle(
            circleId: const CircleId('search_pulse'),
            center: pickup,
            radius: _searchCircleRadiusM,
            fillColor: const Color(0xFF2668D2).withOpacity(0.12),
            strokeColor: const Color(0xFF2668D2).withOpacity(0.35),
            strokeWidth: 2,
          ),
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
      );
    });
  }

  Widget _bottomSheet(FindingDriverController c) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: [
              SizedBox(height: 10.h),
              Container(
                width: 64.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(37.r),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Finding Your Driver',
                style: AppTextStyles.homeTitle.copyWith(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF132235),
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'The driver will pick you up as soon as possible\nafter they confirm your order',
                textAlign: TextAlign.center,
                style: AppTextStyles.homeCaption.copyWith(
                  fontSize: 15.sp,
                  color: const Color(0xFF364B63),
                  height: 1.33,
                ),
              ),
              SizedBox(height: 20.h),
              _searchingSlider(c),
              SizedBox(height: 16.h),
              Obx(() {
                final mins = c.remainingWholeMinutes;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time, size: 22.sp, color: Colors.black87),
                    SizedBox(width: 6.w),
                    Text(
                      '$mins minutes remain',
                      style: AppTextStyles.homeCaption.copyWith(
                        fontSize: 15.sp,
                        color: const Color(0xFF364B63),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }),
              const Spacer(),
              Obx(
                () => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Text(
                    c.isSocketConnected.value
                        ? 'Live • ${c.nearbyDriverCount.value} nearby'
                        : (c.lastSocketError.value.isNotEmpty
                            ? c.lastSocketError.value
                            : 'Connecting…'),
                    style: AppTextStyles.homeCaption.copyWith(
                      color: c.isSocketConnected.value ? AppColors.success : AppColors.shade2,
                      fontSize: 12.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  onPressed: c.confirmCancelRide,
                  child: Text(
                    'Cancel Ride',
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }

  /// Track width = full 10-minute window; fill advances once per second with the countdown.
  Widget _searchingSlider(FindingDriverController c) {
    return Obx(() {
      final total = FindingDriverController.searchTimeoutSeconds;
      final rem = c.remainingSeconds.value.clamp(0, total);
      final elapsed = total - rem;
      final t = total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 1.0;

      return LayoutBuilder(
        builder: (context, constraints) {
          final trackW = constraints.maxWidth;
          final carSize = 40.w;
          final pad = 8.w;
          final maxTravel = (trackW - 2 * pad - carSize).clamp(0.0, double.infinity);
          final carLeft = pad + t * maxTravel;
          final fillW = (trackW * t).clamp(0.0, trackW);

          return Container(
            height: 48.h,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FD),
              borderRadius: BorderRadius.circular(26.r),
              border: Border.all(color: const Color(0xFFE6E9EE), width: 0.8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26.r),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: fillW,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF3004C), Color(0xFFDE074A)],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chevron_right, color: Colors.white, size: 18.sp),
                          Icon(Icons.chevron_right, color: Colors.white, size: 18.sp),
                          Icon(Icons.chevron_right, color: Colors.white, size: 18.sp),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: carLeft,
                    top: 4.h,
                    child: Container(
                      width: carSize,
                      height: carSize,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDE074A),
                        shape: BoxShape.circle,
                      ),
                      child: SvgPictureAsset(
                        AppAssets.rideFindingLoaderCar,
                        width: 22.w,
                        height: 22.w,
                        placeholderBuilder: (_) =>
                            Icon(Icons.directions_car, color: Colors.white, size: 22.sp),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}
