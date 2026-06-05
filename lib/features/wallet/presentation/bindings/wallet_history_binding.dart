import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart';
import '../../domain/usecases/get_wallet_transactions_usecase.dart';
import '../controllers/wallet_history_controller.dart';

class WalletHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WalletHistoryController>(
      () => WalletHistoryController(
        getWalletTransactionsUseCase: sl<GetWalletTransactionsUseCase>(),
      ),
    );
  }
}
