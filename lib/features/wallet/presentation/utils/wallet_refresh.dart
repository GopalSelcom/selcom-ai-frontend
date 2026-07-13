import 'package:get/get.dart';

import '../../../profile/presentation/controllers/profile_controller.dart';
import '../controllers/wallet_controller.dart';

/// Refreshes wallet balance, statement, and profile card after funds change.
abstract final class WalletRefresh {
  WalletRefresh._();

  static Future<void> afterBalanceChange({bool showWalletLoading = false}) async {
    if (Get.isRegistered<WalletController>()) {
      await Get.find<WalletController>().loadWallet(
        showLoading: showWalletLoading,
        fetchBalance: true,
      );
    } else {
      await WalletController().loadWallet(
        showLoading: showWalletLoading,
        fetchBalance: true,
      );
    }

    // Silent profile-card update (no shimmer) after top-up / balance change.
    if (Get.isRegistered<ProfileController>()) {
      await Get.find<ProfileController>().fetchWalletBalance(initialLoad: false);
    }
  }
}
