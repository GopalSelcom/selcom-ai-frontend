import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';

/// Maps backend mid-ride cancel reason codes to localized copy.
String midRideCancelReasonLabel({
  required String? reason,
  String? reasonText,
}) {
  switch ((reason ?? '').trim().toLowerCase()) {
    case 'vehicle_breakdown':
      return AppStrings.midRideReasonVehicleBreakdown.tr;
    case 'accident':
      return AppStrings.midRideReasonAccident.tr;
    case 'unsafe':
      return AppStrings.midRideReasonUnsafe.tr;
    case 'other':
      final text = (reasonText ?? '').trim();
      return text.isNotEmpty ? text : AppStrings.midRideReasonOther.tr;
    default:
      final text = (reasonText ?? '').trim();
      if (text.isNotEmpty) return text;
      return AppStrings.midRideReasonOther.tr;
  }
}
