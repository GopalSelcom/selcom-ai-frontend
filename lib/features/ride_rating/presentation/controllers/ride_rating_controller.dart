import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';

import '../../../../core/data/models/requests/submit_ride_rating_request.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/vehicle_image_utils.dart';
import '../../domain/entities/ride_rating_ride_entity.dart';
import '../../domain/entities/ride_rating_tag_entity.dart';
import '../../domain/usecases/get_review_tags_usecase.dart';
import '../../domain/usecases/get_last_completed_ride_usecase.dart';
import '../../domain/usecases/skip_ride_rating_usecase.dart';
import '../../domain/usecases/submit_ride_rating_usecase.dart';
import '../widgets/ride_rating_bottom_sheet.dart';

class RideRatingController extends GetxController {
  RideRatingController({
    required this.getLastCompletedRideUseCase,
    required this.getReviewTagsUseCase,
    required this.submitRideRatingUseCase,
    required this.skipRideRatingUseCase,
    required this.analyticsService,
  });

  final GetLastCompletedRideUseCase getLastCompletedRideUseCase;
  final GetReviewTagsUseCase getReviewTagsUseCase;
  final SubmitRideRatingUseCase submitRideRatingUseCase;
  final SkipRideRatingUseCase skipRideRatingUseCase;
  final AnalyticsService analyticsService;

  final Rxn<RideRatingRideEntity> pendingReviewRide =
      Rxn<RideRatingRideEntity>();
  final availableTags = <RideRatingTagEntity>[].obs;
  final selectedTags = <String>[].obs;
  final selectedRating = 0.obs;
  final isSubmitting = false.obs;
  final isLoadingRide = false.obs;
  final isLoadingTags = false.obs;
  final commentController = TextEditingController();
  final commentText = ''.obs;

  bool _hasPromptedThisSession = false;
  int _latestTagRequestRating = 0;
  bool _isRatingSheetOpen = false;

  bool get hasSelectedRating => selectedRating.value > 0;

  bool get shouldShowComment => hasSelectedRating;

  bool get requiresComment =>
      selectedRating.value > 0 && selectedRating.value <= 2;

  bool get canSubmit {
    if (!hasSelectedRating || isSubmitting.value) {
      return false;
    }
    if (selectedTags.isEmpty) {
      return false;
    }
    if (requiresComment) {
      return commentText.value.trim().isNotEmpty;
    }
    return true;
  }

  /// Stars, tags, and comment rules satisfied (ignores [isSubmitting]). Used for when to show the ride-details Done action.
  bool get isRatingFormComplete {
    final r = selectedRating.value;
    if (r < 1) return false;
    if (selectedTags.isEmpty) return false;
    if (r <= 2 && commentText.value.trim().isEmpty) return false;
    return true;
  }

  String vehicleImageAssetForType(String vehicleType) {
    return VehicleImageUtils.imageAssetForVehicleType(vehicleType);
  }

  Future<void> tryOpenRatingSheetAfterHomeLoad() async {
    if (_hasPromptedThisSession) return;
    _hasPromptedThisSession = true;
    try {
      await _loadPendingReviewRide();
    } catch (_) {
      pendingReviewRide.value = null;
      selectedRating.value = 0;
      isLoadingRide.value = false;
    }
    if (pendingReviewRide.value != null) {
      _openRatingBottomSheet();
    }
  }

  /// Prepares controller state for rendering rating UI in another sheet/screen.
  Future<void> prepareRatingForRide(RideRatingRideEntity ride) async {
    _resetSheetState(clearPendingRide: true);
    pendingReviewRide.value = ride;
    final initialRating = ride.riderRating;
    selectedRating.value =
        (initialRating != null && initialRating >= 1 && initialRating <= 5)
        ? initialRating
        : 0;
    if (selectedRating.value > 0) {
      await _loadReviewTagsForRating(selectedRating.value);
    }
  }

  /// Opens the rating flow for a specific ride source (e.g. My Rides details).
  void openRatingForRide(RideRatingRideEntity ride) {
    _resetSheetState(clearPendingRide: true);
    pendingReviewRide.value = ride;
    final initialRating = ride.riderRating;
    selectedRating.value =
        (initialRating != null && initialRating >= 1 && initialRating <= 5)
        ? initialRating
        : 0;
    _openRatingBottomSheet();
  }

