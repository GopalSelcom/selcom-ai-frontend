import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/data/models/ride_cancel_info_model.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/errors/failures.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/services/live_activity/live_activity_manager.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../data/models/cancel_ride_response.dart';
import '../../domain/repositories/ride_repository.dart';
import '../widgets/cancel_ride_dialogs.dart';

/// User-initiated cancel ride flow shared by finding-driver and driver-assigned screens.
///
/// Confirmation title/subtitle come from cached [cancelInfo] (socket / active rides).
/// Fee amounts are never computed locally — only rendered from backend strings / cancel response.
class CancelRideFlow {
  CancelRideFlow({
    required this.rideRepository,
    required this.rideId,
    this.cancelInfo,
    this.onCancelApiStarted,
    this.onCancelApiFailed,
    this.onRideAlreadyFinalized,
  });

  final RideRepository rideRepository;
  final String rideId;

  /// Latest `cancel_info` from ride state (may be null on older payloads).
  final RideCancelInfoModel? cancelInfo;

  /// Called when the user confirms cancel (before the cancel API).
  final VoidCallback? onCancelApiStarted;

  /// Called when the cancel API fails so controllers can reset local flags.
  final VoidCallback? onCancelApiFailed;

  /// Called when cancel races the server no-show finalize (HTTP 409).
  /// Controllers should refresh / wait for the terminal socket event.
  final VoidCallback? onRideAlreadyFinalized;

  /// Runs confirm → reasons → cancel API → result (fee/refund) → home.
  Future<void> run() async {
    final info = cancelInfo;
    if (info != null && !info.canCancel) {
      return;
    }

    // 1. Confirmation — backend title/subtitle when available.
    final confirmResult = await AppDialogs.showAnimatedDialog(
      child: CancelConfirmationDialog(cancelInfo: info),
      barrierDismissible: false,
      barrierColor: AppColors.overlayBlack12,
    );
    if (confirmResult != true) return;

    // 2. Server-managed cancel reasons (preload only when not cached).
    final cancelReasons = await di
        .sl<AppSettingsService>()
        .resolveCancellationReasons();
    if (cancelReasons.isEmpty) {
      AppDialogs.showErrorDialog(
        title: AppStrings.cancelFailed.tr,
        message: AppStrings.couldNotCancelTryAgain.tr,
      );
      return;
    }

    String? selectedReason;

    final reasonDialog = CancelReasonSelectionDialog(
      reasons: cancelReasons,
      onContinueTap: (reason) async {
        if (rideId.isEmpty) {
          AppDialogs.showErrorDialog(
            title: AppStrings.cancelFailed.tr,
            message: AppStrings.rideIdIsMissing.tr,
          );
          return;
        }
        selectedReason = reason;
        Get.back();
      },
    );
    await AppDialogs.showAnimatedDialog<void>(
      child: reasonDialog,
      barrierDismissible: false,
      barrierColor: AppColors.overlayBlack12,
    );
    reasonDialog.disposeController();
    if (selectedReason == null) return;

    await _cancelRideAndNavigateHome(selectedReason!);
  }

  Future<void> _cancelRideAndNavigateHome(String reason) async {
    onCancelApiStarted?.call();
    CancelRideData? cancelData;
    Failure? failure;
    await Loader.run(() async {
      final result = await rideRepository.cancelRide(rideId, reason);
      result.fold((f) => failure = f, (data) => cancelData = data);
    });

    if (failure is RideAlreadyFinalizedFailure) {
      // Not an error — no-show (or another finalize) won the race.
      onRideAlreadyFinalized?.call();
      return;
    }

    if (failure != null || cancelData == null) {
      onCancelApiFailed?.call();
      AppDialogs.showErrorDialog(
        title: AppStrings.cancelFailed.tr,
        message: AppStrings.couldNotCancelTryAgain.tr,
      );
      return;
    }

    final data = cancelData!;
    final fee = data.cancellationFee ?? 0;
    final refund = data.netRefund ?? 0;
    if (fee > 0 || refund > 0) {
      await AppDialogs.showAnimatedDialog<void>(
        child: CancelResultDialog(
          cancellationFee: fee,
          netRefund: refund,
        ),
        barrierDismissible: false,
        barrierColor: AppColors.overlayBlack12,
      );
    }

    await AppDialogs.navigateHomeReplacingStack();
    unawaited(LiveActivityManager().endActivity(rideId));
  }
}
