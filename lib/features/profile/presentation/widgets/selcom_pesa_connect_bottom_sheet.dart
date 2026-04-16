import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_primary_button.dart';

class SelcomPesaConnectBottomSheet extends StatelessWidget {
  const SelcomPesaConnectBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
          ),
          SizedBox(height: 24.h),

          Text(
            'Steps to Connect Selcom Pesa',
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.shade1,
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
              color: const Color(0xFFEAF9F1), // Light green
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              'You can still able to request money on Selcom Pesa using another number.',
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFF1D9E75), // Success green
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // Continue Button
          AppPrimaryButton(label: 'Continue', onPressed: () => Get.back()),
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
                  color: const Color(0xFFF8F9FD),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE6E9EE), width: 1),
                ),
                child: Center(
                  child: Text(
                    step,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.shade1,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2.w, color: const Color(0xFFE6E9EE)),
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
                    color: AppColors.shade2,
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
