import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/app_dialogs.dart';

/// Receipt download / share picker body for [AppDialogs.showStandardBottomSheet].
class ReceiptOptionsBottomSheet extends StatelessWidget {
  const ReceiptOptionsBottomSheet({
    super.key,
    required this.onDownload,
    required this.onShare,
  });

  final VoidCallback onDownload;
  final VoidCallback onShare;

  static Future<void> show({
    required VoidCallback onDownload,
    required VoidCallback onShare,
  }) {
    return AppDialogs.showStandardBottomSheet<void>(
      title: AppStrings.receiptOptions.tr,
      subtitle: AppStrings.chooseHowToReceiveReceipt.tr,
      headerTextAlign: TextAlign.center,
      content: ReceiptOptionsBottomSheet(
        onDownload: onDownload,
        onShare: onShare,
      ),
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ReceiptOptionTile(
          icon: Icons.download_rounded,
          title: AppStrings.downloadSlip.tr,
          subtitle: AppStrings.downloadSlipGallerySubtitle.tr,
          onTap: () {
            Get.back();
            onDownload();
          },
        ),
        SizedBox(height: 16.h),
        _ReceiptOptionTile(
          icon: Icons.share_rounded,
          title: AppStrings.shareSlip.tr,
          subtitle: AppStrings.shareSlipSubtitle.tr,
          onTap: () {
            Get.back();
            onShare();
          },
        ),
      ],
    );
  }
}

class _ReceiptOptionTile extends StatelessWidget {
  const _ReceiptOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 24.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 16.sp),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textMuted,
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }
}
