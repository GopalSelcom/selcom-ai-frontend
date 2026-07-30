import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/data/models/responses/rides/ride_details_response.dart';
import '../../../../core/data/models/ride_model.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/fare_breakdown_display.dart';
import '../../../../shared/utils/vehicle_image_utils.dart';
import '../../../ride_rating/data/models/pending_review_response.dart';
import '../../../ride_rating/domain/usecases/get_last_completed_ride_usecase.dart';
import '../../../ride_rating/domain/usecases/get_review_tags_usecase.dart';
import '../../../ride_rating/domain/usecases/skip_ride_rating_usecase.dart';
import '../../../ride_rating/domain/usecases/submit_ride_rating_usecase.dart';
import '../../../ride_rating/presentation/controllers/ride_rating_controller.dart';
import '../../domain/repositories/ride_repository.dart';
import '../../data/models/receipt_response.dart';
import '../utils/mid_ride_cancel_copy.dart';
import '../utils/receipt_image_generator.dart';
import '../utils/receipt_pdf_generator.dart';
import '../widgets/receipt_options_bottom_sheet.dart';

class RideDetailsController extends GetxController {
  RideDetailsController({
    required this.ride,
    this.openedFromCompletionFlow = false,
    this.refreshOnInit = true,
  });

  RideDetailsRide ride;
  final bool openedFromCompletionFlow;
  /// When false, caller already fetched ride details (My Rides tap, completion handoff).
  final bool refreshOnInit;

  late final RideRatingController ratingController;
  final isLoadingRideDetails = true.obs;

  int get _riderRatingValue {
    final raw = ride.riderRating;
    return raw is num ? raw.toInt() : 0;
  }

  bool get hasExistingRating => _riderRatingValue > 0;

  /// Completion-entry should prioritize collecting feedback immediately.
  /// My Rides keeps backend-driven visibility via showReviewUi.
  bool get canShowReviewInput => openedFromCompletionFlow
      ? !hasExistingRating
      : (ride.isCompleted && (ride.showReviewUi ?? true));

  @override
  void onInit() {
    super.onInit();
    ratingController = _resolveRideRatingController();
    // Avoid duplicate GET /rides/:id when navigation already supplied fresh data.
    if (refreshOnInit) {
      unawaited(_loadRideDetails());
    } else {
      isLoadingRideDetails.value = false;
      _primeRatingIfNeeded();
    }
  }

