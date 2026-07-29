/// Thrown when cancel returns HTTP 409 `RIDE_ALREADY_FINALIZED`.
class RideAlreadyFinalizedException implements Exception {
  final String message;
  final String errorCode;

  const RideAlreadyFinalizedException(
    this.message, {
    this.errorCode = 'RIDE_ALREADY_FINALIZED',
  });

  @override
  String toString() => message;
}
