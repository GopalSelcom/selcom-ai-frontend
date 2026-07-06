import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/data/models/ride_model.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/payment_dialog_header_section.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/utils/active_rides_parser.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/book_for_other_prompt_policy.dart';
import '../../../../shared/utils/favorite_location_chip_catalog.dart';
import '../../../../shared/utils/saved_place_confirmation_copy.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../ride/domain/repositories/ride_repository.dart';
import '../../../ride/presentation/widgets/booking_for_someone_else_flow_bottom_sheet.dart';
import '../../domain/repositories/home_repository.dart';
import 'home_controller.dart';

const double _savedPlaceChipTiltRadians = -7 * math.pi / 180;
const double _moveThreshold = 0.00005;

/// Labels and flags for [ConfirmLocationScreen] — built from route in the controller.
class ConfirmLocationUiConfig {
  const ConfirmLocationUiConfig({
    required this.pinLabel,
    required this.headerTitle,
    required this.headerSubtitle,
    required this.headerIconAsset,
    this.headerIconColor = AppColors.mapDropMarkerGreen,
    required this.addressEmptyFallback,
    required this.confirmButtonLabel,
    this.confirmButtonIconAsset = AppAssets.locationIcArrowRight,
    this.showDriverNote = false,
    this.showPreviousPointMarker = true,
    this.showRouteCircles = true,
    this.bottomPanelReserve = 400,
  });

  final String pinLabel;
  final String headerTitle;
  final String headerSubtitle;
  final String headerIconAsset;
  final Color headerIconColor;
  final String addressEmptyFallback;
  final String confirmButtonLabel;
  final String? confirmButtonIconAsset;
  final bool showDriverNote;
  final bool showPreviousPointMarker;
  final bool showRouteCircles;
  final double bottomPanelReserve;

  factory ConfirmLocationUiConfig.ridePickup({
    bool showPreviousPointMarker = true,
    bool showRouteCircles = true,
    bool showDriverNote = true,
  }) {
    return ConfirmLocationUiConfig(
      pinLabel: AppStrings.pickupPoint,
      headerTitle: AppStrings.checkYourPickupPoint,
      headerSubtitle: AppStrings.selectANearbyPointForEasierPickup,
      headerIconAsset: AppAssets.locationIcPickupPin,
      addressEmptyFallback: AppStrings.selectedPickupPoint,
      confirmButtonLabel: AppStrings.confirmPickup,
      showDriverNote: showDriverNote,
      showPreviousPointMarker: showPreviousPointMarker,
      showRouteCircles: showRouteCircles,
    );
  }

  factory ConfirmLocationUiConfig.savedPlacePickup({
    bool showPreviousPointMarker = true,
    bool showRouteCircles = true,
  }) {
    return ConfirmLocationUiConfig(
      pinLabel: AppStrings.pickupPoint,
      headerTitle: AppStrings.checkYourPickupPoint,
      headerSubtitle: AppStrings.selectANearbyPointForEasierPickup,
      headerIconAsset: AppAssets.locationIcPickupPin,
      addressEmptyFallback: AppStrings.selectedPickupPoint,
      confirmButtonLabel: AppStrings.confirmPickup,
      showPreviousPointMarker: showPreviousPointMarker,
      showRouteCircles: showRouteCircles,
    );
  }

  factory ConfirmLocationUiConfig.stop({
    bool showPreviousPointMarker = true,
    bool showRouteCircles = true,
  }) {
    return ConfirmLocationUiConfig(
      pinLabel: AppStrings.stopLocation,
      headerTitle: AppStrings.stopLocation,
      headerSubtitle: AppStrings.searchStopLocation,
      headerIconAsset: AppAssets.locationIcDestinationPin,
      headerIconColor: AppColors.primary,
      addressEmptyFallback: AppStrings.stopLocation,
      confirmButtonLabel: AppStrings.confirmStop,
      showPreviousPointMarker: showPreviousPointMarker,
      showRouteCircles: showRouteCircles,
    );
  }

