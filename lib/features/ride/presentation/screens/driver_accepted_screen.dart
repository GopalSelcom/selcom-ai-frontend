import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:selcom_rides_frontend/shared/widgets/map_widgets.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/widgets/app_draggable_bottom_sheet.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../controllers/driver_accepted_controller.dart';
import '../widgets/ride_common_widgets.dart';

/// SCR-11 — Driver accepted (heading to pickup). See `.agent/context/frontend/SCREENS.md`.
class DriverAcceptedScreen extends StatelessWidget {
  const DriverAcceptedScreen({super.key});

  static const double _sheetInitial = 0.3;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<DriverAcceptedController>();
    final topPad = MediaQuery.of(context).padding.top;
    final sheetController = DraggableScrollableController();

    // Listen to sheet size changes and update controller
    sheetController.addListener(() {
      c.updateSheetSize(sheetController.size);
    });

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
          Obx(() {
            final px = c.assignedDriverEtaScreenPx.value;
            if (px == null) return const SizedBox.shrink();
            return Positioned(
              left: px.dx - 40.w,
              top: px.dy - 60.h, // Moved higher to avoid clashing with marker
              child: IgnorePointer(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE31E24), // Red as seen in screenshot
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    c.etaLabel.value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }),
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
    DriverAcceptedController c,
    DraggableScrollableController sheetController,
  ) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Obx(() {
      final currentSheetSize = c.sheetSize.value;
      final dynamicBottomPad = screenHeight * currentSheetSize;

      final pickup = c.pickupLatLng;
      final destination = c.destinationLatLng;
      final assigned = c.assignedDriverLocation.value;
      final route = c.routePoints.toList();
      final mid = LatLng(
        (pickup.latitude + destination.latitude) / 2,
        (pickup.longitude + destination.longitude) / 2,
      );

      final markers = <Marker>{};

      // Driver Marker
      if (assigned != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('assigned_driver'),
            position: assigned,
            icon:
                c.assignedDriverMarkerIcon.value ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
            rotation: c.assignedDriverHeading.value,
            anchor: const Offset(0.5, 0.5),
            flat: true,
          ),
        );
      }

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

      // Destinations/Stops Markers
      final stops = c.ride.value?.stops ?? [];
      final isMultiStop = c.ride.value?.isMultiStop ?? false;

      if (isMultiStop && stops.isNotEmpty) {
        for (var i = 0; i < stops.length; i++) {
          final stop = stops[i];

          // Use stopIcons[i] which corresponds to B, C, D...
          // because stopIcons index 0 is 'B', 1 is 'C' etc.
          final icon = (i < c.stopIcons.length)
              ? c.stopIcons[i]
              : (c.dropIcon.value ?? BitmapDescriptor.defaultMarker);

          markers.add(
            Marker(
              markerId: MarkerId('stop_$i'),
              position: LatLng(stop.lat, stop.lng),
              icon: icon,
              anchor: const Offset(0.5, 0.5),
            ),
          );
        }
      } else {
        // Standard Single-Stop Ride logic
        if (c.dropIcon.value != null &&
            c.rideBottomSheetState.value !=
                RideBottomSheetState.driverAssigned) {
          markers.add(
            Marker(
              markerId: const MarkerId('drop'),
              position: destination,
              icon: c.dropIcon.value!,
              anchor: const Offset(0.5, 0.5),
            ),
          );
        }
      }

