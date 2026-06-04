import 'package:get/get.dart';

import '../controllers/wallet_passport_scan_controller.dart';

class WalletPassportScanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(WalletPassportScanController.new);
  }
}
