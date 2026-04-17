/// Centralized parameter key constants used across API requests.
/// Prevents typos and ensures consistency.
class Params {
  // ── Common ──
  static const String id = "id";
  static const String applicationJson = "application/json";
  static const String latitude = "latitude";
  static const String longitude = "longitude";
  static const String language = "language";

  // ── Device / Auth ──
  static const String deviceTokenRider = "device_token_rider";
  static const String deviceType = "device_type";

  static const String appUuid = "app_uuid";
  static const String accessToken = "access_token";
  static const String authorization = "authorization";
  static const String encryptionDisabled = "encryption_disabled";

  // ── User ──
  static const String email = "email";
  static const String mobileNumber = "mobile_number";
  static const String countryCode = "country_code";
  static const String firstName = "first_name";
  static const String lastName = "last_name";
  static const String gender = "gender";
  static const String userId = "user_id";
  static const String status = "status";

  // ── Pagination ──
  static const String limit = "limit";
  static const String page = "page";
  static const String pageSize = "pageSize";
  static const String pageIndex = "pageIndex";

  // ── Ride-specific ──
  static const String pickupLatitude = "pickup_latitude";
  static const String pickupLongitude = "pickup_longitude";
  static const String dropoffLatitude = "dropoff_latitude";
  static const String dropoffLongitude = "dropoff_longitude";
  static const String pickupAddress = "pickup_address";
  static const String dropoffAddress = "dropoff_address";
  static const String vehicleType = "vehicle_type";
  static const String rideId = "ride_id";
  static const String driverId = "driver_id";
  static const String rating = "rating";
  static const String comment = "comment";
  static const String cancelReason = "cancel_reason";
  static const String promoCode = "promo_code";

  // ── Payment ──
  static const String paymentMode = "payment_mode";
  static const String amount = "amount";
  static const String currency = "currency";
  static const String orderId = "order_id";
  static const String transId = "transid";
}

/// Standard HTTP status/result codes for API response handling.
class ResultCode {
  static const int SUCCESS = 200;
  static const int CREATED = 201;
  static const int BAD_REQUEST = 400;
  static const int UNAUTHORIZED = 401;
  static const int FORBIDDEN = 403;
  static const int NOT_FOUND = 404;
  static const int TIMEOUT = 408;
  static const int CONFLICT = 409;
  static const int UNPROCESSABLE = 422;
  static const int SERVER_ERROR = 500;
  static const int SERVICE_UNAVAILABLE = 503;
}
