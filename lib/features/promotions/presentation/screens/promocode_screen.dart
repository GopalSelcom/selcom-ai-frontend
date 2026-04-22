import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../controllers/promocode_controller.dart';

class PromocodeScreen extends StatelessWidget {
  const PromocodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PromocodeController controller = Get.put(PromocodeController());

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Column(
        children: [
          const AppProfileHeader(title: 'Apply Promo code'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter Promocode',
                    style: AppTextStyles.bodySecondary.copyWith(
                      fontSize: 15.sp,
                      color: AppColors.shade2,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _buildPromoInputField(controller),
                  SizedBox(height: 32.h),
                  Text(
                    'Promocode list',
                    style: AppTextStyles.bodySecondary.copyWith(
                      fontSize: 15.sp,
                      color: AppColors.shade2,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Obx(
                    () => ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(),
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.promocodes.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 16.h),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.inputBorderDefault.withValues(alpha: 0.5),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Icon(
                Iconsax.ticket_discount,
                color: AppColors.info,
                size: 24.w,
              ),
            ),
            Expanded(
              child: TextField(
                controller: controller.promoCodeTextController,
                decoration: InputDecoration(
                  hintText: 'Enter promo code',
                  hintStyle: AppTextStyles.hint,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                ),
              ),
            ),
            VerticalDivider(
              color: AppColors.divider,
              width: 1,
              thickness: 1,
              indent: 12.h,
              endIndent: 12.h,
            ),
            TextButton(
              onPressed: controller.applyPromoCode,
              child: Text(
                'APPLY',
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.inputBorderDefault.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo.title,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp,
                          color: AppColors.shade1,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        promo.subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.shade2,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  Iconsax.ticket_discount,
                  color: AppColors.info,
                  size: 40.w,
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  promo.footer,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.shade2,
                    fontSize: 13.sp,
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
                    'APPLY',
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
        ],
      ),
    );
  }
}
