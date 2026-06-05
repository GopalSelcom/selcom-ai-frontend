import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class ScreenTitleWidget extends StatefulWidget {
  final String screenTitle;
  final String? subTitle;
  final String? rightIcon;
  final bool isSvg;
  final bool isRightIcon;
  final Widget? rightIconWidget;
  final void Function()? onTapRightIcon;
  final void Function()? onLeftIconTap;
  final bool isLeftIconOnTap;
  final Color? svgColor;
  final Color? leftIconColor;
  final bool isLeftIconVisible;
  final bool isTitleVisible;
  final ColorFilter? colorFilter;
  final double? svgHeight;
  final EdgeInsetsGeometry? padding;
  final bool isTitleCenter;
  final TextStyle? titleStyle;

  const ScreenTitleWidget({
    super.key,
    required this.screenTitle,
    this.onTapRightIcon,
    this.isRightIcon = false,
    this.isSvg = true,
    this.rightIcon,
    this.rightIconWidget,
    this.onLeftIconTap,
    this.isLeftIconOnTap = false,
    this.subTitle,
    this.isLeftIconVisible = true,
    this.isTitleVisible = true,
    this.svgColor,
    this.colorFilter,
    this.svgHeight,
    this.padding,
    this.isTitleCenter = false,
    this.titleStyle,
    this.leftIconColor,
  });

  @override
  State<ScreenTitleWidget> createState() => _ScreenTitleWidgetState();
}

class _ScreenTitleWidgetState extends State<ScreenTitleWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      // padding: const EdgeInsets.symmetric(
      //   horizontal: 20,
      //   vertical: 20,
      // ),
      padding:
          widget.padding ??
          const EdgeInsets.only(
            bottom: 20,
            top: 20,
            left: 15,
            right: 20,
          ), //increased touch area of button from 5px
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              // crossAxisAlignment: CrossAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (widget.isLeftIconOnTap) {
                      widget.onLeftIconTap!();
                    } else {
                      Get.back();
                    }
                  },
                  child: Visibility(
                    visible: widget.isLeftIconVisible,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        color: Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Icon(
                            Icons.arrow_back_ios_outlined,
                            // color: widget.leftIconColor ?? AppColors.whiteColor,
                            color: widget.leftIconColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: widget.isTitleVisible,
                  child: Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        widget.isTitleCenter
                            ? Center(
                                child: Text(
                                  widget.screenTitle,
                                  style:
                                      widget.titleStyle ??
                                      Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.copyWith(
                                        height: 1.4,
                                        fontWeight: FontWeight.w500,
                                        // color: AppColors.whiteColor,
                                      ),
                                ),
                              )
                            : Text(
                                widget.screenTitle,
                                style:
                                    widget.titleStyle ??
                                    Theme.of(
                                      context,
                                    ).textTheme.titleLarge?.copyWith(
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                      // color: AppColors.whiteColor,
                                    ),
                              ),
                        if (widget.subTitle?.isNotEmpty ?? false)
                          const SizedBox(height: 3),
                        if (widget.subTitle?.isNotEmpty ?? false)
                          Text(
                            widget.subTitle ?? "",
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  height: 1.2,
                                  color: AppColors.lightGreyTextColor,
                                ),
                            maxLines: 2,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Visibility(
            visible: widget.isRightIcon,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                widget.onTapRightIcon!();
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child:
                    widget.rightIconWidget ??
                    (widget.isSvg
                        ? SvgPicture.asset(
                            widget.rightIcon ?? "",
                            colorFilter:
                                widget.colorFilter ??
                                ColorFilter.mode(
                                  widget.svgColor ?? (AppColors.blackColor),
                                  BlendMode.srcIn,
                                ),
                            height: widget.svgHeight,
                          )
                        : Image.asset(widget.rightIcon ?? "")),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
