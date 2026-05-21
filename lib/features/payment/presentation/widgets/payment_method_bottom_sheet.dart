import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/data/models/user_profile_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/payment_method_controller.dart';

/// Payment method picker body for [AppDialogs.showStandardBottomSheet].
class PaymentMethodBottomSheet extends StatelessWidget {
  const PaymentMethodBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PaymentMethodController>();
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Obx(() {
      if (controller.isLoading.value && controller.paymentMethods.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 32.h),
          child: const Center(child: CircularProgressIndicator()),
        );
      }

      final methods = controller.paymentMethods;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < methods.length; i++) ...[
            if (i > 0) SizedBox(height: 12.h),
            _PaymentMethodTile(
              method: methods[i],
              isSelected: controller.selectedPayment.value?.id == methods[i].id,
              onTap: () {
                controller.selectPaymentMethod(methods[i]);
                Get.back();
              },
              walletBalance: methods[i].type == 'wallet'
                  ? controller.walletBalance.value
                  : null,
              enabled: methods[i].isAvailable,
            ),
          ],
          SizedBox(height: bottomPadding > 0 ? 4.h : 16.h),
        ],
      );
    });
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.method,
    required this.isSelected,
    required this.onTap,
    required this.enabled,
    this.walletBalance,
  });

  final PaymentMethodModel method;
  final bool isSelected;
  final VoidCallback onTap;
  final bool enabled;
  final WalletBalanceModel? walletBalance;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: IgnorePointer(
        ignoring: !enabled,
        child: InkWell(
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
        ),
      ),
    );
  }
}
