import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_assets.dart';

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
    IconData icon = Icons.notifications_off,
    IconData? secondaryIcon,
  }) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(13.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.r),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Illustration Container (Matching mockup tiered style)
              Container(
                height: 140.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (secondaryIcon != null)
                          Icon(
                            secondaryIcon,
                            size: 48.sp,
                            color: AppColors.primary.withOpacity(0.1),
                          ),
                        Icon(icon, size: 48.sp, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              // Title
              Text(
                title,
                style: AppTextStyles.onboardingTitle.copyWith(
                  fontSize: 24.sp,
                  color: const Color(0xFF222222),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
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
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),

              // Open Settings Button (Primary)
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  onOpenSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 56.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Open Settings',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // Cancel Button (Secondary)
              OutlinedButton(
                onPressed: () {
                  Get.back();
                  if (onCancel != null) onCancel();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE0E0E0), width: 1.2),
                  minimumSize: Size(double.infinity, 56.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                child: Text(
                  'Maybe Later',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: const Color(0xFF9E9E9E),
                    fontWeight: FontWeight.w600,
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

  /// Shows a success dialog for verification completion.
  static void showVerificationSuccessDialog({VoidCallback? onConfirm}) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                ClipPath(
                  clipper: SuccessHeaderClipper(),
                  child: Container(
                    height: 160.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28.r),
                        topRight: Radius.circular(28.r),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 40.h,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        AppAssets.imgSuccessTick,
                        width: 48.w,
                        height: 48.w,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 40.h),
              child: InkWell(
                onTap: () {
                  Get.back();
                  if (onConfirm != null) onConfirm();
                },
                child: Text(
                  "You're all set! Your account is verified and ready to use.",
                  style: AppTextStyles.sectionTitle.copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF222222),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: true,
    );
  }
}

class SuccessHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height * 0.85);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, size.height * 0.85);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
