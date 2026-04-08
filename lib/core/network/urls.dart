/// Centralized endpoint registry.
/// Access via: `URLS.auth.sendOtp`, `URLS.ride.estimateFare`, etc.
abstract class URLS {
  // ── Grouped endpoint accessors ──
  static const auth = _AuthEndpoints();
  static const ride = _RideEndpoints();
  static const home = _HomeEndpoints();
  static const booking = _BookingEndpoints();
  static const profile = _ProfileEndpoints();
  static const common = _CommonEndpoints();
  static const payment = _PaymentEndpoints();
  static const address = _AddressEndpoints();
  static const places = _PlacesEndpoints();
}

/// ─────────────────────────────────
/// AUTH ENDPOINTS
/// ─────────────────────────────────
class _AuthEndpoints {
  const _AuthEndpoints();

  final sendOtp = "send_otp";
  final resendOtp = "resend_otp";
  final verifyOtp = "verify_otp";
  final saveUserDetails = "save_user_additional_details";
  final refreshToken = "refresh_token";
  final logout = "logout";
}

/// ─────────────────────────────────
/// RIDE ENDPOINTS
/// ─────────────────────────────────
class _RideEndpoints {
  const _RideEndpoints();

  final estimateFare = "ride/estimate_fare";
  final getVehicleTypes = "go/vehicles/types";
  final requestRide = "ride/request";
  final cancelRide = "ride/cancel";
  final rideStatus = "ride/status";
  final rideHistory = "ride/history";
  final rideDetails = "ride/details";
  final rateDriver = "ride/rate_driver";
  final getNearbyDrivers = "ride/nearby_drivers";
  final trackDriver = "ride/track_driver";
}

/// ─────────────────────────────────
/// HOME ENDPOINTS
/// ─────────────────────────────────
class _HomeEndpoints {
  const _HomeEndpoints();

  final homeScreen = "home_screen";
}

/// ─────────────────────────────────
/// BOOKING ENDPOINTS
/// ─────────────────────────────────
class _BookingEndpoints {
  const _BookingEndpoints();

  final activeBookings = "booking/active";
  final bookingHistory = "booking/history";
  final bookingDetails = "booking/details";
}

/// ─────────────────────────────────
/// PROFILE ENDPOINTS
/// ─────────────────────────────────
class _ProfileEndpoints {
  const _ProfileEndpoints();

  final updateProfile = "edit_profile";
  final getProfile = "get_profile";
  final notificationHistory = "get_all_notification";
  final deleteNotification = "clear_all_notifications";
}

/// ─────────────────────────────────
/// COMMON ENDPOINTS
/// ─────────────────────────────────
class _CommonEndpoints {
  const _CommonEndpoints();

  final getSettings = "get_setting";
  final aboutUs = "get_setting?type=1";
  final terms = "get_setting?type=2";
  final privacy = "get_setting?type=3";
  final faqs = "get_setting?type=5";
}

/// ─────────────────────────────────
/// PAYMENT ENDPOINTS
/// ─────────────────────────────────
class _PaymentEndpoints {
  const _PaymentEndpoints();

  final makePayment = "unified_payment";
  final checkPaymentStatus = "check_payment_status";
}

/// ─────────────────────────────────
/// ADDRESS ENDPOINTS
/// ─────────────────────────────────
class _AddressEndpoints {
  const _AddressEndpoints();

  final add = "add_user_address";
  final get = "get_user_address";
  final edit = "edit_user_address";
  final delete = "delete_user_address";
  final getSavedPlaces = "get_saved_places";
}

/// ─────────────────────────────────
/// PLACES ENDPOINTS
/// ─────────────────────────────────
class _PlacesEndpoints {
  const _PlacesEndpoints();

  final autocomplete = "go/places/autocomplete";
  final reverseGeocode = "go/places/reverse-geocode";
}

