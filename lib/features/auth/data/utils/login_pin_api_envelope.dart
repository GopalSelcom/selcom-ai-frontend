import 'dart:convert';

import 'package:dio/dio.dart';

/// Parses AUTH-PIN-BIOMETRIC API envelope: `{ status_code, message, data, error_code }`.
///
/// Used by [LoginPinRemoteDataSourceImpl] to detect success and extract `data`.
class LoginPinApiEnvelope {
  LoginPinApiEnvelope._();

  static Map<String, dynamic>? asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        return asMap(decoded);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Reads `attempts_remaining` from nested `data` or the envelope root.
  static int? attemptsRemaining(Map<String, dynamic> envelope) {
    final nested = dataPayload(envelope);
    for (final map in [nested, envelope]) {
      if (map == null) continue;
      final raw = map['attempts_remaining'];
      if (raw == null) continue;
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      return int.tryParse(raw.toString());
    }
    return null;
  }

  static Map<String, dynamic>? dataPayload(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  static int? statusCode(Map<String, dynamic> envelope) {
    final raw = envelope['status_code'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  static bool isSuccess(Response response) {
    final http = response.statusCode ?? 0;
    if (http < 200 || http >= 300) return false;

    final envelope = asMap(response.data);
    if (envelope == null) return http == 200;

    final envelopeCode = statusCode(envelope);
    if (envelopeCode != null) return envelopeCode == 200;

    return envelope['error_code'] == null;
  }
}
