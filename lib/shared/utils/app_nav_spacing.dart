import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_android_navigation_mode/flutter_android_navigation_mode.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Navigation-bar spacing for [AppScaffold] and overlay sheets.
class AppNavSpacing {
  AppNavSpacing._();

  static final AppNavSpacing instance = AppNavSpacing._();

  final ValueNotifier<bool> needBottomSpacing = ValueNotifier(false);

  Future<void> init() async {
    var spacingNeeded = false;
    var navigationMode = DeviceNavigationMode.none;

    if (Platform.isAndroid) {
      final androidDeviceInfo = await DeviceInfoPlugin().androidInfo;
      if (androidDeviceInfo.version.sdkInt > 35) {
        try {
          navigationMode = await AndroidNavigationMode.getNavigationMode;
          spacingNeeded =
              navigationMode != DeviceNavigationMode.fullScreenGesture;
        } on PlatformException {
          spacingNeeded = false;
          navigationMode = DeviceNavigationMode.none;
        }
      }
    }

    needBottomSpacing.value = spacingNeeded;

    if (kDebugMode) {
      debugPrint(
        'needBottomSpacing ==> $spacingNeeded || navigationMode ==> $navigationMode',
      );
    }
  }

  /// False when [AppSafeBottomBox] on [AppScaffold] already reserves bottom inset.
  bool get shouldUseSafeAreaBottom => !needBottomSpacing.value;

  /// Scaffold body [SafeArea] bottom — off when keyboard is open or scaffold handles inset.
  bool scaffoldShouldUseSafeAreaBottom(BuildContext context) {
    if (isKeyboardVisible(context)) return false;
    return shouldUseSafeAreaBottom;
  }

  bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.viewInsetsOf(context).bottom > 0;
  }

  /// [SafeArea] bottom for modal sheets — off when keyboard is open or scaffold handles inset.
  bool overlayShouldUseSafeAreaBottom(BuildContext context) {
    if (isKeyboardVisible(context)) return false;
    return shouldUseSafeAreaBottom;
  }

  double rawSystemBottomInset(BuildContext context) {
    final mq = MediaQuery.of(context);
    final paddingBottom = mq.padding.bottom;
    final viewBottom = mq.viewPadding.bottom;
    return paddingBottom > viewBottom ? paddingBottom : viewBottom;
  }

  /// System inset for content inside [AppScaffold] (0 when [AppSafeBottomBox] is active).
  double scaffoldSystemBottomInset(BuildContext context) {
    if (needBottomSpacing.value) return 0;
    return rawSystemBottomInset(context);
  }

  /// Height of [AppScaffold] expanded body (above [AppSafeBottomBox]).
  double scaffoldBodyHeight(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    if (!needBottomSpacing.value) return h;
    final inset = rawSystemBottomInset(context);
    if (inset <= 0) return h;
    return h - inset;
  }

  /// Lift draggable sheet fractions when [AppSafeBottomBox] shrinks scaffold body.
  double sheetChildSizeWithSafeBottomBox(BuildContext context, double base) {
    if (!needBottomSpacing.value) return base;
    final inset = rawSystemBottomInset(context);
    if (inset <= 0) return base;
    final bodyH = scaffoldBodyHeight(context);
    if (bodyH <= 0) return base;
    return base + inset / bodyH;
  }

  /// Home sheet default open height when [AppSafeBottomBox] is active.
  double homeSheetOpenSizeLift(BuildContext context, double base) {
    return sheetChildSizeWithSafeBottomBox(context, base);
  }

  /// Draggable sheet size lift for map screens inside [AppScaffold].
  double sheetSizeWithNavInset(BuildContext context, double base) {
    final inset = scaffoldSystemBottomInset(context);
    final h = MediaQuery.sizeOf(context).height;
    if (inset <= 0 || h <= 0) return base;
    return base + (inset / h) * 0.55;
  }

  /// Extra scroll padding inside map-style sheets.
  double sheetScrollBottomPad(BuildContext context) {
    return scaffoldSystemBottomInset(context) > 0 ? 2.h : 0;
  }

  /// Bottom gap for modal / overlay sheets (not inside [AppScaffold]).
  double overlayTrailingGap(
    BuildContext context, {
    double fallback = 16,
    double androidExtra = 8,
    double keyboardGap = 12,
  }) {
    // [AppDialogs.showAnimatedBottomSheet] lifts the sheet; add a design gap only.
    if (isKeyboardVisible(context)) {
      return keyboardGap.h;
    }
    final inset = rawSystemBottomInset(context);
    if (needBottomSpacing.value) {
      return inset + androidExtra.h;
    }
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    return inset > 0 ? (isIos ? 0.0 : androidExtra.h) : fallback.h;
  }

  /// Bottom gap for footers inside [AppScaffold].
  double footerTrailingGap(
    BuildContext context, {
    double fallback = 16,
    double keyboardGap = 12,
  }) {
    if (isKeyboardVisible(context)) {
      return keyboardGap.h;
    }
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    final inset = rawSystemBottomInset(context);
    // If iOS has a home indicator area (inset > 0), the Safe Area already 
    // provide enough breathing room below the content, so we return 0 extra gap.
    if (isIos && inset > 0) {
      return 0.0;
    }
    return fallback.h;
  }
}
