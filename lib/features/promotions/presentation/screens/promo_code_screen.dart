import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../../../../shared/widgets/app_skeleton_loader.dart';
import '../controllers/promo_code_controller.dart';

class PromoCodeScreen extends StatelessWidget {
  const PromoCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PromoCodeController controller = Get.find<PromoCodeController>();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          AppProfileHeader(title: AppStrings.havePromoCode.tr),
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
                  Obx(() => _buildPromoInputField(controller)),
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
                  Obx(() => _buildPromoListSection(controller)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoListSection(PromoCodeController controller) {
    if (controller.isLoading.value) {
      return Column(
        children: List.generate(
          3,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: i < 2 ? 12.h : 0),
            child: AppSkeletonLoader(height: 120.h, borderRadius: 16),
          ),
        ),
      );
    }

    final err = controller.loadError.value;
    if (err != null && err.isNotEmpty) {
      return _buildListMessage(
        message: AppStrings.failedToLoadPromoCodes.tr,
        showRetry: true,
        onRetry: controller.loadAvailablePromos,
      );
    }

    if (controller.promoCodes.isEmpty) {
      return _buildListMessage(
        message: AppStrings.noAvailablePromoCodes.tr,
        showRetry: true,
        onRetry: controller.loadAvailablePromos,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.promoCodes.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final promo = controller.promoCodes[index];
        return _buildPromoCard(promo, controller);
      },
    );
  }

  Widget _buildListMessage({
    required String message,
    required bool showRetry,
    required VoidCallback onRetry,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary.copyWith(
              fontSize: 14.sp,
              color: AppColors.textBody,
            ),
          ),
          if (showRetry) ...[
            SizedBox(height: 12.h),
            TextButton(
              onPressed: onRetry,
              child: Text(
                AppStrings.retry.tr,
                style: AppTextStyles.button.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPromoInputField(PromoCodeController controller) {
    final applying = controller.isApplying.value;
    final inlineErr = controller.applyInlineError.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: inlineErr != null && inlineErr.isNotEmpty
                  ? AppColors.error
                  : AppColors.inputBorderDefault.withValues(alpha: 0.5),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Placeholder while icPromoCode loads; matches active badge colors in AppColors.
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
                    child: Icon(
                      Icons.percent,
                      color: AppColors.white,
                      size: 14.sp,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: controller.promoCodeTextController,
                    enabled: !applying,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                      LengthLimitingTextInputFormatter(20),
                    ],
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
                  onPressed: applying ? null : controller.applyPromoCode,
                  child: Text(
                    AppStrings.apply.tr,
                    style: AppTextStyles.button.copyWith(
                      color: applying
                          ? AppColors.textMutedStrong
                          : AppColors.primary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (inlineErr != null && inlineErr.isNotEmpty) ...[
          SizedBox(height: 6.h),
          Text(
            inlineErr,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.error,
              fontSize: 12.sp,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPromoCard(PromocodeModel promo, PromoCodeController controller) {
    return Obx(() {
      final applying = controller.isApplying.value;
      final enabled = promo.isApplicable && !applying;
      final titleColor = promo.isApplicable
          ? AppColors.black
          : AppColors.textMutedStrong;
      final bodyColor = promo.isApplicable
          ? AppColors.textBody
          : AppColors.textMutedStrong;

      return Opacity(
        opacity: promo.isApplicable ? 1 : 0.55,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: promo.isApplicable
                  ? AppColors.inputBorderDefault.withValues(alpha: 0.5)
                  : AppColors.divider,
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
                              color: titleColor,
                              height: 20 / 15,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            promo.subtitle,
                            style: AppTextStyles.caption.copyWith(
                              color: bodyColor,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w500,
                              height: 20 / 15,
                            ),
                          ),
                          if (!promo.isApplicable &&
                              (promo.inapplicableHint?.isNotEmpty ??
                                  false)) ...[
                            SizedBox(height: 4.h),
                            Text(
                              promo.inapplicableHint!,
                              maxLines: 2,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.warningStrong,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // Applicable: icPromoCode + promotionBlue/white. Inapplicable: icPromoCodeDisabled
                    // + promoBadgeStarDisabled / promoBadgeAccentDisabled (same as SVG + placeholders).
                    SvgPictureAsset(
                      promo.isApplicable
                          ? AppAssets.icPromoCode
                          : AppAssets.icPromoCodeDisabled,
                      width: 46.w,
                      height: 46.w,
                      placeholderBuilder: (_) => Container(
                        width: 46.w,
                        height: 46.w,
                        decoration: BoxDecoration(
                          color: promo.isApplicable
                              ? AppColors.promotionBlue
                              : AppColors.promoBadgeStarDisabled,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.percent,
                          color: promo.isApplicable
                              ? AppColors.white
                              : AppColors.promoBadgeAccentDisabled,
                          size: 18.sp,
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
                      Expanded(
                        child: Text(
                          promo.footer.isNotEmpty ? promo.footer : promo.code,
                          style: AppTextStyles.caption.copyWith(
                            color: bodyColor,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                            height: 20 / 15,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: enabled
                            ? () => controller.applyPromo(promo)
                            : null,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          AppStrings.apply.tr,
                          style: AppTextStyles.button.copyWith(
                            color: enabled
                                ? AppColors.primary
                                : AppColors.textMutedStrong,
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
        ),
      );
    });
  }
}
