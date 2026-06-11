import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/services/storage_service.dart';

class AppleAuthStoredProfile {
  const AppleAuthStoredProfile({
    this.email,
    this.givenName,
    this.familyName,
  });

  final String? email;
  final String? givenName;
  final String? familyName;

  String? get displayName {
    final parts = [
      if (givenName != null && givenName!.trim().isNotEmpty) givenName!.trim(),
      if (familyName != null && familyName!.trim().isNotEmpty)
        familyName!.trim(),
    ];
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'givenName': givenName,
    'familyName': familyName,
  };

  factory AppleAuthStoredProfile.fromJson(Map<String, dynamic> json) {
    return AppleAuthStoredProfile(
      email: json['email'] as String?,
      givenName: json['givenName'] as String?,
      familyName: json['familyName'] as String?,
    );
  }
}

abstract class AppleAuthLocalDataSource {
  Future<void> saveFirstLoginProfile({
    required String userIdentifier,
    required AuthorizationCredentialAppleID credential,
  });

  Future<AppleAuthStoredProfile?> readProfile(String userIdentifier);
}

class AppleAuthLocalDataSourceImpl implements AppleAuthLocalDataSource {
  AppleAuthLocalDataSourceImpl({FlutterSecureStorage? secureStorage})
    : _storage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  String _keyFor(String userIdentifier) =>
      '${StorageKeys.appleAuthProfilePrefix}$userIdentifier';

  @override
  Future<void> saveFirstLoginProfile({
    required String userIdentifier,
    required AuthorizationCredentialAppleID credential,
  }) async {
    final email = credential.email?.trim();
    final givenName = credential.givenName?.trim();
    final familyName = credential.familyName?.trim();

    if ((email == null || email.isEmpty) &&
        (givenName == null || givenName.isEmpty) &&
        (familyName == null || familyName.isEmpty)) {
      return;
    }

    final existing = await readProfile(userIdentifier);
    final profile = AppleAuthStoredProfile(
      email: (email != null && email.isNotEmpty) ? email : existing?.email,
      givenName: (givenName != null && givenName.isNotEmpty)
          ? givenName
          : existing?.givenName,
      familyName: (familyName != null && familyName.isNotEmpty)
          ? familyName
          : existing?.familyName,
    );

    await _storage.write(
      key: _keyFor(userIdentifier),
      value: jsonEncode(profile.toJson()),
    );
  }

  @override
  Future<AppleAuthStoredProfile?> readProfile(String userIdentifier) async {
    final raw = await _storage.read(key: _keyFor(userIdentifier));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return AppleAuthStoredProfile.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }
}
