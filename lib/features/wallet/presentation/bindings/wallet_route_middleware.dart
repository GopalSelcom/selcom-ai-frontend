import 'dart:async';

import 'package:get/get.dart';

import '../controllers/wallet_controller.dart';

/// Reloads wallet data whenever the wallet route is opened.
class WalletRouteMiddleware extends GetMiddleware {
  @override
  GetPage? onPageCalled(GetPage? page) {
    final controller = WalletController();
    // Always refresh on route open (not only when summary exists) so a new
    // login never flashes the prior user's balance while a background fetch runs.
    unawaited(
      controller.loadWallet(
        showLoading: controller.summary.value == null,
      ),
    );
    return super.onPageCalled(page);
  }
}
