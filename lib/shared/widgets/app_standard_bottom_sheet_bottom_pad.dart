import 'package:flutter/material.dart';

import '../../core/utils/bottom_inset_helper.dart';

/// Unified bottom clearance for modal bottom sheets.
///
/// - **List-only (gesture nav):** [gestureNavOnly] — same as legacy
///   [AppStandardBottomSheetGesturePad].
/// - **No footer + manual keyboard sizing:** [hideWhenKeyboardOpen] — use as
///   [AppStandardBottomSheet.bottomBodyWidget] with `liftBodyForKeyboard: false`.
class AppStandardBottomSheetBottomPad extends StatelessWidget {
  const AppStandardBottomSheetBottomPad({
    super.key,
    this.hideWhenKeyboardOpen = false,
    this.gestureNavOnly = false,
    this.includeFooterMinGap = true,
  });

  /// Hides the pad while the keyboard is open (avoids double spacing with
  /// sheet-local keyboard height math).
  final bool hideWhenKeyboardOpen;

  /// Android gesture nav only; zero on 3-button / iOS (layout handles those).
  final bool gestureNavOnly;

  /// When false, omits [BottomInsetHelper.footerMinGap] (nav-only clearance).
  final bool includeFooterMinGap;

  @override
  Widget build(BuildContext context) {
    final helper = BottomInsetHelper.instance;

    if (hideWhenKeyboardOpen && helper.isSheetKeyboardOpen(context)) {
      return const SizedBox.shrink();
    }

    final height = helper.resolveSheetBottomPadHeight(
      context,
      gestureNavOnly: gestureNavOnly,
      includeFooterMinGap: includeFooterMinGap,
    );

    if (height <= 0) return const SizedBox.shrink();
    return SizedBox(height: height);
  }
}
