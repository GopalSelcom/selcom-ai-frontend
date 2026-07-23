import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../ride/data/models/recent_destinations_response.dart';
import '../../data/models/places_models.dart';
import 'home_controller.dart';

class SelectSavedLocationController extends GetxController {
  SelectSavedLocationController({required this.homeController});

  final HomeController homeController;

  late final TextEditingController searchController;
  late final String label;
  late final Map<String, dynamic> _routeArgs;

  final isGeocoding = false.obs;

  bool get isSelectingStop => _routeArgs['isSelectingStop'] == true;

  bool get isSelectingDestination => _routeArgs['isSelectingDestination'] == true;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      _routeArgs = Map<String, dynamic>.from(args);
      label = _routeArgs['label']?.toString() ?? AppStrings.searchLocation.tr;
    } else {
      _routeArgs = <String, dynamic>{};
      label = args as String? ?? AppStrings.homeLabel.tr;
    }
    searchController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      homeController.searchQuery.value = '';
      homeController.suggestions.clear();
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void onSearchChanged(String value) {
    homeController.searchQuery.value = value;
  }

  void clearSearch() {
    searchController.clear();
    homeController.searchQuery.value = '';
    homeController.suggestions.clear();
  }

  Future<void> handleLocationSelection(Prediction item) async {
    final title = item.description?.split(',').first ?? label;
    final subtitle = item.description ?? '';

    if (isSelectingStop) {
      if (isGeocoding.value) return;
      isGeocoding.value = true;
      try {
        final latLng = await homeController.getLatLngFromAddress(subtitle);
        isGeocoding.value = false;

        if (latLng != null) {
          final result = await Get.toNamed(
            AppRoutes.confirmStop,
            arguments: {
              'address': subtitle,
              'lat': latLng.latitude,
              'lng': latLng.longitude,
              if (isSelectingDestination) 'isSelectingDestination': true,
            },
          );
          if (result != null) {
            Get.back(result: result);
          }
        } else {
          AppDialogs.showErrorDialog(
            message: AppStrings.unableToGetLocationCoordinates.tr,
          );
        }
      } catch (_) {
        isGeocoding.value = false;
        AppDialogs.showErrorDialog(
          message: AppStrings.anUnexpectedErrorOccurred.tr,
        );
      }
      return;
    }

    final latLng = await homeController.getLatLngFromAddress(subtitle);

    Get.toNamed(
      AppRoutes.checkPickupPoint,
      arguments: {
        'label': label,
        'title': title,
        'subtitle': subtitle,
        'placeId': item.placeId ?? '',
        if (latLng != null) 'lat': latLng.latitude,
        if (latLng != null) 'lng': latLng.longitude,
      },
    );
  }

  Future<void> handleRecentSelection(RecentDestination loc) async {
    final address = loc.address ?? '';
    final title = address.split(',').first;
    final subtitle = address;

    if (isSelectingStop) {
      final result = await Get.toNamed(
        AppRoutes.confirmStop,
        arguments: {
          'address': subtitle,
          'lat': loc.lat,
          'lng': loc.lng,
          if (isSelectingDestination) 'isSelectingDestination': true,
        },
      );
      if (result != null) {
        Get.back(result: result);
      }
      return;
    }

    Get.toNamed(
      AppRoutes.checkPickupPoint,
      arguments: {
        'label': label,
        'title': title,
        'subtitle': subtitle,
        'placeId': '',
        'lat': loc.lat,
        'lng': loc.lng,
      },
    );
  }
}
