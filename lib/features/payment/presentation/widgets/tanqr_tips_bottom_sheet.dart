import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_qr_code.dart';

/// TanQR tips layout: decorative card, live QR, account row, optional timer.
class TanQrTipsContent extends StatelessWidget {
  const TanQrTipsContent({
    super.key,
    required this.qrData,
    required this.accountName,
    required this.accountNumber,
    this.countdownText,
  });

  final String qrData;
  final String accountName;
  final String accountNumber;
  final String? countdownText;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 10.w),
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(31.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Padding(
              //   padding: EdgeInsets.only(left: 22.w, top: 18.h),
              //   child: SvgPictureAsset(
              //     AppAssets.icTips,
              //     width: 92.w,
              //     height: 28.h,
              //     fit: BoxFit.contain,
              //   ),
              // ),
              // SizedBox(height: 18.h),
              _TanQrPaymentCard(
                qrData: qrData,
                accountName: accountName,
                accountNumber: accountNumber,
              ),
            ],
          ),
        ),
        if (countdownText != null && countdownText!.isNotEmpty) ...[
          SizedBox(height: 20.h),
          Text(
            AppStrings.tanQrScanQrInstruction.tr,
            textAlign: TextAlign.center,
            style: AppTextStyles.homeSubtitle.copyWith(
              color: AppColors.textMutedStrong,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            countdownText!,
            textAlign: TextAlign.center,
            style: AppTextStyles.homeTitle.copyWith(
              fontSize: 16.sp,
              color: AppColors.textHeading,
            ),
          ),
        ],
        SizedBox(height: 8.h),
      ],
    );
  }
}

class TanQrTipsBottomSheet extends StatelessWidget {
  const TanQrTipsBottomSheet({super.key});

  static Future<void> show() {
    return AppDialogs.showStandardBottomSheet<void>(
      headerTextAlign: TextAlign.center,
      showHeaderDivider: false,
      barrierDismissible: true,
      content: const TanQrTipsBottomSheet(),
      footer: AppPrimaryButton(
        label: AppStrings.done.tr,
        onPressed: () => Get.back<void>(),
        width: double.infinity,
        height: 56.h,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const TanQrTipsContent(
      qrData: '',
      accountName: '',
      accountNumber: '',
    );
  }
}

class _TanQrPaymentCard extends StatelessWidget {
  const _TanQrPaymentCard({
    required this.qrData,
    required this.accountName,
    required this.accountNumber,
  });

  final String qrData;
  final String accountName;
  final String accountNumber;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(31.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(22.w, 57.h, 22.w, 41.h),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.imgQrBg),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppQrCode(data: qrData),
            SizedBox(height: 27.h),
            _TanQrAccountCard(
              accountName: accountName,
              accountNumber: accountNumber,
            ),
          ],
        ),
      ),
    );
  }
}

class _TanQrAccountCard extends StatelessWidget {
  const _TanQrAccountCard({
    required this.accountName,
    required this.accountNumber,
  });

  final String accountName;
  final String accountNumber;

  @override
  Widget build(BuildContext context) {
    final name = accountName.trim().isNotEmpty ? accountName.trim() : '—';
    final number = accountNumber.trim().isNotEmpty ? accountNumber.trim() : '—';

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        children: [
          Text(
            name,
            style: AppTextStyles.homeSubtitle.copyWith(
              color: AppColors.black,
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              height: 1,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            number,
            style: AppTextStyles.homeSubtitle.copyWith(
              color: AppColors.textQrMeta,
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              height: 1,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
