import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selcom_rides_frontend/core/theme/app_colors.dart';
import 'package:selcom_rides_frontend/core/theme/app_text_styles.dart';

class CommonInputField extends StatelessWidget {
  final TextEditingController controller;
  final TextInputType keyboardType;
  final TextAlign textAlign;
  final TextInputAction textInputAction;
  final Color? textColor;

  final String? hintText;
  final double? fontSize;
  final Color? hintColor;
  final bool isAllowDecimal;
  final FocusNode? customRequestFocus;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final Function(String)? onChange;
  final int? maxLength;
  final bool isTransparent;
  final bool enable;
  final TextCapitalization? textCapitalization;
  final Function? onTap;

  const CommonInputField({
    super.key,
    required this.controller,
    this.keyboardType = TextInputType.name,
    this.textAlign = TextAlign.start,
    this.textInputAction = TextInputAction.next,
    this.textColor,
    required this.hintText,
    this.fontSize,
    this.hintColor,
    this.isAllowDecimal = false,
    this.focusNode,
    this.customRequestFocus,
    this.inputFormatters,
    this.onChange,
    this.maxLength,
    this.isTransparent = false,
    this.textCapitalization,
    this.enable = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap?.call();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.0.sp, vertical: 3.0.sp),
        decoration: BoxDecoration(
          color: isTransparent
              ? Colors.transparent
              : AppColors.boxGray,
          border: Border.all(
            color: isTransparent
                ? Colors.transparent
                : AppColors.borderColor,
            // border color
            width: 0.5, // border width
          ),
          borderRadius: BorderRadius.circular(12.sp),
        ),
        child: TextFormField(
          contextMenuBuilder:
              (BuildContext context, EditableTextState editableTextState) {
                // If supported, show the system context menu.
                if (SystemContextMenu.isSupported(context)) {
                  return SystemContextMenu.editableText(
                    editableTextState: editableTextState,
                  );
                }
                return AdaptiveTextSelectionToolbar.editable(
                  anchors: editableTextState.contextMenuAnchors,
                  clipboardStatus: ClipboardStatus.pasteable,
                  onCopy: () => editableTextState.copySelection(
                    SelectionChangedCause.toolbar,
                  ),
                  onCut: () => editableTextState.cutSelection(
                    SelectionChangedCause.toolbar,
                  ),
                  onPaste: () => editableTextState.pasteText(
                    SelectionChangedCause.toolbar,
                  ),
                  onSelectAll: () => editableTextState.selectAll(
                    SelectionChangedCause.toolbar,
                  ),
                  onLookUp: () {},
                  onSearchWeb: () {},
                  onShare: () {},
                  onLiveTextInput: () {},
                );
              },
          controller: controller,
          keyboardType:
              keyboardType /*TextInputType.numberWithOptions(decimal: isAllowDecimal)*/,
          autofocus: false,
          enabled: enable,
          textAlign: TextAlign.start,
          minLines: 1,
          maxLines: 1,
          maxLength: maxLength,
          textCapitalization:
              textCapitalization ?? TextCapitalization.sentences,
          cursorColor: AppColors.greyColor242E49,
          focusNode: focusNode,
          inputFormatters:
              inputFormatters /* [DecimalFormatter(decimalDigits: 2)]*/,
          textInputAction: textInputAction,
          onFieldSubmitted: (value) {
            FocusScope.of(context).requestFocus(customRequestFocus);
          },
          decoration: InputDecoration(
            hintText: hintText,
            border: InputBorder.none,
            counterText: "",
            contentPadding: EdgeInsets.only(left: 3.sp, right: 3.sp),
            hintStyle: AppTextStyles.screenTitle.copyWith(
              color: hintColor ?? AppColors.textGrayAskleois,
              fontSize: fontSize ?? 14.sp,
            ),
          ),
          style: AppTextStyles.screenTitle.copyWith(
            color: textColor ?? AppColors.textGrayAskleois,
            fontSize: fontSize ?? 14.sp,
          ),
          onChanged: (value) {
            onChange?.call(value);
          },
        ),
      ),
    );
  }
}
