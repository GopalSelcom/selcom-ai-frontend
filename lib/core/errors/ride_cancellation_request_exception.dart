/// Business exceptions for route-deviation cancellation-request APIs.
class RideNotActiveException implements Exception {
  RideNotActiveException(this.message, {this.errorCode = 'RIDE_NOT_ACTIVE'});

  final String message;
  final String errorCode;

  @override
  String toString() => message;
}

class CancellationRequestAlreadyDecidedException implements Exception {
  CancellationRequestAlreadyDecidedException(this.message, {
    this.errorCode = 'ALREADY_DECIDED',
  });

  final String message;
  final String errorCode;

  @override
  String toString() => message;
}
