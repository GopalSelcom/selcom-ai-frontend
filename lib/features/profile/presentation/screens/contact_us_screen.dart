import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/contact_us_controller.dart';

class ContactUsScreen extends GetView<ContactUsController> {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppProfileHeader(title: AppStrings.contactUs.tr),

          SizedBox(height: 16.h),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.subjects.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.reasonToContact.tr,
                        style: AppTextStyles.homeSubtitle,
                      ),
                      SizedBox(height: 8.h),
                      _buildReasonDropdown(context),
                      SizedBox(height: 8.h),
                      Text(
                        AppStrings.message.tr,
                        style: AppTextStyles.homeSubtitle,
                      ),
                      SizedBox(height: 8.h),
                      AppTextField(
                        controller: controller.messageController,
                        hintText: AppStrings.howCanWeHelpYou.tr,
                        maxLines: 5,
                        onChanged: controller.onMessageChanged,
                        textColor: AppColors.textHeading,
                        textFieldBackgroundColor: AppColors.surfaceSubtle,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),

          // Submit Button (Footer)
          Obx(
            () => Padding(
              padding: EdgeInsets.only(
                bottom: controller.canSubmit.value ? 16.h : 0,
                left: 24.w,
                right: 24.w,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axis: Axis.vertical,
                    child: child,
                  ),
                ),
                child: controller.canSubmit.value
                    ? AppPrimaryButton(
                        key: const ValueKey('contact-submit-visible'),
                        label: AppStrings.submit.tr,
                        onPressed: controller.sendMessage,
                        isLoading: controller.isLoading.value,
                      )
                    : const SizedBox.shrink(
                        key: ValueKey('contact-submit-hidden'),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonDropdown(BuildContext context) {
    return GestureDetector(
      onTap: () => _showReasonPicker(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.divider),

        ),
        child: Row(
          children: [
            Expanded(
              child: Obx(
                () => Text(
                  controller.selectedReason.value,
                  style: AppTextStyles.body.copyWith(
                    color: controller.selectedReason.value ==
                            AppStrings.selectAReason.tr
                        ? AppColors.textBody
                        : AppColors.textHeading,
                  ),
                ),
              ),
            ),
            const Icon(Iconsax.arrow_down_1, color: AppColors.textHeading, size: 20),
          ],
        ),
      ),
    );
  }

  void _showReasonPicker(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.selectAReason.tr,
              style: AppTextStyles.sectionTitle,
            ),
            SizedBox(height: 16.h),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: controller.subjects.length,
                itemBuilder: (context, index) {
                  final reason = controller.subjects[index];
                  return ListTile(
                    title: Text(reason, style: AppTextStyles.body.copyWith(
                      color: AppColors.textHeading))
                    ,
                    onTap: () {
                      controller.setSelectedReason(reason);
                      Get.back();
                    },
                    trailing: Obx(
                      () => controller.selectedReason.value == reason
                          ? const Icon(
                              Iconsax.tick_circle,
                              color: AppColors.primary,
                            )
                          : const SizedBox.shrink(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
