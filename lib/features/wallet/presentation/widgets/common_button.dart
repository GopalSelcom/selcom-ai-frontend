import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../utils/media_viewer.dart';
import '../utils/safe_spacing.dart';
import 'pressable.dart';



class CommonButton extends StatefulWidget {
  final double? height;
  final double? width;
  final Color? borderColor;
  final String label;
  final bool? isEnabled;
  final TextStyle? labelTextStyle;
  final Function onTap;
  final Color? enabledColor;
  final Color? disabledColor;
  final double? borderRadius;
  final bool centerText;
  final String? leftIcon;
  final String? rightIcon;
  final double? spaceFromLeft;
  final double? spaceFromRight;
  final Color? iconColor;
  final bool isButtonAnimationEnable;
  final double? iconSize;
  final double? bottomSpace;

  const CommonButton({
    super.key,
    required this.label,
    required this.onTap,
    this.labelTextStyle,
    this.height,
    this.width,
    this.borderColor,
    this.isEnabled,
    this.disabledColor,
    this.enabledColor,
    this.centerText = false,
    this.borderRadius,
    this.leftIcon,
    this.rightIcon,
    this.spaceFromLeft,
    this.spaceFromRight,
    this.iconColor,
    this.iconSize,
    this.bottomSpace,
    this.isButtonAnimationEnable = false,
  });

  @override
  State<CommonButton> createState() => _CommonButtonState();
}

class _CommonButtonState extends State<CommonButton> {
  bool isButtonPressed = false;

  @override
  Widget build(BuildContext context) {
    final bottomSpacing = (widget.bottomSpace ?? SafeSpacing.bottom);
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child:
          Pressable(
                onTap: () {
                  if (widget.isEnabled ?? false) {
                    widget.onTap();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: widget.height ?? 56.0.sp,
                  width: widget.width ?? (Get.width * 0.9),
                  decoration: BoxDecoration(
                    color: widget.isButtonAnimationEnable
                        ? widget.enabledColor ??AppColors.primary
                        : (widget.isEnabled ?? false)
                        ? widget.enabledColor ??AppColors.primary
                        : widget.disabledColor ??
                             AppColors.lightGreyTextColor,
                    borderRadius: BorderRadius.circular(
                      widget.borderRadius ?? 15.0.sp,
                    ),
                    border: Border.all(
                      color: widget.borderColor ?? Colors.transparent,
                    ),
                  ),
                  child: (widget.centerText)
                      ? Center(
                          child: Text(
                            widget.label,
                            style:
                                widget.labelTextStyle ??
                                Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color:AppColors.white,
                                  // fontFamily: Fonts.plusJakartaSansBold,
                                  fontSize: 15.0.sp,
                                ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (widget.leftIcon != null)
                              MediaViewer(path: widget.leftIcon!,
                                color:
                                    widget.iconColor ??
                                   AppColors.white,
                                height: widget.iconSize ?? 25.0.sp,
                              ),
                            //
                            // Image.asset(
                            //   widget.leftIcon!,
                            //   color: widget.iconColor ?? AppColors.whiteColor,
                            //   height: widget.iconSize ?? 20.0.sp,
                            // ),
                            if (widget.leftIcon != null)
                              SizedBox(width: widget.spaceFromLeft ?? 10.0.sp),
                            Text(
                              widget.label,
                              style:
                                  widget.labelTextStyle ??
                                  Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    color:AppColors.white,
                                    height: 1.3,
                                    fontSize: 15.0.sp,
                                    // fontFamily: Fonts.plusJakartaSansBold,
                                  ),
                            ),
                            if (widget.rightIcon != null)
                              SizedBox(width: widget.spaceFromRight ?? 10.0.sp),
                            if (widget.rightIcon != null)
                              MediaViewer(path: widget.rightIcon!,
                                color:
                                    widget.iconColor ??
                                   AppColors.white,
                                height: widget.iconSize ?? 25.0.sp,
                              ),
                            // Image.asset(
                            //   widget.rightIcon!,
                            //   color: widget.iconColor ?? AppColors.whiteColor,
                            //   height: widget.iconSize ?? 20.0.sp,
                            // ),
                          ],
                        ),
                ),
              )
              .animate(
                target:
                    widget.isButtonAnimationEnable &&
                        (widget.isEnabled ?? false)
                    ? 1
                    : 0,
              )
              .then()
              .moveY(
                duration: (widget.isEnabled ?? false) ? 400.ms : 1000.ms,
                begin: widget.isButtonAnimationEnable
                    ? (widget.isEnabled ?? false)
                          ? (widget.height ?? Get.height * 0.067) +
                                bottomSpacing
                          : Get.height * 0.5
                    : 0,
                curve: Curves.easeInOutBack,
              ),
    );
  }
}
