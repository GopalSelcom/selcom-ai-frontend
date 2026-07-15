import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';

/// Copies [text] to the clipboard and shows iOS-only snackbar feedback.
///
/// Android typically shows a system "Copied" toast; iOS does not, so we add a
/// lightweight inset snackbar there only. Use [message] for context-specific copy
/// (e.g. wallet number); otherwise [AppStrings.copiedToClipboard] is shown.
Future<void> copyToClipboardWithFeedback({
  required String text,
  String? message,
}) async {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return;

  await Clipboard.setData(ClipboardData(text: trimmed));

  // Android OS toast is enough; skip custom UI on that platform.
  if (!Platform.isIOS) return;

  final feedback = message ?? AppStrings.copiedToClipboard.tr;

  // Message-only pill (no title), inset from screen edges — not full width.
  Get.rawSnackbar(
    snackPosition: SnackPosition.BOTTOM,
    duration: const Duration(seconds: 2),
    margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
    borderRadius: 8.r,
    messageText: Text(
      feedback,
      textAlign: TextAlign.left,
      style: TextStyle(
        color: AppColors.white,
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
