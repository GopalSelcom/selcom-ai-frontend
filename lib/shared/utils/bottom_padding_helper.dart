import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/utils/bottom_inset_helper.dart';

/// Legacy helpers — prefer [BottomInsetHelper] / [AppDraggableBottomSheet].
SizedBox getSafeBottomBox(BuildContext context) {
  final height =
      BottomInsetHelper.instance.resolveDraggableSheetBottomInset(context);
  if (height <= 0) return const SizedBox.shrink();
  return SizedBox(height: height);
}

double getComputedBottomPadding(
  BuildContext context, {
  double? defaultPadding,
}) {
  final navInset =
      BottomInsetHelper.instance.resolveDraggableSheetBottomInset(context);
  if (navInset > 0) return navInset;
  return defaultPadding ?? 16.h;
}
