import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/data/models/responses/get_saved_places_response.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/domain/entities/location_entity.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../ride/data/models/recent_destinations_response.dart';
import '../../data/models/places_models.dart';
import '../controllers/home_controller.dart';

class LocationSelectionController extends GetxController {
  LocationSelectionController();

  bool _isDisposed = false;

  late final TextEditingController pickupController;
  late final TextEditingController destinationController;
  late final FocusNode pickupFocusNode;
  late final FocusNode destinationFocusNode;

  /// 0 = pickup, 1 = first destination, 2+ = extra stop index `segment - 2`.
  final RxInt activeSegmentIndex = 0.obs;
  final extraDestinationControllers = <TextEditingController>[].obs;
  final extraDestinationFocusNodes = <FocusNode>[].obs;

  /// Parallel to [extraDestinationControllers]: user picked a place (suggestion /
  /// recent / saved) for that row. Typing clears the matching index.
  final extraStopSelected = <bool>[].obs;
  final RxBool pickupEditedByUser = false.obs;
  final RxnString destinationPlaceId = RxnString();
  final RxnDouble routePickupLat = RxnDouble();
  final RxnDouble routePickupLng = RxnDouble();
  final RxnDouble routeDestinationLat = RxnDouble();
  final RxnDouble routeDestinationLng = RxnDouble();
  final RxnString preferredVehicleTypeId = RxnString();
  final RxnString preferredVehicleName = RxnString();
  final RxBool isVehicleSelectionEditMode = false.obs;
  final RxBool isReorderingRows = false.obs;

  /// True while saved places / recents refresh for this screen.
  final isLoadingInitialContent = true.obs;

  HomeController get homeController => Get.find<HomeController>();

  /// From `/go/settings` → `features.max_stops` (excludes final destination).
  int get maxIntermediateStops => di.sl<AppSettingsService>().maxIntermediateStops;

  bool get shouldShowPlaceListShimmer =>
      isLoadingInitialContent.value || homeController.isLoadingHomeData.value;

  bool get hasIntermediateStops => extraDestinationControllers.isNotEmpty;

  int get totalRouteRows => extraDestinationControllers.length + 2;

  int segmentIndexForRowIndex(int rowIndex) {
    final last = totalRouteRows - 1;
    if (rowIndex <= 0) return 0;
    if (rowIndex >= last) return 1;
    return 2 + (rowIndex - 1);
  }

  int rowIndexForSegmentIndex(int segmentIndex) {
    final last = totalRouteRows - 1;
    if (segmentIndex <= 0) return 0;
    if (segmentIndex == 1) return last;
    return (segmentIndex - 2) + 1;
  }

  List<_RouteRowDraft> _buildOrderedRows() {
    final rows = <_RouteRowDraft>[
      _RouteRowDraft(
        text: pickupController.text,
        selected: homeController.isPickupSelected.value,
        lat: routePickupLat.value,
        lng: routePickupLng.value,
      ),
    ];

    for (var i = 0; i < extraDestinationControllers.length; i++) {
      rows.add(
        _RouteRowDraft(
          text: extraDestinationControllers[i].text,
          selected: i < extraStopSelected.length ? extraStopSelected[i] : false,
        ),
      );
    }

    rows.add(
      _RouteRowDraft(
        text: destinationController.text,
        selected: homeController.isDestinationSelected.value,
        lat: routeDestinationLat.value,
        lng: routeDestinationLng.value,
        placeId: destinationPlaceId.value,
      ),
    );

    return rows;
  }

