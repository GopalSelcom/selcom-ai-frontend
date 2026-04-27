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

class RideDetailsController extends GetxController {
  RideDetailsController({required this.ride});

  final RideEntity ride;

  late final RideRatingController ratingController;
  late final bool hasExistingRating;
  late final bool canShowReviewInput;

  @override
  void onInit() {
    super.onInit();
    hasExistingRating = (ride.riderRating ?? 0) > 0;
    canShowReviewInput =
        ride.status == RideStatus.rideCompleted && ride.showReviewUi;
    ratingController = _resolveRideRatingController();
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
