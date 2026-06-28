import 'package:flutter/material.dart';

import '../../core/utils/bottom_inset_helper.dart';
import 'app_standard_bottom_sheet_bottom_pad.dart';

/// Bottom clearance for modal bottom sheets on **Android gesture navigation** only.
///
/// Prefer [AppStandardBottomSheetBottomPad] with `gestureNavOnly: true`.
/// This widget remains for existing list-only sheets.
class AppStandardBottomSheetGesturePad extends StatelessWidget {
  const AppStandardBottomSheetGesturePad({super.key});

  static double height() {
    return BottomInsetHelper.instance.gestureOnlySheetPadHeight();
  }

  @override
  Widget build(BuildContext context) {
    return const AppStandardBottomSheetBottomPad(gestureNavOnly: true);
  }
}
