import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';

/// Reusable draggable bottom sheet shell for map-style screens.
///
/// Sits inside the app-level [SafeArea] ([main.dart]); do not add another
/// bottom [viewPadding] lift here or the sheet sits too high.
class AppDraggableBottomSheet extends StatelessWidget {
  const AppDraggableBottomSheet({
    super.key,
    required this.initialChildSize,
    required this.minChildSize,
    this.maxChildSize = 0.9,
    this.snap = false,
    this.snapSizes,
    this.controller,
    this.expand = true,
    required this.childBuilder,
  });

  final DraggableScrollableController? controller;

  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final bool snap;
  final bool expand;
  final List<double>? snapSizes;
  final Widget Function(ScrollController scrollController) childBuilder;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      snap: snap,
      snapSizes: snapSizes,
      expand: expand,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: childBuilder(scrollController),
        );
      },
    );
  }
}
