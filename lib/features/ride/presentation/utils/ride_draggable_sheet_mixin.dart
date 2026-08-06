import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

/// Shared draggable-sheet state for finding-driver and driver-accepted flows.
mixin RideDraggableSheetMixin on GetxController {
  /// Override for screen-specific starting fraction.
  double get initialSheetSize => 0.3;

  late final RxDouble sheetSize = initialSheetSize.obs;

  final DraggableScrollableController sheetController =
      DraggableScrollableController();

  /// Updates [sheetSize] safely (defers if called during build).
  void updateSheetSize(double size) {
    if ((size - sheetSize.value).abs() < 0.0001) return;
    // DraggableScrollableSheet can notify during build (extent replace).
    // Defer Rx writes so Obx is not marked dirty mid-build.
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      sheetSize.value = size;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if ((size - sheetSize.value).abs() < 0.0001) return;
      sheetSize.value = size;
    });
  }

  /// Animates the sheet to [targetSize] when attached.
  void animateSheetTo(double targetSize) {
    if (!sheetController.isAttached) return;
    Future.microtask(() {
      if (!sheetController.isAttached) return;
      sheetController.animateTo(
        targetSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void bindSheetSizeListener() {
    sheetController.addListener(() {
      updateSheetSize(sheetController.size);
    });
  }

  @override
  void onClose() {
    sheetController.dispose();
    super.onClose();
  }
}
