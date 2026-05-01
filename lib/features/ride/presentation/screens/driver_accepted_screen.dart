import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:selcom_rides_frontend/shared/widgets/map_widgets.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/widgets/app_draggable_bottom_sheet.dart';
import '../controllers/driver_accepted_controller.dart';
import '../controllers/ride_share_controller.dart';
import '../widgets/ride_common_widgets.dart';
import '../../../../shared/utils/phone_formatter.dart';

/// SCR-11 — Driver accepted (heading to pickup). See `.agent/context/frontend/SCREENS.md`.
class DriverAcceptedScreen extends StatelessWidget {
  const DriverAcceptedScreen({super.key});

  static const double _sheetInitial = 0.3;
  static const double _sheetMin = 0.3;
  static const double _sheetMaxDriverAssigned = 0.54;
  static const double _sheetMaxRideStarted = 0.68;

  void _minimizeSheet(DriverAcceptedController c) {
    if (c.sheetController.isAttached) {
      Future.microtask(() {
        c.sheetController.animateTo(
          _sheetMin,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<DriverAcceptedController>();
    final shareController = Get.find<RideShareController>();
    final topPad = MediaQuery.of(context).padding.top;
    // Use the controller's persistent sheet controller
    final sheetController = c.sheetController;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
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
                    AppColors.white,
                    AppColors.white.withValues(alpha: 0.92),
                    AppColors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Obx(() {
            final ride = c.ride.value;
            final isForOther = ride?.isBookedForOther ?? false;

            return AppMapTopHeader(
              top: topPad + 8.h,
              left: 16,
              right: 16,
              onProfileTap: c.openProfile,
              addressWidget: Expanded(
                child: isForOther && ride != null
                    ? AppMapLocationSummaryCard(
                        leading: Container(
                          padding: EdgeInsets.all(6.w),
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Iconsax.user,
                            color: AppColors.primary,
                            size: 20.sp,
                          ),
                        ),
                        label: "Booking for ${ride.passengerName}",
                        address: "Phone: ${TanzaniaPhoneFormatter.formatInternational(ride.passengerPhone ?? '')}",
                        maxAddressLines: 1,
                      )
                    : AppMapLocationSummaryCard(
                        label: 'Current location',
                        address: c.pickupAddress.isEmpty
                            ? 'Selected location'
                            : c.pickupAddress,
                        maxAddressLines: 1,
                      ),
              ),
            );
          }),
          Obx(() {
            final eta = c.etaLabel.value;

            return Positioned(
              top: topPad + 82.h,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    eta,
                    style: AppTextStyles.homeCaption.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ),
            );
          }),
          Obx(() {
            final screenHeight = MediaQuery.sizeOf(context).height;
            final sheetTopOffset = screenHeight * c.sheetSize.value;
            return Positioned(
              left: 16.w,
              right: 16.w,
              bottom: sheetTopOffset + 12.h,
              child: _rideActionRow(c, shareController),
            );
          }),
          Obx(() {
            final state = c.rideBottomSheetState.value;
            final double maxSheetSize;
            switch (state) {
              case RideBottomSheetState.driverAssigned:
                maxSheetSize = _sheetMaxDriverAssigned;
                break;
              case RideBottomSheetState.rideStarted:
                maxSheetSize = _sheetMaxRideStarted;
                break;
            }
            return AppDraggableBottomSheet(
              controller: sheetController,
              initialChildSize: _sheetInitial,
              minChildSize: _sheetMin,
              maxChildSize: maxSheetSize,
              childBuilder: (scrollController) =>
                  _bottomSheet(c, scrollController),
            );
          }),
        ],
      ),
    );
  }

  Widget _rideActionRow(
    DriverAcceptedController c,
    RideShareController shareController,
  ) {
    return Row(
      children: [
        const Spacer(),
        Obx(() {
          final isSharing = shareController.isSharing.value;
          final canRevoke =
              shareController.enableRevokeLink &&
              shareController.shareUrl.value != null;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Navigation / Track Rider Chip
              // Navigation / Track Rider Chip
              Obx(() {
                final isTracking = c.assignedDriverLocation.value != null;
                // Use the controller's state instead of the map's key state
                final isCurrentlyTracking = c.isTrackingRider.value;

                if (!isCurrentlyTracking && isTracking) {
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: _iconActionChip(
                      icon: Icons.navigation,
                      onTap: () {
                        c.mapWidgetKey.currentState?.retrack();
                        _minimizeSheet(c);
                      },
                      color: AppColors.primary,
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              // Current Location GPS Chip
              _iconActionChip(
                icon: Icons.gps_fixed,
                onTap: () {
                  c.mapWidgetKey.currentState?.stopTracking();
                  c.focusOnUserLocation();
                  _minimizeSheet(c);
                },
                color: AppColors.textMapHint,
              ),
              SizedBox(width: 8.w),
              _iconActionChip(
                icon: isSharing ? Icons.hourglass_top : Icons.share_outlined,
                onTap: isSharing
                    ? () {}
                    : () => shareController.shareRide(c.rideId),
                color: AppColors.textVerified,
              ),
              if (canRevoke) ...[
                SizedBox(width: 8.w),
                _iconActionChip(
                  icon: shareController.isRevoking.value
                      ? Icons.hourglass_top
                      : Icons.link_off_outlined,
                  onTap: () => shareController.revokeShareLink(c.rideId),
                  color: AppColors.primary,
                ),
              ],
            ],
          );
        }),
        SizedBox(width: 10.w),
        _iconActionChip(
          icon: Icons.shield_outlined,
          onTap: () => _showSafetyBottomSheet(c, shareController),
          color: AppColors.textHeading,
        ),
      ],
    );
  }

  Widget _iconActionChip({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          width: 44.w,
          height: 44.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.borderWalletCard),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 20.sp),
        ),
      ),
    );
  }

  void _showSafetyBottomSheet(
    DriverAcceptedController c,
    RideShareController shareController,
  ) {
    Get.bottomSheet(
      SafeArea(
        top: false,
        bottom: false,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 22.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.skeletonBase,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 16.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppStrings.safetyOptions.tr,
                    style: AppTextStyles.homeTitle.copyWith(
                      fontSize: 18.sp,
                      color: AppColors.textHeading,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                _safetyOptionTile(
                  title: AppStrings.shareLiveLocation.tr,
                  icon: Icons.share_location_outlined,
                  onTap: () {
                    if (Get.isBottomSheetOpen ?? false) Get.back();
                    shareController.shareRide(c.rideId);
                  },
                ),
                SizedBox(height: 10.h),
                _safetyOptionTile(
                  title: AppStrings.selcomGoSosHelpline.tr,
                  icon: Icons.support_agent_outlined,
                  onTap: () {
                    if (Get.isBottomSheetOpen ?? false) Get.back();
                    Get.snackbar(
                      AppStrings.safety.tr,
                      AppStrings.shareFeatureComingSoon.tr,
                    );
                  },
                ),
                SizedBox(height: 10.h),
                _safetyOptionTile(
                  title: AppStrings.callPolice.tr,
                  icon: Icons.local_police_outlined,
                  onTap: () {
                    if (Get.isBottomSheetOpen ?? false) Get.back();
                    Get.snackbar(
                      AppStrings.safety.tr,
                      AppStrings.shareFeatureComingSoon.tr,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
    );
  }

  Widget _safetyOptionTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surfaceSubtle,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textHeading, size: 20.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.homeSubtitle.copyWith(
                    color: AppColors.textHeading,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14.sp,
                color: AppColors.textMapHint,
              ),
            ],
          ),
        ),
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
      // Use a stable padding instead of tracking the sheet's pixel-by-pixel size.
      // This prevents the "!_dirty" assertion error and keeps the map stable.
      final stableBottomPad = screenHeight * _sheetMin;

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
            color: AppColors.routeBlue,
            width: 5,
          ),
        );
      }

      return Stack(
        children: [
          AppGoogleMap(
            key: c.mapWidgetKey,
            initialCameraPosition: CameraPosition(target: mid, zoom: 15.5),
            padding: EdgeInsets.only(top: 100.h, bottom: stableBottomPad),
            onMapCreated: (ctrl) {
              c.onMapCreated(ctrl);
              c.onRecenterPressed = () =>
                  c.mapWidgetKey.currentState?.retrack();
            },
            onCameraMove: (_) => c.scheduleAssignedEtaOverlayRefresh(),
            onCameraIdle: c.scheduleAssignedEtaOverlayRefresh,
            showGpsButton: true,
            onGpsPressed: c.focusOnUserLocation,
            onUserInteraction: () => _minimizeSheet(c),
            trackRider: c.isTrackingRider.value,
            onTrackingChanged: (tracking) => c.isTrackingRider.value = tracking,
            markers: markers,
            polylines: polylines,
            minMaxZoomPreference: const MinMaxZoomPreference(12, 19),
            onRiderPositionUpdate: (pos) {
              c.animatedRiderLocation.value = pos;
            },
          ),
          Obx(() {
            if (c.isInitialRouteLoaded.value) return const SizedBox.shrink();

            final assigned = c.assignedDriverLocation.value;
            final loadingText = assigned == null
                ? "Locating driver..."
                : "Calculating best route...";

            return Positioned(
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
                    color: AppColors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.08),
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
                          color: AppColors.routeBlue,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        loadingText,
                        style: AppTextStyles.homeCaption.copyWith(
                          color: AppColors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      );
    });
  }

  Widget _bottomSheet(
    DriverAcceptedController c,
    ScrollController scrollController,
  ) {
    return Obx(() {
      if (c.isLoadingRide.value) {
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 0),
          children: [
            Center(
              child: Container(
                width: 64.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: AppColors.skeletonBase,
                  borderRadius: BorderRadius.circular(37.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ],
        );
      }

      final state = c.rideBottomSheetState.value;
      if (state == RideBottomSheetState.driverAssigned) {
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 0),
          children: [
            Center(
              child: Container(
                width: 64.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: AppColors.skeletonBase,
                  borderRadius: BorderRadius.circular(37.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            _driverAssignedSheet(c),
          ],
        );
      }

      if (state == RideBottomSheetState.rideStarted) {
        return _rideStartedSheetWithFixedHeader(c, scrollController);
      }

      return ListView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 0),
        children: [
          Center(
            child: Container(
              width: 64.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: AppColors.skeletonBase,
                borderRadius: BorderRadius.circular(37.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          _rideProgressSheet(c),
        ],
      );
    });
  }

  Widget _rideStartedSheetWithFixedHeader(
    DriverAcceptedController c,
    ScrollController scrollController,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 64.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: AppColors.skeletonBase,
                borderRadius: BorderRadius.circular(37.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            c.rideProgressTitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.homeTitle.copyWith(
              fontSize: 38.sp / 2,
              color: AppColors.textHeading,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 14.h),
          const Divider(color: AppColors.borderWalletCard, height: 1),
          SizedBox(height: 16.h),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.zero,
              children: [_rideProgressBody(c)],
            ),
          ),
        ],
      ),
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
              color: AppColors.textBody,
            ),
            SizedBox(width: 2.w), // 2px gap from Figma
            Text(
              c.arrivalLabel.value,
              style: AppTextStyles.homeCaption.copyWith(
                fontSize: 15.sp,
                color: AppColors.textBody,
                fontWeight: FontWeight.w500,
                height: 1.33,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          AppStrings.driverIsHeadingToYourLocation.tr,
          textAlign: TextAlign.center,
          style: AppTextStyles.homeTitle.copyWith(
            fontSize: 20.sp,
            color: AppColors.textHeading,
            fontWeight: FontWeight.w600,
            height: 1.7,
            letterSpacing: -0.4,
          ),
        ),
        SizedBox(height: 17.h),
        if (c.isPinRequired.value && c.otpDigits.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppStrings.pin.tr,
                style: AppTextStyles.homeCaption.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.sp,
                  color: AppColors.textBody,
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
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.borderWalletCard,
                      width: 0.787,
                    ),
                  ),
                  child: Text(
                    d,
                    style: AppTextStyles.homeCaption.copyWith(
                      color: AppColors.black,
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
        ],
        Obx(() {
          final plateText =
              '${c.plateLinePrimary.value}${c.plateLineSecondary.value.isNotEmpty ? ' ${c.plateLineSecondary.value}' : ''}'
                  .trim();

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IntrinsicWidth(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 8.h,
                    horizontal: 12.w,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ratingGoldDark,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.borderWalletCard,
                      width: 0.787,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: SvgPictureAsset(
                            AppAssets.icTanzaniaFlag,
                            width: 26.w,
                            height: 17.h,
                          ),
                        ),
                      ),
                      Text(
                        plateText,
                        maxLines: 1,
                        style: AppTextStyles.homeTitle.copyWith(
                          fontSize: 36.sp,
                          height: 1,
                          letterSpacing: 7.2,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDarkOlive,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            c.vehicleSubtitle.value,
                            style: AppTextStyles.homeCaption.copyWith(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.black,
                              height: 1.33,
                            ),
                          ),
                          if (c.formattedSpeedLabel.isNotEmpty) ...[
                            Text(
                              " • ",
                              style: AppTextStyles.homeCaption.copyWith(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textMapHint,
                              ),
                            ),
                            Text(
                              c.formattedSpeedLabel,
                              style: AppTextStyles.homeCaption.copyWith(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                height: 1.33,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
        SizedBox(height: 17.h),
        const Divider(color: AppColors.borderWalletCard, height: 1),
        SizedBox(height: 17.h),
        Row(
          children: [
            Obx(() {
              final avatarUrl = c.driverAvatarUrl.value.trim();
              return Container(
                width: 51.66.w,
                height: 51.66.w,
                decoration: const BoxDecoration(
                  color: AppColors.borderGray,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Image.asset(AppAssets.imgBoda, fit: BoxFit.cover),
                        )
                      : Image.asset(AppAssets.imgBoda, fit: BoxFit.cover),
                ),
              );
            }),
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
                              color: AppColors.textHeading,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w600,
                              height: 1.7,
                            ),
                          ),
                        ),
                        SizedBox(width: 9.w),
                        Icon(
                          Icons.star,
                          color: AppColors.ratingGold,
                          size: 11.sp,
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          c.driverRating.value,
                          style: AppTextStyles.homeCaption.copyWith(
                            color: AppColors.textDim,
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
                        color: AppColors.textDim,
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
              AppStrings.cancelRide.tr,
              style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _rideProgressSheet(DriverAcceptedController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          c.rideProgressTitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.homeTitle.copyWith(
            fontSize: 38.sp / 2,
            color: AppColors.textHeading,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 14.h),
        const Divider(color: AppColors.borderWalletCard, height: 1),
        SizedBox(height: 16.h),
        _rideProgressBody(c),
      ],
    );
  }

  Widget _rideProgressBody(DriverAcceptedController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                      color: AppColors.textHeading,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    c.rideProgressSubtitle,
                    style: AppTextStyles.homeCaption.copyWith(
                      fontSize: 15.sp,
                      color: AppColors.textBody,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Obx(
              () => Image.asset(
                c.bottomSheetVehicleImageAsset.value,
                height: 52.h,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.two_wheeler,
                  size: 40.w,
                  color: AppColors.textBody,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            border: Border.all(color: AppColors.borderWalletCard, width: 0.8),
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
              if (!c.isNearDestination() &&
                  c.ride.value?.pendingStopsUpdate == null &&
                  c.ride.value?.isBookedForOther != true) ...[
                GestureDetector(
                  onTap: c.onEditStops,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: Text(
                        AppStrings.addStops.tr,
                        style: AppTextStyles.homeCaption.copyWith(
                          color: AppColors.primary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Obx(
          () => Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              border: Border.all(color: AppColors.borderWalletCard, width: 0.8),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      AppStrings.totalFare.tr,
                      style: AppTextStyles.homeTitle.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHeading,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                SizedBox(height: 10.h),
                FareBreakdownRow(
                  title: AppStrings.rideCharge.tr,
                  amount: c.rideChargeLabel,
                ),
                SizedBox(height: 8.h),
                FareBreakdownRow(
                  title: AppStrings.bookingFeesAndConvenienceCharges.tr,
                  amount: c.bookingFeeLabel,
                ),
                SizedBox(height: 8.h),
                FareBreakdownRow(
                  title: AppStrings.paymentMode.tr,
                  amount: c.paymentModeLabel,
                ),
                SizedBox(height: 8.h),
                FareBreakdownRow(
                  title: AppStrings.totalAmount.tr,
                  amount: c.totalAmountLabel,
                  isTotal: true,
                ),
              ],
            ),
          ),
        ),
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
              child: Icon(icon, size: 14.sp, color: AppColors.white),
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
                    ? AppColors.figmaIconGreen
                    : AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                badge,
                style: TextStyle(
                  color: AppColors.white,
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
