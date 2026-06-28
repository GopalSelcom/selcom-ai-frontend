import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_android_navigation_mode/flutter_android_navigation_mode.dart';

import '../config/app_safe_area_controller.dart';

/// Resolves when bottom safe spacing should be applied and how much.
///
/// Call [init] once at app startup; all spacing decisions are synchronous after that.
class BottomInsetHelper {
  BottomInsetHelper._();

  static final BottomInsetHelper instance = BottomInsetHelper._();

  /// Fixed spacing when [AppSafeAreaController.forceIosStyle] is enabled.
  static const double iosStyleTestSpacing = 34;

  /// Minimum visual gap between footer and screen edge / keyboard.
  static const double footerMinGap = 12;

  /// Fallback when Android gesture nav reports near-zero [MediaQuery] padding.
  static const double gestureFallbackPadding = 16;

  /// Fallback when Android 3-button nav reports near-zero padding (e.g. after
  /// [MediaQuery.removePadding] with `removeBottom: true`).
  static const double threeButtonNavFallbackPadding = 48;

  static const double _gestureSafeAreaThreshold = 5;

  DeviceNavigationMode? _cachedAndroidMode;

  /// Preloads Android navigation mode once at app start.
  Future<void> init() async {
    if (!Platform.isAndroid) return;

    try {
      _cachedAndroidMode = await AndroidNavigationMode.getNavigationMode;
    } catch (_) {
      _cachedAndroidMode = DeviceNavigationMode.none;
    }
  }

  /// Android: spacing when navigation is not full-screen gesture.
  bool shouldApplyAndroidSpacingSync() {
    return _cachedAndroidMode != DeviceNavigationMode.fullScreenGesture;
  }

  /// iOS: spacing only when bottom UI (CTA, footer, etc.) is present.
  bool shouldApplyIosSpacing({required bool hasBottomWidget}) =>
      hasBottomWidget;

  /// Platform-aware spacing decision (synchronous).
  bool shouldApplySpacing({required bool hasBottomWidget}) {
    if (Platform.isAndroid) {
      return shouldApplyAndroidSpacingSync();
    }

    if (Platform.isIOS) {
      return shouldApplyIosSpacing(hasBottomWidget: hasBottomWidget);
    }

    return hasBottomWidget;
  }

  /// Android full-screen gesture navigation (cached at startup).
  bool get isAndroidGestureNavigation =>
      Platform.isAndroid && !shouldApplyAndroidSpacingSync();

  /// Safe-area inset for footer when keyboard is closed.
  ///
  /// Applies a gesture-nav fallback when [MediaQuery.viewPadding.bottom] is
  /// unreliable.
  double resolveFooterSafeAreaInset(
    BuildContext context,
    bool applySpacing,
  ) {
    final raw = resolveBottomInset(
      context,
      applySpacing,
      includeKeyboardInset: false,
    );

    if (isAndroidGestureNavigation && raw < _gestureSafeAreaThreshold) {
      return gestureFallbackPadding;
    }

    if (Platform.isAndroid &&
        shouldApplyAndroidSpacingSync() &&
        raw < _gestureSafeAreaThreshold) {
      return threeButtonNavFallbackPadding;
    }

    return raw;
  }

  /// Footer bottom padding: safe area OR keyboard (never both), plus [footerMinGap].
  double resolveFooterBottomPadding(
    BuildContext context,
    bool applySpacing, {
    required double keyboardInset,
  }) {
    if (keyboardInset > 0) {
      return keyboardInset + footerMinGap;
    }

    return resolveFooterSafeAreaInset(context, applySpacing) + footerMinGap;
  }

  /// Bottom inset for scrollable body when there is no [footer].
  ///
  /// Android gesture: no layout gap (sheets may use [AppStandardBottomSheetGesturePad]).
  /// Android 3-button / iOS: clearance when [hasBottomWidget] is true.
  double resolveBodyOnlyBottomSafeAreaInset(
    BuildContext context, {
    required bool hasFooter,
    required bool hasBottomWidget,
  }) {
    if (hasFooter) return 0;
    if (!hasBottomWidget) return 0;
    if (isAndroidGestureNavigation) return 0;

    return resolveBottomInset(
      context,
      shouldApplySpacing(hasBottomWidget: true),
      includeKeyboardInset: false,
    );
  }

  /// Resolves Android 3-button navigation bar height when [MediaQuery] padding
  /// was removed or reports zero.
  double resolveAndroidThreeButtonNavInset(BuildContext context) {
    if (!Platform.isAndroid || !shouldApplyAndroidSpacingSync()) return 0;

    final mq = MediaQuery.of(context);
    if (mq.viewPadding.bottom >= _gestureSafeAreaThreshold) {
      return mq.viewPadding.bottom;
    }
    if (mq.padding.bottom >= _gestureSafeAreaThreshold) {
      return mq.padding.bottom;
    }
    return threeButtonNavFallbackPadding;
  }

  /// Bottom inset in logical pixels.
  ///
  /// Keyboard inset applies only when [includeKeyboardInset] is true (scaffold
  /// [resizeToAvoidBottomInset]). Otherwise returns safe-area spacing only.
  double resolveBottomInset(
    BuildContext context,
    bool applySpacing, {
    bool includeKeyboardInset = true,
  }) {
    final mq = MediaQuery.of(context);

    if (includeKeyboardInset && mq.viewInsets.bottom > 0) {
      return mq.viewInsets.bottom;
    }

    if (AppSafeAreaController.instance.forceIosStyle) {
      return iosStyleTestSpacing;
    }

    if (!applySpacing) return 0;

    if (Platform.isAndroid && shouldApplyAndroidSpacingSync()) {
      return resolveAndroidThreeButtonNavInset(context);
    }

    return mq.viewPadding.bottom;
  }
}
