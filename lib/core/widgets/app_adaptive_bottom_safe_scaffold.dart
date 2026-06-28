import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_adaptive_bottom_inset_layout.dart';

/// Scaffold with optional footer slot, system safe-area spacing, and keyboard lift.
///
/// Footer padding uses safe area OR keyboard inset (never both), plus a minimum
/// visual gap. When no footer is present, keyboard inset lifts [body] instead.
class AppAdaptiveBottomSafeScaffold extends StatelessWidget {
  const AppAdaptiveBottomSafeScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.pinnedHeader,
    this.footer,
    this.backgroundColor = AppColors.pageBackground,
    this.hasBottomWidget = false,
    this.liftBodyForKeyboard = true,
  });

  final Widget body;

  /// Optional top app bar (Material [AppBar] or [PreferredSizeWidget]).
  final PreferredSizeWidget? appBar;

  /// Fixed content above [body] (search bars, filters, etc.).
  final Widget? pinnedHeader;

  /// Optional bottom slot. Fully screen-controlled.
  final Widget? footer;

  final Color backgroundColor;

  /// Retained for call-site compatibility; also true when [footer] is non-null.
  final bool hasBottomWidget;

  /// When false, [body] is not padded for the keyboard (e.g. inputs live in a top header).
  final bool liftBodyForKeyboard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: appBar,
      body: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        removeTop: appBar != null,
        child: AppAdaptiveBottomInsetLayout(
          pinnedHeader: pinnedHeader,
          body: body,
          footer: footer,
          hasBottomWidget: hasBottomWidget,
          liftBodyForKeyboard: liftBodyForKeyboard,
        ),
      ),
    );
  }
}
