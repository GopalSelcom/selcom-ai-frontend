import 'package:get/get.dart';

import '../controllers/wallet_selfie_verification_controller.dart';

class WalletSelfieVerificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(WalletSelfieVerificationController.new);
  }
}
