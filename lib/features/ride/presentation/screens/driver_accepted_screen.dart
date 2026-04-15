import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:selcom_rides_frontend/shared/widgets/map_widgets.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_draggable_bottom_sheet.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../controllers/driver_accepted_controller.dart';
import '../widgets/ride_common_widgets.dart';

/// SCR-11 — Driver accepted (heading to pickup). See `.agent/context/frontend/SCREENS.md`.
class DriverAcceptedScreen extends StatelessWidget {
  const DriverAcceptedScreen({super.key});

  static const double _sheetInitial = 0.58;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<DriverAcceptedController>();
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildMap(context, c),
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
                address: c.pickupAddress.isEmpty ? 'Selected location' : c.pickupAddress,
              ),
            ),
          ),
          Obx(() {
            final px = c.assignedDriverEtaScreenPx.value;
            if (px == null) return const SizedBox.shrink();
            return Positioned(
              left: px.dx - 44.w,
              top: px.dy - 46.h,
              child: IgnorePointer(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    c.etaLabel.value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }),
          Positioned(
            bottom: (MediaQuery.of(context).size.height * _sheetInitial) - 60.h,
            right: 20.w,
            child: AppMapGpsButton(onPressed: c.recenterMap),
          ),
          AppDraggableBottomSheet(
            initialChildSize: _sheetInitial,
            minChildSize: 0.56,
            childBuilder: (scrollController) => _bottomSheet(c, scrollController),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(BuildContext context, DriverAcceptedController c) {
    return Obx(() {
      final pickup = c.pickupLatLng;
      final destination = c.destinationLatLng;
      final assigned = c.assignedDriverLocation.value;
      final route = c.routePoints.toList();

      final markers = <Marker>{};
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
          markerId: const MarkerId('pickup'),
          position: pickup,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );

      final polylines = <Polyline>{};
      polylines.add(
        Polyline(
          polylineId: const PolylineId('pickup_to_destination'),
          points: route.isNotEmpty ? route : [pickup, destination],
          color: const Color(0xFF3073E8),
          width: 4,
        ),
      );
      if (assigned != null) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('driver_to_pickup'),
            points: [assigned, pickup],
            color: const Color(0xFF3073E8),
            width: 4,
          ),
        );
      }

      return AppGoogleMap(
        mapWidgetKey: const ValueKey('driver_accepted_map'),
        initialCameraPosition: CameraPosition(target: pickup, zoom: 15),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * _sheetInitial,
        ),
        onMapCreated: c.onMapCreated,
        onCameraIdle: c.scheduleAssignedEtaOverlayRefresh,
        markers: markers,
        polylines: polylines,
      );
    });
  }

  Widget _bottomSheet(DriverAcceptedController c, ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
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
        Obx(() {
          if (c.isLoadingRide.value) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          final isCompleted =
              c.rideBottomSheetState.value == RideBottomSheetState.rideCompleted;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isCompleted ? 'You have arrived!' : 'Ride Started',
                textAlign: TextAlign.center,
                style: AppTextStyles.homeTitle.copyWith(
                  fontSize: 38.sp / 2,
                  color: const Color(0xFF132235),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 14.h),
              const Divider(color: Color(0xFFE6E9EE), height: 1),
              SizedBox(height: 16.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.rideVehicleLabel,
                          style: AppTextStyles.homeTitle.copyWith(
                            fontSize: 36.sp / 2,
                            color: const Color(0xFF132235),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          isCompleted ? c.arrivalDateLabel : 'Arrived in ${c.etaLabel.value.toLowerCase()}',
                          style: AppTextStyles.homeCaption.copyWith(
                            fontSize: 15.sp,
                            color: const Color(0xFF364B63),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    AppAssets.imgBoda,
                    height: 52.h,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.two_wheeler,
                      size: 40.w,
                      color: const Color(0xFF364B63),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FD),
                  border: Border.all(color: const Color(0xFFE6E9EE), width: 0.8),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  children: [
                    RideLocationsTimeline(
                      startLocation: c.pickupTitle,
                      startAddress: c.pickupAddress,
                      endLocation: c.destinationTitle,
                      endAddress: c.destinationAddress,
                    ),
                    if (!isCompleted) ...[
                      SizedBox(height: 6.h),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Change Drop Location',
                          style: AppTextStyles.homeCaption.copyWith(
                            color: AppColors.primary,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FD),
                  border: Border.all(color: const Color(0xFFE6E9EE), width: 0.8),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Total Fare',
                          style: AppTextStyles.homeTitle.copyWith(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF132235),
                          ),
                        ),
                        const Spacer(),
                        if (isCompleted)
                          Text(
                            c.totalAmountLabel,
                            style: AppTextStyles.homeTitle.copyWith(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF132235),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    FareBreakdownRow(title: 'Ride Charge', amount: c.rideChargeLabel),
                    SizedBox(height: 8.h),
                    FareBreakdownRow(
                      title: 'Booking Fees & Convenience Charges',
                      amount: c.bookingFeeLabel,
                    ),
                    if (!isCompleted) ...[
                      SizedBox(height: 8.h),
                      FareBreakdownRow(
                        title: 'Payment mode',
                        amount: c.paymentModeLabel,
                      ),
                    ],
                    SizedBox(height: 8.h),
                    FareBreakdownRow(
                      title: 'Total Amount',
                      amount: c.totalAmountLabel,
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              if (isCompleted) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FD),
                    border: Border.all(color: const Color(0xFFE6E9EE), width: 0.8),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How was your ride?',
                        style: AppTextStyles.homeTitle.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF132235),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(5, (index) {
                          final star = index + 1;
                          return GestureDetector(
                            onTap: () => c.setRideRating(star),
                            child: Icon(
                              Icons.star,
                              color: star <= c.selectedRideRating.value
                                  ? const Color(0xFFFFCC00)
                                  : const Color(0xFFD9DDE3),
                              size: 34.w,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.headset_mic_outlined, color: const Color(0xFF364B63), size: 18.sp),
                    SizedBox(width: 6.w),
                    Text(
                      'Need Help?',
                      style: AppTextStyles.homeCaption.copyWith(
                        color: const Color(0xFF364B63),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 20.w),
                    Icon(Icons.download_rounded, color: const Color(0xFF364B63), size: 18.sp),
                    SizedBox(width: 6.w),
                    Text(
                      'Download Slip',
                      style: AppTextStyles.homeCaption.copyWith(
                        color: const Color(0xFF364B63),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                AppPrimaryButton(label: 'Finish', onPressed: c.finishCompletedRide),
              ] else ...[
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
            ],
          );
        }),
      ],
    );
  }
}
