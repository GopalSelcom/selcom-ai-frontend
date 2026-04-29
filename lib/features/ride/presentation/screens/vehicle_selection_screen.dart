import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:selcom_rides_frontend/shared/widgets/map_widgets.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/data/models/responses/rides/fare_estimate_response.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_draggable_bottom_sheet.dart';
import '../../../payment/presentation/widgets/payment_bar.dart';
import '../controllers/vehicle_selection_controller.dart';

/// SCR-09 — vehicle selection, fare, payment + Book Ride.
class VehicleSelectionScreen extends StatefulWidget {
  const VehicleSelectionScreen({super.key});

  @override
  State<VehicleSelectionScreen> createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  late final VehicleSelectionController controller;

  static const double _sheetHeightFactor = 0.50;

  @override
  void initState() {
    super.initState();
    controller = Get.find<VehicleSelectionController>();
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.of(context).canPop();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildMap(context),
          if (canGoBack)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8.h,
              left: 16.w,
              child: const Material(
                color: AppColors.white,
                shape: CircleBorder(),
                elevation: 2,
                child: AppBackButton(
                  color: AppColors.textHeading,
                  alignment: Alignment.center,
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
                  color: AppColors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.skeletonBase),
                ),
                child: Text(
                  controller.isSocketConnected.value
                      ? AppStrings.socketOnDrivers.trParams({
                          'count': '${controller.nearbyDriverCount.value}',
                        })
                      : (controller.lastSocketError.value.isNotEmpty
                            ? AppStrings.socketOffError.trParams({
                                'error': controller.lastSocketError.value,
                              })
                            : AppStrings.socketOff.tr),
                  style: AppTextStyles.homeCaption.copyWith(
                    color: controller.isSocketConnected.value
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          AppDraggableBottomSheet(
            initialChildSize: _sheetHeightFactor,
            minChildSize: _sheetHeightFactor,
            maxChildSize: 0.9,
            snap: true,
            snapSizes: const [_sheetHeightFactor, 0.9],
            childBuilder: (_) => _bottomSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(BuildContext context) {
    return Obx(() {
      if (!controller.isMapDataReady) {
        // If data is lost, we reset the visual readiness
        if (controller.isMapVisualReady.value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.isMapVisualReady.value = false;
          });
        }
        return const ColoredBox(
          color: AppColors.pageBackground,
          child: SizedBox.expand(),
        );
      }

      final points = controller.routePoints.toList();
      final pickup = LatLng(
        controller.pickupEntity.lat,
        controller.pickupEntity.lng,
      );
      final drop = LatLng(
        controller.destinationEntity.lat,
        controller.destinationEntity.lng,
      );
      final mid = LatLng(
        (pickup.latitude + drop.latitude) / 2,
        (pickup.longitude + drop.longitude) / 2,
      );
      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      final drivers = controller.driverMarkerPoints.toList();
      final markers = <Marker>{};
      controller.scheduleOverlayProjection(
        pickup: pickup,
        drop: drop,
        devicePixelRatio: devicePixelRatio,
      );
      for (var i = 0; i < drivers.length; i++) {
        final jitter = drivers[i];
        markers.add(
          Marker(
            markerId: MarkerId('driver_$i'),
            position: jitter,
            icon: controller.driverIcon ?? controller.pickupIcon!,
            anchor: const Offset(0.5, 0.5),
          ),
        );
      }

      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          icon: controller.pickupIcon ?? BitmapDescriptor.defaultMarker,
          consumeTapEvents: true,
          onTap: controller.editPickupFromMap,
        ),
      );

      for (var i = 0; i < controller.destinations.length; i++) {
        final d = controller.destinations[i];
        final isLast = i == controller.destinations.length - 1;

        BitmapDescriptor icon;
        if (isLast) {
          icon = controller.dropIcon ?? BitmapDescriptor.defaultMarker;
        } else {
          // Use numbered icons for intermediate stops
          icon = (i < controller.stopIcons.length)
              ? controller.stopIcons[i]
              : (controller.dropIcon ?? BitmapDescriptor.defaultMarker);
        }

        markers.add(
          Marker(
            markerId: MarkerId('drop_$i'),
            position: LatLng(d.lat, d.lng),
            icon: icon,
            consumeTapEvents: isLast,
            onTap: isLast ? controller.editDropFromMap : null,
          ),
        );
      }

      return Stack(
        fit: StackFit.expand,
        children: [
          AppGoogleMap(
            key: const ValueKey('vehicle_selection_map'),
            // Manual initial zoom level:
            // - Increase value => more zoom in
            // - Decrease value => more zoom out
            initialCameraPosition: CameraPosition(target: mid, zoom: 14.8),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * _sheetHeightFactor,
            ),
            onMapCreated: (c) async {
              controller.onMapCreated(c);
              await controller.projectOverlayOffsets(
                pickup: pickup,
                drop: drop,
                devicePixelRatio: devicePixelRatio,
              );
            },
            onCameraMove: (_) {
              controller.projectOverlayOffsets(
                pickup: pickup,
                drop: drop,
                devicePixelRatio: devicePixelRatio,
              );
            },
            onCameraIdle: () async {
              controller.onCameraIdle();
              await controller.projectOverlayOffsets(
                pickup: pickup,
                drop: drop,
                devicePixelRatio: devicePixelRatio,
              );
            },
            polylines: {
              Polyline(
                polylineId: const PolylineId('route'),
                points: points,
                color: AppColors.inputBorderActive,
                width: 5,
              ),
            },
            markers: markers,
          ),
          IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: controller.isMapVisualReady.value ? 0 : 1,
              child: const ColoredBox(
                color: AppColors.pageBackground,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),
          ),
          Obx(() {
            final offset = controller.pickupOverlayOffset.value;
            if (offset == null) return const SizedBox.shrink();
            return Positioned(
              left: offset.dx - 40.w,
              top: offset.dy - 70.h,
              child: _locationEditBubble(
                label: controller.compactAddress(controller.pickupEntity.address),
                onEditTap: controller.editPickupFromMap,
              ),
            );
          }),
          Obx(() {
            final offset = controller.dropOverlayOffset.value;
            if (offset == null) return const SizedBox.shrink();
            return Positioned(
              left: offset.dx - 40.w,
              top: offset.dy - 70.h,
              child: _locationEditBubble(
                label: controller.compactAddress(
                  controller.destinationEntity.address,
                ),
                onEditTap: controller.editDropFromMap,
              ),
            );
          }),
        ],
      );
    });
  }

  Widget _locationEditBubble({
    required String label,
    required VoidCallback onEditTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80.w,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.homeSubtitle.copyWith(
                    color: AppColors.textHeading,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Material(
                color: AppColors.bgSoftCircle,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onEditTap,
                  child: Padding(
                    padding: EdgeInsets.all(1.w),
                    child: Icon(
                      Icons.edit,
                      color: AppColors.textMapHint,
                      size: 12.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 2.w,
          height: 12.h,
          color: AppColors.black.withValues(alpha: 0.8),
        ),
      ],
    );
  }

  Widget _bottomSheet(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
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
                color: AppColors.skeletonBase,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppStrings.chooseRide.tr,
                  style: AppTextStyles.homeTitle.copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: Obx(() {
                if (controller.isLoadingEstimates.value) {
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
                  itemCount: controller.estimates.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (_, index) {
                    final item = controller.estimates[index];
                    return Obx(() {
                      final selected =
                          controller.selectedVehicleIndex.value == index;
                      return _vehicleCard(
                        index: index,
                        item: item,
                        selected: selected,
                      );
                    });
                  },
                );
              }),
            ),
            Obx(() {
              return PaymentBar(
                buttonLabel:
                    '${AppStrings.bookRide.tr} ${CurrencyFormatter.format(controller.selectedFareAmount)}',
                isLoading: controller.isBooking,
                onActionButtonPressed: controller.bookRide,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _vehicleCard({
    required int index,
    required FareEstimateItem item,
    required bool selected,
  }) {
    final img = controller.vehicleImage(item);
    final eta = item.durationMinutes ?? 0;
    final drop = DateTime.now().add(Duration(minutes: eta));
    final dropLabel =
        '${drop.hour.toString().padLeft(2, '0')}:${drop.minute.toString().padLeft(2, '0')}';

    return Material(
      color: selected ? AppColors.primaryLight : AppColors.surfaceSubtle,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () async => await controller.selectVehicle(index),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.borderWalletCard,
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
                            item.displayName ??
                                item.vehicleName ??
                                AppStrings.fallbackRideName.tr,
                            style: AppTextStyles.homeSubtitle.copyWith(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textHeading,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: AppColors.textBody,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        SvgPictureAsset(
                          AppAssets.icPaymentPerson,
                          width: 14.w,
                          height: 14.w,
                          color: AppColors.textBody,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${item.maxPassengers ?? 1}',
                          style: AppTextStyles.homeCaption.copyWith(
                            color: AppColors.textBody,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      AppStrings.etaMinutesAwayDropTime.trParams({
                        'minutes': '$eta',
                        'time': dropLabel,
                      }),
                      style: AppTextStyles.homeCaption.copyWith(
                        color: AppColors.textBody,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if ((item.waypointCharge ?? 0) > 0 ||
                        controller.destinations.length > 1) ...[
                      SizedBox(height: 2.h),
                      Text(
                        AppStrings.includesStopFee.tr,
                        style: AppTextStyles.homeCaption.copyWith(
                          color: AppColors.primary,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.format(item.fareEstimate ?? 0),
                style: TextStyle(
                  fontFamily: AppTextStyles.metropolisFont,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHeading,
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
          color: AppColors.bgSoftCircle,
          child: const Icon(Icons.directions_car, color: AppColors.textBody),
        ),
      ),
    );
  }
}
