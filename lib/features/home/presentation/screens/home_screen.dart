import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/data/models/vehicle_type_model.dart';
import '../../../ride/data/models/ride_management_models.dart';
import '../controllers/home_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_map_gps_button.dart';
import '../../../../shared/widgets/app_map_top_header.dart';
import '../../../../core/data/models/responses/get_saved_places_response.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  HomeController get controller => Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Stack(
        children: [
          // 1. Map Layer (Static Image from Figma)
          Positioned.fill(
            child: Obx(
              () => GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: controller.mapCenter.value,
                  zoom: 16,
                ),
                myLocationEnabled: controller.hasLocationPermission.value,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
                circles: controller.nearbyPickupRadiusCircles,
                markers: controller.selectedPickupMarkers,
                onMapCreated: controller.onMapCreated,
                padding: EdgeInsets.only(bottom: 245.h),
                onCameraMove: controller.onCameraMove,
                onCameraIdle: controller.onCameraIdle,
              ),
            ),
          ),

          // 2. Top Header (Address + Profile)
          AppMapTopHeader(
            top: MediaQuery.of(context).padding.top + 10.h,
            addressWidget: _buildModernAddressBox(),
            onProfileTap: controller.openProfile,
            profileIcon: Icons.person,
            profileIconColor: Colors.black,
          ),

          // 3. Floating Action Buttons (GPS)
          Positioned(
            bottom: 370.h, // Adjusted based on initial bottom sheet height
            right: 20.w,
            child: AppMapGpsButton(onPressed: () => controller.recenterMap()),
          ),

          // 4. Interactive Bottom UI
          _buildFigmaDraggableSheet(),
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
              height: 66.h,
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
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
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

        return AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          clipBehavior: Clip.hardEdge,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
            padding: EdgeInsets.all(12.w),
            // Removed constraints from AnimatedContainer to avoid interpolation crash.
            // Using BoxConstraints on the child or simply relying on content + padding.
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
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 42.h,
              ), // 66.h total padding subtracted: 12.w * 2 ≈ 24. 66-24=42.
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
                                selected &&
                                    controller.isSavedPlacesExpanded.value
                                ? AppColors.primary
                                : Colors.transparent,
                            width:
                                selected &&
                                    controller.isSavedPlacesExpanded.value
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
          ),
        );
      }),
    );
  }

  Widget _buildFigmaDraggableSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.45,
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
                      _buildFigmaChip('Office', AppAssets.icOfficeChip),
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
    final subtitle = controller.chipSubtitleFor(label);
    return GestureDetector(
      onTap: () => controller.navigateToVehicleSelectionForSavedLabel(label),
      child: Container(
        margin: EdgeInsets.only(right: 12.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(iconPath, width: 20.w, height: 20.w),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTextStyles.homeChip.copyWith(fontSize: 14.sp),
                ),
                if (subtitle != null && subtitle.trim().isNotEmpty)
                  SizedBox(
                    width: 120.w,
                    child: Text(
                      subtitle,
                      style: AppTextStyles.homeCaption.copyWith(
                        fontSize: 11.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
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
                        distance.isEmpty ? '-- KM' : distance,
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
                        distance.isEmpty ? '-- KM' : distance,
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
}
