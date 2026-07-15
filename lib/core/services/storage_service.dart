import 'package:hive_flutter/hive_flutter.dart';

import '../env/env.dart';
import 'hive_secure_box.dart';

/// Centralized storage keys to prevent typos and ensure consistency across the app.
class StorageKeys {
  /// Legacy Hive key — prefer [StorageService.readAccessToken] / [writeAccessToken].
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
  static const String appleAuthProfilePrefix = 'apple_auth_profile_';
  static const String stopsIdempotencyPrefix = 'stops_idem_';
}

/// App-wide key/value persistence backed by Hive (app sandbox).
///
/// Values are encrypted at rest via [openSecureBox] (AES + SHA-256 password).
/// Hive files are removed when the app is uninstalled on both iOS and Android.
class StorageService {
  static final StorageService _instance = StorageService._internal();

  factory StorageService() => _instance;

  StorageService._internal();

  static const String boxName = 'app_storage_box';

  static bool _hiveFlutterInitialized = false;

  Box<String>? _box;

  /// Initializes Hive for Flutter and opens [boxName] with encryption.
  ///
  /// Cipher key is SHA-256([Env.hiveBoxPassword]) — same password for encrypt
  /// and decrypt. Not stored in platform secure storage by design.
  ///
  /// Safe to call multiple times (e.g. from [main] and lazily from reads).
  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;

    if (!_hiveFlutterInitialized) {
      await Hive.initFlutter();
      _hiveFlutterInitialized = true;
    }

    _box = await openSecureBox<String>(
      boxName,
      password: Env.hiveBoxPassword,
    );
  }

  Future<Box<String>> _ensureBox() async {
    await init();
    return _box!;
  }

  Future<void> write(String key, String value) async {
    final box = await _ensureBox();
    await box.put(key, value);
  }

  Future<String?> read(String key) async {
    final box = await _ensureBox();
    return box.get(key);
  }

  Future<void> delete(String key) async {
    final box = await _ensureBox();
    await box.delete(key);
  }

  /// Clears all data in the app storage box — typically used during logout.
  Future<void> deleteAll() async {
    final box = await _ensureBox();
    await box.clear();
  }

  Future<bool> containsKey(String key) async {
    final box = await _ensureBox();
    return box.containsKey(key);
  }

  /// Canonical session JWT — reads [StorageKeys.accessToken], with one-time
  /// fallback to legacy [StorageKeys.authorizationToken].
  Future<String?> readAccessToken() async {
    final token = await read(StorageKeys.accessToken);
    if (token != null && token.trim().isNotEmpty) return token.trim();
    final legacy = await read(StorageKeys.authorizationToken);
    if (legacy == null || legacy.trim().isEmpty) return null;
    return legacy.trim();
  }

  /// Persists the session JWT under [StorageKeys.accessToken] only.
  Future<void> writeAccessToken(String value) async {
    final trimmed = value.trim();
    await write(StorageKeys.accessToken, trimmed);
    await delete(StorageKeys.authorizationToken);
  }
}
