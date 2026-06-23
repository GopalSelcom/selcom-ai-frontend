import 'dart:async';

import 'package:get/get.dart';

import '../controllers/wallet_controller.dart';

/// Reloads wallet data whenever the wallet route is opened again.
class WalletRouteMiddleware extends GetMiddleware {
  @override
  GetPage? onPageCalled(GetPage? page) {
    final controller = WalletController();
    if (controller.summary.value != null) {
      unawaited(controller.loadWallet(showLoading: false));
    }
    return super.onPageCalled(page);
  }
}
