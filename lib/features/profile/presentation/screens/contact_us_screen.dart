import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
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
      backgroundColor: AppColors.pageBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppProfileHeader(title: 'Contact Us', bottomPadding: 24),

          SizedBox(height: 32.h),

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
                        'Reason to Contact',
                        style: AppTextStyles.homeSubtitle,
                      ),
                      SizedBox(height: 8.h),
                      _buildReasonDropdown(context),

                      SizedBox(height: 24.h),
                      Text('Message', style: AppTextStyles.homeSubtitle),
                      SizedBox(height: 8.h),
                      AppTextField(
                        controller: controller.messageController,
                        hintText: 'Type your message here...',
                        maxLines: 5,
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
              padding: EdgeInsets.only(bottom: 16.h, left: 24.w, right: 24.w),
              child: AppPrimaryButton(
                label: 'Submit',
                onPressed: controller.sendMessage,
                isLoading: controller.isLoading.value,
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
          color: Colors.white,
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
                    color: controller.selectedReason.value == 'Select a Reason'
                        ? AppColors.textGrey
                        : AppColors.textDark,
                  ),
                ),
              ),
            ),
            const Icon(Iconsax.arrow_down_1, color: AppColors.shade2, size: 20),
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
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select a Reason', style: AppTextStyles.sectionTitle),
            SizedBox(height: 16.h),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: controller.subjects.length,
                itemBuilder: (context, index) {
                  final reason = controller.subjects[index];
                  return ListTile(
                    title: Text(reason, style: AppTextStyles.body),
                    onTap: () {
                      controller.selectedReason.value = reason;
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
