import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../localization/app_strings.dart';
import 'failures.dart';

class ErrorMapper {
  static Failure mapDioExceptionToFailure(DioException exception) {
    if (exception.type == DioExceptionType.connectionTimeout ||
        exception.type == DioExceptionType.receiveTimeout ||
        exception.type == DioExceptionType.sendTimeout) {
      return NetworkFailure(
        AppStrings.connectionTimedOutPleaseCheckInternet.tr,
      );
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
              return AuthFailure(
                message ?? AppStrings.sessionExpiredPleaseLoginAgain.tr,
              );
            case 'AUTH_TOKEN_EXPIRED':
              return AuthFailure(
                message ?? AppStrings.sessionExpiredRefreshing.tr,
              );
            case 'AUTH_OTP_INVALID':
              return AuthFailure(message ?? AppStrings.invalidOtp.tr);
            case 'AUTH_PIN_WRONG':
            case 'AUTH_PIN_INCORRECT':
              return AuthFailure(message ?? AppStrings.incorrectPin.tr);
            case 'AUTH_PIN_INVALID_FORMAT':
            case 'AUTH_PIN_TOO_WEAK':
            case 'AUTH_PIN_ALREADY_SET':
            case 'AUTH_PIN_NOT_SET':
            case 'AUTH_PIN_REQUIRED_FOR_BIOMETRIC':
              return ServerFailure(message ?? AppStrings.anUnexpectedErrorOccurred.tr);
            case 'AUTH_PIN_LOCKED':
              return ServerFailure(message ?? AppStrings.pinLocked.tr);
            case 'AUTH_USER_BLOCKED':
              return ServerFailure(
                message ?? AppStrings.accountUnavailablePleaseContactSupport.tr,
              );
            case 'RIDE_ALREADY_ACTIVE':
              return ServerFailure(
                message ?? AppStrings.youAlreadyHaveAnActiveRide.tr,
              );
            case 'PAY_INSUFFICIENT_FUNDS':
              return ServerFailure(
                message ?? AppStrings.insufficientFundsInWallet.tr,
              );
            default:
              return ServerFailure(
                message ?? AppStrings.anUnexpectedErrorOccurred.tr,
              );
          }
        }
      }
    }

    return ServerFailure(AppStrings.somethingWentWrongPleaseTryAgain.tr);
  }
}
