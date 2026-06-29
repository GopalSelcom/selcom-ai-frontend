import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/bottom_inset_helper.dart';

/// Reusable draggable bottom sheet shell for map-style screens.
///
/// Sits inside the app-level [SafeArea] ([main.dart] with `bottom: false`);
/// use [reserveSystemBottomInset] (default) so content clears Android 3-button
/// nav, gesture nav, and the iOS home indicator via [BottomInsetHelper].
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
    this.reserveSystemBottomInset = true,
    required this.childBuilder,
  });

  final DraggableScrollableController? controller;

  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final bool snap;
  final bool expand;

  /// When true (default), lifts all sheet content above system bottom inset.
  final bool reserveSystemBottomInset;
  final List<double>? snapSizes;
  final Widget Function(ScrollController scrollController) childBuilder;

  /// Shared bottom clearance for sheet size math and scroll trailing pads.
  static double bottomInsetOf(BuildContext context) {
    return BottomInsetHelper.instance.resolveDraggableSheetBottomInset(context);
  }

  /// Adds [bottomInsetOf] to [baseFraction] for Android sheet sizing.
  ///
  /// On iOS, [reserveSystemBottomInset] shell padding alone clears the home
  /// indicator — inflating the fraction as well causes extra white space.
  static double sheetFractionIncludingBottomInset(
    BuildContext context,
    double baseFraction,
  ) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return baseFraction;
    }

    final screenH = MediaQuery.sizeOf(context).height;
    if (screenH <= 0) return baseFraction;
    final inset = bottomInsetOf(context);
    if (inset <= 0) return baseFraction;
    return (baseFraction + inset / screenH).clamp(baseFraction, 0.92);
  }

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
          child: reserveSystemBottomInset
              ? Padding(
                  padding: EdgeInsets.only(
                    bottom: bottomInsetOf(context),
                  ),
                  child: childBuilder(scrollController),
                )
              : childBuilder(scrollController),
        );
      },
    );
  }
}

/// Trailing spacer for draggable sheet scroll content when
/// [AppDraggableBottomSheet.reserveSystemBottomInset] is false.
class AppDraggableBottomSheetBottomPad extends StatelessWidget {
  const AppDraggableBottomSheetBottomPad({super.key});

  @override
  Widget build(BuildContext context) {
    final height = BottomInsetHelper.instance
        .resolveDraggableSheetScrollBottomPad(context);
    if (height <= 0) return const SizedBox.shrink();
    return SizedBox(height: height);
  }
}
