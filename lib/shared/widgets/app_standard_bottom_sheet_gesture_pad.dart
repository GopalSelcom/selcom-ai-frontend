import 'package:flutter/material.dart';

import '../../core/utils/bottom_inset_helper.dart';

/// Bottom clearance for modal bottom sheets on **Android gesture navigation** only.
///
/// Matches footer-sheet spacing ([BottomInsetHelper.gestureFallbackPadding] +
/// [BottomInsetHelper.footerMinGap]). Android 3-button clearance is handled by
/// [AppAdaptiveBottomInsetLayout] via [BottomInsetHelper.resolveAndroidThreeButtonNavInset].
class AppStandardBottomSheetGesturePad extends StatelessWidget {
  const AppStandardBottomSheetGesturePad({super.key});

  static double height() {
    final helper = BottomInsetHelper.instance;
    if (!helper.isAndroidGestureNavigation) return 0;
    return BottomInsetHelper.gestureFallbackPadding +
        BottomInsetHelper.footerMinGap;
  }

  @override
  Widget build(BuildContext context) {
    final pad = height();
    if (pad <= 0) return const SizedBox.shrink();
    return SizedBox(height: pad);
  }
}
