import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../controllers/promocode_controller.dart';

class PromocodeScreen extends StatelessWidget {
  const PromocodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PromocodeController controller = Get.put(PromocodeController());

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          AppProfileHeader(title: AppStrings.applyPromoCode.tr),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.enterPromocode.tr,
                    style: AppTextStyles.bodySecondary.copyWith(
                      fontSize: 15.sp,
                      color: AppColors.textMutedStrong,
                      fontWeight: FontWeight.w500,
                      height: 20 / 15,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  _buildPromoInputField(controller),
                  SizedBox(height: 18.h),
                  Text(
                    AppStrings.promocodeList.tr,
                    style: AppTextStyles.bodySecondary.copyWith(
                      fontSize: 15.sp,
                      color: AppColors.textBody,
                      fontWeight: FontWeight.w500,
                      height: 20 / 15,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Obx(
                    () => ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(),
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.promocodes.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final promo = controller.promocodes[index];
                        return _buildPromoCard(promo, controller);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoInputField(PromocodeController controller) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.inputBorderDefault.withValues(alpha: 0.5),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      child: IntrinsicHeight(
        child: Row(
          children: [
            SvgPictureAsset(
              AppAssets.icPromoCode,
              width: 24.w,
              height: 24.w,
              placeholderBuilder: (_) => Container(
                width: 24.w,
                height: 24.w,
                decoration: const BoxDecoration(
                  color: AppColors.promotionBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.percent, color: AppColors.white, size: 14.sp),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: controller.promoCodeTextController,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textHeading,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  hintText: AppStrings.enterPromoCode.tr,
                  hintStyle: AppTextStyles.hint,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                ),
              ),
            ),
            const VerticalDivider(
              color: AppColors.divider,
              width: 1,
              thickness: 1,
            ),
            SizedBox(width: 10.w),
            TextButton(
              onPressed: controller.applyPromoCode,
              child: Text(
                AppStrings.apply.tr,
                style: AppTextStyles.button.copyWith(
                  color: AppColors.primary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCard(PromocodeModel promo, PromocodeController controller) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.inputBorderDefault.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(15.w, 17.h, 15.w, 17.h),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo.title,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 15.sp,
                          color: AppColors.black,
                          height: 20 / 15,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        promo.subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textBody,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                          height: 20 / 15,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                SvgPictureAsset(
                  AppAssets.icPromoCode,
                  width: 46.w,
                  height: 46.w,
                  placeholderBuilder: (_) => Container(
                    width: 46.w,
                    height: 46.w,
                    decoration: const BoxDecoration(
                      color: AppColors.promotionBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.percent,
                      color: AppColors.white,
                      size: 14.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 13.h),
            const Divider(color: AppColors.divider, height: 1),
            Padding(
              padding: EdgeInsets.only(top: 15.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    promo.footer,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textBody,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      height: 20 / 15,
                    ),
                  ),
                  TextButton(
                    onPressed: () => controller.applyPromo(promo),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      AppStrings.apply.tr,
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.primary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
