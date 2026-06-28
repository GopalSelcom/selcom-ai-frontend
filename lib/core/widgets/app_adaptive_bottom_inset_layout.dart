import 'package:flutter/material.dart';

import '../config/app_safe_area_controller.dart';
import '../utils/bottom_inset_helper.dart';

/// Shared Column layout for adaptive bottom safe area, keyboard lift, and footer.
///
/// Used by [AppAdaptiveBottomSafeScaffold] and [AppStandardBottomSheet].
class AppAdaptiveBottomInsetLayout extends StatelessWidget {
  const AppAdaptiveBottomInsetLayout({
    super.key,
    this.pinnedHeader,
    required this.body,
    this.footer,
    this.hasBottomWidget = false,
    this.liftBodyForKeyboard = true,
    this.mainAxisSize = MainAxisSize.max,
  });

  /// Optional fixed content above the scrollable/flexible [body].
  final Widget? pinnedHeader;

  final Widget body;

  final Widget? footer;

  final bool hasBottomWidget;

  final bool liftBodyForKeyboard;

  final MainAxisSize mainAxisSize;

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

    final bodyOnlyBottomInset = helper.resolveBodyOnlyBottomSafeAreaInset(
      context,
      hasFooter: _hasFooter,
      hasBottomWidget: hasBottomWidget,
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

    final bodyChild = AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bodyBottomPadding),
      child: body,
    );

    return Column(
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pinnedHeader != null) pinnedHeader!,
        if (mainAxisSize == MainAxisSize.max)
          Expanded(child: bodyChild)
        else
          Flexible(child: bodyChild),
        if (_hasFooter)
          AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: footerBottomPadding),
            child: footer!,
          )
        else if (bodyOnlyBottomInset > 0)
          SizedBox(height: bodyOnlyBottomInset),
      ],
    );
  }
}
