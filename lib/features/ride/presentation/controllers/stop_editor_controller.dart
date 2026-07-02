import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../../../core/domain/entities/ride_entity.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../shared/utils/app_dialogs.dart';
import 'driver_accepted_controller.dart';

/// Add-stops and change-drop editors opened from [DriverAcceptedScreen].
///
/// Route args: `ride` ([RideEntity]) and optional `editorMode: 'destination'`.
/// Stops flow uses preview → confirm via [DriverAcceptedController.stopUpdatePreview];
/// destination flow mirrors that with [DriverAcceptedController.destinationUpdatePreview].
class StopEditorController extends GetxController {
  DriverAcceptedController get driverController =>
      Get.find<DriverAcceptedController>();

  /// Working intermediate stops shown in the reorderable list.
  final stops = <RideStopEntity>[].obs;

  /// Stable keys per row: `confirmed_*` for server stops, `new_*` for drafts.
  /// Draft rows can be removed; confirmed stops cannot.
  final stopLocalKeys = <String>[].obs;
  final isSaving = false.obs;
  final selectedDestination = Rxn<Map<String, dynamic>>();

  late final bool isDestinationEditor;
  late List<RideStopEntity> _initialStops;
  int _newStopCounter = 0;

  @override
  void onInit() {
    super.onInit();
    driverController.stopUpdatePreview.value = null;
    driverController.destinationUpdatePreview.value = null;

    final args = Get.arguments is Map<String, dynamic>
        ? Map<String, dynamic>.from(Get.arguments as Map)
        : <String, dynamic>{};
    isDestinationEditor = args['editorMode'] == 'destination';
    final ride = args['ride'] as RideEntity?;
    final confirmedStops = driverController.mapIntermediateStops.isNotEmpty
        ? driverController.mapIntermediateStops
        : (ride?.stops ?? const <RideStopEntity>[]);

    if (driverController.stopUpdateWorkingStops.isNotEmpty) {
      stops.assignAll(driverController.stopUpdateWorkingStops);
      final baselineCount = confirmedStops.length;
      stopLocalKeys.assignAll(
        List.generate(stops.length, (i) {
          if (i >= baselineCount) return 'new_${_newStopCounter++}';
          return 'confirmed_$i';
        }),
      );
    } else {
      stops.assignAll(
        confirmedStops.map(
          (s) => RideStopEntity(
            index: s.index,
            lat: s.lat,
            lng: s.lng,
            address: s.address,
            status: s.status,
          ),
        ),
      );
      stopLocalKeys.assignAll(
        List.generate(stops.length, (i) => 'confirmed_$i'),
      );
    }
    _initialStops = List.from(stops);
  }

  bool get hasChanges {
    if (stops.length != _initialStops.length) return true;
    for (var i = 0; i < stops.length; i++) {
      if (stops[i].address != _initialStops[i].address ||
          stops[i].lat != _initialStops[i].lat ||
          stops[i].lng != _initialStops[i].lng) {
        return true;
      }
    }
    return false;
  }

  bool get shouldShowSaveButton {
    if (isDestinationEditor) {
      return selectedDestination.value != null ||
          driverController.destinationUpdatePreview.value != null;
    }
    return hasChanges || driverController.stopUpdatePreview.value != null;
  }

  String get appBarTitle => isDestinationEditor
      ? AppStrings.changeDropLocation.tr
      : AppStrings.addStops.tr;

  String get saveButtonLabel {
    if (isDestinationEditor) {
      return driverController.destinationUpdatePreview.value == null
          ? AppStrings.updateDestination.tr
          : AppStrings.confirmAndUpdate.tr;
    }
    return driverController.stopUpdatePreview.value == null
        ? AppStrings.updateRide.tr
        : AppStrings.confirmAndUpdate.tr;
  }

  bool canRemoveDraftStopAt(int index) =>
      stopLocalKeys[index].startsWith('new_');

  bool get isAtMaxStops =>
      stops.length >= driverController.maxIntermediateStops;

  Future<void> addStop() async {
    if (isAtMaxStops) {
      AppDialogs.showErrorDialog(
        title: AppStrings.error.tr,
        message: AppStrings.maxStopsOnly.trParams({
          'count': '${driverController.maxIntermediateStops}',
        }),
      );
      return;
    }

    final result = await Get.toNamed(
      AppRoutes.selectSavedLocation,
      arguments: {'isSelectingStop': true, 'label': AppStrings.addStops.tr},
    );
    if (result is! Map<String, dynamic>) return;

    stops.add(
      RideStopEntity(
        index: stops.length,
        lat: (result['lat'] ?? 0.0).toDouble(),
        lng: (result['lng'] ?? 0.0).toDouble(),
        address: result['address'] ?? AppStrings.selectedLocation.tr,
        status: 'pending',
      ),
    );
    stopLocalKeys.add('new_${_newStopCounter++}');
    driverController.stopUpdatePreview.value = null;
  }

  void removeStop(int index) {
    stops.removeAt(index);
    stopLocalKeys.removeAt(index);
    driverController.stopUpdatePreview.value = null;
  }

  void reorderStops(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = stops.removeAt(oldIndex);
    final key = stopLocalKeys.removeAt(oldIndex);
    stops.insert(newIndex, item);
    stopLocalKeys.insert(newIndex, key);
    driverController.stopUpdatePreview.value = null;
  }

  Future<void> pickNewDestination() async {
    final selected = await driverController.pickNewDropLocation();
    if (selected == null) return;
    selectedDestination.value = selected;
    driverController.destinationUpdatePreview.value = null;
  }

  Future<void> onSave() async {
    // Two-step save: first tap previews fare delta; second tap applies and pops.
    if (isDestinationEditor) {
      final selected = selectedDestination.value;
      if (selected == null) return;
      isSaving.value = true;
      try {
        var popEditorOnSuccess = false;
        await Loader.run(() async {
          if (driverController.destinationUpdatePreview.value == null) {
            await driverController.previewDropLocationUpdate(selected);
          } else {
            popEditorOnSuccess = await driverController.applyDropLocationUpdate(
              selected,
            );
          }
        });
        if (popEditorOnSuccess) {
          await _popChangeDropLocationEditor();
          await driverController.onChangeDropLocationEditorClosedAfterConfirm();
        }
      } finally {
        isSaving.value = false;
      }
      return;
    }

    isSaving.value = true;
    try {
      var popEditorOnSuccess = false;
      await Loader.run(() async {
        if (driverController.stopUpdatePreview.value == null) {
          await driverController.previewStopsUpdate(stops.toList());
        } else {
          popEditorOnSuccess = await driverController.applyStopsUpdate(
            stops.toList(),
          );
        }
      });
      if (popEditorOnSuccess) {
        await _popStopEditor();
        await driverController.onStopEditorClosedAfterConfirm();
      }
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _popChangeDropLocationEditor() async {
    if (Get.currentRoute != AppRoutes.changeDropLocationEditor) return;
    Get.back(result: true);
    await SchedulerBinding.instance.endOfFrame;
  }

  Future<void> _popStopEditor() async {
    if (Get.currentRoute != AppRoutes.stopEditor) return;
    Get.back(result: true);
    await SchedulerBinding.instance.endOfFrame;
  }
}
