import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_adaptive_bottom_safe_scaffold.dart';
import '../../../../../shared/widgets/app_profile_header.dart';
import '../controllers/settings_controller.dart';
import '../widgets/ride_pin_protection_section.dart';
import '../widgets/settings_screen_shimmer.dart';

class SafetyScreen extends GetView<SettingsController> {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveBottomSafeScaffold(
      backgroundColor: AppColors.white,
      hasBottomWidget: true,
      body: Column(
        children: [
          AppProfileHeader(title: AppStrings.safety.tr),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return SettingsScreenShimmer.safetyContent();
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: controller.loadSettings,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
                  children: const [RidePinProtectionSection()],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
