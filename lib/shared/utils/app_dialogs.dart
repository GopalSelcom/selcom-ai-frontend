import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/storage_service.dart';
import '../widgets/app_bottom_sheet_safe_area.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_standard_bottom_sheet.dart';

class AppDialogs {
  static bool _isErrorDialogVisible = false;
  static bool _isLoadingDialogVisible = false;

  /// Standard animated popup function.
  static Future<T?> showAnimatedDialog<T>({
    required Widget child,
    bool barrierDismissible = true,
    Color? barrierColor,
  }) {
    return showGeneralDialog<T>(
      context: Get.context!,
      barrierDismissible: barrierDismissible,
      barrierLabel: "AnimatedBlurDialog",
      barrierColor: barrierColor ?? AppColors.overlayBlack12,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return child;
      },
      transitionBuilder: (context, animation, secondaryAnimation, childWidget) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: const Cubic(0.15, 0.85, 0.2, 1.0),
        );

        final scaleAnimation = Tween<double>(
          begin: 1.15,
          end: 1.0,
        ).animate(curvedAnimation);
        final blurAnimation = Tween<double>(
          begin: 0.0,
          end: 5.0,
        ).animate(curvedAnimation);

        return AnimatedBuilder(
          animation: curvedAnimation,
          builder: (context, _) {
            return BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: blurAnimation.value,
                sigmaY: blurAnimation.value,
              ),
              child: FadeTransition(
                opacity: curvedAnimation,
                child: ScaleTransition(
                  scale: scaleAnimation,
                  child: childWidget,
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Shows a common animated bottom sheet with a blurred barrier and iOS cubic transition.
  static Future<T?> showAnimatedBottomSheet<T>({
    required Widget child,
    bool barrierDismissible = true,
  }) {
    bool hapticTriggered = false;

    return showGeneralDialog<T>(
      context: Get.context!,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'BottomSheet',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, _) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: const Cubic(0.15, 0.85, 0.2, 1.0),
        );

        // Trigger light haptic impact at the start of entrance
        if (!hapticTriggered && animation.value > 0.05) {
          hapticTriggered = true;
          HapticFeedback.lightImpact();
        }

        return Stack(
          children: [
            // Background blur barrier
            GestureDetector(
              onTap: barrierDismissible ? () => _dismissActiveDialog() : null,
              child: AnimatedBuilder(
                animation: curvedAnimation,
                builder: (context, _) {
                  final blurValue = 6.0 * curvedAnimation.value;
                  final opacityValue = 0.25 * curvedAnimation.value;

                  return BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: blurValue,
                      sigmaY: blurValue,
                    ),
                    child: Container(
                      color: Colors.black.withValues(alpha: opacityValue),
                    ),
                  );
                },
              ),
            ),

            // Bottom sheet content
            Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(curvedAnimation),
                child: Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: AppBottomSheetSafeArea(child: child),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Standard app bottom sheet with optional [title], [subtitle], and [content].
  static Future<T?> showStandardBottomSheet<T>({
    String? title,
    String? subtitle,
    required Widget content,
    Widget? footer,
    bool barrierDismissible = true,
    bool showDragHandle = true,
    bool showHeaderDivider = true,
    EdgeInsetsGeometry? contentPadding,
    double maxHeightFactor = 0.75,
  }) {
    return showAnimatedBottomSheet<T>(
      barrierDismissible: barrierDismissible,
      child: AppStandardBottomSheet(
        title: title,
        subtitle: subtitle,
        content: content,
        footer: footer,
        showDragHandle: showDragHandle,
        showHeaderDivider: showHeaderDivider,
        contentPadding: contentPadding,
        maxHeightFactor: maxHeightFactor,
      ),
    );
  }

  static void closeActiveDialog() {
    _dismissActiveDialog();
  }

  /// Dismisses the loading overlay from [showLoadingDialog] when still visible.
  static void dismissLoadingDialog() {
    if (!_isLoadingDialogVisible) return;
    _dismissActiveDialog();
    _isLoadingDialogVisible = false;
  }

  static void _dismissActiveDialog() {
    final context = Get.context;
    if (context != null) {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      }
    }
  }

  /// Shows a common error dialog with an OK button.
  static void showErrorDialog({
    String title = AppStrings.error,
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

    var didHandleAction = false;
    void handleAction({required bool invokeConfirm}) async {
      if (didHandleAction) return;
      didHandleAction = true;
      _isErrorDialogVisible = false;
      if (invokeConfirm && onConfirm != null) {
        onConfirm();
      }
      if (isSessionExpiredError) {
        await StorageService().deleteAll();
        Get.offAllNamed(AppRoutes.phone);
        return;
      }
      _dismissActiveDialog();
    }

    showAnimatedDialog(
      child: PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: AppColors.cardBackground,
          surfaceTintColor: AppColors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  title.tr,
                  style: AppTextStyles.onboardingTitle.copyWith(
                    fontSize: 22.sp,
                    color: AppColors.textHeading,
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
                    color: AppColors.textBody,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),

                // OK Button
                AppPrimaryButton(
                  label: AppStrings.ok.tr,
                  onPressed: () => handleAction(invokeConfirm: true),
                  height: 54.h,
                  borderRadius: 16.r,
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: AppColors.overlayBlack12,
    ).whenComplete(() {
      _isErrorDialogVisible = false;
    });
  }

  /// Shows an info dialog.
  static void showInfoDialog({
    String title = AppStrings.info,
    required String message,
    VoidCallback? onConfirm,
  }) {
    showAnimatedDialog(
      child: Dialog(
        backgroundColor: AppColors.cardBackground,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 48.sp),
              SizedBox(height: 20.h),
              Text(
                title.tr,
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
              AppPrimaryButton(
                label: AppStrings.gotIt.tr,
                onPressed: () {
                  _dismissActiveDialog();
                  if (onConfirm != null) onConfirm();
                },
                height: 50.h,
                borderRadius: 12.r,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a success dialog
  static void showSuccessDialog({
    String title = AppStrings.success,
    required String message,
    VoidCallback? onConfirm,
  }) {
    var didHandleAction = false;
    void handleAction() {
      if (didHandleAction) return;
      didHandleAction = true;
      _dismissActiveDialog();
      if (onConfirm != null) onConfirm();
    }

    showAnimatedDialog(
      child: PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: AppColors.cardBackground,
          surfaceTintColor: AppColors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24.r),
            ),
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.successBadge.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: AppColors.successBadge,
                    size: 32.sp,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  title.tr,
                  style: AppTextStyles.onboardingTitle.copyWith(
                    fontSize: 20.sp,
                    letterSpacing: -0.4,
                  ),
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
                AppPrimaryButton(
                  label: AppStrings.continueLabel.tr,
                  onPressed: handleAction,
                  height: 50.h,
                  borderRadius: 12.r,
                  backgroundColor: AppColors.successBadge,
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: AppColors.overlayBlack12,
    );
  }

  /// Shows a confirmation dialog with Cancel and Confirm buttons.
  static void showConfirmationDialog({
    String title = AppStrings.confirmation,
    required String message,
    String confirmText = AppStrings.confirm,
    String cancelText = AppStrings.cancel,
    Color? confirmColor,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
  }) {
    var didHandleAction = false;
    void handleCancel() {
      if (didHandleAction) return;
      didHandleAction = true;
      _dismissActiveDialog();
      if (onCancel != null) onCancel();
    }

    showAnimatedDialog(
      child: PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: AppColors.cardBackground,
          surfaceTintColor: AppColors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24.r),
            ),
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
                  style: AppTextStyles.homeTitle.copyWith(
                    height: 34 / 20,
                    letterSpacing: -0.4,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),

                // Message
                Text(
                  message,
                  style: AppTextStyles.homeChip.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: AppPrimaryButton(
                        label: cancelText.tr,
                        onPressed: handleCancel,
                        height: 50.h,
                        outlined: true,
                        backgroundColor: AppColors.transparent,
                        textColor: AppColors.textBody,
                        outlinedTextColor: AppColors.textBody,
                        outlinedBorderColor: AppColors.divider,
                        outlinedBorderWidth: 1,
                        borderRadius: 12.r,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: AppPrimaryButton(
                        label: confirmText.tr,
                        onPressed: () {
                          _dismissActiveDialog();
                          onConfirm();
                        },
                        height: 50.h,
                        backgroundColor: confirmColor ?? AppColors.primary,
                        textColor: AppColors.white,
                        borderRadius: 12.r,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: AppColors.overlayBlack12,
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
    showAnimatedDialog(
      child: Dialog(
        backgroundColor: AppColors.cardBackground,
        surfaceTintColor: AppColors.transparent,
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
                  color: AppColors.bgMuted,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadowSoft,
                          blurRadius: 10,
                          offset: Offset(0, 4),
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
                title.tr,
                style: AppTextStyles.onboardingTitle.copyWith(
                  fontSize: 24.sp,
                  color: AppColors.textPrimary,
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
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),

              // Open Settings Button (Primary)
              AppPrimaryButton(
                label: AppStrings.openSettings.tr,
                onPressed: () {
                  _dismissActiveDialog();
                  onOpenSettings();
                },
                height: 56.h,
                borderRadius: 30.r,
              ),
              SizedBox(height: 12.h),

              // Cancel Button (Secondary)
              AppPrimaryButton(
                label: AppStrings.maybeLater.tr,
                onPressed: () {
                  _dismissActiveDialog();
                  if (onCancel != null) onCancel();
                },
                height: 56.h,
                borderRadius: 30.r,
                outlined: true,
                backgroundColor: AppColors.white,
                textColor: AppColors.textMuted,
                outlinedTextColor: AppColors.textMuted,
                outlinedBorderColor: AppColors.borderSubtle,
                outlinedBorderWidth: 1.2,
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
    showAnimatedDialog(
      child: Dialog(
        backgroundColor: AppColors.cardBackground,
        surfaceTintColor: AppColors.transparent,
        elevation: 20,
        shadowColor: AppColors.shadowStrong,
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
                      color: AppColors.bgSuccessLight,
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
                        color: AppColors.successBadge,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.successBadge.withValues(
                              alpha: 0.2,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 32.w,
                        color: AppColors.white,
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
                    AppStrings.verificationSuccessful.tr,
                    style: AppTextStyles.sectionTitle.copyWith(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    AppStrings
                        .yourIdentityHasBeenSuccessfullyVerifiedYouCanNowUseSelcomPesa
                        .tr,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 16.sp,
                      color: AppColors.textBody,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32.h),
                  AppPrimaryButton(
                    label: AppStrings.gotIt.tr,
                    onPressed: () {
                      _dismissActiveDialog();
                      if (onConfirm != null) onConfirm();
                    },
                    height: 56.h,
                    borderRadius: 16.r,
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
    final timeText = AppStrings.minutesCount.trParams({
      'count': minutes.toString(),
    });

    showAnimatedDialog(
      child: Dialog(
        backgroundColor: AppColors.cardBackground,
        surfaceTintColor: AppColors.transparent,
        elevation: 20,
        shadowColor: AppColors.shadowStrong,
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
                      color: AppColors.errorBackground,
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
                        color: AppColors.white,
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
                    AppStrings.pinLocked.tr,
                    style: AppTextStyles.sectionTitle.copyWith(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    AppStrings.pinLockedMessageRetryInTime.trParams({
                      'message': message,
                      'time': timeText,
                    }),
                    style: AppTextStyles.body.copyWith(
                      fontSize: 16.sp,
                      color: AppColors.textBody,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32.h),
                  AppPrimaryButton(
                    label: AppStrings.gotIt.tr,
                    onPressed: () {
                      _dismissActiveDialog();
                      if (onConfirm != null) onConfirm();
                    },
                    height: 56.h,
                    borderRadius: 16.r,
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

  /// Shows a simple loading dialog.
  static void showLoadingDialog({String message = ""}) {
    if (_isLoadingDialogVisible) return;
    _isLoadingDialogVisible = true;
    showAnimatedDialog(
      child: PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: AppColors.transparent,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                if (message.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  Text(
                    message.tr,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textHeading,
                      fontSize: 14.sp,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    ).whenComplete(() {
      _isLoadingDialogVisible = false;
    });
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
