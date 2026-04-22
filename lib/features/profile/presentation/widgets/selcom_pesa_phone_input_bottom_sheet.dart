import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/phone_formatter.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/payment_methods_controller.dart';

class SelcomPesaPhoneInputBottomSheet
    extends GetView<PaymentMethodsController> {
  const SelcomPesaPhoneInputBottomSheet({super.key});

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
            'Enter your Selcom Pesa Number',
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.shade1,
            ),
          ),
          SizedBox(height: 12.h),
          const Divider(color: AppColors.divider, thickness: 1),
          SizedBox(height: 24.h),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Enter Phone number',
              style: AppTextStyles.body.copyWith(
                color: AppColors.shade2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: 8.h),

          Obx(
            () => AppTextField(
              controller: controller.selcomPhoneController,
              keyboardType: TextInputType.phone,
              autofocus: true,
              errorText: controller.phoneError.value.isEmpty
                  ? null
                  : controller.phoneError.value,
              maxLength: 12,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
                TanzaniaPhoneFormatter(),
              ],
              prefixIcon: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Text(
                  '+255',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.shade1,
                  ),
                ),
              ),
              onChanged: (v) {
                if (controller.phoneError.isNotEmpty) {
                  controller.phoneError.value = '';
                }
              },
            ),
          ),

          SizedBox(height: 48.h),

          // Continue Button
          AppPrimaryButton(
            label: 'Continue',
            onPressed: controller.onPhoneContinue,
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
