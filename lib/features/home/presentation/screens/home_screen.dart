import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:selcom_rides_frontend/shared/widgets/map_widgets.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/data/models/ride_model.dart';
import '../../../../core/data/models/vehicle_type_model.dart';
import '../../../../core/data/models/responses/get_saved_places_response.dart';
import '../../../ride/data/models/ride_management_models.dart';
import '../controllers/home_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_draggable_bottom_sheet.dart';
import '../widgets/recent_location_tile.dart';
import '../../../../shared/utils/app_dialogs.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  static const double _homeSheetInitialSize = 0.30;

  @override
  Widget build(BuildContext context) {
    controller.onHomeVisible();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitDialog(context);
      },
      child: Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Stack(
        children: [
          // 1. Map Layer (Static Image from Figma)
          Positioned.fill(
            child: Obx(
              () => AppGoogleMap(
                initialCameraPosition: CameraPosition(
                  target: controller.mapCenter.value,
                  zoom: 16,
                ),
                // Keep map focal content above the draggable sheet peek area.
                padding: EdgeInsets.only(
                  bottom:
                      MediaQuery.of(context).size.height *
                      _homeSheetInitialSize,
                ),
                myLocationEnabled: controller.hasLocationPermission.value,
                circles: controller.nearbyPickupRadiusCircles,
                // markers: controller.selectedPickupMarkers,
                onMapCreated: controller.onMapCreated,
                // onCameraMove: controller.onCameraMove,
                // onCameraIdle: controller.onCameraIdle,
              ),
            ),
          ),

          // 2. Top Header (Address + Profile)
          Obx(
            () => AppMapTopHeader(
              top: MediaQuery.of(context).padding.top + 10.h,
              addressWidget: _buildModernAddressBox(),
              onProfileTap: controller.openProfile,
              profileIcon: Icons.person,
              profileIconColor: AppColors.black,
              isLoading: controller.isLoadingHomeData.value,
              isExpanded: controller.isSavedPlacesExpanded.value,
            ),
          ),

          // 3. Floating Action Buttons (GPS)
          Positioned(
            bottom:
                (MediaQuery.of(context).size.height * _homeSheetInitialSize) +
                20.h,
            right: 20.w,
            child: AppMapGpsButton(onPressed: () => controller.recenterMap()),
          ),
          Obx(() {
            if (controller.isLoadingHomeData.value) {
              return const SizedBox.shrink();
            }
            final activeRide = controller.activeRide.value;
            if (activeRide != null) {
              return Positioned(
                left: 16.w,
                right: 16.w,
                bottom: MediaQuery.of(context).padding.bottom + 12.h,
                child: _activeRideCard(activeRide),
              );
            }
            return _buildFigmaDraggableSheet();
          }),
        ],
      ),
    ));
  }

  Widget _buildModernAddressBox() {
    return Expanded(
      child: Obx(() {
        final bool isLoading = controller.isLoadingHomeData.value;
        final String address = controller.currentMapAddress.value;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOutCubic,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          height: 61.h,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.borderDefault),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.06),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: isLoading
              ? Shimmer.fromColors(
                  baseColor: AppColors.skeletonBase,
                  highlightColor: AppColors.skeletonHighlight,
                  child: Center(
                    child: Container(
                      width: 200.w,
                      height: 16.h,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                )
              : Row(
                  children: [
                    SvgPictureAsset(
                      AppAssets.locationIcPickupPin,
                      width: 21.sp,
                      height: 24.sp,
                      color: AppColors.figmaIconGreen,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Current location',
                            style: AppTextStyles.homeSubtitle.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.figmaTextPrimary,
                              fontSize: 15.sp,
                            ),
                          ),
                          Text(
                            address,
                            style: AppTextStyles.homeSubtitle.copyWith(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.figmaTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      }),
    );
  }

  /*
  // REPLACED BY SIMPLIFIED VERSION PER USER REQUEST
  Widget _buildModernAddressBox() {
    return Expanded(
      child: Obx(() {
        if (controller.savedPlaces.isEmpty) { ... }
        ...
      }),
    );
  }
  */

  Widget _buildFigmaDraggableSheet() {
    return AppDraggableBottomSheet(
      initialChildSize: _homeSheetInitialSize,
      minChildSize: _homeSheetInitialSize,
      maxChildSize: 0.9,
      snap: true,
      snapSizes: const [_homeSheetInitialSize, 0.9],
      childBuilder: (scrollController) {
        return ListView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          children: [
              SizedBox(height: 12.h),
              Center(
                child: Container(
                  width: 48.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: AppColors.skeletonBase,
                    borderRadius: BorderRadius.circular(37.r),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              GestureDetector(
                onTap: () => controller.openLocationSelection(),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.skeletonBase,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      SvgPictureAsset(
                        AppAssets.locationIcDestinationPin,
                        color: AppColors.primary,
                        width: 19.sp,
                        height: 19.sp,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        AppStrings.whereAreYouGoing.tr,
                        style: AppTextStyles.homeSubtitle.copyWith(
                          color: AppColors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: 15.sp
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Obx(
                () => controller.savedPlaces.isEmpty
                    ? const SizedBox.shrink()
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _sortedSavedPlaces(controller.savedPlaces)
                              .map((place) => _buildSavedPlaceChip(place))
                              .toList(),
                        ),
                      ),
              ),
              Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (controller.shouldShowRecentSection) ...[
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppStrings.recentLocation.tr,
                              style: AppTextStyles.homeSubtitle.copyWith(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (controller.canViewMoreRecentLocations)
                            TextButton(
                              onPressed: controller.openRecentLocationsScreen,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'View more',
                                style: AppTextStyles.homeCaption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      if (controller.isLoadingHomeData.value)
                        ...List.generate(3, (index) {
                          final bool isLast = index == 2;
                          return Column(
                            children: [
                              _buildRecentLocationSkeleton(bottomSpacing: 0),
                              if (!isLast)
                                Divider(height: 1.h, color: AppColors.bgSoftCircle),
                            ],
                          );
                        })
                      else
                        ...controller.recentDestinationsPreview.asMap().entries.map(
                          (entry) {
                            final bool isLast = entry.key ==
                                controller.recentDestinationsPreview.length - 1;
                            return Column(
                              children: [
                                _buildRecentLocationItem(entry.value,
                                    bottomSpacing: 8, topSpacing: 8),
                                if (!isLast)
                                  Divider(height: 1.h, color: AppColors.bgSoftCircle),
                              ],
                            );
                          },
                        ),
                    ],
                    if (controller.shouldShowVehicleSection) ...[
                      if (controller.shouldShowRecentSection)
                        SizedBox(height: 12.h),
                      if (!controller.shouldShowRecentSection)
                        SizedBox(height: 28.h),
                      Text(
                        AppStrings.exploreVehicle.tr,
                        style: AppTextStyles.homeSubtitle.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      _buildVehicleHorizontalList(),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 20.h),
          ],
        );
      },
    );
  }

  Widget _buildSavedPlaceChip(SavedPlace place) {
    final label = _savedPlaceLabel(place);
    return GestureDetector(
      onTap: () => controller.navigateToVehicleSelectionForSavedLabel(label),
      onLongPress: () => Get.toNamed(AppRoutes.selectSavedLocation, arguments: label),
      child: Container(
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: SvgPictureAsset(
                _chipIconForLabel(label),
                width: 16.w,
                height: 16.w,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: AppTextStyles.homeChip.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
                color: AppColors.textHeading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _savedPlaceLabel(SavedPlace place) {
    final raw = (place.label ?? place.name ?? '').trim();
    if (raw.isNotEmpty) return raw.capitalizeFirst ?? raw;
    return 'Saved';
  }

  String _chipIconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return AppAssets.icHomeChip;
      case 'work':
        return AppAssets.icWorkChip;
      case 'office':
        return AppAssets.icOfficeChip;
      default:
        return AppAssets.icOtherChip;
    }
  }

  List<SavedPlace> _sortedSavedPlaces(List<SavedPlace> places) {
    int priority(String label) {
      switch (label.toLowerCase()) {
        case 'home':
          return 0;
        case 'work':
          return 1;
        case 'office':
          return 2;
        default:
          return 3;
      }
    }

    final sorted = List<SavedPlace>.from(places);
    sorted.sort((a, b) {
      final la = _savedPlaceLabel(a);
      final lb = _savedPlaceLabel(b);
      final pa = priority(la);
      final pb = priority(lb);
      if (pa != pb) return pa.compareTo(pb);
      return la.toLowerCase().compareTo(lb.toLowerCase());
    });
    return sorted;
  }

  Widget _buildRecentLocationItem(RecentDestinationModel loc,
      {double bottomSpacing = 24,double topSpacing = 24}) {
    return Obx(() {
      final distance = controller.calculateDistanceKm(loc.lat, loc.lng);
      final savedPlace = controller.getSavedPlaceFor(loc.address, null);
      final isFavorite = savedPlace?.isFavourite ?? false;
      return RecentLocationTile(
        title: controller.recentDestinationTitleLine(loc),
        address: loc.address,
        distance: distance,
        isFavorite: isFavorite,
        bottomSpacing: bottomSpacing,
        topSpacing: topSpacing,
        onTap: () =>
            controller.navigateToVehicleSelectionForRecentDestination(loc),
        onFavoriteTap: () => controller.toggleFavoriteForRecent(loc),
      );
    });
  }

  Widget _buildRecentLocationSkeleton({double bottomSpacing = 24}) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing.h),
      child: Row(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: AppColors.skeletonBase,
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14.h,
                  width: 130.w,
                  decoration: BoxDecoration(
                    color: AppColors.skeletonBase,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  height: 12.h,
                  width: 200.w,
                  decoration: BoxDecoration(
                    color: AppColors.skeletonBase,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleHorizontalList() {
    return Obx(
      () => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: controller.isLoadingHomeData.value
              ? List.generate(3, (_) => _buildVehicleSkeleton())
              : controller.vehicleTypes
                    .map((vehicle) => _buildVehicleCard(vehicle))
                    .toList(),
        ),
      ),
    );
  }

  Widget _buildVehicleCard(VehicleTypeModel vehicle) {
    final imagePath = controller.vehicleExploreImageAsset(vehicle.name);

    return GestureDetector(
      onTap: () =>
          controller.openLocationSelectionWithPreferredVehicle(vehicle),
      child: Container(
        margin: EdgeInsets.only(right: 16.w),
        child: Column(
          children: [
            Container(
              width: 80.w,
              height: 60.h,
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.directions_car,
                  color: AppColors.textBody,
                  size: 28.sp,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              vehicle.displayName,
              style: AppTextStyles.homeCaption.copyWith(
                color: AppColors.textHeading,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSkeleton() {
    return Container(
      margin: EdgeInsets.only(right: 16.w),
      child: Column(
        children: [
          Container(
            width: 86.w,
            height: 72.h,
            decoration: BoxDecoration(
              color: AppColors.skeletonBase,
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            width: 56.w,
            height: 10.h,
            decoration: BoxDecoration(
              color: AppColors.skeletonBase,
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeRideCard(RideModel ride) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16.r),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: controller.openActiveRide,
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.skeletonBase),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      _activeRideStatusLabel(ride.status.name),
                      style: AppTextStyles.homeCaption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.directions_car_filled,
                    color: AppColors.primary,
                    size: 18.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    (ride.vehicleDisplayName ?? '').trim().isNotEmpty
                        ? (ride.vehicleDisplayName ?? '').trim()
                        : 'Ride',
                    style: AppTextStyles.homeCaption.copyWith(
                      color: AppColors.textHeading,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                ride.pickup.address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.homeSubtitle.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHeading,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                ride.destination.address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.homeCaption.copyWith(
                  color: AppColors.textBody,
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Text(
                    CurrencyFormatter.format(ride.fareEstimate),
                    style: AppTextStyles.homeSubtitle.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeading,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    AppStrings.viewTrip.tr,
                    style: AppTextStyles.homeCaption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14.sp,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _activeRideStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'driverassigned':
        return 'Driver Assigned';
      case 'driverarriving':
        return 'Driver Arriving';
      case 'driverarrived':
        return 'Driver Arrived';
      case 'ridestarted':
      case 'rideinprogress':
        return 'Ride In Progress';
      case 'neardestination':
        return 'Near Destination';
      default:
        return 'Active Ride';
    }
  }

  void _showExitDialog(BuildContext context) {
    AppDialogs.showConfirmationDialog(
      title: AppStrings.exitApp.tr,
      message: AppStrings.exitAppMessage.tr,
      confirmText: AppStrings.yes.tr,
      cancelText: AppStrings.no.tr,
      onConfirm: () {
        SystemNavigator.pop();
      },
    );
  }
}
