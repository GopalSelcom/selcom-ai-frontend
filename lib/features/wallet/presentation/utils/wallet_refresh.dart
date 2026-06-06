import 'package:get/get.dart';

import '../../../profile/presentation/controllers/profile_controller.dart';
import '../controllers/wallet_controller.dart';

/// Refreshes wallet balance, statement, and profile card after funds change.
abstract final class WalletRefresh {
  WalletRefresh._();

  static Future<void> afterBalanceChange({bool showWalletLoading = false}) async {
    await WalletController().loadWallet(showLoading: showWalletLoading);

    if (Get.isRegistered<ProfileController>()) {
      await Get.find<ProfileController>().fetchWalletBalance();
    }
  }
}
