import 'package:flutter/material.dart';

/// Standard reveal for CTAs that appear after form validation (slide up + fade).
///
/// Uses full-width zero-height placeholder when hidden so layout expands vertically
/// only — avoids left-to-right width animation and clips rounded buttons.
class AppAnimatedReveal extends StatelessWidget {
  const AppAnimatedReveal({
    super.key,
    required this.show,
    required this.child,
    this.duration = const Duration(milliseconds: 750),
    this.slideOffset = const Offset(0, 0.18),
    this.sizeAlignment = Alignment.bottomCenter,
    this.visibleKey = const ValueKey('app-animated-reveal-visible'),
    this.hiddenKey = const ValueKey('app-animated-reveal-hidden'),
  });

  final bool show;
  final Widget child;
  final Duration duration;
  final Offset slideOffset;
  final Alignment sizeAlignment;
  final Key visibleKey;
  final Key hiddenKey;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutQuart,
      switchOutCurve: Curves.easeInOutCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return AnimatedSize(
          duration: duration,
          curve: Curves.easeOutQuart,
          clipBehavior: Clip.none,
          alignment: sizeAlignment,
          child: currentChild ?? const SizedBox.shrink(),
        );
      },
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutQuart,
          reverseCurve: Curves.easeInOutCubic,
        );
        final fade = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: slideOffset,
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      child: show
          ? KeyedSubtree(key: visibleKey, child: child)
          : SizedBox(
              key: hiddenKey,
              width: double.infinity,
              height: 0,
            ),
    );
  }
}
