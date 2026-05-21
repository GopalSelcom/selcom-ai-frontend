import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/data/models/responses/rides/fare_estimate_response.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_draggable_bottom_sheet.dart';
import '../../../../shared/widgets/app_google_map.dart';
import '../../../../shared/widgets/app_map_route_one_line_bar.dart';
import '../../../../shared/widgets/vehicle_selection_promo_chip.dart';
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

  @override
  void initState() {
    super.initState();
    controller = Get.find<VehicleSelectionController>();
  }

  double _calculateInitialSheetSize(BuildContext context) {
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;

    if (screenHeight <= 0) return 0.55;

    // Header: top handle space (10.h) + handle (4.h) + space (16.h) + text (~34.h) + space (12.h) = 76.h
    final double headerHeight = 76.h;

    // Estimates list: up to 3 visible items
    final int estimatesCount = controller.estimates.length;
    final int visibleItems = estimatesCount.clamp(0, 3);

    double listHeight;
    if (controller.isLoadingEstimates.value || estimatesCount == 0) {
      listHeight = 120.h; // Loading spinner height
    } else {
      listHeight =
          (visibleItems * 73.h) +
          ((visibleItems - 1).clamp(0, 2) * 10.h) +
          10.h;
    }

    // PaymentBar: top padding (18.h) + button (~56.h) + bottom padding
    final double paymentBarHeight =
        76.h +
        (GetPlatform.isIOS
            ? (bottomPadding > 0
                  ? (bottomPadding - 10.h).clamp(12.h, bottomPadding)
                  : 18.h)
            : (bottomPadding > 0 ? bottomPadding + 8.h : 18.h));

    // Safety margin is zero since list is non-scrollable when <= 3 items are present
    const double safetyMargin = 0;

    final double totalHeight =
        headerHeight + listHeight + paymentBarHeight + safetyMargin;

    return (totalHeight / screenHeight).clamp(0.35, 0.85);
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
              right: 16.w,
              // Targeted rebuild for header labels/actions via update(['route_header']).
              child: GetBuilder<VehicleSelectionController>(
                id: 'route_header',
                builder: (controller) => AppMapRouteOneLineBar(
                  pickupLabel: controller.pickupMapLabel,
                  destinationLabel: controller.destinationMapLabel,
                  onClose: controller.closeVehicleSelection,
                  onEdit: controller.editRouteHeader,
                ),
              ),
            ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 60.h,
            right: 16.w,
            child: Obx(
              () => Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: controller.socketDriverStatusBackground,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Text(
                  controller.socketDriverStatusText,
                  style: AppTextStyles.homeCaption.copyWith(
                    color: controller.socketDriverStatusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ),
          ),
          Obx(() {
            final double factor = _calculateInitialSheetSize(context);
            final int estimatesCount = controller.estimates.length;
            final bool hasMoreThan3 = estimatesCount > 3;
            final double initialFactor = hasMoreThan3
                ? factor.clamp(0.0, 0.6)
                : factor;
            final double maxFactor = hasMoreThan3 ? 0.6 : factor;
            final bool canSnap = hasMoreThan3 && (maxFactor > initialFactor);
            return AppDraggableBottomSheet(
              key: ValueKey('vehicle_selection_sheet_$estimatesCount'),
              initialChildSize: initialFactor,
              minChildSize: initialFactor,
              maxChildSize: maxFactor,
              snap: canSnap,
              snapSizes: canSnap ? [initialFactor, maxFactor] : null,
              childBuilder: (scrollController) =>
                  _bottomSheet(context, scrollController),
            );
          }),
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

      final double factor = _calculateInitialSheetSize(context);
      final int estimatesCount = controller.estimates.length;
      final bool hasMoreThan3 = estimatesCount > 3;
      final double initialFactor = hasMoreThan3
          ? factor.clamp(0.0, 0.6)
          : factor;
      final double mapBottomPadding =
          MediaQuery.sizeOf(context).height * initialFactor;

      final points = controller.routePoints.toList();
      final pickup = LatLng(
        controller.pickupEntity.lat,
        controller.pickupEntity.lng,
      );
      final drops = controller.destinations
          .map((d) => LatLng(d.lat, d.lng))
          .toList(growable: false);
      final lastDrop = drops.isEmpty ? pickup : drops.last;
      final mid = LatLng(
        (pickup.latitude + lastDrop.latitude) / 2,
        (pickup.longitude + lastDrop.longitude) / 2,
      );
      final drivers = controller.driverMarkerPoints.toList();
      final markers = <Marker>{};
      controller.scheduleOverlayProjection(
        pickup: pickup,
        drops: drops,
        devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
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
            onMapDisposed: () => controller.onMapDisposed(),
            // Manual initial zoom level:
            // - Increase value => more zoom in
            // - Decrease value => more zoom out
            initialCameraPosition: CameraPosition(target: mid, zoom: 14.5),
            padding: EdgeInsets.only(
              // Reserve space for the custom top route header.
              top: MediaQuery.paddingOf(context).top + 52.h,
              bottom: mapBottomPadding,
            ),
            onMapCreated: (c) async {
              controller.onMapCreated(c);
              await controller.projectOverlayOffsets(
                pickup: pickup,
                drops: drops,
                devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
              );
            },
            onCameraMove: (_) {
              controller.projectOverlayOffsets(
                pickup: pickup,
                drops: drops,
                devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
              );
            },
            onCameraIdle: () async {
              controller.onCameraIdle();
              await controller.projectOverlayOffsets(
                pickup: pickup,
                drops: drops,
                devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
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
              left: offset.dx,
              top: offset.dy - 8.h,
              child: FractionalTranslation(
                translation: const Offset(-0.5, -1.0),
                child: _locationEditBubble(
                  label: controller.pickupMapLabel,
                  onTap: controller.editPickupFromMap,
                  bubbleColor: AppColors.textHeading,
                  textColor: AppColors.white,
                  leadingLabel: null,
                  onEditTap: controller.editPickupFromMap,
                ),
              ),
            );
          }),
          Obx(() {
            final offsets = controller.dropOverlayOffsets;
            if (offsets.isEmpty) return const SizedBox.shrink();
            return Stack(
              children: [
                for (var i = 0; i < offsets.length; i++)
                  if (offsets[i] != null)
                    Positioned(
                      left: offsets[i]!.dx,
                      top: offsets[i]!.dy - 8.h,
                      child: FractionalTranslation(
                        translation: const Offset(-0.5, -1.0),
                        child: _locationEditBubble(
                          label: controller.dropMapLabelAt(i),
                          onTap: () => controller.editDropAtIndexFromMap(i),
                          bubbleColor: AppColors.pinRed,
                          textColor: AppColors.white,
                          leadingLabel: i == offsets.length - 1
                              ? controller.destinationEtaBadgeText
                              : null,
                          onEditTap: () => controller.editDropAtIndexFromMap(i),
                        ),
                      ),
                    ),
              ],
            );
          }),
        ],
      );
    });
  }

  Widget _locationEditBubble({
    required String label,
    required VoidCallback onTap,
    required Color bubbleColor,
    required Color textColor,
    required String? leadingLabel,
    required VoidCallback onEditTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10.r),
            child: Container(
              height: 34.h,
              constraints: BoxConstraints(minWidth: 92.w, maxWidth: 148.w),
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: bubbleColor.withValues(alpha: 0.28),
                    blurRadius: 12.r,
                    offset: Offset(0, 6.h),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (leadingLabel != null) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        leadingLabel,
                        style: AppTextStyles.homeCaption.copyWith(
                          color: bubbleColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.homeSubtitle.copyWith(
                        color: textColor,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Icon(Icons.chevron_right, color: textColor, size: 16.sp),
                ],
              ),
            ),
          ),
        ),
        Container(
          width: 2.w,
          height: 16.h,
          margin: EdgeInsets.only(bottom: 16.h),
          decoration: BoxDecoration(
            color: bubbleColor.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(999.r),
          ),
        ),
      ],
    );
  }

  Widget _bottomSheet(BuildContext context, ScrollController scrollController) {
    return SafeArea(
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    AppStrings.chooseRide.tr,
                    style: AppTextStyles.homeTitle,
                  ),
                ),
                VehicleSelectionPromoChip(controller: controller),
              ],
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
                controller: scrollController,
                physics: controller.estimates.length <= 3
                    ? const NeverScrollableScrollPhysics()
                    : null,
                padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 10.h),
                itemCount: controller.estimates.length,
                separatorBuilder: (_, __) => SizedBox(height: 10.h),
                itemBuilder: (_, index) {
                  final item = controller.estimates[index];
                  return Obx(() {
                    final selected =
                        controller.selectedVehicleIndex.value == index;
                    final _ = controller.appliedPromoCode.value;
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
                  '${AppStrings.bookRide.tr} ${CurrencyFormatter.formatPayableOrFree(controller.selectedPayableFareAmount, controller.currency, freeLabel: AppStrings.rideFreeLabel.tr)}',
              isLoading: controller.isBooking,
              onActionButtonPressed: controller.bookRide,
            );
          }),
        ],
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
      color: selected
          ? AppColors.primary.withValues(alpha: 0.12)
          : AppColors.surfaceSubtle,
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                          width: 12.w,
                          height: 12.w,
                          color: AppColors.textBody,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${item.maxPassengers ?? 1}',
                          style: AppTextStyles.homeCaption.copyWith(
                            height: 20 / 12,
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
                        height: 20 / 12,
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
                    if (controller.appliedPromoCode.value.trim().isNotEmpty &&
                        item.promoApplied != true &&
                        (item.promoError?.trim().isNotEmpty ?? false)) ...[
                      SizedBox(height: 4.h),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            AppStrings.promoCodeNotValidForVehicle.tr,
                            maxLines: 1,
                            style: AppTextStyles.homeCaption.copyWith(
                              color: AppColors.warningStrong,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _vehicleFarePrice(item),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vehicleFarePrice(FareEstimateItem item) {
    final showPromo =
        item.promoApplied == true &&
        (item.discountedFare != null) &&
        (item.fareEstimate ?? 0) > (item.discountedFare ?? 0);
    if (!showPromo) {
      return Text(
        CurrencyFormatter.formatWithApiCurrency(
          item.fareEstimate ?? 0,
          item.currency,
        ),
        style: AppTextStyles.homeTitle.copyWith(
          fontSize: 16.sp,
          letterSpacing: -0.4,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          CurrencyFormatter.formatWithApiCurrency(
            item.fareEstimate ?? 0,
            item.currency,
          ),
          style: AppTextStyles.homeCaption.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
            decoration: TextDecoration.lineThrough,
            decorationColor: AppColors.black,
            decorationThickness: 3,
            decorationStyle: TextDecorationStyle.solid,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          CurrencyFormatter.formatPayableOrFree(
            item.displayFare,
            item.currency,
            freeLabel: AppStrings.rideFreeLabel.tr,
          ),
          style: AppTextStyles.homeTitle.copyWith(
            fontSize: 16.sp,
            color: AppColors.primary,
            letterSpacing: -0.4,
          ),
        ),
      ],
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
