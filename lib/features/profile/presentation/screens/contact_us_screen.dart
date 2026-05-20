import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_animated_reveal.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/contact_us_controller.dart';
import '../../../../shared/utils/app_dialogs.dart';

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
              child: AppAnimatedReveal(
                show: controller.canSubmit.value,
                visibleKey: const ValueKey('contact-submit-visible'),
                hiddenKey: const ValueKey('contact-submit-hidden'),
                child: AppPrimaryButton(
                  label: AppStrings.submit.tr,
                  onPressed: controller.sendMessage,
                  isLoading: controller.isLoading.value,
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
    AppDialogs.showAnimatedBottomSheet(
      barrierDismissible: true,
      child: Container(
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
                      Navigator.of(context).pop();
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