  Future<void> _loadRideDetails() async {
    isLoadingRideDetails.value = true;
    try {
      final rideRepository = di.sl<RideRepository>();
      final result = await rideRepository.getRideDetails(ride.id ?? '');
      result.fold(
        (failure) => AppDialogs.showErrorDialog(message: failure.message),
        (freshRide) {
          ride = freshRide;
          _primeRatingIfNeeded();
        },
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppDialogs.showErrorDialog(
        message: AppStrings.anUnexpectedErrorOccurred.tr,
      );
    } finally {
      isLoadingRideDetails.value = false;
    }
  }

  void _primeRatingIfNeeded() {
    if (!hasExistingRating && canShowReviewInput) {
      ratingController.prepareRatingForRide(_toPendingReview(ride));
    }
  }

  String get vehicleDisplayName {
    final value = ride.vehicleDisplayNameResolved;
    return value.isNotEmpty ? value : 'Ride';
  }

  String get vehicleTypeForImage {
    final candidates = [
      ride.vehicleKeyResolved,
      ride.vehicleDisplayNameResolved,
      ride.vehicleSnapshot?.vehicleType,
    ];
    for (final value in candidates) {
      final trimmed = (value ?? '').trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return 'cab';
  }

  String get vehicleImageAsset {
    return VehicleImageUtils.imageAssetForVehicleType(
      vehicleTypeForImage,
      fallbackAsset: AppAssets.imgCab,
    );
  }

  String get formattedDate {
    final date = DateTime.tryParse(ride.createdAt ?? '') ?? DateTime.now();
    return DateFormat('yyyy-MM-dd, hh:mm a').format(date);
  }

  bool get isCancelled => ride.isCancelled;

  bool get isMidRideDriverCancelled => ride.isMidRideDriverCancel;

  bool get isCompleted => ride.isCompleted;

  /// Cancel / mid-ride cancel reason shown above fare `line_items`.
  bool get hasCancellationContext {
    if (isMidRideDriverCancelled) {
      final block = ride.midRideCancel;
      if (block == null) return false;
      return (block.reason ?? '').trim().isNotEmpty ||
          (block.reasonText ?? '').trim().isNotEmpty;
    }
    return isCancelled && ride.shouldShowCancellationReason;
  }

  String get cancellationContextText {
    if (isMidRideDriverCancelled) {
      final block = ride.midRideCancel;
      return midRideCancelReasonLabel(
        reason: block?.reason,
        reasonText: block?.reasonText,
      );
    }
    return _cancelledRideReasonLabel;
  }

  /// Human-readable reason for rider cancels (system / no-show are hidden).
  String get _cancelledRideReasonLabel {
    final raw = ride.displayCancellationReason.trim();
    if (raw.isNotEmpty) return raw;
    return AppStrings.cancellationReasonByRider.tr;
  }

  String? get midRideCancelMessage {
    if (!isMidRideDriverCancelled) return null;
    final message = ride.midRideCancel?.message?.trim() ?? '';
    return message.isEmpty ? null : message;
  }

  /// Total Fare rows from `fare_breakdown.line_items` (API order).
  List<FareBreakdownDisplayRow> get fareLineRows {
    final lineItems = ride.fareBreakdown?.lineItems;
    if (!FareBreakdownDisplay.hasLineItems(lineItems)) {
      return const [];
    }
    return FareBreakdownDisplay.rowsFromLineItems(lineItems!);
  }

  bool get hasFareLineItems => fareLineRows.isNotEmpty;

  String get fareCardTitle {
    if (isMidRideDriverCancelled) {
      return AppStrings.tripEndedByDriver.tr;
    }
    return AppStrings.totalFare.tr;
  }

  String get pickupTitle => (ride.pickup?.address ?? '').split(',').first;

  String get destinationTitle =>
      (ride.destination?.address ?? '').split(',').first;

  /// Adapts raw API stop payloads into [RideStopModel] for [RideLocationsTimeline]
  /// / [RideDetailsScreenShimmer], which are shared across the ride flows.
  List<RideStopModel> get timelineStops {
    return (ride.stops ?? []).map((stop) {
      return RideStopModel(
        index: stop.index ?? 0,
        lat: stop.lat ?? 0,
        lng: stop.lng ?? 0,
        address: stop.address ?? '',
        status: stop.status ?? '',
        arrivedAt: _tryParseDynamicDate(stop.arrivedAt),
        completedAt: _tryParseDynamicDate(stop.completedAt),
      );
    }).toList();
  }

  DateTime? _tryParseDynamicDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  bool get shouldPrioritizeReviewSection =>
      openedFromCompletionFlow && canShowReviewInput && !hasExistingRating;

  void downloadSlip() {
    ReceiptOptionsBottomSheet.show(
      onDownload: _executeDownload,
      onShare: _executeShare,
    );
  }

  /// Waits until [AppDialogs.showLoadingDialog] route is mounted before dismiss.
  Future<void> _showReceiptSlipLoading() async {
    AppDialogs.showLoadingDialog();
    await Future<void>.delayed(Duration.zero);
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _dismissReceiptSlipLoading() async {
    AppDialogs.dismissLoadingDialog();
  }

  Future<void> _executeDownload() async {
    await _showReceiptSlipLoading();
    try {
      final rideRepository = di.sl<RideRepository>();
      final response = await rideRepository.getReceipt(ride.id ?? '');
      final receiptModel = response.fold((l) => null, (r) => r);

      if (receiptModel == null) {
        await _dismissReceiptSlipLoading();
        AppDialogs.showErrorDialog(
          message: AppStrings.couldNotFetchReceiptDetails.tr,
        );
        return;
      }

      final file = await ReceiptImageGenerator.generateReceiptImage(
        receipt: _receiptForDisplay(receiptModel),
      );

      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        await Gal.requestAccess(toAlbum: true);
      }

      await Gal.putImage(file.path);
      await _dismissReceiptSlipLoading();
      AppDialogs.showSuccessDialog(
        message: AppStrings.receiptSavedToGallery.tr,
      );
    } catch (e, stackTrace) {
      await _dismissReceiptSlipLoading();
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppDialogs.showErrorDialog(
        message: AppStrings.couldNotDownloadSlipPleaseTryAgainLater.tr,
      );
    }
  }

  Future<void> _executeShare() async {
    var loadingShown = false;
    try {
      // 1. Check if we already have a PDF link in the ride object
      String? shareUrl;
      final existingLinks = ride.pdfLinks;
      if (existingLinks != null && existingLinks.isNotEmpty) {
        final now = DateTime.now().toUtc();
        // Sort to get the most recent one
        final sortedLinks = List<RideDetailsPdfLink>.from(existingLinks)
          ..sort((a, b) {
            final aDate = DateTime.tryParse(a.uploadedAt ?? '') ?? now;
            final bDate = DateTime.tryParse(b.uploadedAt ?? '') ?? now;
            return bDate.compareTo(aDate);
          });
        shareUrl = sortedLinks.first.url;
      }

      if (shareUrl == null) {
        await _showReceiptSlipLoading();
        loadingShown = true;

        // 2. No link exists, generate PDF and upload it
        final rideRepository = di.sl<RideRepository>();
        final response = await rideRepository.getReceipt(ride.id ?? '');
        final receiptModel = response.fold((l) => null, (r) => r);

        if (receiptModel == null) {
          await _dismissReceiptSlipLoading();
          loadingShown = false;
          AppDialogs.showErrorDialog(
            message: AppStrings.couldNotFetchReceiptDetails.tr,
          );
          return;
        }

        final pdfFile = await ReceiptPdfGenerator.generateReceiptPdf(
          receipt: _receiptForDisplay(receiptModel),
        );

        // Upload the generated PDF
        final uploadResult = await rideRepository.uploadReceiptPdf(
          rideId: ride.id ?? '',
          pdfPath: pdfFile.path,
        );

        if (uploadResult.isLeft()) {
          final failure = uploadResult.fold((l) => l, (r) => null)!;
          await _dismissReceiptSlipLoading();
          loadingShown = false;
          AppDialogs.showErrorDialog(message: failure.message);
          return;
        }

        final newLink = uploadResult.fold((l) => null, (r) => r)!;
        // Update local ride object to prevent redundant uploads in the same session
        final newDetailsLink = RideDetailsPdfLink(
          url: newLink.url,
          token: newLink.token,
          originalName: newLink.originalName,
          expiresAt: newLink.expiresAt?.toIso8601String(),
          uploadedAt: newLink.uploadedAt?.toIso8601String(),
        );
        ride.pdfLinks = [...(ride.pdfLinks ?? []), newDetailsLink];

        shareUrl = newLink.url;
      }

      if (loadingShown) {
        await _dismissReceiptSlipLoading();
        loadingShown = false;
      }

      await SharePlus.instance.share(
        ShareParams(
          text: AppStrings.checkOutMyRideReceiptShareUrl.trParams({
            'url': shareUrl,
          }),
          subject: AppStrings.selcomGoRideReceiptSubject.tr,
        ),
      );
    } catch (e, stackTrace) {
      if (loadingShown) {
        await _dismissReceiptSlipLoading();
      }
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppDialogs.showErrorDialog(
        message: AppStrings.couldNotShareSlipPleaseTryAgainLater.tr,
      );
    }
  }

  ReceiptModel _receiptForDisplay(ReceiptModel receipt) {
    final fallback = (ride.transid ?? '').trim();
    if (receipt.transactionId.trim().isNotEmpty || fallback.isEmpty) {
      return receipt;
    }
    return receipt.copyWith(transactionId: fallback);
  }

  // Map ride details into the pending-review model used by rating UI.
  PendingReview _toPendingReview(RideDetailsRide source) {
    final driver = source.driverSnapshot;
    final transid = source.transid?.trim() ?? '';
    return PendingReview(
      rideId: source.id,
      transid: transid.isNotEmpty ? transid : source.id,
      driverSnapshot: DriverSnapshot(
        name: driver?.name,
        avatarUrl: driver?.avatarUrl,
        vehicleType: vehicleTypeForImage,
      ),
      vehicleSnapshot: VehicleSnapshot(
        vehicleName: vehicleTypeForImage,
        displayName: vehicleDisplayName,
      ),
      pickup: Pickup(
        lat: source.pickup?.lat,
        lng: source.pickup?.lng,
        address: source.pickup?.address,
      ),
      destination: PendingReviewDestination(
        lat: source.destination?.lat,
        lng: source.destination?.lng,
        address: source.destination?.address,
      ),
      finalFare: source.displayTotalAmount,
      riderRating: _riderRatingValue,
      rideCompletedAt: (DateTime.tryParse(source.createdAt ?? '') ??
              DateTime.now())
          .toUtc()
          .toIso8601String(),
    );
  }

  RideRatingController _resolveRideRatingController() {
    if (Get.isRegistered<RideRatingController>()) {
      return Get.find<RideRatingController>();
    }
    // Keep one shared rating controller instance across flows/screens.
    return Get.put<RideRatingController>(
      RideRatingController(
        getLastCompletedRideUseCase: di.sl<GetLastCompletedRideUseCase>(),
        getReviewTagsUseCase: di.sl<GetReviewTagsUseCase>(),
        submitRideRatingUseCase: di.sl<SubmitRideRatingUseCase>(),
        skipRideRatingUseCase: di.sl<SkipRideRatingUseCase>(),
        analyticsService: di.sl<AnalyticsService>(),
      ),
      permanent: true,
    );
  }
}
