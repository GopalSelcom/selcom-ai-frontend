import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../bindings/wallet_selfie_verification_binding.dart';
import '../screens/wallet_selfie_verification_screen.dart';
import '../wallet_link_flow_data.dart';

class WalletFullNameController extends GetxController {
  final firstNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final lastNameController = TextEditingController();

  final isButtonEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    validateFields();
  }

  @override
  void onClose() {
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    super.onClose();
  }

  void validateFields() {
    isButtonEnabled.value = firstNameController.text.trim().isNotEmpty &&
        middleNameController.text.trim().isNotEmpty &&
        lastNameController.text.trim().isNotEmpty;
  }

  /// Mirrors [AskUserFullNameController.updateNames]; then selfie step (auth liveness).
  Future<void> submitNames() async {
    if (!isButtonEnabled.value) return;
    // TODO(wallet-link): persist name via wallet link API.
    final flow = Get.find<WalletLinkFlowData>();
    await Get.to(
      () => const WalletSelfieVerificationScreen(),
      binding: WalletSelfieVerificationBinding(),
    );
    flow.recordRoutePush();
  }
}
