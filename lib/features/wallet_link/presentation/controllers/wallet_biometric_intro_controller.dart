import 'package:get/get.dart';

import '../bindings/wallet_hand_selection_binding.dart';
import '../screens/wallet_hand_selection_screen.dart';
import '../wallet_link_flow_data.dart';

class WalletBiometricIntroController extends GetxController {
  WalletLinkFlowData get _flow => Get.find<WalletLinkFlowData>();

  Future<void> openHandSelection() async {
    await Get.to(
      () => const WalletHandSelectionScreen(),
      binding: WalletHandSelectionBinding(),
    );
    _flow.recordRoutePush();
  }
}
