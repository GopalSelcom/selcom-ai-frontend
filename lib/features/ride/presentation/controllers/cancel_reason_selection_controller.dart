import 'package:get/get.dart';

class CancelReasonSelectionController extends GetxController {
  CancelReasonSelectionController({
    required this.reasons,
    this.onContinueTap,
  });

  final List<String> reasons;
  final Future<void> Function(String reason)? onContinueTap;

  final selectedReason = RxnString();

  bool get hasSelection => selectedReason.value != null;

  void selectReason(String reason) {
    selectedReason.value = reason;
  }

  Future<void> onContinue() async {
    final reason = selectedReason.value;
    if (reason == null) return;
    if (onContinueTap != null) {
      await onContinueTap!(reason);
    } else {
      Get.back(result: reason);
    }
  }
}
