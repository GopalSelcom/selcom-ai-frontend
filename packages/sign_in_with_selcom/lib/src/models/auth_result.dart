/// Status representation of the Selcom Auth process.
enum SelcomAuthStatus {
  /// The authentication was successful and a token was retrieved.
  success,

  /// The authentication failed due to an error.
  failure,

  /// The authentication was cancelled or aborted by the user.
  cancelled,
}

/// Represents the final outcome of the App-to-App SSO authentication workflow.
class SelcomAuthResult {
  /// The overall status of the authentication attempt.
  final SelcomAuthStatus status;

  /// The authentication token, available only on [SelcomAuthStatus.success].
  final String? token;

  /// The error message, available only on [SelcomAuthStatus.failure].
  final String? errorMessage;

  const SelcomAuthResult._({
    required this.status,
    this.token,
    this.errorMessage,
  });

  /// Creates a successful authentication result containing [token].
  factory SelcomAuthResult.success(String token) {
    return SelcomAuthResult._(
      status: SelcomAuthStatus.success,
      token: token,
    );
  }

  /// Creates a failed authentication result containing [errorMessage].
  factory SelcomAuthResult.failure(String errorMessage) {
    return SelcomAuthResult._(
      status: SelcomAuthStatus.failure,
      errorMessage: errorMessage,
    );
  }

  /// Creates a cancelled authentication result.
  factory SelcomAuthResult.cancelled() {
    return SelcomAuthResult._(
      status: SelcomAuthStatus.cancelled,
    );
  }

  /// Helper to check if authentication succeeded.
  bool get isSuccess => status == SelcomAuthStatus.success;

  /// Helper to check if authentication failed.
  bool get isFailure => status == SelcomAuthStatus.failure;

  /// Helper to check if authentication was cancelled.
  bool get isCancelled => status == SelcomAuthStatus.cancelled;

  @override
  String toString() {
    switch (status) {
      case SelcomAuthStatus.success:
        return 'SelcomAuthResult.success(token: $token)';
      case SelcomAuthStatus.failure:
        return 'SelcomAuthResult.failure(error: $errorMessage)';
      case SelcomAuthStatus.cancelled:
        return 'SelcomAuthResult.cancelled()';
    }
  }
}
