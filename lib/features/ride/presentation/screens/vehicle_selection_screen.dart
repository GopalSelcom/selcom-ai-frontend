import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:selcom_rides_frontend/shared/widgets/map_widgets.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/data/models/responses/rides/fare_estimate_response.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../payment/presentation/widgets/payment_bar.dart';
import '../controllers/vehicle_selection_controller.dart';

/// SCR-09 — vehicle selection, fare, payment + Book Ride (map uses dummy route + animated drivers).
class VehicleSelectionScreen extends StatefulWidget {
  const VehicleSelectionScreen({super.key});

  @override
  State<VehicleSelectionScreen> createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen>
    with TickerProviderStateMixin {
  static const double _sheetHeightFactor = 0.58;
  // late AnimationController _polylineAnim;
  // late AnimationController _pulseAnim;

  @override
  void initState() {
    super.initState();
    // _polylineAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
    //   ..forward();
    // _pulseAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
    //   ..repeat(reverse: true);
  }

  @override
  void dispose() {
    // _polylineAnim.dispose();
    // _pulseAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<VehicleSelectionController>();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Obx(() => _buildMap(c)),
          _buildMap(c),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8.h,
            left: 16.w,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 2,
              child: IconButton(
                icon: SvgPictureAsset(
                  AppAssets.locationIcArrowLeft,
                  width: 22.w,
                  height: 20.h,
                  placeholderBuilder: (_) =>
                      const Icon(Icons.arrow_back_ios_new, size: 18),
                ),
                onPressed: Get.back,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 14.h,
            right: 16.w,
            child: Obx(
              () => Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  c.isSocketConnected.value
                      ? 'Socket ON • ${c.nearbyDriverCount.value} drivers'
                      : (c.lastSocketError.value.isNotEmpty
                            ? 'Socket OFF • ${c.lastSocketError.value}'
                            : 'Socket OFF'),
                  style: AppTextStyles.homeCaption.copyWith(
                    color: c.isSocketConnected.value
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _sheetHeightFactor.sh,
            child: _bottomSheet(c),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(VehicleSelectionController c) {
    return Obx(() {
      final routePts = c.routePoints.toList();
      final pickup = LatLng(c.pickupEntity.lat, c.pickupEntity.lng);
      final drop = LatLng(c.destinationEntity.lat, c.destinationEntity.lng);
      // Never block the map on empty geometry — use pickup→drop until API polyline arrives.
      final points = routePts.isNotEmpty ? routePts : <LatLng>[pickup, drop];
      final mid = LatLng(
        (pickup.latitude + drop.latitude) / 2,
        (pickup.longitude + drop.longitude) / 2,
      );
      final drivers = c.driverMarkerPoints.toList();
      final markers = <Marker>{};
      for (var i = 0; i < drivers.length; i++) {
        final base = drivers[i];
        final jitter = LatLng(base.latitude, base.longitude);
        markers.add(
          Marker(
            markerId: MarkerId('driver_$i'),
            position: jitter,
            icon: c.driverIcon ?? BitmapDescriptor.defaultMarker, // fallback
            anchor: const Offset(0.5, 0.5),
          ),
        );
      }

      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          icon: c.pickupIcon ?? BitmapDescriptor.defaultMarker,
        ),
      );
      markers.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: drop,
          icon: c.dropIcon ?? BitmapDescriptor.defaultMarker,
        ),
      );

      return AppGoogleMap(
        mapWidgetKey: const ValueKey('vehicle_selection_map'),
        initialCameraPosition: CameraPosition(target: mid, zoom: 13.5),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * _sheetHeightFactor,
        ),
        onMapCreated: c.onMapCreated,
        polylines: {
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: const Color(0xFF2668D2),
            width: 5,
          ),
        },
        markers: markers,
      );

      // return AnimatedBuilder(
      //   animation: Listenable.merge([_polylineAnim, _pulseAnim]),
      //   builder: (context, _) {
      //     final t = _polylineAnim.value.clamp(0.0, 1.0);
      //     final n = math.max(2, (points.length * t).ceil());
      //     final visible = points.take(n).toList();
      //
      //     final phase = _pulseAnim.value * 2 * math.pi;
      //
      //   },
      // );
    });
  }

  Widget _bottomSheet(VehicleSelectionController c) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            SizedBox(height: 10.h),
            Container(
              width: 48.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choose a ride',
                  style: AppTextStyles.homeTitle.copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: Obx(() {
                if (c.isLoadingEstimates.value) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.only(
                    left: 16.w,
                    right: 16.w,
                    bottom: 16.w,
                  ),
                  itemCount: c.estimates.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (_, index) {
                    final item = c.estimates[index];
                    return Obx(() {
                      final selected = c.selectedVehicleIndex.value == index;
                      return _vehicleCard(
                        c: c,
                        index: index,
                        item: item,
                        selected: selected,
                      );
                    });
                  },
                );
              }),
            ),
            // SizedBox(height: 12.h),
            Obx(() => PaymentBar(
                  buttonLabel: 'Book Ride ${c.currency} ${c.selectedFareAmount}',
                  isLoading: c.isBooking.value,
                  onActionButtonPressed: c.bookRide,
                )),
            // SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  Widget _vehicleCard({
    required VehicleSelectionController c,
    required int index,
    required FareEstimateItem item,
    required bool selected,
  }) {
    final img = c.vehicleImage(item);
    final eta = item.durationMinutes ?? 0;
    final drop = DateTime.now().add(Duration(minutes: eta));
    final dropLabel =
        '${drop.hour.toString().padLeft(2, '0')}:${drop.minute.toString().padLeft(2, '0')}';

    return Material(
      color: selected ? const Color(0xFFFBF0F4) : const Color(0xFFF8F9FD),
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () async => await c.selectVehicle(index),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFE6E9EE),
              width: selected ? 1.2 : 0.787,
            ),
          ),
          child: Row(
            children: [
              _vehicleThumb(img),
              SizedBox(width: 18.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.displayName ?? item.vehicleName ?? 'Ride',
                            style: AppTextStyles.homeSubtitle.copyWith(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.shade1,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: Color(0xFF364B63),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        SvgPictureAsset(
                          AppAssets.icPaymentPerson,
                          width: 14.w,
                          height: 14.w,
                          color: AppColors.shade2,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${item.maxPassengers ?? 1}',
                          style: AppTextStyles.homeCaption.copyWith(
                            color: AppColors.shade2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '$eta min away • Drop $dropLabel',
                      style: AppTextStyles.homeCaption.copyWith(
                        color: AppColors.shade2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${item.currency ?? 'TZS'} ${item.fareEstimate ?? 0}',
                style: TextStyle(
                  fontFamily: 'Metropolis',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  color: AppColors.shade1,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vehicleThumb(String asset) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: Image.asset(
        asset,
        width: 72.w,
        height: 52.h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 72.w,
          height: 52.h,
          color: const Color(0xFFF1F5F9),
          child: const Icon(Icons.directions_car, color: AppColors.shade2),
        ),
      ),
    );
  }
}
