import 'package:dio/dio.dart';
import 'failures.dart';

class ErrorMapper {
  static Failure mapDioExceptionToFailure(DioException exception) {
    if (exception.type == DioExceptionType.connectionTimeout ||
        exception.type == DioExceptionType.receiveTimeout ||
        exception.type == DioExceptionType.sendTimeout) {
      return const NetworkFailure('Connection timed out. Please check your internet.');
    }

    if (exception.response != null) {
      final data = exception.response!.data;
      if (data is Map<String, dynamic>) {
        final errorCode = data['error_code'] as String?;
        final message = data['message'] as String?;

        if (errorCode != null) {
          switch (errorCode) {
            case 'AUTH_NO_TOKEN':
            case 'AUTH_INVALID_TOKEN':
            case 'AUTH_SESSION_REVOKED':
              return AuthFailure(message ?? 'Session expired. Please login again.');
            case 'AUTH_TOKEN_EXPIRED':
              return AuthFailure(message ?? 'Session expired. Refreshing...');
            case 'AUTH_OTP_INVALID':
              return AuthFailure(message ?? 'Invalid OTP.');
            case 'AUTH_PIN_WRONG':
              return AuthFailure(message ?? 'Incorrect PIN.');
            case 'RIDE_ALREADY_ACTIVE':
              return ServerFailure(message ?? 'You already have an active ride.');
            case 'PAY_INSUFFICIENT_FUNDS':
              return ServerFailure(message ?? 'Insufficient funds in wallet.');
            default:
              return ServerFailure(message ?? 'An unexpected error occurred.');
          }
        }
      }
    }

    return const ServerFailure('Something went wrong. Please try again.');
  }
}
