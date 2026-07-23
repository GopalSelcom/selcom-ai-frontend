import 'package:dartz/dartz.dart';
import 'package:selcom_rides_frontend/features/ride/data/models/ride_history_model.dart'
    hide Destination;

import '../../../../core/data/models/requests/validate_ride_payment_request.dart';
import '../../../../core/data/models/responses/rides/validate_ride_payment_response.dart';
import '../../../../core/data/models/ride_model.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/destination_update_models.dart';
import '../../data/models/recent_destinations_response.dart';
import '../../data/models/ride_management_models.dart';
import '../repositories/ride_repository.dart';

class RideUseCase {
  final RideRepository repository;

  RideUseCase(this.repository);

  Future<Either<Failure, RideHistoryModelResponse?>> getRideHistory({
    int page = 1,
    int limit = 10,
  }) {
    return repository.getRideHistory(page: page, limit: limit);
  }

  Future<Either<Failure, List<Destination>>> getRecentDestinations() {
    return repository.getRecentDestinations();
  }

  Future<Either<Failure, RideModel>> getRideDetails(String rideId) {
    return repository.getRideDetails(rideId);
  }

  Future<Either<Failure, bool>> cancelRide(String rideId, String reason) {
    return repository.cancelRide(rideId, reason);
  }

  Future<Either<Failure, DestinationUpdatePreviewModel>>
  previewUpdateDestination(String rideId, Map<String, dynamic> destination) {
    return repository.previewUpdateDestination(rideId, destination);
  }

  Future<Either<Failure, DestinationUpdateAppliedModel>>
  confirmUpdateDestination(String rideId, Map<String, dynamic> destination) {
    return repository.confirmUpdateDestination(rideId, destination);
  }

  Future<Either<Failure, ReceiptModel>> getReceipt(String rideId) {
    return repository.getReceipt(rideId);
  }

  Future<Either<Failure, ValidateRidePaymentResponse>> validateRidePayment(
    ValidateRidePaymentRequest request,
  ) {
    return repository.validateRidePayment(request);
  }
}