  Future<void> _loadPendingReviewRide() async {
    isLoadingRide.value = true;
    try {
      final result = await getLastCompletedRideUseCase();
      result.fold((failure) => _handleFailure(failure), (ride) {
        if (ride == null) {
          pendingReviewRide.value = null;
          selectedRating.value = 0;
          return;
        }

        final isPending = _isWithinPendingReviewWindow(ride);
        pendingReviewRide.value = isPending ? ride : null;

        if (!isPending) {
          selectedRating.value = 0;
          return;
        }

        final initialRating = ride.riderRating;
        selectedRating.value =
            (initialRating != null && initialRating >= 1 && initialRating <= 5)
            ? initialRating
            : 0;
      });
    } catch (_) {
      pendingReviewRide.value = null;
      selectedRating.value = 0;
    } finally {
      isLoadingRide.value = false;
    }
  }

  Future<void> onRatingSelected(int rating) async {
    if (rating < 1 || rating > 5) return;
    if (selectedRating.value == rating && availableTags.isNotEmpty) return;
    selectedRating.value = rating;
    selectedTags.clear();
    if (rating > 2 && commentController.text.isNotEmpty) {
      commentController.clear();
      commentText.value = '';
    }
    await _loadReviewTagsForRating(rating);
  }

  void onTagToggled(String key) {
    if (selectedTags.contains(key)) {
      selectedTags.remove(key);
      selectedTags.refresh();
      return;
    }
    selectedTags.add(key);
    selectedTags.refresh();
  }

  void onCommentChanged(String value) {
    if (commentText.value != value) {
      commentText.value = value;
    }
  }

  // onSuccessConfirmed lets callers decide where "Continue" should navigate
  // after success dialog (e.g., Home for completion flow, pop for My Rides).
  Future<void> onSubmitTap({VoidCallback? onSuccessConfirmed}) async {
    final ride = pendingReviewRide.value;
    if (ride == null) {
      AppDialogs.showErrorDialog(
        title: AppStrings.rating.tr,
        message: AppStrings.rideDataIsUnavailable.tr,
      );
      return;
    }
    if (selectedRating.value == 0) {
      AppDialogs.showErrorDialog(
        title:  AppStrings.ratingRequired.tr,
        message: AppStrings.pleaseRateYourRideBeforeSubmitting.tr,
      );
      return;
    }
    if (selectedTags.isEmpty) {
      AppDialogs.showErrorDialog(
        title: AppStrings.tagRequired.tr,
        message: AppStrings.pleaseSelectAtLeastOneTagBeforeSubmitting.tr,
      );
      return;
    }
    final comment = requiresComment ? commentController.text.trim() : '';
    if (requiresComment && comment.isEmpty) {
      AppDialogs.showErrorDialog(
        title: AppStrings.commentRequired.tr,
        message: AppStrings.pleaseEnterYourCommentFirst.tr,
      );
      return;
    }

    isSubmitting.value = true;
    final result = await submitRideRatingUseCase(
      SubmitRideRatingRequest(
        rideId: ride.rideId,
        rating: selectedRating.value,
        tags: selectedTags.toList(),
        comment: comment,
      ),
    );
    isSubmitting.value = false;

    result.fold((failure) => _handleFailure(failure), (ok) async {
      if (!ok) {
        AppDialogs.showErrorDialog(
          title: AppStrings.submitFailed.tr,
          message:AppStrings.unableToSubmitRatingNow.tr
        );
        return;
      }
      await analyticsService.logEvent(
        'ride_rating_submitted',
        parameters: {
          'ride_id': ride.rideId,
          'rating': selectedRating.value,
          'tags_count': selectedTags.length,
        },
      );
      _resetSheetState(clearPendingRide: true);
      closeBottomSheet();
      AppDialogs.showSuccessDialog(
        title:    AppStrings.thankYou.tr,
        message:  AppStrings.yourRatingHasBeenSubmitted.tr,
        onConfirm: onSuccessConfirmed,
      );
    });
  }

