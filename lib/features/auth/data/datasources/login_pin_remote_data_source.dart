import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;

import '../../../../core/data/models/user_model.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/expected_client_http_status.dart';
import '../../../../core/network/urls.dart';
import '../../../../core/services/storage_service.dart';
import '../models/login_pin_models.dart';
import '../utils/login_pin_api_envelope.dart';

/// Thrown when the auth PIN API returns a business error in the envelope.
class LoginPinApiException implements Exception {
  LoginPinApiException({
    required this.message,
    this.errorCode,
    this.statusCode,
    this.attemptsRemaining,
    this.lockedUntil,
  });

  final String message;
  final String? errorCode;
  final int? statusCode;
  final int? attemptsRemaining;
  final DateTime? lockedUntil;

  @override
  String toString() => message;
}

/// HTTP layer for `/v4/go/auth/pin/*` and `/auth/biometric`.
///
/// Uses [LoginPinApiEnvelope] for `{ status_code, message, data, error_code }`.
/// 4xx bodies are passed through when [ApiService] uses `errorPresentationType: none`.
abstract class LoginPinRemoteDataSource {
  /// `GET pin/status` → `pin_set`, `biometric_enabled`, `locked_until`.
  Future<LoginPinStatusModel> getPinStatus();

  Future<void> setupPin(String pin);

  Future<LoginPinVerifyResultModel> verifyPin(String pin);

  Future<void> changePin({required String oldPin, required String newPin});

  Future<void> deletePin();

  Future<bool> setBiometricEnabled(bool enabled);
}

class LoginPinRemoteDataSourceImpl implements LoginPinRemoteDataSource {
  Never _throwFromResponse(Response response) {
    final envelope = LoginPinApiEnvelope.asMap(response.data);
    if (envelope == null) {
      throw LoginPinApiException(
        message: AppStrings.somethingWentWrongPleaseTryAgain.tr,
        statusCode: response.statusCode,
      );
    }

    final errorCode = envelope['error_code']?.toString();
    final message =
        envelope['message']?.toString() ??
        AppStrings.somethingWentWrongPleaseTryAgain.tr;
    final nested = LoginPinApiEnvelope.dataPayload(envelope);

    int? attempts;
    if (nested != null) {
      final attemptsRaw = nested['attempts_remaining'];
      if (attemptsRaw is int) {
        attempts = attemptsRaw;
      } else if (attemptsRaw != null) {
        attempts = int.tryParse(attemptsRaw.toString());
      }
    }

    final lockedRaw =
        envelope['locked_until'] ??
        (nested != null ? nested['locked_until'] : null);
    DateTime? lockedUntil;
    if (lockedRaw != null) {
      lockedUntil = DateTime.tryParse(lockedRaw.toString());
    }

    throw LoginPinApiException(
      message: message,
      errorCode: errorCode,
      statusCode:
          LoginPinApiEnvelope.statusCode(envelope) ?? response.statusCode,
      attemptsRemaining: attempts,
      lockedUntil: lockedUntil,
    );
  }

  void _ensureSuccess(Response response) {
    if (LoginPinApiEnvelope.isSuccess(response)) return;
    _throwFromResponse(response);
  }

