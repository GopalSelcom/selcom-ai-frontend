import 'package:get/get.dart';

import '../controllers/wallet_enter_nida_controller.dart';
import '../wallet_link_flow_data.dart';

class WalletEnterNidaBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<WalletLinkFlowData>()) {
      Get.put(WalletLinkFlowData(), permanent: false);
    }
    Get.lazyPut(WalletEnterNidaController.new);
  }
}
