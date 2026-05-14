import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 10.h),
            Center(
              child: Container(
                width: 56.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: AppColors.borderNeutralStrong.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(999.r),
                ),
              ),
            ),
            SizedBox(height: 18.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Text(
                AppStrings.selectAPaymentMethod.tr,
                style: AppTextStyles.homeTitle.copyWith(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHeading,
                  height: 34 / 20,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 14.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Divider(
                color: AppColors.bgSoftCircle,
                thickness: 1.h,
                height: 1.h,
              ),
            ),
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
                padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 6.h),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.paymentMethods.length,
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final method = controller.paymentMethods[index];
                  final isSelected =
                      controller.selectedPayment.value?.id == method.id;
                  // Backend `is_available: false` — show row but block taps and
                  // grey it out so the user knows the method exists but cannot pick it.
                  final enabled = method.isAvailable;
                  return Opacity(
                    opacity: enabled ? 1 : 0.45,
                    child: IgnorePointer(
                      ignoring: !enabled,
                      child: _PaymentMethodTile(
                        method: method,
                        isSelected: isSelected,
                        onTap: () {
                          controller.selectPaymentMethod(method);
                          Get.back();
                        },
                        walletBalance: method.type == 'wallet'
                            ? controller.walletBalance.value
                            : null,
                      ),
                    ),
                  );
                },
              );
            }),
            SizedBox(height: 18.h),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        height: 56.h,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        decoration: BoxDecoration(
          color: AppColors.bgVerificationSurface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.28)
                : AppColors.transparent,
            width: 1.w,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                method.label,
                style: AppTextStyles.homeSubtitle.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textHeading,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            if (walletBalance != null) ...[
              SizedBox(width: 12.w),
              Text(
                '${walletBalance!.currency} ${walletBalance!.balance}',
                style: AppTextStyles.homeSubtitle.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
            SizedBox(width: 12.w),
            Icon(
              Icons.chevron_right,
              color: AppColors.textHeading,
              size: 26.sp,
            ),
          ],
        ),
      ),
    );
  }
}
