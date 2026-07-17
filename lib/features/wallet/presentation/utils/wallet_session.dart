import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/local_bank_instructions_service.dart';
import '../../../home/data/repositories/home_repository_impl.dart';
import '../../../profile/presentation/controllers/payment_methods_controller.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../controllers/wallet_controller.dart';
import '../controllers/wallet_history_controller.dart';

/// Wallet session lifecycle helpers.
///
/// [WalletController] keeps a manual singleton and [WalletRepositoryImpl]
/// caches card statements in memory. Without an explicit teardown on logout,
/// the next user can briefly see the previous user's balance/transactions.
abstract final class WalletSession {
  WalletSession._();

  /// Wipes wallet caches and controller state when the auth session ends.
  ///
  /// Call from profile logout and session-expiry flows **before**
  /// [StorageService.deleteAll] so in-flight UI cannot render stale data.
  static void teardownOnLogout() {
    // Drop repository-level statement cache (singleton via DI).
    sl<WalletRepository>().invalidateStatementCache();
    // Profile GET cache — avoid showing the previous user's name/avatar.
    sl<ProfileRepository>().invalidateProfileCache();
    // Local-bank instructions are wallet-number scoped; clear for next login.
    sl<LocalBankInstructionsService>().clear();
    // Vehicle catalog session cache — refetch next login (config may change).
    HomeRepositoryImpl.invalidateVehicleTypesCache();

    // Clear observables and null the WalletController factory singleton.
    WalletController.resetForLogout();

    // Remove GetX registrations so the next visit creates a fresh controller.
    if (Get.isRegistered<WalletHistoryController>()) {
      Get.delete<WalletHistoryController>(force: true);
    }
    if (Get.isRegistered<WalletController>()) {
      Get.delete<WalletController>(force: true);
    }

    // Profile / payment screens also hold wallet summary outside WalletController.
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().clearWalletDisplayOnLogout();
    }
    if (Get.isRegistered<PaymentMethodsController>()) {
      Get.find<PaymentMethodsController>().clearWalletDisplayOnLogout();
    }
  }
}
