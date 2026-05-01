import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:selcom_rides_frontend/shared/widgets/map_widgets.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_draggable_bottom_sheet.dart';
import '../controllers/finding_driver_controller.dart';
import '../../../../shared/utils/phone_formatter.dart';

class FindingDriverScreen extends StatefulWidget {
  const FindingDriverScreen({super.key});

  @override
  State<FindingDriverScreen> createState() => _FindingDriverScreenState();
}

class _FindingDriverScreenState extends State<FindingDriverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  static const double _sheetInitial = 0.38;
  static const double _sheetMin = 0.28;
  static const double _sheetMaxCompact = 0.44;
  static const double _sheetMaxSearching = 0.38;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<FindingDriverController>();
    final topPad = MediaQuery.paddingOf(context).top;
    final sheetController = DraggableScrollableController();
    sheetController.addListener(() {
      c.updateSheetSize(sheetController.size);
    });

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return _buildMap(context, c, sheetController);
            },
          ),
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
            final isForOther = c.isBookedForOther.value;

            return AppMapTopHeader(
              top: topPad + 8.h,
              left: 16,
              right: 16,
              onProfileTap: c.openProfile,
              addressWidget: Expanded(
                child: isForOther
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
                        label: "Booking for ${c.passengerName.value}",
                        address: "Phone: +${TanzaniaPhoneFormatter.formatString(c.passengerPhone.value ?? '')}",
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
            final isSearching = c.assignedDriverLocation.value == null;
            return AppDraggableBottomSheet(
              controller: sheetController,
              initialChildSize: _sheetInitial,
              minChildSize: _sheetMin,
              maxChildSize: isSearching ? _sheetMaxSearching : _sheetMaxCompact,
              childBuilder: (scrollController) =>
                  _bottomSheet(c, scrollController, sheetController),
            );
          }),
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
      final sheetSize = c.sheetSize.value;
      final markers = <Marker>{};
      final circles = <Circle>{};

      // 1. Generate Animated Pulse Circles (Map Waves)
      if (!c.isRideCancelled.value) {
        final pulseVal = _pulseController.value;
        const int circleCount = 3;
        for (int i = 0; i < circleCount; i++) {
          final rippleProgress = (pulseVal + (i / circleCount)) % 1.0;

          // Use an exponential-like curve for radius expansion
          final easedProgress = Curves.easeOutCirc.transform(rippleProgress);
          final radius = 500 * easedProgress; // Max radius 500m

          final opacityBase = (1.0 - easedProgress).clamp(0.0, 1.0);

          // Much darker alpha for better visibility
          final alphaFactor = i == 0 ? 0.85 : (i == 1 ? 0.60 : 0.35);

          circles.add(
            Circle(
              circleId: CircleId('pulse_wave_$i'),
              center: pickup,
              radius: radius,
              fillColor: AppColors.routeBlue.withValues(
                alpha: opacityBase * alphaFactor,
              ),
              strokeColor: AppColors.routeBlue.withValues(
                alpha: opacityBase * alphaFactor * 1.5,
              ),
              strokeWidth: 2, // Thicker stroke for visibility
            ),
          );
        }
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
        key: const ValueKey('finding_driver_map'),
        initialCameraPosition: CameraPosition(target: pickup, zoom: 15),
        padding: EdgeInsets.only(
          top: topPad + 80.h,
          bottom: MediaQuery.of(context).size.height * sheetSize,
        ),
        onMapCreated: c.onMapCreated,
        markers: markers,
        showGpsButton: true,
        onGpsPressed: c.recenterMap,
        trackRider: true,
        onRiderPositionUpdate: (pos) => c.animatedRiderLocation.value = pos,
        onUserInteraction: () {
          if (sheetController.isAttached && sheetController.size > _sheetMin) {
            sheetController.animateTo(
              _sheetInitial,
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
              color: AppColors.inputBorderActive,
              width: 5,
            ),
          if (routePoints.isEmpty && isPickupRoute && driver != null)
            Polyline(
              polylineId: const PolylineId('fallback_pickup_route'),
              points: [driver, pickup],
              color: AppColors.inputBorderActive.withValues(alpha: 0.5),
              width: 3,
            ),
        },
        circles: circles,
      );
    });
  }

  Widget _bottomSheet(
    FindingDriverController c,
    ScrollController scrollController,
    DraggableScrollableController sheetController,
  ) {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 24.h),
      children: [
        Center(
          child: Container(
            width: 48.w,
            height: 5.h,
            decoration: BoxDecoration(
              color: AppColors.skeletonBase,
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        ),
        SizedBox(height: 24.h),

        // 1. Title & Subtitle (Centered)
        Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                c.currentStatusLabel.value,
                textAlign: TextAlign.center,
                style: AppTextStyles.homeTitle.copyWith(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textHeading,
                ),
              ),
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 13.w),
                child: Text(
                  c.currentDescriptionLabel.value,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.homeCaption.copyWith(
                    fontSize: 14.sp,
                    color: AppColors.figmaTextSecondary,
                    height: 1.4,
                  ),
                ),
              ),

              if (!c.isRideCancelled.value) ...[
                SizedBox(height: 42.h),

                // 2. Bolt-like Linear Progress Bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      minHeight: 6.h,
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.15,
                      ),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20.h),

                // 3. Timer (Icon + Text)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: AppColors.textHeading,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '${c.remainingSeconds.value ~/ 60} minutes remain',
                      style: AppTextStyles.homeCaption.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHeading,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        SizedBox(height: 28.h),

        // 4. Action Buttons (Search Again & Back to Home OR Cancel)
        Obx(() {
          if (c.isRideCancelled.value) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (sheetController.isAttached && sheetController.size > 0.35) {
                sheetController.animateTo(
                  0.35,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: c.searchAgain,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 18.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Search Again',
                        style: AppTextStyles.button.copyWith(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Get.offAllNamed(AppRoutes.home),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.borderNeutralStrong,
                          width: 1.5,
                        ),
                        padding: EdgeInsets.symmetric(vertical: 18.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      child: Text(
                        'Back to Home',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.textHeading,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: OutlinedButton(
              onPressed: c.confirmCancelRide,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                padding: EdgeInsets.symmetric(vertical: 18.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(
                'Cancel Ride',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.primary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
