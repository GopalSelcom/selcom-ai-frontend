import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Centralized storage keys to prevent typos and ensure consistency across the app.
class StorageKeys {
  static const String authorizationToken = 'authorization_token';
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String user = 'user_data';
  static const String isFirstTime = 'is_first_time';
  static const String fcmToken = 'fcm_token';
  static const String voipToken = 'voip_push_token';
  static const String preferredLanguage = 'preferred_language';
  /// ISO 3166-1 alpha-2 (e.g. TZ, IN).
  static const String selectedPhoneCountryId = 'selected_phone_country_id';
  static const String signupCompleted = 'signup_completed';
  static const String stopsIdempotencyPrefix = 'stops_idem_';

  /// Login PIN verify (`/go/auth/pin/verify`) — not ride PIN.
  static const String loginMobileNumber = 'login_mobile_number';
  static const String loginCountryCode = 'login_country_code';
  static const String biometricLoginEnabled = 'biometric_login_enabled';
  static const String forgotLoginPinPending = 'forgot_login_pin_pending';
}

/// A service class for handling secure data persistence using FlutterSecureStorage.
/// Implements a singleton pattern to ensure a single instance is used throughout the app.
class StorageService {
  static final StorageService _instance = StorageService._internal();

  /// Factory constructor to return the singleton instance.
  factory StorageService() => _instance;

  /// Internal constructor for singleton initialization.
  StorageService._internal();

  /// Instance of FlutterSecureStorage for encrypted data storage.
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Writes a [value] to secure storage associated with the given [key].
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Reads a value from secure storage for the given [key].
  /// Returns null if the key does not exist.
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// Deletes the value associated with the given [key] from secure storage.
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Clears all data stored in secure storage.
  /// Typically used during logout.
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Checks if a specific [key] exists in secure storage.
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }
}
