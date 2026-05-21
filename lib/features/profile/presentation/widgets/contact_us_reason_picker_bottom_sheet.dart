import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../controllers/contact_us_controller.dart';

/// Contact-us subject picker body for [AppDialogs.showStandardBottomSheet].
class ContactUsReasonPickerBottomSheet extends GetView<ContactUsController> {
  const ContactUsReasonPickerBottomSheet({super.key});

  static Future<void> show() {
    return AppDialogs.showStandardBottomSheet<void>(
      title: AppStrings.selectAReason.tr,
      subtitle: AppStrings.selectAReasonSubtitle.tr,
      headerTextAlign: TextAlign.start,
      barrierDismissible: true,
      content: const ContactUsReasonPickerBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final reasons = controller.subjects;
      if (reasons.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < reasons.length; index++) ...[
            if (index > 0)
              Divider(
                height: 1.h,
                thickness: 1.h,
                color: AppColors.bgSoftCircle,
              ),
            _ReasonTile(
              reason: reasons[index],
              isSelected: controller.selectedReason.value == reasons[index],
              onTap: () {
                controller.setSelectedReason(reasons[index]);
                Get.back<void>();
              },
            ),
          ],
        ],
      );
    });
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.reason,
    required this.isSelected,
    required this.onTap,
  });

  final String reason;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  reason,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textHeading,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Iconsax.tick_circle,
                  color: AppColors.primary,
                  size: 22.sp,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
