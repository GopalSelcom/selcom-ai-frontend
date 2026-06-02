import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/widgets/app_primary_button.dart';

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
              Padding(
                padding: EdgeInsets.only(left: 22.w, top: 18.h),
                child: SvgPictureAsset(
                  AppAssets.icTips,
                  width: 92.w,
                  height: 28.h,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 18.h),
              _QrCard(),
            ],
          ),
        ),
      ],
    );
  }
}

class _QrCard extends StatelessWidget {
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
            Container(
              padding: EdgeInsets.all(28.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(31.r),
              ),
              child: Image.asset(
                AppAssets.imgQrCode,
                width: 220.w,
                height: 220.w,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 27.h),
            _AccountCard(),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
            'Rosario Arun George',
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
            '6056 1255',
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