  factory ConfirmLocationUiConfig.destination({
    bool showPreviousPointMarker = true,
    bool showRouteCircles = true,
  }) {
    return ConfirmLocationUiConfig(
      pinLabel: AppStrings.destination,
      headerTitle: AppStrings.newDestination,
      headerSubtitle: AppStrings.searchDestination,
      headerIconAsset: AppAssets.locationIcDestinationPin,
      headerIconColor: AppColors.primary,
      addressEmptyFallback: AppStrings.destination,
      confirmButtonLabel: AppStrings.updateDestination,
      showPreviousPointMarker: showPreviousPointMarker,
      showRouteCircles: showRouteCircles,
    );
  }
}

/// One controller for pickup confirm, stop confirm, and saved-place confirm.
class ConfirmLocationController extends GetxController {
  ConfirmLocationController({
    required this.homeRepository,
    required this.rideRepository,
    required this.homeController,
  });

  final HomeRepository homeRepository;
  final RideRepository rideRepository;
  final HomeController homeController;

  final selectedLatLng = const LatLng(-6.7924, 39.2083).obs;
  final address = ''.obs;
  final isResolvingAddress = false.obs;
  final isSubmitting = false.obs;
  final isMapReady = false.obs;
  final noteChipRevision = 0.obs;
  final isNoteExpanded = false.obs;
  final routeCircles = Rx<Set<Circle>>(<Circle>{});

  final noteForDriverController = TextEditingController();
  GoogleMapController? mapController;

  late LatLng _initialLatLng;
  late ConfirmLocationUiConfig uiConfig;
  late String _flow;

  String _savedPlaceLabel = '';

  /// Set when rebooking via finding-driver "Search again" after timeout.
  bool _forceRefreshActiveRides = false;

  VoidCallback? _noteListener;
  int _cameraSyncGeneration = 0;

  LatLng get initialLatLng => _initialLatLng;

  bool get hasMovedFromInitial =>
      (selectedLatLng.value.latitude - _initialLatLng.latitude).abs() >
          _moveThreshold ||
      (selectedLatLng.value.longitude - _initialLatLng.longitude).abs() >
          _moveThreshold;

  @override
  void onInit() {
    super.onInit();
    _noteListener = () {
      if (isClosed) return;
      noteChipRevision.value++;
    };
    noteForDriverController.addListener(_noteListener!);
    _bootstrapFromRoute();
  }

  @override
  void onClose() {
    if (_noteListener != null) {
      noteForDriverController.removeListener(_noteListener!);
    }
    noteForDriverController.dispose();
    mapController = null;
    super.onClose();
  }

