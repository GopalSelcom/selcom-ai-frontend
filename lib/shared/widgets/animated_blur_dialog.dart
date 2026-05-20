import 'dart:ui';
import 'package:flutter/material.dart';

class AnimatedBlurDialog extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const AnimatedBlurDialog({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 250),
  });

  @override
  State<AnimatedBlurDialog> createState() => _AnimatedBlurDialogState();
}

class _AnimatedBlurDialogState extends State<AnimatedBlurDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _blurAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = Tween<double>(begin: 1.15, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.15, 0.85, 0.2, 1.0),
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.15, 0.85, 0.2, 1.0),
    );

    _blurAnimation = Tween<double>(begin: 0.0, end: 5.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.15, 0.85, 0.2, 1.0),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: _blurAnimation.value,
            sigmaY: _blurAnimation.value,
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}
