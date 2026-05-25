import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../controllers/settings_controller.dart';
import 'settings_toggle_tile.dart';

/// Ride PIN on/off control — used on the Safety screen.
class RidePinProtectionSection extends StatelessWidget {
  const RidePinProtectionSection({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController controller = Get.find<SettingsController>();

    return Obx(() {
      if (!controller.shouldShowRidePinSetting) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings
                .securityAndPreferenceControlsMoreSettingsWillAppearHereAsTheyAreEnable
                .tr,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textBody,
            ),
          ),
          SizedBox(height: 14.h),
          SettingsToggleTile(
            icon: Iconsax.shield_security,
            title: AppStrings.ridePinProtection.tr,
            subtitle: controller.canToggleRidePin
                ? AppStrings.requireVerificationPinBeforeStartingRide.tr
                : AppStrings.ridePinRequiredByAdminCannotBeTurnedOff.tr,
            statusText: controller.effectiveRequiredRidePin.value
                ? AppStrings.currentStatusRequired.tr
                : AppStrings.currentStatusOptional.tr,
            value: controller.ridePinSwitchValue,
            enabled: controller.canToggleRidePin,
            isSaving: controller.isSaving.value,
            onChanged: controller.onToggleRidePin,
          ),
        ],
      );
    });
  }
}
