import 'package:get/get.dart';

/// In-memory state for the wallet-link identity flow (mirrors selcom_auth session fields).
class WalletLinkFlowData extends GetxService {
  bool isNidaSelected = true;
  String nidaNumber = '';
  String passportNumber = '';
  String passportDateOfBirth = '';
  String passportDateOfExpiry = '';
  String selfieImagePath = '';

  /// Screens pushed above [WalletEnterNidaScreen] before completion.
  int routesAboveEnterNida = 0;

  void recordRoutePush() => routesAboveEnterNida++;

  void resetRouteStack() => routesAboveEnterNida = 0;

  void completeAndReturnToProfile() {
    for (var i = 0; i < routesAboveEnterNida; i++) {
      if (Get.key.currentState?.canPop() ?? false) {
        Get.back();
      }
    }
    routesAboveEnterNida = 0;
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back(result: true);
    }
  }
}
