import 'package:get/get.dart';

import '../controllers/wallet_hand_selection_controller.dart';

class WalletHandSelectionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(WalletHandSelectionController.new);
  }
}
