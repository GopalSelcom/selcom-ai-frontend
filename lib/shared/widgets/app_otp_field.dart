import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AppOtpField extends StatefulWidget {
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
  State<AppOtpField> createState() => _AppOtpFieldState();
}

class _AppOtpFieldState extends State<AppOtpField> {
  final FocusNode _focusNode = FocusNode();
  final ValueNotifier<bool> _isFocused = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    _isFocused.value = _focusNode.hasFocus;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _isFocused.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.fieldHeight ?? 64.h;
    final w = widget.fieldWidth ?? 64.w;
    final borderColor = widget.hasError
        ? AppColors.otpErrorBorder
        : AppColors.primary;
    final glowColor = widget.hasError
        ? AppColors.otpErrorShadow
        : AppColors.inputFocusShadow;

    return ValueListenableBuilder<bool>(
      valueListenable: _isFocused,
      builder: (_, isFocused, __) {
        return SizedBox(
          height: h,
          child: Stack(
            alignment: Alignment.center,
            children: [
              IgnorePointer(
                child: Row(
                  mainAxisAlignment: widget.mainAxisAlignment,
                  children: List.generate(
                    widget.length,
                    (_) => Container(
                      width: w,
                      height: h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18.r),
                        boxShadow: (isFocused || widget.hasError)
                            ? [
                                BoxShadow(
                                  color: glowColor,
                                  blurRadius: 0,
                                  spreadRadius: 4,
                                ),
                              ]
                            : const [],
                      ),
                    ),
                  ),
                ),
              ),
              PinCodeTextField(
                appContext: context,
                length: widget.length,
                controller: widget.controller,
                focusNode: _focusNode,
                onChanged: widget.onChanged ?? (v) {},
                onCompleted: widget.onCompleted,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                mainAxisAlignment: widget.mainAxisAlignment,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(16.r),
                  fieldHeight: h,
                  fieldWidth: w,
                  activeFillColor: AppColors.white,
                  selectedFillColor: AppColors.white,
                  inactiveFillColor: AppColors.white,
                  activeColor: borderColor,
                  selectedColor: borderColor,
                  inactiveColor: borderColor,
                  borderWidth: 1.2.w,
                ),
                cursorColor: AppColors.primary,
                animationDuration: const Duration(milliseconds: 300),
                enableActiveFill: true,
                textStyle: widget.textStyle ?? AppTextStyles.screenTitle,
                beforeTextPaste: (text) => true,
              ),
            ],
          ),
        );
      },
    );
  }
}
