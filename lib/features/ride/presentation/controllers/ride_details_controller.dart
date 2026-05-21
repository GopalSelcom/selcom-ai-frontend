import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/domain/entities/ride_entity.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/vehicle_image_utils.dart';
import '../../../ride_rating/domain/entities/ride_rating_ride_entity.dart';
import '../../../ride_rating/domain/usecases/get_last_completed_ride_usecase.dart';
import '../../../ride_rating/domain/usecases/get_review_tags_usecase.dart';
import '../../../ride_rating/domain/usecases/skip_ride_rating_usecase.dart';
import '../../../ride_rating/domain/usecases/submit_ride_rating_usecase.dart';
import '../../../ride_rating/presentation/controllers/ride_rating_controller.dart';
import '../../domain/repositories/ride_repository.dart';
import '../../domain/utils/receipt_image_generator.dart';
import '../../domain/utils/receipt_pdf_generator.dart';
import '../widgets/receipt_options_bottom_sheet.dart';

class RideDetailsController extends GetxController {
  RideDetailsController({
    required this.ride,
    this.openedFromCompletionFlow = false,
  });

  RideEntity ride;
  final bool openedFromCompletionFlow;

  late final RideRatingController ratingController;
  late final bool hasExistingRating;
  late final bool canShowReviewInput;

  @override
  void onInit() {
    super.onInit();
    hasExistingRating = (ride.riderRating ?? 0) > 0;
    // Completion-entry should prioritize collecting feedback immediately.
    // My Rides keeps backend-driven visibility via showReviewUi.
    canShowReviewInput = openedFromCompletionFlow
        ? !hasExistingRating
        : (ride.status == RideStatus.rideCompleted && ride.showReviewUi);
    ratingController = _resolveRideRatingController();
    // Prime rating state so the screen can render review inputs immediately.
    if (!hasExistingRating && canShowReviewInput) {
      ratingController.prepareRatingForRide(_toRatingEntity(ride));
    }
  }

  String get vehicleDisplayName {
    final value = (ride.vehicleDisplayName ?? '').trim();
    return value.isNotEmpty ? value : 'Ride';
  }

  String get vehicleTypeForImage {
    final value = (ride.vehicleKey ?? '').trim();
    return value.isNotEmpty ? value : 'Ride';
  }

  String get vehicleImageAsset {
    return VehicleImageUtils.imageAssetForVehicleType(
      vehicleTypeForImage,
      fallbackAsset: AppAssets.imgCab,
    );
  }

  String get formattedDate {
    return DateFormat('yyyy-MM-dd, hh:mm a').format(ride.createdAt);
  }

  bool get isCancelled => ride.status.name == 'cancelled';

  bool get isCompleted => ride.status == RideStatus.rideCompleted;

  int get rideCharge {
    if (isCancelled) return ride.cancellationFee ?? 0;
    return ride.fareBreakdown?.rideCharge ?? ride.fareEstimate;
  }

  int get bookingFee {
    if (isCancelled) return 0;
    return ride.fareBreakdown?.bookingFee ?? 0;
  }

  int get totalAmount {
    if (isCancelled) return ride.cancellationFee ?? 0;
    return ride.fareBreakdown?.totalAmount ??
        ride.finalFare ??
        ride.fareEstimate;
  }

  String get rideChargeLabel => CurrencyFormatter.format(rideCharge);

  String get bookingFeeLabel => CurrencyFormatter.format(bookingFee);

  String get totalAmountLabel => CurrencyFormatter.format(totalAmount);

  /// Promo row on fare card (GET ride returns [promo_code], [promo_discount]).
  bool get showPromoFareLine {
    final code = ride.promoCode?.trim() ?? '';
    final d = ride.promoDiscount ?? 0;
    return code.isNotEmpty && d > 0;
  }

  String get promoFareLineTitle => AppStrings.receiptPromoLine
      .trParams({'code': ride.promoCode!.trim()})
      .tr;

  String get promoFareLineAmountLabel =>
      '-${CurrencyFormatter.format(ride.promoDiscount!)}';

  String get pickupTitle => ride.pickup.address.split(',').first;

  String get destinationTitle => ride.destination.address.split(',').first;

  bool get shouldPrioritizeReviewSection =>
      openedFromCompletionFlow && canShowReviewInput && !hasExistingRating;

  void downloadSlip() {
    ReceiptOptionsBottomSheet.show(
      onDownload: _executeDownload,
      onShare: _executeShare,
    );
  }

