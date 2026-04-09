import 'package:dartz/dartz.dart';
import '../../../../core/data/models/requests/validate_ride_payment_request.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/data/models/ride_model.dart';
import '../../data/models/ride_management_models.dart';

abstract class RideRepository {
  Future<Either<Failure, List<RecentDestinationModel>>> getRecentDestinations();
  Future<Either<Failure, List<RideModel>>> getRideHistory({int page = 1, int limit = 10});
  Future<Either<Failure, RideModel>> getRideDetails(String rideId);
  Future<Either<Failure, bool>> cancelRide(String rideId, String reason);
  Future<Either<Failure, bool>> updateDestination(String rideId, Map<String, dynamic> destination);
  Future<Either<Failure, bool>> updatePickup(String rideId, Map<String, dynamic> pickup);
  Future<Either<Failure, bool>> increaseFare(String rideId, int newFare);
  Future<Either<Failure, ReceiptModel>> getReceipt(String rideId);
  Future<Either<Failure, bool>> rateDriver(String rideId, int rating, String comment);
  Future<Either<Failure, bool>> submitFeedback(String rideId, String category, String message);
  Future<Either<Failure, String>> validateRidePayment(ValidateRidePaymentRequest request);
}
