import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:selcom_rides_frontend/shared/widgets/map_widgets.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/widgets/app_draggable_bottom_sheet.dart';
import '../controllers/finding_driver_controller.dart';

class FindingDriverScreen extends StatelessWidget {
  const FindingDriverScreen({super.key});

  static const double _searchCircleRadiusM = 220;
  static const double _sheetInitial = 0.52;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<FindingDriverController>();
    final topPad = MediaQuery.paddingOf(context).top;
    final sheetController = DraggableScrollableController();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildMap(context, c, sheetController),
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
            onProfileTap: c.openProfile,
            addressWidget: Expanded(
              child: AppMapLocationSummaryCard(
                label: 'Home',
                address: c.pickupAddress.isEmpty
                    ? 'Selected location'
                    : c.pickupAddress,
              ),
            ),
          ),
          AppDraggableBottomSheet(
            controller: sheetController,
            initialChildSize: _sheetInitial,
            minChildSize: 0.3,
            childBuilder: (scrollController) =>
                _bottomSheet(c, scrollController),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(
    BuildContext context,
    FindingDriverController c,
    DraggableScrollableController sheetController,
  ) {
    final topPad = MediaQuery.paddingOf(context).top;
    return Obx(() {
      final pickup = c.pickupLatLng;
      final destination = c.destinationLatLng;
      final driver = c.assignedDriverLocation.value;
      final routePoints = c.activeRoutePoints.toList();
      final isPickupRoute = c.routeTarget.value == 'pick_up';
      final markers = <Marker>{};

      // Pickup Marker
      if (c.pickupIcon.value != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: pickup,
            icon: c.pickupIcon.value!,
            anchor: const Offset(0.5, 0.5),
          ),
        );
      }

      // Drop/Destination Marker
      if (c.dropIcon.value != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: destination,
            icon: c.dropIcon.value!,
            anchor: const Offset(0.5, 0.5),
          ),
        );
      }

      // Driver Marker
      if (driver != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('assigned_driver'),
            position: driver,
            icon:
                c.assignedDriverMarkerIcon.value ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
            anchor: const Offset(0.5, 0.5),
            flat: true,
          ),
        );
      } else {
        // Nearby Drivers Markers (only show if no driver is assigned yet)
        for (var i = 0; i < c.driverMarkerPoints.length; i++) {
          markers.add(
            Marker(
              markerId: MarkerId('nearby_driver_$i'),
              position: c.driverMarkerPoints[i],
              icon:
                  c.assignedDriverMarkerIcon.value ??
                  BitmapDescriptor.defaultMarker,
              anchor: const Offset(0.5, 0.5),
            ),
          );
        }
      }
      return AppGoogleMap(
        mapWidgetKey: const ValueKey('finding_driver_map'),
        initialCameraPosition: CameraPosition(target: pickup, zoom: 15),
        padding: EdgeInsets.only(
          top: topPad + 80.h,
          bottom: MediaQuery.of(context).size.height * _sheetInitial,
        ),
        onMapCreated: c.onMapCreated,
        markers: markers,
        showGpsButton: true,
        onGpsPressed: c.recenterMap,
        onUserInteraction: () {
          if (sheetController.isAttached && sheetController.size > 0.3) {
            sheetController.animateTo(
              0.3,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        },
        polylines: {
          if (routePoints.isNotEmpty)
            Polyline(
              polylineId: const PolylineId('active_route'),
              points: routePoints,
              color: const Color(0xFF3073E8),
              width: 5,
            ),
          if (routePoints.isEmpty && isPickupRoute && driver != null)
            Polyline(
              polylineId: const PolylineId('fallback_pickup_route'),
              points: [driver, pickup],
              color: const Color(0xFF3073E8).withOpacity(0.5),
              width: 3,
            ),
        },
        circles: isPickupRoute
            ? {
                Circle(
                  circleId: const CircleId('search_pulse'),
                  center: pickup,
                  radius: _searchCircleRadiusM,
                  fillColor: const Color(0xFF2668D2).withOpacity(0.12),
                  strokeColor: const Color(0xFF2668D2).withOpacity(0.35),
                  strokeWidth: 2,
                ),
              }
            : <Circle>{},
      );
    });
  }

  Widget _bottomSheet(
    FindingDriverController c,
    ScrollController scrollController,
  ) {
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
          () => Text(
            c.currentStatusLabel.value,
            textAlign: TextAlign.center,
            style: AppTextStyles.homeTitle.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF132235),
              letterSpacing: -0.4,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Obx(
          () => Text(
            c.currentDescriptionLabel.value,
            textAlign: TextAlign.center,
            style: AppTextStyles.homeCaption.copyWith(
              fontSize: 15.sp,
              color: const Color(0xFF364B63),
              height: 1.33,
            ),
          ),
        ),
        SizedBox(height: 20.h),
        Obx(() {
          if (c.currentStatusLabel.value == 'Finding Your Driver') {
            return _searchingSlider(c);
          }
          return const SizedBox.shrink();
        }),
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
        SizedBox(height: 12.h),
        // SizedBox(
        //   width: double.infinity,
        //   child: TextButton(
        //     onPressed: c.debugSkipToDriverAccepted,
        //     child: const Text('Temporary: Open SCR-11'),
        //   ),
        // ),
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
              style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w600),
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
          final carSize = 64.w;
          final maxTravel = (trackW - carSize).clamp(0.0, double.infinity);
          final carLeft = t * maxTravel;
          final fillW = (carLeft + carSize / 2).clamp(0.0, trackW);

          return Container(
            height: 52.h,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(26.r),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Pink Fill
                ClipRRect(
                  borderRadius: BorderRadius.circular(26.r),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: fillW,
                      height: double.infinity,
                      decoration: const BoxDecoration(color: Color(0xFFE11D48)),
                      alignment: Alignment.center,
                      child: ShaderMask(
                        shaderCallback: (bounds) {
                          return const LinearGradient(
                            colors: [Colors.transparent, Colors.white],
                            stops: [0.0, 0.4],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.dstIn,
                        child: const SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: NeverScrollableScrollPhysics(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chevron_right,
                                color: Colors.white,
                                size: 24,
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.white,
                                size: 24,
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.white,
                                size: 24,
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.white,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // 2. Car Thumb
                Positioned(
                  left: carLeft,
                  top: -6.h,
                  child: Container(
                    width: carSize,
                    height: carSize,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11D48),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(12.w),
                    child: SvgPictureAsset(
                      _getVehicleAsset(c.requestedVehicleType),
                      width: 32.w,
                      height: 32.w,
                      placeholderBuilder: (_) => Icon(
                        Icons.directions_car,
                        color: Colors.white,
                        size: 32.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  String _getVehicleAsset(String? vehicleType) {
    if (vehicleType == null) return AppAssets.rideFindingLoaderCar;
    final vt = vehicleType.toLowerCase();
    if (vt.contains('boda') || vt.contains('bike')) return AppAssets.boda;
    if (vt.contains('bajaj')) return AppAssets.bajaj;
    return AppAssets.imgCab;
  }
}
