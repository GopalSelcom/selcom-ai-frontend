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
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
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
          SizedBox(height: 24.h),

          Text(
            AppStrings.stepsToConnectSelcomPesa.tr,
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeading,
            ),
          ),
          SizedBox(height: 32.h),

          // Stepper
          _buildStepper(),

          SizedBox(height: 32.h),

          // Info Banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.bgSuccessBanner,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              AppStrings
                  .youCanStillAbleToRequestMoneyOnSelcomPesaUsingAnotherNumber
                  .tr,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // Continue Button
          AppPrimaryButton(
            label: 'Continue',
            onPressed: controller.openPhoneInput,
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return const Column(
      children: [
        _StepperItem(
          step: '1',
          description: 'Enter your Selcom Pesa registered phone number',
          isLast: false,
        ),
        _StepperItem(
          step: '2',
          description:
              'Verify the selfie associated with your Selcom Pesa account.',
          isLast: false,
        ),
        _StepperItem(
          step: '3',
          description:
              'Check your Selcom Pesa app and approve the verification request.',
          isLast: false,
        ),
        _StepperItem(
          step: '4',
          description: "You're all set! Your Selcom Pesa account is connected.",
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
                  border: Border.all(color: AppColors.borderWalletCard, width: 1),
                ),
                child: Center(
                  child: Text(
                    step,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeading,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2.w, color: AppColors.borderWalletCard),
                ),
            ],
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10.h),
                Text(
                  description,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textBody,
                    fontSize: 15.sp,
                    height: 1.4,
                  ),
                ),
                if (!isLast) SizedBox(height: 24.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
