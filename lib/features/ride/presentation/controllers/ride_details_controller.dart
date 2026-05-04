import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/domain/entities/ride_entity.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/vehicle_image_utils.dart';
import '../../../ride_rating/domain/entities/ride_rating_ride_entity.dart';
import '../../../ride_rating/domain/usecases/get_last_completed_ride_usecase.dart';
import '../../../ride_rating/domain/usecases/get_review_tags_usecase.dart';
import '../../../ride_rating/domain/usecases/skip_ride_rating_usecase.dart';
import '../../../ride_rating/domain/usecases/submit_ride_rating_usecase.dart';
import '../../../ride_rating/presentation/controllers/ride_rating_controller.dart';
import '../../domain/repositories/ride_repository.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../domain/utils/receipt_image_generator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/utils/receipt_pdf_generator.dart';

class RideDetailsController extends GetxController {
  RideDetailsController({
    required this.ride,
    this.openedFromCompletionFlow = false,
  });

  final RideEntity ride;
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

  String get pickupTitle => ride.pickup.address.split(',').first;

  String get destinationTitle => ride.destination.address.split(',').first;

  bool get shouldPrioritizeReviewSection =>
      openedFromCompletionFlow && canShowReviewInput && !hasExistingRating;

  void downloadSlip() {
    Get.bottomSheet(
      _ReceiptOptionsBottomSheet(
        onDownload: _executeDownload,
        onShare: _executeShare,
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
        message: 'Could download slip. Please try again later.',
      );
    }
  }

  Future<void> _executeShare() async {
    try {
      AppDialogs.showLoadingDialog();

      // 1. Check if we already have a valid PDF link in the ride object
      PdfLinkEntity? validLink;
      if (ride.pdfLinks != null && ride.pdfLinks!.isNotEmpty) {
        // Sort to get the most recent one
        final sortedLinks = List<PdfLinkEntity>.from(ride.pdfLinks!)
          ..sort(
            (a, b) => (b.uploadedAt ?? DateTime.now()).compareTo(
              a.uploadedAt ?? DateTime.now(),
            ),
          );

        final latestLink = sortedLinks.first;
        // Check if link is expired (compare with today's date)
        if (latestLink.expiresAt == null ||
            latestLink.expiresAt!.isAfter(DateTime.now())) {
          validLink = latestLink;
        }
      }

      String? shareUrl;
      if (validLink != null) {
        shareUrl = validLink.url;
      } else {
        // 2. No valid link exists, generate PDF and upload it
        final rideRepository = di.sl<RideRepository>();
        final response = await rideRepository.getReceipt(ride.id);
        final receiptModel = response.fold((l) => null, (r) => r);

        if (receiptModel == null) {
          if (Get.isDialogOpen ?? false) Get.back();
          AppDialogs.showErrorDialog(message: 'Could not fetch receipt details.');
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

        shareUrl = uploadResult.fold((l) => null, (r) => r.url);
      }

      if (Get.isDialogOpen ?? false) Get.back(); // Hide loading

      if (shareUrl != null) {
        await Share.share(
          'Check out my ride receipt: $shareUrl',
          subject: 'Selcom Go Ride Receipt',
        );
      } else {
        AppDialogs.showErrorDialog(message: 'Could not generate share link.');
      }
    } catch (e, stackTrace) {
      if (Get.isDialogOpen ?? false) Get.back();
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppDialogs.showErrorDialog(
        message: 'Could not share slip. Please try again later.',
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

class _ReceiptOptionsBottomSheet extends StatelessWidget {
  final VoidCallback onDownload;
  final VoidCallback onShare;

  const _ReceiptOptionsBottomSheet({
    required this.onDownload,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.fromLTRB(0,0,0,24.h),
            decoration: BoxDecoration(
              color: AppColors.dividerHandle,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Text(
            'Receipt Options',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 20.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            'Choose how you would like to receive your receipt',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.h),
          _OptionTile(
            icon: Icons.download_rounded,
            title: 'Download Slip',
            subtitle: 'Save a copy to your gallery',
            onTap: () {
              Get.back();
              onDownload();
            },
          ),
          SizedBox(height: 16.h),
          _OptionTile(
            icon: Icons.share_rounded,
            title: 'Share Slip',
            subtitle: 'Send receipt link to others',
            onTap: () {
              Get.back();
              onShare();
            },
          ),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 24.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 16.sp),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textMuted,
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }
}
