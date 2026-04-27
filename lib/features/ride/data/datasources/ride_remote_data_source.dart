import '../../../../core/data/models/responses/rides/active_ride_response.dart';
import '../../../../core/data/models/ride_model.dart';
import '../../../../core/data/models/requests/validate_ride_payment_request.dart';
import '../models/ride_management_models.dart';
import '../models/stop_update_models.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/urls.dart';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';

abstract class RideRemoteDataSource {
  Future<ActiveRideResponseModel?> getActiveRide();
  Future<List<RecentDestinationModel>> getRecentDestinations();
  Future<List<RideModel>> getRideHistory({int page = 1, int limit = 10});
  Future<RideModel> getRideDetails(String rideId);
  Future<RideCancellationChargesModel> getCancellationCharges(String rideId);
  Future<bool> cancelRide(String rideId, String reason);
  Future<bool> updateDestination(
    String rideId,
    Map<String, dynamic> destination,
  );
  Future<bool> updatePickup(String rideId, Map<String, dynamic> pickup);
  Future<bool> increaseFare(String rideId, int newFare);
  Future<ReceiptModel> getReceipt(String rideId);
  Future<bool> rateDriver(String rideId, int rating, String comment);
  Future<bool> submitFeedback(String rideId, String category, String message);
  Future<String> validateRidePayment(ValidateRidePaymentRequest request);
  Future<bool> walletDummyPaymentRequest(DummyPaymentRequest request);
  Future<Map<String, dynamic>> getChatMessages(
    String rideId, {
    int page = 1,
    int limit = 50,
  });
  Future<bool> sendChatMessage(String rideId, String message);
  Future<bool> updateActivityToken(String rideId, String token);
  Future<dynamic> updateStops(
    String rideId, {
    required List<Map<String, dynamic>> stops,
    bool confirm = false,
    required String idempotencyKey,
  });
  Future<void> cancelPendingStops(String rideId);
}

class RideRemoteDataSourceImpl implements RideRemoteDataSource {
  final ApiService apiService = ApiService();

  RideRemoteDataSourceImpl();

