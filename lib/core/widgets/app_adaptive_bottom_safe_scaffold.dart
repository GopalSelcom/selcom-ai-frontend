import 'package:flutter/material.dart';

import '../config/app_safe_area_controller.dart';
import '../theme/app_colors.dart';
import '../utils/bottom_inset_helper.dart';

/// Scaffold with optional footer slot, system safe-area spacing, and keyboard lift.
///
/// Footer padding uses safe area OR keyboard inset (never both), plus a minimum
/// visual gap. When no footer is present, keyboard inset lifts [body] instead.
class AppAdaptiveBottomSafeScaffold extends StatelessWidget {
  const AppAdaptiveBottomSafeScaffold({
    super.key,
    required this.body,
    this.footer,
    this.backgroundColor = AppColors.pageBackground,
    this.hasBottomWidget = false,
    this.liftBodyForKeyboard = true,
  });

  final Widget body;

  /// Optional bottom slot. Fully screen-controlled.
  final Widget? footer;

  final Color backgroundColor;

  /// Retained for call-site compatibility; also true when [footer] is non-null.
  final bool hasBottomWidget;

  /// When false, [body] is not padded for the keyboard (e.g. inputs live in a top header).
  final bool liftBodyForKeyboard;

  bool get _hasFooter => footer != null;

  bool get _needsBottomSafeSpacing => hasBottomWidget || _hasFooter;

  bool _resolveApplySpacing() {
    if (AppSafeAreaController.instance.forceIosStyle) return true;

    if (_needsBottomSafeSpacing) {
      return BottomInsetHelper.instance.shouldApplySpacing(
        hasBottomWidget: _needsBottomSafeSpacing,
      );
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final applySpacing = _resolveApplySpacing();
    final helper = BottomInsetHelper.instance;

    final safeAreaInset = helper.resolveBottomInset(
      context,
      applySpacing,
      includeKeyboardInset: false,
    );

    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    final footerBottomPadding = _hasFooter
        ? helper.resolveFooterBottomPadding(
            context,
            applySpacing,
            keyboardInset: keyboardInset,
          )
        : 0.0;

    final bodyBottomPadding =
        liftBodyForKeyboard && !_hasFooter && keyboardInset > 0
        ? keyboardInset + BottomInsetHelper.footerMinGap
        : 0.0;

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: false,
      body: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: Column(
          children: [
            Expanded(
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: bodyBottomPadding),
                child: body,
              ),
            ),
            if (_hasFooter)
              AnimatedPadding(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: footerBottomPadding),
                child: footer!,
              )
            else if (safeAreaInset > 0)
              SizedBox(height: safeAreaInset),
          ],
        ),
      ),
    );
  }
}

