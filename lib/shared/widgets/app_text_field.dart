import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';

class AppTextField extends StatefulWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool isPassword;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Function(String)? onChanged;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final bool showCounter;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;

  const AppTextField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.keyboardType,
    this.isPassword = false,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.showCounter = false,
    this.inputFormatters,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.readOnly = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
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
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_handleFocusChange);
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
      _focusNode.addListener(_handleFocusChange);
      _isFocused.value = _focusNode.hasFocus;
    }
  }

  void _handleFocusChange() {
    _isFocused.value = _focusNode.hasFocus;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _ownedFocusNode?.dispose();
    _isFocused.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = (widget.errorText ?? '').trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: AppTextStyles.cardTitle),
          SizedBox(height: 8.h),
        ],
        ValueListenableBuilder<bool>(
          valueListenable: _isFocused,
          builder: (_, focused, __) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.input),
                boxShadow: focused && !hasError
                    ? const [
                        BoxShadow(
                          color: Color(0x400F67FE),
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
                textInputAction: widget.textInputAction,
                obscureText: widget.isPassword,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                readOnly: widget.readOnly,
                enabled: widget.enabled,
                maxLines: widget.maxLines,
                maxLength: widget.maxLength,
                autofocus: widget.autofocus,
                inputFormatters: widget.inputFormatters,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: AppTextStyles.hint,
                  errorText: widget.errorText,
                  prefixIcon: widget.prefixIcon,
                  suffixIcon: widget.suffixIcon,
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 18.h,
                  ),
                  counterText: "",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: const BorderSide(color: AppColors.inputBorderDefault),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: const BorderSide(color: AppColors.inputBorderDefault),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: const BorderSide(color: AppColors.inputBorderActive),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: const BorderSide(color: AppColors.inputBorderError),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: const BorderSide(color: AppColors.inputBorderError),
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.showCounter &&
            widget.maxLength != null &&
            widget.controller != null) ...[
          SizedBox(height: 6.h),
          Align(
            alignment: Alignment.centerRight,
            child: ValueListenableBuilder(
              valueListenable: widget.controller!,
              builder: (context, TextEditingValue value, _) {
                final length = value.text.length;
                return Text(
                  '$length/${widget.maxLength}',
                  style: AppTextStyles.bodySecondary.copyWith(
                    fontSize: 12.sp,
                    color: length >= widget.maxLength!
                        ? AppColors.textError
                        : AppColors.borderInputMuted,
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
