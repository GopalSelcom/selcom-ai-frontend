import 'package:get/get.dart';

import '../../data/repositories/active_wallet_repository_impl.dart';
import '../../domain/repositories/active_wallet_repository.dart';
import '../controllers/active_wallet_form_controller.dart';

class ActiveWalletBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ActiveWalletRepository>(() => ActiveWalletRepositoryImpl());
    Get.lazyPut<ActiveWalletFormController>(
      () => ActiveWalletFormController(
        activeWalletRepository: Get.find<ActiveWalletRepository>(),
      ),
    );
  }
}