      final polylines = <Polyline>{};
      if (route.length > 2) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('active_route'),
            points: route,
            color: const Color(0xFF3073E8),
            width: 5,
          ),
        );
      }

      final showRouteLoading = route.length <= 2;
      final loadingText = assigned == null
          ? "Locating driver..."
          : "Calculating best route...";

      return Stack(
        children: [
          AppGoogleMap(
            mapWidgetKey: const ValueKey('driver_accepted_map'),
            initialCameraPosition: CameraPosition(target: mid, zoom: 13.5),
            padding: EdgeInsets.only(
              top: dynamicBottomPad - 40.h, // Balanced with current sheet size
              bottom: dynamicBottomPad,
            ),
            onMapCreated: c.onMapCreated,
            onCameraIdle: c.scheduleAssignedEtaOverlayRefresh,
            showGpsButton: true,
            onGpsPressed: () {
              c.recenterMap();
              if (sheetController.isAttached) {
                sheetController.animateTo(
                  0.3,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              }
            },
            onNavigationPressed: () {
              if (sheetController.isAttached) {
                sheetController.animateTo(
                  0.3,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              }
            },
            onUserInteraction: () {
              if (sheetController.isAttached && sheetController.size > 0.3) {
                sheetController.animateTo(
                  0.3,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            },
            markers: markers,
            polylines: polylines,
            minMaxZoomPreference: const MinMaxZoomPreference(12, 19),
            trackRider: false,
          ),
          if (showRouteLoading)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 150.h,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14.w,
                        height: 14.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF3073E8),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        loadingText,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF364B63),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _bottomSheet(
    DriverAcceptedController c,
    ScrollController scrollController,
  ) {
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
          if (c.rideBottomSheetState.value ==
              RideBottomSheetState.driverAssigned) {
            return _driverAssignedSheet(c);
          }
          return _rideProgressSheet(c);
        }),
      ],
    );
  }

  Widget _driverAssignedSheet(DriverAcceptedController c) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.watch_later_outlined,
              size: 20.sp,
              color: const Color(0xFF364B63),
            ),
            SizedBox(width: 2.w), // 2px gap from Figma
            Text(
              c.arrivalLabel.value,
              style: AppTextStyles.homeCaption.copyWith(
                fontSize: 15.sp,
                color: const Color(0xFF364B63),
                fontWeight: FontWeight.w500,
                height: 1.33,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          'Driver is heading to your location',
          textAlign: TextAlign.center,
          style: AppTextStyles.homeTitle.copyWith(
            fontSize: 20.sp,
            color: const Color(0xFF132235),
            fontWeight: FontWeight.w600,
            height: 1.7,
            letterSpacing: -0.4,
          ),
        ),
        SizedBox(height: 17.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'PIN',
              style: AppTextStyles.homeCaption.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 15.sp,
                color: const Color(0xFF364B63),
                height: 1.33,
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
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: const Color(0xFFE6E9EE),
                    width: 0.787,
                  ),
                ),
                child: Text(
                  d,
                  style: AppTextStyles.homeCaption.copyWith(
                    color: const Color(0xFF000000),
                    fontSize: 12.6.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.28,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 17.h),
        Container(
          width: 221.w,
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: const Color(0xFFD9A800),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFE6E9EE), width: 0.787),
          ),
          child: Obx(
            () => Column(
              children: [
                SizedBox(
                  width: 221.w,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 12.w, top: 4.h),
                      child: SvgPictureAsset(
                        AppAssets.icTanzaniaFlag,
                        width: 26.w,
                        height: 17.h,
                      ),
                    ),
                  ),
                ),
                Text(
                  c.plateLinePrimary.value,
                  style: AppTextStyles.homeTitle.copyWith(
                    fontSize: 48.sp,
                    height: 1,
                    letterSpacing: 9.6, // 20% of 48
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF131D0B),
                  ),
                ),
                if (c.plateLineSecondary.value.isNotEmpty)
                  Text(
                    c.plateLineSecondary.value,
                    style: AppTextStyles.homeTitle.copyWith(
                      fontSize: 48.sp,
                      height: 1,
                      letterSpacing: 9.6,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF131D0B),
                    ),
                  ),
                SizedBox(height: 4.h),
                Text(
                  c.vehicleSubtitle.value,
                  style: AppTextStyles.homeCaption.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF000000),
                    height: 1.33,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 17.h),
        const Divider(color: Color(0xFFE6E9EE), height: 1),
        SizedBox(height: 17.h),
        Row(
          children: [
            Container(
              width: 51.66.w,
              height: 51.66.w,
              decoration: const BoxDecoration(
                color: Color(0xFFD9D9D9),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  AppAssets.imgBoda, // Placeholder for driver image
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            c.driverName.value,
                            style: AppTextStyles.homeTitle.copyWith(
                              color: const Color(0xFF132235),
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w600,
                              height: 1.7,
                            ),
                          ),
                        ),
                        SizedBox(width: 9.w),
                        Icon(
                          Icons.star,
                          color: const Color(0xFFFFD600),
                          size: 11.sp,
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          c.driverRating.value,
                          style: AppTextStyles.homeCaption.copyWith(
                            color: const Color(0xFF585858),
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.33,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      c.driverVehicleLine.value,
                      style: AppTextStyles.homeCaption.copyWith(
                        color: const Color(0xFF585858),
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.33,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _roundAction(
              icon: Icons.call,
              color: AppColors.primary,
              onTap: c.callDriver,
            ),
            SizedBox(width: 9.w),
            Obx(
              () => _roundAction(
                icon: Icons.message_rounded,
                color: AppColors.figmaIconGreen,
                onTap: c.onChatTap,
                badge: c.unreadCount.value > 0
                    ? c.unreadCount.value.toString()
                    : null,
              ),
            ),
          ],
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
              style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _rideProgressSheet(DriverAcceptedController c) {
    final isCompleted =
        c.rideBottomSheetState.value == RideBottomSheetState.rideCompleted &&
        (c.currentRideStatus.value == 'completed' ||
            c.currentRideStatus.value == 'ride_completed');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          c.rideProgressTitle,
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
                    c.rideProgressSubtitle,
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
                stops: c.ride.value?.stops,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.headset_mic_outlined,
                color: const Color(0xFF364B63),
                size: 18.sp,
              ),
              SizedBox(width: 6.w),
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.contactUs),
                child: Text(
                  'Need Help?',
                  style: AppTextStyles.homeCaption.copyWith(
                    color: const Color(0xFF364B63),
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 20.w),
              Icon(
                Icons.download_rounded,
                color: const Color(0xFF364B63),
                size: 18.sp,
              ),
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
        ],
      ],
    );
  }

  Widget _roundAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 33.81.w,
              height: 33.81.w,
              child: Icon(icon, size: 14.sp, color: Colors.white),
            ),
          ),
        ),
        if (badge != null && badge.isNotEmpty)
          Positioned(
            right: -2.w,
            top: -2.h,
            child: Container(
              width: 15.w,
              height: 15.w,
              decoration: BoxDecoration(
                color: (color == AppColors.primary)
                    ? const Color(0xFF269441)
                    : AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                badge,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
