import '../../../../core/data/models/ride_model.dart';
import '../../../../core/data/models/requests/validate_ride_payment_request.dart';
import '../models/ride_management_models.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/urls.dart';

abstract class RideRemoteDataSource {
  Future<List<RecentDestinationModel>> getRecentDestinations();
  Future<List<RideModel>> getRideHistory({int page = 1, int limit = 10});
  Future<RideModel> getRideDetails(String rideId);
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
  Future<Map<String, dynamic>> getChatMessages(
    String rideId, {
    int page = 1,
    int limit = 50,
  });
  Future<bool> sendChatMessage(String rideId, String message);
}

class RideRemoteDataSourceImpl implements RideRemoteDataSource {
  RideRemoteDataSourceImpl();

  @override
  Future<List<RecentDestinationModel>> getRecentDestinations() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.recentDestinations,
        method: ApiMethod.get,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final List data = response.data['data'] ?? [];
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
      return RideModel.fromJson(response.data['data'] ?? {});
    }
    throw Exception('Failed to get ride details');
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
    return response.statusCode == 200;
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
}
