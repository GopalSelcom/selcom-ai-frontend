import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../controllers/driver_accepted_controller.dart';

/// Having-trouble cancel-request card (separate from route deviation).
///
/// Uses the same warning / neutral tones as the deviation cancel states.
class HavingTroubleCancellationBanner extends StatelessWidget {
  const HavingTroubleCancellationBanner({super.key, required this.controller});

  final DriverAcceptedController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.shouldShowManualCancellationBanner) {
        return const SizedBox.shrink();
      }

      final pending = controller.isManualCancellationPending;
      final rejected = controller.isManualCancellationRejected;
      // Match deviation cancel: pending = warning, rejected = neutral.
      final Color bg;
      final Color border;
      final Color accent;
      final IconData icon;
      if (rejected) {
        bg = AppColors.surfaceSubtle;
        border = AppColors.borderWalletCard;
        accent = AppColors.textSlate;
        icon = Icons.info_outline_rounded;
      } else {
        bg = AppColors.bgWarningLight;
        border = AppColors.warning.withValues(alpha: 0.35);
        accent = AppColors.warningStrong;
        icon = Icons.warning_amber_rounded;
      }

      return Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, size: 20.sp, color: accent),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    AppStrings.requestToCancel.tr,
                    style: AppTextStyles.homeSubtitle.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeading,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            if (pending) ...[
              SizedBox(height: 12.h),
              _StatusCallout(
                text: AppStrings.cancellationRequestSentWithTicket.trParams({
                  'ticket': controller.manualCancellationTicketNumber,
                }),
              ),
              SizedBox(height: 12.h),
              AppPrimaryButton(
                label: AppStrings.withdrawRequest.tr,
                onPressed: controller.withdrawManualCancellationRequest,
                outlined: true,
                outlinedBorderColor: AppColors.borderWalletCard,
                outlinedTextColor: AppColors.textHeading,
                height: 44.h,
                borderRadius: 12.r,
                labelStyle: AppTextStyles.homeSubtitle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHeading,
                ),
              ),
            ] else if (rejected) ...[
              SizedBox(height: 12.h),
              _StatusCallout(
                text: AppStrings.supportDeclinedCancellation.tr,
                note: controller.manualCancellationNote.isEmpty
                    ? null
                    : controller.manualCancellationNote,
              ),
              if (controller.canRequestCancellationAfterManualReject) ...[
                SizedBox(height: 12.h),
                AppPrimaryButton(
                  label: AppStrings.requestToCancel.tr,
                  onPressed: () => controller.openHavingTroubleCancellationSheet(
                    forceRetry: true,
                  ),
                  height: 44.h,
                  borderRadius: 12.r,
                  labelStyle: AppTextStyles.homeSubtitle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ],
            ],
          ],
        ),
      );
    });
  }
}

class _StatusCallout extends StatelessWidget {
  const _StatusCallout({required this.text, this.note});

  final String text;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderWalletCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: AppTextStyles.homeSubtitle.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textHeading,
              height: 1.35,
              fontSize: 13.sp,
            ),
          ),
          if (note != null && note!.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              note!,
              style: AppTextStyles.homeSubtitle.copyWith(
                color: AppColors.textSlate,
                height: 1.35,
                fontSize: 12.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