  void _applyOrderedRows(List<_RouteRowDraft> rows) {
    if (rows.length < 2) return;
    final middle = rows.length - 2;

    pickupController.text = rows.first.text;
    destinationController.text = rows.last.text;

    routePickupLat.value = rows.first.lat;
    routePickupLng.value = rows.first.lng;
    routeDestinationLat.value = rows.last.lat;
    routeDestinationLng.value = rows.last.lng;
    destinationPlaceId.value = rows.last.placeId;

    while (extraDestinationControllers.length > middle) {
      extraDestinationControllers.removeLast().dispose();
      extraDestinationFocusNodes.removeLast().dispose();
      if (extraStopSelected.isNotEmpty) {
        extraStopSelected.removeLast();
      }
    }
    while (extraDestinationControllers.length < middle) {
      extraDestinationControllers.add(TextEditingController());
      extraDestinationFocusNodes.add(FocusNode());
      extraStopSelected.add(false);
    }

    for (var i = 0; i < middle; i++) {
      final row = rows[i + 1];
      extraDestinationControllers[i].text = row.text;
      if (i < extraStopSelected.length) {
        extraStopSelected[i] = row.selected;
      }
    }
    extraStopSelected.refresh();

    homeController.isPickupSelected.value = rows.first.selected;
    homeController.isDestinationSelected.value = rows.last.selected;
    pickupEditedByUser.value = true;
  }

  List<Object?> exportOrderedRowsForReorder() => _buildOrderedRows();

  void applyOrderedRowsFromReorder(List<Object?> rows) {
    _applyOrderedRows(rows.cast<_RouteRowDraft>());
  }

  bool get _isPickupSegmentReady {
    final text = pickupController.text.trim();
    if (text.isEmpty || homeController.isNonSelectableMapAddress(text)) {
      return false;
    }
    if (homeController.isPickupSelected.value) return true;
    return routePickupLat.value != null && routePickupLng.value != null;
  }

  bool get _isDestinationSegmentReady {
    final text = destinationController.text.trim();
    if (text.isEmpty) return false;
    if (homeController.isDestinationSelected.value) return true;
    return routeDestinationLat.value != null &&
        routeDestinationLng.value != null;
  }

  bool _isExtraStopReady(int index) {
    if (index < 0 || index >= extraDestinationControllers.length) {
      return false;
    }
    final text = extraDestinationControllers[index].text.trim();
    if (text.isEmpty) return false;
    return index < extraStopSelected.length && extraStopSelected[index];
  }

  /// Visual order: pickup → intermediate stops → final destination.
  /// Returns null when every segment is confirmed.
  int? firstIncompleteSegmentInVisualOrder() {
    if (!_isPickupSegmentReady) return 0;
    for (var i = 0; i < extraDestinationControllers.length; i++) {
      if (!_isExtraStopReady(i)) return 2 + i;
    }
    if (!_isDestinationSegmentReady) return 1;
    return null;
  }

  /// Pickup + final destination + every intermediate row (if any) confirmed from search/recent/saved.
  bool get areAllSegmentsReadyForBooking {
    return firstIncompleteSegmentInVisualOrder() == null;
  }

  void confirmSelectionForSegment(int segmentIndex) {
    if (segmentIndex == 0) {
      homeController.isPickupSelected.value = true;
    } else if (segmentIndex == 1) {
      homeController.isDestinationSelected.value = true;
    } else {
      final i = segmentIndex - 2;
      if (i >= 0 && i < extraStopSelected.length) {
        extraStopSelected[i] = true;
        extraStopSelected.refresh();
      }
    }
    focusNextEmptyOrUnfocus();
    _scheduleAutoProceedIfAllSegmentsReady();
  }

  /// After a place is chosen (or on open): focus the next empty field, or close
  /// the keyboard when the route is complete.
  void focusNextEmptyOrUnfocus({bool immediate = false}) {
    if (_isDisposed) return;
    final next = firstIncompleteSegmentInVisualOrder();
    if (next == null) {
      unfocusAllLocationFields();
      homeController.searchQuery.value = '';
      return;
    }
    activeSegmentIndex.value = next;
    _syncSearchQueryForActiveSegment();
    focusActiveSegment(immediate: immediate);
  }

