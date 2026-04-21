import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
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
          const AppProfileHeader(title: 'Settings'),
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
                            'App Settings',
                            style: AppTextStyles.sectionTitle.copyWith(
                              color: AppColors.shade2,
                              fontSize: 15.sp,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Security and preference controls. More settings will appear here as they are enabled.',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.shade2,
                            ),
                          ),
                          SizedBox(height: 14.h),
                          Obx(
                            () => SettingsToggleTile(
                              icon: Iconsax.shield_security,
                              title: 'Ride PIN Protection',
                              subtitle: controller.canToggleRidePin
                                  ? 'Require a verification PIN before starting a ride.'
                                  : 'Ride PIN is required by admin and cannot be turned off.',
                              statusText: controller.effectiveRequiredRidePin.value
                                  ? 'Current status: required'
                                  : 'Current status: optional',
                              value: controller.userEnabledRidePin.value,
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
