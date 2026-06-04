import 'package:get/get.dart';

import '../controllers/wallet_full_name_controller.dart';

class WalletFullNameBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(WalletFullNameController.new);
  }
}
