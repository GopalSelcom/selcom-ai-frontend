import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../controllers/home_controller.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  late final HomeController controller;
  late final TextEditingController pickupController;
  late final TextEditingController destinationController;
  late final FocusNode pickupFocusNode;
  late final FocusNode destinationFocusNode;
  /// 0 = pickup, 1 = first destination, 2+ = extra stop at index `segment - 2`.
  int _activeSegmentIndex = 1;
  final List<TextEditingController> _extraDestinationControllers = [];
  final List<FocusNode> _extraDestinationFocusNodes = [];
  bool pickupEditedByUser = false;
  /// Set when the first destination is chosen from autocomplete (required for `saved-places` on Book Ride).
  String? _destinationPlaceId;
  static const int _maxExtraStops = 6;

  /// From route args (home / explore vehicle); used for Book Ride pickup coords.
  double? _routePickupLat;
  double? _routePickupLng;
  /// Destination coordinates for first drop, when user picked a source that includes coords.
  double? _routeDestinationLat;
  double? _routeDestinationLng;
  /// Forwarded to vehicle selection as default vehicle.
  String? _preferredVehicleTypeId;
  String? _preferredVehicleName;

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
        pickupEditedByUser = true;
      }
      final plat = (m['pickupLat'] as num?)?.toDouble();
      final plng = (m['pickupLng'] as num?)?.toDouble();
      if (plat != null && plng != null) {
        _routePickupLat = plat;
        _routePickupLng = plng;
      }
      _preferredVehicleTypeId = (m['preferredVehicleTypeId'] as String?)?.trim();
      _preferredVehicleName = (m['preferredVehicleName'] as String?)?.trim();
    }
    pickupController = TextEditingController(text: initialPickup);
    destinationController = TextEditingController();
    pickupFocusNode = FocusNode();
    destinationFocusNode = FocusNode();
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
    setState(() {
      _extraDestinationControllers.add(TextEditingController());
      _extraDestinationFocusNodes.add(FocusNode());
      _activeSegmentIndex = 2 + _extraDestinationControllers.length - 1;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_extraDestinationFocusNodes.isEmpty) return;
      final node = _extraDestinationFocusNodes.last;
      node.requestFocus();
      controller.searchQuery.value = _extraDestinationControllers.last.text.trim();
    });
  }

  int get _destinationCount => 1 + _extraDestinationControllers.length;

  void _setActiveSegment(int index) {
    if (_activeSegmentIndex == index) return;
    setState(() => _activeSegmentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Obx(() {
        final liveAddress = controller.currentMapAddress.value.trim();
        if (!pickupEditedByUser && liveAddress.isNotEmpty) {
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
                    SizedBox(height: 9.h),
                    Padding(
                      padding: EdgeInsets.only(left: 1.w),
                      child: Text(
                        'Recent Locations',
                        style: AppTextStyles.homeSubtitle.copyWith(
                          color: const Color(0xFF77869E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Expanded(child: _buildSearchContent()),
                  ],
                ),
              ),
              Positioned(
                top: 12.h,
                left: 16.w,
                child: InkWell(
                  onTap: Get.back,
                  child: SizedBox(
                    width: 28.w,
                    height: 28.w,
                    child: Center(
                      child: SvgPictureAsset(
                        AppAssets.locationIcArrowLeft,
                        width: 22.w,
                        height: 20.h,
                        placeholderBuilder: (_) => const Icon(Icons.arrow_back_ios_new, size: 18),
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
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _pinColumn(),
                  SizedBox(width: 12.w),
                  Expanded(child: _destinationFieldsColumn()),
                  SizedBox(width: 6.w),
                  Align(
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: _extraDestinationControllers.length >= _maxExtraStops ? 0.45 : 1,
                      child: InkWell(
                        onTap: _extraDestinationControllers.length >= _maxExtraStops ? null : _onAddDestinationStop,
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
                                  border: Border.all(color: const Color(0xFFEDEDED)),
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
                                  placeholderBuilder: (_) =>
                                      const Icon(Icons.add_circle_outline, size: 16, color: Color(0xFF656565)),
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
          ),
        ],
      ),
    );
  }

  Widget _pinColumn() {
    final n = _destinationCount;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPictureAsset(
          AppAssets.locationIcPin,
          width: 12.6.w,
          height: 16.4.h,
          placeholderBuilder: (_) => const Icon(Icons.location_on, color: Color(0xFFF52D56), size: 14),
        ),
        SizedBox(height: 12.h),
        Container(width: 1.w, height: 18.h, color: const Color(0xFFEDEDED)),
        SizedBox(height: 12.h),
        for (int i = 0; i < n; i++) ...[
          const Icon(Icons.push_pin, color: Color(0xFF34C759), size: 14),
          if (i < n - 1) ...[
            SizedBox(height: 12.h),
            Container(width: 1.w, height: 18.h, color: const Color(0xFFEDEDED)),
            SizedBox(height: 12.h),
          ],
        ],
      ],
    );
  }

  Widget _destinationFieldsColumn() {
    final fieldStyle = AppTextStyles.homeSubtitle.copyWith(
      color: AppColors.shade1,
      fontSize: 15.sp,
      fontWeight: FontWeight.w500,
      height: 20 / 15,
    );
    final hintStyle = fieldStyle;

    Widget divider() => Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: SvgPictureAsset(
            AppAssets.locationFieldDivider,
            fit: BoxFit.fitWidth,
            width: double.infinity,
            height: 1.h,
            placeholderBuilder: (_) => Container(height: 1.h, color: const Color(0xFFEDEDED)),
          ),
        );

    final children = <Widget>[
      TextField(
        controller: pickupController,
        focusNode: pickupFocusNode,
        onTap: () {
          _setActiveSegment(0);
          controller.searchQuery.value = pickupController.text.trim();
        },
        onChanged: (value) {
          pickupEditedByUser = true;
          _setActiveSegment(0);
          controller.searchQuery.value = value;
        },
        style: fieldStyle,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: 'AutoBhan Road',
          hintStyle: hintStyle,
        ),
      ),
      divider(),
      TextField(
        controller: destinationController,
        focusNode: destinationFocusNode,
        onTap: () {
          _setActiveSegment(1);
          controller.searchQuery.value = destinationController.text.trim();
        },
        onChanged: (value) {
          _destinationPlaceId = null;
          _setActiveSegment(1);
          controller.searchQuery.value = value;
        },
        style: fieldStyle,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: 'Home',
          hintStyle: hintStyle,
        ),
      ),
    ];

    for (var i = 0; i < _extraDestinationControllers.length; i++) {
      final segment = 2 + i;
      children.add(divider());
      children.add(
        TextField(
          controller: _extraDestinationControllers[i],
          focusNode: _extraDestinationFocusNodes[i],
          onTap: () {
            _setActiveSegment(segment);
            controller.searchQuery.value = _extraDestinationControllers[i].text.trim();
          },
          onChanged: (value) {
            _setActiveSegment(segment);
            controller.searchQuery.value = value;
          },
          style: fieldStyle,
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            hintText: 'Add stop',
            hintStyle: hintStyle,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _chipsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('Home', AppAssets.locationIcChipHome),
          _chip('Office', AppAssets.locationIcChipOffice),
          _chip('Other', AppAssets.locationIcChipOther),
          _chip('Work', AppAssets.locationIcChipWork),
        ],
      ),
    );
  }

  Widget _chip(String label, String iconPath) {
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: InkWell(
        onTap: () {
          final savedPlace = controller.getSavedPlaceByLabel(label);
          final saved = savedPlace?.address?.trim();
          if (saved != null && saved.isNotEmpty) {
            final coords = savedPlace?.location?.coordinates;
            final lat = savedPlace?.lat ?? ((coords != null && coords.length >= 2) ? coords[1] : null);
            final lng = savedPlace?.lng ?? ((coords != null && coords.length >= 2) ? coords[0] : null);
            setState(() {
              destinationController.text = saved;
              _routeDestinationLat = lat;
              _routeDestinationLng = lng;
              _destinationPlaceId = null;
              _activeSegmentIndex = 1;
            });
            controller.searchQuery.value = '';
          }
        },
        child: Container(
          height: 36.h,
          padding: EdgeInsets.symmetric(horizontal: 18.36.w, vertical: 2.36.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFE6E9EE), width: 0.787),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPictureAsset(
                iconPath,
                width: 15.w,
                height: 15.w,
                placeholderBuilder: (_) => const Icon(Icons.place, size: 13),
              ),
              SizedBox(width: 4.72.w),
              Text(
                label,
                style: AppTextStyles.homeChip.copyWith(
                  color: const Color(0xFF2A3143),
                  height: 1.0,
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
        child: Text('No locations found', style: AppTextStyles.homeCaption.copyWith(color: AppColors.shade2)),
      );
    }
    return ListView.separated(
      itemCount: controller.suggestions.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (_, index) {
        final item = controller.suggestions[index];
        final description = item.description ?? '';
        final title = description.split(',').first;
        return _locationTile(
          kmText: '${index + 2} KM',
          title: title,
          subtitle: description,
          isFavorite: index.isOdd,
          onTap: () => _onSuggestionSelected(item),
          onFavoriteTap: () {},
        );
      },
    );
  }

  Widget _recentList(HomeController controller) {
    if (controller.recentDestinations.isNotEmpty) {
      return ListView.separated(
        itemCount: controller.recentDestinations.length,
        separatorBuilder: (_, __) => SizedBox(height: 8.h),
        itemBuilder: (_, index) {
          final destination = controller.recentDestinations[index];
          return _locationTile(
            kmText: '${index + 2} KM',
            title: destination.address.split(',').first,
            subtitle: destination.address,
            isFavorite: index.isOdd,
            onTap: () {
              setState(() {
                _applyTextToActiveSegment(destination.address);
                if (_activeSegmentIndex == 1) {
                  _routeDestinationLat = destination.lat;
                  _routeDestinationLng = destination.lng;
                }
              });
              controller.searchQuery.value = '';
            },
            onFavoriteTap: () {},
          );
        },
      );
    }

    if (controller.recentSearches.isEmpty) {
      return Center(
        child: Text(
          'Start typing destination',
          style: AppTextStyles.homeCaption.copyWith(color: AppColors.shade2),
        ),
      );
    }

    return ListView.separated(
      itemCount: controller.recentSearches.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (_, index) => _locationTile(
        kmText: '${index + 2} KM',
        title: controller.recentSearches[index],
        subtitle: controller.recentSearches[index],
        isFavorite: false,
        onTap: () {
          setState(() => _applyTextToActiveSegment(controller.recentSearches[index]));
          controller.searchQuery.value = '';
        },
        onFavoriteTap: () {},
      ),
    );
  }

  Widget _locationTile({
    required String kmText,
    required String title,
    required String subtitle,
    required bool isFavorite,
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
                  width: 33.w,
                  child: Column(
                    children: [
                      SvgPictureAsset(
                        AppAssets.locationClockDistance,
                        width: 21.44.w,
                        height: 21.44.h,
                        placeholderBuilder: (_) => const Icon(Icons.schedule, color: Color(0xFFCACACA), size: 20),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        kmText,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.homeCaption.copyWith(
                          color: const Color(0xFF656565),
                          fontWeight: FontWeight.w400,
                          height: 20 / 12,
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
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 48.w, minHeight: 48.h),
                  onPressed: onFavoriteTap,
                  icon: isFavorite
                      ? SvgPictureAsset(
                          AppAssets.locationIcHeartFilled,
                          width: 24.w,
                          height: 24.h,
                          placeholderBuilder: (_) => Icon(Icons.favorite, color: AppColors.primary, size: 20),
                        )
                      : Opacity(
                          opacity: 0.5,
                          child: SvgPictureAsset(
                            AppAssets.locationIcHeartOutline,
                            width: 24.w,
                            height: 24.w,
                            placeholderBuilder: (_) => Icon(
                              Icons.favorite_border,
                              color: const Color(0xFF292D32).withOpacity(0.5),
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
    final pickup = pickupController.text.trim();
    final destinations = [
      destinationController.text.trim(),
      ..._extraDestinationControllers.map((c) => c.text.trim()),
    ];
    final enabled =
        pickup.isNotEmpty && destinations.isNotEmpty && destinations.every((d) => d.isNotEmpty);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: enabled
            ? () async {
                final pid = _destinationPlaceId?.trim();
                if (pid != null && pid.isNotEmpty) {
                  await controller.savePlace(
                    label: 'Destination',
                    name: destinations.first,
                    placeId: pid,
                  );
                }
                final pLat =
                    _routePickupLat ?? controller.mapCenter.value.latitude;
                final pLng =
                    _routePickupLng ?? controller.mapCenter.value.longitude;
                final dLat = _routeDestinationLat ?? (pLat - 0.018);
                final dLng = _routeDestinationLng ?? (pLng + 0.014);
                Get.toNamed(
                  AppRoutes.booking,
                  arguments: {
                    'pickup': pickup,
                    'destination': destinations.first,
                    'destinations': destinations,
                    'pickupLat': pLat,
                    'pickupLng': pLng,
                    'destinationLat': dLat,
                    'destinationLng': dLng,
                    if (_preferredVehicleTypeId != null &&
                        _preferredVehicleTypeId!.isNotEmpty)
                      'preferredVehicleTypeId': _preferredVehicleTypeId,
                    if (_preferredVehicleName != null &&
                        _preferredVehicleName!.isNotEmpty)
                      'preferredVehicleName': _preferredVehicleName,
                  },
                );
              }
            : null,
        child: Ink(
          height: 54.h,
          decoration: BoxDecoration(
            color: enabled ? AppColors.primary : const Color(0xFFBFC7D1),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Text(
                  'Book Ride',
                  style: AppTextStyles.onboardingButton.copyWith(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w600,
                    height: 22 / 17,
                  ),
                ),
              ),
              Positioned(
                right: 16.w,
                top: 0,
                bottom: 0,
                child: Center(
                  child: SvgPictureAsset(
                    AppAssets.locationIcArrowRight,
                    width: 24.w,
                    height: 24.w,
                    placeholderBuilder: (_) => const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchContent() {
    final query = controller.searchQuery.value.trim();
    if (query.length >= 2) {
      if (controller.isSearching.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return _suggestionsList(controller);
    }
    return _recentList(controller);
  }

  Future<void> _onSuggestionSelected(dynamic prediction) async {
    await controller.selectPlace(prediction);
    final description = prediction.description ?? '';
    if (_activeSegmentIndex == 0) {
      pickupEditedByUser = true;
      _routePickupLat = null;
      _routePickupLng = null;
      pickupController.text = description;
      pickupController.selection = TextSelection.fromPosition(
        TextPosition(offset: pickupController.text.length),
      );
    } else if (_activeSegmentIndex == 1) {
      destinationController.text = description;
      _routeDestinationLat = null;
      _routeDestinationLng = null;
      _destinationPlaceId = prediction.placeId?.trim();
      destinationController.selection = TextSelection.fromPosition(
        TextPosition(offset: destinationController.text.length),
      );
    } else {
      final i = _activeSegmentIndex - 2;
      if (i >= 0 && i < _extraDestinationControllers.length) {
        final c = _extraDestinationControllers[i];
        c.text = description;
        c.selection = TextSelection.fromPosition(TextPosition(offset: c.text.length));
      }
    }
    controller.searchQuery.value = '';
    setState(() {});
  }

  void _applyTextToActiveSegment(String text) {
    if (_activeSegmentIndex == 0) {
      pickupEditedByUser = true;
      _routePickupLat = null;
      _routePickupLng = null;
      pickupController.text = text;
    } else if (_activeSegmentIndex == 1) {
      destinationController.text = text;
      _routeDestinationLat = null;
      _routeDestinationLng = null;
      _destinationPlaceId = null;
    } else {
      final i = _activeSegmentIndex - 2;
      if (i >= 0 && i < _extraDestinationControllers.length) {
        _extraDestinationControllers[i].text = text;
      }
    }
  }

}
