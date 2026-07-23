import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/services/live_activity/live_activity_manager.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../data/models/cancellation_charges_response.dart';
import '../../domain/repositories/ride_repository.dart';
import '../widgets/cancel_ride_dialogs.dart';

/// User-initiated cancel ride flow shared by finding-driver and driver-assigned screens.
///
/// Follows the driver-assigned sheet pattern: confirm → reasons → (charges if fee > 0) → cancel API → home.
class CancelRideFlow {
  CancelRideFlow({
    required this.rideRepository,
    required this.rideId,
    this.onCancelApiStarted,
    this.onCancelApiFailed,
  });

  final RideRepository rideRepository;
  final String rideId;

  /// Called when the user confirms cancel-and-pay (before the cancel API).
  final VoidCallback? onCancelApiStarted;

  /// Called when the cancel API fails so controllers can reset local flags.
  final VoidCallback? onCancelApiFailed;

  /// Runs confirm → reasons → (charges when fee > 0) → cancel API → home.
  Future<void> run() async {
    // 1. Initial confirmation
    final confirmResult = await AppDialogs.showAnimatedDialog(
      child: const CancelConfirmationDialog(),
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
    RideCancellationChargesData? cancellationData;

    // 3. Reason selection + fetch cancellation charges.
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
        await Loader.run(() async {
          final charges = await rideRepository.getCancellationCharges(rideId);
          await charges.fold(
            (_) async {
              AppDialogs.showErrorDialog(
                title: AppStrings.cancelFailed.tr,
                message: AppStrings.couldNotCancelTryAgain.tr,
              );
            },
            (data) async {
              selectedReason = reason;
              cancellationData = data;
              Get.back();
            },
          );
        });
      },
    );
    await AppDialogs.showAnimatedDialog<void>(
      child: reasonDialog,
      barrierDismissible: false,
      barrierColor: AppColors.overlayBlack12,
    );
    reasonDialog.disposeController();
    if (selectedReason == null || cancellationData == null) return;

    final charges = cancellationData!;

    // 4. No fee — cancel immediately; otherwise show fee/refund summary first.
    if ((charges.cancellationFee ?? 0) <= 0) {
      await _cancelRideAndNavigateHome(selectedReason!);
      return;
    }

    await AppDialogs.showAnimatedDialog<bool>(
      child: CancellationChargesDialog(
        canCancel: charges.canCancel ?? false,
        cancellationFee: charges.cancellationFee ?? 0,
        netRefund: charges.netRefund ?? 0,
        onConfirmTap: () => _cancelRideAndNavigateHome(selectedReason!),
      ),
      barrierDismissible: false,
      barrierColor: AppColors.overlayBlack12,
    );
  }

  Future<void> _cancelRideAndNavigateHome(String reason) async {
    onCancelApiStarted?.call();
    var cancelSucceeded = false;
    await Loader.run(() async {
      final result = await rideRepository.cancelRide(rideId, reason);
      result.fold(
        (_) {
          onCancelApiFailed?.call();
          AppDialogs.showErrorDialog(
            title: AppStrings.cancelFailed.tr,
            message: AppStrings.couldNotCancelTryAgain.tr,
          );
        },
        (_) {
          cancelSucceeded = true;
        },
      );
    });
    if (!cancelSucceeded) return;
    await AppDialogs.navigateHomeReplacingStack();
    unawaited(LiveActivityManager().endActivity(rideId));
  }
}
