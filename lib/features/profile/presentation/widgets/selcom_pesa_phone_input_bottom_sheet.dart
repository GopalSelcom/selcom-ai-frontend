import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';
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
          SizedBox(height: 24.h),

          Text(
            AppStrings.enterYourSelcomPesaNumber.tr,
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textHeading,
              height: 34 / 20,
              letterSpacing: -0.4,
            ),
          ),
          Divider(color: AppColors.divider, thickness: 1, height: 35.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppStrings.enterPhoneNumber.tr,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textBody,
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
              maxLength: 11,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                TanzaniaPhoneFormatter(),
              ],
              prefixIcon: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Text(
                  AppStrings.value255.tr,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              onChanged: controller.onSelcomPhoneChanged,
            ),
          ),

          SizedBox(height: 48.h),

          // Continue Button (visible only when TZ number is complete enough to submit)
          Obx(
            () => Padding(
              padding: EdgeInsets.only(
                bottom: controller.canContinueSelcomPhone.value ? 16.h : 0,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axis: Axis.vertical,
                    child: child,
                  ),
                ),
                child: controller.canContinueSelcomPhone.value
                    ? AppPrimaryButton(
                        key: const ValueKey('selcom-pesa-continue-visible'),
                        label: AppStrings.continueLabel.tr,
                        onPressed: controller.onPhoneContinue,
                      )
                    : const SizedBox.shrink(
                        key: ValueKey('selcom-pesa-continue-hidden'),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