  void _bootstrapFromRoute() {
    final raw = Get.arguments;
    final args = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    final showPreviousPointMarker =
        args['showPreviousPointMarker'] as bool? ?? true;
    final showRouteCircles = args['showRouteCircles'] as bool? ?? true;

    final route = Get.currentRoute;
    if (route == AppRoutes.confirmPickup) {
      _flow = 'ride_pickup';
      _forceRefreshActiveRides = args['forceRefreshActiveRides'] == true;
      uiConfig = ConfirmLocationUiConfig.ridePickup(
        showPreviousPointMarker: showPreviousPointMarker,
        showRouteCircles: showRouteCircles,
      );
      final lat = (args['pickupLat'] as num?)?.toDouble() ?? -6.7924;
      final lng = (args['pickupLng'] as num?)?.toDouble() ?? 39.2083;
      _setLocation(
        lat: lat,
        lng: lng,
        initialAddress:
            (args['pickupAddress'] as String?)?.trim() ??
            'Selected pickup point',
      );
      return;
    }

    if (route == AppRoutes.confirmStop) {
      _flow = 'stop';
      final isDestination = args['isSelectingDestination'] == true;
      uiConfig = isDestination
          ? ConfirmLocationUiConfig.destination(
              showPreviousPointMarker: showPreviousPointMarker,
              showRouteCircles: showRouteCircles,
            )
          : ConfirmLocationUiConfig.stop(
              showPreviousPointMarker: showPreviousPointMarker,
              showRouteCircles: showRouteCircles,
            );
      _setLocation(
        lat: (args['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (args['lng'] as num?)?.toDouble() ?? 0.0,
        initialAddress: (args['address'] as String?)?.trim() ?? '',
      );
      return;
    }

    _flow = 'saved_place';
    uiConfig = ConfirmLocationUiConfig.savedPlacePickup(
      showPreviousPointMarker: showPreviousPointMarker,
      showRouteCircles: showRouteCircles,
    );
    _savedPlaceLabel = (args['label'] as String?)?.trim().isNotEmpty == true
        ? (args['label'] as String).trim()
        : AppStrings.homeLabel.tr;
    final title = (args['title'] as String?)?.trim() ?? '';
    final subtitle = (args['subtitle'] as String?)?.trim() ?? '';
    _setLocation(
      lat:
          (args['lat'] as num?)?.toDouble() ??
          homeController.mapCenter.value.latitude,
      lng:
          (args['lng'] as num?)?.toDouble() ??
          homeController.mapCenter.value.longitude,
      initialAddress: subtitle.isNotEmpty ? subtitle : title,
    );
  }

  void _setLocation({
    required double lat,
    required double lng,
    required String initialAddress,
  }) {
    _initialLatLng = LatLng(lat, lng);
    selectedLatLng.value = _initialLatLng;
    address.value = initialAddress;
    isMapReady.value = false;
    isNoteExpanded.value = false;
    isResolvingAddress.value = false;
    isSubmitting.value = false;
    mapController = null;
    _cameraSyncGeneration++;
  }

  void toggleNoteExpanded() {
    isNoteExpanded.value = !isNoteExpanded.value;
    if (!isNoteExpanded.value) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  Future<void> onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    final generation = _cameraSyncGeneration;
    await _syncCameraToInitial(generation: generation);
    if (!isClosed && generation == _cameraSyncGeneration) {
      isMapReady.value = true;
    }
  }

  Future<void> _syncCameraToInitial({
    required int generation,
    int attempt = 0,
  }) async {
    final ctrl = mapController;
    if (ctrl == null || isClosed || generation != _cameraSyncGeneration) {
      return;
    }

    await SchedulerBinding.instance.endOfFrame;
    if (attempt > 0) {
      await Future<void>.delayed(Duration(milliseconds: 50 * attempt));
    }

    try {
      await ctrl.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _initialLatLng, zoom: 16),
        ),
      );
      selectedLatLng.value = _initialLatLng;
    } catch (_) {
      if (attempt < 3 && generation == _cameraSyncGeneration) {
        await _syncCameraToInitial(generation: generation, attempt: attempt + 1);
      }
    }
  }

  void onCameraMove(CameraPosition position) {
    selectedLatLng.value = position.target;
    if (!uiConfig.showRouteCircles) return;
    routeCircles.value = _buildRouteCircles(
      from: _initialLatLng,
      to: position.target,
    );
  }

  Set<Circle> _buildRouteCircles({required LatLng from, required LatLng to}) {
    final circles = <Circle>{};

    final latDiff = (to.latitude - from.latitude).abs();
    final lngDiff = (to.longitude - from.longitude).abs();
    final hasMoved = latDiff > 0.000001 || lngDiff > 0.000001;
    if (!hasMoved) return circles;

    final approxDistanceMeters = (latDiff + lngDiff) * 111000;
    final dotCount = (approxDistanceMeters / 24).clamp(6, 28).round();
    for (var i = 1; i < dotCount; i++) {
      final t = i / dotCount;
      circles.add(
        Circle(
          circleId: CircleId('confirm_location_route_dot_$i'),
          center: LatLng(
            from.latitude + (to.latitude - from.latitude) * t,
            from.longitude + (to.longitude - from.longitude) * t,
          ),
          radius: 5,
          fillColor: AppColors.primary.withValues(alpha: 0.95),
          strokeColor: AppColors.primary.withValues(alpha: 0.95),
          strokeWidth: 1,
        ),
      );
    }
    return circles;
  }

  Future<void> onCameraIdle() async {
    if (!hasMovedFromInitial) return;

    final lat = selectedLatLng.value.latitude;
    final lng = selectedLatLng.value.longitude;
    isResolvingAddress.value = true;
    final result = await homeRepository.reverseGeocode(lat: lat, lng: lng);
    isResolvingAddress.value = false;

    result.fold((_) {}, (data) {
      if (data == null) return;
      final results = data.data?.results;
      final nextAddress = (results != null && results.isNotEmpty)
          ? results.first.formattedAddress
          : null;
      if (nextAddress != null && nextAddress.trim().isNotEmpty) {
        address.value = nextAddress.trim();
      }
    });
  }

  Future<void> onConfirm() async {
    if (_flow == 'saved_place') {
      await _confirmSavedPlace();
      return;
    }

    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      if (_flow == 'ride_pickup') {
        await _confirmRidePickup();
      } else {
        _confirmStop();
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Pickup confirm: resolves book-for-self vs book-for-other (see
  /// [BookForOtherPromptPolicy] for the full flow diagram).
  Future<void> _confirmRidePickup() async {
    final decision = await _resolveBookForOtherPromptDecision();
    switch (decision.action) {
      case BookForOtherPromptAction.selfOnly:
        // No sheet — return pickup with `isBookedForOther: false`.
        _finishAsSelfBooking();
      case BookForOtherPromptAction.showChoiceSheet:
        // Distance API passed; both self and other slots available.
        await _finishWithBookingPrompt();
      case BookForOtherPromptAction.showOtherOnlySheet:
        // Self ride already active — choice sheet with "for someone else" only.
        await _finishWithOtherOnlyBooking();
      case BookForOtherPromptAction.blocked:
        final activeRides = await _loadActiveRidesForBookForOtherPolicy();
        AppDialogs.showErrorDialog(
          message: hasSelfActiveRide(activeRides)
              ? AppStrings.youAlreadyHaveAnActiveRide.tr
              : AppStrings.bookedForOtherLimitReached.tr,
        );
    }
  }

  void _confirmStop() {
    Get.back(
      result: {
        'address': address.value.trim(),
        'lat': selectedLatLng.value.latitude,
        'lng': selectedLatLng.value.longitude,
      },
    );
  }

  Future<void> _confirmSavedPlace() async {
    final full = address.value.trim();
    final title = full.split(',').first.trim();
    final subtitle = full;
    await _showSavedPlaceDialog(
      title: title,
      subtitle: subtitle,
      onConfirm: () async {
        final resolvedAddress = subtitle.isNotEmpty ? subtitle : title;
        await homeController.saveAddressFromAddress(
          address: resolvedAddress,
          label: _savedPlaceLabel,
          lat: selectedLatLng.value.latitude,
          lng: selectedLatLng.value.longitude,
        );
        Get.until(
          (route) =>
              route.settings.name == AppRoutes.locationSelection ||
              route.settings.name == AppRoutes.home ||
              route.isFirst,
        );
      },
    );
  }

  /// Book-for-other gate on pickup confirm.
  ///
  /// See `docs/flows/book-for-other-pickup-flow.md` and [BookForOtherPromptPolicy].
  Future<BookForOtherPromptDecision> _resolveBookForOtherPromptDecision() async {
    final settingsService = di.sl<AppSettingsService>();
    await settingsService.preload();

    if (!settingsService.bookForOtherEnabled) {
      return BookForOtherPromptDecision.selfOnly;
    }

    final activeRides = await _loadActiveRidesForBookForOtherPolicy();
    final maxActive = settingsService.maxActiveBookForOtherRides;

    // Rider already on a self ride — any new booking must be for someone else.
    // Skip distance check; show choice sheet with only the "other" row.
    if (hasSelfActiveRide(activeRides) &&
        countBookedForOtherRides(activeRides) < maxActive) {
      return const BookForOtherPromptDecision(
        action: BookForOtherPromptAction.showOtherOnlySheet,
      );
    }

    // Pickup distance gate — only blocks the sheet when API explicitly says
    // pickup is near the rider. When GPS is off, skip this gate.
    final bookModeGate = await _resolveCheckBookModeGate();
    if (bookModeGate == CheckBookModeGate.pickupNearRider) {
      return BookForOtherPromptDecision.selfOnly;
    }

    return BookForOtherPromptPolicy.evaluate(
      maxActiveBookForOther: maxActive,
      activeRides: activeRides,
    );
  }

  /// `GET go/check-book-mode` when GPS works; [CheckBookModeGate.unavailable] otherwise.
  Future<CheckBookModeGate> _resolveCheckBookModeGate() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();
    final hasLocationPermission =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    if (!serviceEnabled || !hasLocationPermission) {
      return CheckBookModeGate.unavailable;
    }

    try {
      final position = await Loader.run(
        () => Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        ).timeout(const Duration(seconds: 5)),
      );

      final pickup = selectedLatLng.value;
      final checkResult = await Loader.run(
        () => rideRepository.checkBookMode(
          riderLat: position.latitude,
          riderLng: position.longitude,
          pickupLat: pickup.latitude,
          pickupLng: pickup.longitude,
        ),
      );

      return checkResult.fold(
        (_) => CheckBookModeGate.unavailable,
        (result) => result.showBookForOtherOption
            ? CheckBookModeGate.pickupFarFromRider
            : CheckBookModeGate.pickupNearRider,
      );
    } catch (_) {
      return CheckBookModeGate.unavailable;
    }
  }

  /// Prefer Home cache; refresh from API when empty or [Search again] after timeout.
  Future<List<RideModel>> _loadActiveRidesForBookForOtherPolicy() async {
    if (_forceRefreshActiveRides) {
      if (Get.isRegistered<HomeController>()) {
        await homeController.refreshActiveRide(force: true);
        return homeController.activeRides.toList(growable: false);
      }
      final activeResult = await rideRepository.getActiveRide();
      return activeResult.fold(
        (_) => const <RideModel>[],
        (response) => parseActiveRidesFromResponse(response?.data),
      );
    }

    final cached = homeController.activeRides.toList(growable: false);
    if (cached.isNotEmpty) return cached;

    final activeResult = await rideRepository.getActiveRide();
    return activeResult.fold(
      (_) => const <RideModel>[],
      (response) => parseActiveRidesFromResponse(response?.data),
    );
  }

  /// Both options on the choice step (check-book-mode passed, no self ride).
  Future<void> _finishWithBookingPrompt() async {
    final result = await BookingForSomeoneElseFlowBottomSheet.show();
    if (result == null) return;

    final mode = result['mode'] as BookingMode;
    final isBookedForOther = mode == BookingMode.other;

    Get.back(
      result: _buildPickupResult(
        isBookedForOther: isBookedForOther,
        bookingResult: result,
      ),
    );
  }

  /// Choice step with only "For someone else" — user taps through to details.
  Future<void> _finishWithOtherOnlyBooking() async {
    final result = await BookingForSomeoneElseFlowBottomSheet.show(
      showSelfOption: false,
      showOtherOption: true,
    );
    if (result == null) return;

    Get.back(
      result: _buildPickupResult(
        isBookedForOther: true,
        bookingResult: result,
      ),
    );
  }

  void _finishAsSelfBooking() {
    Get.back(
      result: _buildPickupResult(isBookedForOther: false, bookingResult: null),
    );
  }

  Map<String, dynamic> _buildPickupResult({
    required bool isBookedForOther,
    Map<String, dynamic>? bookingResult,
  }) {
    return {
      'pickupLat': selectedLatLng.value.latitude,
      'pickupLng': selectedLatLng.value.longitude,
      'pickupAddress': address.value.trim().isEmpty
          ? 'Selected pickup point'
          : address.value.trim(),
      'note': noteForDriverController.text.trim(),
      'isBookedForOther': isBookedForOther,
      'passengerName': isBookedForOther
          ? (bookingResult?['name'] as String?)?.trim()
          : null,
      'passengerPhone': isBookedForOther && bookingResult != null
          ? bookingResult['phone'] as String?
          : null,
    };
  }

  Future<void> _showSavedPlaceDialog({
    required String title,
    required String subtitle,
    required Future<void> Function() onConfirm,
  }) async {
    final dialogRadius = 28.r;
    await AppDialogs.showAnimatedDialog(
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dialogRadius),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(dialogRadius),
          child: Container(
            color: AppColors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PaymentSuccessDialogHeader(
                  headerHeight: 172.h,
                  centerChild: Align(
                    alignment: const Alignment(0, -0.07),
                    child: Container(
                      width: 76.w,
                      height: 76.w,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.38),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: AppColors.white,
                        size: 42.sp,
                      ),
                    ),
                  ),
                  overlay: Positioned(
                    left: 0,
                    right: 0,
                    top: 100.h,
                    child: Center(
                      child: Transform.rotate(
                        angle: _savedPlaceChipTiltRadians,
                        alignment: Alignment.center,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.black.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(13.76.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _savedPlaceDialogChipIcon(),
                                SizedBox(width: 5.w),
                                Text(
                                  _savedPlaceLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.homeCaption.copyWith(
                                    fontSize: 16.06.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textHeading,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 22.h, 24.w, 24.h),
                  child: Column(
                    children: [
                      Text(
                        AppStrings.areYouSureYouWantToAddThisAddressAs.trParams({
                          'phrase':
                              SavedPlaceConfirmationCopy.phraseAsIndefiniteNoun(
                                _savedPlaceLabel,
                              ),
                        }),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.homeTitle.copyWith(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHeading,
                          height: 34 / 20,
                          letterSpacing: -0.4,
                        ),
                      ),
                      SizedBox(height: 18.34.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: AppColors.bgSoftCircle,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SvgPictureAsset(
                                  AppAssets.locationIcPickupPin,
                                  width: 16.w,
                                  height: 16.w,
                                  color: AppColors.textError,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  title,
                                  style: AppTextStyles.homeSubtitle.copyWith(
                                    color: AppColors.textHeading,
                                    height: 20 / 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            SizedBox(height: 4.w),
                            Text(
                              subtitle,
                              style: AppTextStyles.homeCaption.copyWith(
                                color: AppColors.textBody,
                                fontSize: 12.sp,
                                height: 20 / 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      const Divider(color: AppColors.divider, thickness: 1),
                      SizedBox(height: 15.5.h),
                      SizedBox(
                        width: double.infinity,
                        height: 52.h,
                        child: Obx(
                          () => AppPrimaryButton(
                            label: AppStrings.yes.tr,
                            height: 52.h,
                            borderRadius: 26.r,
                            isLoading: homeController.isSavingPlace.value,
                            onPressed: homeController.isSavingPlace.value
                                ? null
                                : () async {
                                    await onConfirm();
                                  },
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      SizedBox(
                        width: double.infinity,
                        height: 52.h,
                        child: Obx(
                          () => AppPrimaryButton(
                            label: AppStrings.changeLocation.tr,
                            height: 52.h,
                            borderRadius: 26.r,
                            outlined: true,
                            backgroundColor: AppColors.white,
                            textColor: AppColors.textBody,
                            outlinedTextColor: AppColors.textBody,
                            outlinedBorderColor: AppColors.bgSoftCircle,
                            outlinedBorderWidth: 1,
                            onPressed: homeController.isSavingPlace.value
                                ? null
                                : () => Get.back(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _savedPlaceDialogChipIcon() {
    final asset = FavoriteLocationChipCatalog.chipIconAssetForDisplayLabel(
      _savedPlaceLabel,
    );

    return Container(
      width: 20.w,
      height: 20.w,
      padding: EdgeInsets.all(2.w),
      alignment: Alignment.center,
      child: SvgPictureAsset(
        asset,
        width: 20.w,
        height: 20.w,
        fit: BoxFit.contain,
        alignment: Alignment.center,
      ),
    );
  }
}
