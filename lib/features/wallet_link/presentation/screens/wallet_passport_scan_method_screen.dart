import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../controllers/wallet_passport_scan_controller.dart';

/// Passport scan method — parity with selcom_auth [PassportScanMethodScreen].
class WalletPassportScanMethodScreen
    extends GetView<WalletPassportScanController> {
  const WalletPassportScanMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 0),
              child: Row(
                children: [
                  AppBackButton(
                    color: AppColors.textHeading,
                    size: 22.w,
                    onPressed: Get.back,
                  ),
                  Expanded(
                    child: Text(
                      AppStrings.walletLinkPassportScanTitle.tr,
                      style: AppTextStyles.sectionTitle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 40.w),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.walletLinkPassportScanHow.tr,
                      style: AppTextStyles.cardTitle.copyWith(height: 1.35),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      AppStrings.walletLinkPassportScanHowBody.tr,
                      style: AppTextStyles.bodySecondary.copyWith(height: 1.35),
                    ),
                    SizedBox(height: 24.h),
                    _MethodCard(
                      icon: CupertinoIcons.waveform_path,
                      title: AppStrings.walletLinkPassportNfcTitle.tr,
                      body: AppStrings.walletLinkPassportNfcBody.tr,
                      buttonLabel: AppStrings.walletLinkPassportNfcCta.tr,
                      onPressed: () => controller.openNfcScan(context),
                    ),
                    SizedBox(height: 16.h),
                    _MethodCard(
                      icon: CupertinoIcons.camera,
                      title: AppStrings.walletLinkPassportCameraTitle.tr,
                      body: AppStrings.walletLinkPassportCameraBody.tr,
                      buttonLabel: AppStrings.walletLinkPassportCameraCta.tr,
                      onPressed: () => controller.openCameraScan(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String body;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.bgVerificationSurface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 28.sp, color: AppColors.textHeading),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(title, style: AppTextStyles.cardTitle),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            body,
            style: AppTextStyles.bodySecondary.copyWith(height: 1.4),
          ),
          SizedBox(height: 16.h),
          AppPrimaryButton(
            label: buttonLabel,
            width: double.infinity,
            height: 48.h,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}