  Future<void> onSkipTap() async {
    final ride = pendingReviewRide.value;
    if (ride == null) {
      closeBottomSheet();
      return;
    }

    isSubmitting.value = true;
    final result = await skipRideRatingUseCase(rideId: ride.rideId);
    isSubmitting.value = false;

    result.fold((failure) => _handleFailure(failure), (ok) async {
      if (!ok) {
        AppDialogs.showErrorDialog(
          title: AppStrings.skipFailed.tr,
          message: AppStrings.unableToSkipRatingNow.tr,
        );
        return;
      }
      await analyticsService.logEvent(
        'ride_rating_skipped',
        parameters: {'ride_id': ride.rideId},
      );
      _resetSheetState(clearPendingRide: true);
      closeBottomSheet();
    });
  }

  void closeBottomSheet() {
    if (_isRatingSheetOpen) {
      AppDialogs.closeActiveDialog();
      _isRatingSheetOpen = false;
    }
  }

  void _openRatingBottomSheet() {
    if (_isRatingSheetOpen) return;
    _isRatingSheetOpen = true;
    AppDialogs.showAnimatedBottomSheet(
      child: const RideRatingBottomSheet(),
      barrierDismissible: true,
    ).then((_) => _isRatingSheetOpen = false);
  }

  Future<void> _loadReviewTagsForRating(int rating) async {
    availableTags.clear();
    isLoadingTags.value = true;
    _latestTagRequestRating = rating;
    final result = await getReviewTagsUseCase(rating: rating);
    if (_latestTagRequestRating != rating) {
      isLoadingTags.value = false;
      return;
    }
    result.fold((failure) => _handleFailure(failure), (tags) {
      availableTags.assignAll(tags);
    });
    isLoadingTags.value = false;
  }

  bool isTagSelected(String key) => selectedTags.contains(key);

  String get rideTitle {
    final ride = pendingReviewRide.value;
    if (ride == null) return '';
    final displayName = ride.vehicleDisplayName.trim();
    if (displayName.isNotEmpty) return displayName;
    return ride.vehicleType;
  }

  String get rideDateLabel {
    final date = pendingReviewRide.value?.rideCompletedAt;
    if (date == null) return '';
    return DateFormat("dd MMM yyyy . hh:mma").format(date.toLocal());
  }

  String get rideFareLabel {
    final fare = pendingReviewRide.value?.finalFare;
    if (fare == null) return '';
    return CurrencyFormatter.format(fare);
  }

  bool _isWithinPendingReviewWindow(RideRatingRideEntity? ride) {
    final completedAt = ride?.rideCompletedAt;
    if (ride == null || completedAt == null) return ride != null;
    final age = DateTime.now().toUtc().difference(completedAt.toUtc());
    return !age.isNegative && age <= const Duration(hours: 24);
  }

  void _resetSheetState({required bool clearPendingRide}) {
    selectedRating.value = 0;
    availableTags.clear();
    selectedTags.clear();
    commentController.clear();
    commentText.value = '';
    isLoadingTags.value = false;
    _latestTagRequestRating = 0;
    if (clearPendingRide) {
      pendingReviewRide.value = null;
    }
  }

  void _handleFailure(Failure failure) {
    final raw = failure.message.trim();
    final normalized = raw.startsWith('Exception: ')
        ? raw.substring('Exception: '.length)
        : raw;
    final parts = normalized.split('|');
    final errorCode = parts.length > 1 ? parts.first.trim() : '';
    final message = parts.length > 1
        ? parts.sublist(1).join('|').trim()
        : normalized;

    if (errorCode == 'RIDE_ALREADY_RATED') {
      _resetSheetState(clearPendingRide: true);
      closeBottomSheet();
      return;
    }

    AppDialogs.showErrorDialog(
      message: message.isEmpty ? AppStrings.anUnexpectedErrorOccurred.tr : message,
    );
  }

  @override
  void onInit() {
    super.onInit();
    commentController.addListener(_syncCommentText);
  }

  void _syncCommentText() {
    final nextValue = commentController.text;
    if (commentText.value != nextValue) {
      commentText.value = nextValue;
    }
  }

  @override
  void onClose() {
    commentController.removeListener(_syncCommentText);
    commentController.dispose();
    super.onClose();
  }
}
