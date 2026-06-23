import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shared metrics for [ProfileScreen] loaded UI and shimmer (prevents height jump).
abstract final class ProfileScreenLayout {
  static const int maxMenuItemCount = 7;

  static double get avatarSize => 60.w;

  /// Name row: 30.sp title line + edit icon (24.w).
  static double get nameRowHeight => 38.h;

  static double get phoneLineHeight => 20.h;

  static double get ratingGap => 4.h;

  static double get ratingRowHeight => 14.h;

  static double get userTextBlockHeight =>
      nameRowHeight + phoneLineHeight + ratingGap + ratingRowHeight;

  static double get userRowHeight =>
      userTextBlockHeight > avatarSize ? userTextBlockHeight : avatarSize;

  static EdgeInsets get userInfoPadding =>
      EdgeInsets.symmetric(horizontal: 16.w);

  static EdgeInsets get walletPadding =>
      EdgeInsets.fromLTRB(17.w, 16.h, 14.w, 12.h);

  /// [WalletSummaryCard] — 51.w icon + 12.h vertical padding.
  static double get walletCardHeight => 63.h;

  static double get menuRowContentHeight => 24.h;

  static double get menuRowPaddingBottom => 11.h;

  static double get menuDividerBlockHeight => 18.h;

  static double get menuItemWithDividerHeight =>
      menuRowPaddingBottom + menuRowContentHeight + menuDividerBlockHeight;

  static double get menuLastItemHeight =>
      menuRowPaddingBottom + menuRowContentHeight;

  static double menuBlockHeight(int itemCount) {
    if (itemCount <= 0) return 0;
    if (itemCount == 1) return menuLastItemHeight;
    return (itemCount - 1) * menuItemWithDividerHeight + menuLastItemHeight;
  }

  static EdgeInsets get settingsContainerPadding =>
      EdgeInsets.fromLTRB(10.w, 19.h, 10.w, 10.h);

  static double get logoutVerticalPadding => 16.h;

  static double get logoutHorizontalPadding => 16.w;

  static double get logoutRowHeight => 24.h;

  static double get logoutButtonHeight =>
      logoutVerticalPadding * 2 + logoutRowHeight;

  static double get logoutGapAfterSettings => 18.h;

  static double get logoutBorderRadius => 16.r;
}
