import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AppOtpField extends StatelessWidget {
  final int length;
  final Function(String) onCompleted;
  final Function(String)? onChanged;
  final TextEditingController? controller;
  final bool hasError;

  const AppOtpField({
    super.key,
    this.length = 4,
    required this.onCompleted,
    this.onChanged,
    this.controller,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return PinCodeTextField(
      appContext: context,
      length: length,
      controller: controller,
      onChanged: onChanged ?? (v) {},
      onCompleted: onCompleted,
      keyboardType: TextInputType.number,
      animationType: AnimationType.fade,
      pinTheme: PinTheme(
        shape: PinCodeFieldShape.box,
        borderRadius: BorderRadius.circular(8.r),
        fieldHeight: 64.h,
        fieldWidth: 64.w,
        activeFillColor: Colors.white,
        selectedFillColor: Colors.white,
        inactiveFillColor: Colors.white,
        activeColor: hasError ? AppColors.error : AppColors.inputBorderActive,
        selectedColor: AppColors.inputBorderActive,
        inactiveColor: AppColors.inputBorderDefault,
        borderWidth: 1.w,
      ),
      cursorColor: AppColors.primary,
      animationDuration: const Duration(milliseconds: 300),
      enableActiveFill: true,
      textStyle: AppTextStyles.screenTitle,
      beforeTextPaste: (text) => true,
    );
  }
}
