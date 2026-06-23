import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart';
import '../../../wallet/domain/usecases/get_wallet_summary_usecase.dart';
import '../../../wallet/presentation/controllers/wallet_controller.dart';
import '../../../wallet/presentation/utils/wallet_format_utils.dart';

class StepsToLoadGoWalletController extends GetxController {
  StepsToLoadGoWalletController({GetWalletSummaryUseCase? getWalletSummaryUseCase})
    : _getWalletSummaryUseCase =
          getWalletSummaryUseCase ?? sl<GetWalletSummaryUseCase>();

  final GetWalletSummaryUseCase _getWalletSummaryUseCase;

  final walletNumber = ''.obs;
  final isLoading = true.obs;

  String get formattedWalletNumber =>
      formatWalletAccountNumber(walletNumber.value);

  String get walletNumberForCopy =>
      walletNumber.value.replaceAll(RegExp(r'\s+'), '');

  @override
  void onInit() {
    super.onInit();
    unawaited(_loadWalletNumber());
  }

  Future<void> _loadWalletNumber() async {
    isLoading.value = true;
    try {
      if (Get.isRegistered<WalletController>()) {
        final cached = WalletController().walletNumberForCopy.trim();
        if (cached.isNotEmpty) {
          walletNumber.value = cached;
          return;
        }
      }

      final summary = await _getWalletSummaryUseCase();
      walletNumber.value = summary.walletNumber.trim();
    } catch (_) {
      walletNumber.value = '';
    } finally {
      isLoading.value = false;
    }
  }

  void copyWalletNumber() {
    final number = walletNumberForCopy;
    if (number.isEmpty) return;
    Clipboard.setData(ClipboardData(text: number));
  }
}