  Future<void> _executeDownload() async {
    try {
      AppDialogs.showLoadingDialog();
      final rideRepository = di.sl<RideRepository>();
      final response = await rideRepository.getReceipt(ride.id);
      final receiptModel = response.fold((l) => null, (r) => r);

      if (receiptModel == null) {
        if (Get.isDialogOpen ?? false) Get.back();
        AppDialogs.showErrorDialog(message: 'Could not fetch receipt details.');
        return;
      }

      final file = await ReceiptImageGenerator.generateReceiptImage(
        receipt: receiptModel,
      );

      if (Get.isDialogOpen ?? false) Get.back();

      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        await Gal.requestAccess(toAlbum: true);
      }

      await Gal.putImage(file.path);
      AppDialogs.showSuccessDialog(
        message: 'Receipt saved to your photos gallery.',
      );
    } catch (e, stackTrace) {
      if (Get.isDialogOpen ?? false) Get.back();
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppDialogs.showErrorDialog(
        message: 'Could not download slip. Please try again later.',
      );
    }
  }

  Future<void> _executeShare() async {
    try {
      AppDialogs.showLoadingDialog();

      // 1. Check if we already have a PDF link in the ride object
      String? shareUrl;
      if (ride.pdfLinks != null && ride.pdfLinks!.isNotEmpty) {
        final now = DateTime.now().toUtc();
        // Sort to get the most recent one
        final sortedLinks = List<PdfLinkEntity>.from(ride.pdfLinks!)
          ..sort(
            (a, b) => (b.uploadedAt ?? now).compareTo(
              a.uploadedAt ?? now,
            ),
          );
        shareUrl = sortedLinks.first.url;
      }

      if (shareUrl == null) {
        // 2. No link exists, generate PDF and upload it
        final rideRepository = di.sl<RideRepository>();
        final response = await rideRepository.getReceipt(ride.id);
        final receiptModel = response.fold((l) => null, (r) => r);

        if (receiptModel == null) {
          if (Get.isDialogOpen ?? false) Get.back();
          AppDialogs.showErrorDialog(
            message: AppStrings.couldNotFetchReceiptDetails.tr,
          );
          return;
        }

        final pdfFile = await ReceiptPdfGenerator.generateReceiptPdf(
          receipt: receiptModel,
        );

        // Upload the generated PDF
        final uploadResult = await rideRepository.uploadReceiptPdf(
          rideId: ride.id,
          pdfPath: pdfFile.path,
        );

        if (uploadResult.isLeft()) {
          if (Get.isDialogOpen ?? false) Get.back();
          final failure = uploadResult.fold((l) => l, (r) => null)!;
          AppDialogs.showErrorDialog(message: failure.message);
          return;
        }

        final newLink = uploadResult.fold((l) => null, (r) => r)!;
        // Update local ride object to prevent redundant uploads in the same session
        final updatedLinks = <PdfLinkEntity>[...(ride.pdfLinks ?? []), newLink];
        ride = ride.copyWith(pdfLinks: updatedLinks);

        shareUrl = newLink.url;
      }

      if (Get.isDialogOpen ?? false) Get.back(); // Hide loading

      await SharePlus.instance.share(
        ShareParams(
          text: AppStrings.checkOutMyRideReceiptShareUrl.trParams({
            'url': shareUrl,
          }),
          subject: AppStrings.selcomGoRideReceiptSubject.tr,
        ),
      );
    } catch (e, stackTrace) {
      if (Get.isDialogOpen ?? false) Get.back();
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppDialogs.showErrorDialog(
        message: AppStrings.couldNotShareSlipPleaseTryAgainLater.tr,
      );
    }
  }

  // Map ride details into the rating module contract.
  RideRatingRideEntity _toRatingEntity(RideEntity source) {
    final fareValue =
        source.fareBreakdown?.totalAmount ??
        source.finalFare ??
        source.fareEstimate;
    return RideRatingRideEntity(
      rideId: source.id,
      transactionId: source.id,
      driverName: source.driverSnapshot?.name ?? '',
      driverImage: source.driverSnapshot?.avatarUrl ?? '',
      vehicleType: vehicleTypeForImage,
      vehicleDisplayName: vehicleDisplayName,
      pickupAddress: source.pickup.address,
      destinationAddress: source.destination.address,
      pickupLat: source.pickup.lat,
      pickupLng: source.pickup.lng,
      destinationLat: source.destination.lat,
      destinationLng: source.destination.lng,
      finalFare: fareValue,
      riderRating: source.riderRating,
      rideCompletedAt: source.createdAt,
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
