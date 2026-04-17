import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:selcom_rides_frontend/shared/widgets/map_widgets.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/data/models/ride_model.dart';
import '../../../../core/data/models/vehicle_type_model.dart';
import '../../../ride/data/models/ride_management_models.dart';
import '../controllers/home_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_map_gps_button.dart';
import '../../../../shared/widgets/app_map_top_header.dart';
import '../../../../core/data/models/responses/get_saved_places_response.dart';
import '../../../../core/routes/app_routes.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});
  static const double _homeSheetInitialSize = 0.45;

  @override
  Widget build(BuildContext context) {
    controller.onHomeVisible();
    return Scaffold(
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
                markers: controller.selectedPickupMarkers,
                onMapCreated: controller.onMapCreated,
                onCameraMove: controller.onCameraMove,
                onCameraIdle: controller.onCameraIdle,
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
              profileIconColor: Colors.black,
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
    );
  }

  Widget _buildModernAddressBox() {
    return Expanded(
      child: Obx(() {
        if (controller.savedPlaces.isEmpty) {
          return AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            clipBehavior: Clip.hardEdge,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOutCubic,
              padding: EdgeInsets.all(12.w),
              height: 75.h, // Matched with Profile Chip height
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: controller.isLoadingHomeData.value
                    ? Shimmer.fromColors(
                        baseColor: const Color(0xFFE2E8F0),
                        highlightColor: const Color(0xFFF8FAFC),
                        child: Container(
                          width: 200.w,
                          height: 16.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      )
                    : Text(
                        controller.currentMapAddress.value,
                        style: AppTextStyles.homeSubtitle.copyWith(
                          color: AppColors.shade2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
              ),
            ),
          );
        }

        final placesToShow = controller.addressHeaderPlacesToShow;
        final bool isExpanded = controller.isSavedPlacesExpanded.value;

        return AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          clipBehavior: Clip.hardEdge,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
            padding: EdgeInsets.all(12.w),
            height: isExpanded
                ? null
                : 75.h, // Matched with Profile Chip height
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(placesToShow.length, (index) {
                final place = placesToShow[index];
                final selected = controller.isSavedPlaceSelectedAsPickup(
                  place.id,
                );
                return InkWell(
                  onTap: () {
                    if (controller.isSavedPlacesExpanded.value) {
                      controller.selectSavedPlaceAsPickup(place);
                    } else {
                      controller.toggleAddressHeaderExpansion();
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: index == placesToShow.length - 1 ? 0 : 12.h,
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 4.h,
                        horizontal: 4.w,
                      ),
                      decoration: BoxDecoration(
                        color:
                            selected && controller.isSavedPlacesExpanded.value
                            ? AppColors.primaryLight.withOpacity(0.35)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color:
                              selected && controller.isSavedPlacesExpanded.value
                              ? AppColors.primary
                              : Colors.transparent,
                          width:
                              selected && controller.isSavedPlacesExpanded.value
                              ? 1
                              : 0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: AppColors.primary,
                              size: 20.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      place.label ?? 'Place',
                                      style: AppTextStyles.homeSubtitle
                                          .copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.shade1,
                                          ),
                                    ),
                                    if (index == 0) ...[
                                      SizedBox(width: 4.w),
                                      AnimatedRotation(
                                        duration: const Duration(
                                          milliseconds: 280,
                                        ),
                                        curve: Curves.easeInOutCubic,
                                        turns: controller
                                            .addressHeaderChevronTurns,
                                        child: Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 18.sp,
                                          color: AppColors.shade2,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  place.address ??
                                      place.name ??
                                      'No address provided',
                                  style: AppTextStyles.homeCaption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFigmaDraggableSheet() {
    return DraggableScrollableSheet(
      initialChildSize: _homeSheetInitialSize,
      minChildSize: _homeSheetInitialSize,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
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
          child: Obx(
            () => ListView(
              controller: scrollController,
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              children: [
                SizedBox(height: 12.h),
                Center(
                  child: Container(
                    width: 48.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(37.r),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Where to?',
                  style: AppTextStyles.homeTitle.copyWith(fontSize: 20.sp),
                ),
                SizedBox(height: 16.h),
                GestureDetector(
                  onTap: () => controller.openLocationSelection(),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 24.sp,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Where are you going?',
                          style: AppTextStyles.homeSubtitle,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                // Quick Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFigmaChip('Home', AppAssets.icHomeChip),
                      _buildFigmaChip('Work', AppAssets.icWorkChip),
                      _buildFigmaChip('Other', AppAssets.icOtherChip),
                    ],
                  ),
                ),
                if (controller.shouldShowRecentSection) ...[
                  SizedBox(height: 28.h),
                  Text(
                    'Recent Location',
                    style: AppTextStyles.homeSubtitle.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  if (controller.isLoadingHomeData.value)
                    ...List.generate(3, (_) => _buildRecentLocationSkeleton())
                  else
                    ...controller.recentDestinations.map(
                      (loc) => _buildRecentLocationItem(loc),
                    ),
                ],
                if (controller.shouldShowVehicleSection) ...[
                  if (controller.shouldShowRecentSection)
                    SizedBox(height: 24.h),
                  if (!controller.shouldShowRecentSection)
                    SizedBox(height: 28.h),
                  Text(
                    'Explore Vehicle',
                    style: AppTextStyles.homeSubtitle.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildVehicleHorizontalList(),
                ],
                if (controller.savedPlaces.isNotEmpty) ...[
                  SizedBox(height: 28.h),
                  Text(
                    'Saved Places',
                    style: AppTextStyles.homeSubtitle.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ...controller.savedPlaces.map(
                    (place) => _buildSavedPlaceItem(place),
                  ),
                ],
                SizedBox(height: 40.h),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFigmaChip(String label, String iconPath) {
    return Obx(() {
      final savedPlace = controller.savedPlaces.firstWhereOrNull(
        (p) => p.label?.toLowerCase() == label.toLowerCase(),
      );
      final isSaved = savedPlace != null;

      return GestureDetector(
        onTap: () {
          if (isSaved) {
            // For now, if saved, navigate to the selection flow or handle as per ride logic
            // The original logic was: controller.navigateToVehicleSelectionForSavedLabel(label)
            controller.navigateToVehicleSelectionForSavedLabel(label);
          } else {
            Get.toNamed(AppRoutes.selectSavedLocation, arguments: label);
          }
        },
        onLongPress: isSaved
            ? () => Get.toNamed(AppRoutes.selectSavedLocation, arguments: label)
            : null,
        child: Container(
          margin: EdgeInsets.only(right: 12.w),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: isSaved ? const Color(0xFFFEF3C7) : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: isSaved
                    ? Icon(
                        label.toLowerCase() == 'home'
                            ? Icons.home_rounded
                            : label.toLowerCase() == 'work'
                            ? Icons.work_rounded
                            : Icons.bookmark_rounded,
                        color: const Color(0xFFB45309),
                        size: 14.sp,
                      )
                    : Icon(Icons.add, color: Colors.white, size: 14.sp),
              ),
              SizedBox(width: 8.w),
              Text(
                label,
                style: AppTextStyles.homeChip.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.shade1,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSavedPlaceItem(SavedPlace place) {
    final label =
        (place.label ?? 'Saved Place').capitalizeFirst ?? 'Saved Place';
    final isFavorite = place.isFavourite ?? false;

    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: InkWell(
        onTap: () => controller.navigateToVehicleSelectionForSavedPlace(place),
        borderRadius: BorderRadius.circular(12.r),
        child: Row(
          children: [
            Obx(() {
              final distance = controller.calculateDistanceKm(
                place.lat,
                place.lng,
              );
              return Container(
                constraints: BoxConstraints(minWidth: 52.w),
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 20.sp,
                      color: AppColors.shade2,
                    ),
                    SizedBox(height: 4.h),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        distance.isEmpty ? 'SAVED' : distance,
                        style: AppTextStyles.homeCaption.copyWith(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.shade2,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.homeSubtitle.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.shade1,
                      fontSize: 15.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    place.address ?? 'No address',
                    style: AppTextStyles.homeCaption.copyWith(
                      color: AppColors.shade2,
                      fontSize: 13.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () =>
                  controller.toggleFavorite(place.address ?? '', null),
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? AppColors.primary : const Color(0xFFE2E8F0),
                size: 24.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLocationItem(RecentDestinationModel loc) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: InkWell(
        onTap: () =>
            controller.navigateToVehicleSelectionForRecentDestination(loc),
        borderRadius: BorderRadius.circular(12.r),
        child: Row(
          children: [
            // Distance Badge
            Obx(() {
              final distance = controller.calculateDistanceKm(loc.lat, loc.lng);
              return Container(
                constraints: BoxConstraints(minWidth: 52.w),
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_car_outlined,
                      size: 20.sp,
                      color: AppColors.shade2,
                    ),
                    SizedBox(height: 4.h),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        distance.isEmpty ? 'SAVED' : distance,
                        style: AppTextStyles.homeCaption.copyWith(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.recentDestinationTitleLine(loc),
                    style: AppTextStyles.homeSubtitle.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.shade1,
                      fontSize: 15.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    loc.address,
                    style: AppTextStyles.homeCaption.copyWith(
                      color: AppColors.shade2,
                      fontSize: 13.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Obx(() {
              final savedPlace = controller.getSavedPlaceFor(loc.address, null);
              final isFavorite = savedPlace?.isFavourite ?? false;
              return IconButton(
                onPressed: () => controller.toggleFavorite(loc.address, null),
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite
                      ? AppColors.primary
                      : const Color(0xFFE2E8F0),
                  size: 24.sp,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLocationSkeleton() {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Row(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
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
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  height: 12.h,
                  width: 200.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
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
              width: 86.w,
              height: 72.h,
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.directions_car,
                  color: AppColors.shade2,
                  size: 28.sp,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              vehicle.displayName,
              style: AppTextStyles.homeCaption.copyWith(
                color: AppColors.shade1,
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
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            width: 56.w,
            height: 10.h,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeRideCard(RideModel ride) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: controller.openActiveRide,
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
                      color: const Color(0xFFFCE7F3),
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
                    ride.vehicleSnapshot?.vehicleType ?? ride.vehicleTypeId,
                    style: AppTextStyles.homeCaption.copyWith(
                      color: AppColors.shade1,
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
                  color: AppColors.shade1,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                ride.destination.address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.homeCaption.copyWith(
                  color: AppColors.shade2,
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Text(
                    'TZS ${ride.fareEstimate}',
                    style: AppTextStyles.homeSubtitle.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.shade1,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'View trip',
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
}
