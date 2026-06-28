import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../utils/app_dialogs.dart';
import 'app_standard_bottom_sheet_gesture_pad.dart';

/// One row in [AppReasonPickerBottomSheet].
class AppReasonPickerOption {
  const AppReasonPickerOption({
    required this.label,
    String? value,
  }) : value = value ?? label;

  final String label;
  final String value;
}

/// Standard reason / subject list for [AppDialogs.showStandardBottomSheet].
class AppReasonPickerBottomSheet extends StatelessWidget {
  const AppReasonPickerBottomSheet({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  final List<AppReasonPickerOption> options;
  final String selectedValue;
  final ValueChanged<AppReasonPickerOption> onSelected;

  /// Opens the sheet shell; pass [content] (often wrapped in `Obx`) for reactive lists.
  static Future<void> show({required Widget content}) {
    return AppDialogs.showStandardBottomSheet<void>(
      title: AppStrings.selectAReason.tr,
      subtitle: AppStrings.selectAReasonSubtitle.tr,
      headerTextAlign: TextAlign.start,
      barrierDismissible: true,
      content: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < options.length; index++) ...[
          if (index > 0)
            Divider(
              height: 1.h,
              thickness: 1.h,
              color: AppColors.bgSoftCircle,
            ),
          _ReasonTile(
            label: options[index].label,
            isSelected: selectedValue == options[index].value,
            onTap: () {
              onSelected(options[index]);
              Get.back<void>();
            },
          ),
        ],
        const AppStandardBottomSheetGesturePad(),
      ],
    );
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
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
                  label,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textHeading,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
