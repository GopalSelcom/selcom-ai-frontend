import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/ride_stop_limits.dart';
import '../../../../core/data/models/responses/get_saved_places_response.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_saved_place_chip.dart';
import '../../data/models/places_models.dart';
import '../controllers/home_controller.dart';
import '../controllers/location_selection_controller.dart';
import '../widgets/favorite_icon_button.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  HomeController get controller => Get.find<HomeController>();

  LocationSelectionController get locationController =>
      Get.find<LocationSelectionController>();

  TextEditingController get pickupController =>
      locationController.pickupController;

  TextEditingController get destinationController =>
      locationController.destinationController;

  FocusNode get pickupFocusNode => locationController.pickupFocusNode;

  FocusNode get destinationFocusNode => locationController.destinationFocusNode;

  RxInt get _activeSegmentIndex => locationController.activeSegmentIndex;

  RxList<TextEditingController> get _extraDestinationControllers =>
      locationController.extraDestinationControllers;

  RxList<FocusNode> get _extraDestinationFocusNodes =>
      locationController.extraDestinationFocusNodes;

  RxBool get pickupEditedByUser => locationController.pickupEditedByUser;

  RxnString get _destinationPlaceId => locationController.destinationPlaceId;

  RxnDouble get _routePickupLat => locationController.routePickupLat;

  RxnDouble get _routePickupLng => locationController.routePickupLng;

  RxnDouble get _routeDestinationLat => locationController.routeDestinationLat;

  RxnDouble get _routeDestinationLng => locationController.routeDestinationLng;

  RxnString get _preferredVehicleTypeId =>
      locationController.preferredVehicleTypeId;

  RxnString get _preferredVehicleName =>
      locationController.preferredVehicleName;

  bool get _isVehicleSelectionEditMode =>
      locationController.isVehicleSelectionEditMode.value;

  int get _maxExtraStops => RideStopLimits.maxIntermediateStops;

  void _onAddDestinationStop() => locationController.onAddDestinationStop();

  void _setActiveSegment(int index) =>
      locationController.setActiveSegment(index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Obx(() {
              final bool shouldShowBookRideButton =
                  locationController.areAllSegmentsReadyForBooking ||
                  controller.isProceedingToBooking.value;
              return AnimatedPadding(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.fromLTRB(
                  16.w,
                  60.h,
                  16.w,
                  shouldShowBookRideButton ? 92.h : 16.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() {
                      locationController.syncPickupFromLiveAddress();
                      return _pickupDestinationCard();
                    }),
                    SizedBox(height: 8.79.h),
                    _chipsRow(),
                    SizedBox(height: 9.h),
                    Expanded(child: _buildSearchContent()),
                  ],
                ),
              );
            }),
            Positioned(
              top: 12.h,
              left: 16.w,
              child: Navigator.of(context).canPop()
                  ? AppBackButton(
                      color: AppColors.textHeading,
                      onPressed: controller.closeLocationSelection,
                    )
                  : const SizedBox.shrink(),
            ),
            Positioned(
              top: 12.h,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  AppStrings.locationSelection.tr,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.homeTitle.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 34 / 20,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ),
            Obx(() {
              final bool shouldShowBookRideButton =
                  locationController.areAllSegmentsReadyForBooking ||
                  controller.isProceedingToBooking.value;
              return Positioned(
                left: 16.w,
                right: 16.w,
                bottom: 26.h,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 360),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        sizeFactor: animation,
                        axis: Axis.vertical,
                        child: child,
                      ),
                    );
                  },
                  child: shouldShowBookRideButton
                      ? _bookRideButton(
                          key: const ValueKey('book-ride-visible'),
                        )
                      : const SizedBox.shrink(
                          key: ValueKey('book-ride-hidden'),
                        ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _pickupDestinationCard() {
    return ClipRRect(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          border: Border.all(color: AppColors.borderDefault),
          borderRadius: BorderRadius.all(Radius.circular(16.r)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(22.32.w, 15.54.h, 20.32.w, 17.22.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _integratedLocationFields()),
              Material(
                color: AppColors.transparent,
                child: Opacity(
                  opacity: _extraDestinationControllers.length >= _maxExtraStops
                      ? 0.45
                      : 1.0,
                  child: InkWell(
                    onTap: _extraDestinationControllers.length >= _maxExtraStops
                        ? null
                        : _onAddDestinationStop,
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      width: 81.28.w,
                      height: 43.03.h,
                      decoration: BoxDecoration(
                        color: AppColors.bgNeutralSoft,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: AppColors.borderNeutral,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPictureAsset(
                            AppAssets.locationIcAdd,
                            width: 16.74.w,
                            height: 16.74.w,
                            color: AppColors.iconMutedLight,
                            placeholderBuilder: (_) => const Icon(
                              Icons.add_circle,
                              size: 16,
                              color: AppColors.iconMutedLight,
                            ),
                          ),
                          SizedBox(width: 4.72.w),
                          Text(
                            AppStrings.add.tr,
                            style: AppTextStyles.homeCaption.copyWith(
                              color: AppColors.textMutedStrong,
                              fontSize: 14.34.sp,
                              fontWeight: FontWeight.w400,
                            ),
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
              width: 18.w,
              child: Center(child: icon),
            ),
            SizedBox(width: 13.06.w),
            Expanded(child: field),
            if (trailing != null) ...[SizedBox(width: 8.w), trailing],
          ],
        ),
        if (showDivider)
          const Divider(
            color: AppColors.borderNeutral,
            height: 26,
            endIndent: 0,
          ),
      ],
    );
  }

  Widget _integratedLocationFields() {
    final fieldStyle = AppTextStyles.homeSubtitle.copyWith(
      color: AppColors.textHeading,
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
          AppAssets.locationIcPickupPin,
          width: 12.6.w,
          height: 16.4.h,
          placeholderBuilder: (_) =>
              const Icon(Icons.location_on, color: AppColors.pinRed, size: 16),
        ),
        field: TextField(
          controller: pickupController,
          focusNode: pickupFocusNode,
          onTap: () {
            _setActiveSegment(0);
            locationController.onPickupFieldTapped();
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
            hintText: AppStrings.searchPickupLocation.tr,
            hintStyle: hintStyle,
          ),
        ),
        showDivider: true,
      ),
    );

    // 2. Extra stops (shown between pickup and final destination)
    for (var i = 0; i < _extraDestinationControllers.length; i++) {
      final segment = 2 + i;
      rows.add(
        _pinFieldRow(
          icon: SvgPictureAsset(
            AppAssets.locationIcDestinationPin,
            width: 12.6.w,
            height: 16.4.h,
            color: AppColors.mapDropMarkerGreen,
            placeholderBuilder: (_) => Icon(
              Icons.push_pin,
              color: AppColors.mapDropMarkerGreen,
              size: 16.w,
            ),
          ),
          trailing: Material(
            color: AppColors.transparent,
            child: Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: InkWell(
                onTap: () => _onRemoveDestinationStop(i),
                borderRadius: BorderRadius.circular(22.r),
                child: Padding(
                  padding: EdgeInsets.all(2.w),
                  child: Icon(
                    Icons.close,
                    color: AppColors.textHint,
                    size: 20.sp,
                  ),
                ),
              ),
            ),
          ),
          field: TextField(
            controller: _extraDestinationControllers[i],
            focusNode: _extraDestinationFocusNodes[i],
            onTap: () {
              _setActiveSegment(segment);
              locationController.onExtraStopFieldTapped(i);
            },
            onChanged: (value) {
              _setActiveSegment(segment);
              locationController.markExtraStopUnconfirmed(i);
              controller.searchQuery.value = value;
            },
            style: fieldStyle,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: AppStrings.searchStopLocation.tr,
              hintStyle: hintStyle,
            ),
          ),
          // Keep a connector line to the next row (another stop or final destination).
          showDivider: true,
        ),
      );
    }

    // 3. Final destination (always the last row)
    rows.add(
      _pinFieldRow(
        icon: SvgPictureAsset(
          AppAssets.locationIcDestinationPin,
          width: 12.6.w,
          height: 16.4.h,
          color: AppColors.mapDropMarkerGreen,
          placeholderBuilder: (_) => Icon(
            Icons.push_pin,
            color: AppColors.mapDropMarkerGreen,
            size: 16.w,
          ),
        ),
        field: TextField(
          controller: destinationController,
          focusNode: destinationFocusNode,
          onTap: () {
            _setActiveSegment(1);
            locationController.onDestinationFieldTapped();
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
            hintText: AppStrings.searchDestination.tr,
            hintStyle: hintStyle,
          ),
        ),
        showDivider: false,
      ),
    );

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
      if (index < locationController.extraStopSelected.length) {
        locationController.extraStopSelected.removeAt(index);
      }
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
    return Obx(
      () => controller.savedPlaces.isEmpty
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _sortedSavedPlaces(
                  controller.savedPlaces,
                ).map((place) => _chip(place)).toList(),
              ),
            ),
    );
  }

  Widget _chip(SavedPlace savedPlace) {
    final label = _savedPlaceLabel(savedPlace);

    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: AppSavedPlaceChip(
        label: label,
        iconAsset: _chipIconForLabel(label),
        backgroundColor: AppColors.white,
        borderColor: AppColors.borderWalletCard,
        onTap: () {
          final applied = controller.applySavedLabelToLocationSelection(
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
          if (applied) {
            locationController.confirmSelectionForSegment(
              _activeSegmentIndex.value,
            );
          }
        },
        onLongPress: () =>
            Get.toNamed(AppRoutes.selectSavedLocation, arguments: label),
      ),
    );
  }

  String _savedPlaceLabel(SavedPlace place) {
    final raw = (place.label ?? place.name ?? '').trim();
    if (raw.isNotEmpty) return raw.capitalizeFirst ?? raw;
    return AppStrings.saved.tr;
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

  Widget _suggestionsList(HomeController controller) {
    if (controller.suggestions.isEmpty) {
      return Center(
        child: Text(
          AppStrings.noLocationsFound.tr,
          style: AppTextStyles.homeCaption.copyWith(color: AppColors.textBody),
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
          kmText: dist.isEmpty ? AppStrings.searchTag.tr : dist,
          title: title,
          subtitle: description,
          isFavorite: isFavorite,
          showFavorite: showFavorite,
          onTap: () => _onSuggestionSelected(item),
          onFavoriteTap: () => controller.toggleAddAddressBottomSheet(item),
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
            AppStrings.startTypingDestination.tr,
            style: AppTextStyles.homeCaption.copyWith(
              color: AppColors.textBody,
            ),
          ),
        );
      }

      return ListView(
        shrinkWrap: true,
        children: [
          if (controller.savedPlaces.isNotEmpty) ...[
            _sectionHeader(AppStrings.savedPlaces.tr),
            SizedBox(height: 12.h),
            _savedPlacesList(controller),
            SizedBox(height: 24.h),
          ],
          if (controller.recentDestinations.isNotEmpty) ...[
            _sectionHeader(AppStrings.recentLocations.tr),
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
                  kmText: dist.isEmpty ? AppStrings.recentTag.tr : dist,
                  title: destination.address.split(',').first,
                  subtitle: destination.address,
                  isFavorite: isFavorite,
                  showFavorite: showFavorite,
                  onTap: () {
                    if (Get.arguments is Map &&
                        Get.arguments['isSelectingStop'] == true) {
                      _handleStopSelection(
                        address: destination.address,
                        lat: destination.lat,
                        lng: destination.lng,
                      );
                      return;
                    }
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
                    locationController.confirmSelectionForSegment(
                      _activeSegmentIndex.value,
                    );
                  },
                  onFavoriteTap: () =>
                      controller.toggleAddAddressBottomSheetForAddress(
                        address: destination.address,
                        lat: destination.lat,
                        lng: destination.lng,
                      ),
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
          kmText: dist.isEmpty ? AppStrings.recentTag.tr : dist,
          title: recentText,
          subtitle: recentText,
          isFavorite: isFavorite,
          showFavorite: showFavorite,
          onTap: () async {
            if (Get.arguments is Map &&
                Get.arguments['isSelectingStop'] == true) {
              AppDialogs.showLoadingDialog();
              final result = await controller.homeRepository.getGeocode(
                address: recentText,
              );
              Get.back(); // close loading

              result.fold(
                (failure) =>
                    AppDialogs.showErrorDialog(message: failure.message),
                (data) {
                  final loc = data.results?.firstOrNull?.geometry?.location;
                  if (loc != null && loc.lat != null && loc.lng != null) {
                    _handleStopSelection(
                      address: recentText,
                      lat: loc.lat!,
                      lng: loc.lng!,
                    );
                  } else {
                    AppDialogs.showErrorDialog(
                      message: AppStrings.unableToGetLocationCoordinates.tr,
                    );
                  }
                },
              );
              return;
            }
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
            locationController.confirmSelectionForSegment(
              _activeSegmentIndex.value,
            );
          },
          onFavoriteTap: () => controller.toggleAddAddressBottomSheetForAddress(
            address: recentText,
          ),
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
          kmText: dist.isEmpty ? AppStrings.savedTag.tr : dist,
          title: label,
          subtitle: place.address ?? '',
          isFavorite: place.isFavourite ?? false,
          showFavorite: true,
          onTap: () {
            if (Get.arguments is Map &&
                Get.arguments['isSelectingStop'] == true) {
              _handleStopSelection(
                address: place.address ?? '',
                lat: place.lat ?? 0.0,
                lng: place.lng ?? 0.0,
              );
              return;
            }
            final applied = controller.applySavedLabelToLocationSelection(
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
            if (applied) {
              locationController.confirmSelectionForSegment(
                _activeSegmentIndex.value,
              );
            }
          },
          onFavoriteTap: () => controller.toggleAddAddressBottomSheetForAddress(
            address: place.address ?? '',
            lat: place.lat,
            lng: place.lng,
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.homeSubtitle.copyWith(
        color: AppColors.textSectionMuted,
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
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14.w, 15.h, 13.w, 14.56.h),
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPictureAsset(
                    AppAssets.locationIcTime,
                    width: 21.44.w,
                    height: 21.44.h,
                    placeholderBuilder: (_) => Icon(
                      Icons.access_time_outlined,
                      color: AppColors.iconMutedLight,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    kmText,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.homeCaption.copyWith(
                      color: AppColors.textSlateSoft,
                      fontWeight: FontWeight.w400,
                      fontSize: 12.sp,
                      height: 20 / 12,
                    ),
                  ),
                ],
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
                        color: AppColors.textHeading,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.homeCaption.copyWith(
                        color: AppColors.textBody,
                        fontWeight: FontWeight.w500,
                        height: 20 / 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (showFavorite)
                FavoriteIconButton(
                  isFavorite: isFavorite,
                  onPressed: onFavoriteTap,
                  size: 24,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 48.w, minHeight: 48.h),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bookRideButton({Key? key}) {
    return Obx(() {
      return AppPrimaryButton(
        key: key,
        label: AppStrings.bookRide.tr,
        height: 56.h,
        borderRadius: 16.r,
        iconAsset: AppAssets.icArrowRight,
        iconColor: AppColors.white,
        isLoading: controller.isProceedingToBooking.value,
        onPressed: () async {
          final destinations = <String>[];
          for (final c in _extraDestinationControllers) {
            final t = c.text.trim();
            if (t.isNotEmpty) destinations.add(t);
          }
          final finalDestination = destinationController.text.trim();
          if (finalDestination.isNotEmpty) {
            destinations.add(finalDestination);
          }
          if (_isVehicleSelectionEditMode) {
            final payload = await _buildVehicleSelectionEditResult(
              pickupText: pickupController.text.trim(),
              destinationTexts: destinations,
            );
            if (payload == null) {
              AppDialogs.showErrorDialog(
                message: AppStrings
                    .pleaseSelectValidPickupAndDestinationLocations
                    .tr,
              );
              return;
            }
            Get.back(result: payload);
            return;
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
        },
      );
    });
  }

  Future<Map<String, dynamic>?> _buildVehicleSelectionEditResult({
    required String pickupText,
    required List<String> destinationTexts,
  }) async {
    final cleanedDestinations = destinationTexts
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (pickupText.isEmpty || cleanedDestinations.isEmpty) return null;

    final pickupLatLng =
        (_routePickupLat.value != null && _routePickupLng.value != null)
        ? null
        : await controller.getLatLngFromAddress(pickupText);
    final pickupLat = _routePickupLat.value ?? pickupLatLng?.latitude;
    final pickupLng = _routePickupLng.value ?? pickupLatLng?.longitude;
    if (pickupLat == null || pickupLng == null) return null;

    final resultDestinations = <Map<String, dynamic>>[];
    for (var i = 0; i < cleanedDestinations.length; i++) {
      final text = cleanedDestinations[i];
      double? lat;
      double? lng;
      if (i == cleanedDestinations.length - 1) {
        lat = _routeDestinationLat.value;
        lng = _routeDestinationLng.value;
      }
      if (lat == null || lng == null) {
        final resolved = await controller.getLatLngFromAddress(text);
        lat = resolved?.latitude;
        lng = resolved?.longitude;
      }
      if (lat == null || lng == null) return null;
      resultDestinations.add({'address': text, 'lat': lat, 'lng': lng});
    }

    return {
      'pickup': pickupText,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'destinations': resultDestinations,
    };
  }

  Future<void> _handleStopSelection({
    required String address,
    required double lat,
    required double lng,
  }) async {
    final result = await Get.toNamed(
      AppRoutes.confirmStop,
      arguments: {'address': address, 'lat': lat, 'lng': lng},
    );
    if (result != null) {
      Get.back(result: result);
    }
  }

  void _onSuggestionSelected(Prediction prediction) async {
    if (Get.arguments is Map && Get.arguments['isSelectingStop'] == true) {
      final description = prediction.description ?? '';
      AppDialogs.showLoadingDialog();
      final result = await controller.homeRepository.getGeocode(
        address: description,
      );
      Get.back(); // close loading

      result.fold(
        (failure) => AppDialogs.showErrorDialog(message: failure.message),
        (data) {
          final loc = data.results?.firstOrNull?.geometry?.location;
          if (loc != null && loc.lat != null && loc.lng != null) {
            _handleStopSelection(
              address: description,
              lat: loc.lat!,
              lng: loc.lng!,
            );
          } else {
            AppDialogs.showErrorDialog(
              message: AppStrings.unableToGetLocationCoordinates.tr,
            );
          }
        },
      );
      return;
    }
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
    locationController.confirmSelectionForSegment(_activeSegmentIndex.value);
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
