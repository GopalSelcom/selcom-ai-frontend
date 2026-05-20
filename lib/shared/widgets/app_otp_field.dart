import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Keeps OTP input numeric and restarts entry after a failed verify when full.
class _OtpDigitsFormatter extends TextInputFormatter {
  _OtpDigitsFormatter({
    required this.maxLength,
    required this.isRetryActive,
    required this.onRestarted,
  });

  final int maxLength;
  final bool Function() isRetryActive;
  final VoidCallback onRestarted;

  static String _onlyDigits(String text) => text.replaceAll(RegExp(r'\D'), '');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldDigits = _onlyDigits(oldValue.text);
    var newDigits = _onlyDigits(newValue.text);

    if (newValue.text.isNotEmpty && newDigits.isEmpty) {
      return oldValue;
    }

    if (isRetryActive() &&
        oldDigits.length >= maxLength &&
        newDigits.isNotEmpty &&
        newDigits != oldDigits) {
      final insertedCount = newValue.text.length - oldValue.text.length;
      final isLikelyPaste = insertedCount > 1 || newDigits.length > maxLength;

      if (isLikelyPaste) {
        if (newDigits.length > maxLength) {
          newDigits = newDigits.substring(0, maxLength);
        }
      } else {
        newDigits = newDigits.substring(newDigits.length - 1);
      }
      onRestarted();
    }

    if (newDigits.length > maxLength) {
      newDigits = newDigits.substring(0, maxLength);
    }

    return TextEditingValue(
      text: newDigits,
      selection: TextSelection.collapsed(offset: newDigits.length),
    );
  }
}

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
  late final TextEditingController _controller;
  late final bool _ownsController;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  int _filledLength = 0;
  bool _retryOnNextInput = false;
  late final _OtpDigitsFormatter _digitsFormatter;

  TextEditingController get _effectiveController =>
      widget.controller ?? _controller;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _digitsFormatter = _OtpDigitsFormatter(
      maxLength: widget.length,
      isRetryActive: () => _retryOnNextInput && widget.hasError,
      onRestarted: () => _retryOnNextInput = false,
    );
    _focusNode.addListener(_onFocusChanged);
    _effectiveController.addListener(_onControllerChanged);
    _filledLength = _onlyDigits(_effectiveController.text).length;
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
  }

  @override
  void didUpdateWidget(AppOtpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      widget.controller?.addListener(_onControllerChanged);
      _filledLength = _onlyDigits(_effectiveController.text).length;
    }

    if (widget.hasError && _filledLength >= widget.length) {
      _retryOnNextInput = true;
    } else if (oldWidget.hasError && !widget.hasError) {
      _retryOnNextInput = false;
    }
  }

  void _onFocusChanged() {
    final focused = _focusNode.hasFocus;
    if (_isFocused != focused) {
      setState(() => _isFocused = focused);
    }
  }

  void _onControllerChanged() {
    final len = _onlyDigits(_effectiveController.text).length;
    if (_filledLength != len) {
      setState(() => _filledLength = len);
    }
  }

  String _onlyDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  void _restartWithDigit(String digit) {
    _retryOnNextInput = false;
    _effectiveController.value = TextEditingValue(
      text: digit,
      selection: const TextSelection.collapsed(offset: 1),
    );
    setState(() => _filledLength = 1);
    widget.onChanged?.call(digit);
  }

  bool _handleHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (!_focusNode.hasFocus) return false;
    if (!_retryOnNextInput || !widget.hasError) return false;
    if (_filledLength < widget.length) return false;

    final char = event.character;
    if (char != null && RegExp(r'^\d$').hasMatch(char)) {
      _restartWithDigit(char);
      return true;
    }
    return false;
  }

  void _handleChanged(String value) {
    final digits = _onlyDigits(value);
    final len = digits.length;
    if (_filledLength != len) {
      setState(() => _filledLength = len);
    }
    if (digits != value) {
      widget.onChanged?.call(digits);
      return;
    }
    widget.onChanged?.call(digits);
  }

  bool _beforeTextPaste(String? text) {
    if (text == null) return false;
    return _onlyDigits(text).isNotEmpty;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    _effectiveController.removeListener(_onControllerChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
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
            controller: _effectiveController,
            focusNode: _focusNode,
            autoDisposeControllers: false,
            onChanged: _handleChanged,
            onCompleted: widget.onCompleted,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _digitsFormatter,
            ],
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
            beforeTextPaste: _beforeTextPaste,
          ),
        ],
      ),
    );
  }
}
