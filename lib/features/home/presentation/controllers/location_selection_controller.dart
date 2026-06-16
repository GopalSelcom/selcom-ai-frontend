import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/ride_stop_limits.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/map_route_marker_utils.dart';
import '../controllers/home_controller.dart';

class LocationSelectionController extends GetxController {
  LocationSelectionController();

  bool _isDisposed = false;

  late final TextEditingController pickupController;
  late final TextEditingController destinationController;
  late final FocusNode pickupFocusNode;
  late final FocusNode destinationFocusNode;

  /// 0 = pickup, 1 = first destination, 2+ = extra stop index `segment - 2`.
  final RxInt activeSegmentIndex = 1.obs;
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

  /// True while saved places / recents refresh for this screen.
  final isLoadingInitialContent = true.obs;

  HomeController get homeController => Get.find<HomeController>();

  bool get shouldShowPlaceListShimmer =>
      isLoadingInitialContent.value || homeController.isLoadingHomeData.value;

  bool get hasIntermediateStops => extraDestinationControllers.isNotEmpty;

  ({String letter, Color color}) routeLetterStyleForPickup() {
    if (!hasIntermediateStops) {
      return (letter: 'P', color: AppColors.mapPickupMarkerBlue);
    }
    return (
      letter: MapRouteMarkerUtils.letterAt(0),
      color: AppColors.mapPickupMarkerBlue,
    );
  }

  ({String letter, Color color}) routeLetterStyleForIntermediateStop(
    int stopIndex,
  ) {
    return (
      letter: MapRouteMarkerUtils.letterAt(stopIndex + 1),
      color: AppColors.mapStopMarkerRed,
    );
  }

  ({String letter, Color color}) routeLetterStyleForDestination() {
    if (!hasIntermediateStops) {
      return (letter: 'D', color: AppColors.mapDropMarkerGreen);
    }
    return (
      letter: MapRouteMarkerUtils.letterAt(
        MapRouteMarkerUtils.destinationLetterIndex(
          intermediateStopCount: extraDestinationControllers.length,
        ),
      ),
      color: AppColors.mapDropMarkerGreen,
    );
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

  /// Pickup + final destination + every intermediate row (if any) confirmed from search/recent/saved.
  bool get areAllSegmentsReadyForBooking {
    if (!_isPickupSegmentReady) return false;
    if (!_isDestinationSegmentReady) return false;
    final n = extraDestinationControllers.length;
    if (extraStopSelected.length != n) return false;
    for (var i = 0; i < n; i++) {
      if (extraDestinationControllers[i].text.trim().isEmpty) return false;
      if (!extraStopSelected[i]) return false;
    }
    return true;
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
    _scheduleAutoProceedIfAllSegmentsReady();
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
      final payload = await buildVehicleSelectionEditResult(
        pickupText: pickupController.text.trim(),
        destinationTexts: destinations,
      );
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

  void markExtraStopUnconfirmed(int index) {
    if (index >= 0 && index < extraStopSelected.length) {
      extraStopSelected[index] = false;
      extraStopSelected.refresh();
    }
  }

  @override
  void onInit() {
    super.onInit();
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
      await Future.wait<void>([
        homeController.refreshRecentDestinations(),
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
    var initialActiveSegment = 1;
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

    pickupController = TextEditingController(text: initialPickup);
    destinationController = TextEditingController(text: initialDestination);
    pickupFocusNode = FocusNode();
    destinationFocusNode = FocusNode();
    for (final stopAddress in initialExtraStops.take(
      RideStopLimits.maxIntermediateStops,
    )) {
      extraDestinationControllers.add(TextEditingController(text: stopAddress));
      extraDestinationFocusNodes.add(FocusNode());
      extraStopSelected.add(true);
    }
    activeSegmentIndex.value = initialActiveSegment;

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
        if (!_isDisposed) {
          focusActiveSegment(immediate: true);
        }
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
    if (extraDestinationControllers.length >=
        RideStopLimits.maxIntermediateStops) {
      return;
    }
    extraDestinationControllers.add(TextEditingController());
    extraDestinationFocusNodes.add(FocusNode());
    extraStopSelected.add(false);
    activeSegmentIndex.value = 2 + extraDestinationControllers.length - 1;
    homeController.searchQuery.value = extraDestinationControllers.last.text
        .trim();
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
