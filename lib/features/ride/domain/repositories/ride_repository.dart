import 'package:dartz/dartz.dart';

import '../../../../core/data/models/requests/book_ride_request.dart';
import '../../../../core/data/models/requests/fare_estimate_request.dart';
import '../../../../core/data/models/requests/validate_ride_payment_request.dart';
import '../../../../core/data/models/responses/rides/active_ride_response.dart';
import '../../../../core/data/models/responses/rides/book_rides_response.dart';
import '../../../../core/data/models/responses/rides/fare_estimate_response.dart';
import '../../../../core/data/models/responses/rides/promo_validate_response.dart';
import '../../../../core/data/models/responses/rides/validate_ride_payment_response.dart';
import '../../../../core/data/models/responses/rides/vehicle_types_response.dart';
import '../../../../core/data/models/ride_model.dart';
import '../../../../core/errors/failures.dart';
import '../../../wallet/data/models/go_card_balance_response.dart';
import '../../data/models/destination_update_models.dart';
import '../../data/models/emergency_contacts_response.dart';
import '../../data/models/mid_ride_cancel_models.dart';
import '../../data/models/recent_destinations_response.dart';
import '../../data/models/ride_history_model.dart';
import '../../data/models/ride_management_models.dart';

abstract class RideRepository {
  Future<Either<Failure, List<VehicleType>>> getVehicleTypes();

  Future<Either<Failure, FareEstimateResponseModel>> estimateFare(
    FareEstimateRequest request,
  );

  Future<Either<Failure, BookRideResponse>> bookRide(BookRideRequest request);

  Future<Either<Failure, PromoValidateData>> validatePromo({
    required String code,
    required String vehicleTypeId,
    required int fareEstimate,
  });

  Future<Either<Failure, ActiveRideResponseModel?>> getActiveRide();

  Future<Either<Failure, List<RecentDestination>>> getRecentDestinations();

  Future<Either<Failure, RideHistoryModelResponse?>> getRideHistory({
    int page = 1,
    int limit = 10,
  });

  Future<Either<Failure, RideModel>> getRideDetails(String rideId);

  Future<Either<Failure, RideCancellationChargesModel>> getCancellationCharges(
    String rideId,
  );

  Future<Either<Failure, bool>> cancelRide(String rideId, String reason);

  Future<Either<Failure, DisputeChargeResult>> disputeCharge(
    String rideId, {
    String? reason,
  });

  Future<Either<Failure, DestinationUpdatePreviewModel>>
  previewUpdateDestination(String rideId, Map<String, dynamic> destination);

  Future<Either<Failure, DestinationUpdateAppliedModel>>
  confirmUpdateDestination(String rideId, Map<String, dynamic> destination);

  Future<Either<Failure, ReceiptModel>> getReceipt(String rideId);

  Future<Either<Failure, ValidateRidePaymentResponse>> validateRidePayment(
    ValidateRidePaymentRequest request,
  );

  Future<Either<Failure, GoCardBalanceResponseModel>> getWalletBalance();

  Future<Either<Failure, bool>> walletDummyPaymentRequest(
    DummyPaymentRequest request,
  );

  Future<Either<Failure, bool>> updateActivityToken(
    String rideId,
    String token,
  );

  Future<Either<Failure, dynamic>> updateStops(
    String rideId, {
    required List<Map<String, dynamic>> stops,
    bool confirm = false,
    required String idempotencyKey,
  });

  Future<Either<Failure, CheckBookModeResult>> checkBookMode({
    required double riderLat,
    required double riderLng,
    required double pickupLat,
    required double pickupLng,
  });

  Future<Either<Failure, EmergencyContactsResponse>> getEmergencyContacts();

  Future<Either<Failure, PdfLinkModel>> uploadReceiptPdf({
    required String rideId,
    required String pdfPath,
  });
}
