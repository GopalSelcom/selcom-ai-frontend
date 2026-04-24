import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../core/data/models/user_profile_models.dart';
import '../controllers/payment_method_controller.dart';

class PaymentMethodBottomSheet extends StatelessWidget {
  const PaymentMethodBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PaymentMethodController>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 12.h),
            Center(
              child: Container(
                width: 48.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.skeletonBase,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Text(
                AppStrings.selectAPaymentMethod.tr,
                style: AppTextStyles.homeTitle.copyWith(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHeading,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Divider(color: AppColors.bgSoftCircle, thickness: 1.h),
            Obx(() {
              if (controller.isLoading.value &&
                  controller.paymentMethods.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.all(24.w),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.paymentMethods.length,
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final method = controller.paymentMethods[index];
                  final isSelected =
                      controller.selectedPayment.value?.id == method.id;
                  return _PaymentMethodTile(
                    method: method,
                    isSelected: isSelected,
                    onTap: () {
                      controller.selectPaymentMethod(method);
                      Get.back();
                    },
                    walletBalance: method.type == 'wallet'
                        ? controller.walletBalance.value
                        : null,
                  );
                },
              );
            }),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final PaymentMethodModel method;
  final bool isSelected;
  final VoidCallback onTap;
  final WalletBalanceModel? walletBalance;

  const _PaymentMethodTile({
    required this.method,
    required this.isSelected,
    required this.onTap,
    this.walletBalance,
  });

  @override
  Widget build(BuildContext context) {
    String asset = AppAssets.icPaymentCard;
    if (method.type == 'wallet') asset = AppAssets.icPaymentWallet;
    if (method.type == 'selcom_pesa') asset = AppAssets.icPaymentSelcomPesa;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.transparent,
            width: 1.5.w,
          ),
        ),
        child: Row(
          children: [
            SvgPictureAsset(
              asset,
              width: 24.w,
              height: 24.w,
              color: AppColors.textHeading,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.label,
                    style: AppTextStyles.homeSubtitle.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textHeading,
                    ),
                  ),
                  if (walletBalance != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      '${walletBalance!.currency} ${walletBalance!.balance}',
                      style: AppTextStyles.homeCaption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primary, size: 20.sp),
          ],
        ),
      ),
    );
  }
}
