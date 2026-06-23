import 'package:get/get.dart';

import '../controllers/mobile_money_topup_controller.dart';
import '../controllers/selcom_pesa_topup_controller.dart';
import '../controllers/tanqr_wallet_topup_controller.dart';

/// Delay aligned with [AppDialogs.ensureKeyboardClosed] so sheet routes finish
/// popping before GetX controllers dispose their [TextEditingController]s.
const Duration walletTopupSheetTeardownDelay = Duration(milliseconds: 350);

Future<void> disposeSelcomPesaTopupAfterSheetClosed(String tag) async {
  await Future<void>.delayed(walletTopupSheetTeardownDelay);
  if (!Get.isRegistered<SelcomPesaTopupController>(tag: tag)) return;
  final controller = Get.find<SelcomPesaTopupController>(tag: tag);
  if (controller.shouldRetainAfterSheetClose) return;
  controller.handleSheetDismissed();
  controller.disposeTextFields();
  Get.delete<SelcomPesaTopupController>(tag: tag);
}

Future<void> disposeTanQrTopupAfterSheetClosed(String tag) async {
  await Future<void>.delayed(walletTopupSheetTeardownDelay);
  if (!Get.isRegistered<TanQrWalletTopupController>(tag: tag)) return;
  final controller = Get.find<TanQrWalletTopupController>(tag: tag);
  controller.handleSheetDismissed();
  controller.disposeTextFields();
  Get.delete<TanQrWalletTopupController>(tag: tag);
}

Future<void> disposeMobileMoneyTopupAfterSheetClosed(String tag) async {
  await Future<void>.delayed(walletTopupSheetTeardownDelay);
  if (!Get.isRegistered<MobileMoneyTopupController>(tag: tag)) return;
  final controller = Get.find<MobileMoneyTopupController>(tag: tag);
  if (controller.isAwaitingPaymentResult) return;
  controller.handleSheetDismissed();
  controller.disposeTextFields();
  Get.delete<MobileMoneyTopupController>(tag: tag);
}
