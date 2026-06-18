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
            case 'AUTH_OTP_EXPIRED':
              return AuthFailure(message ?? AppStrings.invalidOtp.tr);
            case 'AUTH_PHONE_ALREADY_IN_USE':
              return AuthFailure(
                message ??
                    'This phone number is already linked to another account.',
              );
            case 'AUTH_FIREBASE_TOKEN_MISSING':
            case 'AUTH_FIREBASE_TOKEN_INVALID':
            case 'AUTH_FIREBASE_TOKEN_EXPIRED':
              return AuthFailure(
                message ?? AppStrings.somethingWentWrongPleaseTryAgain.tr,
              );
            case 'AUTH_FIREBASE_NOT_CONFIGURED':
              return ServerFailure(
                message ?? AppStrings.somethingWentWrongPleaseTryAgain.tr,
              );
            case 'AUTH_USER_BLOCKED':
              return AuthFailure(
                message ?? 'Account unavailable. Please contact support.',
              );
            case 'AUTH_OTP_DEPRECATED_FOR_GO':
              return ServerFailure(
                message ?? AppStrings.somethingWentWrongPleaseTryAgain.tr,
              );
            case 'AUTH_PIN_WRONG':
              return AuthFailure(message ?? AppStrings.incorrectPin.tr);
            case 'RIDE_ALREADY_ACTIVE':
              return ServerFailure(AppStrings.youAlreadyHaveAnActiveRide.tr);
            case 'BOOKED_FOR_OTHER_LIMIT_REACHED':
              return ServerFailure(AppStrings.bookedForOtherLimitReached.tr);
            case 'BOOKED_FOR_OTHER_NO_MULTI_STOP':
              return ServerFailure(AppStrings.bookedForOtherNoMultiStop.tr);
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
