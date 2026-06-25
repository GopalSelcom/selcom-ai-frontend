import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../utils/app_nav_spacing.dart';
import 'app_screen_safe_area.dart';

/// Sticky footer inside [AppScaffold] — design gap above keyboard or [AppSafeBottomBox].
class AppFooterBar extends StatelessWidget {
  const AppFooterBar({
    super.key,
    required this.child,
    this.padding,
    this.bottomGap = 16,
    this.keyboardBottomGap = 12,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double bottomGap;
  final double keyboardBottomGap;

  @override
  Widget build(BuildContext context) {
    final nav = AppNavSpacing.instance;
    final base = padding?.resolve(Directionality.of(context)) ?? EdgeInsets.zero;
    final trailingGap = nav.isKeyboardVisible(context)
        ? keyboardBottomGap.h
        : bottomGap.h;

    return AppScreenSafeArea(
      top: false,
      left: false,
      right: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: base.left,
          top: base.top,
          right: base.right,
          bottom: base.bottom + trailingGap,
        ),
        child: child,
      ),
    );
  }
}
