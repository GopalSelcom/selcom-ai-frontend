import 'dart:async';

import 'package:get/get.dart';

import '../../../profile/presentation/controllers/payment_methods_controller.dart';
import '../controllers/selcom_pesa_topup_controller.dart';

/// Binds wallet screen controllers and loads linked accounts on open.
///
/// [topupTag] scopes [SelcomPesaTopupController] so this screen does not clash
/// with the other-number bottom sheet instance.
class SelcomPesaToWalletBinding extends Bindings {
  static String? topupTag;

  @override
  void dependencies() {
    topupTag = 'selcom_pesa_self_${DateTime.now().millisecondsSinceEpoch}';
    if (!Get.isRegistered<PaymentMethodsController>()) {
      Get.put(PaymentMethodsController(), permanent: true);
    }
    unawaited(Get.find<PaymentMethodsController>().loadLinkedAccounts());
    Get.put(
      SelcomPesaTopupController(controllerTag: topupTag),
      tag: topupTag,
    );
  }
}
