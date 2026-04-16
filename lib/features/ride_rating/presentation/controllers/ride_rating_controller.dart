import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/analytics_service.dart';
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

  final Rxn<RideRatingRideEntity> pendingReviewRide = Rxn<RideRatingRideEntity>();
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

  Future<void> tryOpenRatingSheetAfterHomeLoad() async {
    if (_hasPromptedThisSession) return;
    _hasPromptedThisSession = true;
    await _loadPendingReviewRide();
    if (pendingReviewRide.value != null) {
      _openRatingBottomSheet();
    }
  }

  Future<void> _loadPendingReviewRide() async {
    isLoadingRide.value = true;
    final result = await getLastCompletedRideUseCase();
    result.fold(
      (failure) => _handleFailure(failure),
      (ride) => pendingReviewRide.value = _isWithinPendingReviewWindow(ride)
          ? ride
          : null,
    );
    isLoadingRide.value = false;
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

  Future<void> onSubmitTap() async {
    final ride = pendingReviewRide.value;
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
    if (selectedTags.isEmpty) {
      Get.snackbar(
        'Tag required',
        'Please select at least one tag before submitting.',
      );
      return;
    }
    final comment = requiresComment ? commentController.text.trim() : '';
    if (requiresComment && comment.isEmpty) {
      Get.snackbar('Comment required', 'Please enter your comment first.');
      return;
    }

    isSubmitting.value = true;
    final result = await submitRideRatingUseCase(
      rideId: ride.rideId,
      rating: selectedRating.value,
      tags: selectedTags.toList(),
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
        parameters: {
          'ride_id': ride.rideId,
          'rating': selectedRating.value,
          'tags_count': selectedTags.length,
        },
      );
      _resetSheetState(clearPendingRide: true);
      closeBottomSheet();
      Get.snackbar('Thank you', 'Your rating has been submitted.');
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
        Get.snackbar('Skip failed', 'Unable to skip rating now.');
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
    if (Get.isBottomSheetOpen ?? false) {
      Get.close(1);
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
    return 'TZS ${fare.toString()}';
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

    Get.snackbar(
      'Error',
      message.isEmpty ? 'Something went wrong.' : message,
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
