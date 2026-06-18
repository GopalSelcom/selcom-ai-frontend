import 'package:get/get.dart';

import '../../core/localization/app_strings.dart';

/// User-facing copy for `POST go/validate_ride_payment` business rejections.
abstract final class RidePaymentValidationMessages {
  static String displayMessage({
    required String errorCode,
    String apiMessage = '',
  }) {
    switch (errorCode.trim()) {
      case 'BOOKED_FOR_OTHER_LIMIT_REACHED':
        return AppStrings.bookedForOtherLimitReached.tr;
      case 'BOOKED_FOR_OTHER_NO_MULTI_STOP':
        return AppStrings.bookedForOtherNoMultiStop.tr;
      case 'RIDE_ALREADY_ACTIVE':
        return AppStrings.youAlreadyHaveAnActiveRide.tr;
      default:
        final trimmedApiMessage = apiMessage.trim();
        if (trimmedApiMessage.isNotEmpty) return trimmedApiMessage;
        return AppStrings.couldNotValidatePaymentPleaseTryAgain.tr;
    }
  }
}
