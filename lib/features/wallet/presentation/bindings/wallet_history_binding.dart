import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../controllers/wallet_history_controller.dart';

class WalletHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WalletHistoryController>(
      () => WalletHistoryController(
        walletRepository: sl<WalletRepository>(),
      ),
    );
  }
}
