import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';

import '../widgets/cancel_ride_dialogs.dart';

class CancelDialogGalleryScreen extends StatelessWidget {
  const CancelDialogGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.cancelDialogsGallery.tr),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            _buildTestButton(
              title: AppStrings.value1StandardConfirmation.tr,
              onTap: () => Get.dialog(const CancelConfirmationDialog()),
            ),
            SizedBox(height: 16.h),
            _buildTestButton(
              title: AppStrings.value2AssignmentWarningFee.tr,
              onTap: () => Get.dialog(const CancelAssignmentWarningDialog()),
            ),
            SizedBox(height: 16.h),
            _buildTestButton(
              title: AppStrings.value3ReasonSelection.tr,
              onTap: () async {
                final reason = await Get.dialog<String>(
                  const CancelReasonSelectionDialog(),
                );
                if (reason != null) {}
              },
            ),
            const Spacer(),
            Text(
              AppStrings.tapEachButtonToPreviewThePopupUi.tr,
              style: TextStyle(color: Colors.grey, fontSize: 13.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton({
    required String title,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          backgroundColor: const Color(0xFFF1F5F9),
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        onPressed: onTap,
        child: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp),
        ),
      ),
    );
  }
}
