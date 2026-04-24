import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/app_profile_header.dart';
import '../controllers/settings_controller.dart';
import '../widgets/settings_toggle_tile.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Column(
        children: [
          AppProfileHeader(title: AppStrings.settings.tr),
          Expanded(
            child: Obx(
              () => controller.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: controller.loadSettings,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 24.h),
                        children: [
                          Text(
                            AppStrings.appSettings.tr,
                            style: AppTextStyles.sectionTitle.copyWith(
                              color: AppColors.textBody,
                              fontSize: 15.sp,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            AppStrings
                                .securityAndPreferenceControlsMoreSettingsWillAppearHereAsTheyAreEnable
                                .tr,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textBody,
                            ),
                          ),
                          SizedBox(height: 14.h),
                          if (!controller.hasRidePinFeature)
                            Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                border: Border.all(color: AppColors.divider),
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: Text(
                                AppStrings
                                    .noConfigurableSettingsAreAvailableRightNow
                                    .tr,
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textBody,
                                ),
                              ),
                            )
                          else
                            Obx(
                              () => SettingsToggleTile(
                                icon: Iconsax.shield_security,
                                title: AppStrings.ridePinProtection.tr,
                                subtitle: controller.canToggleRidePin
                                    ? 'Require a verification PIN before starting a ride.'
                                    : 'Ride PIN is required by admin and cannot be turned off.',
                                statusText:
                                    controller.effectiveRequiredRidePin.value
                                    ? 'Current status: required'
                                    : 'Current status: optional',
                                value: controller.ridePinSwitchValue,
                                enabled: controller.canToggleRidePin,
                                isSaving: controller.isSaving.value,
                                onChanged: controller.onToggleRidePin,
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
