import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/app_profile_header.dart';
import '../../../../../shared/widgets/custom_loader.dart';
import '../controllers/settings_controller.dart';
import '../widgets/ride_pin_protection_section.dart';

class SafetyScreen extends GetView<SettingsController> {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          AppProfileHeader(title: AppStrings.safety.tr),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const CustomLoader();
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: controller.loadSettings,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
                  children: const [
                    RidePinProtectionSection(),
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
