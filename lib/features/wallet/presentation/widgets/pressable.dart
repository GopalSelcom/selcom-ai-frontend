import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for HapticFeedback

class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 8,
    this.scaleFactor = 0.95,
    this.enableRipple = false,
    this.rippleColor,
    this.enableHaptics = true, // 👈 new flag
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final double scaleFactor;
  final bool enableRipple;
  final Color? rippleColor;
  final bool enableHaptics;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _onTapDown(TapDownDetails details) {
    setState(() => _pressed = true);
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact(); // 👈 subtle haptic on press down
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _pressed = false);
  }

  void _onTapCancel() {
    setState(() => _pressed = false);
  }

  void _onTap() {
    if (widget.enableHaptics) {
      HapticFeedback.mediumImpact(); // 👈 satisfying click feedback
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final scaledChild = AnimatedScale(
      scale: _pressed ? widget.scaleFactor : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: widget.child,
    );

    if (widget.enableRipple) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          splashColor: widget.rippleColor ?? Colors.black12,
          onTap: _onTap,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: scaledChild,
          ),
          // onDoubleTap: (){},
        ),
      );
    } else {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: scaledChild,
        // onDoubleTap: (){},
      );
    }
  }
}
