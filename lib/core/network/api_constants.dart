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
  static const String deviceToken = "device_token";
  static const String deviceType = "device_type";
  static const String languageCode = "language_code";
  static const String intUdid = "int_udid";

  static const String appUuid = "app_uuid";
  static const String accessToken = "access_token";
  static const String authorization = "authorization";
  static const String encryptionDisabled = "encryption_disabled";

  // ── User ──
  static const String email = "email";
  static const String mobileNumber = "mobile_number";
  static const String countryCode = "country_code";
  static const String countryId = "country_id";
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
  static String CARD_NUMBER = "card_number";
  static String CARD_TYPE = "card_type";
  static String CARD_CVN = "card_cvn";
  static String CARD_EXPIRY_DATE = "card_expiry_date";
  static String app_referal_code = "app_referal_code";

  // ── Additional Request Params ──
  static const String reason = "reason";
  static const String destination = "destination";
  static const String confirm = "confirm";
  static const String stops = "stops";
  static const String role = "role";
  static const String input = "input";
  static const String lat = "lat";
  static const String lng = "lng";
  static const String address = "address";
  static const String message = "message";
  static const String iosActivityToken = "ios_activity_token";
  static const String expiryMonth = "expiry_month";
  static const String expiryYear = "expiry_year";
  static const String cvv = "cvv";
  static const String name = "name";
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
