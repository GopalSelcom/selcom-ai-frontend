import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/app_colors.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.color = AppColors.white,
    this.size,
    this.onPressed,
    this.alignment = Alignment.centerLeft,
    this.showOnlyWhenCanPop = true,
    this.hitSize = 40,
    this.alignToParent = true,
    this.alignIconToStart = false,
  });

  final Color color;
  final double? size;
  final VoidCallback? onPressed;
  final AlignmentGeometry alignment;
  final bool showOnlyWhenCanPop;
  final double hitSize;

  /// When `false`, returns only the tappable control (e.g. inside a [Row]).
  final bool alignToParent;

  /// When `true`, draws the icon at the leading edge of [hitSize] so it lines
  /// up with left-aligned headings in a [Column]. Default centers the icon.
  final bool alignIconToStart;

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.of(context).canPop();
    if (showOnlyWhenCanPop && !canGoBack) {
      return const SizedBox.shrink();
    }

    final backButton = InkWell(
      customBorder: const CircleBorder(),
      onTap: onPressed ?? () => Get.back(),
      child: SizedBox(
        width: hitSize,
        height: hitSize,
        child: alignIconToStart
            ? Align(
                alignment: Alignment.centerLeft,
                child: Icon(
                  Iconsax.arrow_left,
                  color: color,
                  size: size ?? 28.w,
                ),
              )
            : Center(
                child: Icon(
                  Iconsax.arrow_left,
                  color: color,
                  size: size ?? 28.w,
                ),
              ),
      ),
    );

    if (!alignToParent) {
      return backButton;
    }
    return Align(alignment: alignment, child: backButton);
  }
}
