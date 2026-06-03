import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../features/payment/domain/models/insufficient_wallet_balance_details.dart';
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
              return AuthFailure(message ?? AppStrings.incorrectPin.tr);
            case 'RIDE_ALREADY_ACTIVE':
              return ServerFailure(
                message ?? AppStrings.youAlreadyHaveAnActiveRide.tr,
              );
            case 'PAY_INSUFFICIENT_FUNDS': {
              final details =
                  InsufficientWalletBalanceDetails.tryParseFromApiResponse(data);
              if (details != null) {
                return InsufficientWalletBalanceFailure(
                  message ?? AppStrings.insufficientFundsInWallet.tr,
                  details: details,
                );
              }
              return ServerFailure(
                message ?? AppStrings.insufficientFundsInWallet.tr,
              );
            }
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
