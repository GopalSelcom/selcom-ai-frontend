import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../controllers/payment_methods_controller.dart';

class SelcomPesaConnectBottomSheet extends GetView<PaymentMethodsController> {
  const SelcomPesaConnectBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36.r)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 64.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: AppColors.dividerHandle,
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
          ),
          SizedBox(height: 13.h),

          Text(
            AppStrings.stepsToConnectSelcomPesa.tr,
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textHeading,
              height: 34 / 20,
              letterSpacing: -0.4,
            ),
          ),

          Divider(height: 34.h, color: AppColors.divider, thickness: 1),

          // Stepper
          _buildStepper(),

          SizedBox(height: 17.h),

          // Info Banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.bgRequestMoney,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              AppStrings
                  .youCanStillAbleToRequestMoneyOnSelcomPesaUsingAnotherNumber
                  .tr,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w500,
                fontSize: 15.sp,
                height: 20 / 15,
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // Continue Button
          AppPrimaryButton(
            label: AppStrings.continueLabel.tr,
            onPressed: controller.openPhoneInput,
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Column(
      children: [
        _StepperItem(
          step: '1',
          description: AppStrings.selcomPesaConnectStep1.tr,
          isLast: false,
        ),
        _StepperItem(
          step: '2',
          description: AppStrings.selcomPesaConnectStep2.tr,
          isLast: false,
        ),
        _StepperItem(
          step: '3',
          description: AppStrings.selcomPesaConnectStep3.tr,
          isLast: false,
        ),
        _StepperItem(
          step: '4',
          description: AppStrings.selcomPesaConnectStep4.tr,
          isLast: true,
        ),
      ],
    );
  }
}

class _StepperItem extends StatelessWidget {
  final String step;
  final String description;
  final bool isLast;

  const _StepperItem({
    required this.step,
    required this.description,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.borderWalletCard,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    step,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textHeading,
                      fontSize: 15.sp,
                      height: 20 / 15,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 10.w,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      border: Border.symmetric(
                        vertical: BorderSide(
                          color: AppColors.borderWalletCard,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 2.h),
                Text(
                  description,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textBody,
                    fontSize: 15.sp,
                    height: 1.4,
                  ),
                ),
                if (!isLast) SizedBox(height: 32.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
