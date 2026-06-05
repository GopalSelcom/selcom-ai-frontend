import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/theme/app_colors.dart';


class CheckboxWithText extends StatefulWidget {
  final bool value;
  final Function()? onTap;
  final String? text;
  final String? spannedText;
  final Color? textColor;
  final Color? checkBoxColor;
  final double? textSize;
  final double? leftPadding;
  final double? rightPadding;
  final bool isSwitchVisible;

  const CheckboxWithText({
    super.key,
    this.value = false,
    this.text,
    this.textSize,
    this.leftPadding,
    this.rightPadding,
    this.onTap,
    this.spannedText,
    this.textColor,
    this.checkBoxColor,
    this.isSwitchVisible = false,
  });

  @override
  State<CheckboxWithText> createState() => _CheckboxWithTextState();
}

class _CheckboxWithTextState extends State<CheckboxWithText> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // Haptics.instance.selectionClick();
        widget.onTap!();
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          left: (widget.leftPadding ?? 0),
          right: (widget.rightPadding ?? 0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            if (widget.isSwitchVisible == false)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (widget.value)
                        ? AppColors.greenColor
                        : widget.checkBoxColor ??
                              AppColors.lightThemeLightGreyTextColor,
                  ),
                  color: (widget.value)
                      ? AppColors.greenColor
                      : widget.checkBoxColor ?? AppColors.whiteColor,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Icon(
                    Icons.check_rounded,
                    color: (widget.value)
                        ? AppColors.whiteColor
                        : Colors.transparent,
                    size: 20,
                  ),
                ),
              ),
            widget.isSwitchVisible == true
                ? Container()
                : const SizedBox(width: 10),
            widget.isSwitchVisible == true
                ? FittedBox(
                    child: Text(
                      widget.text ?? "",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: widget.textColor,
                        fontSize: widget.textSize,
                        overflow: TextOverflow.ellipsis,
                        // fontFamily: FontName.NunitoSansRegular,
                      ),
                    ),
                  )
                : Flexible(
                    child: RichText(
                      text: TextSpan(
                        text: widget.text,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: (widget.value == true)
                              ? AppColors.greenColor
                              : widget.textColor,
                          fontSize: widget.textSize,
                          // fontFamily: FontName.NunitoSansRegular,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: widget.spannedText,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 10.0.sp,
                                  // fontFamily: FontName.NunitoSansRegular,

                                  // decoration: TextDecoration.underline,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
            if (widget.isSwitchVisible == true) const Spacer(),
            if (widget.isSwitchVisible == true)
              CupertinoSwitch(
                value: widget.value,
                onChanged: (value) {
                  widget.onTap?.call();
                },
              ),
          ],
        ),
      ),
    );
  }
}
