import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/analytics_service.dart';
import '../../domain/entities/ride_rating_ride_entity.dart';
import '../../domain/usecases/get_last_completed_ride_usecase.dart';
import '../../domain/usecases/skip_ride_rating_usecase.dart';
import '../../domain/usecases/submit_ride_rating_usecase.dart';
import '../widgets/ride_rating_bottom_sheet.dart';

class RideRatingController extends GetxController {
  RideRatingController({
    required this.getLastCompletedRideUseCase,
    required this.submitRideRatingUseCase,
    required this.skipRideRatingUseCase,
    required this.analyticsService,
  });

  final GetLastCompletedRideUseCase getLastCompletedRideUseCase;
  final SubmitRideRatingUseCase submitRideRatingUseCase;
  final SkipRideRatingUseCase skipRideRatingUseCase;
  final AnalyticsService analyticsService;

  final Rxn<RideRatingRideEntity> lastCompletedRide =
      Rxn<RideRatingRideEntity>();
  final selectedRating = 0.obs;
  final isSubmitting = false.obs;
  final isLoadingRide = false.obs;
  final commentController = TextEditingController();

  bool _hasPromptedThisSession = false;

  /// Whether low rating requires reason/comment.
  bool get shouldShowComment =>
      selectedRating.value > 0 && selectedRating.value <= 2;

  /// Returns the appropriate vehicle image based on ride vehicle type.
  String vehicleImageAssetForType(String vehicleType) {
    final type = vehicleType.toLowerCase().trim();
    if (type.contains('boda') || type.contains('bike')) {
      return AppAssets.imgBoda;
    }
    if (type.contains('bajaj') ||
        type.contains('auto') ||
        type.contains('rickshaw') ||
        type.contains('tuk')) {
      return AppAssets.imgBajaji;
    }
    return AppAssets.imgCab;
  }

  /// Called by home flow after initial load to show prompt if ride exists.
  Future<void> tryOpenRatingSheetAfterHomeLoad() async {
    if (_hasPromptedThisSession) return;
    _hasPromptedThisSession = true;
    await _loadLastCompletedRide();
    if (lastCompletedRide.value != null) {
      _openRatingBottomSheet();
    }
  }

  Future<void> _loadLastCompletedRide() async {
    isLoadingRide.value = true;
    final result = await getLastCompletedRideUseCase();
    result.fold(
      (failure) => _handleFailure(failure),
      (ride) => lastCompletedRide.value = ride,
    );
    isLoadingRide.value = false;
  }

  void onRatingSelected(int rating) {
    selectedRating.value = rating;
    if (!shouldShowComment && commentController.text.isNotEmpty) {
      commentController.clear();
    }
  }

  Future<void> onSubmitTap() async {
    final ride = lastCompletedRide.value;
    if (ride == null) {
      Get.snackbar('Rating', 'Ride data is unavailable.');
      return;
    }
    if (selectedRating.value == 0) {
      Get.snackbar(
        'Rating required',
        'Please rate your ride before submitting.',
      );
      return;
    }
    final comment = shouldShowComment ? commentController.text.trim() : '';
    if (shouldShowComment && comment.isEmpty) {
      Get.snackbar('Comment required', 'Please tell us what went wrong.');
      return;
    }

    isSubmitting.value = true;
    final result = await submitRideRatingUseCase(
      rideId: ride.rideId,
      rating: selectedRating.value,
      comment: comment,
    );
    isSubmitting.value = false;

    result.fold((failure) => _handleFailure(failure), (ok) async {
      if (!ok) {
        Get.snackbar('Submit failed', 'Unable to submit rating now.');
        return;
      }
      await analyticsService.logEvent(
        'ride_rating_submitted',
        parameters: {'ride_id': ride.rideId, 'rating': selectedRating.value},
      );
      closeBottomSheet();
    });
  }

  Future<void> onSkipTap() async {
    final ride = lastCompletedRide.value;
    if (ride == null) {
      closeBottomSheet();
      return;
    }

    final result = await skipRideRatingUseCase(rideId: ride.rideId);
    result.fold((failure) => _handleFailure(failure), (ok) async {
      if (!ok) {
        Get.snackbar('Skip failed', 'Unable to skip rating now.');
        return;
      }
      await analyticsService.logEvent(
        'ride_rating_skipped',
        parameters: {'ride_id': ride.rideId},
      );
      closeBottomSheet();
    });
  }

  void closeBottomSheet() {
    if (Get.isBottomSheetOpen ?? false) {
      Get.back<void>();
    }
  }

  void _openRatingBottomSheet() {
    if (Get.isBottomSheetOpen ?? false) return;
    Get.bottomSheet(
      const RideRatingBottomSheet(),
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _handleFailure(Failure failure) {
    final msg = failure.message.trim();
    Get.snackbar('Error', msg.isEmpty ? 'Something went wrong.' : msg);
  }

  @override
  void onClose() {
    commentController.dispose();
    super.onClose();
  }
}
