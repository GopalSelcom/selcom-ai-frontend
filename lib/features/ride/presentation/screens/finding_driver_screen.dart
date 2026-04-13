import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
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
        const initialSheetSize = 0.42;
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
            _topMapActions(c, topPad),
            _draggableBottomSheet(c, initialSize: initialSheetSize),
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

  Widget _draggableBottomSheet(FindingDriverController c, {required double initialSize}) {
    return AppDraggableBottomSheet(
      initialChildSize: initialSize,
      minChildSize: 0.42,
      childBuilder: (scrollController) => _bottomSheet(
        c,
        scrollController: scrollController,
      ),
    );
  }

  Widget _bottomSheet(
    FindingDriverController c, {
    required ScrollController scrollController,
  }) {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 0),
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
        _chooseRideContent(c),
        SizedBox(height: 12.h),
        _paymentFooter(c),
      ],
    );
  }

  Widget _chooseRideContent(FindingDriverController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose a ride',
          style: AppTextStyles.homeTitle.copyWith(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            letterSpacing: -0.4,
          ),
        ),
        SizedBox(height: 8.h),
        ...List.generate(
          c.rideOptions.length,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: _rideOptionTile(c, index),
          ),
        ),
      ],
    );
  }

  Widget _rideOptionTile(FindingDriverController c, int index) {
    return Obx(() {
      final opt = c.rideOptions[index];
      final selected = c.selectedRideIndex.value == index;
      return InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () => c.selectRideOption(index),
        child: Container(
          height: 79.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FD),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFE6E9EE),
              width: selected ? 1.2 : .8,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 70.w,
                child: Image.asset(
                  opt.assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.directions_car, color: AppColors.shade2, size: 30.sp),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(
                          opt.name,
                          style: AppTextStyles.homeSubtitle.copyWith(
                            color: const Color(0xFF132235),
                            fontSize: 30.sp / 2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          ' \u2022 ${opt.capacity}',
                          style: AppTextStyles.homeCaption.copyWith(
                            color: const Color(0xFF364B63),
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                    if (opt.nearFast)
                      Container(
                        margin: EdgeInsets.only(top: 2.h, bottom: 2.h),
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5FFF9),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          '\u26A1 NEAR & FAST',
                          style: TextStyle(
                            color: const Color(0xFF269441),
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Text(
                      '${opt.eta} \u2022 ${opt.dropAt}',
                      style: AppTextStyles.homeCaption.copyWith(
                        color: const Color(0xFF364B63),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                opt.fare,
                style: AppTextStyles.homeTitle.copyWith(
                  fontSize: 28.sp / 2,
                  color: const Color(0xFF132235),
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _paymentFooter(FindingDriverController c) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: -16.w),
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pay Using',
                    style: TextStyle(color: Colors.white, fontSize: 13.sp),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Mastercard / Visa',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30.sp / 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Card ending in XX1234',
                    style: TextStyle(color: Colors.white, fontSize: 10.sp),
                  ),
                ],
              ),
            ),
          ),
          Obx(
            () => Container(
              width: 212.w,
              height: 68.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22.r),
              ),
              child: Center(
                child: Text(
                  'Book Ride ${c.selectedFare}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topMapActions(FindingDriverController c, double topPad) {
    return Stack(
      children: [
        Positioned(
          top: topPad + 8.h,
          left: 16.w,
          child: InkWell(
            onTap: Get.back,
            child: SizedBox(
              width: 28.w,
              height: 28.h,
              child: const Icon(Icons.arrow_back, color: Colors.black),
            ),
          ),
        ),
        Positioned(
          top: topPad + 8.h,
          right: 16.w,
          child: Container(
            height: 28.h,
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            decoration: BoxDecoration(
              color: const Color(0xFF2668D2),
              borderRadius: BorderRadius.circular(31.r),
            ),
            child: Row(
              children: [
                const Icon(Icons.settings, color: Colors.white, size: 14),
                SizedBox(width: 4.w),
                Text(
                  'Promotions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

}
