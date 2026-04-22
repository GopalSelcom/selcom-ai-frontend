import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_assets.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/storage_service.dart';

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
    final normalizedMessage = message.toLowerCase();
    final isSessionExpiredError =
        normalizedMessage.contains('session expired') ||
        normalizedMessage.contains('login again') ||
        normalizedMessage.contains('unauthorized');

    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App Logo
              Container(
                padding: EdgeInsets.all(24.h),
                decoration: const BoxDecoration(
                  color: AppColors.textLight,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(AppAssets.selcomGoLogo, height: 48.h),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 24.h),

                    // Title
                    Text(
                      title,
                      style: AppTextStyles.onboardingTitle.copyWith(
                        fontSize: 22.sp,
                        color: AppColors.shade1,
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
                        color: AppColors.shade2,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32.h),

                    // OK Button
                    InkWell(
                      onTap: () async {
                        _isErrorDialogVisible = false;
                        if (onConfirm != null) onConfirm();
                        if (isSessionExpiredError) {
                          await StorageService().deleteAll();
                          Get.offAllNamed(AppRoutes.phone);
                          return;
                        }
                        Get.back(); // Close dialog
                      },
                      child: Container(
                        height: 54.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'OK',
                            style: AppTextStyles.onboardingButton.copyWith(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                  color: Colors.green.withValues(alpha: 0.1),
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
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
                  color: (confirmColor ?? AppColors.primary).withValues(
                    alpha: 0.1,
                  ),
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
                                  .withValues(alpha: 0.3),
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
                          color: Colors.black.withValues(alpha: 0.05),
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
                            color: AppColors.primary.withValues(alpha: 0.1),
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
        elevation: 20,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                ClipPath(
                  clipper: SuccessHeaderClipper(),
                  child: Container(
                    height: 140.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32.r),
                        topRight: Radius.circular(32.r),
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
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 32.w,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(32.w, 40.h, 32.w, 48.h),
              child: Column(
                children: [
                  Text(
                    "Verification Successful!",
                    style: AppTextStyles.sectionTitle.copyWith(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    "Your identity has been successfully verified. You can now use Selcom Pesa.",
                    style: AppTextStyles.body.copyWith(
                      fontSize: 16.sp,
                      color: AppColors.shade2,
                      height: 1.5,
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
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Center(
                        child: Text(
                          "Got it",
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Shows a PIN locked error dialog.
  static void showPinLockedDialog({
    required String message,
    required int retryAfterSeconds,
    VoidCallback? onConfirm,
  }) {
    final minutes = (retryAfterSeconds / 60).ceil();
    final timeText = minutes > 1 ? "$minutes minutes" : "1 minute";

    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 20,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                ClipPath(
                  clipper: SuccessHeaderClipper(),
                  child: Container(
                    height: 140.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDECEA),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32.r),
                        topRight: Radius.circular(32.r),
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
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        size: 32.w,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(32.w, 40.h, 32.w, 48.h),
              child: Column(
                children: [
                  Text(
                    "PIN Locked",
                    style: AppTextStyles.sectionTitle.copyWith(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    "$message. Please try again in $timeText.",
                    style: AppTextStyles.body.copyWith(
                      fontSize: 16.sp,
                      color: AppColors.shade2,
                      height: 1.5,
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
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Center(
                        child: Text(
                          "Got it",
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
    path.lineTo(0, size.height - 25.h);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 25.h,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
