import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../controllers/home_controller.dart';
import '../../data/models/places_models.dart';
import '../../../../core/routes/app_routes.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  late final HomeController controller;
  late final TextEditingController pickupController;
  late final TextEditingController destinationController;
  late final FocusNode pickupFocusNode;
  late final FocusNode destinationFocusNode;

  /// 0 = pickup, 1 = first destination, 2+ = extra stop at index `segment - 2`.
  final RxInt _activeSegmentIndex = 1.obs;
  final _extraDestinationControllers = <TextEditingController>[].obs;
  final _extraDestinationFocusNodes = <FocusNode>[].obs;
  final RxBool pickupEditedByUser = false.obs;

  /// Set when the first destination is chosen from autocomplete (required for `saved-places` on Book Ride).
  final RxnString _destinationPlaceId = RxnString();
  static const int _maxExtraStops = 2;

  /// From route args (home / explore vehicle); used for Book Ride pickup coords.
  final RxnDouble _routePickupLat = RxnDouble();
  final RxnDouble _routePickupLng = RxnDouble();

  /// Destination coordinates for first drop, when user picked a source that includes coords.
  final RxnDouble _routeDestinationLat = RxnDouble();
  final RxnDouble _routeDestinationLng = RxnDouble();

  /// Forwarded to vehicle selection as default vehicle.
  final RxnString _preferredVehicleTypeId = RxnString();
  final RxnString _preferredVehicleName = RxnString();

  @override
  void initState() {
    super.initState();
    controller = Get.find<HomeController>();
    final raw = Get.arguments;
    String initialPickup = controller.currentMapAddress.value;
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      final p = (m['pickup'] as String?)?.trim();
      if (p != null && p.isNotEmpty) {
        initialPickup = p;
        pickupEditedByUser.value = true;
      }
      final plat = (m['pickupLat'] as num?)?.toDouble();
      final plng = (m['pickupLng'] as num?)?.toDouble();
      if (plat != null && plng != null) {
        _routePickupLat.value = plat;
        _routePickupLng.value = plng;
      }
      _preferredVehicleTypeId.value = (m['preferredVehicleTypeId'] as String?)
          ?.trim();
      _preferredVehicleName.value = (m['preferredVehicleName'] as String?)
          ?.trim();
    }
    pickupController = TextEditingController(text: initialPickup);
    destinationController = TextEditingController();
    pickupFocusNode = FocusNode();
    destinationFocusNode = FocusNode();
    if (_routePickupLat.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.isPickupSelected.value = true;
      });
    }
  }

  @override
  void dispose() {
    pickupController.dispose();
    destinationController.dispose();
    for (final c in _extraDestinationControllers) {
      c.dispose();
    }
    for (final f in _extraDestinationFocusNodes) {
      f.dispose();
    }
    pickupFocusNode.dispose();
    destinationFocusNode.dispose();
    super.dispose();
  }

  void _onAddDestinationStop() {
    if (_extraDestinationControllers.length >= _maxExtraStops) return;
    _extraDestinationControllers.add(TextEditingController());
    _extraDestinationFocusNodes.add(FocusNode());
    _activeSegmentIndex.value = 2 + _extraDestinationControllers.length - 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_extraDestinationFocusNodes.isEmpty) return;
      final node = _extraDestinationFocusNodes.last;
      node.requestFocus();
      controller.searchQuery.value = _extraDestinationControllers.last.text
          .trim();
    });
  }

  void _setActiveSegment(int index) {
    if (_activeSegmentIndex.value == index) return;
    _activeSegmentIndex.value = index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Obx(() {
        final liveAddress = controller.currentMapAddress.value.trim();
        if (!pickupEditedByUser.value && liveAddress.isNotEmpty) {
          pickupController.text = liveAddress;
        }

        return SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 59.h, 16.w, 88.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _pickupDestinationCard(),
                    SizedBox(height: 9.h),
                    _chipsRow(),
                    SizedBox(height: 12.h),
                    Expanded(child: _buildSearchContent()),
                  ],
                ),
              ),
              Positioned(
                top: 12.h,
                left: 16.w,
                child: InkWell(
                  onTap: controller.closeLocationSelection,
                  child: SizedBox(
                    width: 28.w,
                    height: 28.w,
                    child: Center(
                      child: SvgPictureAsset(
                        AppAssets.locationIcArrowLeft,
                        width: 22.w,
                        height: 20.h,
                        placeholderBuilder: (_) =>
                            const Icon(Icons.arrow_back_ios_new, size: 18),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12.h,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Location Selection',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.homeTitle.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 34 / 20,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16.w,
                right: 16.w,
                bottom: 22.h,
                child: _bookRideButton(),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _pickupDestinationCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: Stack(
        fit: StackFit.loose,
        children: [
          Positioned.fill(
            child: SvgPictureAsset(
              AppAssets.locationCardBackground,
              fit: BoxFit.fill,
              placeholderBuilder: (_) => Container(color: Colors.white),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 10.w, 16.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _integratedLocationFields()),
                SizedBox(width: 6.w),
                Material(
                  color: Colors.transparent,
                  child: Opacity(
                    opacity:
                        _extraDestinationControllers.length >= _maxExtraStops
                        ? 0.45
                        : 1.0,
                    child: InkWell(
                      onTap:
                          _extraDestinationControllers.length >= _maxExtraStops
                          ? null
                          : _onAddDestinationStop,
                      borderRadius: BorderRadius.circular(20.r),
                      child: SizedBox(
                        width: 81.28.w,
                        height: 43.03.h,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SvgPictureAsset(
                              AppAssets.locationAddPillBackground,
                              fit: BoxFit.fill,
                              placeholderBuilder: (_) => Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAFAFA),
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: Border.all(
                                    color: const Color(0xFFEDEDED),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPictureAsset(
                                  AppAssets.locationIcAdd,
                                  width: 21.5.w,
                                  height: 21.5.h,
                                  placeholderBuilder: (_) => const Icon(
                                    Icons.add_circle_outline,
                                    size: 16,
                                    color: Color(0xFF656565),
                                  ),
                                ),
                                SizedBox(width: 4.72.w),
                                Text(
                                  'Add',
                                  style: AppTextStyles.homeCaption.copyWith(
                                    color: const Color(0xFF656565),
                                    fontSize: 14.34.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pinFieldRow({
    required Widget icon,
    required Widget field,
    bool showDivider = false,
    Widget? trailing,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            SizedBox(
              width: 14.w,
              child: Center(child: icon),
            ),
            SizedBox(width: 12.w),
            Expanded(child: field),
            if (trailing != null) ...[SizedBox(width: 8.w), trailing],
          ],
        ),
        if (showDivider)
          Row(
            children: [
              SizedBox(
                width: 14.w,
                child: Center(
                  child: Container(
                    width: 1.w,
                    height: 17.h,
                    color: const Color(0xFFEDEDED),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: SvgPictureAsset(
                    AppAssets.locationFieldDivider,
                    fit: BoxFit.fitWidth,
                    width: double.infinity,
                    height: 1.h,
                    placeholderBuilder: (_) =>
                        Container(height: 1.h, color: const Color(0xFFEDEDED)),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _integratedLocationFields() {
    final fieldStyle = AppTextStyles.homeSubtitle.copyWith(
      color: AppColors.shade1,
      fontSize: 15.sp,
      fontWeight: FontWeight.w500,
      height: 20 / 15,
    );
    final hintStyle = AppTextStyles.hint;

    final List<Widget> rows = [];

    // 1. Pickup
    rows.add(
      _pinFieldRow(
        icon: SvgPictureAsset(
          AppAssets.locationIcPin,
          width: 12.6.w,
          height: 16.4.h,
          placeholderBuilder: (_) =>
              const Icon(Icons.location_on, color: Color(0xFFF52D56), size: 14),
        ),
        field: TextField(
          controller: pickupController,
          focusNode: pickupFocusNode,
          onTap: () {
            _setActiveSegment(0);
            controller.searchQuery.value = pickupController.text.trim();
          },
          onChanged: (value) {
            pickupEditedByUser.value = true;
            _routePickupLat.value = null;
            _routePickupLng.value = null;
            controller.isPickupSelected.value = false;
            _setActiveSegment(0);
            controller.searchQuery.value = value;
          },
          style: fieldStyle,
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            hintText: 'Search pickup location',
            hintStyle: hintStyle,
          ),
        ),
        showDivider: true,
      ),
    );

    // 2. Destination
    rows.add(
      _pinFieldRow(
        icon: const Icon(Icons.push_pin, color: Color(0xFF34C759), size: 14),
        field: TextField(
          controller: destinationController,
          focusNode: destinationFocusNode,
          onTap: () {
            _setActiveSegment(1);
            controller.searchQuery.value = destinationController.text.trim();
          },
          onChanged: (value) {
            _destinationPlaceId.value = null;
            controller.isDestinationSelected.value = false;
            _setActiveSegment(1);
            controller.searchQuery.value = value;
          },
          style: fieldStyle,
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            hintText: 'Search destination',
            hintStyle: hintStyle,
          ),
        ),
        showDivider: _extraDestinationControllers.isNotEmpty,
      ),
    );

    // 3. Extra stops
    for (var i = 0; i < _extraDestinationControllers.length; i++) {
      final segment = 2 + i;
      rows.add(
        _pinFieldRow(
          icon: const Icon(Icons.push_pin, color: Color(0xFF34C759), size: 14),
          trailing: InkWell(
            onTap: () => _onRemoveDestinationStop(i),
            child: Icon(
              Icons.close,
              color: const Color(0xFF94A3B8),
              size: 16.sp,
            ),
          ),
          field: TextField(
            controller: _extraDestinationControllers[i],
            focusNode: _extraDestinationFocusNodes[i],
            onTap: () {
              _setActiveSegment(segment);
              controller.searchQuery.value = _extraDestinationControllers[i]
                  .text
                  .trim();
            },
            onChanged: (value) {
              _setActiveSegment(segment);
              controller.isDestinationSelected.value = false;
              controller.searchQuery.value = value;
            },
            style: fieldStyle,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: 'Search stop location',
              hintStyle: hintStyle,
            ),
          ),
          showDivider: i < _extraDestinationControllers.length - 1,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  void _onRemoveDestinationStop(int index) {
    if (index >= 0 && index < _extraDestinationControllers.length) {
      _extraDestinationControllers.removeAt(index);
      _extraDestinationFocusNodes[index].dispose();
      _extraDestinationFocusNodes.removeAt(index);
      // Reset search if we removed the active segment
      if (_activeSegmentIndex.value == 2 + index) {
        _setActiveSegment(1); // Set to main destination
        controller.searchQuery.value = '';
      } else if (_activeSegmentIndex.value > 2 + index) {
        _setActiveSegment(_activeSegmentIndex.value - 1);
      }
    }
  }

  Widget _chipsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('Home', AppAssets.icHomeChip),
          _chip('Work', AppAssets.icWorkChip),
          _chip('Other', AppAssets.icOtherChip),
        ],
      ),
    );
  }

  Widget _chip(String label, String iconPath) {
    final savedPlace = controller.savedPlaces.firstWhereOrNull(
      (p) => p.label?.toLowerCase() == label.toLowerCase(),
    );
    final isSaved = savedPlace != null;

    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: InkWell(
        onTap: () {
          if (isSaved) {
            controller.applySavedLabelToLocationSelection(
              label: label,
              activeSegmentIndex: _activeSegmentIndex.value,
              pickupController: pickupController,
              destinationController: destinationController,
              extraDestinationControllers: _extraDestinationControllers,
              pickupEditedByUser: pickupEditedByUser,
              routePickupLat: _routePickupLat,
              routePickupLng: _routePickupLng,
              routeDestinationLat: _routeDestinationLat,
              routeDestinationLng: _routeDestinationLng,
              destinationPlaceId: _destinationPlaceId,
            );
            controller.isDestinationSelected.value = true;
          } else {
            Get.toNamed(AppRoutes.selectSavedLocation, arguments: label);
          }
        },
        onLongPress: isSaved
            ? () => Get.toNamed(AppRoutes.selectSavedLocation, arguments: label)
            : null,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
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
                    ? SvgPictureAsset(
                        label.toLowerCase() == 'home'
                            ? AppAssets.icHomeChip
                            : label.toLowerCase() == 'work'
                            ? AppAssets.icWorkChip
                            : AppAssets.icOtherChip,
                        width: 16.w,
                        height: 16.w,
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
      ),
    );
  }

  Widget _suggestionsList(HomeController controller) {
    if (controller.suggestions.isEmpty) {
      return Center(
        child: Text(
          'No locations found',
          style: AppTextStyles.homeCaption.copyWith(color: AppColors.shade2),
        ),
      );
    }
    return ListView.separated(
      itemCount: controller.suggestions.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (_, index) {
        final item = controller.suggestions[index];
        final description = item.description ?? '';
        final title = description.split(',').first;
        final savedPlace = controller.getSavedPlaceFor(
          description,
          item.placeId,
        );
        final isFavorite = savedPlace?.isFavourite ?? false;
        final showFavorite = savedPlace != null;

        final dist = controller.calculateDistanceKm(
          savedPlace?.lat,
          savedPlace?.lng,
        );

        return _locationTile(
          kmText: dist.isEmpty ? 'SEARCH' : dist,
          title: title,
          subtitle: description,
          isFavorite: isFavorite,
          showFavorite: showFavorite,
          onTap: () => _onSuggestionSelected(item),
          onFavoriteTap: () =>
              controller.toggleFavorite(description, item.placeId),
        );
      },
    );
  }

  Widget _recentList(HomeController controller) {
    if (controller.searchQuery.value.trim().isEmpty) {
      if (controller.savedPlaces.isEmpty &&
          controller.recentDestinations.isEmpty) {
        return Center(
          child: Text(
            'Start typing destination',
            style: AppTextStyles.homeCaption.copyWith(color: AppColors.shade2),
          ),
        );
      }

      return ListView(
        shrinkWrap: true,
        children: [
          if (controller.savedPlaces.isNotEmpty) ...[
            _sectionHeader('Saved Places'),
            SizedBox(height: 12.h),
            _savedPlacesList(controller),
            SizedBox(height: 24.h),
          ],
          if (controller.recentDestinations.isNotEmpty) ...[
            _sectionHeader('Recent History'),
            SizedBox(height: 12.h),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.recentDestinations.length,
              separatorBuilder: (_, __) => SizedBox(height: 8.h),
              itemBuilder: (_, index) {
                final destination = controller.recentDestinations[index];
                final savedPlace = controller.getSavedPlaceFor(
                  destination.address,
                  null,
                );
                final isFavorite = savedPlace?.isFavourite ?? false;
                final showFavorite = savedPlace != null;

                final dist = controller.calculateDistanceKm(
                  destination.lat,
                  destination.lng,
                );

                return _locationTile(
                  kmText: dist.isEmpty ? 'RECENT' : dist,
                  title: destination.address.split(',').first,
                  subtitle: destination.address,
                  isFavorite: isFavorite,
                  showFavorite: showFavorite,
                  onTap: () {
                    controller.applyRecentDestinationToLocationSelection(
                      destination: destination,
                      activeSegmentIndex: _activeSegmentIndex.value,
                      pickupController: pickupController,
                      destinationController: destinationController,
                      extraDestinationControllers: _extraDestinationControllers,
                      pickupEditedByUser: pickupEditedByUser,
                      routePickupLat: _routePickupLat,
                      routePickupLng: _routePickupLng,
                      routeDestinationLat: _routeDestinationLat,
                      routeDestinationLng: _routeDestinationLng,
                      destinationPlaceId: _destinationPlaceId,
                    );
                    controller.isDestinationSelected.value = true;
                  },
                  onFavoriteTap: () =>
                      controller.toggleFavorite(destination.address, null),
                );
              },
            ),
          ],
        ],
      );
    }

    return ListView.separated(
      itemCount: controller.recentSearches.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (_, index) {
        final recentText = controller.recentSearches[index];
        final savedPlace = controller.getSavedPlaceFor(recentText, null);
        final isFavorite = savedPlace?.isFavourite ?? false;
        final showFavorite = savedPlace != null;

        final dist = controller.calculateDistanceKm(
          savedPlace?.lat,
          savedPlace?.lng,
        );

        return _locationTile(
          kmText: dist.isEmpty ? 'RECENT' : dist,
          title: recentText,
          subtitle: recentText,
          isFavorite: isFavorite,
          showFavorite: showFavorite,
          onTap: () {
            controller.applyRecentSearchToLocationSelection(
              recentText: recentText,
              activeSegmentIndex: _activeSegmentIndex.value,
              pickupController: pickupController,
              destinationController: destinationController,
              extraDestinationControllers: _extraDestinationControllers,
              pickupEditedByUser: pickupEditedByUser,
              routePickupLat: _routePickupLat,
              routePickupLng: _routePickupLng,
              routeDestinationLat: _routeDestinationLat,
              routeDestinationLng: _routeDestinationLng,
              destinationPlaceId: _destinationPlaceId,
            );
            controller.isDestinationSelected.value = true;
          },
          onFavoriteTap: () => controller.toggleFavorite(recentText, null),
        );
      },
    );
  }

  Widget _savedPlacesList(HomeController controller) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.savedPlaces.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (_, index) {
        final place = controller.savedPlaces[index];
        final label = (place.label ?? '').capitalizeFirst ?? '';
        final dist = controller.calculateDistanceKm(place.lat, place.lng);
        return _locationTile(
          kmText: dist.isEmpty ? 'SAVED' : dist,
          title: label,
          subtitle: place.address ?? '',
          isFavorite: place.isFavourite ?? false,
          showFavorite: true,
          onTap: () {
            controller.applySavedLabelToLocationSelection(
              label: label,
              activeSegmentIndex: _activeSegmentIndex.value,
              pickupController: pickupController,
              destinationController: destinationController,
              extraDestinationControllers: _extraDestinationControllers,
              pickupEditedByUser: pickupEditedByUser,
              routePickupLat: _routePickupLat,
              routePickupLng: _routePickupLng,
              routeDestinationLat: _routeDestinationLat,
              routeDestinationLng: _routeDestinationLng,
              destinationPlaceId: _destinationPlaceId,
            );
            controller.isDestinationSelected.value = true;
          },
          onFavoriteTap: () =>
              controller.toggleFavorite(place.address ?? '', null),
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.homeTitle.copyWith(
        fontSize: 16.sp,
        color: AppColors.shade1,
      ),
    );
  }

  Widget _locationTile({
    required String kmText,
    required String title,
    required String subtitle,
    required bool isFavorite,
    bool showFavorite = true,
    required VoidCallback onTap,
    required VoidCallback onFavoriteTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.r),
        onTap: onTap,
        child: SizedBox(
          height: 72.h,
          child: Padding(
            padding: EdgeInsets.fromLTRB(14.w, 15.h, 0, 15.h),
            child: Row(
              children: [
                SizedBox(
                  width: 60.w,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time_outlined,
                        color: const Color(0xFF94A3B8),
                        size: 20.sp,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        kmText,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.homeCaption.copyWith(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                          fontSize: 12.sp,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.homeSubtitle.copyWith(
                          color: AppColors.shade1,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.4,
                          height: 1.0,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.homeCaption.copyWith(
                          color: AppColors.shade2,
                          fontWeight: FontWeight.w400,
                          height: 20 / 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showFavorite)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: 48.w,
                      minHeight: 48.h,
                    ),
                    onPressed: onFavoriteTap,
                    icon: isFavorite
                        ? SvgPictureAsset(
                            AppAssets.locationIcHeartFilled,
                            width: 24.w,
                            height: 24.h,
                            placeholderBuilder: (_) => const Icon(
                              Icons.favorite,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          )
                        : Opacity(
                            opacity: 0.5,
                            child: SvgPictureAsset(
                              AppAssets.locationIcHeartOutline,
                              width: 24.w,
                              height: 24.w,
                              placeholderBuilder: (_) => Icon(
                                Icons.favorite_border,
                                color: const Color(
                                  0xFF292D32,
                                ).withValues(alpha: 0.5),
                                size: 20,
                              ),
                            ),
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bookRideButton() {
    return Obx(() {
      final isReady =
          controller.isPickupSelected.value &&
          controller.isDestinationSelected.value;
      return Material(
        color: isReady ? AppColors.primary : const Color(0xFFCBD5E1),
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: (isReady && !controller.isProceedingToBooking.value)
              ? () {
                  final destinations = <String>[];
                  destinations.add(destinationController.text.trim());
                  for (final c in _extraDestinationControllers) {
                    final t = c.text.trim();
                    if (t.isNotEmpty) destinations.add(t);
                  }
                  controller.proceedToBookingFromLocationSelection(
                    pickup: pickupController.text.trim(),
                    destinations: destinations,
                    destinationPlaceId: _destinationPlaceId.value,
                    routePickupLat: _routePickupLat.value,
                    routePickupLng: _routePickupLng.value,
                    routeDestinationLat: _routeDestinationLat.value,
                    routeDestinationLng: _routeDestinationLng.value,
                    preferredVehicleTypeId: _preferredVehicleTypeId.value,
                    preferredVehicleName: _preferredVehicleName.value,
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(16.r),
          child: SizedBox(
            height: 56.h,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (controller.isProceedingToBooking.value)
                  SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                else
                  Text(
                    'Book Ride',
                    style: AppTextStyles.homeTitle.copyWith(
                      color: isReady ? Colors.white : const Color(0xFF94A3B8),
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (!controller.isProceedingToBooking.value)
                  Positioned(
                    right: 20.w,
                    child: Icon(
                      Icons.arrow_forward,
                      color: isReady ? Colors.white : const Color(0xFF94A3B8),
                      size: 20.sp,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _onSuggestionSelected(Prediction prediction) {
    controller.applySuggestionToLocationSelection(
      prediction: prediction,
      activeSegmentIndex: _activeSegmentIndex.value,
      pickupController: pickupController,
      destinationController: destinationController,
      extraDestinationControllers: _extraDestinationControllers,
      pickupEditedByUser: pickupEditedByUser,
      routePickupLat: _routePickupLat,
      routePickupLng: _routePickupLng,
      routeDestinationLat: _routeDestinationLat,
      routeDestinationLng: _routeDestinationLng,
      destinationPlaceId: _destinationPlaceId,
    );
    if (_activeSegmentIndex.value == 0) {
      controller.isPickupSelected.value = true;
    } else {
      controller.isDestinationSelected.value = true;
    }
    controller.suggestions.clear();
  }

  Widget _buildSearchContent() {
    return Obx(() {
      if (controller.isSearching.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.searchQuery.value.trim().isNotEmpty) {
        return _suggestionsList(controller);
      }
      return _recentList(controller);
    });
  }
}
