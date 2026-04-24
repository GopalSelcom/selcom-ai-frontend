import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.color = Colors.white,
    this.size = 28,
    this.onPressed,
    this.alignment = Alignment.centerLeft,
    this.showOnlyWhenCanPop = true,
    this.hitSize = 40,
  });

  final Color color;
  final double size;
  final VoidCallback? onPressed;
  final AlignmentGeometry alignment;
  final bool showOnlyWhenCanPop;
  final double hitSize;

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
        child: Center(
          child: Icon(Iconsax.arrow_left, color: color, size: size),
        ),
      ),
    );

    return Align(alignment: alignment, child: backButton);
  }
}
