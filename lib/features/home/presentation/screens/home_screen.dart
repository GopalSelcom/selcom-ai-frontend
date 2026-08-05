import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/data/models/responses/rides/vehicle_types_response.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_route_observer.dart';
import '../../../../core/services/app_map_type_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/widgets/app_cupertino_text_button.dart';
import '../../../../shared/widgets/app_draggable_bottom_sheet.dart';
import '../../../../shared/widgets/app_google_map.dart';
import '../../../../shared/widgets/app_map_gps_button.dart';
import '../../../../shared/widgets/app_map_layer_button.dart';
import '../../../../shared/widgets/app_map_top_header.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../../../shared/widgets/app_vehicle_explore_tile.dart';
import '../../../../shared/widgets/favorite_location_chips_row.dart';
import '../../../ride/data/models/recent_destinations_response.dart';
import '../controllers/home_controller.dart';
import '../widgets/home_active_ride_card.dart';
import '../widgets/home_active_rides_panel.dart';
import '../widgets/home_address_header_skeleton.dart';
import '../widgets/home_sheet_layout.dart';
import '../widgets/home_sheet_loading_content.dart';
import '../widgets/recent_location_tile.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final mapTypeService = di.sl<AppMapTypeService>();
    return _HomeRouteVisibility(
      onVisible: controller.onHomeVisible,
      child: PopScope(
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
              // 1. Map — deferred mount; sheet padding updates are throttled and
              // kept out of the GetX Obx that also tracks GPS/permission.
              Positioned.fill(
                child: _HomeMapHost(
                  screenHeight: screenHeight,
                  controller: controller,
                ),
              ),

              // 2. Top Header (Address + Profile)
              Obx(
                () => AppMapTopHeader(
                  top: MediaQuery.of(context).padding.top + 10.h,
                  addressWidget: _buildModernAddressBox(),
                  onProfileTap: controller.openProfile,
                  profileImageUrl: controller.profileImageUrl.value.isEmpty
                      ? null
                      : controller.profileImageUrl.value,
                  isLoading: controller.isLoadingHomeData.value,
                  isExpanded: controller.isSavedPlacesExpanded.value,
                ),
              ),

              // 3. GPS button — lifts with the draggable bottom sheet / active ride card.
              Obx(() {
                if (controller.isLoadingHomeData.value ||
                    controller.isActiveRidesExpanded.value) {
                  return const SizedBox.shrink();
                }
                final activeRide = controller.activeRide.value;
                final sheetBottom = screenHeight * controller.sheetSize.value;
                final bottomOffset = activeRide == null
                    ? sheetBottom + 12.h
                    : HomeActiveRideCard.gpsButtonBottom(
                        sheetBottomFromScreenBottom: sheetBottom,
                      );
                return Positioned(
                  bottom: bottomOffset,
                  right: 20.w,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Satellite toggle shares session state via AppMapTypeService.
                      Obx(
                        () => AppMapLayerButton(
                          isSatelliteView: mapTypeService.isSatelliteView,
                          onPressed: mapTypeService.toggleMapType,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      AppMapGpsButton(
                        onPressed: () => controller.recenterMap(),
                      ),
                    ],
                  ),
                );
              }),
              _buildFigmaDraggableSheet(context),
              Obx(() {
                if (controller.isLoadingHomeData.value) {
                  return const SizedBox.shrink();
                }
                final activeRide = controller.activeRide.value;
                if (activeRide == null) return const SizedBox.shrink();

                final rides = controller.activeRides.toList(growable: false);
                final sheetBottom = screenHeight * controller.sheetSize.value;
                final cardBottom =
                    sheetBottom + HomeActiveRideCard.gapAboveSheet.h;

                if (!controller.hasMultipleActiveRides) {
                  return Positioned(
                    left: 16.w,
                    right: 16.w,
                    bottom: cardBottom,
                    child: HomeActiveRideCard(
                      vehicleAssetPath: controller.activeRideVehicleImageAsset(
                        activeRide,
                      ),
                      routeTitle: controller.activeRideRouteTitle(activeRide),
                      remainingLabel: controller.activeRideRemainingLabel(
                        activeRide,
                      ),
                      additionalRidesCount: 0,
                      onViewRide: controller.openActiveRide,
                    ),
                  );
                }

                final isExpanded = controller.isActiveRidesExpanded.value;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: HomeActiveRidesBlurBarrier(
                        isExpanded: isExpanded,
                        onClose: controller.collapseActiveRidesStack,
                      ),
                    ),
                    Positioned(
                      left: 16.w,
                      right: 16.w,
                      bottom: cardBottom,
                      child: HomeActiveRidesPanel(
                        isExpanded: isExpanded,
                        rides: rides,
                        additionalRidesCount:
                            controller.additionalActiveRidesCount,
                        onExpand: controller.expandActiveRidesStack,
                        onCollapse: controller.collapseActiveRidesStack,
                        vehicleAssetPathFor:
                            controller.activeRideVehicleImageAsset,
                        routeTitleFor: controller.activeRideRouteTitle,
                        remainingLabelFor: controller.activeRideRemainingLabel,
                        onViewRide: controller.openActiveRide,
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernAddressBox() {
    return Expanded(
      child: Obx(() {
        final bool isLoading = controller.isLoadingHomeData.value;
        final String address = controller.currentMapAddress.value;

        return GestureDetector(
          onTap: () => controller.recenterMap(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
            constraints: BoxConstraints(minHeight: 64.w),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.06),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: isLoading
                ? const HomeAddressHeaderSkeleton()
                : Row(
                    children: [
                      SizedBox(
                        width: 28.w,
                        height: 28.w,
                        child: SvgPictureAsset(
                          AppAssets.locationIcPickupPin,
                          width: 21.sp,
                          height: 24.5.sp,
                          color: AppColors.primary,
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

  static const double _sheetHorizontalPadding =
      HomeSheetLayout.horizontalPadding;

  Widget _buildFigmaDraggableSheet(BuildContext context) {
    return Obx(() {
      final isLoading = controller.isLoadingHomeData.value;

      // While bootstrapping, only subscribe to the loading flag so parallel
      // list assignAlls do not rebuild the sheet (and measure) repeatedly.
      if (!isLoading) {
        controller.recentDestinations.length;
        controller.vehicleTypes.length;
        controller.savedPlaces.length;
        controller.measuredSheetContentHeightPx.value;
      }

      final minSize = controller.homeSheetMinSize;
      final initialSize = controller.homeSheetInitialSize;
      final maxSize = controller.homeSheetMaxChildSize;
      final snapSizes = controller.homeSheetSnapSizes;
      final scrollPhysics = controller.homeSheetScrollPhysics;
      final contentSignature = isLoading
          ? Object.hash(true, 0)
          : Object.hash(
              false,
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
          final children = isLoading
              ? HomeSheetLoadingContent.buildChildren(
                  horizontalPadding: _sheetHorizontalPadding,
                )
              : _buildHomeSheetContentChildren();
          return AbsorbPointer(
            absorbing: isLoading,
            child: _HomeSheetScrollContent(
              key: ValueKey<int>(contentSignature),
              scrollController: scrollController,
              physics: scrollPhysics,
              contentSignature: contentSignature,
              onContentMeasured: controller.reportHomeSheetContentHeight,
              children: children,
            ),
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
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColors.borderWalletCard,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    SvgPictureAsset(
                      AppAssets.locationIcDestinationPin,
                      color: AppColors.secondary,
                      width: 19.sp,
                      height: 19.sp,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      AppStrings.whereAreYouGoing.tr,
                      style: AppTextStyles.homeSubtitle.copyWith(
                        color: AppColors.figmaTextPrimary,
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
        controller.recentHomeChipKey.value;
        final extras = controller.savedPlacesBeyondPresetSlots;
        return FavoriteLocationChipsRow(
          contentHorizontalPadding: _sheetHorizontalPadding.w,
          chipBackgroundColor: AppColors.surfaceSubtle,
          highlightedChipKey: controller.recentHomeChipKey.value,
          resolvePlace: controller.getSavedPlaceByLabel,
          extraSavedPlaces: extras,
          onChipTap: controller.onHomePresetChipTap,
          onSavedChipLongPress: controller.onHomePresetChipLongPress,
          onExtraChipTap: controller.onHomeExtraChipTap,
          onExtraChipLongPress: controller.onHomeExtraChipLongPress,
        );
      }),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: _sheetHorizontalPadding.w),
        child: Obx(() {
          const sectionGap = HomeSheetLayout.sectionGap;
          const titleContentGap = HomeSheetLayout.titleContentGap;
          const recentItemGap = HomeSheetLayout.recentItemGap;

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
    color: AppColors.figmaTextPrimary,
  );

  Widget _viewMoreButton({required VoidCallback onPressed}) {
    return AppCupertinoTextButton.viewMore(
      label: AppStrings.viewMore.tr,
      onPressed: onPressed,
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

  Widget _buildRecentLocationSkeleton() {
    return AppShimmer(
      child: Row(
        children: [
          AppShimmerBox(width: 52.w, height: 52.w, borderRadius: 12.r),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmerBox(height: 14.h, width: 130.w, borderRadius: 8.r),
                SizedBox(height: 8.h),
                AppShimmerBox(height: 12.h, width: 200.w, borderRadius: 8.r),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentLocationItem(RecentDestination loc) {
    return Obx(() {
      final distance = controller.calculateDistanceKm(loc.lat, loc.lng);
      final savedPlace = controller.getSavedPlaceFor(loc.address ?? '', null);
      final isFavorite = savedPlace?.isFavourite ?? false;
      return RecentLocationTile(
        title: controller.recentDestinationTitleLine(loc),
        address: loc.address ?? '',
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

  Widget _buildVehicleHorizontalList() {
    return Obx(
      () => SizedBox(
        height: HomeSheetLayout.vehicleRowHeight.h,
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

  Widget _buildVehicleSkeleton() {
    return AppShimmer(
      child: Container(
        margin: EdgeInsets.only(right: 16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppShimmerBox(width: 62.w, height: 42.h, borderRadius: 16.r),
            SizedBox(height: 4.h),
            AppShimmerBox(width: 52.w, height: 10.h, borderRadius: 8.r),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(VehicleType vehicle) {
    final imagePath = controller.vehicleExploreImageAsset(vehicle.name ?? '');

    return GestureDetector(
      onTap: () =>
          controller.openLocationSelectionWithPreferredVehicle(vehicle),
      child: Container(
        margin: EdgeInsets.only(right: 29.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppVehicleExploreTile(assetPath: imagePath),
            SizedBox(height: 4.h),
            Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Text(
                vehicle.displayName ?? vehicle.name ?? '',
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

/// Hosts the home [AppGoogleMap] with:
/// - deferred platform-view mount (lets chrome paint first)
/// - sheet padding driven by [DraggableScrollableController] (throttled),
///   not by an Obx on [HomeController.sheetSize]
class _HomeMapHost extends StatefulWidget {
  const _HomeMapHost({
    required this.screenHeight,
    required this.controller,
  });

  final double screenHeight;
  final HomeController controller;

  static const LatLng _defaultMapTarget = LatLng(-6.7924, 39.2083);

  @override
  State<_HomeMapHost> createState() => _HomeMapHostState();
}

class _HomeMapHostState extends State<_HomeMapHost> {
  static const Duration _paddingThrottle = Duration(milliseconds: 120);
  /// Circles / padding stay off longer so tile load is not stacked with overlays.
  static const Duration _circlesDelay = Duration(milliseconds: 2500);
  static const Duration _paddingFreezeAfterMount = Duration(milliseconds: 2800);

  bool _mapAllowed = false;
  bool _circlesAllowed = false;
  bool _hasPermission = false;
  double _activeRideFootprint = 0;
  Set<Circle> _circles = const {};
  double _sheetFraction = HomeController.homeSheetCollapsedPeekMin;
  Timer? _paddingThrottleTimer;
  Timer? _circlesTimer;
  Timer? _paddingFreezeTimer;
  DateTime? _paddingFrozenUntil;
  double? _pendingSheetFraction;
  final List<Worker> _workers = <Worker>[];

  @override
  void initState() {
    super.initState();
    final c = widget.controller;
    _sheetFraction = c.sheetSize.value;
    _hasPermission = c.hasLocationPermission.value;
    _activeRideFootprint = _footprintFor(c);
    c.homeSheetController.addListener(_onSheetChanged);

    if (c.homeMapSurfaceReady.value) {
      _allowMap();
    } else {
      // Safety: if RouteAware/bootstrap race left the gate closed, open next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.controller.homeMapSurfaceReady.value) {
          _allowMap();
        } else {
          widget.controller.ensureHomeMapSurfaceOpen();
        }
      });
    }
    _workers.add(
      ever(c.homeMapSurfaceReady, (ready) {
        if (!mounted) return;
        if (ready == true) {
          if (_mapAllowed) {
            // Remount after ride return / dead platform view.
            setState(() {
              _mapAllowed = false;
              _circlesAllowed = false;
              _hasPermission = false;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _allowMap();
            });
          } else {
            _allowMap();
          }
        } else if (_mapAllowed) {
          setState(() {
            _mapAllowed = false;
            _circlesAllowed = false;
            _hasPermission = false;
          });
        }
      }),
    );
    _workers.add(
      ever(c.hasLocationPermission, (granted) {
        if (!mounted || granted == _hasPermission) return;
        // Avoid toggling myLocation during settle (reconfigures platform map).
        if (_isPaddingFrozen) {
          _hasPermission = granted;
          return;
        }
        setState(() {
          _hasPermission = granted;
          if (_circlesAllowed) {
            _circles = c.nearbyPickupRadiusCircles;
          }
        });
      }),
    );
    _workers.add(
      ever(c.deviceGpsLocation, (_) {
        if (!mounted || !_circlesAllowed) return;
        final next = c.nearbyPickupRadiusCircles;
        if (identical(next, _circles)) return;
        setState(() => _circles = next);
      }),
    );
    _workers.add(
      ever(c.activeRide, (_) {
        if (!mounted) return;
        final next = _footprintFor(c);
        if ((next - _activeRideFootprint).abs() < 0.5) return;
        if (_isPaddingFrozen) {
          _activeRideFootprint = next;
          return;
        }
        setState(() => _activeRideFootprint = next);
      }),
    );
    _workers.add(
      ever(c.activeRides, (_) {
        if (!mounted) return;
        final next = _footprintFor(c);
        if ((next - _activeRideFootprint).abs() < 0.5) return;
        if (_isPaddingFrozen) {
          _activeRideFootprint = next;
          return;
        }
        setState(() => _activeRideFootprint = next);
      }),
    );
  }

  bool get _isPaddingFrozen {
    final until = _paddingFrozenUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  double _footprintFor(HomeController c) {
    final activeRide = c.activeRide.value;
    if (activeRide == null) return 0;
    return HomeActiveRideCard.footprintAboveSheet(
      showsMoreBadge: c.hasMultipleActiveRides,
    );
  }

  void _allowMap() {
    if (!mounted || _mapAllowed) return;
    final sheet = widget.controller.homeSheetController;
    setState(() {
      _mapAllowed = true;
      if (sheet.isAttached) {
        _sheetFraction = sheet.size;
      }
      // Keep myLocation off during quiet window — enabling it at create
      // reconfigures the platform map while tiles are still loading.
      _hasPermission = false;
    });
    _paddingFrozenUntil = DateTime.now().add(_paddingFreezeAfterMount);
    _paddingFreezeTimer?.cancel();
    _paddingFreezeTimer = Timer(_paddingFreezeAfterMount, () {
      if (!mounted) return;
      // One padding + location sync after quiet period.
      final attached = widget.controller.homeSheetController;
      final nextFraction = attached.isAttached
          ? attached.size
          : widget.controller.sheetSize.value;
      setState(() {
        _sheetFraction = nextFraction;
        _activeRideFootprint = _footprintFor(widget.controller);
        _hasPermission = widget.controller.hasLocationPermission.value;
        if (_circlesAllowed) {
          _circles = widget.controller.nearbyPickupRadiusCircles;
        }
      });
    });
    _circlesTimer?.cancel();
    _circlesTimer = Timer(_circlesDelay, () {
      if (!mounted) return;
      setState(() {
        _circlesAllowed = true;
        _circles = widget.controller.nearbyPickupRadiusCircles;
      });
    });
  }

  @override
  void dispose() {
    _paddingThrottleTimer?.cancel();
    _circlesTimer?.cancel();
    _paddingFreezeTimer?.cancel();
    for (final w in _workers) {
      w.dispose();
    }
    widget.controller.homeSheetController.removeListener(_onSheetChanged);
    super.dispose();
  }

  void _onSheetChanged() {
    final sheet = widget.controller.homeSheetController;
    if (!sheet.isAttached) return;
    if (Get.isDialogOpen ?? false) return;
    if (Get.isBottomSheetOpen ?? false) return;
    final next = sheet.size;
    if ((next - _sheetFraction).abs() < 0.005) return;
    _pendingSheetFraction = next;
    if (_isPaddingFrozen) return;
    if (_paddingThrottleTimer?.isActive ?? false) return;
    _paddingThrottleTimer = Timer(_paddingThrottle, _flushPadding);
  }

  void _flushPadding() {
    final next = _pendingSheetFraction;
    _pendingSheetFraction = null;
    if (next == null || !mounted) return;
    if ((next - _sheetFraction).abs() < 0.005) return;
    if (_isPaddingFrozen) return;
    setState(() => _sheetFraction = next);
  }

  @override
  Widget build(BuildContext context) {
    if (!_mapAllowed) {
      return const ColoredBox(color: AppColors.skeletonBase);
    }

    return RepaintBoundary(
      child: AppGoogleMap(
        key: ValueKey(
          'home_google_map_${widget.controller.homeMapMountGeneration.value}',
        ),
        layerTogglePlacement: AppMapLayerTogglePlacement.none,
        initialCameraPosition: const CameraPosition(
          target: _HomeMapHost._defaultMapTarget,
          zoom: 16,
        ),
        padding: EdgeInsets.only(
          bottom: widget.screenHeight * _sheetFraction + _activeRideFootprint,
        ),
        myLocationEnabled: _hasPermission,
        indoorViewEnabled: false,
        circles: _circlesAllowed ? _circles : const <Circle>{},
        onMapCreated: widget.controller.onMapCreated,
        onMapDisposed: widget.controller.onHomeMapDisposed,
        onCameraIdle: widget.controller.onHomeMapCameraIdle,
      ),
    );
  }
}

/// Reports Home visibility via [RouteAware] instead of calling from [build].
class _HomeRouteVisibility extends StatefulWidget {
  const _HomeRouteVisibility({required this.onVisible, required this.child});

  final VoidCallback onVisible;
  final Widget child;

  @override
  State<_HomeRouteVisibility> createState() => _HomeRouteVisibilityState();
}

class _HomeRouteVisibilityState extends State<_HomeRouteVisibility>
    with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() => widget.onVisible();

  @override
  void didPopNext() => widget.onVisible();

  @override
  Widget build(BuildContext context) => widget.child;
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
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    final double computedBottomPadding = bottomPadding > 0
        ? (GetPlatform.isIOS ? 0.0 : 8.h)
        : 16.h;

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
            children: [
              ...widget.children,
              SafeArea(
                top: false,
                bottom: true,
                child: SizedBox(height: computedBottomPadding),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