  @override
  Future<ActiveRideResponseModel?> getActiveRide() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.activeRide,
        method: ApiMethod.get,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      return ActiveRideResponseModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    }
    return null;
  }

  @override
  Future<List<RecentDestinationModel>> getRecentDestinations() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.recentDestinations,
        method: ApiMethod.get,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final List data = response.data['data']?['destinations'] ?? [];
      return data.map((e) => RecentDestinationModel.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<List<RideModel>> getRideHistory({int page = 1, int limit = 10}) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.history,
        method: ApiMethod.get,
        queryParams: {'page': page, 'limit': limit},
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final List rides = response.data['data']?['rides'] ?? [];
      return rides.map((e) => RideModel.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<RideModel> getRideDetails(String rideId) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: "${URLS.ride.base}/$rideId",
        method: ApiMethod.get,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final rideData =
          response.data['data']?['ride'] ?? response.data['data'] ?? {};
      return RideModel.fromJson(rideData);
    }
    throw Exception('Failed to get ride details');
  }

  @override
  Future<RideCancellationChargesModel> getCancellationCharges(
    String rideId,
  ) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.cancellationCharges(rideId),
        method: ApiMethod.get,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = Map<String, dynamic>.from(response.data['data'] ?? {});
      return RideCancellationChargesModel.fromJson(data);
    }
    throw Exception('Failed to fetch cancellation charges');
  }

  @override
  Future<bool> cancelRide(String rideId, String reason) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.cancelRide(rideId),
        method: ApiMethod.put,
        body: {'reason': reason},
      ),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  @override
  Future<bool> updateDestination(
    String rideId,
    Map<String, dynamic> destination,
  ) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: "${URLS.ride.base}/$rideId/update-destination",
        method: ApiMethod.put,
        body: {'destination': destination},
      ),
    );
    return response.statusCode == 200;
  }

  @override
  Future<bool> updatePickup(String rideId, Map<String, dynamic> pickup) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: "${URLS.ride.base}/$rideId/update-pickup",
        method: ApiMethod.put,
        body: {'pickup': pickup},
      ),
    );
    return response.statusCode == 200;
  }

  @override
  Future<bool> increaseFare(String rideId, int newFare) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: "${URLS.ride.base}/$rideId/increase-fare",
        method: ApiMethod.put,
        body: {'new_fare': newFare},
      ),
    );
    return response.statusCode == 200;
  }

  @override
  Future<ReceiptModel> getReceipt(String rideId) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: "${URLS.ride.base}/$rideId/receipt",
        method: ApiMethod.get,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      return ReceiptModel.fromJson(response.data['data'] ?? {});
    }
    throw Exception('Failed to get receipt');
  }

  @override
  Future<bool> rateDriver(String rideId, int rating, String comment) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: "${URLS.ride.base}/$rideId/rate",
        method: ApiMethod.post,
        body: {'rating': rating, 'comment': comment},
      ),
    );
    return response.statusCode == 200;
  }

  @override
  Future<bool> submitFeedback(
    String rideId,
    String category,
    String message,
  ) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: "${URLS.ride.base}/$rideId/feedback",
        method: ApiMethod.post,
        body: {'category': category, 'message': message},
      ),
    );
    return response.statusCode == 200;
  }

  @override
  Future<String> validateRidePayment(ValidateRidePaymentRequest request) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.payment.validateRidePayment,
        method: ApiMethod.post,
        body: request.toJson(),
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      return response.data['data']?['validation_id'] ?? '';
    }
    throw Exception('Payment validation failed');
  }

  @override
  Future<Map<String, dynamic>> getChatMessages(
    String rideId, {
    int page = 1,
    int limit = 50,
  }) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: "${URLS.ride.base}/$rideId/messages",
        method: ApiMethod.get,
        queryParams: {'page': page, 'limit': limit},
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      return response.data['data'] ?? {};
    }
    return {};
  }

  @override
  Future<bool> sendChatMessage(String rideId, String message) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: "${URLS.ride.base}/$rideId/messages",
        method: ApiMethod.post,
        body: {'message': message},
      ),
    );
    return response.statusCode == 200;
  }

  @override
  Future<bool> walletDummyPaymentRequest(DummyPaymentRequest request) async {
    final response = await ApiService().call(
      request: ApiRequest(
        customBaseUrl:
            "https://dukastaging.selcom.dev:7443/api/v4/go/dev/payment_callback",
        // endpoint: "${URLS.ride.base}/$rideId/messages",
        endpoint: "",
        method: ApiMethod.post,
        body: request.toJson(),
      ),
    );
    return response.statusCode == 200;
  }

  @override
  Future<bool> updateActivityToken(String rideId, String token) async {
    try {
      developer.log(
        "🚀 API Request: PATCH /v4/go/rides/$rideId/activity-token",
        name: 'ORDER_TRACKING',
      );
      final response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.ride.activityToken(rideId),
          method: ApiMethod.patch,
          body: {'ios_activity_token': token},
        ),
      );
      developer.log(
        "✅ API Response: ${response.statusCode} for ride $rideId",
        name: 'ORDER_TRACKING',
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      if (e is DioException) {
        developer.log(
          "❌ API Error: ${e.response?.statusCode} - ${e.response?.data} while updating token for ride $rideId",
          name: 'ORDER_TRACKING',
        );
      } else {
        developer.log(
          "❌ Unexpected Error: $e while updating token for ride $rideId",
          name: 'ORDER_TRACKING',
        );
      }
      return false;
    }
  }

  @override
  Future<dynamic> updateStops(
    String rideId, {
    required List<Map<String, dynamic>> stops,
    bool confirm = false,
    required String idempotencyKey,
  }) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.updateStops(rideId),
        method: ApiMethod.put,
        headers: {'Idempotency-Key': idempotencyKey},
        body: {'stops': stops, 'confirm': confirm},
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data['data'] ?? {};
      if (confirm) {
        return StopUpdateAppliedModel.fromJson(data);
      } else {
        return StopUpdatePreviewModel.fromJson(data);
      }
    }
    throw Exception(response.data?['message'] ?? 'Failed to update stops');
  }

  @override
  Future<void> cancelPendingStops(String rideId) async {
    try {
      await apiService.call(
        request: ApiRequest(
          endpoint: URLS.ride.cancelPendingStops(rideId),
          method: ApiMethod.delete,
        ),
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      developer.log("Error cancelling pending stops: $e");
    }
  }
}
