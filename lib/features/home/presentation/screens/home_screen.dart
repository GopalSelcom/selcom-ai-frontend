import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/data/models/ride_model.dart';
import '../../../../core/data/models/vehicle_type_model.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_draggable_bottom_sheet.dart';
import '../../../../shared/widgets/app_google_map.dart';
import '../../../../shared/widgets/app_map_gps_button.dart';
import '../../../../shared/widgets/app_map_top_header.dart';
import '../../../../shared/widgets/favorite_location_chips_row.dart';
import '../../../ride/data/models/ride_management_models.dart';
import '../controllers/home_controller.dart';
import '../widgets/recent_location_tile.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    controller.onHomeVisible();
    final screenHeight = MediaQuery.sizeOf(context).height;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitDialog(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        resizeToAvoidBottomInset: false,
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
                    bottom: screenHeight * controller.sheetSize.value,
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

            // 3. GPS button — lifts with the draggable bottom sheet.
            Obx(() {
              if (controller.isLoadingHomeData.value) {
                return const SizedBox.shrink();
              }
              final activeRide = controller.activeRide.value;
              final bottomOffset = activeRide != null
                  ? MediaQuery.paddingOf(context).bottom + 12.h + 120.h
                  : screenHeight * controller.sheetSize.value;
              return Positioned(
                bottom: bottomOffset,
                right: 20.w,
                child: AppMapGpsButton(
                  onPressed: () => controller.recenterMap(),
                ),
              );
            }),
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
              return _buildFigmaDraggableSheet(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAddressBox() {
    return Expanded(
      child: Obx(() {
        final bool isLoading = controller.isLoadingHomeData.value;
        final String address = controller.currentMapAddress.value;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOutCubic,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.borderDefault),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.06),
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
                    SizedBox(
                      width: 28.w,
                      height: 28.w,
                      child: SvgPictureAsset(
                        AppAssets.locationIcPickupPin,
                        width: 21.sp,
                        height: 24.5.sp,
                        color: AppColors.figmaIconGreen,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppStrings.currentLocation.tr,
                            style: AppTextStyles.homeSubtitle.copyWith(
                              color: AppColors.figmaTextPrimary,
                              height: 20 / 15,
                            ),
                          ),
                          Text(
                            address,
                            style: AppTextStyles.homeSubtitle.copyWith(
                              color: AppColors.figmaTextSecondary,
                              height: 20 / 15,
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

  static const double _sheetHorizontalPadding = 24;

  Widget _buildFigmaDraggableSheet(BuildContext context) {
    return Obx(() {
      controller.recentDestinations.length;
      controller.vehicleTypes.length;
      controller.savedPlaces.length;
      controller.isLoadingHomeData.value;
      controller.measuredSheetContentHeightPx.value;

      final minSize = controller.homeSheetMinSize;
      final initialSize = controller.homeSheetInitialSize;
      final maxSize = controller.homeSheetMaxChildSize;
      final snapSizes = controller.homeSheetSnapSizes;
      final scrollPhysics = controller.homeSheetScrollPhysics;
      final contentSignature = Object.hash(
        controller.recentDestinations.length,
        controller.vehicleTypes.length,
        controller.savedPlaces.length,
        controller.shouldShowRecentSection,
        controller.shouldShowVehicleSection,
      );

      return AppDraggableBottomSheet(
        controller: controller.homeSheetController,
        initialChildSize: initialSize,
        minChildSize: minSize,
        maxChildSize: maxSize > minSize ? maxSize : minSize + 0.01,
        snap: controller.homeSheetShouldSnap,
        snapSizes: snapSizes,
        childBuilder: (scrollController) {
          return _HomeSheetScrollContent(
            key: ValueKey<int>(contentSignature),
            scrollController: scrollController,
            physics: scrollPhysics,
            contentSignature: contentSignature,
            onContentMeasured: controller.reportHomeSheetContentHeight,
            children: _buildHomeSheetContentChildren(),
          );
        },
      );
    });
  }

  List<Widget> _buildHomeSheetContentChildren() {
    return [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: _sheetHorizontalPadding.w),
        child: Column(
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
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.skeletonBase, width: 0.8),
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
                        fontSize: 15.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 8.h),
      Obx(() {
        controller.savedPlaces.length;
        final extras = controller.savedPlacesBeyondPresetSlots;
        return FavoriteLocationChipsRow(
          contentHorizontalPadding: _sheetHorizontalPadding.w,
          chipBackgroundColor: AppColors.surfaceSubtle,
          chipBorderColor: AppColors.borderWalletCard,
          resolvePlace: controller.getSavedPlaceByLabel,
          extraSavedPlaces: extras,
          onChipTap: (canonical, place) {
            if (place == null) {
              Get.toNamed(AppRoutes.selectSavedLocation, arguments: canonical);
            } else {
              controller.navigateToVehicleSelectionForSavedLabel(canonical);
            }
          },
          onSavedChipLongPress: (canonical) =>
              Get.toNamed(AppRoutes.selectSavedLocation, arguments: canonical),
          onExtraChipTap: (place) =>
              controller.navigateToVehicleSelectionForSavedPlace(place),
          onExtraChipLongPress: (place) {
            final raw = (place.label ?? place.name ?? '').trim();
            Get.toNamed(
              AppRoutes.selectSavedLocation,
              arguments: raw.isEmpty ? AppStrings.saved.tr : raw,
            );
          },
        );
      }),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: _sheetHorizontalPadding.w),
        child: Obx(() {
          const sectionGap = 12.0;
          const titleContentGap = 10.0;
          const recentItemGap = 12.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (controller.shouldShowRecentSection) ...[
                SizedBox(height: sectionGap.h),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.recentLocation.tr,
                        style: _sectionTitleStyle,
                      ),
                    ),
                    if (controller.canViewMoreRecentLocations)
                      _viewMoreButton(
                        onPressed: controller.openRecentLocationsScreen,
                      ),
                  ],
                ),
                SizedBox(height: titleContentGap.h),
                ..._buildRecentLocationListItems(itemGap: recentItemGap.h),
              ],
              if (controller.shouldShowVehicleSection) ...[
                SizedBox(height: sectionGap.h),
                Text(AppStrings.exploreVehicle.tr, style: _sectionTitleStyle),
                SizedBox(height: titleContentGap.h),
                _buildVehicleHorizontalList(),
              ],
            ],
          );
        }),
      ),
    ];
  }

  TextStyle get _sectionTitleStyle => AppTextStyles.homeSubtitle.copyWith(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    color: AppColors.textHeading,
  );

  Widget _viewMoreButton({required VoidCallback onPressed}) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        AppStrings.viewMore.tr,
        style: AppTextStyles.homeSubtitle.copyWith(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.primary,
          decorationThickness: 1,
          height: 18 / 14,
        ),
      ),
    );
  }

  List<Widget> _buildRecentLocationListItems({required double itemGap}) {
    if (controller.isLoadingHomeData.value) {
      return List.generate(3, (index) {
        final isLast = index == 2;
        return Column(
          children: [
            _buildRecentLocationSkeleton(),
            if (!isLast) ...[
              SizedBox(height: itemGap),
              Divider(height: 1.h, color: AppColors.bgSoftCircle),
              SizedBox(height: itemGap),
            ],
          ],
        );
      });
    }

    final items = controller.recentDestinationsPreview;
    final widgets = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      widgets.add(_buildRecentLocationItem(items[i]));
      if (i < items.length - 1) {
        widgets.addAll([
          SizedBox(height: itemGap),
          Divider(height: 1.h, color: AppColors.bgSoftCircle),
          SizedBox(height: itemGap),
        ]);
      }
    }
    return widgets;
  }

  Widget _buildRecentLocationItem(RecentDestinationModel loc) {
    return Obx(() {
      final distance = controller.calculateDistanceKm(loc.lat, loc.lng);
      final savedPlace = controller.getSavedPlaceFor(loc.address, null);
      final isFavorite = savedPlace?.isFavourite ?? false;
      return RecentLocationTile(
        title: controller.recentDestinationTitleLine(loc),
        address: loc.address,
        distance: distance,
        isFavorite: isFavorite,
        onTap: () => controller.navigateToVehicleSelectionForRecentDestination(
          loc,
          showHomeFareEstimateLoader: true,
        ),
        onFavoriteTap: () => controller.toggleFavoriteForRecent(loc),
      );
    });
  }

  Widget _buildRecentLocationSkeleton() {
    return Row(
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
    );
  }

  /// Image (42) + gap (4) + label + descender padding — fixed row height for the sheet.
  static const double _vehicleRowHeight = 72;

  Widget _buildVehicleHorizontalList() {
    return Obx(
      () => SizedBox(
        height: _vehicleRowHeight.h,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: controller.isLoadingHomeData.value
                ? List.generate(3, (_) => _buildVehicleSkeleton())
                : controller.vehicleTypes
                      .map((vehicle) => _buildVehicleCard(vehicle))
                      .toList(),
          ),
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
        margin: EdgeInsets.only(right: 29.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 62.w,
              height: 42.h,
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
            SizedBox(height: 4.h),
            Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Text(
                vehicle.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.homeCaption.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.textHeading,
                  fontWeight: FontWeight.w400,
                  height: 1.25,
                ),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62.w,
            height: 42.h,
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.skeletonBase,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Container(
            width: 52.w,
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
                        : AppStrings.fallbackRideName.tr,
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
        return AppStrings.driverAssigned.tr;
      case 'driverarriving':
        return AppStrings.driverArriving.tr;
      case 'driverarrived':
        return AppStrings.driverArrived.tr;
      case 'ridestarted':
      case 'rideinprogress':
        return AppStrings.rideInProgress.tr;
      case 'neardestination':
        return AppStrings.nearDestination.tr;
      default:
        return AppStrings.activeRide.tr;
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

/// Measures real content height and reports it so the sheet max matches layout.
class _HomeSheetScrollContent extends StatefulWidget {
  const _HomeSheetScrollContent({
    super.key,
    required this.scrollController,
    required this.physics,
    required this.contentSignature,
    required this.onContentMeasured,
    required this.children,
  });

  final ScrollController scrollController;
  final ScrollPhysics physics;
  final int contentSignature;
  final void Function({
    required double contentHeightPx,
    required double layoutHeightPx,
  })
  onContentMeasured;
  final List<Widget> children;

  @override
  State<_HomeSheetScrollContent> createState() =>
      _HomeSheetScrollContentState();
}

class _HomeSheetScrollContentState extends State<_HomeSheetScrollContent> {
  final GlobalKey _contentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scheduleMeasure();
  }

  @override
  void didUpdateWidget(covariant _HomeSheetScrollContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contentSignature != widget.contentSignature) {
      _scheduleMeasure();
    }
  }

  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureNow();
      // Nested Obx sections may lay out on a later frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureNow());
    });
  }

  void _measureNow() {
    final contentContext = _contentKey.currentContext;
    final renderBox = contentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize || contentContext == null) {
      return;
    }
    final layoutHeight = MediaQuery.sizeOf(contentContext).height;
    widget.onContentMeasured(
      contentHeightPx: renderBox.size.height,
      layoutHeightPx: layoutHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      physics: widget.physics,
      primary: false,
      clipBehavior: Clip.hardEdge,
      child: NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (_) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _measureNow());
          return false;
        },
        child: SizeChangedLayoutNotifier(
          child: Column(
            key: _contentKey,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: widget.children,
          ),
        ),
      ),
    );
  }
}
