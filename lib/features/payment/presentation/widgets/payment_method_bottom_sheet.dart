import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/data/models/user_profile_models.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../controllers/payment_method_controller.dart';

/// Payment method picker body for [AppDialogs.showStandardBottomSheet].
class PaymentMethodBottomSheet extends StatelessWidget {
  const PaymentMethodBottomSheet({super.key});

  /// Opens the sheet via [AppDialogs.showStandardBottomSheet] (centered title).
  static Future<void> show() {
    return AppDialogs.showStandardBottomSheet<void>(
      title: AppStrings.selectAPaymentMethod.tr,
      content: const PaymentMethodBottomSheet(),
      barrierDismissible: true,
      headerTextAlign: TextAlign.center,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PaymentMethodController>();
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final computedBottomPadding = bottomPadding > 0
        ? (GetPlatform.isIOS
            ? (bottomPadding - 12.h).clamp(
                10.h > bottomPadding ? bottomPadding : 10.h,
                bottomPadding,
              )
            : bottomPadding + 12.h)
        : 12.h;

    return Obx(() {
      if (controller.isLoading.value &&
          controller.paymentMethods.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.paymentMethods.length,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final method = controller.paymentMethods[index];
              final isSelected =
                  controller.selectedPayment.value?.id == method.id;
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
          ),
          SizedBox(height: computedBottomPadding),
        ],
      );
    });
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
