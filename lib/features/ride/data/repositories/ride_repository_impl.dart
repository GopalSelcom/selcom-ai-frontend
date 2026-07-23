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
import '../../../../core/errors/insufficient_wallet_balance_exception.dart';
import '../../../../core/errors/ride_payment_validation_exception.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../shared/utils/ride_payment_validation_messages.dart';
import '../../../wallet/data/models/go_card_balance_response.dart';
import '../../domain/repositories/ride_repository.dart';
import '../datasources/ride_remote_data_source.dart';
import '../models/destination_update_models.dart';
import '../models/emergency_contacts_response.dart';
import '../models/mid_ride_cancel_models.dart';
import '../models/recent_destinations_response.dart';
import '../models/ride_history_model.dart';
import '../models/cancel_ride_response.dart';
import '../models/cancellation_charges_response.dart';
import '../models/receipt_response.dart';
import '../models/ride_management_models.dart';

class RideRepositoryImpl implements RideRepository {
  final RideRemoteDataSource remoteDataSource;

  RideRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<VehicleType>>> getVehicleTypes() async {
    try {
      final response = await remoteDataSource.getVehicleTypes();
      if (!response.isSuccess) {
        return const Right([]);
      }
      return Right(response.vehicleTypes);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FareEstimateResponse>> estimateFare(
    FareEstimateRequest request,
  ) async {
    try {
      final response = await remoteDataSource.estimateFare(request);
      if (response.statusCode != 200 || response.data == null) {
        final msg = (response.message ?? '').trim();
        final display = msg.isEmpty
            ? 'Unable to estimate fare for this route.'
            : msg;
        final code = response.errorCode?.trim();
        final failureMessage = (code != null && code.isNotEmpty)
            ? '$code|$display'
            : display;
        return Left(ServerFailure(failureMessage));
      }
      return Right(response);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BookRideResponse>> bookRide(
    BookRideRequest request,
  ) async {
    try {
      final result = await remoteDataSource.bookRide(request);
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PromoValidateData>> validatePromo({
    required String code,
    required String vehicleTypeId,
    required int fareEstimate,
  }) async {
    try {
      final r = await remoteDataSource.validatePromo(
        code: code,
        vehicleTypeId: vehicleTypeId,
        fareEstimate: fareEstimate,
      );
      if (r.statusCode == 200 && r.data != null) {
        return Right(r.data!);
      }
      final err = r.errorCode?.trim();
      final msg = (r.message ?? '').trim();
      return Left(
        PromoValidationFailure(
          msg.isEmpty ? 'Promo code cannot be applied.' : msg,
          errorCode: (err == null || err.isEmpty) ? null : err,
        ),
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GoCardBalanceResponseModel>> getWalletBalance() async {
    try {
      final result = await remoteDataSource.getWalletBalance();
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ActiveRideResponseModel?>> getActiveRide() async {
    try {
      final result = await remoteDataSource.getActiveRide();
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RecentDestination>>>
  getRecentDestinations() async {
    try {
      final result = await remoteDataSource.getRecentDestinations();
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RideHistoryModelResponse?>> getRideHistory({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final result = await remoteDataSource.getRideHistory(
        page: page,
        limit: limit,
      );
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RideModel>> getRideDetails(String rideId) async {
    try {
      final result = await remoteDataSource.getRideDetails(rideId);
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RideCancellationChargesData>> getCancellationCharges(
    String rideId,
  ) async {
    try {
      final result = await remoteDataSource.getCancellationCharges(rideId);
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CancelRideData>> cancelRide(
    String rideId,
    String reason,
  ) async {
    try {
      final result = await remoteDataSource.cancelRide(rideId, reason);
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DisputeChargeResult>> disputeCharge(
    String rideId, {
    String? reason,
  }) async {
    try {
      final result = await remoteDataSource.disputeCharge(
        rideId,
        reason: reason,
      );
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      final message = e.toString();
      if (message.contains('dispute_window_closed')) {
        return Left(ServerFailure('dispute_window_closed'));
      }
      return Left(ServerFailure(message));
    }
  }

  @override
  Future<Either<Failure, DestinationUpdatePreviewModel>>
  previewUpdateDestination(
    String rideId,
    Map<String, dynamic> destination,
  ) async {
    try {
      final result = await remoteDataSource.previewUpdateDestination(
        rideId,
        destination,
      );
      return Right(result);
    } on InsufficientWalletBalanceException catch (e) {
      return Left(InsufficientWalletBalanceFailure('', details: e.details));
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(_exceptionMessage(e)));
    }
  }

  @override
  Future<Either<Failure, DestinationUpdateAppliedModel>>
  confirmUpdateDestination(
    String rideId,
    Map<String, dynamic> destination,
  ) async {
    try {
      final result = await remoteDataSource.confirmUpdateDestination(
        rideId,
        destination,
      );
      return Right(result);
    } on InsufficientWalletBalanceException catch (e) {
      return Left(InsufficientWalletBalanceFailure('', details: e.details));
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(_exceptionMessage(e)));
    }
  }

  @override
  Future<Either<Failure, ReceiptModel>> getReceipt(String rideId) async {
    try {
      final result = await remoteDataSource.getReceipt(rideId);
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ValidateRidePaymentResponse>> validateRidePayment(
    ValidateRidePaymentRequest request,
  ) async {
    try {
      final result = await remoteDataSource.validateRidePayment(request);
      return Right(result);
    } on InsufficientWalletBalanceException catch (e) {
      return Left(InsufficientWalletBalanceFailure('', details: e.details));
    } on RidePaymentValidationException catch (e) {
      return Left(
        RidePaymentValidationFailure(
          RidePaymentValidationMessages.displayMessage(
            errorCode: e.errorCode,
            apiMessage: e.message,
          ),
          errorCode: e.errorCode,
          activeRideId: e.activeRideId,
          activeRideStatus: e.activeRideStatus,
        ),
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> walletDummyPaymentRequest(
    DummyPaymentRequest request,
  ) async {
    try {
      final result = await remoteDataSource.walletDummyPaymentRequest(request);
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> updateActivityToken(
    String rideId,
    String token,
  ) async {
    try {
      final result = await remoteDataSource.updateActivityToken(rideId, token);
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppLogger.d(
        "❌ Repository Error during updateActivityToken: $e",
        tag: 'ORDER_TRACKING',
      );
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> updateStops(
    String rideId, {
    required List<Map<String, dynamic>> stops,
    bool confirm = false,
    required String idempotencyKey,
  }) async {
    try {
      final result = await remoteDataSource.updateStops(
        rideId,
        stops: stops,
        confirm: confirm,
        idempotencyKey: idempotencyKey,
      );
      return Right(result);
    } on InsufficientWalletBalanceException catch (e) {
      return Left(InsufficientWalletBalanceFailure('', details: e.details));
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(_exceptionMessage(e)));
    }
  }

  String _exceptionMessage(Object error) {
    if (error is Exception) {
      final raw = error.toString();
      const prefix = 'Exception: ';
      if (raw.startsWith(prefix)) {
        return raw.substring(prefix.length);
      }
      return raw;
    }
    return error.toString();
  }

  @override
  Future<Either<Failure, CheckBookModeResult>> checkBookMode({
    required double riderLat,
    required double riderLng,
    required double pickupLat,
    required double pickupLng,
  }) async {
    try {
      final result = await remoteDataSource.checkBookMode(
        riderLat: riderLat,
        riderLng: riderLng,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
      );
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, EmergencyContactsResponse>>
  getEmergencyContacts() async {
    try {
      final result = await remoteDataSource.getEmergencyContacts();
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PdfLinkModel>> uploadReceiptPdf({
    required String rideId,
    required String pdfPath,
  }) async {
    try {
      final result = await remoteDataSource.uploadReceiptPdf(
        rideId: rideId,
        pdfPath: pdfPath,
      );
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }
}
