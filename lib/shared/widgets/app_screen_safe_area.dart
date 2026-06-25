import 'package:flutter/material.dart';

import '../utils/app_nav_spacing.dart';

/// [SafeArea] for [AppScaffold] bodies — bottom is off when [AppSafeBottomBox] applies.
class AppScreenSafeArea extends StatelessWidget {
  const AppScreenSafeArea({
    super.key,
    required this.child,
    this.top = true,
    this.left = true,
    this.right = true,
    this.minimum = EdgeInsets.zero,
    this.maintainBottomViewPadding = false,
  });

  final Widget child;
  final bool top;
  final bool left;
  final bool right;
  final EdgeInsets minimum;
  final bool maintainBottomViewPadding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: top,
      left: left,
      right: right,
      bottom: AppNavSpacing.instance.shouldUseSafeAreaBottom,
      minimum: minimum,
      maintainBottomViewPadding: maintainBottomViewPadding,
      child: child,
    );
  }
}
