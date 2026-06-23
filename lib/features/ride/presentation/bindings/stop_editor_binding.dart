import 'package:get/get.dart';

import '../controllers/stop_editor_controller.dart';

/// Registers [StopEditorController] for `/stop-editor` and `/change-drop-location-editor`.
class StopEditorBinding extends Bindings {
  @override
  void dependencies() {
    // Replace stale instance when re-opening the editor from driver accepted.
    if (Get.isRegistered<StopEditorController>()) {
      Get.delete<StopEditorController>(force: true);
    }
    Get.put(StopEditorController());
  }
}
