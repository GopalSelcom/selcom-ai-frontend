import 'package:get/get.dart';

import '../controllers/wallet_biometric_intro_controller.dart';

class WalletBiometricIntroBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(WalletBiometricIntroController.new);
  }
}
