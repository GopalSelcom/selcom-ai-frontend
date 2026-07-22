import 'package:dio/dio.dart';
import 'package:selcom_rides_frontend/features/ride/data/models/ride_history_model.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/config/ride_payment_endpoints.dart';
import '../../../../core/data/models/requests/validate_ride_payment_request.dart';
import '../../../../core/data/models/responses/chat_quick_replies_response.dart';
import '../../../../core/data/models/responses/rides/active_ride_response.dart';
import '../../../../core/data/models/ride_model.dart';
import '../../../../core/errors/insufficient_wallet_balance_exception.dart';
import '../../../../core/errors/ride_payment_validation_exception.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/expected_client_http_status.dart';
import '../../../../core/network/urls.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../../../core/services/session_expiry_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../payment/domain/models/insufficient_wallet_balance_details.dart';
import '../models/destination_update_models.dart';
import '../models/emergency_contacts_response.dart';
import '../models/mid_ride_cancel_models.dart';
import '../models/ride_management_models.dart';
import '../models/stop_update_models.dart';

abstract class RideRemoteDataSource {
  Future<ActiveRideResponseModel?> getActiveRide();

  Future<List<RecentDestinationModel>> getRecentDestinations();

  Future<RideHistoryModelResponse?> getRideHistory({int page = 1, int limit = 10});

  Future<RideModel> getRideDetails(String rideId);

  Future<RideCancellationChargesModel> getCancellationCharges(String rideId);

  Future<bool> cancelRide(String rideId, String reason);

  Future<DisputeChargeResult> disputeCharge(String rideId, {String? reason});

  Future<DestinationUpdatePreviewModel> previewUpdateDestination(
    String rideId,
    Map<String, dynamic> destination,
  );

  Future<DestinationUpdateAppliedModel> confirmUpdateDestination(
    String rideId,
    Map<String, dynamic> destination,
  );

  Future<ReceiptModel> getReceipt(String rideId);

  Future<String> validateRidePayment(ValidateRidePaymentRequest request);

  Future<bool> walletDummyPaymentRequest(DummyPaymentRequest request);

  Future<Map<String, dynamic>> getChatMessages(
    String rideId, {
    int page = 1,
    int limit = 50,
  });

  Future<bool> sendChatMessage(String rideId, String message);

  Future<List<String>> getChatQuickReplies({String role = 'passenger'});

  Future<bool> updateActivityToken(String rideId, String token);

  Future<dynamic> updateStops(
    String rideId, {
    required List<Map<String, dynamic>> stops,
    bool confirm = false,
    required String idempotencyKey,
  });

  Future<CheckBookModeResult> checkBookMode({
    required double riderLat,
    required double riderLng,
    required double pickupLat,
    required double pickupLng,
  });

  Future<EmergencyContactsResponse> getEmergencyContacts();

