import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../controllers/finding_driver_controller.dart';

/// SCR-10 — Finding driver (Figma `207:24889`). Map + nearby drivers socket (same as vehicle selection),
/// ride room for status, 10-minute search window, animated search UI.
class FindingDriverScreen extends StatefulWidget {
  const FindingDriverScreen({super.key});

  @override
  State<FindingDriverScreen> createState() => _FindingDriverScreenState();
}

class _FindingDriverScreenState extends State<FindingDriverScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _sliderController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _sliderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _sliderController.dispose();
    super.dispose();
  }

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
                Expanded(child: _addressCard(c)),
                SizedBox(width: 12.w),
                _profileChip(),
              ],
            ),
          ),
          Positioned(
            bottom: 0.48.sh + 8.h,
            right: 20.w,
            child: _gpsButton(c),
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

  Widget _addressCard(FindingDriverController c) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFD3DDE7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: AppColors.primary, size: 26.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pickup',
                  style: AppTextStyles.homeSubtitle.copyWith(
                    color: const Color(0xFF2A3143),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  c.pickupAddress.isEmpty ? 'Selected location' : c.pickupAddress,
                  style: AppTextStyles.homeCaption.copyWith(
                    color: const Color(0xFF586377),
                    fontSize: 13.sp,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileChip() {
    return Container(
      width: 64.w,
      height: 61.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFD3DDE7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(Icons.person_outline, size: 28.sp, color: Colors.black87),
    );
  }

  Widget _gpsButton(FindingDriverController c) {
    return Material(
      color: const Color(0xFFFBFBFB),
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: c.recenterMap,
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
            child: SvgPictureAsset(
              AppAssets.icGps,
              width: 24.w,
              height: 24.w,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMap(FindingDriverController c) {
    return Obx(() {
      final pickup = c.pickupLatLng;
      final drivers = c.driverMarkerPoints.toList();
      final assigned = c.assignedDriverLocation.value;

      return AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _sliderController]),
        builder: (context, _) {
          final pulse = 0.55 + 0.45 * _pulseController.value;
          final baseRadius = 220.0 * pulse;
          final phase = _sliderController.value * 2 * math.pi;

          final markers = <Marker>{};
          for (var i = 0; i < drivers.length; i++) {
            final base = drivers[i];
            final jitter = LatLng(
              base.latitude + 0.00004 * math.sin(phase + i * 1.7),
              base.longitude + 0.00004 * math.cos(phase + i * 1.1),
            );
            markers.add(
              Marker(
                markerId: MarkerId('near_$i'),
                position: jitter,
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
                radius: baseRadius,
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
        },
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
              _searchingSlider(),
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

  Widget _searchingSlider() {
    return AnimatedBuilder(
      animation: _sliderController,
      builder: (context, _) {
        final t = _sliderController.value;
        return LayoutBuilder(
          builder: (context, constraints) {
            final trackW = constraints.maxWidth;
            final carSize = 40.w;
            final maxLeft = (trackW - carSize - 16.w).clamp(0.0, double.infinity);
            final carLeft = 8.w + t * maxLeft;
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
                      width: trackW * (0.32 + 0.18 * math.sin(t * math.pi * 2)),
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
                        child: Icon(Icons.directions_car, color: Colors.white, size: 22.sp),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
