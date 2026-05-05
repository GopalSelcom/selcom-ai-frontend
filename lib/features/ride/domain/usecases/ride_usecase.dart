import 'package:dartz/dartz.dart';
import '../../../../core/data/models/ride_model.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/ride_repository.dart';
import '../../../../core/data/models/requests/validate_ride_payment_request.dart';
import '../../data/models/destination_update_models.dart';
import '../../data/models/ride_management_models.dart';

class RideUseCase {
  final RideRepository repository;

  RideUseCase(this.repository);

  Future<Either<Failure, List<RideModel>>> getRideHistory({int page = 1, int limit = 10}) {
    return repository.getRideHistory(page: page, limit: limit);
  }

  Future<Either<Failure, List<RecentDestinationModel>>> getRecentDestinations() {
    return repository.getRecentDestinations();
  }

  Future<Either<Failure, RideModel>> getRideDetails(String rideId) {
    return repository.getRideDetails(rideId);
  }

  Future<Either<Failure, bool>> cancelRide(String rideId, String reason) {
    return repository.cancelRide(rideId, reason);
  }

  Future<Either<Failure, bool>> cancelVoiceCall(String rideId) {
    return repository.cancelVoiceCall(rideId);
  }

  Future<Either<Failure, DestinationUpdatePreviewModel>> previewUpdateDestination(
    String rideId,
    Map<String, dynamic> destination,
  ) {
    return repository.previewUpdateDestination(rideId, destination);
  }

  Future<Either<Failure, DestinationUpdateAppliedModel>> confirmUpdateDestination(
    String rideId,
    Map<String, dynamic> destination,
  ) {
    return repository.confirmUpdateDestination(rideId, destination);
  }

  Future<Either<Failure, bool>> updatePickup(String rideId, Map<String, dynamic> pickup) {
    return repository.updatePickup(rideId, pickup);
  }

  Future<Either<Failure, bool>> increaseFare(String rideId, int newFare) {
    return repository.increaseFare(rideId, newFare);
  }

  Future<Either<Failure, ReceiptModel>> getReceipt(String rideId) {
    return repository.getReceipt(rideId);
  }

  Future<Either<Failure, bool>> rateDriver(String rideId, int rating, String comment) {
    return repository.rateDriver(rideId, rating, comment);
  }

  Future<Either<Failure, bool>> submitFeedback(String rideId, String category, String message) {
    return repository.submitFeedback(rideId, category, message);
  }

  Future<Either<Failure, String>> validateRidePayment(ValidateRidePaymentRequest request) {
    return repository.validateRidePayment(request);
  }
}
