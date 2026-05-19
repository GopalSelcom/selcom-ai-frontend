import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/app_profile_header.dart';
import '../controllers/settings_controller.dart';
import '../../widgets/menu_item_widget.dart';
import '../widgets/settings_toggle_tile.dart';

/// App settings: login security, optional ride PIN, notification/language/change PIN.
///
/// **Login & security** — biometric toggle only when [SettingsController.shouldShowBiometricLoginSetting].
/// **General card** — notification, language, change PIN (only if [SettingsController.loginPinSet]).
class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          AppProfileHeader(title: AppStrings.settings.tr),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: controller.loadSettings,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
                  children: [
                    Obx(() {
                      if (!controller.shouldShowBiometricLoginSetting) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.loginAndSecurity.tr,
                            style: AppTextStyles.sectionTitle.copyWith(
                              color: AppColors.textBody,
                              fontSize: 15.sp,
                            ),
                          ),
                          SizedBox(height: 14.h),
                          SettingsToggleTile(
                            icon: Iconsax.finger_scan,
                            title: AppStrings.biometricLogin.tr,
                            subtitle: controller.canToggleBiometricLogin
                                ? AppStrings.unlockWithBiometric.tr
                                : AppStrings.setPinFirstForBiometric.tr,
                            statusText: controller.biometricLoginEnabled.value
                                ? AppStrings.currentStatusRequired.tr
                                : AppStrings.currentStatusOptional.tr,
                            value: controller.biometricLoginEnabled.value,
                            enabled: controller.canToggleBiometricLogin,
                            isSaving: controller.isSavingBiometric.value,
                            onChanged: controller.onToggleBiometricLogin,
                          ),
                          SizedBox(height: 20.h),
                        ],
                      );
                    }),
                    if (controller.shouldShowRidePinSetting) ...[
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
                      Obx(
                        () => SettingsToggleTile(
                          icon: Iconsax.shield_security,
                          title: AppStrings.ridePinProtection.tr,
                          subtitle: controller.canToggleRidePin
                              ? AppStrings.requireVerificationPinBeforeStartingRide.tr
                              : AppStrings.ridePinRequiredByAdminCannotBeTurnedOff.tr,
                          statusText:
                              controller.effectiveRequiredRidePin.value
                              ? AppStrings.currentStatusRequired.tr
                              : AppStrings.currentStatusOptional.tr,
                          value: controller.ridePinSwitchValue,
                          enabled: controller.canToggleRidePin,
                          isSaving: controller.isSaving.value,
                          onChanged: controller.onToggleRidePin,
                        ),
                      ),
                      SizedBox(height: 14.h),
                    ],
                    Container(
                      padding: EdgeInsets.fromLTRB(10.w, 19.h, 10.w, 10.h),
                      decoration: BoxDecoration(
                        color: AppColors.pageBackground,
                        border: Border.all(color: AppColors.divider),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Obx(
                        () {
                          final pinSet = controller.loginPinSet.value;
                          return Column(
                            children: [
                              MenuItemWidget(
                                icon: Iconsax.reserve,
                                title: AppStrings.notification.tr,
                                onTap: controller.openNotifications,
                              ),
                              MenuItemWidget(
                                icon: Iconsax.language_square,
                                title:
                                    '${AppStrings.language.tr} (${controller.currentLanguageLabel})',
                                onTap: () =>
                                    controller.toggleLanguage(context),
                                showDivider: pinSet,
                              ),
                              if (pinSet)
                                MenuItemWidget(
                                  icon: Iconsax.lock,
                                  title: AppStrings.changeLoginPin.tr,
                                  onTap: controller.openChangeLoginPin,
                                  showDivider: false,
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
