import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/widgets/app_draggable_bottom_sheet.dart';
import '../../../../shared/widgets/app_map_gps_button.dart';
import '../../../../shared/widgets/app_map_location_summary_card.dart';
import '../../../../shared/widgets/app_map_top_header.dart';
import '../controllers/finding_driver_controller.dart';

class FindingDriverScreen extends StatelessWidget {
  const FindingDriverScreen({super.key});

  static const double _searchCircleRadiusM = 220;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<FindingDriverController>();
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Obx(() {
        final isAssigned = c.ridePhase.value == 'driver_assigned';
        final initialSheetSize = isAssigned ? 0.64 : 0.52;
        return Stack(
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
            AppMapTopHeader(
              top: topPad + 8.h,
              left: 16,
              right: 16,
              addressWidget: Expanded(
                child: AppMapLocationSummaryCard(
                  label: 'Home',
                  address: c.pickupAddress.isEmpty ? 'Selected location' : c.pickupAddress,
                ),
              ),
            ),
            Positioned(
              bottom: (MediaQuery.of(context).size.height * initialSheetSize) - 60.h,
              right: 20.w,
              child: AppMapGpsButton(onPressed: c.recenterMap),
            ),
            _draggableBottomSheet(c, initialSize: initialSheetSize, isAssigned: isAssigned),
          ],
        );
      }),
    );
  }

  Widget _buildMap(FindingDriverController c) {
    return Obx(() {
      final pickup = c.pickupLatLng;
      final mine = c.myLocation.value;
      final drivers = c.driverMarkerPoints.toList();
      final assigned = c.assignedDriverLocation.value;
      final isAssigned = c.ridePhase.value == 'driver_assigned';

      final markers = <Marker>{};
      if (!isAssigned) {
        for (var i = 0; i < drivers.length; i++) {
          final base = drivers[i];
          final isCar = i == 1;
          markers.add(
            Marker(
              markerId: MarkerId('near_$i'),
              position: base,
              icon: isCar
                  ? (c.nearCarMarkerIcon.value ??
                      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure))
                  : (c.nearBikeMarkerIcon.value ??
                      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose)),
              anchor: const Offset(0.5, 0.5),
              flat: true,
            ),
          );
        }
      }
      if (assigned != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('assigned_driver'),
            position: assigned,
            icon: c.assignedDriverMarkerIcon.value ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            anchor: const Offset(0.5, 0.5),
            flat: true,
          ),
        );
      }
      markers.add(
        Marker(
          markerId: const MarkerId('my_location'),
          position: mine,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
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
        polylines: assigned == null
            ? {
                Polyline(
                  polylineId: const PolylineId('mock_rider_route'),
                  points: [mine, pickup],
                  color: const Color(0xFF3073E8),
                  width: 4,
                ),
              }
            : {
                Polyline(
                  polylineId: const PolylineId('mock_rider_route'),
                  points: [mine, pickup],
                  color: const Color(0xFF3073E8),
                  width: 4,
                ),
                Polyline(
                  polylineId: const PolylineId('assigned_route'),
                  points: [assigned, pickup],
                  color: const Color(0xFF3073E8),
                  width: 4,
                ),
              },
        circles: isAssigned
            ? const {}
            : {
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

  Widget _draggableBottomSheet(
    FindingDriverController c, {
    required double initialSize,
    required bool isAssigned,
  }) {
    return AppDraggableBottomSheet(
      initialChildSize: initialSize,
      minChildSize: isAssigned ? 0.56 : 0.48,
      childBuilder: (scrollController) => _bottomSheet(c, scrollController: scrollController),
    );
  }

  Widget _bottomSheet(
    FindingDriverController c, {
    required ScrollController scrollController,
  }) {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
      children: [
        Center(
          child: Container(
            width: 64.w,
            height: 5.h,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(37.r),
            ),
          ),
        ),
        SizedBox(height: 20.h),
        Obx(
          () => c.ridePhase.value == 'driver_assigned'
              ? _driverAssignedContent(c)
              : _searchingContent(c),
        ),
        SizedBox(height: 16.h),
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
      ],
    );
  }

  Widget _searchingContent(FindingDriverController c) {
    return Column(
      children: [
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
      ],
    );
  }

  Widget _driverAssignedContent(FindingDriverController c) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, size: 22.sp, color: Colors.black87),
            SizedBox(width: 6.w),
            Obx(
              () => Text(
                c.arrivalLabel.value,
                style: AppTextStyles.homeCaption.copyWith(
                  fontSize: 15.sp,
                  color: const Color(0xFF364B63),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          'Driver is heading to your location',
          style: AppTextStyles.homeTitle.copyWith(
            fontSize: 20.sp,
            color: const Color(0xFF132235),
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 10.h),
        Obx(
          () => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'OTP',
                style: AppTextStyles.homeCaption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF364B63),
                ),
              ),
              SizedBox(width: 8.w),
              ...c.otpDigits.map(
                (d) => Container(
                  margin: EdgeInsets.only(right: 4.w),
                  width: 28.w,
                  height: 28.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FD),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: const Color(0xFFE6E9EE), width: .8),
                  ),
                  child: Text(
                    d,
                    style: AppTextStyles.homeCaption.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          width: 221.w,
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: const Color(0xFFD9A800),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Obx(
            () => Column(
              children: [
                Text(
                  c.plateDigits.first,
                  style: AppTextStyles.homeTitle.copyWith(
                    fontSize: 48.sp,
                    height: 1,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF131D0B),
                  ),
                ),
                Text(
                  c.plateDigits.last,
                  style: AppTextStyles.homeTitle.copyWith(
                    fontSize: 48.sp,
                    height: 1,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF131D0B),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  c.vehicleDisplay.value,
                  style: AppTextStyles.homeCaption.copyWith(
                    fontSize: 15.sp,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Divider(color: const Color(0xFFE6E9EE), height: 1.h),
        SizedBox(height: 12.h),
        Obx(
          () => Row(
            children: [
              CircleAvatar(
                radius: 24.r,
                backgroundColor: const Color(0xFFD3DDE7),
                child: Text(
                  c.driverName.value.characters.first,
                  style: AppTextStyles.homeTitle.copyWith(
                    color: AppColors.shade1,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          c.driverName.value,
                          style: AppTextStyles.homeTitle.copyWith(
                            color: const Color(0xFF132235),
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        const Icon(Icons.star, color: Color(0xFFF4C542), size: 16),
                        SizedBox(width: 2.w),
                        Text(
                          c.driverRating.value,
                          style: AppTextStyles.homeCaption.copyWith(
                            color: const Color(0xFF585858),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${c.driverVehicle.value} - ${c.driverPlate.value}',
                      style: AppTextStyles.homeCaption.copyWith(
                        color: const Color(0xFF585858),
                        fontSize: 15.sp,
                      ),
                    ),
                  ],
                ),
              ),
              _actionIcon(icon: Icons.call, badge: '1'),
              SizedBox(width: 8.w),
              _actionIcon(icon: Icons.chat, badge: '1'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionIcon({required IconData icon, required String badge}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 34.w,
          height: 34.w,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
          child: Icon(icon, size: 18.sp, color: Colors.white),
        ),
        Positioned(
          top: -2.h,
          right: -2.w,
          child: Container(
            width: 15.w,
            height: 15.w,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

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
