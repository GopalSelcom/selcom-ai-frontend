import 'package:local_auth/local_auth.dart';

/// Device biometric gate for app login (Face ID / fingerprint).
///
/// Server only stores `biometric_enabled`; unlock still requires valid session refresh.
/// Used by [LoginPinController], [SettingsController], [LoginPinGateService].
class BiometricService {
  BiometricService() : _auth = LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      return canCheck && supported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({String localizedReason = 'Unlock Selcom Go'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