  Future<PdfLinkModel> uploadReceiptPdf({
    required String rideId,
    required String pdfPath,
  });
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
        errorPresentationType: ErrorPresentationType.none,
        // Context:
        // - This endpoint is polled continuously during active-trip screens.
        // - We observed intermittent 502/503/504 responses from backend/gateway.
        // Why retry here:
        // - These statuses are usually transient and often recover quickly.
        // - A short retry prevents temporary backend spikes from immediately
        //   interrupting ride-state UX.
        // Scope/safety:
        // - Applied only to active-ride polling (not global).
        // - Keeps other endpoints and feature flows unchanged.
        retryPolicy: const ApiRetryPolicy(
          retryDelays: <Duration>[
            Duration(milliseconds: 500),
            Duration(seconds: 1),
          ],
          retryStatusCodes: <int>{502, 503, 504},
        ),
      ),
    );

    final raw = response.data;
    Map<String, dynamic>? bodyMap;
    if (raw is Map<String, dynamic>) {
      bodyMap = raw;
    } else if (raw is Map) {
      bodyMap = Map<String, dynamic>.from(raw);
    }

    if (bodyMap != null &&
        SessionExpiryService.isSessionExpired(
          httpStatus: response.statusCode,
          body: bodyMap,
        )) {
      await SessionExpiryService.handleSessionExpired();
      return null;
    }

    if (response.statusCode == 200 && bodyMap != null) {
      return ActiveRideResponseModel.fromJson(bodyMap);
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
      final body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);
      final parsed = RecentDestinationsResponseModel.fromJson(body);
      return parsed.data?.destinations ?? [];
    }
    return [];
  }

  @override
  Future<RideHistoryModelResponse?> getRideHistory({int page = 1, int limit = 10}) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.history,
        method: ApiMethod.get,
        queryParams: {Params.page: page, Params.limit: limit},
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = RideHistoryModelResponse.fromJson(response.data);
      return data;
    }
    return null;
  }

  @override
  Future<RideModel> getRideDetails(String rideId) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.rideDetails(rideId),
        method: ApiMethod.get,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final rideData =
          response.data['data']?['ride'] ?? response.data['data'] ?? {};
      return RideModel.fromJson(rideData);
    }
    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      return RideModel.fromJson({'_id': rideId});
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
    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      return RideCancellationChargesModel.fromJson({'ride_id': rideId});
    }
    throw Exception('Failed to fetch cancellation charges');
  }

  @override
  Future<bool> cancelRide(String rideId, String reason) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.cancelRide(rideId),
        method: ApiMethod.put,
        body: {Params.reason: reason},
      ),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  @override
  Future<DisputeChargeResult> disputeCharge(
    String rideId, {
    String? reason,
  }) async {
    final body = <String, dynamic>{};
    final trimmed = reason?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      body[Params.reason] = trimmed;
    }

    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.disputeCharge(rideId),
        method: ApiMethod.post,
        body: body.isEmpty ? null : body,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = Map<String, dynamic>.from(response.data['data'] ?? {});
      return DisputeChargeResult.fromJson(data);
    }
    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      throw Exception('dispute_window_closed');
    }
    throw Exception('Failed to dispute charge');
  }

  @override
  Future<DestinationUpdatePreviewModel> previewUpdateDestination(
    String rideId,
    Map<String, dynamic> destination,
  ) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: RidePaymentEndpoints.updateDestination(rideId),
        method: ApiMethod.put,
        body: {Params.destination: destination, Params.confirm: false},
        errorPresentationType: ErrorPresentationType.none,
      ),
    );
    if (response.statusCode == 200 && response.data != null) {
      final raw = response.data['data'];
      if (raw is Map<String, dynamic>) {
        return DestinationUpdatePreviewModel.fromJson(raw);
      }
      if (raw is Map) {
        return DestinationUpdatePreviewModel.fromJson(
          Map<String, dynamic>.from(raw),
        );
      }
    }
    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      _throwIfInsufficientWalletBalance(response.data);
      final message = _businessErrorMessage(response.data);
      if (message != null) {
        throw Exception(message);
      }
      return DestinationUpdatePreviewModel.fromJson({});
    }
    _throwIfInsufficientWalletBalance(response.data);
    throw Exception(
      response.data?['message']?.toString() ?? 'Failed to preview destination',
    );
  }

  @override
  Future<DestinationUpdateAppliedModel> confirmUpdateDestination(
    String rideId,
    Map<String, dynamic> destination,
  ) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: RidePaymentEndpoints.updateDestination(rideId),
        method: ApiMethod.put,
        body: {Params.destination: destination, Params.confirm: true},
        errorPresentationType: ErrorPresentationType.none,
      ),
    );
    if (response.statusCode == 200 && response.data != null) {
      final raw = response.data['data'];
      if (raw is Map<String, dynamic>) {
        return DestinationUpdateAppliedModel.fromJson(raw);
      }
      if (raw is Map) {
        return DestinationUpdateAppliedModel.fromJson(
          Map<String, dynamic>.from(raw),
        );
      }
    }
    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      _throwIfInsufficientWalletBalance(response.data);
      final message = _businessErrorMessage(response.data);
      if (message != null) {
        throw Exception(message);
      }
      return DestinationUpdateAppliedModel.fromJson({});
    }
    _throwIfInsufficientWalletBalance(response.data);
    throw Exception(
      response.data?['message']?.toString() ?? 'Failed to update destination',
    );
  }

  @override
  Future<ReceiptModel> getReceipt(String rideId) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.receipt(rideId),
        method: ApiMethod.get,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final receiptJson =
          (response.data['data'] as Map?)?['receipt'] as Map<String, dynamic>?;
      return ReceiptModel.fromJson(receiptJson ?? {});
    }
    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      return ReceiptModel.fromJson({'ride_id': rideId});
    }
    throw Exception('Failed to get receipt');
  }

  @override
  Future<String> validateRidePayment(ValidateRidePaymentRequest request) async {
    final endpoint = RidePaymentEndpoints.validateRidePayment;
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: endpoint,
        method: ApiMethod.post,
        body: request.toJson(),
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final body = _apiResponseMap(response.data);
      if (body != null) {
        return body['data']?['validation_id']?.toString() ?? '';
      }
      return '';
    }

    final body = _apiResponseMap(response.data);
    if (body != null) {
      final insufficient =
          InsufficientWalletBalanceDetails.tryParseFromApiResponse(body);
      if (insufficient != null) {
        throw InsufficientWalletBalanceException(insufficient);
      }

      final errorCode = body['error_code']?.toString().trim() ?? '';
      final message = body['message']?.toString().trim() ?? '';
      final statusCode = response.statusCode;

      // Business rejections from validate payment (400/409) — never return empty validation_id.
      if (_isValidateRidePaymentBusinessRejection(
        statusCode,
        errorCode,
        message,
      )) {
        final payload = body['data'];
        throw RidePaymentValidationException(
          errorCode: errorCode.isNotEmpty
              ? errorCode
              : 'VALIDATE_PAYMENT_REJECTED',
          message: message,
          activeRideId: payload is Map
              ? payload['active_ride_id']?.toString()
              : null,
          activeRideStatus: payload is Map
              ? payload['active_ride_status']?.toString()
              : null,
        );
      }

      if (message.isNotEmpty) {
        throw Exception(message);
      }
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
        endpoint: URLS.ride.messages(rideId),
        method: ApiMethod.get,
        queryParams: {Params.page: page, Params.limit: limit},
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
        endpoint: URLS.ride.messages(rideId),
        method: ApiMethod.post,
        body: {Params.message: message},
      ),
    );
    return response.statusCode == 200;
  }

  @override
  Future<List<String>> getChatQuickReplies({String role = 'passenger'}) async {
    try {
      final response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.common.chatQuickReplies,
          method: ApiMethod.get,
          queryParams: {Params.role: role},
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        return parseChatQuickRepliesFromResponse(
          response.data is Map<String, dynamic>
              ? response.data as Map<String, dynamic>
              : Map<String, dynamic>.from(response.data as Map),
        );
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
    }
    return const [];
  }

  @override
  Future<bool> walletDummyPaymentRequest(DummyPaymentRequest request) async {
    if (!AppConfig.ridePaymentBypass) {
      return false;
    }
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.payment.devPaymentCallback,
        method: ApiMethod.post,
        body: request.toJson(),
      ),
    );
    return response.statusCode == 200;
  }

  @override
  Future<bool> updateActivityToken(String rideId, String token) async {
    try {
      AppLogger.d(
        "🚀 API Request: PATCH ${URLS.ride.activityToken(rideId)}",
        tag: 'ORDER_TRACKING',
      );
      final response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.ride.activityToken(rideId),
          method: ApiMethod.patch,
          body: {Params.iosActivityToken: token},
        ),
      );
      AppLogger.d(
        "✅ API Response: ${response.statusCode} for ride $rideId",
        tag: 'ORDER_TRACKING',
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      if (e is DioException) {
        AppLogger.d(
          "❌ API Error: ${e.response?.statusCode} - ${e.response?.data} while updating token for ride $rideId",
          tag: 'ORDER_TRACKING',
        );
      } else {
        AppLogger.d(
          "❌ Unexpected Error: $e while updating token for ride $rideId",
          tag: 'ORDER_TRACKING',
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
        endpoint: RidePaymentEndpoints.updateStops(rideId),
        method: ApiMethod.put,
        headers: {'Idempotency-Key': idempotencyKey},
        body: {Params.stops: stops, Params.confirm: confirm},
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
    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      _throwIfInsufficientWalletBalance(response.data);
      final message = _businessErrorMessage(response.data);
      if (message != null) {
        throw Exception(message);
      }
      if (confirm) {
        return StopUpdateAppliedModel.fromJson({});
      }
      return StopUpdatePreviewModel.fromJson({});
    }
    _throwIfInsufficientWalletBalance(response.data);
    throw Exception(response.data?['message'] ?? 'Failed to update stops');
  }

  String? _businessErrorMessage(dynamic data) {
    if (data is! Map) return null;
    final map = data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data);
    final message = map['message']?.toString().trim();
    if (message == null || message.isEmpty) return null;
    final errorCode = map['error_code']?.toString().trim();
    if (errorCode != null && errorCode.isNotEmpty) {
      return '$errorCode|$message';
    }
    return message;
  }

  @override
  Future<CheckBookModeResult> checkBookMode({
    required double riderLat,
    required double riderLng,
    required double pickupLat,
    required double pickupLng,
  }) async {
    final response = await apiService.call(
      request: ApiRequest(
        endpoint: URLS.ride.checkBookMode,
        method: ApiMethod.get,
        queryParams: {
          'rider_lat': riderLat,
          'rider_lng': riderLng,
          'pickup_lat': pickupLat,
          'pickup_lng': pickupLng,
        },
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      return CheckBookModeResult.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    }
    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      return const CheckBookModeResult(
        showBookForOtherOption: false,
        distanceKm: null,
        thresholdKm: 1.0,
      );
    }
    throw Exception('Failed to check book mode');
  }

  @override
  Future<EmergencyContactsResponse> getEmergencyContacts() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.emergencyContacts,
        method: ApiMethod.get,
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        return EmergencyContactsResponse.fromJson(
          Map<String, dynamic>.from(raw),
        );
      }
      if (raw is Map) {
        return EmergencyContactsResponse.fromJson(
          Map<String, dynamic>.from(raw),
        );
      }
    }
    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      return EmergencyContactsResponse(
        statusCode: response.statusCode ?? 400,
        message: '',
        data: EmergencyContactsData.fromJson({}),
      );
    }
    throw Exception('Failed to fetch emergency contacts');
  }

  @override
  Future<PdfLinkModel> uploadReceiptPdf({
    required String rideId,
    required String pdfPath,
  }) async {
    final response = await apiService.call(
      request: ApiRequest(
        endpoint: URLS.pdf.upload,
        method: ApiMethod.multipart,
        multipartFiles: [
          LocalMultipartFile(
            name: 'pdf',
            path: pdfPath,
            contentType: 'application/pdf',
          ),
        ],
        body: {Params.rideId: rideId},
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data['data'] ?? {};
      return PdfLinkModel.fromJson(data);
    }
    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      return PdfLinkModel.fromJson({});
    }
    throw Exception(response.data?['message'] ?? 'Failed to upload PDF');
  }
}

Map<String, dynamic>? _apiResponseMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return null;
}

void _throwIfInsufficientWalletBalance(dynamic raw) {
  final body = _apiResponseMap(raw);
  if (body == null) return;
  final insufficient = InsufficientWalletBalanceDetails.tryParseFromApiResponse(
    body,
  );
  if (insufficient != null) {
    throw InsufficientWalletBalanceException(insufficient);
  }
}

bool _isValidateRidePaymentBusinessRejection(
  int? statusCode,
  String errorCode,
  String message,
) {
  if (statusCode == 409) return errorCode.isNotEmpty || message.isNotEmpty;
  if (statusCode == 400) return errorCode.isNotEmpty || message.isNotEmpty;
  return false;
}
