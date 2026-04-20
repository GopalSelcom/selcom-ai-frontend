import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/data/models/ride_model.dart';
import '../../../../core/domain/entities/ride_entity.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/ride_rating/domain/entities/ride_rating_ride_entity.dart';
import '../../../../features/ride_rating/domain/usecases/get_last_completed_ride_usecase.dart';
import '../../../../features/ride_rating/domain/usecases/get_review_tags_usecase.dart';
import '../../../../features/ride_rating/domain/usecases/skip_ride_rating_usecase.dart';
import '../../../../features/ride_rating/domain/usecases/submit_ride_rating_usecase.dart';
import '../../../../features/ride_rating/presentation/controllers/ride_rating_controller.dart';
import '../../../../features/ride_rating/presentation/widgets/ride_rating_input_section.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import 'ride_common_widgets.dart';

class RideDetailsBottomSheet extends StatefulWidget {
  final RideModel ride;

  const RideDetailsBottomSheet({super.key, required this.ride});

  @override
  State<RideDetailsBottomSheet> createState() => _RideDetailsBottomSheetState();
}

class _RideDetailsBottomSheetState extends State<RideDetailsBottomSheet> {
  late final RideRatingController _ratingController;
  late final bool _hasExistingRating;
  late final bool _canShowReviewInput;

  RideRatingRideEntity _toRatingEntity(RideModel source) {
    final vehicleType = source.vehicleSnapshot?.vehicleType ?? '';
    final displayName = source.vehicleSnapshot?.vehicleType ?? vehicleType;
    final fareValue =
        source.fareBreakdown?.totalAmount ??
        source.finalFare ??
        source.fareEstimate;

    return RideRatingRideEntity(
      rideId: source.id,
      transactionId: source.id,
      driverName: source.driverSnapshot?.name ?? '',
      driverImage: source.driverSnapshot?.avatarUrl ?? '',
      vehicleType: vehicleType,
      vehicleDisplayName: displayName,
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

  @override
  void initState() {
    super.initState();
    _hasExistingRating = (widget.ride.riderRating ?? 0) > 0;
    _canShowReviewInput =
        widget.ride.status == RideStatus.rideCompleted && widget.ride.showReviewUi;
    _ratingController = _resolveRideRatingController();
    if (!_hasExistingRating && _canShowReviewInput) {
      _ratingController.prepareRatingForRide(_toRatingEntity(widget.ride));
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      'yyyy-MM-dd, hh:mm a',
    ).format(widget.ride.createdAt);
    final isCancelled = widget.ride.status.name == 'cancelled';
    final fare = widget.ride.fareBreakdown;
    final rideCharge = isCancelled
        ? (widget.ride.cancellationFee ?? 0)
        : (fare?.rideCharge ?? widget.ride.fareEstimate);
    final bookingFee = isCancelled ? 0 : (fare?.bookingFee ?? 0);
    final totalAmount = isCancelled
        ? (widget.ride.cancellationFee ?? 0)
        : (fare?.totalAmount ??
              widget.ride.finalFare ??
              widget.ride.fareEstimate);

    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 24.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(37.r),
          topRight: Radius.circular(37.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12.h),
          // Drag handle
          Container(
            width: 48.w,
            height: 5.h,
            decoration: BoxDecoration(
              color: const Color(0xFFE6E9EE),
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          SizedBox(height: 16.h),

          Text(
            'Your Rides',
            style: TextStyle(
              fontFamily: AppTextStyles.metropolisFont,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              fontSize: 20.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),

          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Vehicle Type and Image Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.ride.vehicleSnapshot?.vehicleType ?? 'Boda',
                            style: TextStyle(
                              fontFamily: AppTextStyles.metropolisFont,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                              fontSize: 20.sp,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            RideDateFormatter.formatDate(formattedDate),
                            style: TextStyle(
                              fontFamily: AppTextStyles.metropolisFont,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF364B63),
                              fontSize: 15.sp,
                            ),
                          ),
                        ],
                      ),
                      Image.asset(
                        'assets/images/img_boda.png',
                        height: 60.h,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.two_wheeler,
                          size: 50.w,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // Pick and Drop locations
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FD),
                      border: Border.all(
                        color: const Color(0xFFE6E9EE),
                        width: 0.78,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: RideLocationsTimeline(
                      startLocation: widget.ride.pickup.address
                          .split(',')
                          .first,
                      startAddress: widget.ride.pickup.address,
                      endLocation: widget.ride.destination.address
                          .split(',')
                          .first,
                      endAddress: widget.ride.destination.address,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Total Fare
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FD),
                      border: Border.all(
                        color: const Color(0xFFE6E9EE),
                        width: 0.78,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Fare',
                          style: TextStyle(
                            fontFamily: AppTextStyles.metropolisFont,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                            fontSize: 15.sp,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        FareBreakdownRow(
                          title: 'Ride Charge',
                          amount: 'TZS $rideCharge',
                        ),
                        SizedBox(height: 12.h),
                        FareBreakdownRow(
                          title: 'Booking Fees & Convenience Charges',
                          amount: 'TZS $bookingFee',
                        ),
                        SizedBox(height: 12.h),
                        FareBreakdownRow(
                          title: 'Total Amount',
                          amount: 'TZS $totalAmount',
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  _hasExistingRating
                      ? Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FD),
                            border: Border.all(
                              color: const Color(0xFFE6E9EE),
                              width: 0.78,
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'How was your ride?',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.metropolisFont,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                  fontSize: 15.sp,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              RideRatingStars(
                                rating:
                                    (widget.ride.riderRating?.toDouble() ?? 0),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                '${widget.ride.riderRating}/5 rating given',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.metropolisFont,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textGrey,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _canShowReviewInput
                          ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: 12.h),
                            RideRatingInputSection(
                              controller: _ratingController,
                              starSize: 40,
                            ),
                          ],
                          )
                          : const SizedBox.shrink(),
                  SizedBox(height: 24.h),

                  // Need Help
                  const NeedHelpRow(),
                ],
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // Done Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: (_hasExistingRating || !_canShowReviewInput)
                ? AppPrimaryButton(
                    label: 'Done',
                    onPressed: () => Navigator.pop(context),
                  )
                : Obx(
                    () => AppPrimaryButton(
                      label: 'Done',
                      isLoading: _ratingController.isSubmitting.value,
                      onPressed: _ratingController.canSubmit
                          ? _ratingController.onSubmitTap
                          : null,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
