import 'package:google_sign_in/google_sign_in.dart' as gsi;

enum GoogleSignInErrorType { canceled, configurationError, unsupported, other }

class GoogleSignInServiceException implements Exception {
  const GoogleSignInServiceException(this.type);

  final GoogleSignInErrorType type;
}

class GoogleSignInService {
  gsi.GoogleSignIn get _googleSignIn => gsi.GoogleSignIn.instance;

  Future<void>? _initFuture;

  Future<void> _ensureInitialized() {
    _initFuture ??= _googleSignIn.initialize();
    return _initFuture!;
  }

  Future<gsi.GoogleSignInAccount> signIn() async {
    await _ensureInitialized();

    if (!_googleSignIn.supportsAuthenticate()) {
      throw const GoogleSignInServiceException(
        GoogleSignInErrorType.unsupported,
      );
    }

    try {
      return await _googleSignIn.authenticate(scopeHint: ['email']);
    } on gsi.GoogleSignInException catch (e) {
      throw GoogleSignInServiceException(_mapErrorType(e.code));
    }
  }

  GoogleSignInErrorType _mapErrorType(gsi.GoogleSignInExceptionCode code) {
    switch (code) {
      case gsi.GoogleSignInExceptionCode.canceled:
        return GoogleSignInErrorType.canceled;
      case gsi.GoogleSignInExceptionCode.clientConfigurationError:
        return GoogleSignInErrorType.configurationError;
      default:
        return GoogleSignInErrorType.other;
    }
  }
}