  void _syncSearchQueryForActiveSegment() {
    final seg = activeSegmentIndex.value;
    if (seg == 0) {
      homeController.searchQuery.value = pickupController.text.trim();
      return;
    }
    if (seg == 1) {
      homeController.searchQuery.value = destinationController.text.trim();
      return;
    }
    final i = seg - 2;
    if (i >= 0 && i < extraDestinationControllers.length) {
      homeController.searchQuery.value =
          extraDestinationControllers[i].text.trim();
    } else {
      homeController.searchQuery.value = '';
    }
  }

  void _scheduleAutoProceedIfAllSegmentsReady() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed) return;
      if (!areAllSegmentsReadyForBooking) return;
      unawaited(proceedWithBooking());
    });
  }

  Future<void> proceedWithBooking() async {
    if (!areAllSegmentsReadyForBooking) return;
    if (homeController.isProceedingToBooking.value) return;

    final destinations = <String>[];
    for (final c in extraDestinationControllers) {
      final t = c.text.trim();
      if (t.isNotEmpty) destinations.add(t);
    }
    final finalDestination = destinationController.text.trim();
    if (finalDestination.isNotEmpty) {
      destinations.add(finalDestination);
    }

    if (isVehicleSelectionEditMode.value) {
      EstimateValidationOutcome? validationFailure;
      Map<String, dynamic>? payload;
      homeController.isProceedingToBooking.value = true;
      try {
        payload = await Loader.run(() async {
          final built = await buildVehicleSelectionEditResult(
            pickupText: pickupController.text.trim(),
            destinationTexts: destinations,
          );
          if (built == null) return null;

          final destEntities = _locationEntitiesFromEditPayload(built);
          if (destEntities.isEmpty) return null;

          final validation = await homeController.validateEstimateForRoute(
            pickupAddress: (built['pickup'] as String?)?.trim() ?? '',
            pickupLat: (built['pickupLat'] as num).toDouble(),
            pickupLng: (built['pickupLng'] as num).toDouble(),
            destination: destEntities.last,
            stops: destEntities.length > 1
                ? destEntities.sublist(0, destEntities.length - 1)
                : const [],
          );
          if (!validation.canProceed) {
            validationFailure = validation;
            return null;
          }
          if (validation.estimate != null) {
            built['initialFareEstimate'] = validation.estimate;
            built['initialFareEstimateAt'] = validation.estimatedAt;
          }
          return built;
        });
      } finally {
        homeController.isProceedingToBooking.value = false;
      }

      if (validationFailure != null) {
        await homeController.presentEstimateValidationError(validationFailure!);
        return;
      }
      if (payload == null) {
        AppDialogs.showErrorDialog(
          message: AppStrings.pleaseSelectValidPickupAndDestinationLocations.tr,
        );
        return;
      }
      Get.back(result: payload);
      return;
    }

    await homeController.proceedToBookingFromLocationSelection(
      pickup: pickupController.text.trim(),
      destinations: destinations,
      destinationPlaceId: destinationPlaceId.value,
      routePickupLat: routePickupLat.value,
      routePickupLng: routePickupLng.value,
      routeDestinationLat: routeDestinationLat.value,
      routeDestinationLng: routeDestinationLng.value,
      preferredVehicleTypeId: preferredVehicleTypeId.value,
      preferredVehicleName: preferredVehicleName.value,
    );
  }

  Future<Map<String, dynamic>?> buildVehicleSelectionEditResult({
    required String pickupText,
    required List<String> destinationTexts,
  }) async {
    final cleanedDestinations = destinationTexts
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (pickupText.isEmpty || cleanedDestinations.isEmpty) return null;

    final pickupLatLng =
        (routePickupLat.value != null && routePickupLng.value != null)
        ? null
        : await homeController.getLatLngFromAddress(pickupText);
    final pickupLat = routePickupLat.value ?? pickupLatLng?.latitude;
    final pickupLng = routePickupLng.value ?? pickupLatLng?.longitude;
    if (pickupLat == null || pickupLng == null) return null;

    final resultDestinations = <Map<String, dynamic>>[];
    for (var i = 0; i < cleanedDestinations.length; i++) {
      final text = cleanedDestinations[i];
      double? lat;
      double? lng;
      if (i == cleanedDestinations.length - 1) {
        lat = routeDestinationLat.value;
        lng = routeDestinationLng.value;
      }
      if (lat == null || lng == null) {
        final resolved = await homeController.getLatLngFromAddress(text);
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

  List<LocationEntity> _locationEntitiesFromEditPayload(
    Map<String, dynamic> payload,
  ) {
    final rawDestinations = payload['destinations'];
    if (rawDestinations is! List) return const [];

    final entities = <LocationEntity>[];
    for (final item in rawDestinations) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final lat = (map['lat'] as num?)?.toDouble();
      final lng = (map['lng'] as num?)?.toDouble();
      final address = (map['address'] as String?)?.trim() ?? '';
      if (lat == null || lng == null || address.isEmpty) continue;
      entities.add(LocationEntity(lat: lat, lng: lng, address: address));
    }
    return entities;
  }

  void markExtraStopUnconfirmed(int index) {
    if (index >= 0 && index < extraStopSelected.length) {
      extraStopSelected[index] = false;
      extraStopSelected.refresh();
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Create field controllers before any await so the first Obx frame never
    // hits LateInitializationError while settings preload runs.
    pickupController = TextEditingController();
    destinationController = TextEditingController();
    pickupFocusNode = FocusNode();
    destinationFocusNode = FocusNode();
    unawaited(_init());
  }

  Future<void> _init() async {
    if (!di.sl<AppSettingsService>().isLoaded.value) {
      await di.sl<AppSettingsService>().preload();
    }
    if (_isDisposed) return;
    _initializeFromArguments();
    _loadInitialContent();
  }

  Future<void> _loadInitialContent() async {
    isLoadingInitialContent.value = true;
    try {
      while (homeController.isLoadingHomeData.value) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        if (_isDisposed) return;
      }

      // Home already fetched recent + saved in [_loadHomeData] — reuse that cache.
      if (homeController.hasCompletedInitialHomeLoad) {
        return;
      }

      // Fallback when Home never completed its initial load (rare race / cold path).
      await Future.wait<void>([
        homeController.reloadRecentDestinations(),
        homeController.loadSavedPlaces(),
      ]);
    } finally {
      if (!_isDisposed) {
        isLoadingInitialContent.value = false;
      }
    }
  }

  void _initializeFromArguments() {
    final raw = Get.arguments;
    String initialPickup = homeController.currentMapAddress.value;
    String initialDestination = '';
    var initialActiveSegment = 0;
    var clearPickupOnOpen = false;
    var clearDestinationOnOpen = false;
    final initialExtraStops = <String>[];
    isVehicleSelectionEditMode.value = false;

    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      isVehicleSelectionEditMode.value =
          (m['fromVehicleSelectionEdit'] as bool?) ?? false;
      final p = (m['pickup'] as String?)?.trim();
      if (p != null && p.isNotEmpty) {
        initialPickup = p;
        pickupEditedByUser.value = true;
      }
      final d = (m['destination'] as String?)?.trim();
      if (d != null && d.isNotEmpty) {
        initialDestination = d;
      }
      final rawDestinations = m['destinations'];
      if (rawDestinations is List && rawDestinations.isNotEmpty) {
        final cleaned = <Map<String, dynamic>>[];
        for (final item in rawDestinations) {
          if (item is Map<String, dynamic>) {
            cleaned.add(item);
          } else if (item is Map) {
            cleaned.add(Map<String, dynamic>.from(item));
          }
        }
        if (cleaned.isNotEmpty) {
          final finalDestination = cleaned.last;
          final finalAddress =
              (finalDestination['address'] as String?)?.trim() ?? '';
          if (finalAddress.isNotEmpty) {
            initialDestination = finalAddress;
          }
          final finalLat = (finalDestination['lat'] as num?)?.toDouble();
          final finalLng = (finalDestination['lng'] as num?)?.toDouble();
          if (finalLat != null && finalLng != null) {
            routeDestinationLat.value = finalLat;
            routeDestinationLng.value = finalLng;
          }
          for (final stop in cleaned.take(cleaned.length - 1)) {
            final stopAddress = (stop['address'] as String?)?.trim() ?? '';
            if (stopAddress.isNotEmpty) {
              initialExtraStops.add(stopAddress);
            }
          }
        }
      }
      final plat = (m['pickupLat'] as num?)?.toDouble();
      final plng = (m['pickupLng'] as num?)?.toDouble();
      if (plat != null && plng != null) {
        routePickupLat.value = plat;
        routePickupLng.value = plng;
      }
      final dlat = (m['destinationLat'] as num?)?.toDouble();
      final dlng = (m['destinationLng'] as num?)?.toDouble();
      if (dlat != null && dlng != null) {
        routeDestinationLat.value = dlat;
        routeDestinationLng.value = dlng;
      }
      final active = (m['activeSegmentIndex'] as num?)?.toInt();
      if (active != null && active >= 0) {
        initialActiveSegment = active;
      }
      clearPickupOnOpen = (m['clearPickupOnOpen'] as bool?) ?? false;
      clearDestinationOnOpen = (m['clearDestinationOnOpen'] as bool?) ?? false;
      preferredVehicleTypeId.value = (m['preferredVehicleTypeId'] as String?)
          ?.trim();
      preferredVehicleName.value = (m['preferredVehicleName'] as String?)
          ?.trim();
    }

    if (clearPickupOnOpen) {
      initialPickup = '';
      routePickupLat.value = null;
      routePickupLng.value = null;
      pickupEditedByUser.value = true;
    }
    if (clearDestinationOnOpen) {
      initialDestination = '';
      routeDestinationLat.value = null;
      routeDestinationLng.value = null;
      destinationPlaceId.value = null;
    }

    if (homeController.isNonSelectableMapAddress(initialPickup)) {
      initialPickup = '';
    }

    pickupController.text = initialPickup;
    destinationController.text = initialDestination;
    for (final stopAddress in initialExtraStops.take(maxIntermediateStops)) {
      extraDestinationControllers.add(TextEditingController(text: stopAddress));
      extraDestinationFocusNodes.add(FocusNode());
      extraStopSelected.add(true);
    }

    // Prefer first empty field (pickup → stops → destination). Fall back to
    // route-arg segment only when the route is already complete (e.g. edit).
    final firstIncomplete = firstIncompleteSegmentInVisualOrder();
    activeSegmentIndex.value = firstIncomplete ?? initialActiveSegment;

    if (routePickupLat.value != null && initialPickup.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        homeController.isPickupSelected.value = true;
      });
    }
    if (routeDestinationLat.value != null && initialDestination.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        homeController.isDestinationSelected.value = true;
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (_isDisposed) return;
        final stillIncomplete = firstIncompleteSegmentInVisualOrder();
        if (stillIncomplete != null) {
          activeSegmentIndex.value = stillIncomplete;
          _syncSearchQueryForActiveSegment();
          focusActiveSegment(immediate: true);
          return;
        }
        if (isVehicleSelectionEditMode.value) {
          _syncSearchQueryForActiveSegment();
          focusActiveSegment(immediate: true);
          return;
        }
        unfocusAllLocationFields();
        homeController.searchQuery.value = '';
      });
    });
  }

  /// One segment field should own focus. Clears other focus nodes to avoid multiple cursors.
  void focusActiveSegment({bool immediate = false}) {
    if (_isDisposed) return;

    void doFocus() {
      if (_isDisposed) return;
      final seg = activeSegmentIndex.value;
      if (seg == 0) {
        destinationFocusNode.unfocus();
        for (final n in extraDestinationFocusNodes.toList()) {
          n.unfocus();
        }
        pickupFocusNode.requestFocus();
      } else if (seg == 1) {
        pickupFocusNode.unfocus();
        for (final n in extraDestinationFocusNodes.toList()) {
          n.unfocus();
        }
        destinationFocusNode.requestFocus();
      } else {
        pickupFocusNode.unfocus();
        destinationFocusNode.unfocus();
        final targetIdx = seg - 2;
        for (var idx = 0; idx < extraDestinationFocusNodes.length; idx++) {
          if (idx != targetIdx) {
            extraDestinationFocusNodes[idx].unfocus();
          }
        }
        if (targetIdx >= 0 && targetIdx < extraDestinationFocusNodes.length) {
          extraDestinationFocusNodes[targetIdx].requestFocus();
        }
      }
    }

    if (immediate) {
      doFocus();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        doFocus();
      });
    }
  }

  void unfocusAllLocationFields() {
    FocusManager.instance.primaryFocus?.unfocus();
    pickupFocusNode.unfocus();
    destinationFocusNode.unfocus();
    for (final node in extraDestinationFocusNodes.toList()) {
      node.unfocus();
    }
  }

  void syncPickupFromLiveAddress() {
    if (pickupEditedByUser.value) return;
    final liveAddress = homeController.currentMapAddress.value.trim();
    if (homeController.isNonSelectableMapAddress(liveAddress)) {
      if (homeController.isNonSelectableMapAddress(pickupController.text)) {
        pickupController.clear();
      }
      return;
    }
    if (liveAddress.isNotEmpty) {
      pickupController.text = liveAddress;
    }
  }

  void onAddDestinationStop() {
    if (extraDestinationControllers.length >= maxIntermediateStops) {
      return;
    }
    extraDestinationControllers.add(TextEditingController());
    extraDestinationFocusNodes.add(FocusNode());
    extraStopSelected.add(false);
    activeSegmentIndex.value = 2 + extraDestinationControllers.length - 1;
    homeController.searchQuery.value = '';
    focusActiveSegment();
  }

  void setActiveSegment(int index) {
    if (activeSegmentIndex.value == index) return;
    activeSegmentIndex.value = index;
  }

  void onPickupFieldTapped() {
    final pickupText = pickupController.text.trim();
    if (homeController.isNonSelectableMapAddress(pickupText)) {
      pickupEditedByUser.value = true;
      pickupController.clear();
      routePickupLat.value = null;
      routePickupLng.value = null;
      homeController.isPickupSelected.value = false;
      homeController.searchQuery.value = '';
      return;
    }
    if (!pickupEditedByUser.value && pickupText.isNotEmpty) {
      pickupEditedByUser.value = true;
      pickupController.clear();
      routePickupLat.value = null;
      routePickupLng.value = null;
      homeController.isPickupSelected.value = false;
      homeController.searchQuery.value = '';
      return;
    }

    // Tap a pickup that was already chosen from search / saved — clear to pick again.
    if (homeController.isPickupSelected.value && pickupText.isNotEmpty) {
      pickupEditedByUser.value = true;
      pickupController.clear();
      routePickupLat.value = null;
      routePickupLng.value = null;
      homeController.isPickupSelected.value = false;
      homeController.searchQuery.value = '';
      return;
    }

    homeController.searchQuery.value = pickupText;
  }

  /// Tap final destination when it already has a confirmed place — clear to search again.
  void onDestinationFieldTapped() {
    final text = destinationController.text.trim();
    if (homeController.isDestinationSelected.value && text.isNotEmpty) {
      destinationController.clear();
      routeDestinationLat.value = null;
      routeDestinationLng.value = null;
      destinationPlaceId.value = null;
      homeController.isDestinationSelected.value = false;
      homeController.searchQuery.value = '';
      return;
    }
    homeController.searchQuery.value = text;
  }

  /// Tap an intermediate stop that already has a confirmed place — clear to search again.
  void onExtraStopFieldTapped(int index) {
    if (index < 0 || index >= extraDestinationControllers.length) return;
    final c = extraDestinationControllers[index];
    final text = c.text.trim();
    final confirmed =
        index < extraStopSelected.length && extraStopSelected[index];
    if (confirmed && text.isNotEmpty) {
      c.clear();
      extraStopSelected[index] = false;
      homeController.searchQuery.value = '';
      return;
    }
    homeController.searchQuery.value = text;
  }

  void openSelectSavedLocation(String canonical) {
    Get.toNamed(AppRoutes.selectSavedLocation, arguments: canonical);
  }

  void openSelectSavedLocationForSavedPlace(SavedPlace place) {
    final raw = (place.label ?? place.name ?? '').trim();
    Get.toNamed(
      AppRoutes.selectSavedLocation,
      arguments: raw.isEmpty ? AppStrings.saved.tr : raw,
    );
  }

  void onPresetChipTap(String canonical, SavedPlace? place) {
    if (place == null) {
      openSelectSavedLocation(canonical);
      return;
    }
    _applySavedPlaceChip(place);
  }

  void onPresetChipLongPress(String canonical) {
    openSelectSavedLocation(canonical);
  }

  void onExtraChipTap(SavedPlace place) {
    _applySavedPlaceChip(place);
  }

  void onExtraChipLongPress(SavedPlace place) {
    openSelectSavedLocationForSavedPlace(place);
  }

  void _applySavedPlaceChip(SavedPlace place) {
    final applied = homeController.applySavedPlaceToLocationSelection(
      savedPlace: place,
      activeSegmentIndex: activeSegmentIndex.value,
      pickupController: pickupController,
      destinationController: destinationController,
      extraDestinationControllers: extraDestinationControllers,
      pickupEditedByUser: pickupEditedByUser,
      routePickupLat: routePickupLat,
      routePickupLng: routePickupLng,
      routeDestinationLat: routeDestinationLat,
      routeDestinationLng: routeDestinationLng,
      destinationPlaceId: destinationPlaceId,
    );
    if (applied) {
      confirmSelectionForSegment(activeSegmentIndex.value);
    }
  }

  /// Confirm-stop flow when picking an intermediate stop from search.
  Future<void> handleStopSelection({
    required String address,
    required double lat,
    required double lng,
  }) async {
    final parentArgs = Get.arguments is Map
        ? Map<String, dynamic>.from(Get.arguments as Map)
        : <String, dynamic>{};
    final result = await Get.toNamed(
      AppRoutes.confirmStop,
      arguments: {
        'address': address,
        'lat': lat,
        'lng': lng,
        if (parentArgs['isSelectingDestination'] == true)
          'isSelectingDestination': true,
      },
    );
    if (result != null) {
      Get.back(result: result);
    }
  }

  /// True when this screen was opened to pick an intermediate stop (not route booking).
  bool get isSelectingStop {
    final raw = Get.arguments;
    return raw is Map && raw['isSelectingStop'] == true;
  }

  /// Geocode [address] then open confirm-stop. Keeps repository calls off the screen.
  Future<void> selectStopFromAddress(String address) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty || _isDisposed) return;

    AppDialogs.showLoadingDialog();
    try {
      final coords = await homeController.resolveAddressCoordinates(
        trimmed,
        onFailure: (message) {
          if (_isDisposed) return;
          AppDialogs.showErrorDialog(message: message);
        },
      );
      if (coords == null || _isDisposed) return;
      await handleStopSelection(
        address: trimmed,
        lat: coords.latitude,
        lng: coords.longitude,
      );
    } finally {
      AppDialogs.dismissLoadingDialog();
    }
  }

  Future<void> onSuggestionSelected(Prediction prediction) async {
    if (isSelectingStop) {
      await selectStopFromAddress(prediction.description ?? '');
      return;
    }
    homeController.applySuggestionToLocationSelection(
      prediction: prediction,
      activeSegmentIndex: activeSegmentIndex.value,
      pickupController: pickupController,
      destinationController: destinationController,
      extraDestinationControllers: extraDestinationControllers,
      pickupEditedByUser: pickupEditedByUser,
      routePickupLat: routePickupLat,
      routePickupLng: routePickupLng,
      routeDestinationLat: routeDestinationLat,
      routeDestinationLng: routeDestinationLng,
      destinationPlaceId: destinationPlaceId,
    );
    confirmSelectionForSegment(activeSegmentIndex.value);
  }

  Future<void> onRecentSearchSelected(String recentText) async {
    if (isSelectingStop) {
      await selectStopFromAddress(recentText);
      return;
    }
    homeController.applyRecentSearchToLocationSelection(
      recentText: recentText,
      activeSegmentIndex: activeSegmentIndex.value,
      pickupController: pickupController,
      destinationController: destinationController,
      extraDestinationControllers: extraDestinationControllers,
      pickupEditedByUser: pickupEditedByUser,
      routePickupLat: routePickupLat,
      routePickupLng: routePickupLng,
      routeDestinationLat: routeDestinationLat,
      routeDestinationLng: routeDestinationLng,
      destinationPlaceId: destinationPlaceId,
    );
    confirmSelectionForSegment(activeSegmentIndex.value);
  }

  Future<void> onSavedPlaceSelected(SavedPlace place) async {
    if (isSelectingStop) {
      await handleStopSelection(
        address: place.address ?? '',
        lat: place.lat ?? 0.0,
        lng: place.lng ?? 0.0,
      );
      return;
    }
    final applied = homeController.applySavedPlaceToLocationSelection(
      savedPlace: place,
      activeSegmentIndex: activeSegmentIndex.value,
      pickupController: pickupController,
      destinationController: destinationController,
      extraDestinationControllers: extraDestinationControllers,
      pickupEditedByUser: pickupEditedByUser,
      routePickupLat: routePickupLat,
      routePickupLng: routePickupLng,
      routeDestinationLat: routeDestinationLat,
      routeDestinationLng: routeDestinationLng,
      destinationPlaceId: destinationPlaceId,
    );
    if (applied) {
      confirmSelectionForSegment(activeSegmentIndex.value);
    }
  }

  Future<void> onRecentDestinationSelected(RecentDestination destination) async {
    if (isSelectingStop) {
      await handleStopSelection(
        address: destination.address ?? '',
        lat: destination.lat ?? 0,
        lng: destination.lng ?? 0,
      );
      return;
    }
    homeController.applyRecentDestinationToLocationSelection(
      destination: destination,
      activeSegmentIndex: activeSegmentIndex.value,
      pickupController: pickupController,
      destinationController: destinationController,
      extraDestinationControllers: extraDestinationControllers,
      pickupEditedByUser: pickupEditedByUser,
      routePickupLat: routePickupLat,
      routePickupLng: routePickupLng,
      routeDestinationLat: routeDestinationLat,
      routeDestinationLng: routeDestinationLng,
      destinationPlaceId: destinationPlaceId,
    );
    confirmSelectionForSegment(activeSegmentIndex.value);
  }

  @override
  void onClose() {
    _isDisposed = true;
    pickupController.dispose();
    destinationController.dispose();
    for (final c in extraDestinationControllers) {
      c.dispose();
    }
    for (final f in extraDestinationFocusNodes) {
      f.dispose();
    }
    extraStopSelected.clear();
    pickupFocusNode.dispose();
    destinationFocusNode.dispose();
    super.onClose();
  }
}

class _RouteRowDraft {
  _RouteRowDraft({
    required this.text,
    required this.selected,
    this.lat,
    this.lng,
    this.placeId,
  });

  String text;
  bool selected;
  double? lat;
  double? lng;
  String? placeId;
}
