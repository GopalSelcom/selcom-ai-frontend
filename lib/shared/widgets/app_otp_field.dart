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
  bool _isFocused = false;
  int _filledLength = 0;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    widget.controller?.addListener(_onExternalControllerChanged);
    _filledLength = widget.controller?.text.length ?? 0;
  }

  @override
  void didUpdateWidget(AppOtpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onExternalControllerChanged);
      widget.controller?.addListener(_onExternalControllerChanged);
      _filledLength = widget.controller?.text.length ?? 0;
    }
  }

  void _onFocusChanged() {
    final focused = _focusNode.hasFocus;
    if (_isFocused != focused) {
      setState(() => _isFocused = focused);
    }
  }

  void _onExternalControllerChanged() {
    final len = widget.controller?.text.length ?? 0;
    if (_filledLength != len) {
      setState(() => _filledLength = len);
    }
  }

  void _handleChanged(String value) {
    final len = value.length;
    if (_filledLength != len) {
      setState(() => _filledLength = len);
    }
    widget.onChanged?.call(value);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onExternalControllerChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.fieldHeight ?? 64.h;
    final w = widget.fieldWidth ?? 64.w;
    const greyBorder = AppColors.borderDefault;
    final glowColor = widget.hasError
        ? AppColors.otpErrorShadow
        : AppColors.inputFocusShadow;

    final isComplete = !widget.hasError && _filledLength >= widget.length;
    final activeCellIndex = _filledLength < widget.length
        ? _filledLength
        : widget.length - 1;

    late final Color activeBorder;
    late final Color selectedBorder;
    late final Color inactiveBorder;
    if (widget.hasError) {
      activeBorder = selectedBorder = inactiveBorder = AppColors.otpErrorBorder;
    } else if (isComplete) {
      activeBorder = selectedBorder = inactiveBorder = AppColors.primary;
    } else if (_isFocused) {
      activeBorder = AppColors.primary;
      selectedBorder = AppColors.primary;
      inactiveBorder = AppColors.primary;
    } else {
      activeBorder = selectedBorder = inactiveBorder = greyBorder;
    }

    bool cellGlowsAt(int index) {
      if (widget.hasError) return true;
      return _isFocused && !isComplete && index == activeCellIndex;
    }

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
                (index) => Container(
                  width: w,
                  height: h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18.r),
                    boxShadow: cellGlowsAt(index)
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
            onChanged: _handleChanged,
            onCompleted: widget.onCompleted,
            keyboardType: TextInputType.number,
            animationType: AnimationType.fade,
            mainAxisAlignment: widget.mainAxisAlignment,
            showCursor: false,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(16.r),
              fieldHeight: h,
              fieldWidth: w,
              activeFillColor: AppColors.white,
              selectedFillColor: AppColors.white,
              inactiveFillColor: AppColors.white,
              activeColor: activeBorder,
              selectedColor: selectedBorder,
              inactiveColor: inactiveBorder,
              borderWidth: 1.2.w,
            ),
            animationDuration: const Duration(milliseconds: 300),
            enableActiveFill: true,
            textStyle: widget.textStyle ?? AppTextStyles.screenTitle,
            beforeTextPaste: (text) => true,
          ),
        ],
      ),
    );
  }
}
