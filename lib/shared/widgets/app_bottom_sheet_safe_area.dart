import 'package:flutter/material.dart';

/// Extra bottom padding for sheets shown **outside** the app-level [SafeArea]
/// (e.g. [showGeneralDialog] overlays). In-route widgets should rely on that
/// [SafeArea] only — do not add [viewPadding] again.
class AppBottomSheetSafeArea extends StatelessWidget {
  const AppBottomSheetSafeArea({
    super.key,
    required this.child,
    this.extraBottom = 0,
  });

  final Widget child;
  final double extraBottom;

  @override
  Widget build(BuildContext context) {
    final bottom = appBottomSheetBottomInset(context) + extraBottom;
    if (bottom <= 0) return child;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: child,
    );
  }
}

/// Bottom inset for modal sheets only (not [AppDraggableBottomSheet] on map screens).
///
/// Returns [MediaQuery.padding.bottom] — non-zero when the platform reports bottom
/// obstruction that was **not** already consumed by the global app [SafeArea].
/// After the app [SafeArea], this is 0 for normal routes and draggable sheets.
double appBottomSheetBottomInset(BuildContext context) {
  return MediaQuery.paddingOf(context).bottom;
}
