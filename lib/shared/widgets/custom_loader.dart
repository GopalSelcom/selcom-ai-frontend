import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/spin_kit_fading_circle.dart';

/// Full-screen loader — same as Duka Direct [CustomLoader].
class CustomLoader extends StatelessWidget {
  const CustomLoader({
    super.key,
    this.color,
    this.bgColor = Colors.transparent,
    this.size,
  });

  final Color? color;
  final Color? bgColor;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height,
      width: MediaQuery.sizeOf(context).width,
      color: bgColor,
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: 80.sp,
            maxWidth: 80.sp,
            minHeight: 50.sp,
            minWidth: 50.sp,
          ),
          child: Center(
            child: SpinKitFadingCircle(
              duration: const Duration(milliseconds: 1300),
              color: color ?? AppColors.primary,
              size: size ?? 50.sp,
            ),
          ),
        ),
      ),
    );
  }
}
