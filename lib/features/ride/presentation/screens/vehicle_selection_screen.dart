import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/data/models/responses/rides/fare_estimate_response.dart';
import '../../../../core/data/models/user_profile_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../controllers/vehicle_selection_controller.dart';

/// SCR-09 — vehicle selection, fare, payment + Book Ride (map uses dummy route + animated drivers).
class VehicleSelectionScreen extends StatefulWidget {
  const VehicleSelectionScreen({super.key});

  @override
  State<VehicleSelectionScreen> createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _polylineAnim;
  late AnimationController _pulseAnim;

  @override
  void initState() {
    super.initState();
    _polylineAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..forward();
    _pulseAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _polylineAnim.dispose();
    _pulseAnim.dispose();
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
                  placeholderBuilder: (_) => const Icon(Icons.arrow_back_ios_new, size: 18),
                ),
                onPressed: Get.back,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 0.58.sh,
            child: _bottomSheet(c),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(VehicleSelectionController c) {
    return Obx(() {
      final points = c.routePoints.toList();
      if (points.isEmpty) {
        return const ColoredBox(color: Color(0xFFF8FAFC));
      }

      return AnimatedBuilder(
        animation: Listenable.merge([_polylineAnim, _pulseAnim]),
        builder: (context, _) {
          final t = _polylineAnim.value.clamp(0.0, 1.0);
          final n = math.max(2, (points.length * t).ceil());
          final visible = points.take(n).toList();

          final phase = _pulseAnim.value * 2 * math.pi;
          final drivers = c.driverMarkerPoints.toList();
          final markers = <Marker>{};
          for (var i = 0; i < drivers.length; i++) {
            final base = drivers[i];
            final jitter = LatLng(
              base.latitude + 0.00012 * math.sin(phase + i * 1.7),
              base.longitude + 0.0001 * math.cos(phase + i * 1.1),
            );
            markers.add(
              Marker(
                markerId: MarkerId('driver_$i'),
                position: jitter,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  i == 0 ? BitmapDescriptor.hueRose : BitmapDescriptor.hueAzure,
                ),
                anchor: const Offset(0.5, 0.5),
              ),
            );
          }

          markers.add(
            Marker(
              markerId: const MarkerId('pickup'),
              position: points.first,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            ),
          );
          markers.add(
            Marker(
              markerId: const MarkerId('drop'),
              position: points.last,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            ),
          );

          return GoogleMap(
            initialCameraPosition: CameraPosition(target: points[points.length ~/ 2], zoom: 13.5),
            onMapCreated: c.onMapCreated,
            polylines: {
              Polyline(
                polylineId: const PolylineId('route'),
                points: visible,
                color: const Color(0xFF2668D2),
                width: 5,
              ),
            },
            markers: markers,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          );
        },
      );
    });
  }

  Widget _bottomSheet(VehicleSelectionController c) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
        child: SafeArea(
        top: false,
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
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
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
            SizedBox(height: 12.h),
            _paymentBar(context, c),
            SizedBox(height: 8.h),
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
    final img = _vehicleImage(item);
    final eta = item.durationMinutes ?? 0;
    final drop = DateTime.now().add(Duration(minutes: eta));
    final dropLabel =
        '${drop.hour.toString().padLeft(2, '0')}:${drop.minute.toString().padLeft(2, '0')}';

    return Material(
      color: selected ? const Color(0xFFFBF0F4) : const Color(0xFFF8F9FD),
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () => c.selectVehicle(index),
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
                        Icon(Icons.person_outline, size: 14.sp, color: AppColors.shade2),
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
          child: Icon(Icons.directions_car, color: AppColors.shade2),
        ),
      ),
    );
  }

  String _vehicleImage(FareEstimateItem e) {
    final n = '${e.vehicleName ?? ''} ${e.displayName ?? ''}'.toLowerCase();
    if (n.contains('boda') || n.contains('bike') || n.contains('moto')) return AppAssets.imgBoda;
    if (n.contains('bajaj') || n.contains('auto')) return AppAssets.imgBajaji;
    return AppAssets.imgCab;
  }

  Widget _paymentBar(BuildContext context, VehicleSelectionController c) {
    return Obx(() {
      final pay = c.selectedPayment.value;
      final fare = c.selectedFareAmount;
      final currency = c.currency;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 18.h),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _openPaymentSheet(context, c),
                borderRadius: BorderRadius.circular(12.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Pay Using',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 18.sp),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        pay?.label ?? 'Select payment',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (pay?.type == 'card')
                        Text(
                          'Card on file',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(22.r),
                onTap: c.isBooking.value ? null : c.bookRide,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                  child: c.isBooking.value
                      ? SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : Text(
                          'Book Ride $currency $fare',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _openPaymentSheet(BuildContext context, VehicleSelectionController c) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Obx(() {
            if (c.isLoadingPayments.value) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Text(
                    'Pay using',
                    style: AppTextStyles.sectionTitle,
                  ),
                ),
                ...c.paymentMethods.map((PaymentMethodModel m) {
                  final sel = c.selectedPayment.value?.id == m.id;
                  return ListTile(
                    leading: Icon(
                      m.type == 'wallet' ? Icons.account_balance_wallet_outlined : Icons.payment,
                      color: AppColors.shade1,
                    ),
                    title: Text(m.label),
                    trailing: sel ? Icon(Icons.check_circle, color: AppColors.primary) : null,
                    onTap: () {
                      c.selectPaymentMethod(m);
                      Navigator.of(ctx).pop();
                    },
                  );
                }),
                SizedBox(height: 8.h),
              ],
            );
          }),
        );
      },
    );
  }
}
