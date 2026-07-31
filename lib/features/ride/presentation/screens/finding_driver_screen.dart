import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_draggable_bottom_sheet.dart';
import '../../../../shared/widgets/app_google_map.dart';
import '../../../../shared/widgets/app_map_route_polyline.dart';
import '../../../../shared/utils/map_route_marker_utils.dart';
import '../../../../shared/widgets/app_map_route_one_line_bar.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../controllers/finding_driver_controller.dart';

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

  static double _systemBottomInsetPx(BuildContext context) {
    final mq = MediaQuery.of(context);
    final p = mq.padding.bottom;
    final v = mq.viewPadding.bottom;
    return p > v ? p : v;
  }

  /// Slightly taller min/initial when nav bar present — avoids clipping cancel.
  static double _sheetSizeWithNavInset(BuildContext context, double base) {
    final inset = _systemBottomInsetPx(context);
    final h = MediaQuery.sizeOf(context).height;
    if (inset <= 0 || h <= 0) return base;
    return base + (inset / h) * 0.55;
  }

  static double _scrollBottomPad(BuildContext context) {
    return _systemBottomInsetPx(context) > 0 ? 2.h : 0;
  }

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
          Positioned(
            top: topPad + 8.h,
            left: 16.w,
            right: 16.w,
            child: AppMapRouteOneLineBar(
              pickupLabel: c.mapRoutePickupLabel,
              destinationLabel: c.mapRouteDestinationLabel,
            ),
          ),
          Obx(() {
            final isSearching = c.assignedDriverLocation.value == null;
            return AppDraggableBottomSheet(
              controller: sheetController,
              reserveSystemBottomInset: true,
              initialChildSize: _sheetSizeWithNavInset(context, _sheetInitial),
              minChildSize: _sheetSizeWithNavInset(context, _sheetMin),
              maxChildSize: _sheetSizeWithNavInset(
                context,
                isSearching ? _sheetMaxSearching : _sheetMaxCompact,
              ),
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

      if (c.usesMultiStopRouteMarkers) {
        for (var i = 0; i < c.destinations.length; i++) {
          final stop = c.destinations[i];
          final isLast = i == c.destinations.length - 1;
          final icon = isLast
              ? (c.dropIcon.value ?? BitmapDescriptor.defaultMarker)
              : (i < c.stopIcons.length
                    ? c.stopIcons[i]
                    : c.redRouteLetterIconForSequentialIndex(i));

          markers.add(
            Marker(
              markerId: MarkerId(
                'stop_${MapRouteMarkerUtils.letterAt(i + 1)}_'
                '${stop.lat.toStringAsFixed(5)}_'
                '${stop.lng.toStringAsFixed(5)}',
              ),
              position: LatLng(stop.lat, stop.lng),
              icon: icon,
              anchor: const Offset(0.5, 0.5),
            ),
          );
        }
      } else if (c.dropIcon.value != null) {
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
        polylines: AppMapRoutePolyline.set(
          polylineId: 'active_route',
          points: routePoints,
        ),
        circles: circles,
      );
    });
  }

  Widget _bottomSheet(
    FindingDriverController c,
    ScrollController scrollController,
    DraggableScrollableController sheetController,
  ) {
    return SingleChildScrollView(
      controller: scrollController,
      primary: false,
      clipBehavior: Clip.hardEdge,
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, _scrollBottomPad(context)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  style: AppTextStyles.homeTitle,
                ),
                SizedBox(height: 4.h),
                Text(
                  c.currentDescriptionLabel.value,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.homeSubtitle,
                ),

                // Countdown + progress only while status is still `searching`.
                if (c.isSearchingPhase && !c.isRideCancelled.value) ...[
                  SizedBox(height: 36.h),

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

                  // 3. Timer: "X min Y sec remaining" (wall-clock; survives background)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: AppColors.textHeading,
                        size: 18.sp,
                      ),
                      SizedBox(width: 4.5.w),
                      Text(
                        c.findingDriverMinutesRemainLabel(),
                        style: AppTextStyles.homeSubtitle,
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
                      child: AppPrimaryButton(
                        label: AppStrings.searchAgain.tr,
                        onPressed: c.searchAgain,
                        height: 56.h,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      child: AppPrimaryButton(
                        label: AppStrings.backToHome.tr,
                        onPressed: c.goToHome,
                        outlined: true,
                        height: 56.h,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Obx(() {
                final info = c.cancelInfo.value;
                if (info != null && !info.canCancel) {
                  return const SizedBox.shrink();
                }
                return AppPrimaryButton(
                  label: AppStrings.cancelRide.tr,
                  onPressed: c.confirmCancelRide,
                  outlined: true,
                  outlinedBorderColor: AppColors.iconHeartFilled,
                  outlinedTextColor: AppColors.iconHeartFilled,
                  height: 56.h,
                );
              }),
            );
          }),
        ],
      ),
    );
  }
}
