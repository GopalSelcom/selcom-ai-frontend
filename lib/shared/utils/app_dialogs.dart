import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/progress_indicator/loader.dart';
import '../../core/services/session_expiry_service.dart';
import '../../features/payment/domain/models/insufficient_wallet_balance_details.dart';
import '../../features/payment/presentation/widgets/insufficient_wallet_balance_dialog.dart';
import '../widgets/animated_blur_dialog.dart';
import '../widgets/app_cancel_flow_dialog.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_standard_bottom_sheet.dart';

class AppDialogs {
  static bool _isErrorDialogVisible = false;

  /// Utility to ensure keyboard is closed before showing dialogs/bottom sheets
  static Future<void> ensureKeyboardClosed() async {
    final context = Get.context;
    if (context == null) return;

    final primaryFocus = FocusManager.instance.primaryFocus;
    final hasKeyboard =
        (primaryFocus != null && primaryFocus.hasFocus) ||
        MediaQuery.viewInsetsOf(context).bottom > 0;

    if (hasKeyboard) {
      primaryFocus?.unfocus();
      // Wait for keyboard closing animation to finish to prevent UI glitches/jumping
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
  }

  /// Standard animated popup function.
  static Future<T?> showAnimatedDialog<T>({
    required Widget child,
    bool barrierDismissible = true,
    Color? barrierColor,
    bool useRootNavigator = false,
  }) async {
    await ensureKeyboardClosed();
    return showGeneralDialog<T>(
      context: Get.context!,
      useRootNavigator: useRootNavigator,
      barrierDismissible: barrierDismissible,
      barrierLabel: "AnimatedBlurDialog",
      barrierColor: barrierColor ?? AppColors.overlayBlack12,
      transitionDuration: AppModalBlurTokens.duration,
      pageBuilder: (context, animation, secondaryAnimation) {
        return child;
      },
      transitionBuilder: (context, animation, secondaryAnimation, childWidget) {
        return AppModalBlurTransition(animation: animation, child: childWidget);
      },
    );
  }

  /// Ride cancel flow modal (title, optional subtitle, custom body/actions).
  static Future<T?> showCancelFlowDialog<T>({
    required String title,
    String? subtitle,
    required Widget content,
    bool canPop = true,
    bool barrierDismissible = false,
    EdgeInsetsGeometry? padding,
    double? spacingAfterHeader,
    double spacingBetweenTitleAndSubtitle = 0,
    bool showDividerAfterSubtitle = true,
    double? spacingBeforeDivider,
    double? spacingAfterDivider,
  }) {
    return showAnimatedDialog<T>(
      child: AppCancelFlowDialog(
        title: title,
        subtitle: subtitle,
        content: content,
        canPop: canPop,
        padding: padding,
        showDivider: showDividerAfterSubtitle,
      ),
      barrierDismissible: barrierDismissible,
      barrierColor: AppColors.overlayBlack12,
    );
  }

  /// Low-level bottom sheet overlay (blur + slide). Prefer [showStandardBottomSheet]
  /// for shared title/subtitle/content sheets.
  static Future<T?> showAnimatedBottomSheet<T>({
    required Widget child,
    bool barrierDismissible = true,
    bool enableDrag = true,
  }) async {
    await ensureKeyboardClosed();
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
                    child: _DragToDismissWrapper(
                      enableDrag: enableDrag,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Single entry point for app bottom sheets (blur, slide, safe area).
  ///
  /// **Body only** — pass [content] with [title] / [subtitle]; shell is built for you:
  /// ```dart
  /// AppDialogs.showStandardBottomSheet(
  ///   title: 'Title',
  ///   subtitle: 'Subtitle',
  ///   content: MySheetBody(),
  ///   headerTextAlign: TextAlign.start,
  /// );
  /// ```
  ///
  /// **Full sheet widget** — pass [sheet] when the widget already returns
  /// [AppStandardBottomSheet] (multi-step flows, dynamic headers):
  /// ```dart
  /// AppDialogs.showStandardBottomSheet(
  ///   sheet: const BookingForSomeoneElseFlowBottomSheet(),
  /// );
  /// ```
  ///
  /// Do not pass both [content] and [sheet]. For one-off custom UIs without
  /// [AppStandardBottomSheet], use [showAnimatedBottomSheet].
  static Future<T?> showStandardBottomSheet<T>({
    String? title,
    String? subtitle,
    Widget? content,
    Widget? sheet,
    Widget? footer,
    bool barrierDismissible = true,
    bool enableDrag = true,
    bool showDragHandle = true,
    bool showHeaderDivider = true,
    EdgeInsetsGeometry? contentPadding,
    double maxHeightFactor = 0.75,
    TextAlign headerTextAlign = TextAlign.start,
  }) {
    assert(
      (sheet != null) != (content != null),
      'showStandardBottomSheet: provide exactly one of `content` (body only) '
      'or `sheet` (widget that already wraps AppStandardBottomSheet).',
    );

    final Widget child =
        sheet ??
        AppStandardBottomSheet(
          title: title,
          subtitle: subtitle,
          content: content!,
          footer: footer,
          showDragHandle: showDragHandle,
          showHeaderDivider: showHeaderDivider,
          contentPadding: contentPadding,
          maxHeightFactor: maxHeightFactor,
          headerTextAlign: headerTextAlign,
        );

    return showAnimatedBottomSheet<T>(
      barrierDismissible: barrierDismissible,
      enableDrag: enableDrag,
      child: child,
    );
  }

  static void closeActiveDialog() {
    _dismissActiveDialog();
  }

  /// Dismisses the global [Loader] overlay from [showLoadingDialog].
  static void dismissLoadingDialog() {
    Loader.instance.hide();
  }

  /// Closes the top modal overlay, then replaces the stack with [route].
  /// Use after ride cancel so Obx/dialog dependents dispose before navigation.
  static Future<void> navigateReplacingStack(String route) async {
    // Let any in-flight widget rebuilds settle before tearing down overlays.
    await WidgetsBinding.instance.endOfFrame;
    dismissLoadingDialog();
    if ((Get.isDialogOpen ?? false) || (Get.isBottomSheetOpen ?? false)) {
      final navigator = Get.key.currentState;
      if (navigator != null && navigator.canPop()) {
        navigator.pop();
      }
      await WidgetsBinding.instance.endOfFrame;
    }
    await WidgetsBinding.instance.endOfFrame;
    await Get.offAllNamed(route);
  }

  static Future<void> navigateHomeReplacingStack() {
    return navigateReplacingStack(AppRoutes.home);
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

  /// Pops the top overlay route (e.g. [showAnimatedDialog], bottom sheets).
  /// Use instead of [Get.back] — GetX does not track [showGeneralDialog] routes.
  static void dismissTopOverlay() => _dismissActiveDialog();

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
        await SessionExpiryService.handleSessionExpired();
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
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: AppColors.primary,
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

  /// Insufficient wallet balance before book ride (see Figma insufficient-balance alert).
  static Future<void> showInsufficientWalletBalanceDialog({
    required InsufficientWalletBalanceDetails details,
    required VoidCallback onTopUp,
  }) {
    return showAnimatedDialog<void>(
      barrierDismissible: true,
      child: InsufficientWalletBalanceDialog(
        details: details,
        onTopUp: () {
          _dismissActiveDialog();
          onTopUp();
        },
        onDismiss: _dismissActiveDialog,
      ),
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
                        backgroundColor:
                            confirmColor ?? AppColors.primaryButton,
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

  /// Settings prompt for denied permissions (notifications, location, camera, …).
  static Future<void> showPermissionDialog({
    required String title,
    required String message,
    required VoidCallback onOpenSettings,
    VoidCallback? onCancel,
    IconData icon = Icons.notifications_off,
    IconData? secondaryIcon,
  }) {
    return showAnimatedDialog<void>(
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
                      color: AppColors.primaryLight,
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
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
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

  /// Shows Duka Direct global loader (Lottie + blur). [message] is ignored (Duka parity).
  static void showLoadingDialog({String message = ""}) {
    Loader.instance.show();
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

class _DragToDismissWrapper extends StatefulWidget {
  const _DragToDismissWrapper({
    required this.child,
    required this.enableDrag,
  });

  final Widget child;
  final bool enableDrag;

  @override
  State<_DragToDismissWrapper> createState() => _DragToDismissWrapperState();
}

class _DragToDismissWrapperState extends State<_DragToDismissWrapper>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  late AnimationController _snapController;
  late Animation<double> _snapAnimation;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _snapAnimation = _snapController.drive(Tween<double>(begin: 0.0, end: 0.0));
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!widget.enableDrag) return;
    setState(() {
      _dragOffset = (_dragOffset + details.primaryDelta!).clamp(0.0, double.infinity);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!widget.enableDrag) return;

    final velocity = details.primaryVelocity ?? 0.0;
    if (_dragOffset > 100.0 || velocity > 500.0) {
      Navigator.of(context).pop();
    } else {
      _snapAnimation = _snapController.drive(
        Tween<double>(begin: _dragOffset, end: 0.0),
      );
      _snapController.forward(from: 0.0).then((_) {
        setState(() {
          _dragOffset = 0.0;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableDrag) return widget.child;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      child: AnimatedBuilder(
        animation: _snapController,
        builder: (context, child) {
          final offset = _snapController.isAnimating ? _snapAnimation.value : _dragOffset;
          return Transform.translate(
            offset: Offset(0.0, offset),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
