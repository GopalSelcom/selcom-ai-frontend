import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';

class SettingsToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String statusText;
  final bool value;
  final bool enabled;
  final bool isSaving;
  final ValueChanged<bool>? onChanged;

  const SettingsToggleTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.statusText,
    required this.value,
    required this.enabled,
    required this.isSaving,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 36.w,
                  width: 36.w,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 18.w),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.cardTitle.copyWith(
                      color: AppColors.textHeading,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: enabled ? onChanged : null,
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    final selected = states.contains(WidgetState.selected);
                    final disabled = states.contains(WidgetState.disabled);

                    if (selected && disabled) {
                      return AppColors.primary.withValues(alpha: 0.9);
                    }
                    if (selected) return AppColors.primary;
                    if (disabled) {
                      return AppColors.textBody.withValues(alpha: 0.6);
                    }
                    return AppColors.textBody;
                  }),
                  trackColor: WidgetStateProperty.resolveWith((states) {
                    final selected = states.contains(WidgetState.selected);
                    final disabled = states.contains(WidgetState.disabled);

                    if (selected && disabled) {
                      return AppColors.primary.withValues(alpha: 0.35);
                    }
                    if (selected) {
                      return AppColors.primary.withValues(alpha: 0.45);
                    }
                    if (disabled) {
                      return AppColors.divider.withValues(alpha: 0.8);
                    }
                    return AppColors.divider;
                  }),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              subtitle,
              style: AppTextStyles.body.copyWith(color: AppColors.textBody),
            ),
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.pageBackground,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.info_circle,
                    size: 14.w,
                    color: AppColors.textBody,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      statusText,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textBody,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isSaving) ...[
              SizedBox(height: 10.h),
              Row(
                children: [
                  SizedBox(
                    width: 14.w,
                    height: 14.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    AppStrings.savingChanges.tr,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textBody,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
