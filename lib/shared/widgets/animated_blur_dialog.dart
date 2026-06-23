import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Shared motion tokens for app modals ([AppDialogs], bottom sheets, in-screen overlays).
abstract final class AppModalBlurTokens {
  static const Duration duration = Duration(milliseconds: 300);
  static const Curve curve = Cubic(0.15, 0.85, 0.2, 1.0);
  static const double scaleBegin = 1.15;
  static const double blurSigmaEnd = 5.0;
}

/// Blur + fade + scale wrapper for [showGeneralDialog] transitions ([AppDialogs.showAnimatedDialog]).
class AppModalBlurTransition extends StatelessWidget {
  const AppModalBlurTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: AppModalBlurTokens.curve,
    );
    final scaleAnimation = Tween<double>(
      begin: AppModalBlurTokens.scaleBegin,
      end: 1.0,
    ).animate(curvedAnimation);
    final blurAnimation = Tween<double>(
      begin: 0.0,
      end: AppModalBlurTokens.blurSigmaEnd,
    ).animate(curvedAnimation);

    return AnimatedBuilder(
      animation: curvedAnimation,
      builder: (context, _) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurAnimation.value,
            sigmaY: blurAnimation.value,
          ),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: ScaleTransition(scale: scaleAnimation, child: child),
          ),
        );
      },
    );
  }
}

/// Full-screen dim + blur for in-route overlays (e.g. promo apply loading/success on a screen).
class AppBlurModalOverlay extends StatefulWidget {
  const AppBlurModalOverlay({
    super.key,
    required this.child,
    this.barrierColor,
    this.duration = AppModalBlurTokens.duration,
  });

  final Widget child;
  final Color? barrierColor;
  final Duration duration;

  @override
  State<AppBlurModalOverlay> createState() => _AppBlurModalOverlayState();
}

class _AppBlurModalOverlayState extends State<AppBlurModalOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _blurAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curved = CurvedAnimation(
      parent: _controller,
      curve: AppModalBlurTokens.curve,
    );
    _fadeAnimation = curved;
    _scaleAnimation = Tween<double>(
      begin: AppModalBlurTokens.scaleBegin,
      end: 1.0,
    ).animate(curved);
    _blurAnimation = Tween<double>(
      begin: 0.0,
      end: AppModalBlurTokens.blurSigmaEnd,
    ).animate(curved);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barrier = widget.barrierColor ?? AppColors.overlayBlack12;

    return AbsorbPointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: ColoredBox(color: barrier),
              ),
              FadeTransition(
                opacity: _fadeAnimation,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: _blurAnimation.value,
                    sigmaY: _blurAnimation.value,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              Center(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: widget.child,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