  @override
  Future<LoginPinStatusModel> getPinStatus() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.auth.pinStatus,
        method: ApiMethod.get,
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    if (LoginPinApiEnvelope.isSuccess(response)) {
      final payload = LoginPinApiEnvelope.asMap(response.data);
      final data = payload != null
          ? LoginPinApiEnvelope.dataPayload(payload)
          : null;
      if (data != null) {
        return LoginPinStatusModel.fromJson(data);
      }
    }
    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      return const LoginPinStatusModel(pinSet: false, biometricEnabled: false);
    }
    _throwFromResponse(response);
  }

  @override
  Future<void> setupPin(String pin) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.auth.pinSetup,
        method: ApiMethod.post,
        body: {'pin': pin},
        errorPresentationType: ErrorPresentationType.none,
      ),
    );
    _ensureSuccess(response);
  }

  @override
  Future<LoginPinVerifyResultModel> verifyPin(String pin) async {
    final mobile = await StorageService().read(StorageKeys.loginMobileNumber);
    final countryCode = await StorageService().read(
      StorageKeys.loginCountryCode,
    );
    if (mobile == null ||
        mobile.isEmpty ||
        countryCode == null ||
        countryCode.isEmpty) {
      throw LoginPinApiException(
        message: AppStrings.sessionExpiredPleaseLoginAgain.tr,
        errorCode: 'AUTH_PIN_NOT_SET',
        statusCode: 404,
      );
    }

    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.auth.pinVerify,
        method: ApiMethod.post,
        body: {
          'mobile_number': mobile.replaceAll(RegExp(r'\D'), ''),
          'country_code': countryCode.replaceAll('+', ''),
          'pin': pin,
        },
        skipAuthInterceptor: true,
        errorPresentationType: ErrorPresentationType.none,
        shouldQueue: false,
      ),
    );

    if (LoginPinApiEnvelope.isSuccess(response)) {
      final envelope = LoginPinApiEnvelope.asMap(response.data);
      final payload = envelope != null
          ? LoginPinApiEnvelope.dataPayload(envelope)
          : null;
      if (payload != null) {
        return LoginPinVerifyResultModel.fromJson(payload);
      }
    }
    _throwFromResponse(response);
  }

  @override
  Future<void> changePin({
    required String oldPin,
    required String newPin,
  }) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.auth.pinChange,
        method: ApiMethod.put,
        body: {'old_pin': oldPin, 'new_pin': newPin},
        errorPresentationType: ErrorPresentationType.none,
      ),
    );
    _ensureSuccess(response);
  }

  @override
  Future<void> deletePin() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.auth.pinDelete,
        method: ApiMethod.delete,
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    if (LoginPinApiEnvelope.isSuccess(response)) {
      final envelope = LoginPinApiEnvelope.asMap(response.data);
      final data = envelope != null
          ? LoginPinApiEnvelope.dataPayload(envelope)
          : null;
      final biometricEnabled = data?['biometric_enabled'] == true;
      await StorageService().write(
        StorageKeys.biometricLoginEnabled,
        biometricEnabled.toString(),
      );
      return;
    }
    _throwFromResponse(response);
  }

  @override
  Future<bool> setBiometricEnabled(bool enabled) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.auth.biometricLogin,
        method: ApiMethod.put,
        body: {'enabled': enabled},
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    if (LoginPinApiEnvelope.isSuccess(response)) {
      final envelope = LoginPinApiEnvelope.asMap(response.data);
      final data = envelope != null
          ? LoginPinApiEnvelope.dataPayload(envelope)
          : null;
      final value = data?['biometric_enabled'] == true;
      await StorageService().write(
        StorageKeys.biometricLoginEnabled,
        value.toString(),
      );
      return value;
    }
    _throwFromResponse(response);
  }
}

/// Persists tokens and user after PIN verify (same shape as `verify_otp`).
Future<void> persistLoginSessionFromTokens({
  required String accessToken,
  required String refreshToken,
  Map<String, dynamic>? userJson,
}) async {
  final storage = StorageService();
  if (accessToken.isNotEmpty) {
    await storage.write(StorageKeys.authorizationToken, accessToken);
    await storage.write(StorageKeys.accessToken, accessToken);
  }
  if (refreshToken.isNotEmpty) {
    await storage.write(StorageKeys.refreshToken, refreshToken);
  }
  if (userJson != null && userJson.isNotEmpty) {
    final normalized = Map<String, dynamic>.from(userJson);
    if (normalized['emailId'] == null && normalized['email'] != null) {
      normalized['emailId'] = normalized['email'];
    }
    final user = UserModel.fromJson(normalized);
    await storage.write(StorageKeys.user, jsonEncode(user.toJson()));
  }
}
