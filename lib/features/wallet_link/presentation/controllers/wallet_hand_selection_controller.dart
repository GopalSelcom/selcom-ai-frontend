import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../bindings/wallet_full_name_binding.dart';
import '../screens/wallet_full_name_screen.dart';
import '../widgets/wallet_finger_scan_instruction_sheet.dart';
import '../wallet_link_flow_data.dart';

class WalletHandSelectionController extends GetxController {
  final isLeftHandSelected = true.obs;
  final isRightHandSelected = false.obs;

  bool get hasHandSelected =>
      isLeftHandSelected.value || isRightHandSelected.value;

  void selectLeftHand() {
    isLeftHandSelected.value = true;
    isRightHandSelected.value = false;
  }

  void selectRightHand() {
    isRightHandSelected.value = true;
    isLeftHandSelected.value = false;
  }

  Future<void> openFingerScanInstructions() async {
    if (!hasHandSelected) return;
    await Get.bottomSheet(
      WalletFingerScanInstructionSheet(onContinue: openFullNameScreen),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> openMissingFingers() async {
    if (!hasHandSelected) return;
    // TODO(wallet-link): MissingFingersScreen when identy license is bundled.
    await openFullNameScreen();
  }

  Future<void> openFullNameScreen() async {
    final flow = Get.find<WalletLinkFlowData>();
    await Get.to(
      () => const WalletFullNameScreen(),
      binding: WalletFullNameBinding(),
    );
    flow.recordRoutePush();
  }
}
