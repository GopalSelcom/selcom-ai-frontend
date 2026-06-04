import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart';
import '../../domain/usecases/get_wallet_summary_usecase.dart';
import '../../domain/usecases/get_wallet_transactions_usecase.dart';
import '../controllers/wallet_controller.dart';

class WalletBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WalletController>(
      () => WalletController(
        getWalletSummaryUseCase: sl<GetWalletSummaryUseCase>(),
        getWalletTransactionsUseCase: sl<GetWalletTransactionsUseCase>(),
      ),
    );
  }
}
