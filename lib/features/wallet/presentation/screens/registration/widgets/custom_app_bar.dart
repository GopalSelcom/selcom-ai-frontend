import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../shared/widgets/app_back_button.dart';
import '../../../utils/common_shadow.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBack;
  final VoidCallback? onBack;
  final String? title;
  final Widget? titleWidget;
  final bool centerTitle;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final double? toolbarHeight;
  final Widget? bottomWidget;

  const CustomAppBar({
    super.key,
    this.showBack = false,
    this.onBack,
    this.title,
    this.titleWidget,
    this.centerTitle = false,
    this.actions,
    this.backgroundColor,
    this.toolbarHeight,
    this.bottomWidget,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight((75.0.sp) + (bottomWidget != null ? 40.0 : 0));

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.0.sp)),
        color: backgroundColor ?? Colors.white,
        boxShadow: AppShadows.secondary,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.0.sp)),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 8.0.sp),
              child: AppBar(
                automaticallyImplyLeading: false,
                surfaceTintColor: Colors.transparent,
                backgroundColor: backgroundColor ?? Colors.white,
                centerTitle: centerTitle,
                elevation: 0,
                titleSpacing: 0,
                toolbarHeight: toolbarHeight,
                title: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    if (showBack)
                      AppBackButton(onPressed: onBack ?? () => Get.back()),
                    Expanded(
                      child:
                          titleWidget ??
                          (title != null
                              ? Text(
                                  title!,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: AppColors.greyColor242E49,
                                        // fontFamily:
                                        //     Fonts.plusJakartaSansExtraBold,
                                        fontSize: 24.0.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: centerTitle
                                      ? TextAlign.center
                                      : TextAlign.left,
                                )
                              : const SizedBox.shrink()),
                    ),
                  ],
                ),
                actions: actions,
              ),
            ),
            if (bottomWidget != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: 8.sp,
                  horizontal: 12.sp,
                ),
                child: bottomWidget,
              ),
          ],
        ),
      ),
    );
  }
}

// class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
//   final bool isLeadingEnable;
//   final String? leadingIcon;
//   final Widget? leadingIconWidget;
//   final Function()? onTapLeading;
//   final bool centerTitle;
//   final String? title;
//   final Widget? titleWidget;
//   final Color? titleColor;
//   final String? fontFamily;
//   final double? fontSize;
//   final double? toolbarHeight;
//   final FontWeight? fontWeight;
//
//   final String? actionIcon;
//   final Function()? onTapAction;
//   final Color? backgroundColor;
//
//   final List<Widget>? actionWidgets;
//   final double? leadingWidth;
//   final Color? leadingColor;
//   final Widget? bottomWidget;
//
//   const CustomAppBar({
//     super.key,
//     this.isLeadingEnable = true,
//     this.leadingIcon,
//     this.onTapLeading,
//     this.centerTitle = true,
//     required this.title,
//     this.titleWidget,
//     this.titleColor,
//     this.fontFamily,
//     this.fontSize,
//     this.fontWeight,
//     this.actionIcon,
//     this.onTapAction,
//     this.backgroundColor,
//     this.actionWidgets,
//     this.leadingIconWidget,
//     this.leadingWidth,
//     this.leadingColor,
//     this.toolbarHeight,
//     this.bottomWidget,
//   }) : assert(title != null || titleWidget != null);
//
//   @override
//   Size get preferredSize => Size.fromHeight((toolbarHeight ?? kToolbarHeight));
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: backgroundColor ?? Colors.white,
//         borderRadius: BorderRadius.vertical(bottom: Radius.circular(22.0.sp)),
//         boxShadow: AppShadows.secondary,
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.0.sp)),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             AppBar(
//               backgroundColor: backgroundColor ?? Colors.white,
//               automaticallyImplyLeading: isLeadingEnable,
//               centerTitle: centerTitle,
//               elevation: 0,
//               titleSpacing: 0,
//               toolbarHeight: toolbarHeight,
//               leadingWidth:
//                   leadingWidth ?? (leadingIconWidget != null ? 55.0.sp : null),
//               leading: isLeadingEnable
//                   ? (leadingIconWidget ??
//                         (leadingIcon != null
//                             ? IconButton(
//                                 icon: MediaViewer(path: //                                   leadingIcon!,
//                                   color:
//                                       leadingColor ?? AppColors.greyColor242E49,
//                                   height: 15.0.sp,
//                                 ),
//                                 onPressed: onTapLeading,
//                               )
//                             : null))
//                   : null,
//               title:
//                   titleWidget ??
//                   Text(
//                     title ?? "",
//                     style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                       color: titleColor ?? AppColors.greyColor242E49,
//                       fontFamily: fontFamily ?? Fonts.plusJakartaSansExtraBold,
//                       fontSize: fontSize ?? 24.0.sp,
//                     ),
//                   ),
//               actions: <Widget>[...?actionWidgets],
//             ),
//             // Custom bottom widgets support
//             if (bottomWidget != null)
//               Container(
//                 width: double.infinity,
//                 padding: EdgeInsets.only(bottom: 10.0.sp),
//                 child: bottomWidget,
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
