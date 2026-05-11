import 'package:dartz/dartz.dart';
import '../../../../core/data/models/requests/validate_ride_payment_request.dart';
import '../../../../core/data/models/responses/rides/active_ride_response.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/data/models/ride_model.dart';
import '../../data/models/emergency_contacts_response.dart';
import '../../data/models/destination_update_models.dart';
import '../../data/models/ride_management_models.dart';

abstract class RideRepository {
  Future<Either<Failure, ActiveRideResponseModel?>> getActiveRide();
  Future<Either<Failure, List<RecentDestinationModel>>> getRecentDestinations();
  Future<Either<Failure, List<RideModel>>> getRideHistory({
    int page = 1,
    int limit = 10,
  });
  Future<Either<Failure, RideModel>> getRideDetails(String rideId);
  Future<Either<Failure, RideCancellationChargesModel>> getCancellationCharges(
    String rideId,
  );
  Future<Either<Failure, bool>> cancelRide(String rideId, String reason);
  Future<Either<Failure, bool>> cancelVoiceCall(String rideId);
  Future<Either<Failure, DestinationUpdatePreviewModel>> previewUpdateDestination(
    String rideId,
    Map<String, dynamic> destination,
  );
  Future<Either<Failure, DestinationUpdateAppliedModel>> confirmUpdateDestination(
    String rideId,
    Map<String, dynamic> destination,
  );
  Future<Either<Failure, bool>> updatePickup(
    String rideId,
    Map<String, dynamic> pickup,
  );
  Future<Either<Failure, bool>> increaseFare(String rideId, int newFare);
  Future<Either<Failure, ReceiptModel>> getReceipt(String rideId);
  Future<Either<Failure, bool>> rateDriver(
    String rideId,
    int rating,
    String comment,
  );
  Future<Either<Failure, bool>> submitFeedback(
    String rideId,
    String category,
    String message,
  );
  Future<Either<Failure, String>> validateRidePayment(
    ValidateRidePaymentRequest request,
  );
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

  Future<Either<Failure, void>> cancelPendingStops(String rideId);
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
