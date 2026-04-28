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
  final double? fieldHeight;
  final double? fieldWidth;
  final TextStyle? textStyle;
  final MainAxisAlignment mainAxisAlignment;

  const AppOtpField({
    super.key,
    this.length = 4,
    required this.onCompleted,
    this.onChanged,
    this.controller,
    this.hasError = false,
    this.fieldHeight,
    this.fieldWidth,
    this.textStyle,
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
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
      mainAxisAlignment: mainAxisAlignment,
      pinTheme: PinTheme(
        shape: PinCodeFieldShape.box,
        borderRadius: BorderRadius.circular(16.r),
        fieldHeight: fieldHeight ?? 64.h,
        fieldWidth: fieldWidth ?? 64.w,
        activeFillColor: AppColors.white,
        selectedFillColor: AppColors.white,
        inactiveFillColor: AppColors.white,
        activeColor: hasError ? AppColors.error : AppColors.inputBorderActive,
        selectedColor: hasError ? AppColors.error : AppColors.inputBorderActive,
        inactiveColor: hasError ? AppColors.error : AppColors.inputBorderDefault,
        borderWidth: 1.w,
      ),
      cursorColor: AppColors.inputBorderActive,
      animationDuration: const Duration(milliseconds: 300),
      enableActiveFill: true,
      textStyle: textStyle ?? AppTextStyles.screenTitle,
      beforeTextPaste: (text) => true,
    );
  }
}
