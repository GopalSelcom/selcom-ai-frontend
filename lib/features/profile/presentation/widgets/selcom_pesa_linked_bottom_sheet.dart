import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_assets.dart';
import '../controllers/payment_methods_controller.dart';

class SelcomPesaLinkedBottomSheet extends GetView<PaymentMethodsController> {
  const SelcomPesaLinkedBottomSheet({super.key});

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
            'Your Linked Account',
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.shade1,
            ),
          ),
          SizedBox(height: 12.h),
          const Divider(color: AppColors.divider, thickness: 1),
          SizedBox(height: 24.h),

          _buildReadOnlyField(label: 'Name', value: 'Chirag panchal'),
          SizedBox(height: 20.h),

          _buildReadOnlyField(label: 'Phone number', value: '+255 711 410 410'),
          SizedBox(height: 24.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                AppAssets.icAccountVerified,
                width: 24.w,
                height: 24.w,
              ),
              SizedBox(width: 12.w),
              Text(
                'Account Verified',
                style: AppTextStyles.body.copyWith(
                  color: const Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),

          SizedBox(height: 48.h),

          // Remove Account Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: controller.unlinkAccount,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(
                'Remove Account',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: AppColors.shade2,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FD),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFE6E9EE)),
          ),
          child: Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.shade1,
            ),
          ),
        ),
      ],
    );
  }
}
