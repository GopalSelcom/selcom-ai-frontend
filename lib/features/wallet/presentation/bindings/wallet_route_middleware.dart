import 'dart:async';

import 'package:get/get.dart';

import '../../../profile/presentation/controllers/profile_controller.dart';
import '../controllers/wallet_controller.dart';

/// Reloads wallet data whenever the wallet route is opened.
class WalletRouteMiddleware extends GetMiddleware {
  @override
  GetPage? onPageCalled(GetPage? page) {
    final controller = WalletController();
    // Always start with a masked balance when entering the wallet screen.
    controller.resetWalletBalanceVisibilityOnScreenEntry();
    // Reuse profile session cache for balance; fetch statement only unless cache
    // is empty (e.g. deep link straight to wallet).
    unawaited(
      controller.loadWallet(
        showLoading: controller.summary.value == null,
        fetchBalance: !ProfileWalletCache.isLoaded,
      ),
    );
    return super.onPageCalled(page);
  }
}
