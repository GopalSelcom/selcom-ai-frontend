import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/ride_stop_limits.dart';
import '../controllers/home_controller.dart';

class LocationSelectionController extends GetxController {
  LocationSelectionController();

  late final TextEditingController pickupController;
  late final TextEditingController destinationController;
  late final FocusNode pickupFocusNode;
  late final FocusNode destinationFocusNode;

  /// 0 = pickup, 1 = first destination, 2+ = extra stop index `segment - 2`.
  final RxInt activeSegmentIndex = 1.obs;
  final extraDestinationControllers = <TextEditingController>[].obs;
  final extraDestinationFocusNodes = <FocusNode>[].obs;
  final RxBool pickupEditedByUser = false.obs;
  final RxnString destinationPlaceId = RxnString();
  final RxnDouble routePickupLat = RxnDouble();
  final RxnDouble routePickupLng = RxnDouble();
  final RxnDouble routeDestinationLat = RxnDouble();
  final RxnDouble routeDestinationLng = RxnDouble();
  final RxnString preferredVehicleTypeId = RxnString();
  final RxnString preferredVehicleName = RxnString();
  final RxBool isVehicleSelectionEditMode = false.obs;

  HomeController get homeController => Get.find<HomeController>();

  @override
  void onInit() {
    super.onInit();
    _initializeFromArguments();
  }

  void _initializeFromArguments() {
    final raw = Get.arguments;
    String initialPickup = homeController.currentMapAddress.value;
    String initialDestination = '';
    var initialActiveSegment = 1;
    var clearPickupOnOpen = false;
    var clearDestinationOnOpen = false;
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
      preferredVehicleName.value = (m['preferredVehicleName'] as String?)?.trim();
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

    pickupController = TextEditingController(text: initialPickup);
    destinationController = TextEditingController(text: initialDestination);
    pickupFocusNode = FocusNode();
    destinationFocusNode = FocusNode();
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
      if (activeSegmentIndex.value == 0) {
        pickupFocusNode.requestFocus();
      } else {
        destinationFocusNode.requestFocus();
      }
    });
  }

  void syncPickupFromLiveAddress() {
    final liveAddress = homeController.currentMapAddress.value.trim();
    if (!pickupEditedByUser.value && liveAddress.isNotEmpty) {
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
    activeSegmentIndex.value = 2 + extraDestinationControllers.length - 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (extraDestinationFocusNodes.isEmpty) return;
      final node = extraDestinationFocusNodes.last;
      node.requestFocus();
      homeController.searchQuery.value =
          extraDestinationControllers.last.text.trim();
    });
  }

  void setActiveSegment(int index) {
    if (activeSegmentIndex.value == index) return;
    activeSegmentIndex.value = index;
  }

  void onPickupFieldTapped() {
    if (!pickupEditedByUser.value && pickupController.text.trim().isNotEmpty) {
      pickupEditedByUser.value = true;
      pickupController.clear();
      routePickupLat.value = null;
      routePickupLng.value = null;
      homeController.isPickupSelected.value = false;
      homeController.searchQuery.value = '';
      return;
    }

    homeController.searchQuery.value = pickupController.text.trim();
  }

  @override
  void onClose() {
    pickupController.dispose();
    destinationController.dispose();
    for (final c in extraDestinationControllers) {
      c.dispose();
    }
    for (final f in extraDestinationFocusNodes) {
      f.dispose();
    }
    pickupFocusNode.dispose();
    destinationFocusNode.dispose();
    super.onClose();
  }
}
