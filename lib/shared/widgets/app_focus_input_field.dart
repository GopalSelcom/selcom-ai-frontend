import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';

class AppFocusInputField extends StatefulWidget {
  const AppFocusInputField({
    super.key,
    this.height,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.maxLength,
    this.inputFormatters,
    this.hintText,
    this.onChanged,
    this.style,
    this.hintStyle,
    this.contentPadding,
    this.borderColor,
    this.focusedBorderColor,
  });

  final double? height;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final EdgeInsetsGeometry? contentPadding;
  final Color? borderColor;
  final Color? focusedBorderColor;

  @override
  State<AppFocusInputField> createState() => _AppFocusInputFieldState();
}

class _AppFocusInputFieldState extends State<AppFocusInputField> {
  FocusNode? _ownedFocusNode;
  late FocusNode _focusNode;
  final ValueNotifier<bool> _isFocused = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _ownedFocusNode = FocusNode();
      _focusNode = _ownedFocusNode!;
    }
    _focusNode.addListener(_onFocusChange);
    _isFocused.value = _focusNode.hasFocus;
  }

  @override
  void didUpdateWidget(covariant AppFocusInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_onFocusChange);
      if (_ownedFocusNode != null && oldWidget.focusNode == null) {
        _ownedFocusNode!.dispose();
      }
      _ownedFocusNode = null;
      if (widget.focusNode != null) {
        _focusNode = widget.focusNode!;
      } else {
        _ownedFocusNode = FocusNode();
        _focusNode = _ownedFocusNode!;
      }
      _focusNode.addListener(_onFocusChange);
      _isFocused.value = _focusNode.hasFocus;
    }
  }

  void _onFocusChange() {
    _isFocused.value = _focusNode.hasFocus;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _ownedFocusNode?.dispose();
    _isFocused.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isFocused,
      builder: (_, focused, __) {
        final Color borderColor = widget.borderColor ?? AppColors.borderDefault;
        final Color focusedBorderColor =
            widget.focusedBorderColor ?? AppColors.primary;
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(
              color: focused ? focusedBorderColor : borderColor,
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: focused
                ? const [
                    BoxShadow(
                      color: AppColors.inputFocusShadow,
                      blurRadius: 0,
                      spreadRadius: 4,
                    ),
                  ]
                : const [],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            style: widget.style,
            maxLength: widget.maxLength,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              hintText: widget.hintText,
              counterText: '',
              hintStyle: widget.hintStyle,
              border: InputBorder.none,
              contentPadding:
                  widget.contentPadding ??
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            ),
          ),
        );
      },
    );
  }
}
