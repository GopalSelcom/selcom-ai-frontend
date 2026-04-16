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
  static const wallet = _WalletEndpoints();
  static const notification = _NotificationEndpoints();
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

  final estimateFare = "go/rides/estimate";
  final getVehicleTypes = "go/vehicles/types";
  final bookRide = "go/rides/book";
  final history = "go/rides/history";
  final recentDestinations = "go/rides/recent-destinations";
  final pendingReview = "go/rides/pending-review";
  final reviewTags = "go/review-tags";
  String cancelRide(String rideId) => "$base/$rideId/cancel";
  String rateRide(String rideId) => "$base/$rideId/rate";
  String skipRideRating(String rideId) => "$base/$rideId/skip-rating";
  final base =
      "go/rides"; // Use for /{{id}}, /{{id}}/cancel, /{{id}}/rate, etc.
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
  final paymentMethods = "go/user/payment-methods";
  final getEmailSubject = "go/get_email_subject";
  final sendEmail = "go/send_email";
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

  final validateRidePayment = "go/validate_ride_payment";
  final makePayment = "unified_payment";
  final checkPaymentStatus = "check_payment_status";
}

/// ─────────────────────────────────
/// ADDRESS ENDPOINTS (Saved Places)
/// ─────────────────────────────────
class _AddressEndpoints {
  const _AddressEndpoints();

  final savedPlaces = "go/user/saved-places";
}

/// ─────────────────────────────────
/// PLACES ENDPOINTS
/// ─────────────────────────────────
class _PlacesEndpoints {
  const _PlacesEndpoints();

  final autocomplete = "go/places/autocomplete";
  final reverseGeocode = "go/places/reverse-geocode";
  final geocode = "go/places/geocode";
}

/// ─────────────────────────────────
/// WALLET ENDPOINTS
/// ─────────────────────────────────
class _WalletEndpoints {
  const _WalletEndpoints();

  final balance = "go/wallet/balance";
}

/// ─────────────────────────────────
/// NOTIFICATION ENDPOINTS
/// ─────────────────────────────────
class _NotificationEndpoints {
  const _NotificationEndpoints();

  final list = "go/notifications";
  final readAll = "go/notifications/read-all";
  final base = "go/notifications"; // Use for /{{id}}/read
}
