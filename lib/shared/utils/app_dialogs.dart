import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AppDialogs {
  static bool _isErrorDialogVisible = false;

  /// Shows a common error dialog with an OK button.
  static void showErrorDialog({
    String title = 'Error',
    required String message,
    VoidCallback? onConfirm,
  }) {
    if (_isErrorDialogVisible) return;
    _isErrorDialogVisible = true;
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error Icon
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 32.sp,
                ),
              ),
              SizedBox(height: 20.h),

              // Title
              Text(
                title,
                style: AppTextStyles.onboardingTitle.copyWith(
                  fontSize: 20.sp,
                  color: AppColors.shade1,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),

              // Message
              Text(
                message,
                style: AppTextStyles.onboardingSubtitle.copyWith(
                  fontSize: 14.sp,
                  color: AppColors.shade2,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),

              // OK Button
              InkWell(
                onTap: () {
                  _isErrorDialogVisible = false;
                  Get.back(); // Close dialog
                  if (onConfirm != null) onConfirm();
                },
                child: Container(
                  height: 50.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'OK',
                      style: AppTextStyles.onboardingButton.copyWith(
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Shows a success dialog
  static void showSuccessDialog({
    String title = 'Success',
    required String message,
    VoidCallback? onConfirm,
  }) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 32.sp,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                title,
                style: AppTextStyles.onboardingTitle.copyWith(fontSize: 20.sp),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                message,
                style: AppTextStyles.onboardingSubtitle.copyWith(
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              InkWell(
                onTap: () {
                  Get.back();
                  if (onConfirm != null) onConfirm();
                },
                child: Container(
                  height: 50.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: Text(
                      'Continue',
                      style: AppTextStyles.onboardingButton,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a confirmation dialog with Cancel and Confirm buttons.
  static void showConfirmationDialog({
    String title = 'Confirmation',
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
  }) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Confirmation Icon
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: (confirmColor ?? AppColors.primary).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.help_outline,
                  color: confirmColor ?? AppColors.primary,
                  size: 32.sp,
                ),
              ),
              SizedBox(height: 20.h),

              // Title
              Text(
                title,
                style: AppTextStyles.onboardingTitle.copyWith(
                  fontSize: 20.sp,
                  color: AppColors.shade1,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),

              // Message
              Text(
                message,
                style: AppTextStyles.onboardingSubtitle.copyWith(
                  fontSize: 14.sp,
                  color: AppColors.shade2,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),

              // Buttons
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Get.back();
                        if (onCancel != null) onCancel();
                      },
                      child: Container(
                        height: 50.h,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Center(
                          child: Text(
                            cancelText,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.shade2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Confirm Button
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Get.back();
                        onConfirm();
                      },
                      child: Container(
                        height: 50.h,
                        decoration: BoxDecoration(
                          color: confirmColor ?? AppColors.primary,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: (confirmColor ?? AppColors.primary)
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            confirmText,
                            style: AppTextStyles.onboardingButton.copyWith(
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Shows a permission dialog when notifications are disabled.
  static void showPermissionDialog({
    required String title,
    required String message,
    required VoidCallback onOpenSettings,
    VoidCallback? onCancel,
  }) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.r),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Illustration (Placeholder for the one in screenshot)
              Container(
                height: 120.h,
                width: 140.w,
                decoration: BoxDecoration(
                  color: AppColors.divider.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 64.sp,
                        color: AppColors.primary,
                      ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Icon(
                          Icons.settings,
                          size: 24.sp,
                          color: AppColors.shade2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32.h),

              // Title
              Text(
                title,
                style: AppTextStyles.onboardingTitle.copyWith(
                  fontSize: 22.sp,
                  color: const Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),

              // Message
              Text(
                message,
                style: AppTextStyles.onboardingSubtitle.copyWith(
                  fontSize: 15.sp,
                  color: const Color(0xFF666666),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),

              // Open Settings Button (Primary)
              InkWell(
                onTap: () {
                  Get.back();
                  onOpenSettings();
                },
                child: Container(
                  height: 56.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(28.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Open Settings',
                      style: AppTextStyles.onboardingButton.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // Cancel Button (Secondary)
              InkWell(
                onTap: () {
                  Get.back();
                  if (onCancel != null) onCancel();
                },
                child: Container(
                  height: 56.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(
                      color: const Color(0xFFE0E0E0),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(28.r),
                  ),
                  child: Center(
                    child: Text(
                      'Maybe Later',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF888888),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
}
